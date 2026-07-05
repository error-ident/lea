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
      final starts = startsFrom(DateTime(2026, 1, 1), [28, 28, 28]);
      final pred = predictCycle(
        periodStartDates: starts,
        today: DateTime(2026, 3, 20),
      );
      final r = DayPhaseResolver(
        periodDays: starts,
        prediction: pred,
      );
      // центр прогноза должен быть forecastPeriod
      expect(r.phaseFor(pred.nextPeriodStart), DayPhase.forecastPeriod);
    });

    test('день овуляции → ovulation', () {
      final starts = startsFrom(DateTime(2026, 1, 1), [28, 28, 28]);
      final pred = predictCycle(
        periodStartDates: starts,
        today: DateTime(2026, 3, 20),
      );
      final r = DayPhaseResolver(periodDays: starts, prediction: pred);
      final ovDay = pred.nextPeriodStart.subtract(const Duration(days: 14));
      expect(r.phaseFor(ovDay), DayPhase.ovulation);
    });
  });
}
