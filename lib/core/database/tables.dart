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
