import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lea_design/lea_design.dart';
// Только Value: drift экспортирует Column, который конфликтует
// с виджетом Column из Flutter.
import 'package:drift/drift.dart' show Value;

import '../../core/database/app_database.dart';
import '../../core/notifications/notification_service.dart';
import '../../core/providers/providers.dart';

/// Раздел «Лекарства».
///
/// Отдельно от напоминаний: у препарата есть название, дозировка, несколько
/// приёмов в день, курс с датами и история приёмов. Это данные, а не будильник.
///
/// Тон: пропуск приёма — факт, а не провал. Никаких укоров, «стриков» и
/// геймификации: человек и так знает, что забыл.
class MedicationsScreen extends ConsumerWidget {
  const MedicationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lea = context.lea;
    final meds = ref.watch(allMedicationsProvider).valueOrNull;

    return Scaffold(
      backgroundColor: lea.background,
      appBar: AppBar(title: const Text('Лекарства')),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: lea.accent,
        foregroundColor: lea.textOnAccent,
        onPressed: () => _openEditor(context, ref, null),
        icon: const Icon(Icons.add),
        label: const Text('Добавить'),
      ),
      body: meds == null
          ? const SizedBox.expand()
          : meds.isEmpty
              ? _Empty(lea: lea)
              : ListView(
                  padding: const EdgeInsets.all(LeaSpace.xl),
                  children: [
                    for (final m in meds.where((e) => !e.archived))
                      _MedCard(
                        med: m,
                        onTap: () => _openEditor(context, ref, m),
                      ),
                    if (meds.any((e) => e.archived)) ...[
                      const SizedBox(height: LeaSpace.lg),
                      Text('ЗАВЕРШЁННЫЕ',
                          style: LeaType.sectionLabel
                              .copyWith(color: lea.textTertiary)),
                      const SizedBox(height: LeaSpace.md),
                      for (final m in meds.where((e) => e.archived))
                        _MedCard(
                          med: m,
                          archived: true,
                          onTap: () => _openEditor(context, ref, m),
                        ),
                    ],
                    const SizedBox(height: 80),
                  ],
                ),
    );
  }

  void _openEditor(BuildContext context, WidgetRef ref, Medication? med) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => MedicationEditor(med: med)),
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty({required this.lea});
  final LeaColors lea;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(LeaSpace.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.medication_outlined, size: 48, color: lea.textTertiary),
            const SizedBox(height: LeaSpace.lg),
            Text(
              'Пока ничего не добавлено',
              style: LeaType.subtitle.copyWith(color: lea.textPrimary),
            ),
            const SizedBox(height: LeaSpace.xs),
            Text(
              'Здесь можно вести любые препараты: контрацептивы, витамины, '
              'курсовые лекарства. Лея напомнит о приёме и сохранит историю.',
              textAlign: TextAlign.center,
              style: LeaType.label.copyWith(color: lea.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}

class _MedCard extends StatelessWidget {
  const _MedCard({
    required this.med,
    required this.onTap,
    this.archived = false,
  });

  final Medication med;
  final VoidCallback onTap;
  final bool archived;

  @override
  Widget build(BuildContext context) {
    final lea = context.lea;
    final times = med.times.split(',').where((e) => e.isNotEmpty).toList();

    return Opacity(
      opacity: archived ? 0.55 : 1,
      child: Container(
        margin: const EdgeInsets.only(bottom: LeaSpace.md),
        decoration: BoxDecoration(
          color: lea.surface,
          borderRadius: LeaRadius.cardBR,
          border: Border.all(color: lea.border),
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: LeaSpace.lg,
            vertical: LeaSpace.xs,
          ),
          title: Text(med.name,
              style: LeaType.subtitle.copyWith(color: lea.textPrimary)),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (med.dosage.isNotEmpty)
                Text(med.dosage,
                    style:
                        LeaType.caption.copyWith(color: lea.textSecondary)),
              Text(
                times.isEmpty
                    ? 'без расписания'
                    : '${times.join(', ')}'
                        '${med.remind ? '' : ' · без напоминаний'}',
                style: LeaType.caption.copyWith(color: lea.textTertiary),
              ),
            ],
          ),
          trailing: Icon(Icons.chevron_right, color: lea.textTertiary),
          onTap: onTap,
        ),
      ),
    );
  }
}

/// Форма создания/редактирования препарата.
class MedicationEditor extends ConsumerStatefulWidget {
  const MedicationEditor({super.key, this.med});
  final Medication? med;

  @override
  ConsumerState<MedicationEditor> createState() => _MedicationEditorState();
}

class _MedicationEditorState extends ConsumerState<MedicationEditor> {
  late final TextEditingController _name =
      TextEditingController(text: widget.med?.name ?? '');
  late final TextEditingController _dosage =
      TextEditingController(text: widget.med?.dosage ?? '');
  late List<String> _times = (widget.med?.times ?? '')
      .split(',')
      .where((e) => e.isNotEmpty)
      .toList();
  late bool _remind = widget.med?.remind ?? true;
  late DateTime _start = widget.med?.startDate ?? DateTime.now();
  late DateTime? _end = widget.med?.endDate;
  late bool _archived = widget.med?.archived ?? false;

  @override
  void dispose() {
    _name.dispose();
    _dosage.dispose();
    super.dispose();
  }

  Future<void> _addTime() async {
    final t = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 9, minute: 0),
    );
    if (t == null) return;
    final s = '${t.hour.toString().padLeft(2, '0')}:'
        '${t.minute.toString().padLeft(2, '0')}';
    if (_times.contains(s)) return;
    setState(() {
      _times = [..._times, s]..sort();
    });
  }

  Future<void> _save() async {
    final name = _name.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Введите название')),
      );
      return;
    }
    final db = ref.read(databaseProvider);
    final times = _times.join(',');

    if (widget.med == null) {
      await db.insertMedication(
        MedicationsCompanion.insert(
          name: name,
          dosage: Value(_dosage.text.trim()),
          times: Value(times),
          remind: Value(_remind),
          startDate: _start,
          endDate: Value(_end),
        ),
      );
    } else {
      await db.updateMedication(
        widget.med!.copyWith(
          name: name,
          dosage: _dosage.text.trim(),
          times: times,
          remind: _remind,
          startDate: _start,
          endDate: Value(_end),
          archived: _archived,
        ),
      );
    }
    ref.invalidate(allMedicationsProvider);
    ref.invalidate(activeMedicationsProvider);
    await _rescheduleMeds();
    if (mounted) Navigator.of(context).pop();
  }

  /// Перепланировать напоминания после изменения списка препаратов.
  Future<void> _rescheduleMeds() async {
    final db = ref.read(databaseProvider);
    final active = await db.activeMedications();
    await NotificationService().scheduleMedications([
      for (final m in active)
        (id: m.id, name: m.name, times: m.times, remind: m.remind),
    ]);
  }

  Future<void> _delete() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Удалить препарат?'),
        content: const Text(
          'Вместе с ним удалится история приёмов. '
          'Если курс просто закончился — лучше завершить его, '
          'тогда история сохранится.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    final db = ref.read(databaseProvider);
    await db.deleteMedication(widget.med!.id);
    ref.invalidate(allMedicationsProvider);
    ref.invalidate(activeMedicationsProvider);
    await _rescheduleMeds();
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final lea = context.lea;
    final isNew = widget.med == null;

    return Scaffold(
      backgroundColor: lea.background,
      appBar: AppBar(
        title: Text(isNew ? 'Новый препарат' : 'Препарат'),
        actions: [
          if (!isNew)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: _delete,
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(LeaSpace.xl),
        children: [
          TextField(
            controller: _name,
            decoration: const InputDecoration(
              labelText: 'Название',
              hintText: 'Например: Циклодинон',
            ),
          ),
          const SizedBox(height: LeaSpace.lg),
          TextField(
            controller: _dosage,
            decoration: const InputDecoration(
              labelText: 'Дозировка (необязательно)',
              hintText: '1 таблетка / 25 мг',
            ),
          ),
          const SizedBox(height: LeaSpace.xxl),
          Text('ВРЕМЯ ПРИЁМА',
              style: LeaType.sectionLabel.copyWith(color: lea.textTertiary)),
          const SizedBox(height: LeaSpace.xs),
          Text(
            'Можно добавить несколько — например, утро и вечер',
            style: LeaType.caption.copyWith(color: lea.textSecondary),
          ),
          const SizedBox(height: LeaSpace.md),
          Wrap(
            spacing: LeaSpace.sm,
            runSpacing: LeaSpace.sm,
            children: [
              for (final t in _times)
                InputChip(
                  label: Text(t),
                  onDeleted: () => setState(() => _times.remove(t)),
                ),
              ActionChip(
                avatar: const Icon(Icons.add, size: 18),
                label: const Text('Время'),
                onPressed: _addTime,
              ),
            ],
          ),
          const SizedBox(height: LeaSpace.lg),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text('Напоминать',
                style: LeaType.subtitle.copyWith(color: lea.textPrimary)),
            subtitle: Text(
              _times.isEmpty
                  ? 'сначала добавьте время приёма'
                  : 'уведомление в указанное время',
              style: LeaType.caption.copyWith(color: lea.textSecondary),
            ),
            value: _remind && _times.isNotEmpty,
            activeThumbColor: lea.accent,
            onChanged: _times.isEmpty
                ? null
                : (v) => setState(() => _remind = v),
          ),
          const SizedBox(height: LeaSpace.lg),
          Text('ПЕРИОД',
              style: LeaType.sectionLabel.copyWith(color: lea.textTertiary)),
          const SizedBox(height: LeaSpace.md),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text('Начало',
                style: LeaType.body.copyWith(color: lea.textPrimary)),
            trailing: Text(_fmt(_start),
                style: LeaType.body.copyWith(color: lea.textSecondary)),
            onTap: () async {
              final d = await showDatePicker(
                context: context,
                initialDate: _start,
                firstDate: DateTime(2020),
                lastDate: DateTime(2100),
              );
              if (d != null) setState(() => _start = d);
            },
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text('Окончание',
                style: LeaType.body.copyWith(color: lea.textPrimary)),
            subtitle: Text('не указано — принимается постоянно',
                style: LeaType.caption.copyWith(color: lea.textSecondary)),
            trailing: Text(_end == null ? 'нет' : _fmt(_end!),
                style: LeaType.body.copyWith(color: lea.textSecondary)),
            onTap: () async {
              final d = await showDatePicker(
                context: context,
                initialDate: _end ?? _start.add(const Duration(days: 30)),
                firstDate: _start,
                lastDate: DateTime(2100),
              );
              setState(() => _end = d);
            },
          ),
          if (_end != null)
            TextButton(
              onPressed: () => setState(() => _end = null),
              child: const Text('Убрать дату окончания'),
            ),
          if (!isNew) ...[
            const SizedBox(height: LeaSpace.lg),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text('Курс завершён',
                  style: LeaType.subtitle.copyWith(color: lea.textPrimary)),
              subtitle: Text('уберём из активных, история сохранится',
                  style: LeaType.caption.copyWith(color: lea.textSecondary)),
              value: _archived,
              activeThumbColor: lea.accent,
              onChanged: (v) => setState(() => _archived = v),
            ),
            const SizedBox(height: LeaSpace.xxl),
            _IntakeHistory(medicationId: widget.med!.id, times: _times),
          ],
          const SizedBox(height: LeaSpace.xxl),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: lea.accent,
              foregroundColor: lea.textOnAccent,
              minimumSize: const Size.fromHeight(48),
            ),
            onPressed: _save,
            child: const Text('Сохранить'),
          ),
        ],
      ),
    );
  }

  static String _fmt(DateTime d) {
    const m = [
      'янв', 'фев', 'мар', 'апр', 'мая', 'июн',
      'июл', 'авг', 'сен', 'окт', 'ноя', 'дек'
    ];
    return '${d.day} ${m[d.month - 1]} ${d.year}';
  }
}

/// История приёмов за последние 30 дней.
///
/// ПРИНЦИП: показываем ФАКТЫ, а не оценку. Никаких «вы пропустили 5 приёмов»
/// и процентов соблюдения — человек и так знает, что забывал, а укоры в
/// приложении о здоровье работают против него. Просто сетка: где отмечено,
/// где нет.
///
/// Неотмеченный день ≠ пропущенный: человек мог принять и не нажать.
/// Поэтому нейтральный серый, а не красный.
class _IntakeHistory extends ConsumerWidget {
  const _IntakeHistory({required this.medicationId, required this.times});

  final int medicationId;
  final List<String> times;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lea = context.lea;
    final db = ref.watch(databaseProvider);
    final today = DateTime.now();
    final from = DateTime(today.year, today.month, today.day)
        .subtract(const Duration(days: 29));
    final to = DateTime(today.year, today.month, today.day);

    return FutureBuilder<Map<DateTime, Set<String>>>(
      future: db.intakeHistory(medicationId, from, to),
      builder: (context, snap) {
        final data = snap.data;
        if (data == null) return const SizedBox.shrink();

        // Сколько приёмов в день ожидается (0 = препарат без расписания).
        final perDay = times.isEmpty ? 1 : times.length;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('ПОСЛЕДНИЕ 30 ДНЕЙ',
                style: LeaType.sectionLabel.copyWith(color: lea.textTertiary)),
            const SizedBox(height: LeaSpace.sm),
            Text(
              'Отмеченные приёмы. Пустой день не обязательно значит пропуск — '
              'возможно, приём просто не отметили.',
              style: LeaType.caption.copyWith(color: lea.textSecondary),
            ),
            const SizedBox(height: LeaSpace.md),
            Wrap(
              spacing: 4,
              runSpacing: 4,
              children: [
                for (var i = 0; i < 30; i++)
                  _HistoryDot(
                    day: from.add(Duration(days: i)),
                    count: data[from.add(Duration(days: i))]?.length ?? 0,
                    perDay: perDay,
                    lea: lea,
                  ),
              ],
            ),
          ],
        );
      },
    );
  }
}

class _HistoryDot extends StatelessWidget {
  const _HistoryDot({
    required this.day,
    required this.count,
    required this.perDay,
    required this.lea,
  });

  final DateTime day;
  final int count;
  final int perDay;
  final LeaColors lea;

  @override
  Widget build(BuildContext context) {
    // Полностью отмечен — акцент; частично — полупрозрачный; пусто — фон.
    final Color color;
    if (count >= perDay) {
      color = lea.accent;
    } else if (count > 0) {
      color = lea.accent.withValues(alpha: 0.45);
    } else {
      color = lea.border;
    }

    return Tooltip(
      message: '${day.day}.${day.month.toString().padLeft(2, '0')} — '
          '${count == 0 ? 'не отмечено' : '$count из $perDay'}',
      child: Container(
        width: 22,
        height: 22,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(6),
        ),
        alignment: Alignment.center,
        child: Text(
          '${day.day}',
          style: LeaType.caption.copyWith(
            fontSize: 9,
            color: count >= perDay ? lea.textOnAccent : lea.textTertiary,
          ),
        ),
      ),
    );
  }
}
