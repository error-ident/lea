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
class _SummaryCards extends StatelessWidget {
  const _SummaryCards({required this.stats});
  final CycleStats stats;

  @override
  Widget build(BuildContext context) {
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
      ],
    );
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
class _CycleRow extends StatelessWidget {
  const _CycleRow({required this.record});
  final CycleRecord record;

  @override
  Widget build(BuildContext context) {
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
