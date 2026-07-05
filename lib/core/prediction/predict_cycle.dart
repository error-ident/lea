import 'dart:math' as math;
import 'cycle_prediction.dart';

/// Константы из спеки (данные JMIR, когорта 1.5 млн женщин).
abstract final class CycleConstants {
  /// Лютеиновая фаза — почти константа (по данным пик 14–15 дней).
  /// Овуляция = следующие месячные − это число.
  static const int lutealPhaseDays = 14;

  /// Фертильное окно: овуляция −5 … +1 (сперматозоиды живут ~5 дней, яйцеклетка ~1).
  static const int fertileBeforeOvulation = 5;
  static const int fertileAfterOvulation = 1;

  /// Сколько последних циклов берём для медианы (rhythm-метод: ≤6).
  static const int maxCyclesForMedian = 6;

  /// Популяционный априор длины цикла (медиана 28, но слабый — только 16% женщин).
  static const int populationDefaultCycle = 28;

  /// Границы правдоподобной длины цикла (91% женщин: 21–35).
  static const int minPlausibleCycle = 10;
  static const int maxPlausibleCycle = 100;

  /// Популяционная погрешность при холодном старте (широкая).
  static const int coldStartMargin = 5;

  /// Пороги вариативности (стд. отклонение длины), из распределения JMIR:
  /// 25% женщин — вариация 0–1.5 дня; 69% — <6 дней.
  static const double lowVariabilityStd = 1.5;
  static const double highVariabilityStd = 6.0;
}

/// Чистая функция прогноза. Без побочных эффектов, легко тестируется.
///
/// [periodStartDates] — даты ПЕРВЫХ дней менструаций (начала циклов), в любом порядке.
/// [userStatedCycleLength] / [userStatedPeriodLength] — из онбординга (если есть).
CyclePrediction predictCycle({
  required List<DateTime> periodStartDates,
  int? userStatedCycleLength,
  int? userStatedPeriodLength,
  DateTime? today,
}) {
  final now = DateUtilsLite.dateOnly(today ?? DateTime.now());

  // Нормализуем: только дни, по возрастанию, без дублей.
  final starts = periodStartDates
      .map(DateUtilsLite.dateOnly)
      .toSet()
      .toList()
    ..sort();

  // --- Холодный старт: нет ни одной отметки ---
  if (starts.isEmpty) {
    return _coldStart(now, userStatedCycleLength, userStatedPeriodLength);
  }

  final lastStart = starts.last;

  // Длины завершённых циклов (разница между соседними началами).
  final lengths = <int>[];
  for (var i = 1; i < starts.length; i++) {
    final len = DateUtilsLite.daysBetween(starts[i - 1], starts[i]);
    // Отбрасываем явный мусор (двойные отметки/опечатки), но мягко.
    if (len >= 10 && len <= 90) lengths.add(len);
  }

  // --- Мало данных: 0 завершённых циклов (есть только 1 отметка) ---
  if (lengths.isEmpty) {
    final cycleLen = _clampPlausible(
      userStatedCycleLength ?? CycleConstants.populationDefaultCycle,
    );
    return _buildPrediction(
      lastStart: lastStart,
      cycleLength: cycleLen,
      marginDays: CycleConstants.coldStartMargin,
      confidence: ConfidenceLevel.low,
      cyclesUsed: 0,
      isUncertain: true,
    );
  }

  // --- Основной путь: считаем по истории ---
  // Берём последние ≤6 циклов.
  final recent = lengths.length > CycleConstants.maxCyclesForMedian
      ? lengths.sublist(lengths.length - CycleConstants.maxCyclesForMedian)
      : lengths;

  final medianLen = _median(recent).round();
  final cycleLen = _clampPlausible(medianLen);

  // Личная вариативность → размер диапазона погрешности.
  final std = _stdDev(recent);
  final margin = _marginFromVariability(std, recent.length);

  // Уверенность по количеству данных и вариативности.
  final confidence = _confidence(recent.length, std);
  final uncertain = std > CycleConstants.highVariabilityStd;

  return _buildPrediction(
    lastStart: lastStart,
    cycleLength: cycleLen,
    marginDays: margin,
    confidence: confidence,
    cyclesUsed: recent.length,
    isUncertain: uncertain,
  );
}

// --- Вспомогательные ---

CyclePrediction _coldStart(
  DateTime now,
  int? statedCycle,
  int? statedPeriod,
) {
  final cycleLen = _clampPlausible(
    statedCycle ?? CycleConstants.populationDefaultCycle,
  );
  // Без даты последних — опираем прогноз от "сегодня" как грубую точку отсчёта.
  return _buildPrediction(
    lastStart: now,
    cycleLength: cycleLen,
    marginDays: CycleConstants.coldStartMargin,
    confidence: ConfidenceLevel.low,
    cyclesUsed: 0,
    isUncertain: true,
  );
}

CyclePrediction _buildPrediction({
  required DateTime lastStart,
  required int cycleLength,
  required int marginDays,
  required ConfidenceLevel confidence,
  required int cyclesUsed,
  required bool isUncertain,
}) {
  final nextStart = lastStart.add(Duration(days: cycleLength));

  // Овуляция через лютеиновую фазу: nextStart − 14.
  final ovulationDay =
      nextStart.subtract(const Duration(days: CycleConstants.lutealPhaseDays));

  final ovulationWindow = DateRange(
    ovulationDay.subtract(const Duration(days: 1)),
    ovulationDay.add(const Duration(days: 1)),
  );

  final fertileWindow = DateRange(
    ovulationDay
        .subtract(const Duration(days: CycleConstants.fertileBeforeOvulation)),
    ovulationDay
        .add(const Duration(days: CycleConstants.fertileAfterOvulation)),
  );

  return CyclePrediction(
    nextPeriodStart: nextStart,
    marginDays: marginDays,
    ovulationWindow: ovulationWindow,
    fertileWindow: fertileWindow,
    confidence: confidence,
    cyclesUsed: cyclesUsed,
    medianCycleLength: cycleLength,
    isUncertain: isUncertain,
  );
}

int _clampPlausible(int len) => len.clamp(
      CycleConstants.minPlausibleCycle,
      CycleConstants.maxPlausibleCycle,
    );

/// Диапазон погрешности из вариативности (с поправкой на малую выборку).
int _marginFromVariability(double std, int n) {
  // База — округлённое стд. отклонение, минимум 1.
  var m = std.ceil();
  if (m < 1) m = 1;
  // Мало циклов — расширяем (меньше доверия личной вариативности).
  if (n < 3) m = math.max(m, CycleConstants.coldStartMargin);
  // Не раздуваем сверх разумного.
  return m.clamp(1, 7);
}

ConfidenceLevel _confidence(int n, double std) {
  if (n >= 4 && std <= CycleConstants.lowVariabilityStd) {
    return ConfidenceLevel.high;
  }
  if (n >= 3 && std <= CycleConstants.highVariabilityStd) {
    return ConfidenceLevel.medium;
  }
  return ConfidenceLevel.low;
}

double _median(List<int> xs) {
  final s = [...xs]..sort();
  final n = s.length;
  if (n.isOdd) return s[n ~/ 2].toDouble();
  return (s[n ~/ 2 - 1] + s[n ~/ 2]) / 2.0;
}

double _stdDev(List<int> xs) {
  if (xs.length < 2) return 0;
  final mean = xs.reduce((a, b) => a + b) / xs.length;
  final variance =
      xs.map((x) => math.pow(x - mean, 2)).reduce((a, b) => a + b) /
          xs.length;
  return math.sqrt(variance);
}
