import 'package:flutter/material.dart';
import 'package:lea_design/lea_design.dart';
import '../splash/lea_mark.dart';

/// Приветственный экран — самый первый для нового пользователя.
/// Логотип-цветок, слоган, обещание приватности, «Начать» / «Восстановить».
class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({
    super.key,
    required this.onStart,
    required this.onRestore,
  });

  final VoidCallback onStart;
  final VoidCallback onRestore;

  @override
  Widget build(BuildContext context) {
    final lea = context.lea;
    final dark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: lea.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(LeaSpace.xxl),
          child: Column(
            children: [
              const Spacer(flex: 2),
              // логотип-цветок
              LeaMark(size: 128, dark: dark),
              const SizedBox(height: LeaSpace.xl),
              Text(
                'Лея',
                style: LeaType.display.copyWith(
                  color: lea.textPrimary,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: LeaSpace.md),
              Text(
                'Тихий дневник вашего цикла.\nСпокойно, тепло, без лишнего.',
                textAlign: TextAlign.center,
                style: LeaType.body.copyWith(color: lea.textSecondary),
              ),
              const SizedBox(height: LeaSpace.xl),
              // плашка приватности
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: LeaSpace.lg,
                  vertical: LeaSpace.md,
                ),
                decoration: BoxDecoration(
                  color: lea.surface,
                  borderRadius: LeaRadius.cardBR,
                  border: Border.all(color: lea.border),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.lock_outline,
                        size: LeaIconSize.sm, color: lea.accent),
                    const SizedBox(width: LeaSpace.sm),
                    Flexible(
                      child: Text(
                        'Данные хранятся только у вас',
                        style: LeaType.caption
                            .copyWith(color: lea.textSecondary),
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(flex: 3),
              // кнопка «Начать»
              SizedBox(
                width: double.infinity,
                child: Material(
                  color: lea.textPrimary,
                  borderRadius: LeaRadius.buttonBR,
                  child: InkWell(
                    borderRadius: LeaRadius.buttonBR,
                    onTap: onStart,
                    child: Container(
                      height: LeaSize.button,
                      alignment: Alignment.center,
                      child: Text(
                        'Начать',
                        style: LeaType.button
                            .copyWith(color: lea.textOnAccent),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: LeaSpace.sm),
              TextButton(
                onPressed: onRestore,
                child: Text(
                  'Уже пользуетесь? Восстановить',
                  style: LeaType.button.copyWith(color: lea.textSecondary),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
