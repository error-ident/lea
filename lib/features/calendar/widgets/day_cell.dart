import 'package:flutter/material.dart';
import 'package:lea_design/lea_design.dart';

import '../day_phase.dart';

/// Ячейка одного дня в сетке календаря.
/// Раскраска по фазе; прогноз — пунктирная обводка + мягкая заливка.
class DayCell extends StatelessWidget {
  const DayCell({
    super.key,
    required this.date,
    required this.phase,
    required this.isToday,
    required this.isSelected,
    required this.hasLog,
    required this.inCurrentMonth,
    required this.onTap,
  });

  final DateTime date;
  final DayPhase phase;
  final bool isToday;
  final bool isSelected;
  final bool hasLog;
  final bool inCurrentMonth;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final lea = context.lea;

    final (fill, textColor, dashed) = _style(lea);

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AspectRatio(
        aspectRatio: 1,
        child: Padding(
          padding: const EdgeInsets.all(2),
          child: CustomPaint(
            // foregroundPainter рисует ПОВЕРХ child — иначе непрозрачная
            // заливка (в светлых темах) перекрывала бы пунктир.
            foregroundPainter: dashed
                ? _DashedCirclePainter(color: lea.forecastDash)
                : null,
            child: Container(
              decoration: BoxDecoration(
                color: fill,
                shape: BoxShape.circle,
                border: isSelected
                    // выбранный день — жирная обводка акцентом
                    ? Border.all(color: lea.accent, width: 2.5)
                    : (isToday && !dashed
                        // сегодня — тонкая обводка акцентом (мягче выбранного)
                        ? Border.all(color: lea.accent, width: 1.5)
                        : null),
              ),
              alignment: Alignment.center,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '${date.day}',
                    style: (isToday ? LeaType.dayNumberActive : LeaType.dayNumber)
                        .copyWith(
                      color: inCurrentMonth
                          ? textColor
                          : textColor.withValues(alpha: 0.35),
                      fontWeight: isToday ? FontWeight.w800 : null,
                    ),
                  ),
                  if (hasLog)
                    Container(
                      margin: const EdgeInsets.only(top: 1),
                      width: 4,
                      height: 4,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: textColor.withValues(alpha: 0.8),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// (заливка, цвет текста, пунктир?)
  (Color, Color, bool) _style(LeaColors lea) {
    return switch (phase) {
      DayPhase.menstrual => (lea.phaseMenstrual, lea.onPhase, false),
      DayPhase.ovulation => (lea.phaseOvulation, lea.onPhase, false),
      DayPhase.fertileWindow => (
          lea.phaseOvulation.withValues(alpha: 0.25),
          lea.textPrimary,
          false,
        ),
      DayPhase.follicular => (
          lea.phaseFollicular.withValues(alpha: 0.30),
          lea.textPrimary,
          false,
        ),
      DayPhase.luteal => (
          lea.phaseLuteal.withValues(alpha: 0.25),
          lea.textPrimary,
          false,
        ),
      DayPhase.forecastPeriod => (lea.forecastFill, lea.accent, true),
      DayPhase.none => (Colors.transparent, lea.textPrimary, false),
    };
  }
}

/// Пунктирная окружность для прогнозных дней.
class _DashedCirclePainter extends CustomPainter {
  _DashedCirclePainter({required this.color});
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width / 2) - 1.5;

    const dashCount = 14;
    const sweep = 6.28318 / dashCount;
    for (var i = 0; i < dashCount; i++) {
      final start = i * sweep;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        start,
        sweep * 0.55,
        false,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_DashedCirclePainter old) => old.color != color;
}
