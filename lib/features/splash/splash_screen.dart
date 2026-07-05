import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/providers.dart';
import 'lea_mark.dart';

/// Загрузочный экран Леи.
/// Держится, пока считается первый прогноз цикла (и не меньше minDuration,
/// чтобы анимация распускания успела доиграть). Затем мягко растворяется
/// в [next] — главная появляется сразу готовой, без лоадера.
class LeaSplash extends ConsumerStatefulWidget {
  const LeaSplash({
    super.key,
    required this.next,
    this.minDuration = const Duration(milliseconds: 1600),
  });

  final Widget next;
  final Duration minDuration;

  @override
  ConsumerState<LeaSplash> createState() => _LeaSplashState();
}

class _LeaSplashState extends ConsumerState<LeaSplash>
    with TickerProviderStateMixin {
  late final AnimationController _bloom;
  late final AnimationController _breathe;
  bool _leaving = false;
  bool _started = false;

  @override
  void initState() {
    super.initState();
    _bloom = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..forward();

    _breathe = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat(reverse: true);
  }

  bool _dataReady = false;
  bool _minTimePassed = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_started) {
      _started = true;
      // минимальное время анимации
      Future.delayed(widget.minDuration).then((_) {
        _minTimePassed = true;
        _maybeLeave();
      });
      // страховочный таймаут — уйти в любом случае
      Future.delayed(const Duration(seconds: 6)).then((_) {
        _dataReady = true;
        _minTimePassed = true;
        _maybeLeave();
      });
      // ВАЖНО: watch провайдеров через listen — реально их запускает.
      // Ждём и прогноз, и поток дней (главная использует оба).
      var predReady = false;
      var daysReady = false;
      void check() {
        if (predReady && daysReady) {
          _dataReady = true;
          _maybeLeave();
        }
      }

      ref.listenManual(predictionProvider, (prev, next) {
        if (next.hasValue || next.hasError) {
          predReady = true;
          check();
        }
      }, fireImmediately: true);

      ref.listenManual(periodDaysStreamProvider, (prev, next) {
        if (next.hasValue || next.hasError) {
          daysReady = true;
          check();
        }
      }, fireImmediately: true);
    }
  }

  void _maybeLeave() {
    if (!mounted || _leaving) return;
    if (_dataReady && _minTimePassed) {
      _leave();
    }
  }

  Future<void> _leave() async {
    setState(() => _leaving = true);
    await Future.delayed(const Duration(milliseconds: 320));
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 300),
        pageBuilder: (_, __, ___) => widget.next,
        transitionsBuilder: (_, anim, __, child) =>
            FadeTransition(opacity: anim, child: child),
      ),
    );
  }

  @override
  void dispose() {
    _bloom.dispose();
    _breathe.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final bg1 = dark ? const Color(0xFF2D2623) : const Color(0xFFFFF8F3);
    final bg2 = dark ? const Color(0xFF221C1A) : const Color(0xFFF7EDE6);
    final txt = dark ? const Color(0xFFF2E9E3) : const Color(0xFF3D332E);
    final sub = dark ? const Color(0xFFA8978D) : const Color(0xFF8A7A70);
    final dots = dark
        ? const [Color(0xFFEE9E88), Color(0xFFAFD3A2), Color(0xFFCBB4E4)]
        : const [Color(0xFFF5A38F), Color(0xFFC3DEB6), Color(0xFFD8C4EC)];

    return AnimatedOpacity(
      opacity: _leaving ? 0.0 : 1.0,
      duration: const Duration(milliseconds: 300),
      child: Scaffold(
        body: Container(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: const Alignment(0, -0.32),
              radius: 1.1,
              colors: [bg1, bg2],
            ),
          ),
          child: Stack(
            children: [
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AnimatedBuilder(
                      animation: Listenable.merge([_bloom, _breathe]),
                      builder: (context, _) {
                        final bloom = _bloom.value;
                        final pulse = bloom >= 0.99
                            ? Curves.easeInOut.transform(_breathe.value)
                            : 0.0;
                        return LeaMark(
                          size: 150,
                          bloom: bloom,
                          pulse: pulse,
                          dark: dark,
                        );
                      },
                    ),
                    const SizedBox(height: 28),
                    AnimatedBuilder(
                      animation: _bloom,
                      builder: (context, child) {
                        final p =
                            ((_bloom.value - 0.3) / 0.7).clamp(0.0, 1.0);
                        final eased = Curves.easeOut.transform(p);
                        return Opacity(
                          opacity: eased,
                          child: Transform.translate(
                            offset: Offset(0, 16 * (1 - eased)),
                            child: child,
                          ),
                        );
                      },
                      child: Column(
                        children: [
                          Text(
                            'Лея',
                            style: TextStyle(
                              fontFamily: 'Nunito',
                              fontSize: 40,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -1,
                              color: txt,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Спокойный дневник цикла',
                            style: TextStyle(
                              fontFamily: 'Nunito',
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                              color: sub,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Positioned(
                bottom: 48,
                left: 0,
                right: 0,
                child: AnimatedBuilder(
                  animation: _breathe,
                  builder: (context, _) => Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(3, (i) {
                      final phase = (_breathe.value + i * 0.2) % 1.0;
                      final o = 0.4 +
                          0.6 * (0.5 + 0.5 * math.sin(phase * 2 * math.pi));
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 3.5),
                        child: Opacity(
                          opacity: o,
                          child: Container(
                            width: 7,
                            height: 7,
                            decoration: BoxDecoration(
                              color: dots[i],
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
