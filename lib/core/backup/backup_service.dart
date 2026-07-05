import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:drift/drift.dart';
import 'package:encrypt/encrypt.dart' as enc;

import '../database/app_database.dart';

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
/// Формат файла: JSON-снимок всех таблиц → AES-256 (ключ из пароля через PBKDF-подобный
/// хэш с солью) → base64. Соль и IV хранятся в шапке файла.
class BackupService {
  BackupService(this.db);
  final AppDatabase db;

  static const _magic = 'LEA-BACKUP-1';

  /// Собрать снимок всех данных в JSON-строку.
  Future<String> _exportJson() async {
    final periodDays = await db.select(db.periodDays).get();
    final categories = await db.select(db.trackingCategories).get();
    final options = await db.select(db.trackingOptions).get();
    final logs = await db.select(db.dayLogs).get();
    final notes = await db.select(db.dayNotes).get();
    final meas = await db.select(db.measurements).get();
    final settings = await db.select(db.settingsKv).get();

    final data = {
      'version': 1,
      'exportedAt': DateTime.now().toIso8601String(),
      'periodDays': periodDays.map((e) => e.toJson()).toList(),
      'categories': categories.map((e) => e.toJson()).toList(),
      'options': options.map((e) => e.toJson()).toList(),
      'logs': logs.map((e) => e.toJson()).toList(),
      'notes': notes.map((e) => e.toJson()).toList(),
      'measurements': meas.map((e) => e.toJson()).toList(),
      'settings': settings.map((e) => e.toJson()).toList(),
    };
    return jsonEncode(data);
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

    // Шапка (читаемый префикс) + соль + iv + шифртекст, всё base64.
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
    await db.transaction(() async {
      // чистим пользовательские данные (справочник пересидится при необходимости)
      await db.delete(db.dayLogs).go();
      await db.delete(db.dayNotes).go();
      await db.delete(db.measurements).go();
      await db.delete(db.periodDays).go();

      for (final r in (data['periodDays'] as List? ?? const [])) {
        final m = r as Map<String, dynamic>;
        await db.into(db.periodDays).insert(
              PeriodDaysCompanion.insert(
                date: _parseDate(m['date']),
                isCycleStart: Value(m['isCycleStart'] == true),
              ),
            );
      }
      for (final r in (data['notes'] as List? ?? const [])) {
        final m = r as Map<String, dynamic>;
        await db.into(db.dayNotes).insert(
              DayNotesCompanion.insert(
                date: _parseDate(m['date']),
                note: _str(m['note']),
              ),
            );
      }
      for (final r in (data['measurements'] as List? ?? const [])) {
        final m = r as Map<String, dynamic>;
        await db.into(db.measurements).insert(
              MeasurementsCompanion.insert(
                date: _parseDate(m['date']),
                typeCode: _str(m['typeCode']),
                value: _toDouble(m['value']),
                unit: _str(m['unit']),
              ),
            );
      }
      for (final r in (data['logs'] as List? ?? const [])) {
        final m = r as Map<String, dynamic>;
        await db.into(db.dayLogs).insert(
              DayLogsCompanion.insert(
                date: _parseDate(m['date']),
                optionId: _toInt(m['optionId']),
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

  /// Разбор даты: drift сериализует DateTime как Unix-секунды/миллисекунды
  /// (число), но возможна и ISO-строка. Понимаем оба варианта.
  static DateTime _parseDate(Object? v) {
    if (v is int) {
      // эвристика: > 10^12 — миллисекунды, иначе секунды
      return v > 100000000000
          ? DateTime.fromMillisecondsSinceEpoch(v)
          : DateTime.fromMillisecondsSinceEpoch(v * 1000);
    }
    final s = v?.toString() ?? '';
    final asInt = int.tryParse(s);
    if (asInt != null) {
      return asInt > 100000000000
          ? DateTime.fromMillisecondsSinceEpoch(asInt)
          : DateTime.fromMillisecondsSinceEpoch(asInt * 1000);
    }
    return DateTime.parse(s);
  }
  static double _toDouble(Object? v) =>
      v is num ? v.toDouble() : double.tryParse(v?.toString() ?? '') ?? 0;
  static int _toInt(Object? v) =>
      v is int ? v : int.tryParse(v?.toString() ?? '') ?? 0;
  static int? _toIntOrNull(Object? v) {
    if (v == null) return null;
    if (v is int) return v;
    return int.tryParse(v.toString());
  }

  // --- крипто-хелперы ---

  Uint8List _deriveKey(String password, List<int> salt) {
    // Простой стретчинг на sha256 (несколько раундов). Для on-device бэкапа
    // достаточно; при желании заменить на pbkdf2/argon2.
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
