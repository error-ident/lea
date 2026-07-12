import '../../core/prediction/cycle_prediction.dart';
import '../../core/prediction/cycle_history.dart';
import '../../core/prediction/predict_cycle.dart';

/// Фаза/статус дня для раскраски ячейки календаря.
enum DayPhase {
  none,
  menstrual, // фактические дни менструации
  follicular,
  ovulation,
  luteal,
  forecastPeriod, // прогнозные дни следующих месячных (пунктир)
  fertileWindow, // фертильное окно (мягко)
}

/// Определяет фазу дня. КЛЮЧЕВОЕ: фаза считается ОТНОСИТЕЛЬНО ЦИКЛА,
/// в котором лежит день, а не от одного глобального окна. Это даёт
/// правильный порядок в каждом месяце:
///   менструация → фолликулярная → овуляция → лютеиновая → (новый цикл).
///
/// Научная основа (Cleveland Clinic, UCSF, NCBI):
/// - день 1 цикла = первый день менструации;
/// - менструация: дни 1..periodLength;
/// - овуляция: за 13–15 дней до конца цикла (лютеиновая фаза, по длине цикла);
/// - фолликулярная: от конца менструации до овуляции;
/// - лютеиновая: от овуляции до конца цикла.
class DayPhaseResolver {
  DayPhaseResolver({
    required this.periodDays,
    required this.prediction,
  })  : _periodSet = periodDays
            .map((d) => DateTime(d.year, d.month, d.day))
            .toSet(),
        _cycles = buildCycleHistory(periodDays);

  final List<DateTime> periodDays;
  final CyclePrediction prediction;
  final Set<DateTime> _periodSet;
  final List<CycleRecord> _cycles;

  // Лютеиновая фаза считается динамически по длине цикла через
  // lutealForCycle(...) — единая функция с движком прогноза, чтобы
  // календарь и предсказание не рассинхронились.

  DayPhase phaseFor(DateTime date) {
    final day = DateTime(date.year, date.month, date.day);

    // 1. Фактическая менструация — всегда приоритет (что отмечено, то и есть).
    if (_periodSet.contains(day)) return DayPhase.menstrual;

    // 2. Ищем цикл, в который попадает день (по истории).
    final cycle = _cycleFor(day);
    if (cycle != null) {
      return _phaseInCycle(day, cycle);
    }

    // 3. День в будущем (после последнего известного цикла) — работает прогноз.
    return _forecastPhase(day);
  }

  /// Цикл, в диапазон [startDate..endDate] которого попадает день.
  CycleRecord? _cycleFor(DateTime day) {
    for (final c in _cycles) {
      final start = DateTime(c.startDate.year, c.startDate.month, c.startDate.day);
      final end = DateTime(c.endDate.year, c.endDate.month, c.endDate.day);
      if (!day.isBefore(start) && !day.isAfter(end)) return c;
    }
    return null;
  }

  /// Номер дня внутри цикла (1-й, 2-й, …) для отображения на клетке.
  ///
  /// Возвращает null для дней вне известных циклов (будущее за прогнозом,
  /// прошлое до первой отметки) — там номер был бы выдуманным, а врать
  /// пользователю нельзя.
  int? cycleDayFor(DateTime date) {
    final day = DateTime(date.year, date.month, date.day);
    final c = _cycleFor(day);
    if (c == null) return null;
    final start =
        DateTime(c.startDate.year, c.startDate.month, c.startDate.day);
    return day.difference(start).inDays + 1;
  }

  /// Фаза дня ВНУТРИ конкретного цикла — правильный порядок.
  DayPhase _phaseInCycle(DateTime day, CycleRecord c) {
    final start =
        DateTime(c.startDate.year, c.startDate.month, c.startDate.day);
    final dayInCycle = day.difference(start).inDays + 1; // 1-based

    // длина цикла: известная, либо медиана прогноза для текущего
    final cycleLen = c.cycleLength ?? prediction.medianCycleLength;

    // день овуляции = за (лютеиновая фаза) дней до конца цикла, но не раньше,
    // чем через день после окончания менструации (защита коротких циклов).
    // Лютеиновая фаза динамическая по длине ЭТОГО цикла.
    final rawOvulation = cycleLen - lutealForCycle(cycleLen);
    final ovulationDay =
        rawOvulation > c.periodLength ? rawOvulation : c.periodLength + 1;

    // менструация: дни 1..periodLength
    if (dayInCycle <= c.periodLength) return DayPhase.menstrual;

    // овуляция: день овуляции ±1
    if ((dayInCycle - ovulationDay).abs() <= 1) return DayPhase.ovulation;

    // фертильное окно: несколько дней перед овуляцией (мягкая подсветка)
    if (dayInCycle >= ovulationDay - 4 && dayInCycle < ovulationDay - 1) {
      return DayPhase.fertileWindow;
    }

    // фолликулярная: от конца менструации до овуляции
    if (dayInCycle < ovulationDay) return DayPhase.follicular;

    // лютеиновая: после овуляции до конца цикла
    return DayPhase.luteal;
  }

  /// Для будущих дней (после истории) — опираемся на прогноз.
  DayPhase _forecastPhase(DateTime day) {
    // прогнозные следующие месячные — пунктир
    if (prediction.nextPeriodWindow.contains(day)) {
      return DayPhase.forecastPeriod;
    }
    // окно овуляции/фертильное из прогноза
    if (prediction.ovulationWindow.contains(day)) return DayPhase.ovulation;
    if (prediction.fertileWindow.contains(day)) return DayPhase.fertileWindow;

    // между сегодня и прогнозной овуляцией — фолликулярная;
    // между овуляцией и след. месячными — лютеиновая
    final ovStart = prediction.ovulationWindow.start;
    if (day.isBefore(ovStart)) return DayPhase.follicular;
    if (day.isAfter(prediction.ovulationWindow.end) &&
        day.isBefore(prediction.nextPeriodWindow.start)) {
      return DayPhase.luteal;
    }
    return DayPhase.none;
  }
}
