import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lea_design/lea_design.dart';

import '../../core/providers/providers.dart';
import 'settings_screen.dart' show IconPicker;

/// Оформление: цветовая тема, тёмный режим, иконка приложения.
/// Вынесено из основных настроек — там осталось только функциональное.
class AppearanceScreen extends ConsumerWidget {
  const AppearanceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lea = context.lea;
    final themeId = ref.watch(themeIdProvider);
    final dark = ref.watch(darkModeProvider);

    return Scaffold(
      backgroundColor: lea.background,
      appBar: AppBar(title: const Text('Оформление')),
      body: ListView(
        padding: const EdgeInsets.all(LeaSpace.xl),
        children: [
          Text('ЦВЕТОВАЯ ТЕМА',
              style: LeaType.sectionLabel.copyWith(color: lea.textTertiary)),
          const SizedBox(height: LeaSpace.md),
          // Сетка 2×2 — по две темы в строке, по центру.
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: LeaSpace.sm,
            crossAxisSpacing: LeaSpace.sm,
            childAspectRatio: 3.2,
            children: [
              for (final id in const [
                LeaThemeId.cream,
                LeaThemeId.lavender,
                LeaThemeId.sage,
                LeaThemeId.strawberry,
              ])
                _ThemeTile(
                  id: id,
                  selected: themeId == id,
                  onTap: () => ref.read(themeIdProvider.notifier).set(id),
                ),
            ],
          ),
          const SizedBox(height: LeaSpace.lg),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text('Тёмная тема',
                style: LeaType.subtitle.copyWith(color: lea.textPrimary)),
            value: dark,
            activeThumbColor: lea.accent,
            onChanged: (v) => ref.read(darkModeProvider.notifier).set(v),
          ),
          const SizedBox(height: LeaSpace.lg),
          Text('ИКОНКА ПРИЛОЖЕНИЯ',
              style: LeaType.sectionLabel.copyWith(color: lea.textTertiary)),
          const SizedBox(height: LeaSpace.md),
          const IconPicker(),
        ],
      ),
    );
  }
}

/// Плитка выбора темы — заливка цветом темы, без галочки.
class _ThemeTile extends StatelessWidget {
  const _ThemeTile({
    required this.id,
    required this.selected,
    required this.onTap,
  });

  final LeaThemeId id;
  final bool selected;
  final VoidCallback onTap;

  static const _names = {
    LeaThemeId.cream: 'Тёплый крем',
    LeaThemeId.lavender: 'Лаванда',
    LeaThemeId.sage: 'Шалфей',
    LeaThemeId.strawberry: 'Земляника',
  };

  @override
  Widget build(BuildContext context) {
    final lea = context.lea;
    return Material(
      color: selected ? lea.accentSoft : lea.surface,
      borderRadius: LeaRadius.cardBR,
      child: InkWell(
        borderRadius: LeaRadius.cardBR,
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: LeaRadius.cardBR,
            border: Border.all(
              color: selected ? lea.accent : lea.border,
              width: selected ? 2 : 1,
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            _names[id] ?? id.name,
            textAlign: TextAlign.center,
            style: LeaType.label.copyWith(color: lea.textPrimary),
          ),
        ),
      ),
    );
  }
}