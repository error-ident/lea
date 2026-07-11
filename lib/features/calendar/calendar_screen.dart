import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lea_design/lea_design.dart';

import '../../core/prediction/cycle_prediction.dart';
import '../../core/prediction/predict_cycle.dart';
import '../../core/providers/providers.dart';
import 'day_phase.dart';
import 'widgets/month_grid.dart';
import 'widgets/cycle_ring_painted.dart';
import 'full_calendar_screen.dart';
import '../day_entry/day_entry_sheet.dart';

class CalendarScreen extends ConsumerStatefulWidget {
  const CalendarScreen({super.key});

  @override
  ConsumerState<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends ConsumerState<CalendarScreen> {
  DateTime? _selected;

  @override
  Widget build(BuildContext context) {
    final lea = context.lea;
    final prediction = ref.watch(predictionProvider);
    final periodDaysAsync = ref.watch(periodDaysStreamProvider);
    final today = DateTime.now();

    return Scaffold(
      backgroundColor: lea.background,
      appBar: AppBar(
        toolbarHeight: 80,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_greeting(today),
                style: LeaType.h1.copyWith(color: lea.textPrimary)),
            const SizedBox(height: 2),
            Text(_todayLabel(today),
                style: LeaType.body.copyWith(color: lea.textSecondary)),
          ],
        ),
      ),
      body: prediction.when(
        // splash уже дождался прогноза; на случай микро-кадра показываем
        // просто фон (без крутилки), чтобы не мелькал лоадер
        loading: () => const SizedBox.expand(),
        error: (e, _) => Center(
          child: Text('Не удалось загрузить прогноз',
              style: LeaType.body.copyWith(color: lea.error)),
        ),
        data: (pred) {
          final periodDates = periodDaysAsync.maybeWhen(
            data: (rows) => rows.map((r) => r.date).toList(),
            orElse: () => <DateTime>[],
          );
          final loggedSet = periodDates
              .map((d) => DateTime(d.year, d.month, d.day))
              .toSet();
          final entryDates = ref.watch(datesWithEntriesProvider).maybeWhen(
                data: (s) => s,
                orElse: () => <DateTime>{},
              );
          final resolver = DayPhaseResolver(
            periodDays: periodDates,
            prediction: pred,
          );

          // главный экран: текущий + следующий месяц (чтобы прогноз был виден),
          // полная история — по кнопке «Все циклы» ниже
          final months = [
            DateTime(today.year, today.month),
            DateTime(today.year, today.month + 1),
          ];

          return GestureDetector(
            onVerticalDragEnd: (details) {
              // свайп вниз в самом верху → открыть полный календарь
              if ((details.primaryVelocity ?? 0) > 500) {
                _openFullCalendar();
              }
            },
            child: ListView(
              key: const PageStorageKey('calendar_scroll'),
              padding: const EdgeInsets.symmetric(
                horizontal: LeaSpace.xl,
                vertical: LeaSpace.lg,
              ),
              children: [
                _PredictionCard(prediction: pred),
                const SizedBox(height: LeaSpace.lg),
                _Legend(),
                const SizedBox(height: LeaSpace.xxl),
                for (final m in months) ...[
                  MonthGrid(
                    month: m,
                    resolver: resolver,
                    today: today,
                    selected: _selected,
                    loggedDays: entryDates,
                    onSelect: (d) => _onSelectDay(d, loggedSet.contains(
                        DateTime(d.year, d.month, d.day))),
                  ),
                  const SizedBox(height: LeaSpace.xxl),
                ],
                _AllCyclesButton(onTap: _openFullCalendar),
                const SizedBox(height: 80), // под FAB
              ],
            ),
          );
        },
      ),
    );
  }

  void _onSelectDay(DateTime day, bool isPeriod) {
    // №2: будущие дни не редактируем
    final now = DateTime.now();
    if (day.isAfter(DateTime(now.year, now.month, now.day))) return;
    setState(() => _selected = day);
    final lea = context.lea;
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: lea.surface,
      shape: RoundedRectangleBorder(borderRadius: LeaRadius.sheetTopBR),
      builder: (_) => _DayActions(
        date: day,
        isPeriod: isPeriod,
        onTogglePeriod: () async {
          final db = ref.read(databaseProvider);
          await db.togglePeriodDay(day);
          ref.invalidate(cycleStartsProvider);
          ref.invalidate(periodDaysStreamProvider);
          if (mounted) Navigator.of(context).pop();
        },
        onMarkPeriod: () async {
          // открыть полный календарь в режиме выделения диапазона
          if (mounted) Navigator.of(context).pop();
          _openFullCalendar();
        },
        onOpenEntry: () {
          Navigator.of(context).pop();
          showModalBottomSheet<void>(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (_) => DayEntrySheet(date: day),
          );
        },
      ),
    );
  }

  void _openFullCalendar() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const FullCalendarScreen()),
    );
  }

  static String _todayLabel(DateTime d) {
    const months = [
      'января', 'февраля', 'марта', 'апреля', 'мая', 'июня',
      'июля', 'августа', 'сентября', 'октября', 'ноября', 'декабря'
    ];
    return 'Сегодня, ${d.day} ${months[d.month - 1]}';
  }

  /// Приятное приветствие — зависит от времени суток, внутри набора
  /// выбирается по дню (стабильно в течение суток, меняется день ото дня).
  static String _greeting(DateTime d) {
    final hour = d.hour;
    final List<String> phrases;
    if (hour >= 5 && hour < 12) {
      phrases = _morning;
    } else if (hour >= 12 && hour < 18) {
      phrases = _day;
    } else if (hour >= 18 && hour < 23) {
      phrases = _evening;
    } else {
      phrases = _night;
    }
    final dayOfYear = d.difference(DateTime(d.year, 1, 1)).inDays;
    return phrases[dayOfYear % phrases.length];
  }

  static const _morning = [
    'Доброе утро 🌅',
    'Мягкого тебе утра',
    'С новым днём, милая',
    'Пусть утро будет добрым',
    'Потянись, ты проснулась ✨',
    'Доброе утро, ты прекрасна 💛',
    'Начни день с улыбки',
    'Пусть сегодня будет светло',
    'Ты выспалась? Обними себя',
    'Новый день — новые силы 🌷',
    'Тёплого утра тебе',
    'Ты проснулась — уже молодец',
    'Пусть кофе будет вкусным ☕',
    'Доброе утро, вселенная ждёт',
    'Дыши глубже, день начинается',
  ];

  static const _day = [
    'Хорошего дня!',
    'Ты справляешься, правда',
    'Не забудь отдохнуть 🍃',
    'Ты молодец, продолжай',
    'Сделай паузу, если устала',
    'Ты важнее любых дел',
    'Пусть день несёт радость',
    'Попей воды 💧',
    'Ты в своём ритме, и это хорошо',
    'Замедлись, ты не опаздываешь',
    'Ты храбрее, чем думаешь',
    'Всё идёт своим чередом',
    'Гордись собой хоть немного',
    'Ты нужна этому миру',
    'Побудь доброй к себе сегодня',
  ];

  static const _evening = [
    'Добрый вечер 🌙',
    'Ты хорошо потрудилась',
    'Пора отдохнуть, ты заслужила',
    'Вечер — время для себя',
    'Ты прожила этот день, молодец',
    'Пусть вечер будет тёплым 🕯️',
    'Отпусти этот день с миром',
    'Ты сделала достаточно',
    'Обними себя за сегодня',
    'Пусть на душе будет покой',
    'Ты заслужила отдых',
    'Спасибо тебе за этот день 💛',
    'Замедлись, день почти позади',
    'Побалуй себя вечером',
    'Ты — тёплый свет ✨',
  ];

  static const _night = [
    'Уже поздно, отдохни 🌙',
    'Тебе пора отдыхать',
    'Сладких снов, когда ляжешь',
    'Ночь — время восстановиться',
    'Береги себя, поспи',
    'Ты сильная, но отдых важен',
    'Пусть сон будет глубоким 🌛',
    'Отпусти тревоги до утра',
    'Ты в безопасности, отдыхай',
    'Доброй ночи, милая 💛',
  ];
}

class _AllCyclesButton extends StatelessWidget {
  const _AllCyclesButton({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final lea = context.lea;
    return Center(
      child: TextButton.icon(
        onPressed: onTap,
        icon: Icon(Icons.keyboard_arrow_down, color: lea.accent, size: 18),
        label: Text('Все циклы',
            style: LeaType.label.copyWith(color: lea.accent)),
      ),
    );
  }
}

class _DayActions extends StatelessWidget {
  const _DayActions({
    required this.date,
    required this.isPeriod,
    required this.onTogglePeriod,
    required this.onMarkPeriod,
    required this.onOpenEntry,
  });
  final DateTime date;
  final bool isPeriod;
  final VoidCallback onTogglePeriod;
  final VoidCallback onMarkPeriod;
  final VoidCallback onOpenEntry;

  @override
  Widget build(BuildContext context) {
    final lea = context.lea;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(LeaSpace.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_fmt(date),
                style: LeaType.h2.copyWith(color: lea.textPrimary)),
            const SizedBox(height: LeaSpace.lg),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(
                isPeriod ? Icons.close : Icons.water_drop_outlined,
                color: lea.phaseMenstrual,
              ),
              title: Text(
                isPeriod ? 'Убрать этот день' : 'Отметить этот день',
                style: LeaType.subtitle.copyWith(color: lea.textPrimary),
              ),
              onTap: onTogglePeriod,
            ),
            if (!isPeriod)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(Icons.date_range, color: lea.phaseMenstrual),
                title: Text(
                  'Отметить период (диапазоном)',
                  style: LeaType.subtitle.copyWith(color: lea.textPrimary),
                ),
                subtitle: Text(
                  'выделить начало и конец в календаре',
                  style: LeaType.caption.copyWith(color: lea.textSecondary),
                ),
                onTap: onMarkPeriod,
              ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.edit_note, color: lea.accent),
              title: Text(
                'Отметить симптомы и заметку',
                style: LeaType.subtitle.copyWith(color: lea.textPrimary),
              ),
              onTap: onOpenEntry,
            ),
          ],
        ),
      ),
    );
  }

  static String _fmt(DateTime d) {
    const m = [
      'января', 'февраля', 'марта', 'апреля', 'мая', 'июня',
      'июля', 'августа', 'сентября', 'октября', 'ноября', 'декабря',
    ];
    return '${d.day} ${m[d.month - 1]}';
  }
}

class _PredictionCard extends StatefulWidget {
  const _PredictionCard({required this.prediction});
  final CyclePrediction prediction;

  @override
  State<_PredictionCard> createState() => _PredictionCardState();
}

class _PredictionCardState extends State<_PredictionCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final lea = context.lea;
    final p = widget.prediction;

    // понятный заголовок: точность прогноза словами
    final certainty = switch (p.confidence) {
      ConfidenceLevel.high => 'ожидаются',
      ConfidenceLevel.medium => 'ориентировочно',
      ConfidenceLevel.low => 'примерно',
    };
    final dayInCycle = _dayInCycle(p);
    final phaseLabel = _phaseLabel(p, dayInCycle);

    return GestureDetector(
      onTap: () => setState(() => _expanded = !_expanded),
      child: Container(
        padding: const EdgeInsets.all(LeaSpace.lg),
        decoration: BoxDecoration(
          color: lea.surface,
          borderRadius: LeaRadius.cardBR,
          boxShadow: LeaShadow.card(lea.shadow),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('СЛЕДУЮЩИЕ МЕСЯЧНЫЕ $certainty'.toUpperCase(),
                          style: LeaType.sectionLabel
                              .copyWith(color: lea.textTertiary)),
                      const SizedBox(height: LeaSpace.sm),
                      Text(_fmt(p.nextPeriodStart),
                          style: LeaType.h1.copyWith(color: lea.textPrimary)),
                      const SizedBox(height: LeaSpace.xs),
                      Text(
                        _countdownText(p),
                        style:
                            LeaType.label.copyWith(color: lea.textSecondary),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: LeaSpace.lg),
                CycleRingPainted(
                  progress: _cycleProgress(p),
                  size: _expanded ? 96 : 72,
                ),
              ],
            ),
            // раскрываемые детали по тапу
            AnimatedCrossFade(
              duration: const Duration(milliseconds: 200),
              crossFadeState: _expanded
                  ? CrossFadeState.showSecond
                  : CrossFadeState.showFirst,
              firstChild: const SizedBox(width: double.infinity),
              secondChild: Padding(
                padding: const EdgeInsets.only(top: LeaSpace.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Divider(color: lea.border, height: 1),
                    const SizedBox(height: LeaSpace.md),
                    _detailRow(lea, 'Сейчас', phaseLabel),
                    if (dayInCycle != null)
                      _detailRow(lea, 'День цикла', '$dayInCycle-й'),
                    _detailRow(lea, 'Средний цикл',
                        '${p.medianCycleLength} ${_dayWord(p.medianCycleLength)}'),
                    _detailRow(
                        lea,
                        'Точность',
                        switch (p.confidence) {
                          ConfidenceLevel.high => 'высокая',
                          ConfidenceLevel.medium => 'средняя',
                          ConfidenceLevel.low => 'низкая — нужно больше данных',
                        }),
                    const SizedBox(height: LeaSpace.xs),
                    Text(
                      p.cyclesUsed > 0
                          ? 'Расчёт по ${p.cyclesUsed} последним циклам.'
                          : 'Добавьте первые дни — прогноз станет точнее.',
                      style:
                          LeaType.caption.copyWith(color: lea.textTertiary),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(LeaColors lea, String k, String v) => Padding(
        padding: const EdgeInsets.only(bottom: LeaSpace.xs),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(k, style: LeaType.label.copyWith(color: lea.textSecondary)),
            Text(v, style: LeaType.label.copyWith(color: lea.textPrimary)),
          ],
        ),
      );

  /// Честный текст обратного отсчёта. Три состояния:
  /// 1) будущее — «через N дней»;
  /// 2) внутри прогнозного окна (±margin) — «со дня на день»;
  /// 3) вышли за окно — «задержка N дней / цикл длиннее обычного».
  /// Третье состояние убирает «враньё в прошлом»: раньше карточка
  /// бесконечно показывала «со дня на день», даже когда цикл явно затянулся.
  String _countdownText(CyclePrediction p) {
    final marginText = '± ${p.marginDays} ${_dayWord(p.marginDays)}';
    final today = DateTime(
      DateTime.now().year,
      DateTime.now().month,
      DateTime.now().day,
    );
    final start = DateTime(
      p.nextPeriodStart.year,
      p.nextPeriodStart.month,
      p.nextPeriodStart.day,
    );
    final daysToNext = start.difference(today).inDays;

    // Верхняя граница прогнозного окна (центр + margin).
    final windowEnd = start.add(Duration(days: p.marginDays));
    final daysPastWindow = today.difference(windowEnd).inDays;

    if (daysToNext > 0) {
      return 'через $daysToNext ${_dayWord(daysToNext)} · $marginText';
    }
    if (daysPastWindow <= 0) {
      // Ещё внутри окна погрешности — нормально ждать со дня на день.
      return 'ожидаются со дня на день · $marginText';
    }
    // Вышли за окно. Честно показываем задержку, не притворяясь уверенными.
    final overdue = today.difference(start).inDays;
    if (p.isUncertain) {
      // При нерегулярном цикле не давим «задержкой» — цикл просто длиннее.
      return 'цикл длиннее обычного · задержка $overdue ${_dayWord(overdue)}';
    }
    return 'задержка $overdue ${_dayWord(overdue)} · прогноз уточнится';
  }

  int? _dayInCycle(CyclePrediction p) {
    final cycleLen = p.medianCycleLength;
    if (cycleLen <= 0) return null;
    final daysToNext = p.nextPeriodStart.difference(DateTime.now()).inDays;
    final d = cycleLen - daysToNext;
    return d > 0 ? d : null;
  }

  String _phaseLabel(CyclePrediction p, int? dayInCycle) {
    if (dayInCycle == null) return 'фаза неизвестна';
    final cycleLen = p.medianCycleLength;
    final ovulation = cycleLen - lutealForCycle(cycleLen);
    if (dayInCycle <= 5) return 'менструация';
    if ((dayInCycle - ovulation).abs() <= 1) return 'овуляция';
    if (dayInCycle < ovulation) return 'фолликулярная фаза';
    return 'лютеиновая фаза';
  }

  double _cycleProgress(CyclePrediction p) {
    final cycleLen = p.medianCycleLength;
    if (cycleLen <= 0) return 0;
    final daysToNext = p.nextPeriodStart.difference(DateTime.now()).inDays;
    final dayInCycle = cycleLen - daysToNext;
    return (dayInCycle / cycleLen).clamp(0.0, 1.0);
  }

  static String _fmt(DateTime d) {
    const months = [
      'января', 'февраля', 'марта', 'апреля', 'мая', 'июня',
      'июля', 'августа', 'сентября', 'октября', 'ноября', 'декабря',
    ];
    return '${d.day} ${months[d.month - 1]}';
  }

  static String _dayWord(int n) {
    if (n % 10 == 1 && n % 100 != 11) return 'день';
    if ([2, 3, 4].contains(n % 10) && ![12, 13, 14].contains(n % 100)) {
      return 'дня';
    }
    return 'дней';
  }
}

class _Legend extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final lea = context.lea;
    Widget item(Color c, String label, {bool dashed = false}) => Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 14,
              height: 14,
              decoration: BoxDecoration(
                color: dashed ? lea.forecastFill : c,
                shape: BoxShape.circle,
                border: dashed ? Border.all(color: lea.forecastDash) : null,
              ),
            ),
            const SizedBox(width: LeaSpace.xs),
            Text(label,
                style: LeaType.caption.copyWith(color: lea.textSecondary)),
          ],
        );

    return Wrap(
      spacing: LeaSpace.lg,
      runSpacing: LeaSpace.sm,
      children: [
        item(lea.phaseMenstrual, 'Менструация'),
        item(lea.phaseFollicular, 'Фолликулярная'),
        item(lea.phaseOvulation, 'Овуляция'),
        item(lea.phaseLuteal, 'Лютеиновая'),
        item(lea.forecastFill, 'Прогноз', dashed: true),
      ],
    );
  }
}
