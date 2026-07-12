import 'package:flutter/material.dart';
import 'package:lea_design/lea_design.dart';

import '../day_phase.dart';

/// Ячейка одного дня в сетке календаря.
/// Раскраска по фазе; прогноз — пунктирная обводка + мягкая заливка.
/// Дни менструации дополнительно градуируются по интенсивности (если задана).
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
    this.flowCode,
    this.cycleDay,
  });

  final DateTime date;
  final DayPhase phase;
  final bool isToday;
  final bool isSelected;
  final bool hasLog;
  final bool inCurrentMonth;
  final VoidCallback onTap;

  /// Код интенсивности менструации: light / medium / heavy / clots.
  /// null — интенсивность не задана (это нормально, она необязательна):
  /// день красится базовым цветом менструации.
  final String? flowCode;

  /// Номер дня внутри цикла (1-й, 2-й…). null — день вне известных циклов,
  /// номер не показываем (выдумывать его нельзя).
  final int? cycleDay;

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
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // --- Круг дня ---
              Expanded(
                child: AspectRatio(
                  aspectRatio: 1,
                  child: CustomPaint(
                    // foregroundPainter рисует ПОВЕРХ child — иначе
                    // непрозрачная заливка перекрывала бы пунктир.
                    foregroundPainter: dashed
                        ? _DashedCirclePainter(color: lea.forecastDash)
                        : null,
                    child: Container(
                      decoration: BoxDecoration(
                        color: fill,
                        shape: BoxShape.circle,
                        border: isSelected
                            ? Border.all(color: lea.accent, width: 2.5)
                            : (isToday && !dashed
                                ? Border.all(color: lea.accent, width: 1.5)
                                : null),
                      ),
                      alignment: Alignment.center,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '${date.day}',
                            style: (isToday
                                    ? LeaType.dayNumberActive
                                    : LeaType.dayNumber)
                                .copyWith(
                              color: inCurrentMonth
                                  ? textColor
                                  : textColor.withValues(alpha: 0.35),
                              fontWeight: isToday ? FontWeight.w800 : null,
                            ),
                          ),
                          // Номер дня цикла — мелко под числом, ВНУТРИ круга.
                          // Показывается только если включено в настройках
                          // (по умолчанию выключено) и день внутри цикла.
                          if (cycleDay != null && inCurrentMonth)
                            Text(
                              '$cycleDay',
                              style: LeaType.caption.copyWith(
                                fontSize: 8,
                                height: 1.0,
                                color: textColor.withValues(alpha: 0.65),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              // --- Точка «есть записи» — ПОД кругом, чтобы не превращать
              //     содержимое круга в кашу.
              SizedBox(
                height: 8,
                child: hasLog
                    ? Padding(
                        padding: const EdgeInsets.only(top: 3),
                        child: Center(
                          child: Container(
                            width: 4,
                            height: 4,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: lea.accent.withValues(alpha: 0.8),
                            ),
                          ),
                        ),
                      )
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// (заливка, цвет текста, пунктир?)
  (Color, Color, bool) _style(LeaColors lea) {
    return switch (phase) {
      DayPhase.menstrual => _menstrualStyle(lea),
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

  /// Раскраска дня менструации с градацией по интенсивности.
  ///
  /// Базовый цвет — lea.phaseMenstrual. Интенсивность меняет насыщенность:
  /// скудные — светлее, обильные/сгустки — на полную. Если интенсивность
  /// не задана (она НЕобязательна) — красим базовым цветом, как раньше.
  ///
  /// Текст на светлых заливках — тёмный (читаемость), на насыщенных — onPhase.
  (Color, Color, bool) _menstrualStyle(LeaColors lea) {
    final base = lea.phaseMenstrual;
    final alpha = switch (flowCode) {
      'light' => 0.45, // скудные
      'medium' => 0.70, // средние
      'heavy' => 1.0, // обильные
      'clots' => 1.0, // сгустки — как обильные по насыщенности
      _ => 1.0, // не задана — базовый цвет (как было до градаций)
    };
    // На бледных заливках белый текст нечитаем — берём тёмный.
    final onLight = alpha < 0.6;
    return (
      base.withValues(alpha: alpha),
      onLight ? lea.textPrimary : lea.onPhase,
      false,
    );
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
