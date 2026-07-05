import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lea_design/lea_design.dart';

import '../../core/database/settings_keys.dart';
import '../../core/providers/providers.dart';
import 'welcome_screen.dart';
import '../backup/backup_screen.dart';

/// Онбординг: 3 коротких вопроса, на которых заводится прогноз.
/// Дата последних месячных, обычная длина цикла, длительность менструации.
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key, required this.onDone});
  final VoidCallback onDone;

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  int _step = 0;
  bool _showWelcome = true;

  DateTime? _lastPeriod;
  int _cycleLength = 28; // дефолт, но честно говорим что это «обычно»
  int _periodLength = 5;

  Future<void> _finish() async {
    final db = ref.read(databaseProvider);
    if (_lastPeriod != null) {
      // первый день = старт цикла
      await db.markPeriodRange(_lastPeriod!, _periodLength);
    }
    await db.setSetting(SettingsKeys.statedCycleLength, '$_cycleLength');
    await db.setSetting(SettingsKeys.statedPeriodLength, '$_periodLength');
    await db.setSetting(SettingsKeys.onboardingDone, 'true');
    // сбрасываем кэш, чтобы прогноз пересчитался
    ref.invalidate(onboardingDoneProvider);
    ref.invalidate(statedCycleProvider);
    ref.invalidate(cycleStartsProvider);
    widget.onDone();
  }

  void _next() {
    if (_step < 2) {
      setState(() => _step++);
    } else {
      _finish();
    }
  }

  void _back() {
    if (_step > 0) setState(() => _step--);
  }

  @override
  Widget build(BuildContext context) {
    final lea = context.lea;

    // самый первый экран — приветствие с логотипом
    if (_showWelcome) {
      return WelcomeScreen(
        onStart: () => setState(() => _showWelcome = false),
        onRestore: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const BackupScreen()),
          );
        },
      );
    }

    return Scaffold(
      backgroundColor: lea.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(LeaSpace.xxl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // прогресс
              Row(
                children: [
                  for (var i = 0; i < 3; i++)
                    Expanded(
                      child: Container(
                        margin: EdgeInsets.only(right: i < 2 ? LeaSpace.xs : 0),
                        height: 4,
                        decoration: BoxDecoration(
                          color: i <= _step ? lea.accent : lea.border,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: LeaSpace.xxxl),
              Expanded(child: _buildStep(lea)),
              Row(
                children: [
                  if (_step > 0)
                    TextButton(
                      onPressed: _back,
                      child: Text('Назад',
                          style: LeaType.button.copyWith(color: lea.textSecondary)),
                    ),
                  const Spacer(),
                  _PrimaryButton(
                    label: _step < 2 ? 'Далее' : 'Готово',
                    enabled: _step != 0 || _lastPeriod != null,
                    onTap: _next,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStep(LeaColors lea) {
    return switch (_step) {
      0 => _StepLastPeriod(
          selected: _lastPeriod,
          onPick: (d) => setState(() => _lastPeriod = d),
        ),
      1 => _StepNumber(
          title: 'Какая обычно длина цикла?',
          hint: 'От первого дня месячных до следующего. Обычно 24–35 дней — точную знать не обязательно.',
          value: _cycleLength,
          min: 10,
          max: 100,
          unit: 'дней',
          onChanged: (v) => setState(() => _cycleLength = v),
        ),
      _ => _StepNumber(
          title: 'Сколько длятся месячные?',
          hint: 'Обычно 3–7 дней.',
          value: _periodLength,
          min: 1,
          max: 14,
          unit: 'дней',
          onChanged: (v) => setState(() => _periodLength = v),
        ),
    };
  }
}

class _StepLastPeriod extends StatelessWidget {
  const _StepLastPeriod({required this.selected, required this.onPick});
  final DateTime? selected;
  final ValueChanged<DateTime> onPick;

  @override
  Widget build(BuildContext context) {
    final lea = context.lea;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Когда начались последние месячные?',
            style: LeaType.h1.copyWith(color: lea.textPrimary)),
        const SizedBox(height: LeaSpace.sm),
        Text('Это первый день. По нему построим первый прогноз.',
            style: LeaType.body.copyWith(color: lea.textSecondary)),
        const SizedBox(height: LeaSpace.xxl),
        _PrimaryButton(
          label: selected == null
              ? 'Выбрать дату'
              : _fmt(selected!),
          enabled: true,
          filled: selected != null,
          onTap: () async {
            final now = DateTime.now();
            final picked = await showDatePicker(
              context: context,
              initialDate: selected ?? now,
              firstDate: now.subtract(const Duration(days: 365)),
              lastDate: now,
            );
            if (picked != null) onPick(picked);
          },
        ),
      ],
    );
  }

  static String _fmt(DateTime d) {
    const m = [
      'января', 'февраля', 'марта', 'апреля', 'мая', 'июня',
      'июля', 'августа', 'сентября', 'октября', 'ноября', 'декабря',
    ];
    return '${d.day} ${m[d.month - 1]} ${d.year}';
  }
}

class _StepNumber extends StatelessWidget {
  const _StepNumber({
    required this.title,
    required this.hint,
    required this.value,
    required this.min,
    required this.max,
    required this.unit,
    required this.onChanged,
  });

  final String title;
  final String hint;
  final int value;
  final int min;
  final int max;
  final String unit;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final lea = context.lea;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: LeaType.h1.copyWith(color: lea.textPrimary)),
        const SizedBox(height: LeaSpace.sm),
        Text(hint, style: LeaType.body.copyWith(color: lea.textSecondary)),
        const SizedBox(height: LeaSpace.xxxl),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _StepperButton(
              icon: Icons.remove,
              onTap: value > min ? () => onChanged(value - 1) : null,
            ),
            const SizedBox(width: LeaSpace.xl),
            Column(
              children: [
                Text('$value',
                    style: LeaType.displayLarge.copyWith(color: lea.accent)),
                Text(unit,
                    style: LeaType.label.copyWith(color: lea.textTertiary)),
              ],
            ),
            const SizedBox(width: LeaSpace.xl),
            _StepperButton(
              icon: Icons.add,
              onTap: value < max ? () => onChanged(value + 1) : null,
            ),
          ],
        ),
      ],
    );
  }
}

class _StepperButton extends StatefulWidget {
  const _StepperButton({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback? onTap;

  @override
  State<_StepperButton> createState() => _StepperButtonState();
}

class _StepperButtonState extends State<_StepperButton> {
  Timer? _timer;
  int _delay = 350;

  void _startRepeat() {
    if (widget.onTap == null) return;
    widget.onTap!.call();
    _delay = 350;
    _scheduleNext();
  }

  void _scheduleNext() {
    _timer = Timer(Duration(milliseconds: _delay), () {
      if (widget.onTap == null) {
        _stopRepeat();
        return;
      }
      widget.onTap!.call();
      // ускоряемся до минимума 50мс
      _delay = (_delay * 0.8).round().clamp(50, 350);
      _scheduleNext();
    });
  }

  void _stopRepeat() {
    _timer?.cancel();
    _timer = null;
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final lea = context.lea;
    final enabled = widget.onTap != null;
    return Material(
      color: lea.surface,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: enabled ? () {} : null, // только для ripple; логика в tapDown
        onTapDown: enabled ? (_) => _startRepeat() : null,
        onTapUp: (_) => _stopRepeat(),
        onTapCancel: _stopRepeat,
        child: Padding(
          padding: const EdgeInsets.all(LeaSpace.md),
          child: Icon(widget.icon,
              color: enabled ? lea.accent : lea.textTertiary,
              size: LeaIconSize.md),
        ),
      ),
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  const _PrimaryButton({
    required this.label,
    required this.onTap,
    this.enabled = true,
    this.filled = true,
  });
  final String label;
  final VoidCallback onTap;
  final bool enabled;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    final lea = context.lea;
    return Opacity(
      opacity: enabled ? 1 : 0.5,
      child: Material(
        color: filled ? lea.textPrimary : lea.surface,
        borderRadius: LeaRadius.buttonBR,
        child: InkWell(
          borderRadius: LeaRadius.buttonBR,
          onTap: enabled ? onTap : null,
          child: Container(
            height: LeaSize.button,
            padding: const EdgeInsets.symmetric(horizontal: LeaSpace.xxl),
            alignment: Alignment.center,
            child: Text(
              label,
              style: LeaType.button.copyWith(
                color: filled ? lea.textOnAccent : lea.textPrimary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
