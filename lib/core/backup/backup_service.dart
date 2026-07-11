import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:drift/drift.dart';
import 'package:encrypt/encrypt.dart' as enc;

import '../database/app_database.dart';
import 'backup_date_codec.dart';

/// Понятная пользователю ошибка операций с бэкапом.
class BackupException implements Exception {
  const BackupException(this.message);
  final String message;
  @override
  String toString() => message;
}

/// Экспорт/импорт данных в переносимый зашифрованный файл.
///
/// ВАЖНО: бэкапим НЕ файл sqlite (он привязан к ключу устройства в Keystore
/// и не откроется на другом телефоне), а отдельный экспорт, зашифрованный
/// ПАРОЛЕМ ПОЛЬЗОВАТЕЛЯ. Поэтому копия переносима между устройствами.
///
/// Формат файла: JSON-снимок всех таблиц → AES-256 (ключ из пароля) → base64.
/// Соль и IV хранятся в шапке файла.
///
/// ФОРМАТ ДАННЫХ v2: даты сериализуются как КАЛЕНДАРНЫЕ СТРОКИ 'YYYY-MM-DD',
/// а НЕ как epoch-миллисекунды. Это критично: drift по умолчанию пишет
/// DateTime как UTC-epoch, из-за чего при переносе между телефонами в разных
/// часовых поясах день «съезжал» на ±1. Календарная строка не привязана к
/// поясу — день остаётся тем же на любом устройстве.
/// Чтение v1 (epoch) поддерживается для старых копий.
class BackupService {
  BackupService(this.db);
  final AppDatabase db;

  static const _magic = 'LEA-BACKUP-1';
  static const _dataVersion = 2;

  /// Собрать снимок всех данных в JSON-строку.
  Future<String> _exportJson() async {
    final periodDays = await db.select(db.periodDays).get();
    final logs = await db.select(db.dayLogs).get();
    final notes = await db.select(db.dayNotes).get();
    final meas = await db.select(db.measurements).get();
    final settings = await db.select(db.settingsKv).get();

    // Карта id опции → составной ключ 'catCode:optCode' (для flowOptionId и логов).
    final opts = await db.select(db.trackingOptions).get();
    final cats = await db.select(db.trackingCategories).get();
    final catIdToCode = {for (final c in cats) c.id: c.code};
    final optIdToKey = {
      for (final o in opts)
        o.id: '${catIdToCode[o.categoryId] ?? ''}:${o.code}',
    };

    final data = {
      'version': _dataVersion,
      'exportedAt': BackupDateCodec.encode(DateTime.now()),
      // periodDays: дата-строка + flowOption по составному ключу (устойчиво
      // к пересеву справочника) + isCycleStart.
      'periodDays': periodDays
          .map((e) => {
                'date': BackupDateCodec.encode(e.date),
                'flowOptionId': e.flowOptionId, // fallback v1
                'flowOptionKey':
                    e.flowOptionId == null ? null : optIdToKey[e.flowOptionId],
                'isCycleStart': e.isCycleStart,
              })
          .toList(),
      // Логи — по составному ключу catCode:optCode.
      'logs': _logsWithKeys(logs, optIdToKey),
      'notes': notes
          .map((e) => {'date': BackupDateCodec.encode(e.date), 'note': e.note})
          .toList(),
      'measurements': meas
          .map((e) => {
                'date': BackupDateCodec.encode(e.date),
                'typeCode': e.typeCode,
                'value': e.value,
                'unit': e.unit,
              })
          .toList(),
      'settings':
          settings.map((e) => {'key': e.key, 'value': e.value}).toList(),
    };
    return jsonEncode(data);
  }

  /// Логи с составным ключом опции (устойчиво к пересеву и неуникальным кодам,
  /// напр. 'positive' есть и в тестах овуляции, и в настроении).
  List<Map<String, dynamic>> _logsWithKeys(
      List<DayLog> logs, Map<int, String> optIdToKey) {
    return logs
        .map((e) => {
              'date': BackupDateCodec.encode(e.date),
              'optionId': e.optionId, // fallback v1
              'optionKey': optIdToKey[e.optionId], // основной ключ v2 (cat:opt)
              'intensity': e.intensity,
            })
        .toList();
  }

  /// Создать зашифрованный паролем бэкап (возвращает байты файла).
  Future<Uint8List> createEncryptedBackup(String password) async {
    final json = await _exportJson();

    final salt = _randomBytes(16);
    final keyBytes = _deriveKey(password, salt);
    final key = enc.Key(keyBytes);
    final iv = enc.IV(_randomBytes(16));

    final encrypter = enc.Encrypter(enc.AES(key, mode: enc.AESMode.cbc));
    final encrypted = encrypter.encrypt(json, iv: iv);

    final header = {
      'magic': _magic,
      'salt': base64.encode(salt),
      'iv': base64.encode(iv.bytes),
      'data': encrypted.base64,
    };
    return Uint8List.fromList(utf8.encode(jsonEncode(header)));
  }

  /// Восстановить из зашифрованного бэкапа.
  /// Бросает [BackupException] с понятным сообщением.
  Future<void> restoreEncryptedBackup(
      Uint8List fileBytes, String password) async {
    Map<String, dynamic> header;
    try {
      header = jsonDecode(utf8.decode(fileBytes)) as Map<String, dynamic>;
    } catch (_) {
      throw const BackupException('Это не похоже на файл резервной копии Леи.');
    }
    if (header['magic'] != _magic) {
      throw const BackupException('Это не файл резервной копии Леи.');
    }
    final salt = base64.decode(header['salt'] as String);
    final iv = enc.IV(base64.decode(header['iv'] as String));
    final keyBytes = _deriveKey(password, salt);
    final key = enc.Key(keyBytes);

    final encrypter = enc.Encrypter(enc.AES(key, mode: enc.AESMode.cbc));
    final String json;
    try {
      json = encrypter.decrypt64(header['data'] as String, iv: iv);
    } catch (_) {
      throw const BackupException('Неверный пароль.');
    }

    Map<String, dynamic> data;
    try {
      data = jsonDecode(json) as Map<String, dynamic>;
    } catch (_) {
      throw const BackupException('Неверный пароль.');
    }

    try {
      await _importData(data);
    } catch (e) {
      throw BackupException('Не удалось восстановить данные. ($e)');
    }
  }

  /// Записать данные из снимка в БД (полная замена пользовательских данных).
  Future<void> _importData(Map<String, dynamic> data) async {
    // Карта составного ключа 'catCode:optCode' → id опции на ЭТОМ устройстве.
    // Плюс запасная карта только по коду опции — для v1-бэкапов без optionKey.
    final opts = await db.select(db.trackingOptions).get();
    final cats = await db.select(db.trackingCategories).get();
    final catIdToCode = {for (final c in cats) c.id: c.code};
    final keyToId = {
      for (final o in opts)
        '${catIdToCode[o.categoryId] ?? ''}:${o.code}': o.id,
    };
    final codeToIdFallback = {for (final o in opts) o.code: o.id};

    await db.transaction(() async {
      // чистим пользовательские данные (справочник НЕ трогаем — он пересеян)
      await db.delete(db.dayLogs).go();
      await db.delete(db.dayNotes).go();
      await db.delete(db.measurements).go();
      await db.delete(db.periodDays).go();

      for (final r in (data['periodDays'] as List? ?? const [])) {
        final m = r as Map<String, dynamic>;
        // flowOption: по составному ключу (v2), иначе сырой id (v1).
        final flowKey = m['flowOptionKey'] as String?;
        int? flowId;
        if (flowKey != null) {
          flowId = keyToId[flowKey];
        } else {
          flowId = _toIntOrNull(m['flowOptionId']);
        }
        await db.into(db.periodDays).insert(
              PeriodDaysCompanion.insert(
                date: BackupDateCodec.decode(m['date']),
                flowOptionId:
                    flowId == null ? const Value.absent() : Value(flowId),
                isCycleStart: Value(m['isCycleStart'] == true),
              ),
              mode: InsertMode.insertOrIgnore,
            );
      }
      for (final r in (data['notes'] as List? ?? const [])) {
        final m = r as Map<String, dynamic>;
        await db.into(db.dayNotes).insert(
              DayNotesCompanion.insert(
                date: BackupDateCodec.decode(m['date']),
                note: _str(m['note']),
              ),
              mode: InsertMode.insertOrIgnore,
            );
      }
      for (final r in (data['measurements'] as List? ?? const [])) {
        final m = r as Map<String, dynamic>;
        await db.into(db.measurements).insert(
              MeasurementsCompanion.insert(
                date: BackupDateCodec.decode(m['date']),
                typeCode: _str(m['typeCode']),
                value: _toDouble(m['value']),
                unit: _str(m['unit']),
              ),
            );
      }
      for (final r in (data['logs'] as List? ?? const [])) {
        final m = r as Map<String, dynamic>;
        // v2: сопоставляем по составному ключу catCode:optCode (устойчиво
        // к пересеву справочника и к неуникальным кодам опций).
        // Промежуточный fallback — по одному коду опции (старый v2).
        // v1 fallback — сырой optionId.
        final key = m['optionKey'] as String?;
        int? resolvedId;
        if (key != null) {
          resolvedId = keyToId[key];
        } else if (m['optionCode'] is String) {
          resolvedId = codeToIdFallback[m['optionCode'] as String];
        } else {
          resolvedId = _toIntOrNull(m['optionId']);
        }
        if (resolvedId == null) continue; // опции нет на устройстве — пропускаем
        await db.into(db.dayLogs).insert(
              DayLogsCompanion.insert(
                date: BackupDateCodec.decode(m['date']),
                optionId: resolvedId,
                intensity: Value(_toIntOrNull(m['intensity'])),
              ),
              mode: InsertMode.insertOrIgnore,
            );
      }
      for (final r in (data['settings'] as List? ?? const [])) {
        final m = r as Map<String, dynamic>;
        await db.into(db.settingsKv).insertOnConflictUpdate(
              SettingsKvCompanion.insert(
                key: _str(m['key']),
                value: _str(m['value']),
              ),
            );
      }
    });
  }

  // безопасные приведения (значения из JSON бывают разных типов)
  static String _str(Object? v) => v?.toString() ?? '';

  static double _toDouble(Object? v) =>
      v is num ? v.toDouble() : double.tryParse(v?.toString() ?? '') ?? 0;
  static int? _toIntOrNull(Object? v) {
    if (v == null) return null;
    if (v is int) return v;
    return int.tryParse(v.toString());
  }

  // --- крипто-хелперы ---

  Uint8List _deriveKey(String password, List<int> salt) {
    // Стретчинг на sha256 (10k раундов). Для on-device бэкапа достаточно.
    var bytes = utf8.encode(password) + salt;
    Digest d = sha256.convert(bytes);
    for (var i = 0; i < 10000; i++) {
      d = sha256.convert(d.bytes);
    }
    return Uint8List.fromList(d.bytes); // 32 байта → AES-256
  }

  Uint8List _randomBytes(int n) {
    final rnd = enc.SecureRandom(n);
    return rnd.bytes;
  }
}
