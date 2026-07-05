import 'package:flutter/material.dart';
import 'package:lea_design/lea_design.dart';

import '../day_phase.dart';
import 'day_cell.dart';

/// Сетка одного месяца. Неделя начинается с понедельника.
class MonthGrid extends StatelessWidget {
  const MonthGrid({
    super.key,
    required this.month,
    required this.resolver,
    required this.today,
    required this.selected,
    required this.loggedDays,
    required this.onSelect,
  });

  final DateTime month; // любой день месяца
  final DayPhaseResolver resolver;
  final DateTime today;
  final DateTime? selected;
  final Set<DateTime> loggedDays;
  final ValueChanged<DateTime> onSelect;

  static const _weekdays = ['Пн', 'Вт', 'Ср', 'Чт', 'Пт', 'Сб', 'Вс'];

  @override
  Widget build(BuildContext context) {
    final lea = context.lea;
    final first = DateTime(month.year, month.month, 1);
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    // Понедельник = 1 ... Воскресенье = 7
    final leadingEmpty = first.weekday - 1;

    final cells = <Widget>[];

    // дни недели
    for (final w in _weekdays) {
      cells.add(Center(
        child: Text(w,
            style: LeaType.caption.copyWith(color: lea.textTertiary)),
      ));
    }

    // пустые ячейки до первого дня
    for (var i = 0; i < leadingEmpty; i++) {
      cells.add(const SizedBox.shrink());
    }

    for (var d = 1; d <= daysInMonth; d++) {
      final date = DateTime(month.year, month.month, d);
      cells.add(DayCell(
        date: date,
        phase: resolver.phaseFor(date),
        isToday: _same(date, today),
        isSelected: selected != null && _same(date, selected!),
        hasLog: loggedDays.contains(DateTime(date.year, date.month, date.day)),
        inCurrentMonth: true,
        onTap: () => onSelect(date),
      ));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _monthTitle(month),
          style: LeaType.titleCard.copyWith(color: lea.textPrimary),
        ),
        const SizedBox(height: LeaSpace.sm),
        GridView.count(
          crossAxisCount: 7,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 2,
          crossAxisSpacing: 2,
          children: cells,
        ),
      ],
    );
  }

  bool _same(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  String _monthTitle(DateTime m) {
    const months = [
      'Январь', 'Февраль', 'Март', 'Апрель', 'Май', 'Июнь',
      'Июль', 'Август', 'Сентябрь', 'Октябрь', 'Ноябрь', 'Декабрь',
    ];
    return '${months[m.month - 1]} ${m.year}';
  }
}
