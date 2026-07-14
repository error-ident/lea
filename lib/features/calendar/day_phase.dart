import '../../core/prediction/cycle_prediction.dart';
import '../../core/prediction/cycle_history.dart';
import '../../core/prediction/predict_cycle.dart';

/// Фаза/статус дня для раскраски ячейки календаря.
enum DayPhase {
  none,
  menstrual, // фактические дни менструации (подтверждённые пользователем)
  assumedPeriod, // ПРЕДПОЛАГАЕМОЕ продолжение месячных (человек отметил старт
  // и не заходил). Показываем мягче, в расчёт цикла НЕ берём — только после
  // подтверждения пользователем.
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
    this.assumedDismissedUntil,
  })  : _periodSet = periodDays
            .map((d) => DateTime(d.year, d.month, d.day))
            .toSet(),
        _cycles = buildCycleHistory(periodDays);

  final List<DateTime> periodDays;
  final CyclePrediction prediction;

  /// Дата, до которой пользователь сказал «месячные уже закончились».
  /// Если последняя отметка не позже этой даты — предполагаемые дни не строим
  /// (иначе баннер возвращался бы снова и снова).
  final DateTime? assumedDismissedUntil;

  final Set<DateTime> _periodSet;
  final List<CycleRecord> _cycles;

  /// Личная медиана длины менструации (сколько дней обычно идут месячные).
  /// Нужна, чтобы понять, сколько дней после последней отметки ЕЩЁ можно
  /// считать продолжением. Если истории нет — берём 5 (среднее по Mihm 2011).
  late final int _typicalPeriodLength = _computeTypicalPeriodLength();

  int _computeTypicalPeriodLength() {
    final lens = _cycles
        .map((c) => c.periodLength)
        .where((l) => l >= 2 && l <= 10)
        .toList()
      ..sort();
    if (lens.isEmpty) return 5;
    return lens[lens.length ~/ 2];
  }

  /// Дни, которые МЫ ПРЕДПОЛАГАЕМ как продолжение текущих месячных.
  ///
  /// Сценарий: человек отметил старт и не заходил в приложение. Раньше
  /// отмечался ровно один день, и месячные «обрывались». Теперь мы
  /// достраиваем предполагаемые дни (по личной длине менструации), но:
  ///   • показываем их ОТДЕЛЬНЫМ цветом (не как подтверждённые);
  ///   • НЕ пишем в БД и НЕ учитываем в расчёте цикла;
  ///   • при следующем входе спрашиваем подтверждение.
  /// Так мы не теряем данные, но и не выдаём догадку за факт.
  late final Set<DateTime> _assumedDays = _computeAssumedDays();

  Set<DateTime> _computeAssumedDays() {
    if (_periodSet.isEmpty) return {};

    // Последняя отмеченная дата.
    final last = _periodSet.reduce((a, b) => a.isAfter(b) ? a : b);

    // Пользователь уже сказал «месячные закончились» для этой серии —
    // не достраиваем и не показываем баннер повторно.
    final dismissed = assumedDismissedUntil;
    if (dismissed != null && !last.isAfter(dismissed)) return {};

    // Считаем, сколько дней подряд уже отмечено, заканчивая последней датой.
    var confirmedStreak = 0;
    var cursor = last;
    while (_periodSet.contains(cursor)) {
      confirmedStreak++;
      cursor = cursor.subtract(const Duration(days: 1));
    }

    // Если подтверждённых дней уже больше типичной длины — не достраиваем.
    if (confirmedStreak >= _typicalPeriodLength) return {};

    final out = <DateTime>{};
    // Достраиваем от дня ПОСЛЕ последней отметки, но не дальше сегодня и не
    // дольше типичной длины менструации.
    for (var i = 1; i <= _typicalPeriodLength - confirmedStreak; i++) {
      final d = last.add(Duration(days: i));
      if (_periodSet.contains(d)) continue; // уже подтверждён
      out.add(d);
    }
    return out;
  }


  Set<DateTime> _pastAssumed() {
    final now = DateTime.now();
    final todayDay = DateTime(now.year, now.month, now.day);
    return _assumedDays.where((d) => d.isBefore(todayDay)).toSet();
  }

  /// Есть ли ПРОШЛЫЕ предполагаемые дни, которые стоит попросить подтвердить.
  /// Будущие дни в баннер не идут — они ещё не наступили.
  bool get hasAssumedDays => _pastAssumed().isNotEmpty;

  /// Прошлые предполагаемые дни (для баннера подтверждения).
  List<DateTime> get assumedDays => _pastAssumed().toList()..sort();

  // Лютеиновая фаза считается динамически по длине цикла через
  // lutealForCycle(...) — единая функция с движком прогноза, чтобы
  // календарь и предсказание не рассинхронились.

  DayPhase phaseFor(DateTime date) {
    final day = DateTime(date.year, date.month, date.day);

    // 1. Фактическая менструация — всегда приоритет (что отмечено, то и есть).
    if (_periodSet.contains(day)) return DayPhase.menstrual;

    // 2. Предполагаемое продолжение месячных (не подтверждено пользователем).
    if (_assumedDays.contains(day)) return DayPhase.assumedPeriod;

    // 3. Ищем цикл, в который попадает день (по истории).
    final cycle = _cycleFor(day);
    if (cycle != null) {
      return _phaseInCycle(day, cycle);
    }

    // 4. День в будущем (после последнего известного цикла) — работает прогноз.
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
