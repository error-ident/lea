import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lea_design/lea_design.dart';

import '../../core/database/app_database.dart';
import '../../core/prediction/cycle_prediction.dart';
import '../../core/prediction/predict_cycle.dart';
import '../../core/providers/providers.dart';
import '../../l10n/strings.dart';
import 'day_phase.dart';
import 'phase_info.dart';
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

  /// Последний успешный прогноз. Нужен, чтобы календарь НЕ исчезал во время
  /// пересчёта.
  ///
  /// КОРЕНЬ МИГАНИЯ: setFlowForDay делает UPDATE таблицы periodDays. Drift
  /// пушит это в живой поток periodDaysStreamProvider → пересчитывается
  /// cycleStartsProvider → predictionProvider уходит в loading →
  /// prediction.when(loading:) возвращал пустой SizedBox → весь календарь
  /// исчезал на кадр. Интенсивность НЕ меняет дни цикла, поэтому показывать
  /// прошлый прогноз во время пересчёта абсолютно корректно.
  CyclePrediction? _lastPrediction;

  @override
  Widget build(BuildContext context) {
    final lea = context.lea;
    final prediction = ref.watch(predictionProvider);
    final periodDaysAsync = ref.watch(periodDaysStreamProvider);
    final today = DateTime.now();

    // Держим последний успешный прогноз.
    final predValue = prediction.valueOrNull ?? _lastPrediction;
    if (prediction.valueOrNull != null) {
      _lastPrediction = prediction.valueOrNull;
    }

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
      body: predValue == null
          ? (prediction.hasError
              ? Center(
                  child: Text('Не удалось загрузить прогноз',
                      style: LeaType.body.copyWith(color: lea.error)),
                )
              // splash уже дождался прогноза; на случай микро-кадра показываем
              // просто фон (без крутилки), чтобы не мелькал лоадер
              : const SizedBox.expand())
          : Builder(builder: (context) {
              final pred = predValue;
          final periodDates =
              (periodDaysAsync.valueOrNull ?? const []).map((r) => r.date).toList();
          final loggedSet = periodDates
              .map((d) => DateTime(d.year, d.month, d.day))
              .toSet();
          // valueOrNull СОХРАНЯЕТ предыдущее значение во время перезагрузки.
          // maybeWhen(orElse: {}) сбрасывал карту в пустую на один кадр —
          // из-за этого календарь под шторкой мигал (терял градации/точки).
          final entryDates =
              ref.watch(datesWithEntriesProvider).valueOrNull ?? <DateTime>{};
          final flowMap = ref.watch(flowByDateProvider).valueOrNull ??
              <DateTime, String>{};
          final showCycleDay =
              ref.watch(showCycleDayProvider).valueOrNull ?? false;
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
                    flowByDate: flowMap,
                    showCycleDay: showCycleDay,
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
        }),
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
        initialIsPeriod: isPeriod,
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

/// Шторка действий по дню.
///
/// UX-принцип: отметка дня — ОДИН тап, интенсивность НЕ обязательна.
/// Многие не заполняют интенсивность, и заставлять их нельзя. Поэтому:
/// тап отмечает день сразу, шторка остаётся открытой и показывает
/// ненавязчивый ряд интенсивности. Не выбрал — ничего страшного.
class _DayActions extends ConsumerStatefulWidget {
  const _DayActions({
    required this.date,
    required this.initialIsPeriod,
    required this.onMarkPeriod,
    required this.onOpenEntry,
  });
  final DateTime date;
  final bool initialIsPeriod;
  final VoidCallback onMarkPeriod;
  final VoidCallback onOpenEntry;

  @override
  ConsumerState<_DayActions> createState() => _DayActionsState();
}

class _DayActionsState extends ConsumerState<_DayActions> {
  late bool _isPeriod = widget.initialIsPeriod;
  List<TrackingOption> _flowOptions = const [];
  int? _flowId;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final db = ref.read(databaseProvider);
    final opts = await db.flowIntensityOptions();
    final flow = _isPeriod ? await db.flowForDay(widget.date) : null;
    if (!mounted) return;
    setState(() {
      _flowOptions = opts;
      _flowId = flow;
      _loading = false;
    });
  }

  Future<void> _togglePeriod() async {
    final db = ref.read(databaseProvider);
    await db.togglePeriodDay(widget.date);
    ref.invalidate(cycleStartsProvider);
    ref.invalidate(periodDaysStreamProvider);
    ref.invalidate(predictionProvider);
    ref.invalidate(flowByDateProvider);
    if (!mounted) return;
    final nowPeriod = !_isPeriod;
    setState(() {
      _isPeriod = nowPeriod;
      if (!nowPeriod) _flowId = null; // сняли день — интенсивность не нужна
    });
    // Шторку НЕ закрываем: если день только что отмечен, пользователь
    // может (по желанию!) сразу выбрать интенсивность.
    if (!nowPeriod && mounted) Navigator.of(context).pop();
  }

  Future<void> _selectFlow(int optionId) async {
    final db = ref.read(databaseProvider);
    // Повторный тап по тому же варианту — снять выбор.
    final next = _flowId == optionId ? null : optionId;
    await db.setFlowForDay(widget.date, next);
    // ВАЖНО: инвалидируем ТОЛЬКО провайдер интенсивностей.
    // periodDaysStreamProvider трогать нельзя — он перерисовывает состав
    // дней цикла, из-за чего календарь под шторкой мигал.
    ref.invalidate(flowByDateProvider);
    if (!mounted) return;
    setState(() => _flowId = next);
  }

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
            Text(_fmt(widget.date),
                style: LeaType.h2.copyWith(color: lea.textPrimary)),
            const SizedBox(height: LeaSpace.lg),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(
                _isPeriod ? Icons.close : Icons.water_drop_outlined,
                color: lea.phaseMenstrual,
              ),
              title: Text(
                _isPeriod ? 'Убрать этот день' : 'Отметить этот день',
                style: LeaType.subtitle.copyWith(color: lea.textPrimary),
              ),
              onTap: _togglePeriod,
            ),
            // ---- Интенсивность: только для отмеченных дней, по желанию ----
            if (_isPeriod && !_loading && _flowOptions.isNotEmpty) ...[
              const SizedBox(height: LeaSpace.xs),
              Text(
                'Интенсивность — если хотите',
                style: LeaType.caption.copyWith(color: lea.textTertiary),
              ),
              const SizedBox(height: LeaSpace.sm),
              Wrap(
                spacing: LeaSpace.sm,
                runSpacing: LeaSpace.sm,
                children: [
                  for (final o in _flowOptions)
                    _FlowChip(
                      label: L.t(o.titleKey),
                      selected: _flowId == o.id,
                      onTap: () => _selectFlow(o.id),
                    ),
                ],
              ),
              const SizedBox(height: LeaSpace.sm),
            ],
            if (!_isPeriod)
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
                onTap: widget.onMarkPeriod,
              ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.edit_note, color: lea.accent),
              title: Text(
                'Отметить симптомы и заметку',
                style: LeaType.subtitle.copyWith(color: lea.textPrimary),
              ),
              onTap: widget.onOpenEntry,
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
                    // ---- Что происходит в этой фазе ----
                    // Показывается только по раскрытию карточки — не занимает
                    // место постоянно и не навязывается.
                    ...(() {
                      final info =
                          PhaseInfo.forPhase(_phaseEnum(p, dayInCycle) ??
                              DayPhase.none);
                      if (info == null) return <Widget>[];
                      return <Widget>[
                        const SizedBox(height: LeaSpace.md),
                        Divider(color: lea.border, height: 1),
                        const SizedBox(height: LeaSpace.md),
                        Text(
                          info.title,
                          style: LeaType.subtitle
                              .copyWith(color: lea.textPrimary),
                        ),
                        const SizedBox(height: LeaSpace.xs),
                        Text(
                          info.whatHappens,
                          style: LeaType.label
                              .copyWith(color: lea.textSecondary),
                        ),
                        const SizedBox(height: LeaSpace.sm),
                        Text(
                          info.someNotice,
                          style: LeaType.label
                              .copyWith(color: lea.textSecondary),
                        ),
                        const SizedBox(height: LeaSpace.sm),
                        Text(
                          PhaseInfo.disclaimer,
                          style: LeaType.caption
                              .copyWith(color: lea.textTertiary),
                        ),
                      ];
                    })(),
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

  /// Та же логика, что в [_phaseLabel], но возвращает фазу как enum —
  /// чтобы подтянуть описание из PhaseInfo.
  DayPhase? _phaseEnum(CyclePrediction p, int? dayInCycle) {
    if (dayInCycle == null) return null;
    final cycleLen = p.medianCycleLength;
    final ovulation = cycleLen - lutealForCycle(cycleLen);
    if (dayInCycle <= 5) return DayPhase.menstrual;
    if ((dayInCycle - ovulation).abs() <= 1) return DayPhase.ovulation;
    if (dayInCycle < ovulation) return DayPhase.follicular;
    return DayPhase.luteal;
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

/// Чип выбора интенсивности менструации. Компактный, необязательный.
/// Повторный тап по выбранному — снимает выбор.
class _FlowChip extends StatelessWidget {
  const _FlowChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final lea = context.lea;
    return Material(
      color: selected ? lea.phaseMenstrual : lea.accentSoft,
      borderRadius: LeaRadius.buttonBR,
      child: InkWell(
        borderRadius: LeaRadius.buttonBR,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: LeaSpace.md,
            vertical: LeaSpace.sm,
          ),
          child: Text(
            label,
            style: LeaType.label.copyWith(
              color: selected ? lea.textOnAccent : lea.textPrimary,
            ),
          ),
        ),
      ),
    );
  }
}
