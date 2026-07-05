import 'package:flutter_test/flutter_test.dart';
import 'package:lea/core/prediction/predict_cycle.dart';
import 'package:lea/core/prediction/cycle_prediction.dart';

// Хелпер: список начал циклов от стартовой даты с заданными длинами.
List<DateTime> startsFrom(DateTime first, List<int> lengths) {
  final out = <DateTime>[first];
  var cur = first;
  for (final len in lengths) {
    cur = cur.add(Duration(days: len));
    out.add(cur);
  }
  return out;
}

void main() {
  group('predictCycle — холодный старт', () {
    test('нет данных вообще → low confidence, широкий margin', () {
      final p = predictCycle(periodStartDates: []);
      expect(p.confidence, ConfidenceLevel.low);
      expect(p.cyclesUsed, 0);
      expect(p.isUncertain, true);
      expect(p.marginDays, CycleConstants.coldStartMargin);
    });

    test('одна отметка + заявленная длина из онбординга', () {
      final last = DateTime(2026, 1, 1);
      final p = predictCycle(
        periodStartDates: [last],
        userStatedCycleLength: 30,
      );
      expect(p.cyclesUsed, 0);
      expect(p.medianCycleLength, 30);
      // Следующие = последние + 30.
      expect(p.nextPeriodStart, DateTime(2026, 1, 31));
      expect(p.confidence, ConfidenceLevel.low);
    });
  });

  group('predictCycle — регулярный цикл', () {
    test('идеально регулярные 28-дневные циклы → high confidence, узкий margin', () {
      final starts = startsFrom(DateTime(2026, 1, 1), [28, 28, 28, 28]);
      final p = predictCycle(periodStartDates: starts, today: DateTime(2026, 4, 1));

      expect(p.medianCycleLength, 28);
      expect(p.confidence, ConfidenceLevel.high);
      expect(p.marginDays, 1); // нулевая вариативность → минимальный диапазон
      expect(p.isUncertain, false);

      // Последнее начало = 1 янв + 4*28 = 2026-04-09 (старт последнего цикла).
      final lastStart = starts.last;
      expect(p.nextPeriodStart, lastStart.add(const Duration(days: 28)));
    });

    test('овуляция считается через лютеиновую фазу (nextStart − 14)', () {
      final starts = startsFrom(DateTime(2026, 1, 1), [28, 28, 28]);
      final p = predictCycle(periodStartDates: starts, today: DateTime(2026, 3, 1));

      final expectedOvulation =
          p.nextPeriodStart.subtract(const Duration(days: 14));
      // День овуляции должен лежать внутри окна овуляции.
      expect(p.ovulationWindow.contains(expectedOvulation), true);
      // Фертильное окно шире и включает овуляцию.
      expect(p.fertileWindow.contains(expectedOvulation), true);
      // Фертильное окно начинается за 5 дней до овуляции.
      expect(
        p.fertileWindow.start,
        expectedOvulation.subtract(const Duration(days: 5)),
      );
    });
  });

  group('predictCycle — нерегулярный цикл', () {
    test('большой разброс → low/medium confidence, широкий margin, uncertain', () {
      // Циклы 24, 35, 26, 38, 28 — сильный разброс.
      final starts = startsFrom(DateTime(2026, 1, 1), [24, 35, 26, 38, 28]);
      final p = predictCycle(periodStartDates: starts, today: DateTime(2026, 6, 1));

      expect(p.marginDays, greaterThan(2));
      expect(p.confidence, isNot(ConfidenceLevel.high));
    });

    test('один выброс не ломает медиану', () {
      // Четыре по 28 и один аномальный 60 — медиана должна остаться около 28.
      final starts = startsFrom(DateTime(2026, 1, 1), [28, 28, 60, 28, 28]);
      final p = predictCycle(periodStartDates: starts, today: DateTime(2026, 7, 1));
      // Медиана последних 5 длин [28,28,60,28,28] = 28.
      expect(p.medianCycleLength, 28);
    });
  });

  group('predictCycle — граничные значения', () {
    test('экстремально короткая заявленная длина зажимается до минимума', () {
      final p = predictCycle(
        periodStartDates: [DateTime(2026, 1, 1)],
        userStatedCycleLength: 5,
      );
      expect(p.medianCycleLength, CycleConstants.minPlausibleCycle);
    });

    test('берём только последние 6 циклов', () {
      // 10 циклов: первые короткие, последние 6 длинные → медиана от длинных.
      final lengths = [22, 22, 22, 22, 33, 33, 33, 33, 33, 33];
      final starts = startsFrom(DateTime(2025, 1, 1), lengths);
      final p = predictCycle(periodStartDates: starts, today: DateTime(2027, 1, 1));
      // Последние 6 длин — все 33 → медиана 33.
      expect(p.medianCycleLength, 33);
    });
  });
}
