import 'package:flutter_test/flutter_test.dart';
import 'package:lea/core/prediction/predict_cycle.dart';
import 'package:lea/features/calendar/day_phase.dart';

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
  group('DayPhaseResolver', () {
    test('фактический день менструации → menstrual', () {
      final periods = [DateTime(2026, 1, 1), DateTime(2026, 1, 2)];
      final pred = predictCycle(
        periodStartDates: [DateTime(2026, 1, 1)],
        userStatedCycleLength: 28,
        today: DateTime(2026, 1, 5),
      );
      final r = DayPhaseResolver(periodDays: periods, prediction: pred);
      expect(r.phaseFor(DateTime(2026, 1, 1)), DayPhase.menstrual);
      expect(r.phaseFor(DateTime(2026, 1, 2)), DayPhase.menstrual);
    });

    test('прогнозное окно следующих месячных → forecastPeriod', () {
      // Даты в БУДУЩЕМ относительно реального now(), т.к. buildCycleHistory
      // использует DateTime.now() для конца текущего цикла. Иначе прошлые
      // тестовые даты «поглощаются» текущим циклом до сегодня.
      final base = DateTime.now().add(const Duration(days: 400));
      final starts = startsFrom(base, [28, 28, 28]);
      final pred = predictCycle(
        periodStartDates: starts,
        today: base.add(const Duration(days: 84)),
      );
      final r = DayPhaseResolver(
        periodDays: starts,
        prediction: pred,
      );
      // центр прогноза должен быть forecastPeriod
      expect(r.phaseFor(pred.nextPeriodStart), DayPhase.forecastPeriod);
    });

    test('день овуляции → ovulation', () {
      final base = DateTime.now().add(const Duration(days: 400));
      final starts = startsFrom(base, [28, 28, 28]);
      final pred = predictCycle(
        periodStartDates: starts,
        today: base.add(const Duration(days: 84)),
      );
      final r = DayPhaseResolver(periodDays: starts, prediction: pred);
      // лютеиновая для цикла 28 = 14; овуляция = nextStart − 14
      final ovDay = pred.nextPeriodStart
          .subtract(Duration(days: lutealForCycle(pred.medianCycleLength)));
      expect(r.phaseFor(ovDay), DayPhase.ovulation);
    });
  });
}
