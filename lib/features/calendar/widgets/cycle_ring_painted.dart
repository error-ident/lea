import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:lea_design/lea_design.dart';

/// Кольцо фаз цикла на CustomPaint — полноценный визуал, работает без Rive.
/// Когда появится cycle_ring.riv, можно заменить на CycleRingIcon.
///
/// [progress] 0..1 — позиция текущего дня в цикле (маркер).
/// Сегменты 4 фазы раскрашиваются цветами палитры.
class CycleRingPainted extends StatelessWidget {
  const CycleRingPainted({
    super.key,
    required this.progress,
    this.size = LeaSize.phaseRing,
    this.centerLabel,
    this.centerSub,
  });

  final double progress;
  final double size;
  final String? centerLabel;
  final String? centerSub;

  @override
  Widget build(BuildContext context) {
    final lea = context.lea;
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _RingPainter(
          progress: progress.clamp(0.0, 1.0),
          menstrual: lea.phaseMenstrual,
          follicular: lea.phaseFollicular,
          ovulation: lea.phaseOvulation,
          luteal: lea.phaseLuteal,
          track: lea.border,
          marker: lea.textPrimary,
        ),
        child: (centerLabel != null)
            ? Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(centerLabel!,
                        style: LeaType.titleCard
                            .copyWith(color: lea.textPrimary)),
                    if (centerSub != null)
                      Text(centerSub!,
                          style: LeaType.caption
                              .copyWith(color: lea.textTertiary)),
                  ],
                ),
              )
            : null,
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter({
    required this.progress,
    required this.menstrual,
    required this.follicular,
    required this.ovulation,
    required this.luteal,
    required this.track,
    required this.marker,
  });

  final double progress;
  final Color menstrual, follicular, ovulation, luteal, track, marker;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final stroke = size.width * 0.13;
    final radius = (size.width - stroke) / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    // примерные доли фаз (менструация ~18%, фолликулярная ~32%,
    // овуляция ~14%, лютеиновая ~36%) — визуальный ориентир
    final segments = <(double, Color)>[
      (0.18, menstrual),
      (0.32, follicular),
      (0.14, ovulation),
      (0.36, luteal),
    ];

    const start = -math.pi / 2; // сверху
    var angle = start;
    const gap = 0.04;
    for (final (frac, color) in segments) {
      final sweep = frac * 2 * math.pi - gap;
      final paint = Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..strokeCap = StrokeCap.round;
      canvas.drawArc(rect, angle + gap / 2, sweep, false, paint);
      angle += frac * 2 * math.pi;
    }

    // маркер текущего дня
    final markerAngle = start + progress * 2 * math.pi;
    final mp = Offset(
      center.dx + radius * math.cos(markerAngle),
      center.dy + radius * math.sin(markerAngle),
    );
    canvas.drawCircle(mp, stroke * 0.55, Paint()..color = marker);
    canvas.drawCircle(
        mp, stroke * 0.30, Paint()..color = const Color(0xFFFFFFFF));
  }

  @override
  bool shouldRepaint(_RingPainter old) => old.progress != progress;
}
