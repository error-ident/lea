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
import '../about/support_screen.dart';
import '../lock/set_pin_screen.dart';
import '../notifications/notifications_screen.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lea = context.lea;
    final dark = ref.watch(darkModeProvider);
    final themeId = ref.watch(themeIdProvider);

    return Scaffold(
      backgroundColor: lea.background,
      appBar: AppBar(title: const Text('Настройки')),
      body: ListView(
        padding: const EdgeInsets.all(LeaSpace.xl),
        children: [
          Text('ТЕМА',
              style: LeaType.sectionLabel.copyWith(color: lea.textTertiary)),
          const SizedBox(height: LeaSpace.md),
          Wrap(
            spacing: LeaSpace.sm,
            children: [
              for (final id in const [
                LeaThemeId.cream,
                LeaThemeId.lavender,
                LeaThemeId.sage,
                LeaThemeId.strawberry,
              ])
                ChoiceChip(
                  label: Text(_name(id)),
                  selected: themeId == id,
                  onSelected: (_) =>
                      ref.read(themeIdProvider.notifier).set(id),
                ),
            ],
          ),
          const SizedBox(height: LeaSpace.lg),
          SwitchListTile(
            title: Text('Тёмная тема',
                style: LeaType.subtitle.copyWith(color: lea.textPrimary)),
            value: dark,
            activeThumbColor: lea.accent,
            onChanged: (v) => ref.read(darkModeProvider.notifier).set(v),
          ),
          // Номера дней цикла на календаре — по умолчанию ВЫКЛЮЧЕНО.
          // Не всем нужно, а без номеров календарь читается чище.
          SwitchListTile(
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
          const SizedBox(height: LeaSpace.lg),
          Text('ИКОНКА ПРИЛОЖЕНИЯ',
              style: LeaType.sectionLabel.copyWith(color: lea.textTertiary)),
          const SizedBox(height: LeaSpace.md),
          const _IconPicker(),
          const Divider(),
          ListTile(
            title: Text('Напоминания',
                style: LeaType.subtitle.copyWith(color: lea.textPrimary)),
            subtitle: Text('Что напоминать, нейтральный текст',
                style: LeaType.caption.copyWith(color: lea.textSecondary)),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const NotificationsScreen()),
            ),
          ),
          ListTile(
            title: Text('Защита входа',
                style: LeaType.subtitle.copyWith(color: lea.textPrimary)),
            subtitle: Text('PIN / отпечаток / лицо',
                style: LeaType.caption.copyWith(color: lea.textSecondary)),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _openLockSettings(context),
          ),
          ListTile(
            title: Text('Резервная копия',
                style: LeaType.subtitle.copyWith(color: lea.textPrimary)),
            subtitle: Text('Зашифрованный файл',
                style: LeaType.caption.copyWith(color: lea.textSecondary)),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const BackupScreen()),
            ),
          ),
          ListTile(
            title: Text('О приложении',
                style: LeaType.subtitle.copyWith(color: lea.textPrimary)),
            subtitle: Text('Приватность, методика, источники',
                style: LeaType.caption.copyWith(color: lea.textSecondary)),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const AboutScreen()),
            ),
          ),
          ListTile(
            title: Text('Поддержать разработку',
                style: LeaType.subtitle.copyWith(color: lea.textPrimary)),
            trailing: const Icon(Icons.favorite_border),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const SupportScreen()),
            ),
          ),
        ],
      ),
    );
  }

  String _name(LeaThemeId id) => switch (id) {
        LeaThemeId.cream => 'Крем',
        LeaThemeId.lavender => 'Лаванда',
        LeaThemeId.sage => 'Шалфей',
        LeaThemeId.coal => 'Уголь',
        LeaThemeId.strawberry => 'Клубничка',
      };

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
class _IconPicker extends StatefulWidget {
  const _IconPicker();

  @override
  State<_IconPicker> createState() => _IconPickerState();
}

class _IconPickerState extends State<_IconPicker> {
  AppIconVariant _current = AppIconVariant.cream;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    AppIconService.current().then((v) {
      if (mounted) setState(() => _current = v);
    });
  }

  Future<void> _select(AppIconVariant v) async {
    if (_busy || v == _current) return;
    setState(() => _busy = true);
    final ok = await AppIconService.set(v);
    if (!mounted) return;
    setState(() {
      _busy = false;
      if (ok) _current = v;
    });
    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Не удалось сменить иконку')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
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
