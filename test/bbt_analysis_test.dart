import 'package:flutter_test/flutter_test.dart';
import 'package:lea/core/prediction/bbt_analysis.dart';

/// Тесты подтверждения овуляции по базальной температуре.
///
/// Это медицинская логика — от неё зависит точность прогноза, поэтому
/// покрываем и нормальные сценарии, и те, где алгоритм ОБЯЗАН промолчать
/// (ановуляторный цикл, мало данных). Ложное подтверждение хуже отсутствия
/// подтверждения: оно сдвинет все последующие прогнозы.
void main() {
  /// Хелпер: цикл с подъёмом температуры после дня [ovDay].
  Map<int, double> cycle({
    required int length,
    required int ovDay,
    double low = 36.40,
    double high = 36.70,
    Set<int> skip = const {},
  }) {
    final m = <int, double>{};
    for (var d = 1; d <= length; d++) {
      if (skip.contains(d)) continue; // день без измерения
      m[d] = d <= ovDay ? low : high;
    }
    return m;
  }

  group('BbtAnalysis.detectOvulationDay', () {
    test('классический цикл: овуляция на 14-й день', () {
      final ov = BbtAnalysis.detectOvulationDay(cycle(length: 28, ovDay: 14));
      expect(ov, 14);
    });

    test('поздняя овуляция в длинном цикле', () {
      // Длинный цикл объясняется длинной ФОЛЛИКУЛЯРНОЙ фазой,
      // лютеиновая при этом остаётся обычной.
      final ov = BbtAnalysis.detectOvulationDay(cycle(length: 35, ovDay: 21));
      expect(ov, 21);
    });

    test('пропуски измерений не ломают детекцию', () {
      final ov = BbtAnalysis.detectOvulationDay(
        cycle(length: 28, ovDay: 14, skip: {5, 9, 17, 22}),
      );
      expect(ov, 14);
    });

    test('ановуляторный цикл: подъёма нет → null', () {
      final flat = {for (var d = 1; d <= 28; d++) d: 36.45};
      expect(BbtAnalysis.detectOvulationDay(flat), null);
    });

    test('мало данных → null', () {
      final few = {for (var d = 1; d <= 5; d++) d: 36.5};
      expect(BbtAnalysis.detectOvulationDay(few), null);
    });

    test('подъём меньше порога не считается овуляцией', () {
      // Разница 0.10 °C — в пределах шума бытового термометра.
      final noisy = cycle(length: 28, ovDay: 14, low: 36.40, high: 36.50);
      expect(BbtAnalysis.detectOvulationDay(noisy), null);
    });
  });

  group('BbtAnalysis.lutealLengthForCycle', () {
    test('цикл 28, овуляция 14 → лютеиновая 14', () {
      final l = BbtAnalysis.lutealLengthForCycle(
        byDayInCycle: cycle(length: 28, ovDay: 14),
        cycleLength: 28,
      );
      expect(l, 14);
    });

    test('цикл 35, овуляция 21 → лютеиновая 14', () {
      final l = BbtAnalysis.lutealLengthForCycle(
        byDayInCycle: cycle(length: 35, ovDay: 21),
        cycleLength: 35,
      );
      expect(l, 14);
    });

    test('неправдоподобная лютеиновая фаза отбрасывается', () {
      // Овуляция на 3-й день дала бы лютеиновую 25 дней — это ошибка
      // детекции, а не физиология. Лучше промолчать.
      final l = BbtAnalysis.lutealLengthForCycle(
        byDayInCycle: cycle(length: 28, ovDay: 3),
        cycleLength: 28,
      );
      expect(l, null);
    });
  });

  group('BbtAnalysis.personalLutealLength', () {
    test('на одном цикле вывод не делается', () {
      expect(BbtAnalysis.personalLutealLength([14]), null);
    });

    test('медиана по нескольким циклам', () {
      expect(BbtAnalysis.personalLutealLength([13, 14, 15]), 14);
    });

    test('один сбойный цикл не сдвигает оценку', () {
      // Медиана, а не среднее: выброс 18 не должен тянуть результат.
      expect(BbtAnalysis.personalLutealLength([13, 13, 14, 14, 18]), 14);
    });
  });
}
