import 'package:flutter/material.dart';
import 'package:lea_design/lea_design.dart';
import 'package:url_launcher/url_launcher.dart';
import '../splash/lea_mark.dart';

/// Экран «Поддержать разработку» — мягкая благодарность в духе Леи.
class SupportScreen extends StatelessWidget {
  const SupportScreen({super.key});

  static const _telegram = 'https://t.me/matherla';
  static const _tips = 'https://pay.cloudtips.ru/p/7546efde';

  Future<void> _open(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final lea = context.lea;
    final dark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: lea.background,
      appBar: AppBar(title: const Text('Поддержать')),
      body: ListView(
        padding: const EdgeInsets.all(LeaSpace.xl),
        children: [
          const SizedBox(height: LeaSpace.lg),
          Center(child: LeaMark(size: 96, dark: dark)),
          const SizedBox(height: LeaSpace.xl),
          Text(
            'Спасибо, что вы здесь',
            textAlign: TextAlign.center,
            style: LeaType.h1.copyWith(color: lea.textPrimary),
          ),
          const SizedBox(height: LeaSpace.md),
          Text(
            'Лея бесплатна и живёт без рекламы и подписок. '
            'Она не собирает и не продаёт ваши данные — и никогда не будет. '
            'Это маленький проект, сделанный с заботой.',
            textAlign: TextAlign.center,
            style: LeaType.body.copyWith(color: lea.textSecondary),
          ),
          const SizedBox(height: LeaSpace.md),
          Text(
            'Если Лея вам помогает и хочется поддержать развитие — '
            'это по желанию и очень тепло принимается. '
            'А если нет — просто пользуйтесь на здоровье.',
            textAlign: TextAlign.center,
            style: LeaType.body.copyWith(color: lea.textSecondary),
          ),
          const SizedBox(height: LeaSpace.xxl),

          // кнопка доната
          SizedBox(
            width: double.infinity,
            child: Material(
              color: lea.accent,
              borderRadius: LeaRadius.buttonBR,
              child: InkWell(
                borderRadius: LeaRadius.buttonBR,
                onTap: () => _open(_tips),
                child: Container(
                  height: LeaSize.button,
                  alignment: Alignment.center,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.favorite,
                          size: LeaIconSize.sm, color: lea.textOnAccent),
                      const SizedBox(width: LeaSpace.sm),
                      Text('Поддержать',
                          style: LeaType.button
                              .copyWith(color: lea.textOnAccent)),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: LeaSpace.sm),

          // Telegram автора
          SizedBox(
            width: double.infinity,
            child: Material(
              color: lea.surface,
              borderRadius: LeaRadius.buttonBR,
              child: InkWell(
                borderRadius: LeaRadius.buttonBR,
                onTap: () => _open(_telegram),
                child: Container(
                  height: LeaSize.button,
                  alignment: Alignment.center,
                  child: Text('Автор в Telegram',
                      style: LeaType.button
                          .copyWith(color: lea.textPrimary)),
                ),
              ),
            ),
          ),

          const SizedBox(height: LeaSpace.xl),
          Center(
            child: Text('С теплом, Matheria 🌸',
                style: LeaType.caption.copyWith(color: lea.textTertiary)),
          ),
        ],
      ),
    );
  }
}
