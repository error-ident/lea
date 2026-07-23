import 'package:drift/drift.dart';

/// Типы категорий трекинга.
enum TrackingType { singleChoice, multiChoice, toggle, numeric }

/// Дни менструации. Из них вычисляются длины циклов для predictCycle.
class PeriodDays extends Table {
  IntColumn get id => integer().autoIncrement()();

  /// День (хранится как дата без времени).
  DateTimeColumn get date => dateTime()();

  /// Обильность — ссылка на опцию справочника (discharge/flow), опционально.
  IntColumn get flowOptionId =>
      integer().nullable().references(TrackingOptions, #id)();

  /// true = первый день цикла (опора расчёта).
  BoolColumn get isCycleStart => boolean().withDefault(const Constant(false))();

  DateTimeColumn get createdAt =>
      dateTime().withDefault(currentDateAndTime)();

  @override
  List<Set<Column>> get uniqueKeys => [
        {date},
      ];
}

/// Категории трекинга (гибкий справочник, скрываемые).
class TrackingCategories extends Table {
  IntColumn get id => integer().autoIncrement()();

  /// Машинный код: mood, symptoms, discharge, sex, digestion, activity,
  /// contraception, pills, ovulation_test, other, weight, bbt, water.
  TextColumn get code => text().unique()();

  /// Ключ локализации названия.
  TextColumn get titleKey => text()();

  /// Имя Rive/иконки.
  TextColumn get iconRef => text().withDefault(const Constant(''))();

  IntColumn get type => intEnum<TrackingType>()();

  BoolColumn get isBuiltIn => boolean().withDefault(const Constant(true))();
  BoolColumn get isHidden => boolean().withDefault(const Constant(false))();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
}

/// Опции внутри категории.
class TrackingOptions extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get categoryId =>
      integer().references(TrackingCategories, #id)();

  TextColumn get code => text()();
  TextColumn get titleKey => text()();
  TextColumn get iconRef => text().nullable()();
  TextColumn get colorHex => text().nullable()();

  BoolColumn get isBuiltIn => boolean().withDefault(const Constant(true))();
  BoolColumn get isHidden => boolean().withDefault(const Constant(false))();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
}

/// Отметки опций по дням (многие-ко-многим день↔опция).
class DayLogs extends Table {
  IntColumn get id => integer().autoIncrement()();
  DateTimeColumn get date => dateTime()();
  IntColumn get optionId => integer().references(TrackingOptions, #id)();

  /// Опциональная интенсивность (напр. сила симптома 1–3).
  IntColumn get intensity => integer().nullable()();

  DateTimeColumn get createdAt =>
      dateTime().withDefault(currentDateAndTime)();

  @override
  List<Set<Column>> get uniqueKeys => [
        {date, optionId},
      ];
}

/// Свободная заметка на день.
class DayNotes extends Table {
  IntColumn get id => integer().autoIncrement()();
  DateTimeColumn get date => dateTime()();
  TextColumn get note => text()();
  DateTimeColumn get updatedAt =>
      dateTime().withDefault(currentDateAndTime)();

  @override
  List<Set<Column>> get uniqueKeys => [
        {date},
      ];
}

/// Числовые замеры (вес, БТ, вода). typeCode = код категории numeric.
class Measurements extends Table {
  IntColumn get id => integer().autoIncrement()();
  DateTimeColumn get date => dateTime()();

  /// Код категории numeric: weight / bbt / water.
  TextColumn get typeCode => text()();
  RealColumn get value => real()();
  TextColumn get unit => text()();

  DateTimeColumn get createdAt =>
      dateTime().withDefault(currentDateAndTime)();
}

/// Настройки — ключ-значение.
class SettingsKv extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();

  @override
  Set<Column> get primaryKey => {key};
}

/// Лекарство/препарат, который человек принимает.
///
/// Отдельная сущность, а не просто напоминание: у лекарства есть название,
/// расписание (может быть несколько приёмов в день), период курса и
/// история приёмов. Это нужно, чтобы видеть соблюдение курса и связывать
/// приём с симптомами (например: начала пить железо → ушла ли усталость).
class Medications extends Table {
  IntColumn get id => integer().autoIncrement()();

  /// Название препарата, как его называет человек.
  TextColumn get name => text()();

  /// Дозировка — свободный текст («1 таблетка», «25 мг»). Необязательно.
  TextColumn get dosage => text().withDefault(const Constant(''))();

  /// Времена приёма через запятую в формате HH:mm — «09:00,21:00».
  /// Строкой, а не отдельной таблицей: приёмов в день редко больше 4,
  /// а так проще читать и редактировать.
  TextColumn get times => text().withDefault(const Constant(''))();

  /// Слать ли напоминания в эти времена.
  BoolColumn get remind => boolean().withDefault(const Constant(true))();

  /// Начало приёма. Конец — null, если принимается постоянно.
  DateTimeColumn get startDate => dateTime()();
  DateTimeColumn get endDate => dateTime().nullable()();

  /// Курс завершён вручную — не показываем в активных, но историю храним.
  BoolColumn get archived => boolean().withDefault(const Constant(false))();

  DateTimeColumn get createdAt =>
      dateTime().withDefault(currentDateAndTime)();
}

/// Факт приёма лекарства в конкретный день и время.
///
/// Запись есть = принято. Записи нет = не отмечено (это НЕ то же самое,
/// что «пропущено»: человек мог просто не отметить). Мы не додумываем
/// за пользователя и не укоряем — просто показываем, что отмечено.
class MedicationIntakes extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get medicationId =>
      integer().references(Medications, #id, onDelete: KeyAction.cascade)();

  /// День приёма (без времени).
  DateTimeColumn get date => dateTime()();

  /// Какое именно время из расписания отмечено — «09:00».
  /// Позволяет различать утренний и вечерний приём одного лекарства.
  TextColumn get slot => text()();

  DateTimeColumn get takenAt =>
      dateTime().withDefault(currentDateAndTime)();

  @override
  List<String> get customConstraints =>
      ['UNIQUE (medication_id, date, slot)'];
}
