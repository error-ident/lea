import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lea_design/lea_design.dart';

import '../../core/providers/providers.dart';
import '../../core/prediction/cycle_history.dart';
import '../../core/prediction/predict_cycle.dart';

class StatsScreen extends ConsumerStatefulWidget {
  const StatsScreen({super.key});

  @override
  ConsumerState<StatsScreen> createState() => _StatsScreenState();
}

enum _HistFilter { last3, last6, all }

class _StatsScreenState extends ConsumerState<StatsScreen> {
  _HistFilter _filter = _HistFilter.last6;

  @override
  Widget build(BuildContext context) {
    final lea = context.lea;
    final statsAsync = ref.watch(cycleHistoryProvider);

    return Scaffold(
      backgroundColor: lea.background,
      appBar: AppBar(title: const Text('Мои циклы')),
      body: statsAsync.when(
        loading: () =>
            Center(child: CircularProgressIndicator(color: lea.accent)),
        error: (e, _) => Center(child: Text('$e')),
        data: (stats) {
          if (stats.records.isEmpty) {
            return _Empty();
          }
          return ListView(
            padding: const EdgeInsets.all(LeaSpace.xl),
            children: [
              _SummaryCards(stats: stats),
              const SizedBox(height: LeaSpace.xxl),
              _HistoryHeader(
                filter: _filter,
                onFilter: (f) => setState(() => _filter = f),
              ),
              const SizedBox(height: LeaSpace.md),
              ..._buildHistory(context, stats),
              const SizedBox(height: 80),
            ],
          );
        },
      ),
    );
  }

  List<Widget> _buildHistory(BuildContext context, CycleStats stats) {
    var records = stats.records; // новые → старые
    if (_filter == _HistFilter.last3) {
      records = records.take(3).toList();
    } else if (_filter == _HistFilter.last6) {
      records = records.take(6).toList();
    }

    // группировка по годам (только заполненные)
    final widgets = <Widget>[];
    int? lastYear;
    for (final r in records) {
      if (r.year != lastYear) {
        lastYear = r.year;
        widgets.add(Padding(
          padding: const EdgeInsets.only(top: LeaSpace.md, bottom: LeaSpace.sm),
          child: Text('$lastYear',
              style: LeaType.sectionLabel
                  .copyWith(color: context.lea.textTertiary)),
        ));
      }
      widgets.add(_CycleRow(record: r));
    }
    return widgets;
  }
}

class _Empty extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final lea = context.lea;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(LeaSpace.xxxl),
        child: Text(
          'Отметьте первые месячные — здесь появятся ваши циклы.',
          textAlign: TextAlign.center,
          style: LeaType.body.copyWith(color: lea.textTertiary),
        ),
      ),
    );
  }
}

/// Верхние карточки: длина предыдущего цикла, месячных, колебания.
class _SummaryCards extends ConsumerWidget {
  const _SummaryCards({required this.stats});
  final CycleStats stats;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lea = context.lea;
    // предыдущий завершённый цикл
    final lastCompleted = stats.records.firstWhere(
      (r) => r.cycleLength != null,
      orElse: () => stats.records.first,
    );

    final (regLabel, regColor) = switch (stats.regularity) {
      CycleRegularity.regular => ('Регулярные', lea.success),
      CycleRegularity.moderate => ('Умеренно регулярные', lea.warning),
      CycleRegularity.irregular => ('Нерегулярные', lea.phaseMenstrual),
      CycleRegularity.unknown => ('Недостаточно данных', lea.textTertiary),
    };

    return Column(
      children: [
        _StatCard(
          title: 'Длина предыдущего цикла',
          value: lastCompleted.cycleLength != null
              ? '${lastCompleted.cycleLength} дней'
              : '—',
          subtitle: stats.avgCycle != null
              ? 'в среднем ${stats.avgCycle} дней'
              : null,
          accent: lea.accent,
        ),
        const SizedBox(height: LeaSpace.md),
        _StatCard(
          title: 'Длина предыдущих месячных',
          value: '${lastCompleted.periodLength} дней',
          subtitle: lastCompleted.periodNormal
              ? 'в пределах нормы'
              : 'вне обычного диапазона (2–7 дней)',
          subtitleColor: lastCompleted.periodNormal ? lea.success : lea.warning,
          accent: lea.phaseMenstrual,
        ),
        const SizedBox(height: LeaSpace.md),
        _StatCard(
          title: 'Колебания длины цикла',
          value: regLabel,
          valueColor: regColor,
          subtitle: stats.spread != null
              ? 'разброс ${stats.spread} дней'
              : null,
          accent: regColor,
        ),
        const SizedBox(height: LeaSpace.md),
        // --- Лютеиновая фаза: личная или популяционная оценка ---
        // Показываем ЧЕСТНО: если подтверждения нет, так и говорим, что
        // это оценка. Иначе человек решит, что Лея знает больше, чем знает.
        Builder(builder: (context) {
          final s = ref.watch(lutealSummaryProvider).valueOrNull;
          final days = s?.days;
          final n = s?.confirmedCycles ?? 0;
          return _StatCard(
            title: 'Лютеиновая фаза',
            value: days != null ? '$days дней' : '13–15 дней',
            valueColor: days != null ? lea.success : null,
            subtitle: days != null
                ? 'ваша, подтверждена по ${_cyclesWord(n)} с температурой'
                : 'общая оценка — ведите базальную температуру, '
                    'и Лея вычислит вашу',
            subtitleColor: days != null ? lea.success : lea.textSecondary,
            accent: days != null ? lea.success : lea.textTertiary,
          );
        }),
        const SizedBox(height: LeaSpace.md),
        // --- Овуляция в текущем цикле: измерена или рассчитана ---
        Builder(builder: (context) {
          final lh = ref.watch(lhOvulationDateProvider).valueOrNull;
          final luteal = ref.watch(lutealSummaryProvider).valueOrNull?.days;
          final String value;
          final String sub;
          final Color color;
          if (lh != null) {
            value = 'Подтверждена';
            sub = 'по тесту на овуляцию — прогноз опирается на измерение';
            color = lea.success;
          } else if (luteal != null) {
            value = 'Уточнена';
            sub = 'по вашей длине лютеиновой фазы';
            color = lea.success;
          } else {
            value = 'Расчёт по календарю';
            sub = 'отмечайте тесты на овуляцию — прогноз станет точнее';
            color = lea.textTertiary;
          }
          return _StatCard(
            title: 'Овуляция в этом цикле',
            value: value,
            valueColor: color,
            subtitle: sub,
            subtitleColor:
                color == lea.success ? lea.success : lea.textSecondary,
            accent: color,
          );
        }),
      ],
    );
  }

  /// «3 циклам» / «1 циклу» — чтобы подпись читалась естественно.
  static String _cyclesWord(int n) {
    if (n % 10 == 1 && n % 100 != 11) return '$n циклу';
    return '$n циклам';
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.title,
    required this.value,
    this.subtitle,
    this.subtitleColor,
    this.valueColor,
    required this.accent,
  });
  final String title;
  final String value;
  final String? subtitle;
  final Color? subtitleColor;
  final Color? valueColor;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final lea = context.lea;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(LeaSpace.lg),
      decoration: BoxDecoration(
        color: lea.surface,
        borderRadius: LeaRadius.cardBR,
        boxShadow: LeaShadow.card(lea.shadow),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 4,
                height: 16,
                decoration: BoxDecoration(
                  color: accent,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: LeaSpace.sm),
              Text(title,
                  style: LeaType.caption.copyWith(color: lea.textSecondary)),
            ],
          ),
          const SizedBox(height: LeaSpace.sm),
          Text(value,
              style: LeaType.h1
                  .copyWith(color: valueColor ?? lea.textPrimary)),
          if (subtitle != null) ...[
            const SizedBox(height: 2),
            Text(subtitle!,
                style: LeaType.caption
                    .copyWith(color: subtitleColor ?? lea.textTertiary)),
          ],
        ],
      ),
    );
  }
}

class _HistoryHeader extends StatelessWidget {
  const _HistoryHeader({required this.filter, required this.onFilter});
  final _HistFilter filter;
  final ValueChanged<_HistFilter> onFilter;

  @override
  Widget build(BuildContext context) {
    final lea = context.lea;
    Widget chip(String label, _HistFilter f) {
      final active = filter == f;
      return GestureDetector(
        onTap: () => onFilter(f),
        child: Container(
          padding: const EdgeInsets.symmetric(
              horizontal: LeaSpace.md, vertical: LeaSpace.xs),
          decoration: BoxDecoration(
            color: active ? lea.accent : lea.surface,
            borderRadius: BorderRadius.circular(LeaRadius.chip),
            border: Border.all(color: active ? lea.accent : lea.border),
          ),
          child: Text(label,
              style: LeaType.caption.copyWith(
                  color: active ? lea.textOnAccent : lea.textSecondary)),
        ),
      );
    }

    return Row(
      children: [
        Text('История циклов',
            style: LeaType.h2.copyWith(color: lea.textPrimary)),
        const Spacer(),
        chip('3', _HistFilter.last3),
        const SizedBox(width: LeaSpace.xs),
        chip('6', _HistFilter.last6),
        const SizedBox(width: LeaSpace.xs),
        chip('Все', _HistFilter.all),
      ],
    );
  }
}

/// Строка цикла: дата, длина, ряд точек по дням (фазы).
class _CycleRow extends ConsumerWidget {
  const _CycleRow({required this.record});
  final CycleRecord record;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lea = context.lea;
    final r = record;

    final title = r.isCurrent
        ? 'Текущий цикл'
        : '${_fmt(r.startDate)} – ${_fmt(r.endDate)}';
    final lenLabel =
        r.cycleLength != null ? '${r.cycleLength} дней' : '${_daysSoFar(r)} дней';

    return Padding(
      padding: const EdgeInsets.only(bottom: LeaSpace.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(title,
                  style: LeaType.subtitle.copyWith(
                      color: lea.textPrimary,
                      fontWeight:
                          r.isCurrent ? FontWeight.w700 : FontWeight.w500)),
              const Spacer(),
              Text(lenLabel,
                  style: LeaType.body.copyWith(color: lea.textSecondary)),
            ],
          ),
          const SizedBox(height: LeaSpace.sm),
          _DotsRow(record: r),
          // Расход средств гигиены за менструацию этого цикла.
          _HygieneSummary(record: r),
        ],
      ),
    );
  }

  int _daysSoFar(CycleRecord r) =>
      DateTime.now().difference(r.startDate).inDays + 1;

  static String _fmt(DateTime d) {
    const m = [
      'янв', 'фев', 'мар', 'апр', 'мая', 'июн',
      'июл', 'авг', 'сен', 'окт', 'ноя', 'дек'
    ];
    return '${d.day} ${m[d.month - 1]}';
  }
}

/// Ряд точек цикла: розовые = месячные, серые = обычные, бирюзовая = овуляция.
class _DotsRow extends StatelessWidget {
  const _DotsRow({required this.record});
  final CycleRecord record;

  @override
  Widget build(BuildContext context) {
    final lea = context.lea;
    final r = record;
    final total = r.cycleLength ??
        (DateTime.now().difference(r.startDate).inDays + 1);
    // ограничим визуал разумным числом точек
    final n = total.clamp(1, 45);
    // овуляция ≈ за (лютеиновая фаза) дней до конца цикла — динамически
    final ovulationDay = r.cycleLength != null
        ? r.cycleLength! - lutealForCycle(r.cycleLength!)
        : -1;

    return Wrap(
      spacing: 3,
      runSpacing: 3,
      children: [
        for (var day = 1; day <= n; day++)
          _dot(lea, day, r.periodLength, ovulationDay),
      ],
    );
  }

  Widget _dot(LeaColors lea, int day, int periodLen, int ovulationDay) {
    Color c;
    if (day <= periodLen) {
      c = lea.phaseMenstrual; // дни месячных
    } else if (ovulationDay > 0 && (day - ovulationDay).abs() <= 1) {
      c = lea.phaseOvulation; // окно овуляции
    } else {
      c = lea.border; // обычные дни
    }
    return Container(
      width: 9,
      height: 9,
      decoration: BoxDecoration(shape: BoxShape.circle, color: c),
    );
  }
}

/// Сводка расхода средств гигиены за менструацию цикла.
/// Показывается ТОЛЬКО если расход вводился — иначе ничего не рисуем,
/// чтобы не мусорить в истории у тех, кто счётчиками не пользуется.
///
/// Данные берутся из hygieneAllByDateProvider — он грузит весь расход ОДНИМ
/// запросом, а здесь мы лишь суммируем нужный диапазон локально. Раньше был
/// FutureBuilder с запросом к БД на каждую строку истории.
class _HygieneSummary extends ConsumerWidget {
  const _HygieneSummary({required this.record});
  final CycleRecord record;

  static const _labels = {
    'pads': 'прокладки',
    'tampons': 'тампоны',
    'cup': 'чаша',
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lea = context.lea;
    final all = ref.watch(hygieneAllByDateProvider).valueOrNull;
    if (all == null || all.isEmpty) return const SizedBox.shrink();

    // Менструация цикла: от начала цикла на periodLength дней.
    final start = DateTime(
        record.startDate.year, record.startDate.month, record.startDate.day);
    final lastDay = (record.periodLength - 1).clamp(0, 14);

    final total = <String, int>{};
    for (var i = 0; i <= lastDay; i++) {
      final day = start.add(Duration(days: i));
      final m = all[day];
      if (m == null) continue;
      for (final e in m.entries) {
        total[e.key] = (total[e.key] ?? 0) + e.value;
      }
    }
    if (total.isEmpty) return const SizedBox.shrink();

    final parts = <String>[];
    for (final e in _labels.entries) {
      final n = total[e.key] ?? 0;
      if (n > 0) parts.add('${e.value} — $n');
    }
    if (parts.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: LeaSpace.xs),
      child: Text(
        'Расход: ${parts.join(', ')}',
        style: LeaType.caption.copyWith(color: lea.textTertiary),
      ),
    );
  }
}
