import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqlite3/open.dart';
import 'package:sqlcipher_flutter_libs/sqlcipher_flutter_libs.dart';

import 'tables.dart';
import 'seed_data.dart';

export 'tables.dart' show TrackingType;

part 'app_database.g.dart';

@DriftDatabase(
  tables: [
    PeriodDays,
    TrackingCategories,
    TrackingOptions,
    DayLogs,
    DayNotes,
    Measurements,
    SettingsKv,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.e);

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async {
          await m.createAll();
          await _seed();
        },
        beforeOpen: (details) async {
          await customStatement('PRAGMA foreign_keys = ON');
        },
      );

  /// Заполнение справочников встроенными категориями при первом запуске.
  Future<void> _seed() async {
    for (final cat in kSeedCategories) {
      final catId = await into(trackingCategories).insert(
        TrackingCategoriesCompanion.insert(
          code: cat.code,
          titleKey: cat.titleKey,
          iconRef: Value(cat.iconRef),
          type: cat.type,
          sortOrder: Value(cat.sortOrder),
        ),
      );
      for (var i = 0; i < cat.options.length; i++) {
        final opt = cat.options[i];
        await into(trackingOptions).insert(
          TrackingOptionsCompanion.insert(
            categoryId: catId,
            code: opt.code,
            titleKey: opt.titleKey,
            iconRef: Value(opt.iconRef),
            colorHex: Value(opt.colorHex),
            sortOrder: Value(i),
          ),
        );
      }
    }
  }

  // ---- Цикл ----

  /// Даты начала циклов — вычисляются автоматически из дней месячных.
  /// Старт цикла = день менструации, перед которым был перерыв > 5 дней
  /// (т.е. это новая менструация, а не продолжение текущей).
  Future<List<DateTime>> cycleStartDates() async {
    final rows = await (select(periodDays)
          ..orderBy([(t) => OrderingTerm.asc(t.date)]))
        .get();
    final days = rows.map((r) => DateTime(r.date.year, r.date.month, r.date.day)).toList();
    if (days.isEmpty) return [];

    final starts = <DateTime>[days.first];
    for (var i = 1; i < days.length; i++) {
      final gap = days[i].difference(days[i - 1]).inDays;
      if (gap > 5) starts.add(days[i]); // перерыв → новая менструация
    }
    return starts;
  }

  /// Реактивный поток всех дней менструации (для календаря).
  Stream<List<PeriodDay>> watchPeriodDays() => select(periodDays).watch();

  /// Все даты, у которых есть хоть какая-то запись (лог/заметка/замер).
  /// Для точек-меток на календаре.
  Future<Set<DateTime>> datesWithEntries() async {
    final logs = await select(dayLogs).get();
    final notes = await select(dayNotes).get();
    final meas = await select(measurements).get();
    final set = <DateTime>{};
    for (final l in logs) {
      set.add(DateTime(l.date.year, l.date.month, l.date.day));
    }
    for (final n in notes) {
      set.add(DateTime(n.date.year, n.date.month, n.date.day));
    }
    for (final m in meas) {
      set.add(DateTime(m.date.year, m.date.month, m.date.day));
    }
    return set;
  }

  /// Один день менструации вкл/выкл (для ручной правки на календаре).
  Future<void> togglePeriodDay(DateTime date) async {
    final day = DateTime(date.year, date.month, date.day);
    final existing = await (select(periodDays)
          ..where((t) => t.date.equals(day)))
        .getSingleOrNull();
    if (existing != null) {
      await (delete(periodDays)..where((t) => t.date.equals(day))).go();
    } else {
      await into(periodDays).insert(
        PeriodDaysCompanion.insert(date: day),
      );
    }
  }

  /// Отметить менструацию на [lengthDays] подряд от [start].
  /// Используется в онбординге и при отметке начала месячных.
  Future<void> markPeriodRange(DateTime start, int lengthDays) async {
    final s = DateTime(start.year, start.month, start.day);
    // одна транзакция — все дни записываются разом (без поочерёдной перерисовки)
    await transaction(() async {
      for (var i = 0; i < lengthDays; i++) {
        final d = s.add(Duration(days: i));
        await into(periodDays).insertOnConflictUpdate(
          PeriodDaysCompanion.insert(date: DateTime(d.year, d.month, d.day)),
        );
      }
    });
  }

  /// Отметить менструацию в диапазоне между двумя датами (включительно).
  /// Для ручного выделения истории: тап начала → тап конца → заливка.
  Future<void> markPeriodBetween(DateTime a, DateTime b) async {
    var start = DateTime(a.year, a.month, a.day);
    var end = DateTime(b.year, b.month, b.day);
    if (end.isBefore(start)) {
      final t = start;
      start = end;
      end = t;
    }
    final days = end.difference(start).inDays + 1;
    await markPeriodRange(start, days);
  }

  /// Совместимость: отметить один день (старт игнорируется — старты считаются авто).
  Future<void> setPeriodDay(DateTime date, {bool isStart = false}) async {
    final day = DateTime(date.year, date.month, date.day);
    await into(periodDays).insertOnConflictUpdate(
      PeriodDaysCompanion.insert(date: day),
    );
  }

  Future<void> removePeriodDay(DateTime date) async {
    final day = DateTime(date.year, date.month, date.day);
    await (delete(periodDays)..where((t) => t.date.equals(day))).go();
  }

  // ---- Интенсивность менструации (flowOptionId у дня) ----

  /// Варианты интенсивности для быстрого выбора при отметке дня.
  ///
  /// ВАЖНО: 'spotting' (мазня) СПЕЦИАЛЬНО исключена. Медицински это не
  /// «очень слабые месячные», а отдельное явление: мазня может быть в
  /// середине цикла (например, около овуляции) и не должна отмечать день
  /// как менструацию или влиять на расчёт цикла. Она остаётся обычной
  /// записью в дневнике дня.
  Future<List<TrackingOption>> flowIntensityOptions() async {
    final cat = await (select(trackingCategories)
          ..where((t) => t.code.equals('flow')))
        .getSingleOrNull();
    if (cat == null) return [];
    final opts = await (select(trackingOptions)
          ..where((t) => t.categoryId.equals(cat.id))
          ..orderBy([(t) => OrderingTerm(expression: t.sortOrder)]))
        .get();
    return opts.where((o) => o.code != 'spotting').toList();
  }

  /// Текущая интенсивность дня (null — не задана, это нормально:
  /// пользователь не обязан её указывать).
  Future<int?> flowForDay(DateTime date) async {
    final day = DateTime(date.year, date.month, date.day);
    final row = await (select(periodDays)..where((t) => t.date.equals(day)))
        .getSingleOrNull();
    return row?.flowOptionId;
  }

  /// Задать/снять интенсивность дня. Повторный выбор того же варианта
  /// снимает его (null). День при этом остаётся отмеченным.
  Future<void> setFlowForDay(DateTime date, int? optionId) async {
    final day = DateTime(date.year, date.month, date.day);
    await (update(periodDays)..where((t) => t.date.equals(day))).write(
      PeriodDaysCompanion(flowOptionId: Value(optionId)),
    );
  }

  /// Подтвердить предполагаемые дни месячных (пользователь сказал «да, шли»).
  /// Записываем их как настоящие дни менструации.
  Future<void> confirmAssumedDays(List<DateTime> days) async {
    await batch((b) {
      for (final d in days) {
        final day = DateTime(d.year, d.month, d.day);
        b.insert(
          periodDays,
          PeriodDaysCompanion.insert(date: day),
          mode: InsertMode.insertOrIgnore,
        );
      }
    });
  }

  // ---- Счётчики средств гигиены (прокладки / тампоны / чаша) ----
  //
  // Храним в measurements (date + typeCode + value) — новая таблица не нужна.
  // typeCode: 'pads' | 'tampons' | 'cup'. Для чаши value = число опорожнений.
  //
  // Зачем: расход — объективный показатель обильности, точнее субъективного
  // «скудно/обильно». Плюс полезно в поездках и походах.

  Future<Map<String, int>> hygieneForDay(DateTime date) async {
    final day = DateTime(date.year, date.month, date.day);
    final rows = await (select(measurements)
          ..where((t) => t.date.equals(day))
          ..where((t) => t.typeCode.isIn(const ['pads', 'tampons', 'cup'])))
        .get();
    return {for (final r in rows) r.typeCode: r.value.round()};
  }

  /// Задать количество. 0 — удаляем запись (чтобы не копить нули).
  Future<void> setHygieneCount(
      DateTime date, String typeCode, int count) async {
    final day = DateTime(date.year, date.month, date.day);
    await (delete(measurements)
          ..where((t) => t.date.equals(day))
          ..where((t) => t.typeCode.equals(typeCode)))
        .go();
    if (count <= 0) return;
    await into(measurements).insert(
      MeasurementsCompanion.insert(
        date: day,
        typeCode: typeCode,
        value: count.toDouble(),
        unit: 'шт',
      ),
    );
  }

  /// Карта «день → код интенсивности» для раскраски календаря градациями.
  /// Дни без заданной интенсивности в карту не попадают (это нормально —
  /// интенсивность необязательна, такие дни красятся базовым цветом).
  Future<Map<DateTime, String>> flowByDate() async {
    final q = select(periodDays).join([
      leftOuterJoin(
        trackingOptions,
        trackingOptions.id.equalsExp(periodDays.flowOptionId),
      ),
    ]);
    final rows = await q.get();
    final out = <DateTime, String>{};
    for (final r in rows) {
      final pd = r.readTable(periodDays);
      final opt = r.readTableOrNull(trackingOptions);
      if (opt == null) continue;
      final d = DateTime(pd.date.year, pd.date.month, pd.date.day);
      out[d] = opt.code;
    }
    return out;
  }

  // ---- Справочники ----

  /// Видимые категории (не скрытые), по порядку.
  Future<List<TrackingCategory>> visibleCategories() {
    final q = select(trackingCategories)
      ..where((t) => t.isHidden.equals(false))
      ..orderBy([(t) => OrderingTerm.asc(t.sortOrder)]);
    return q.get();
  }

  Future<List<TrackingOption>> optionsForCategory(int categoryId) {
    final q = select(trackingOptions)
      ..where((t) =>
          t.categoryId.equals(categoryId) & t.isHidden.equals(false))
      ..orderBy([(t) => OrderingTerm.asc(t.sortOrder)]);
    return q.get();
  }

  // ---- Логи дня ----

  Future<List<DayLog>> logsForDate(DateTime date) {
    final day = DateTime(date.year, date.month, date.day);
    return (select(dayLogs)..where((t) => t.date.equals(day))).get();
  }

  /// Набор id выбранных опций за день — удобно для подсветки чипов.
  Future<Set<int>> selectedOptionIds(DateTime date) async {
    final logs = await logsForDate(date);
    return logs.map((l) => l.optionId).toSet();
  }

  /// Все опции всех категорий разом (мапа categoryId -> опции).
  /// Чтобы не дёргать БД в цикле на экране ввода.
  Future<Map<int, List<TrackingOption>>> allOptionsByCategory() async {
    final opts = await (select(trackingOptions)
          ..where((t) => t.isHidden.equals(false))
          ..orderBy([(t) => OrderingTerm.asc(t.sortOrder)]))
        .get();
    final map = <int, List<TrackingOption>>{};
    for (final o in opts) {
      map.putIfAbsent(o.categoryId, () => []).add(o);
    }
    return map;
  }

  /// Заметка за день (или null).
  Future<DayNote?> noteForDate(DateTime date) {
    final day = DateTime(date.year, date.month, date.day);
    return (select(dayNotes)..where((t) => t.date.equals(day)))
        .getSingleOrNull();
  }

  /// Замеры за день.
  Future<List<Measurement>> measurementsForDate(DateTime date) {
    final day = DateTime(date.year, date.month, date.day);
    return (select(measurements)..where((t) => t.date.equals(day))).get();
  }

  /// Установить/обновить замер за день (один на тип в день — перезаписываем).
  Future<void> setMeasurement(
    DateTime date,
    String typeCode,
    double value,
    String unit,
  ) async {
    final day = DateTime(date.year, date.month, date.day);
    await (delete(measurements)
          ..where((t) => t.date.equals(day) & t.typeCode.equals(typeCode)))
        .go();
    await into(measurements).insert(
      MeasurementsCompanion.insert(
        date: day,
        typeCode: typeCode,
        value: value,
        unit: unit,
      ),
    );
  }

  Future<void> toggleLog(DateTime date, int optionId, {int? intensity}) async {
    final day = DateTime(date.year, date.month, date.day);
    final existing = await (select(dayLogs)
          ..where((t) => t.date.equals(day) & t.optionId.equals(optionId)))
        .getSingleOrNull();
    if (existing != null) {
      await (delete(dayLogs)..where((t) => t.id.equals(existing.id))).go();
    } else {
      await into(dayLogs).insert(
        DayLogsCompanion.insert(
          date: day,
          optionId: optionId,
          intensity: Value(intensity),
        ),
      );
    }
  }

  // ---- Заметки ----

  Future<void> setNote(DateTime date, String text) async {
    final day = DateTime(date.year, date.month, date.day);
    await into(dayNotes).insertOnConflictUpdate(
      DayNotesCompanion.insert(date: day, note: text),
    );
  }

  // ---- Замеры ----

  Future<void> addMeasurement(
    DateTime date,
    String typeCode,
    double value,
    String unit,
  ) async {
    final day = DateTime(date.year, date.month, date.day);
    await into(measurements).insert(
      MeasurementsCompanion.insert(
        date: day,
        typeCode: typeCode,
        value: value,
        unit: unit,
      ),
    );
  }

  // ---- Настройки ----

  Future<String?> getSetting(String key) async {
    final row = await (select(settingsKv)..where((t) => t.key.equals(key)))
        .getSingleOrNull();
    return row?.value;
  }

  Future<void> setSetting(String key, String value) async {
    await into(settingsKv).insertOnConflictUpdate(
      SettingsKvCompanion.insert(key: key, value: value),
    );
  }
}

/// Настройка SQLCipher: подменяет sqlite на шифрованную сборку.
/// Нужна и на главном изолейте, и на фоновом (createInBackground его создаёт).
void _setupSqlCipher() {
  open.overrideFor(OperatingSystem.android, openCipherOnAndroid);
}

/// Открытие зашифрованной БД (SQLCipher).
/// [encryptionKey] берётся из flutter_secure_storage (Android Keystore).
LazyDatabase openEncryptedDatabase(String encryptionKey) {
  return LazyDatabase(() async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File(p.join(dir.path, 'lea.db'));

    // На главном изолейте — до открытия БД.
    _setupSqlCipher();

    return NativeDatabase.createInBackground(
      file,
      // КРИТИЧНО: фоновый изолейт не наследует override — настраиваем и там.
      isolateSetup: () async {
        _setupSqlCipher();
      },
      setup: (raw) {
        // Сначала проверяем, что это действительно SQLCipher.
        final cipher = raw.select('PRAGMA cipher_version;');
        if (cipher.isEmpty) {
          throw StateError(
            'SQLCipher не активен — проверьте зависимость sqlcipher_flutter_libs',
          );
        }
        final escaped = encryptionKey.replaceAll("'", "''");
        raw.execute("PRAGMA key = '$escaped';");
      },
    );
  });
}
