import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Цвета фаз цикла — те же, что в кольце на главном экране.
class LeaMarkColors {
  static const menstrual = Color(0xFFF5A38F);
  static const follicular = Color(0xFFF8CFA1);
  static const ovulation = Color(0xFFC3DEB6);
  static const luteal = Color(0xFFD8C4EC);
  static const blush = Color(0xFFF6C2D0);

  static const petals = [menstrual, follicular, ovulation, luteal, blush];
}

/// Знак Леи — цветок из 5 лепестков.
/// [bloom] 0..1 — распускание (0 = бутон, 1 = раскрыт).
/// [pulse] 0..1 — лёгкое «дыхание».
class LeaMark extends StatelessWidget {
  const LeaMark({
    super.key,
    this.size = 140,
    this.bloom = 1.0,
    this.pulse = 0.0,
    this.dark = false,
  });

  final double size;
  final double bloom;
  final double pulse;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _MarkPainter(bloom: bloom, pulse: pulse, dark: dark),
      ),
    );
  }
}

class _MarkPainter extends CustomPainter {
  _MarkPainter({required this.bloom, required this.pulse, required this.dark});
  final double bloom;
  final double pulse;
  final bool dark;

  static const _darkPetals = [
    Color(0xFFEE9E88),
    Color(0xFFEDCB9C),
    Color(0xFFAFD3A2),
    Color(0xFFCBB4E4),
    Color(0xFFEFB0C2),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    // viewBox эталона 512, центр 256,256; лепестки cy=-82 rx=44 ry=82
    final s = size.width / 512.0 * (1.0 + pulse * 0.03);
    canvas.save();
    canvas.translate(size.width / 2, size.height / 2);
    canvas.scale(s);

    const opacity = 0.9;
    final petals = dark ? _darkPetals : LeaMarkColors.petals;

    for (var i = 0; i < 5; i++) {
      // волна: каждый лепесток раскрывается с небольшой задержкой
      final delay = i * 0.08;
      final local = ((bloom - delay) / (1.0 - delay)).clamp(0.0, 1.0);
      final t = Curves.easeOutBack.transform(local);

      final angle = i * 72.0 * math.pi / 180.0;
      canvas.save();
      canvas.rotate(angle);
      // лепесток выдвигается из центра (0) на позицию (-82) и вырастает
      canvas.translate(0, -82 * t);
      canvas.scale(t); // 0 = точка в центре, 1 = полный размер
      final paint = Paint()
        ..color = petals[i].withValues(alpha: opacity)
        ..isAntiAlias = true;
      // рисуем эллипс в локальных координатах (центр уже сдвинут translate)
      final rect = Rect.fromCenter(
        center: Offset.zero,
        width: 88,
        height: 164,
      );
      canvas.drawOval(rect, paint);
      canvas.restore();
    }

    // центр появляется в конце
    final ct = Curves.easeOut.transform(bloom.clamp(0.0, 1.0));
    final cs = 0.4 + 0.6 * ct;
    final coreColor = dark ? const Color(0xFF2D2623) : const Color(0xFFFFF8F3);
    final pollen = dark ? const Color(0xFFEDCB9C) : const Color(0xFFF6C9A8);
    canvas.drawCircle(Offset.zero, 30 * cs, Paint()..color = coreColor);
    canvas.drawCircle(Offset.zero, 15 * cs, Paint()..color = pollen);

    canvas.restore();
  }

  @override
  bool shouldRepaint(_MarkPainter old) =>
      old.bloom != bloom || old.pulse != pulse || old.dark != dark;
}
