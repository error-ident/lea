import 'package:flutter_test/flutter_test.dart';
import 'package:lea/core/prediction/lh_analysis.dart';
import 'package:lea/core/prediction/predict_cycle.dart';

/// Тесты слоя 4 (ЛГ-тесты) и ИЕРАРХИИ слоёв точности.
///
/// Иерархия важнее самого модуля: если измеренный сигнал не перекроет
/// календарный расчёт, вся работа со слоями бессмысленна.
void main() {
  group('LhAnalysis.ovulationDayFromPositive', () {
    test('пик на 13-й день → овуляция на 14-й', () {
      expect(LhAnalysis.ovulationDayFromPositive([13]), 14);
    });

    test('два положительных подряд — берём первый', () {
      // Пик LH короткий: повторный положительный обычно тот же пик,
      // а не второй. Иначе овуляция «уехала» бы на день вперёд.
      expect(LhAnalysis.ovulationDayFromPositive([13, 14]), 14);
    });

    test('положительный в начале цикла игнорируется', () {
      // Пик LH на 3-й день физиологически невозможен — фолликулу нужно
      // время созреть. Это ошибка теста или неверно отмеченный день.
      expect(LhAnalysis.ovulationDayFromPositive([3]), null);
    });

    test('ложный в начале + настоящий позже — берём настоящий', () {
      expect(LhAnalysis.ovulationDayFromPositive([3, 13]), 14);
    });

    test('поздний пик в длинном цикле', () {
      expect(LhAnalysis.ovulationDayFromPositive([20]), 21);
    });

    test('нет положительных → null', () {
      expect(LhAnalysis.ovulationDayFromPositive([]), null);
    });
  });

  group('Иерархия слоёв: измерение перекрывает расчёт', () {
    // Ровная история: три цикла по 28 дней.
    final starts = <DateTime>[
      DateTime(2026, 1, 1),
      DateTime(2026, 1, 29),
      DateTime(2026, 2, 26),
    ];
    final today = DateTime(2026, 3, 10);

    test('без измерений — календарная оценка, окно овуляции ±1 день', () {
      final p = predictCycle(periodStartDates: starts, today: today);
      // Окно шириной 3 дня: календарь так точен не бывает.
      final width = p.ovulationWindow.end
              .difference(p.ovulationWindow.start)
              .inDays +
          1;
      expect(width, 3);
      // И фертильное окно включает день ПОСЛЕ овуляции (поправка на
      // погрешность календарной оценки).
      expect(
        p.fertileWindow.end.isAfter(p.ovulationWindow.start),
        true,
      );
    });

    test('BBT-калибровка сужает окно овуляции до одного дня', () {
      final p = predictCycle(
        periodStartDates: starts,
        today: today,
        personalLutealDays: 13,
      );
      expect(p.ovulationWindow.start, p.ovulationWindow.end);
    });

    test('личная лютеиновая фаза реально сдвигает овуляцию', () {
      final base = predictCycle(periodStartDates: starts, today: today);
      final withBbt = predictCycle(
        periodStartDates: starts,
        today: today,
        personalLutealDays: 11, // заметно короче популяционных 14
      );
      // Более короткая лютеиновая фаза → овуляция ПОЗЖЕ.
      expect(
        withBbt.ovulationWindow.start.isAfter(base.ovulationWindow.start),
        true,
      );
    });

    test('ЛГ перекрывает и календарь, и BBT', () {
      final lhDate = DateTime(2026, 3, 12);
      final p = predictCycle(
        periodStartDates: starts,
        today: today,
        personalLutealDays: 13, // BBT говорит одно…
        lhOvulationDate: lhDate, // …а измеренный ЛГ — другое
      );
      // Овуляция берётся из ЛГ, а не считается по лютеиновой фазе.
      expect(p.ovulationWindow.start, lhDate);
      expect(p.ovulationWindow.end, lhDate);
    });

    test('при измеренной овуляции фертильное окно классическое', () {
      final lhDate = DateTime(2026, 3, 12);
      final p = predictCycle(
        periodStartDates: starts,
        today: today,
        lhOvulationDate: lhDate,
      );
      // Классическое окно (Mihm 2011): 5 дней до овуляции и день овуляции.
      // Добавочного дня после НЕТ — поправка на погрешность не нужна,
      // овуляция измерена.
      expect(p.fertileWindow.end, lhDate);
      expect(
        p.fertileWindow.start,
        lhDate.subtract(
            const Duration(days: CycleConstants.fertileBeforeOvulation)),
      );
    });
  });
}
