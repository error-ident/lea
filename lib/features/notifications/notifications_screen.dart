import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lea_design/lea_design.dart';

import '../../core/notifications/notification_service.dart';
import '../../core/providers/providers.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lea = context.lea;
    final settingsAsync = ref.watch(notificationSettingsProvider);

    return Scaffold(
      backgroundColor: lea.background,
      appBar: AppBar(title: const Text('Напоминания')),
      body: settingsAsync.when(
        loading: () =>
            Center(child: CircularProgressIndicator(color: lea.accent)),
        error: (e, _) => Center(child: Text('$e')),
        data: (s) => _Body(settings: s),
      ),
    );
  }
}

class _Body extends ConsumerStatefulWidget {
  const _Body({required this.settings});
  final NotificationSettings settings;

  @override
  ConsumerState<_Body> createState() => _BodyState();
}

class _BodyState extends ConsumerState<_Body> {
  late NotificationSettings s;
  bool _permissionGranted = true;

  @override
  void initState() {
    super.initState();
    s = widget.settings;
    _checkPermission();
  }

  Future<void> _checkPermission() async {
    final granted = await NotificationService().hasPermission();
    if (mounted) setState(() => _permissionGranted = granted);
  }

  Future<void> _requestPermission() async {
    await NotificationService().requestPermissions();
    await _checkPermission();
    // после выдачи разрешения перепланируем текущие настройки
    if (_permissionGranted) {
      final pred = await ref.read(predictionProvider.future);
      await NotificationService().reschedule(pred, s);
    }
  }

  Future<void> _save(NotificationSettings next) async {
    setState(() => s = next);
    final db = ref.read(databaseProvider);
    await db.setSetting('notification_settings', jsonEncode(next.toJson()));
    ref.invalidate(notificationSettingsProvider);
    final pred = await ref.read(predictionProvider.future);
    await NotificationService().reschedule(pred, next);
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(LeaSpace.xl),
      children: [
        // баннер-подсказка если уведомления не разрешены
        if (!_permissionGranted) _PermissionBanner(onTap: _requestPermission),
        // ---- Скоро месячные ----
        _ToggleCard(
          title: 'Скоро месячные',
          enabled: s.periodEnabled,
          onToggle: (v) => _save(s.copyWith(periodEnabled: v)),
          children: [
            _DaysSlider(
              label: 'Предупредить за',
              days: s.daysBeforePeriod,
              onChanged: (v) => _save(s.copyWith(daysBeforePeriod: v)),
            ),
            _TextField(
              label: 'Текст напоминания',
              value: s.periodText,
              onChanged: (v) => _save(s.copyWith(periodText: v)),
            ),
          ],
        ),
        // ---- Скоро овуляция ----
        _ToggleCard(
          title: 'Скоро овуляция',
          enabled: s.ovulationEnabled,
          onToggle: (v) => _save(s.copyWith(ovulationEnabled: v)),
          children: [
            _DaysSlider(
              label: 'Предупредить за',
              days: s.daysBeforeOvulation,
              onChanged: (v) => _save(s.copyWith(daysBeforeOvulation: v)),
            ),
            _TextField(
              label: 'Текст напоминания',
              value: s.ovulationText,
              onChanged: (v) => _save(s.copyWith(ovulationText: v)),
            ),
          ],
        ),
        const SizedBox(height: LeaSpace.lg),
        // ---- Время для прогнозных напоминаний ----
        _TimeCard(
          title: 'Время уведомлений',
          hour: s.hour,
          minute: s.minute,
          onChanged: (h, m) => _save(s.copyWith(hour: h, minute: m)),
        ),
        const SizedBox(height: LeaSpace.xxl),
        // ---- Таблетки ----
        _ListSection(
          title: 'Таблетки',
          addLabel: 'Добавить таблетку',
          items: s.pills,
          defaultLabel: '',
          onChanged: (list) => _save(s.copyWith(pills: list)),
        ),
        const SizedBox(height: LeaSpace.xxl),
        // ---- Вода ----
        _ListSection(
          title: 'Вода',
          addLabel: 'Добавить напоминание',
          items: s.waters,
          defaultLabel: 'Попить воды',
          onChanged: (list) => _save(s.copyWith(waters: list)),
        ),
        const SizedBox(height: 80),
      ],
    );
  }
}

/// Карточка с переключателем и раскрывающимися настройками.
class _ToggleCard extends StatelessWidget {
  const _ToggleCard({
    required this.title,
    required this.enabled,
    required this.onToggle,
    required this.children,
  });
  final String title;
  final bool enabled;
  final ValueChanged<bool> onToggle;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final lea = context.lea;
    return Container(
      margin: const EdgeInsets.only(bottom: LeaSpace.md),
      padding: const EdgeInsets.all(LeaSpace.lg),
      decoration: BoxDecoration(
        color: lea.surface,
        borderRadius: LeaRadius.cardBR,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(title,
                    style:
                        LeaType.subtitle.copyWith(color: lea.textPrimary)),
              ),
              Switch(value: enabled, onChanged: onToggle),
            ],
          ),
          if (enabled) ...[
            const SizedBox(height: LeaSpace.md),
            ...children,
          ],
        ],
      ),
    );
  }
}

/// Слайдер «за N дней» (0-10).
class _DaysSlider extends StatelessWidget {
  const _DaysSlider({
    required this.label,
    required this.days,
    required this.onChanged,
  });
  final String label;
  final int days;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final lea = context.lea;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label,
                style: LeaType.label.copyWith(color: lea.textSecondary)),
            Text(
              days == 0 ? 'в день события' : '$days ${_dayWord(days)}',
              style: LeaType.label.copyWith(color: lea.accent),
            ),
          ],
        ),
        Slider(
          value: days.toDouble(),
          min: 0,
          max: 10,
          divisions: 10,
          label: '$days',
          onChanged: (v) => onChanged(v.round()),
        ),
      ],
    );
  }

  static String _dayWord(int n) {
    if (n % 10 == 1 && n % 100 != 11) return 'день';
    if ([2, 3, 4].contains(n % 10) && ![12, 13, 14].contains(n % 100)) {
      return 'дня';
    }
    return 'дней';
  }
}

/// Поле редактирования текста напоминания.
class _TextField extends StatefulWidget {
  const _TextField({
    required this.label,
    required this.value,
    required this.onChanged,
  });
  final String label;
  final String value;
  final ValueChanged<String> onChanged;

  @override
  State<_TextField> createState() => _TextFieldState();
}

class _TextFieldState extends State<_TextField> {
  late final TextEditingController _ctrl;
  bool _changed = false;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.value);
    _ctrl.addListener(() {
      final changed = _ctrl.text != widget.value;
      if (changed != _changed) setState(() => _changed = changed);
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _commit() {
    widget.onChanged(_ctrl.text);
    setState(() => _changed = false);
    FocusScope.of(context).unfocus();
  }

  @override
  Widget build(BuildContext context) {
    final lea = context.lea;
    return Padding(
      padding: const EdgeInsets.only(top: LeaSpace.sm),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _ctrl,
              style: LeaType.body.copyWith(color: lea.textPrimary),
              decoration: InputDecoration(
                labelText: widget.label,
                labelStyle:
                    LeaType.label.copyWith(color: lea.textSecondary),
              ),
              onSubmitted: (_) => _commit(),
              textInputAction: TextInputAction.done,
            ),
          ),
          // кнопка появляется только когда текст изменён
          if (_changed)
            Padding(
              padding: const EdgeInsets.only(left: LeaSpace.sm),
              child: FilledButton(
                onPressed: _commit,
                style: FilledButton.styleFrom(
                  backgroundColor: lea.accent,
                  padding: const EdgeInsets.symmetric(
                      horizontal: LeaSpace.md),
                ),
                child: const Text('Сохранить'),
              ),
            ),
        ],
      ),
    );
  }
}

/// Карточка выбора времени.
class _TimeCard extends StatelessWidget {
  const _TimeCard({
    required this.title,
    required this.hour,
    required this.minute,
    required this.onChanged,
  });
  final String title;
  final int hour;
  final int minute;
  final void Function(int hour, int minute) onChanged;

  @override
  Widget build(BuildContext context) {
    final lea = context.lea;
    final t = '${hour.toString().padLeft(2, '0')}:'
        '${minute.toString().padLeft(2, '0')}';
    return InkWell(
      onTap: () async {
        final picked = await showTimePicker(
          context: context,
          initialTime: TimeOfDay(hour: hour, minute: minute),
        );
        if (picked != null) onChanged(picked.hour, picked.minute);
      },
      child: Container(
        padding: const EdgeInsets.all(LeaSpace.lg),
        decoration: BoxDecoration(
          color: lea.surface,
          borderRadius: LeaRadius.cardBR,
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(title,
                  style: LeaType.subtitle.copyWith(color: lea.textPrimary)),
            ),
            Text(t, style: LeaType.h2.copyWith(color: lea.accent)),
            const SizedBox(width: LeaSpace.sm),
            Icon(Icons.access_time, color: lea.textSecondary, size: 18),
          ],
        ),
      ),
    );
  }
}

/// Секция со списком повторяющихся напоминаний (таблетки/вода).
class _ListSection extends StatelessWidget {
  const _ListSection({
    required this.title,
    required this.addLabel,
    required this.items,
    required this.defaultLabel,
    required this.onChanged,
  });
  final String title;
  final String addLabel;
  final List<TimedReminder> items;
  final String defaultLabel;
  final ValueChanged<List<TimedReminder>> onChanged;

  @override
  Widget build(BuildContext context) {
    final lea = context.lea;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: LeaType.h2.copyWith(color: lea.textPrimary)),
        const SizedBox(height: LeaSpace.md),
        for (final item in items)
          _ReminderRow(
            item: item,
            onChanged: (updated) {
              final list = items
                  .map((e) => e.id == updated.id ? updated : e)
                  .toList();
              onChanged(list);
            },
            onDelete: () =>
                onChanged(items.where((e) => e.id != item.id).toList()),
          ),
        const SizedBox(height: LeaSpace.sm),
        OutlinedButton.icon(
          onPressed: () {
            // время новой записи — на час позже последней (или 9:00)
            int h = 9, m = 0;
            if (items.isNotEmpty) {
              final last = items.last;
              h = (last.hour + 1) % 24;
              m = last.minute;
            }
            final id = 1000 + DateTime.now().millisecondsSinceEpoch % 100000;
            final next = [
              ...items,
              TimedReminder(id: id, label: defaultLabel, hour: h, minute: m),
            ];
            onChanged(next);
          },
          icon: const Icon(Icons.add, size: 18),
          label: Text(addLabel),
        ),
      ],
    );
  }
}

class _ReminderRow extends StatelessWidget {
  const _ReminderRow({
    required this.item,
    required this.onChanged,
    required this.onDelete,
  });
  final TimedReminder item;
  final ValueChanged<TimedReminder> onChanged;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final lea = context.lea;
    final t = '${item.hour.toString().padLeft(2, '0')}:'
        '${item.minute.toString().padLeft(2, '0')}';
    return Container(
      margin: const EdgeInsets.only(bottom: LeaSpace.sm),
      padding: const EdgeInsets.symmetric(
          horizontal: LeaSpace.lg, vertical: LeaSpace.sm),
      decoration: BoxDecoration(
        color: lea.surface,
        borderRadius: LeaRadius.cardSmBR,
      ),
      child: Row(
        children: [
          Switch(
            value: item.enabled,
            onChanged: (v) => onChanged(item.copyWith(enabled: v)),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => _editLabel(context),
              child: Row(
                children: [
                  Flexible(
                    child: Text(
                      item.label.isEmpty ? 'Нажмите, чтобы назвать' : item.label,
                      style: LeaType.body.copyWith(
                        color: item.label.isEmpty
                            ? lea.textTertiary
                            : lea.textPrimary,
                        decoration: TextDecoration.underline,
                        decorationColor: lea.textTertiary,
                        decorationStyle: TextDecorationStyle.dotted,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(Icons.edit, size: 13, color: lea.textTertiary),
                ],
              ),
            ),
          ),
          TextButton(
            onPressed: () async {
              final picked = await showTimePicker(
                context: context,
                initialTime:
                    TimeOfDay(hour: item.hour, minute: item.minute),
              );
              if (picked != null) {
                onChanged(
                    item.copyWith(hour: picked.hour, minute: picked.minute));
              }
            },
            child: Text(t, style: LeaType.subtitle.copyWith(color: lea.accent)),
          ),
          IconButton(
            icon: Icon(Icons.delete_outline, color: lea.error, size: 20),
            onPressed: onDelete,
          ),
        ],
      ),
    );
  }

  Future<void> _editLabel(BuildContext context) async {
    final lea = context.lea;
    final ctrl = TextEditingController(text: item.label);
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: lea.surface,
        title: Text('Название',
            style: LeaType.h2.copyWith(color: lea.textPrimary)),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'Например, витамин D'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, ctrl.text),
            child: const Text('Сохранить'),
          ),
        ],
      ),
    );
    if (result != null) onChanged(item.copyWith(label: result));
  }
}

/// Баннер-подсказка: уведомления не разрешены, кнопка запроса.
class _PermissionBanner extends StatelessWidget {
  const _PermissionBanner({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final lea = context.lea;
    return Container(
      margin: const EdgeInsets.only(bottom: LeaSpace.lg),
      padding: const EdgeInsets.all(LeaSpace.lg),
      decoration: BoxDecoration(
        color: lea.accentSoft,
        borderRadius: LeaRadius.cardBR,
        border: Border.all(color: lea.accent, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.notifications_off_outlined,
                  color: lea.accent, size: LeaIconSize.md),
              const SizedBox(width: LeaSpace.sm),
              Expanded(
                child: Text('Уведомления выключены',
                    style:
                        LeaType.subtitle.copyWith(color: lea.textPrimary)),
              ),
            ],
          ),
          const SizedBox(height: LeaSpace.sm),
          Text(
            'Чтобы напоминания приходили, разрешите Лее '
            'отправлять уведомления.',
            style: LeaType.label.copyWith(color: lea.textSecondary),
          ),
          const SizedBox(height: LeaSpace.md),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: onTap,
              style: FilledButton.styleFrom(backgroundColor: lea.accent),
              child: const Text('Разрешить уведомления'),
            ),
          ),
        ],
      ),
    );
  }
}
