import 'package:flutter/foundation.dart';

/// Диапазон дат (включительно).
@immutable
class DateRange {
  const DateRange(this.start, this.end);
  final DateTime start;
  final DateTime end;

  bool contains(DateTime d) {
    final day = DateUtilsLite.dateOnly(d);
    return !day.isBefore(DateUtilsLite.dateOnly(start)) &&
        !day.isAfter(DateUtilsLite.dateOnly(end));
  }

  @override
  String toString() => 'DateRange($start … $end)';
}

/// Уровень уверенности прогноза — для выбора формулировок в UI.
enum ConfidenceLevel {
  /// Мало истории или высокая вариативность. UI: «примерно», широкий диапазон.
  low,

  /// Достаточно данных, умеренная вариативность.
  medium,

  /// Много истории, регулярный цикл. UI: уверенный, узкий диапазон.
  high,
}

/// Результат прогноза. Всё вычисляется на лету, нигде не хранится.
@immutable
class CyclePrediction {
  const CyclePrediction({
    required this.nextPeriodStart,
    required this.marginDays,
    required this.ovulationWindow,
    required this.fertileWindow,
    required this.confidence,
    required this.cyclesUsed,
    required this.medianCycleLength,
    this.isUncertain = false,
  });

  /// Центральная (наиболее вероятная) дата начала следующих месячных.
  final DateTime nextPeriodStart;

  /// ± размер диапазона в днях («размытый диапазон» на календаре).
  final int marginDays;

  /// Окно овуляции (через лютеиновую фазу).
  final DateRange ovulationWindow;

  /// Фертильное окно (овуляция −5 … +1).
  final DateRange fertileWindow;

  /// Уровень уверенности — управляет формулировками UI.
  final ConfidenceLevel confidence;

  /// Сколько циклов учтено (для «прогноз точнее — N циклов»).
  final int cyclesUsed;

  /// Использованная медианная длина цикла.
  final int medianCycleLength;

  /// true, если цикл нерегулярный / данных мало — UI смягчает обещания.
  final bool isUncertain;

  /// Прогнозный диапазон начала месячных (центр ± margin).
  DateRange get nextPeriodWindow => DateRange(
        nextPeriodStart.subtract(Duration(days: marginDays)),
        nextPeriodStart.add(Duration(days: marginDays)),
      );
}

/// Утилита работы с датами без времени (день как точка).
abstract final class DateUtilsLite {
  static DateTime dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  static int daysBetween(DateTime a, DateTime b) =>
      dateOnly(b).difference(dateOnly(a)).inDays;
}
