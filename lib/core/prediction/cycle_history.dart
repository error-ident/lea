
/// Один цикл в истории: даты, длина, длина месячных, дни по фазам.
class CycleRecord {
  CycleRecord({
    required this.startDate,
    required this.endDate,
    required this.cycleLength,
    required this.periodLength,
    required this.isCurrent,
  });

  /// Первый день менструации этого цикла.
  final DateTime startDate;

  /// Последний день цикла (день перед следующей менструацией),
  /// либо сегодня для текущего цикла.
  final DateTime endDate;

  /// Длина цикла в днях (от старта до старта следующего).
  /// null — если это текущий (ещё не завершён) цикл.
  final int? cycleLength;

  /// Сколько дней длилась менструация в этом цикле.
  final int periodLength;

  final bool isCurrent;

  int get year => startDate.year;

  /// Оценка длины месячных: норма 2–7 дней.
  bool get periodNormal => periodLength >= 2 && periodLength <= 7;
}

/// Сводка по циклам (для верхних карточек статистики).
class CycleStats {
  CycleStats({
    required this.records,
    required this.avgCycle,
    required this.minCycle,
    required this.maxCycle,
    required this.avgPeriod,
    required this.spread,
  });

  final List<CycleRecord> records; // новые → старые
  final int? avgCycle;
  final int? minCycle;
  final int? maxCycle;
  final int? avgPeriod;
  final int? spread; // разброс длины цикла (макс-мин)

  bool get hasEnough => records.length >= 2;

  /// Регулярность по разбросу длины цикла.
  CycleRegularity get regularity {
    final s = spread;
    if (s == null) return CycleRegularity.unknown;
    if (s <= 3) return CycleRegularity.regular;
    if (s <= 7) return CycleRegularity.moderate;
    return CycleRegularity.irregular;
  }
}

enum CycleRegularity { unknown, regular, moderate, irregular }

/// Построить историю циклов из всех дней менструации.
/// [periodDays] — все отмеченные дни (в любом порядке).
List<CycleRecord> buildCycleHistory(List<DateTime> periodDays) {
  if (periodDays.isEmpty) return [];

  // нормализуем и сортируем
  final days = periodDays
      .map((d) => DateTime(d.year, d.month, d.day))
      .toSet()
      .toList()
    ..sort();

  // группируем подряд идущие дни в "менструации" (перерыв > 5 дней = новая)
  final periods = <List<DateTime>>[];
  var current = <DateTime>[days.first];
  for (var i = 1; i < days.length; i++) {
    final gap = days[i].difference(days[i - 1]).inDays;
    if (gap > 5) {
      periods.add(current);
      current = [days[i]];
    } else {
      current.add(days[i]);
    }
  }
  periods.add(current);

  final today = DateTime.now();
  final todayMid = DateTime(today.year, today.month, today.day);

  final records = <CycleRecord>[];
  for (var i = 0; i < periods.length; i++) {
    final start = periods[i].first;
    final periodLen = periods[i].length;
    final isCurrent = i == periods.length - 1;

    int? cycleLen;
    DateTime end;
    if (!isCurrent) {
      final nextStart = periods[i + 1].first;
      cycleLen = nextStart.difference(start).inDays;
      end = nextStart.subtract(const Duration(days: 1));
    } else {
      // текущий цикл: длина пока не известна, конец = сегодня
      cycleLen = null;
      end = todayMid;
    }

    records.add(CycleRecord(
      startDate: start,
      endDate: end,
      cycleLength: cycleLen,
      periodLength: periodLen,
      isCurrent: isCurrent,
    ));
  }

  // новые → старые
  return records.reversed.toList();
}

/// Посчитать сводку из истории.
CycleStats computeCycleStats(List<CycleRecord> records) {
  // длины завершённых циклов
  final lengths = records
      .where((r) => r.cycleLength != null)
      .map((r) => r.cycleLength!)
      .where((l) => l >= 10 && l <= 100)
      .toList();
  final periods = records.map((r) => r.periodLength).toList();

  int? avg, mn, mx, spread, avgP;
  if (lengths.isNotEmpty) {
    avg = (lengths.reduce((a, b) => a + b) / lengths.length).round();
    mn = lengths.reduce((a, b) => a < b ? a : b);
    mx = lengths.reduce((a, b) => a > b ? a : b);
    spread = mx - mn;
  }
  if (periods.isNotEmpty) {
    avgP = (periods.reduce((a, b) => a + b) / periods.length).round();
  }

  return CycleStats(
    records: records,
    avgCycle: avg,
    minCycle: mn,
    maxCycle: mx,
    avgPeriod: avgP,
    spread: spread,
  );
}
