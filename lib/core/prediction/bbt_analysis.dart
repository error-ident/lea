import 'dart:math' as math;

/// Подтверждение овуляции по базальной температуре (BBT).
///
/// ЗАЧЕМ. Календарный прогноз вычисляет овуляцию как «конец цикла минус
/// лютеиновая фаза 13–15 дней». Но лютеиновая фаза у конкретного человека
/// своя, и диапазон 13–15 — это популяционная оценка. BBT позволяет
/// измерить её ЛИЧНОЕ значение: после овуляции прогестерон поднимает
/// базальную температуру, и этот сдвиг виден в данных.
///
/// ЧТО ЭТО ДАЁТ. Накопив несколько циклов с подтверждённой овуляцией, мы
/// считаем личную длину лютеиновой фазы и подставляем её вместо
/// диапазона. Все последующие прогнозы становятся точнее — и это работает
/// полностью офлайн, без носимых устройств.
///
/// ЧЕГО ЭТО НЕ ДАЁТ. BBT подтверждает овуляцию ПОСТФАКТУМ: подъём виден
/// только после того, как овуляция произошла. Предсказать овуляцию вперёд
/// температура не может — для этого нужны ЛГ-тесты (слой 4).
///
/// МЕТОДИКА. Классическое правило «3 через 6» из методов распознавания
/// фертильности: три подряд измерения выше максимума предыдущих шести,
/// с порогом на шум измерения. День овуляции — последний день ДО подъёма.
abstract final class BbtAnalysis {
  /// Сколько предыдущих дней берём как «базовую линию».
  static const int baselineDays = 6;

  /// Сколько подряд повышенных дней подтверждают сдвиг.
  static const int riseDays = 3;

  /// Минимальное превышение над базовой линией, °C.
  ///
  /// Подъём после овуляции обычно 0.2–0.5 °C. Порог 0.15 отсекает шум
  /// бытового термометра (±0.05–0.1) и естественные колебания, но не
  /// теряет реальный сдвиг.
  static const double minRise = 0.15;

  /// Найти день овуляции в цикле по ряду измерений.
  ///
  /// [byDayInCycle] — температура по дню цикла (1-й, 2-й…). Пропуски
  /// допустимы: дни без измерения просто отсутствуют в карте.
  ///
  /// Возвращает номер дня цикла, в который овуляция ПРОИЗОШЛА, или null,
  /// если подтверждённого сдвига нет (мало данных, нет подъёма, шум).
  static int? detectOvulationDay(Map<int, double> byDayInCycle) {
    if (byDayInCycle.length < baselineDays + riseDays) return null;

    final days = byDayInCycle.keys.toList()..sort();

    // Идём по возможным точкам начала подъёма.
    for (final start in days) {
      // Базовая линия — baselineDays измерений строго ДО точки подъёма.
      final baseline = days
          .where((d) => d < start)
          .toList()
          .reversed
          .take(baselineDays)
          .map((d) => byDayInCycle[d]!)
          .toList();
      if (baseline.length < baselineDays) continue;

      final threshold = baseline.reduce(math.max) + minRise;

      // Проверяем riseDays подряд ИДУЩИХ ПО ЦИКЛУ дней с измерениями.
      final rise = days.where((d) => d >= start).take(riseDays).toList();
      if (rise.length < riseDays) break;

      // Подъём должен быть непрерывным по дням цикла (без больших дыр),
      // иначе «три дня» могут растянуться на две недели.
      if (rise.last - rise.first > riseDays + 1) continue;

      final allAbove = rise.every((d) => byDayInCycle[d]! >= threshold);
      if (!allAbove) continue;

      // Овуляция — последний день ДО подъёма.
      final before = days.where((d) => d < start);
      if (before.isEmpty) continue;
      return before.last;
    }
    return null;
  }

  /// Личная длина лютеиновой фазы по завершённому циклу.
  ///
  /// Считается как «длина цикла минус день овуляции»: от овуляции до
  /// начала следующих месячных.
  static int? lutealLengthForCycle({
    required Map<int, double> byDayInCycle,
    required int cycleLength,
  }) {
    final ov = detectOvulationDay(byDayInCycle);
    if (ov == null) return null;
    final luteal = cycleLength - ov;
    // Отсекаем неправдоподобное: лютеиновая фаза короче 9 или длиннее 18
    // дней почти наверняка означает ошибку детекции, а не физиологию.
    if (luteal < 9 || luteal > 18) return null;
    return luteal;
  }

  /// Личная лютеиновая фаза по нескольким циклам — медиана.
  ///
  /// Медиана, а не среднее: один сбойный цикл (болезнь, плохие измерения)
  /// не должен сдвигать оценку.
  ///
  /// Возвращает null, если подтверждённых циклов меньше [minCycles] —
  /// на одном цикле делать вывод нельзя.
  static int? personalLutealLength(
    List<int> confirmedLutealLengths, {
    int minCycles = 2,
  }) {
    if (confirmedLutealLengths.length < minCycles) return null;
    final s = [...confirmedLutealLengths]..sort();
    final n = s.length;
    if (n.isOdd) return s[n ~/ 2];
    return ((s[n ~/ 2 - 1] + s[n ~/ 2]) / 2).round();
  }
}
