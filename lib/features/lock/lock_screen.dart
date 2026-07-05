import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lea_design/lea_design.dart';

import '../../core/security/lock_service.dart';

/// Экран блокировки. Показывается при старте, если включена защита.
class LockScreen extends ConsumerStatefulWidget {
  const LockScreen({super.key, required this.onUnlocked});
  final VoidCallback onUnlocked;

  @override
  ConsumerState<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends ConsumerState<LockScreen> {
  final _lock = LockService();
  String _entered = '';
  bool _error = false;
  LockType? _type; // null = ещё определяем (не мелькаем PIN)

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final type = await _lock.currentType();
    if (mounted) setState(() => _type = type);
    if (type == LockType.biometric) {
      // небольшая задержка чтобы экран успел отрисоваться, потом диалог
      await Future.delayed(const Duration(milliseconds: 200));
      await _tryBiometric();
    }
  }

  Future<void> _onDigit(String d) async {
    if (_entered.length >= 4) return;
    HapticFeedback.selectionClick();
    setState(() {
      _entered += d;
      _error = false;
    });
    if (_entered.length == 4) {
      final ok = await _lock.verifyPin(_entered);
      if (ok) {
        widget.onUnlocked();
      } else {
        HapticFeedback.heavyImpact();
        setState(() {
          _error = true;
          _entered = '';
        });
      }
    }
  }

  void _backspace() {
    if (_entered.isEmpty) return;
    setState(() => _entered = _entered.substring(0, _entered.length - 1));
  }

  @override
  Widget build(BuildContext context) {
    final lea = context.lea;

    // пока тип не определён — не мелькаем PIN-клавиатурой
    if (_type == null) {
      return Scaffold(
        backgroundColor: lea.background,
        body: Center(child: CircularProgressIndicator(color: lea.accent)),
      );
    }

    final isBiometric = _type == LockType.biometric;

    return Scaffold(
      backgroundColor: lea.background,
      body: SafeArea(
        child: Column(
          children: [
            const Spacer(),
            Text('Лея', style: LeaType.display.copyWith(color: lea.accent)),
            const SizedBox(height: LeaSpace.sm),
            Text(
              isBiometric
                  ? 'Приложите палец'
                  : (_error ? 'Неверный код' : 'Введите код'),
              style: LeaType.body.copyWith(
                  color: _error ? lea.error : lea.textSecondary),
            ),
            const SizedBox(height: LeaSpace.xxl),
            if (isBiometric)
              // крупная кнопка биометрии — тап вызывает системный диалог
              Expanded(
                child: Center(
                  child: GestureDetector(
                    onTap: _tryBiometric,
                    child: Container(
                      width: 96,
                      height: 96,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: lea.accent.withValues(alpha: 0.12),
                      ),
                      child: Icon(Icons.fingerprint,
                          color: lea.accent, size: 56),
                    ),
                  ),
                ),
              )
            else ...[
              // точки PIN
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (var i = 0; i < 4; i++)
                    Container(
                      margin:
                          const EdgeInsets.symmetric(horizontal: LeaSpace.sm),
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: i < _entered.length
                            ? lea.accent
                            : Colors.transparent,
                        border: Border.all(color: lea.accent, width: 1.5),
                      ),
                    ),
                ],
              ),
              const Spacer(),
              _Keypad(
                onDigit: _onDigit,
                onBackspace: _backspace,
                showBiometric: false,
                onBiometric: () {},
              ),
            ],
            const SizedBox(height: LeaSpace.xxxl),
          ],
        ),
      ),
    );
  }

  Future<void> _tryBiometric() async {
    final ok = await _lock.authenticateBiometric();
    if (ok) widget.onUnlocked();
  }
}

class _Keypad extends StatelessWidget {
  const _Keypad({
    required this.onDigit,
    required this.onBackspace,
    required this.showBiometric,
    required this.onBiometric,
  });
  final ValueChanged<String> onDigit;
  final VoidCallback onBackspace;
  final bool showBiometric;
  final VoidCallback onBiometric;

  @override
  Widget build(BuildContext context) {
    final lea = context.lea;
    Widget key(String label, {VoidCallback? onTap, IconData? icon}) => SizedBox(
          width: 72,
          height: 72,
          child: Material(
            color: Colors.transparent,
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: onTap ?? (() => onDigit(label)),
              child: Center(
                child: icon != null
                    ? Icon(icon, color: lea.textPrimary, size: LeaIconSize.md)
                    : Text(label,
                        style: LeaType.h1.copyWith(color: lea.textPrimary)),
              ),
            ),
          ),
        );

    Widget row(List<Widget> ch) => Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: ch
              .map((w) => Padding(
                  padding: const EdgeInsets.all(LeaSpace.sm), child: w))
              .toList(),
        );

    return Column(
      children: [
        row([key('1'), key('2'), key('3')]),
        row([key('4'), key('5'), key('6')]),
        row([key('7'), key('8'), key('9')]),
        row([
          showBiometric
              ? key('', icon: Icons.fingerprint, onTap: onBiometric)
              : const SizedBox(width: 72),
          key('0'),
          key('', icon: Icons.backspace_outlined, onTap: onBackspace),
        ]),
      ],
    );
  }
}
