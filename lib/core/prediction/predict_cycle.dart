import 'dart:math' as math;
import 'cycle_prediction.dart';

/// Константы из спеки (данные JMIR, когорта 1.5 млн женщин).
abstract final class CycleConstants {
  /// Лютеиновая фаза — стабильнее фолликулярной, но не жёсткая константа.
  /// Считается динамически по длине цикла: см. [lutealForCycle].
  /// Границы диапазона (по данным — пик 13–15 дней).
  static const int lutealMinDays = 13;
  static const int lutealMaxDays = 15;

  /// Фертильное окно: овуляция −5 … +1.
  ///
  /// Классическое окно (Mihm et al. 2011) — 5 дней ДО овуляции и день
  /// овуляции: сперматозоиды живут ~5 дней, яйцеклетка ~24 часа.
  ///
  /// Почему +1 сверх источника: у нас овуляция ВЫЧИСЛЕНА по календарю, а не
  /// измерена (нет BBT/ЛГ-подтверждения), поэтому её момент может сдвинуться
  /// на день. Добавочный день — поправка на погрешность нашей же оценки,
  /// а не утверждение о более длинной фертильности. Сузить окно до дня
  /// овуляции значило бы заявить точность, которой у календарного метода нет.
  static const int fertileBeforeOvulation = 5;
  static const int fertileAfterOvulation = 1;

  /// Сколько последних циклов берём для медианы (rhythm-метод: ≤6).
  static const int maxCyclesForMedian = 6;

  /// Популяционный априор длины цикла (медиана 28, но слабый — только 16% женщин).
  static const int populationDefaultCycle = 28;

  /// Границы правдоподобной длины ЗАВЕРШЁННОГО цикла.
  static const int minPlausibleCycle = 10;
  static const int maxPlausibleCycle = 100;

  /// Абсолютный мусор-фильтр на сырых длинах (опечатки/двойные отметки).
  /// Всё вне этого диапазона отбрасывается ещё до анализа склеек.
  static const int rawMinLength = 10;
  static const int rawMaxLength = 120;

  /// Популяционная погрешность при холодном старте (широкая).
  static const int coldStartMargin = 5;

  /// Пороги вариативности (по разбросу длины), из распределения JMIR:
  /// 25% женщин — вариация 0–1.5 дня; 69% — <6 дней.
  static const double lowVariabilityStd = 1.5;
  static const double highVariabilityStd = 6.0;

  /// --- Слой 0: детектор склеек (пропущенных отметок) ---
  /// Склейкой считается цикл, длина которого близка к ЦЕЛОМУ кратному ≥2
  /// личной медианы (±20%). Это отличает пропущенную отметку (~2× медианы)
  /// от реального длинного цикла. Порог адаптивный — от личной медианы,
  /// поэтому стабильные длинные циклы (34–40) не трогаются.
}

/// Динамическая длина лютеиновой фазы по длине цикла.
///
/// Физиология: лютеиновая фаза стабильнее фолликулярной, но слегка растёт
/// с длиной цикла. Короткие циклы → ближе к 13, длинные → к 15.
/// Держим в границах [lutealMinDays..lutealMaxDays].
///
/// Публичная и чистая — ИМЕННО ЕЁ должен использовать и календарь (day_phase),
/// чтобы движок и отображение фаз не рассинхронились.
int lutealForCycle(int cycleLength) {
  // Опорные точки: короткий цикл (<=24) → 13, длинный (>=33) → 15, середина → 14.
  if (cycleLength <= 24) return CycleConstants.lutealMinDays; // 13
  if (cycleLength >= 33) return CycleConstants.lutealMaxDays; // 15
  return 14;
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

  // Сырые длины завершённых циклов (разница между соседними началами).
  // Отбрасываем только явный мусор (опечатки/двойные отметки).
  final rawLengths = <int>[];
  for (var i = 1; i < starts.length; i++) {
    final len = DateUtilsLite.daysBetween(starts[i - 1], starts[i]);
    if (len >= CycleConstants.rawMinLength &&
        len <= CycleConstants.rawMaxLength) {
      rawLengths.add(len);
    }
  }

  // --- Мало данных: 0 завершённых циклов (есть только 1 отметка) ---
  if (rawLengths.isEmpty) {
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

  // --- Слой 0: разбираем вероятные склейки из пропущенных отметок ---
  final cleaned = _resolveSeams(rawLengths);

  // --- Основной путь: считаем по очищенной истории ---
  // Берём последние ≤6 циклов.
  final recent = cleaned.length > CycleConstants.maxCyclesForMedian
      ? cleaned.sublist(cleaned.length - CycleConstants.maxCyclesForMedian)
      : cleaned;

  final medianLen = _median(recent).round();
  final cycleLen = _clampPlausible(medianLen);

  // --- Слой 1: разброс через MAD (устойчив к выбросам, согласован с медианой) ---
  final spread = _mad(recent);
  final margin = _marginFromVariability(spread, recent.length);

  // Уверенность по количеству данных и вариативности.
  final confidence = _confidence(recent.length, spread);
  final uncertain = spread > CycleConstants.highVariabilityStd;

  return _buildPrediction(
    lastStart: lastStart,
    cycleLength: cycleLen,
    marginDays: margin,
    confidence: confidence,
    cyclesUsed: recent.length,
    isUncertain: uncertain,
  );
}

// --- Слой 0: разрешение склеек -------------------------------------------

/// Разбирает циклы, которые с высокой вероятностью «склеены» из-за забытой
/// отметки месячных. Такой цикл близок к кратному от личной медианы
/// (обычно ×2). Мы делим его на предполагаемые под-циклы, чтобы он не
/// раздувал медиану и разброс.
///
/// Важно: порог адаптивный (от медианы очищаемой выборки), поэтому длинные
/// регулярные циклы (например, стабильные 34–40) НЕ считаются склейками.
List<int> _resolveSeams(List<int> rawLengths) {
  if (rawLengths.length < 2) return List<int>.from(rawLengths);

  // Базовая медиана — по ВСЕЙ выборке (устойчива к выбросам сама по себе).
  // Раньше бралась по «нижним 75%», из-за чего при смеси коротких и длинных
  // циклов порог смещался вниз и нормальные длинные ошибочно резались.
  final baseMedian = _median(rawLengths);

  final out = <int>[];
  for (final len in rawLengths) {
    // Кандидат в склейку — только если длина близка к ЦЕЛОМУ кратному ≥2
    // личной медианы (склейка из пропущенной отметки ⇒ ~2× медианы, и каждый
    // под-цикл ≈ медиане). Просто «длиннее в 1.5×» недостаточно — это может
    // быть реальный длинный цикл.
    final ratio = len / baseMedian;
    final parts = ratio.round();
    if (parts >= 2 && len >= 2 * CycleConstants.rawMinLength) {
      final sub = len / parts;
      final relErr = (sub - baseMedian).abs() / baseMedian;
      // делим, только если под-циклы близки к медиане (±20%) и правдоподобны
      if (relErr <= 0.20 &&
          sub.round() >= CycleConstants.minPlausibleCycle &&
          sub.round() <= CycleConstants.maxPlausibleCycle) {
        for (var k = 0; k < parts; k++) {
          out.add(sub.round());
        }
        continue;
      }
    }
    out.add(len);
  }
  return out;
}

// --- Вспомогательные ------------------------------------------------------

CyclePrediction _coldStart(
  DateTime now,
  int? statedCycle,
  int? statedPeriod,
) {
  final cycleLen = _clampPlausible(
    statedCycle ?? CycleConstants.populationDefaultCycle,
  );
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

  // --- Слой 3-preview: лютеиновая фаза динамическая, по длине цикла ---
  final luteal = lutealForCycle(cycleLength);
  final ovulationDay = nextStart.subtract(Duration(days: luteal));

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
/// Принимает разброс (MAD), а не std.
int _marginFromVariability(double spread, int n) {
  var m = spread.ceil();
  if (m < 1) m = 1;
  // Мало циклов — расширяем (меньше доверия личной вариативности).
  if (n < 3) m = math.max(m, CycleConstants.coldStartMargin);
  return m.clamp(1, 7);
}

ConfidenceLevel _confidence(int n, double spread) {
  if (n >= 4 && spread <= CycleConstants.lowVariabilityStd) {
    return ConfidenceLevel.high;
  }
  if (n >= 3 && spread <= CycleConstants.highVariabilityStd) {
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

/// Median Absolute Deviation — медиана |x − медиана|.
/// Устойчив к выбросам и согласован с медианным центром прогноза.
double _mad(List<int> xs) {
  if (xs.length < 2) return 0;
  final med = _median(xs);
  final devs = xs.map((x) => (x - med).abs().toDouble()).toList();
  final s = [...devs]..sort();
  final n = s.length;
  if (n.isOdd) return s[n ~/ 2];
  return (s[n ~/ 2 - 1] + s[n ~/ 2]) / 2.0;
}
