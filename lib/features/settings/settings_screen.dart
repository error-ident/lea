import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lea_design/lea_design.dart';

import '../../core/providers/providers.dart';
import '../../core/database/settings_keys.dart';
import '../../core/security/lock_service.dart';
import '../../core/icon/app_icon_service.dart';
import '../splash/lea_mark.dart';
import '../backup/backup_screen.dart';
import '../about/about_screen.dart';
import '../medications/medications_screen.dart';
import 'diary_setup_screen.dart';
import '../about/support_screen.dart';
import '../lock/set_pin_screen.dart';
import '../notifications/notifications_screen.dart';
import 'appearance_screen.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lea = context.lea;

    return Scaffold(
      backgroundColor: lea.background,
      appBar: AppBar(title: const Text('Настройки')),
      body: ListView(
        padding: const EdgeInsets.all(LeaSpace.xl),
        children: [
          const SizedBox(height: LeaSpace.lg),
          // Номера дней цикла на календаре — по умолчанию ВЫКЛЮЧЕНО.
          // Не всем нужно, а без номеров календарь читается чище.
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            secondary: Icon(Icons.tag, color: lea.accent),
            title: Text('Номер дня цикла на календаре',
                style: LeaType.subtitle.copyWith(color: lea.textPrimary)),
            subtitle: Text(
              'показывать мелким шрифтом под датой',
              style: LeaType.caption.copyWith(color: lea.textSecondary),
            ),
            value: ref.watch(showCycleDayProvider).valueOrNull ?? false,
            activeThumbColor: lea.accent,
            onChanged: (v) async {
              final db = ref.read(databaseProvider);
              await db.setSetting(SettingsKeys.showCycleDay, v.toString());
              ref.invalidate(showCycleDayProvider);
            },
          ),
          // Средства гигиены — какие счётчики показывать в дне.
          // По умолчанию НИЧЕГО не выбрано: счётчиков нет, никому не мешают.
          const SizedBox(height: LeaSpace.lg),
          Text('СРЕДСТВА ГИГИЕНЫ',
              style: LeaType.sectionLabel.copyWith(color: lea.textTertiary)),
          const SizedBox(height: LeaSpace.xs),
          Text(
            'Отметьте, чем пользуетесь — в дне появятся счётчики расхода',
            style: LeaType.caption.copyWith(color: lea.textSecondary),
          ),
          const SizedBox(height: LeaSpace.md),
          const _HygienePicker(),
          const SizedBox(height: LeaSpace.lg),
          const Divider(),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(Icons.palette_outlined, color: lea.accent),
            title: Text('Оформление',
                style: LeaType.subtitle.copyWith(color: lea.textPrimary)),
            subtitle: Text('тема, тёмный режим, иконка',
                style: LeaType.caption.copyWith(color: lea.textSecondary)),
            trailing: Icon(Icons.chevron_right, color: lea.textTertiary),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const AppearanceScreen()),
            ),
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(Icons.tune, color: lea.accent),
            title: Text('Дневник',
                style: LeaType.subtitle.copyWith(color: lea.textPrimary)),
            subtitle: Text('какие разделы показывать и в каком порядке',
                style: LeaType.caption.copyWith(color: lea.textSecondary)),
            trailing: Icon(Icons.chevron_right, color: lea.textTertiary),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const DiarySetupScreen()),
            ),
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(Icons.medication_outlined, color: lea.accent),
            title: Text('Лекарства',
                style: LeaType.subtitle.copyWith(color: lea.textPrimary)),
            subtitle: Text('Препараты, расписание, история приёма',
                style: LeaType.caption.copyWith(color: lea.textSecondary)),
            trailing: Icon(Icons.chevron_right, color: lea.textTertiary),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const MedicationsScreen()),
            ),
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(Icons.notifications_outlined, color: lea.accent),
            title: Text('Напоминания',
                style: LeaType.subtitle.copyWith(color: lea.textPrimary)),
            subtitle: Text('Что напоминать, нейтральный текст',
                style: LeaType.caption.copyWith(color: lea.textSecondary)),
            trailing: Icon(Icons.chevron_right, color: lea.textTertiary),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const NotificationsScreen()),
            ),
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(Icons.lock_outline, color: lea.accent),
            title: Text('Защита входа',
                style: LeaType.subtitle.copyWith(color: lea.textPrimary)),
            subtitle: Text('PIN / отпечаток / лицо',
                style: LeaType.caption.copyWith(color: lea.textSecondary)),
            trailing: Icon(Icons.chevron_right, color: lea.textTertiary),
            onTap: () => _openLockSettings(context),
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(Icons.backup_outlined, color: lea.accent),
            title: Text('Резервная копия',
                style: LeaType.subtitle.copyWith(color: lea.textPrimary)),
            subtitle: Text('Зашифрованный файл',
                style: LeaType.caption.copyWith(color: lea.textSecondary)),
            trailing: Icon(Icons.chevron_right, color: lea.textTertiary),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const BackupScreen()),
            ),
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(Icons.info_outline, color: lea.accent),
            title: Text('О приложении',
                style: LeaType.subtitle.copyWith(color: lea.textPrimary)),
            subtitle: Text('Приватность, методика, источники',
                style: LeaType.caption.copyWith(color: lea.textSecondary)),
            trailing: Icon(Icons.chevron_right, color: lea.textTertiary),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const AboutScreen()),
            ),
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(Icons.favorite_outline, color: lea.accent),
            title: Text('Поддержать разработку',
                style: LeaType.subtitle.copyWith(color: lea.textPrimary)),
            trailing: Icon(Icons.chevron_right, color: lea.textTertiary),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const SupportScreen()),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openLockSettings(BuildContext context) async {
    final lock = LockService();
    final type = await lock.currentType();
    if (!context.mounted) return;

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: context.lea.surface,
      shape: RoundedRectangleBorder(borderRadius: LeaRadius.sheetTopBR),
      builder: (ctx) {
        final lea = ctx.lea;
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(LeaSpace.xl),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Защита входа',
                    style: LeaType.h2.copyWith(color: lea.textPrimary)),
                const SizedBox(height: LeaSpace.lg),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.pin_outlined, color: lea.accent),
                  title: Text('Установить PIN',
                      style: LeaType.subtitle.copyWith(color: lea.textPrimary)),
                  trailing: type == LockType.pin
                      ? Icon(Icons.check, color: lea.success)
                      : null,
                  onTap: () async {
                    Navigator.pop(ctx);
                    await Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const SetPinScreen()),
                    );
                  },
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.fingerprint, color: lea.accent),
                  title: Text('Биометрия (отпечаток/лицо)',
                      style: LeaType.subtitle.copyWith(color: lea.textPrimary)),
                  trailing: type == LockType.biometric
                      ? Icon(Icons.check, color: lea.success)
                      : null,
                  onTap: () async {
                    final can = await lock.canUseBiometric();
                    if (can) {
                      await lock.enableBiometric();
                    }
                    if (ctx.mounted) Navigator.pop(ctx);
                    if (context.mounted && !can) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('Биометрия недоступна на устройстве')),
                      );
                    }
                  },
                ),
                if (type != LockType.none)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(Icons.lock_open, color: lea.error),
                    title: Text('Отключить защиту',
                        style:
                            LeaType.subtitle.copyWith(color: lea.textPrimary)),
                    onTap: () async {
                      await lock.disable();
                      if (ctx.mounted) Navigator.pop(ctx);
                    },
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Выбор иконки приложения — три превью-карточки.
class IconPicker extends StatefulWidget {
  const IconPicker({super.key});

  @override
  State<IconPicker> createState() => IconPickerState();
}

class IconPickerState extends State<IconPicker> {
  AppIconVariant _current = AppIconVariant.cream;
  bool _busy = false;

  /// Время последней успешной смены. Нужен cooldown: пакет применяет иконку
  /// асинхронно (через перезапуск активности), и частые повторные вызовы
  /// накладываются друг на друга — приложение падало/закрывалось.
  /// Аналогичный throttle встроен в другие пакеты смены иконок.
  DateTime? _lastChange;
  static const _cooldown = Duration(seconds: 5);

  @override
  void initState() {
    super.initState();
    AppIconService.current().then((v) {
      if (mounted) setState(() => _current = v);
    });
  }

  Future<void> _select(AppIconVariant v) async {
    // 1) уже идёт смена — игнорируем
    if (_busy) return;
    // 2) тап по уже активной иконке — ничего не делаем
    if (v == _current) return;
    // 3) cooldown: не даём дёргать систему чаще, чем раз в несколько секунд
    final last = _lastChange;
    if (last != null && DateTime.now().difference(last) < _cooldown) {
      final left = _cooldown - DateTime.now().difference(last);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Подождите ${left.inSeconds + 1} с — иконка ещё применяется',
          ),
          duration: const Duration(seconds: 2),
        ),
      );
      return;
    }

    setState(() => _busy = true);
    final ok = await AppIconService.set(v);
    if (!mounted) return;

    if (ok) {
      _lastChange = DateTime.now();
      setState(() => _current = v);
      // _busy держим ещё немного: система применяет иконку асинхронно,
      // и в этот момент повторный вызов роняет приложение.
      await Future<void>.delayed(const Duration(seconds: 2));
      if (mounted) setState(() => _busy = false);
    } else {
      setState(() => _busy = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Не удалось сменить иконку')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Во время применения иконки блокируем весь ряд: и логически (IgnorePointer),
    // и визуально (притухание). Иначе пользователь тыкает, не понимая, почему
    // нет реакции, и накликивает падение.
    return IgnorePointer(
      ignoring: _busy,
      child: AnimatedOpacity(
        opacity: _busy ? 0.5 : 1.0,
        duration: const Duration(milliseconds: 150),
        child: Row(
          children: [
            for (final v in AppIconVariant.values) ...[
              Expanded(
                child: _IconCard(
                  variant: v,
                  selected: v == _current,
                  onTap: () => _select(v),
                ),
              ),
              if (v != AppIconVariant.values.last)
                const SizedBox(width: LeaSpace.sm),
            ],
          ],
        ),
      ),
    );
  }
}

class _IconCard extends StatelessWidget {
  const _IconCard({
    required this.variant,
    required this.selected,
    required this.onTap,
  });
  final AppIconVariant variant;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final lea = context.lea;
    // фон карточки-превью под вариант
    final (bg, isDark) = switch (variant) {
      AppIconVariant.cream => (const Color(0xFFFFF8F3), false),
      AppIconVariant.blush => (const Color(0xFFF6C2D0), false),
      AppIconVariant.dark => (const Color(0xFF2D2623), true),
    };

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: LeaRadius.cardBR,
        onTap: onTap,
        child: Column(
          children: [
            Container(
              height: 72,
              decoration: BoxDecoration(
                color: bg,
                borderRadius: LeaRadius.cardBR,
                border: Border.all(
                  color: selected ? lea.accent : lea.border,
                  width: selected ? 2.5 : 1,
                ),
              ),
              child: Center(
                child: variant == AppIconVariant.blush
                    ? const _WhiteMark(size: 44)
                    : LeaMark(size: 44, dark: isDark),
              ),
            ),
            const SizedBox(height: LeaSpace.xs),
            Text(
              variant.title,
              style: LeaType.caption.copyWith(
                color: selected ? lea.accent : lea.textSecondary,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Белый цветок для превью «Румянец».
class _WhiteMark extends StatelessWidget {
  const _WhiteMark({required this.size});
  final double size;
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _WhitePainter()),
    );
  }
}

class _WhitePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / 512.0;
    canvas.translate(size.width / 2, size.height / 2);
    canvas.scale(s);
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.95)
      ..isAntiAlias = true;
    for (var i = 0; i < 5; i++) {
      canvas.save();
      canvas.rotate(i * 72.0 * 3.14159265 / 180.0);
      canvas.drawOval(
        Rect.fromCenter(center: const Offset(0, -82), width: 88, height: 164),
        paint,
      );
      canvas.restore();
    }
    canvas.drawCircle(Offset.zero, 30, Paint()..color = const Color(0xFFF6C2D0));
  }

  @override
  bool shouldRepaint(_WhitePainter old) => false;
}

/// Выбор средств гигиены. По умолчанию ничего не выбрано — счётчиков
/// в дне нет, они не мешают тем, кому не нужны.
class _HygienePicker extends ConsumerWidget {
  const _HygienePicker();

  static const _labels = {
    'pads': 'Прокладки',
    'tampons': 'Тампоны',
    'cup': 'Чаша',
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected =
        ref.watch(hygieneProductsProvider).valueOrNull ?? const <String>{};

    return Wrap(
      spacing: LeaSpace.sm,
      runSpacing: LeaSpace.sm,
      children: [
        for (final e in _labels.entries)
          FilterChip(
            label: Text(e.value),
            selected: selected.contains(e.key),
            showCheckmark: false,
            onSelected: (on) async {
              final next = Set<String>.from(selected);
              if (on) {
                next.add(e.key);
              } else {
                next.remove(e.key);
              }
              final db = ref.read(databaseProvider);
              await db.setSetting(
                SettingsKeys.hygieneProducts,
                next.join(','),
              );
              ref.invalidate(hygieneProductsProvider);
            },
          ),
      ],
    );
  }
}
