import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lea_design/lea_design.dart';

import '../../core/security/lock_service.dart';

/// Экран установки PIN. Двойной ввод (задать → подтвердить).
class SetPinScreen extends StatefulWidget {
  const SetPinScreen({super.key});

  @override
  State<SetPinScreen> createState() => _SetPinScreenState();
}

class _SetPinScreenState extends State<SetPinScreen> {
  final _lock = LockService();
  String _first = '';
  String _entered = '';
  bool _confirming = false;
  bool _mismatch = false;

  Future<void> _onDigit(String d) async {
    if (_entered.length >= 4) return;
    HapticFeedback.selectionClick();
    setState(() {
      _entered += d;
      _mismatch = false;
    });
    if (_entered.length == 4) {
      if (!_confirming) {
        setState(() {
          _first = _entered;
          _entered = '';
          _confirming = true;
        });
      } else {
        if (_entered == _first) {
          await _lock.setPin(_entered);
          if (mounted) Navigator.of(context).pop(true);
        } else {
          HapticFeedback.heavyImpact();
          setState(() {
            _mismatch = true;
            _entered = '';
            _first = '';
            _confirming = false;
          });
        }
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
    final title = _mismatch
        ? 'Коды не совпали, ещё раз'
        : _confirming
            ? 'Повторите код'
            : 'Придумайте код';

    return Scaffold(
      backgroundColor: lea.background,
      appBar: AppBar(title: const Text('Код доступа')),
      body: SafeArea(
        child: Column(
          children: [
            const Spacer(),
            Text(title,
                style: LeaType.h2.copyWith(
                    color: _mismatch ? lea.error : lea.textPrimary)),
            const SizedBox(height: LeaSpace.xxl),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var i = 0; i < 4; i++)
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: LeaSpace.sm),
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
            _MiniKeypad(onDigit: _onDigit, onBackspace: _backspace),
            const SizedBox(height: LeaSpace.xxxl),
          ],
        ),
      ),
    );
  }
}

class _MiniKeypad extends StatelessWidget {
  const _MiniKeypad({required this.onDigit, required this.onBackspace});
  final ValueChanged<String> onDigit;
  final VoidCallback onBackspace;

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
          const SizedBox(width: 72),
          key('0'),
          key('', icon: Icons.backspace_outlined, onTap: onBackspace),
        ]),
      ],
    );
  }
}
