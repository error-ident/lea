import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lea_design/lea_design.dart';

import 'core/providers/providers.dart';
import 'features/calendar/calendar_screen.dart';
import 'features/stats/stats_screen.dart';
import 'features/settings/settings_screen.dart';
import 'features/day_entry/day_entry_sheet.dart';
import 'features/onboarding/onboarding_screen.dart';
import 'features/lock/lock_screen.dart';
import 'core/security/lock_service.dart';
import 'features/splash/splash_screen.dart';

class LeaApp extends ConsumerWidget {
  const LeaApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeId = ref.watch(themeIdProvider);
    final dark = ref.watch(darkModeProvider);

    // Светлая = выбранная цветовая тема; тёмная = тёмный вариант ТОЙ ЖЕ темы
    // (лаванда→лаванда-тёмная, шалфей→шалфей-тёмная), а не всегда уголь.
    final lightId = themeId == LeaThemeId.coal ? LeaThemeId.cream : themeId;

    return MaterialApp(
      title: 'Лея',
      debugShowCheckedModeBanner: false,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('ru')],
      locale: const Locale('ru'),
      theme: LeaTheme.build(lightId),
      darkTheme: LeaTheme.buildFromPalette(lightId.darkPalette),
      themeMode: dark ? ThemeMode.dark : ThemeMode.light,
      home: const LeaSplash(
        next: _LockGate(child: _RootGate()),
      ),
    );
  }
}

/// Проверяет защиту входа при старте. Если включена — показывает LockScreen.
class _LockGate extends StatefulWidget {
  const _LockGate({required this.child});
  final Widget child;

  @override
  State<_LockGate> createState() => _LockGateState();
}

class _LockGateState extends State<_LockGate> {
  final _lock = LockService();
  bool _checked = false;
  bool _locked = false;

  @override
  void initState() {
    super.initState();
    _check();
  }

  Future<void> _check() async {
    final enabled = await _lock.isLockEnabled();
    setState(() {
      _locked = enabled;
      _checked = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_checked) {
      return const _SplashLoader();
    }
    if (_locked) {
      return LockScreen(onUnlocked: () => setState(() => _locked = false));
    }
    return widget.child;
  }
}

/// Решает, показать онбординг или основное приложение.
class _RootGate extends ConsumerWidget {
  const _RootGate();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final done = ref.watch(onboardingDoneProvider);
    return done.when(
      loading: () => const _SplashLoader(),
      error: (_, __) => const _HomeShell(),
      data: (isDone) => isDone
          ? const _HomeShell()
          : OnboardingScreen(
              onDone: () => ref.invalidate(onboardingDoneProvider),
            ),
    );
  }
}

class _SplashLoader extends StatelessWidget {
  const _SplashLoader();
  @override
  Widget build(BuildContext context) {
    // Тот же фон, что у стартового сплэша — чтобы переходы между
    // проверкой блокировки / онбординга были бесшовными (без серого
    // мелькания и без крутилки: данные уже дождался LeaSplash).
    final dark = Theme.of(context).brightness == Brightness.dark;
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: RadialGradient(
          center: const Alignment(0, -0.32),
          radius: 1.1,
          colors: dark
              ? const [Color(0xFF2D2623), Color(0xFF221C1A)]
              : const [Color(0xFFFFF8F3), Color(0xFFF7EDE6)],
        ),
      ),
      child: const SizedBox.expand(),
    );
  }
}

/// Каркас с нижней навигацией: Календарь / Статистика / Настройки + FAB.
class _HomeShell extends StatefulWidget {
  const _HomeShell();

  @override
  State<_HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<_HomeShell> {
  int _index = 0;

  static const _screens = [
    CalendarScreen(),
    StatsScreen(),
    SettingsScreen(),
  ];

  void _openDayEntry() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const DayEntrySheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final lea = context.lea;

    return Scaffold(
      body: IndexedStack(index: _index, children: _screens),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      floatingActionButton: _index == 0
          ? Container(
              width: LeaSize.fab,
              height: LeaSize.fab,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: lea.accentGradient,
                boxShadow: LeaShadow.fab(lea.accent.withValues(alpha: 0.7)),
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: _openDayEntry,
                  child: Icon(Icons.add,
                      color: lea.textOnAccent, size: LeaIconSize.md),
                ),
              ),
            )
          : null,
      bottomNavigationBar: _BottomBar(
        index: _index,
        onChanged: (i) => setState(() => _index = i),
      ),
    );
  }
}

class _BottomBar extends StatelessWidget {
  const _BottomBar({required this.index, required this.onChanged});
  final int index;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final lea = context.lea;
    final items = [
      (Icons.calendar_today_outlined, 'Календарь'),
      (Icons.bar_chart_rounded, 'Статистика'),
      (Icons.settings_outlined, 'Настройки'),
    ];

    return Container(
      decoration: BoxDecoration(
        color: lea.surface,
        border: Border(top: BorderSide(color: lea.border)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: LeaSize.navbar,
          child: Row(
            children: [
              for (var i = 0; i < items.length; i++)
                Expanded(
                  child: InkWell(
                    onTap: () => onChanged(i),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          items[i].$1,
                          size: LeaIconSize.md,
                          color: i == index
                              ? lea.accent
                              : lea.textSecondary.withValues(alpha: 0.5),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          items[i].$2,
                          style: LeaType.caption.copyWith(
                            color: i == index
                                ? lea.accent
                                : lea.textSecondary.withValues(alpha: 0.5),
                          ),
                        ),
                      ],
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
