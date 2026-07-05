import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lea_design/lea_design.dart';

import '../../core/providers/providers.dart';
import 'day_phase.dart';
import 'widgets/month_grid.dart';
import '../day_entry/day_entry_sheet.dart';

/// Полноэкранный календарь: выбор года + 12 месяцев года.
/// Режим выделения месячных диапазоном (тап начала → тап конца → заливка)
/// для переноса истории. По умолчанию — текущий год, текущий месяц виден.
class FullCalendarScreen extends ConsumerStatefulWidget {
  const FullCalendarScreen({super.key});

  @override
  ConsumerState<FullCalendarScreen> createState() => _FullCalendarScreenState();
}

class _FullCalendarScreenState extends ConsumerState<FullCalendarScreen> {
  late int _year;
  bool _rangeMode = false;
  DateTime? _rangeStart;

  /// Множество отмеченных дней месячных (для умного снятия по тапу).
  Set<DateTime> _periodSet = {};

  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _year = DateTime.now().year;
    // после первого кадра — проскроллить к текущему месяцу
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToCurrentMonth());
  }

  void _scrollToCurrentMonth() {
    final now = DateTime.now();
    if (_year != now.year) return;
    // примерная высота одного месяца ~ 360px; прокрутка к текущему
    final offset = (now.month - 1) * 360.0;
    if (_scrollController.hasClients) {
      _scrollController.jumpTo(
        offset.clamp(0, _scrollController.position.maxScrollExtent),
      );
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final lea = context.lea;
    final entryDates = ref.watch(datesWithEntriesProvider).maybeWhen(
          data: (s) => s,
          orElse: () => <DateTime>{},
        );
    final today = DateTime.now();

    // НЕ используем .when с loading — иначе при обновлении ListView заменяется
    // спиннером и скролл слетает на январь. Держим последнее значение.
    final pred = ref.watch(predictionProvider).valueOrNull;
    final periodDates = ref.watch(periodDaysStreamProvider).valueOrNull
            ?.map((r) => r.date).toList() ??
        <DateTime>[];
    // обновляем множество отмеченных дней для умного снятия по тапу
    _periodSet = periodDates
        .map((d) => DateTime(d.year, d.month, d.day))
        .toSet();

    return Scaffold(
      backgroundColor: lea.background,
      appBar: AppBar(
        title: Text(_rangeMode ? 'Отметьте период' : 'Все циклы'),
        leading: IconButton(
          icon: const Icon(Icons.keyboard_arrow_down),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          TextButton.icon(
            onPressed: () => setState(() {
              _rangeMode = !_rangeMode;
              _rangeStart = null;
            }),
            icon: Icon(
              _rangeMode ? Icons.close : Icons.water_drop_outlined,
              color: _rangeMode ? lea.textSecondary : lea.phaseMenstrual,
              size: 18,
            ),
            label: Text(
              _rangeMode ? 'Готово' : 'Отметить',
              style: LeaType.label.copyWith(
                color: _rangeMode ? lea.textSecondary : lea.phaseMenstrual,
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          _YearSelector(
            year: _year,
            onPrev: () => setState(() => _year--),
            onNext: _year < today.year ? () => setState(() => _year++) : null,
          ),
          if (_rangeMode)
            Container(
              width: double.infinity,
              color: lea.phaseMenstrual.withValues(alpha: 0.12),
              padding: const EdgeInsets.all(LeaSpace.md),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      _rangeStart == null
                          ? 'Тап — начало периода. Тап по отмеченному дню — убрать его.'
                          : 'Теперь тапните последний день периода.',
                      style:
                          LeaType.label.copyWith(color: lea.phaseMenstrual),
                    ),
                  ),
                  if (_rangeStart != null)
                    TextButton(
                      onPressed: () => setState(() => _rangeStart = null),
                      child: Text('Отмена',
                          style: LeaType.label
                              .copyWith(color: lea.phaseMenstrual)),
                    ),
                ],
              ),
            ),
          Expanded(
            child: pred == null
                ? Center(child: CircularProgressIndicator(color: lea.accent))
                : Builder(builder: (context) {
                    final resolver = DayPhaseResolver(
                        periodDays: periodDates, prediction: pred);
                    final months = [
                      for (var m = 1; m <= 12; m++) DateTime(_year, m),
                    ];
                    return ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.symmetric(
                        horizontal: LeaSpace.xl,
                        vertical: LeaSpace.lg,
                      ),
                      itemCount: months.length + 1,
                      itemBuilder: (context, i) {
                        if (i == months.length) {
                          return const SizedBox(height: 40);
                        }
                        final m = months[i];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: LeaSpace.xxl),
                          child: MonthGrid(
                            month: m,
                            resolver: resolver,
                            today: today,
                            selected: _rangeMode ? _rangeStart : null,
                            loggedDays: entryDates,
                            onSelect: (d) => _onSelect(d),
                          ),
                        );
                      },
                    );
                  }),
          ),
        ],
      ),
    );
  }

  Future<void> _onSelect(DateTime day) async {
    final today = DateTime.now();
    final todayMidnight = DateTime(today.year, today.month, today.day);
    if (day.isAfter(todayMidnight)) return; // №2: будущее не трогаем

    if (_rangeMode) {
      final norm = DateTime(day.year, day.month, day.day);
      final db = ref.read(databaseProvider);

      // если ещё не начали диапазон и тапнули по уже отмеченному дню — СНЯТЬ его
      if (_rangeStart == null && _periodSet.contains(norm)) {
        await db.togglePeriodDay(norm); // удаляет день
        if (mounted) setState(() {});
        return;
      }

      if (_rangeStart == null) {
        // начало нового диапазона
        setState(() => _rangeStart = norm);
      } else {
        // конец — заливаем диапазон (перекрытие старого ОК: дни до-отметятся)
        await db.markPeriodBetween(_rangeStart!, norm);
        if (mounted) setState(() => _rangeStart = null);
      }
      return;
    }

    // обычный режим — открыть ввод дня (заметки/симптомы)
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DayEntrySheet(date: day),
    );
  }
}

class _YearSelector extends StatelessWidget {
  const _YearSelector({
    required this.year,
    required this.onPrev,
    required this.onNext,
  });
  final int year;
  final VoidCallback onPrev;
  final VoidCallback? onNext;

  @override
  Widget build(BuildContext context) {
    final lea = context.lea;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: LeaSpace.sm),
      decoration: BoxDecoration(
        color: lea.surface,
        border: Border(bottom: BorderSide(color: lea.border)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            icon: Icon(Icons.chevron_left, color: lea.accent),
            onPressed: onPrev,
          ),
          SizedBox(
            width: 80,
            child: Text(
              '$year',
              textAlign: TextAlign.center,
              style: LeaType.h2.copyWith(color: lea.textPrimary),
            ),
          ),
          IconButton(
            icon: Icon(Icons.chevron_right,
                color: onNext != null ? lea.accent : lea.textTertiary),
            onPressed: onNext,
          ),
        ],
      ),
    );
  }
}
