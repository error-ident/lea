import 'package:lottie/lottie.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lea_design/lea_design.dart';

import '../../core/database/app_database.dart';
import '../../core/providers/providers.dart';
import '../../l10n/strings.dart';

/// Полный экран отметки дня. По умолчанию — сегодня.
class DayEntrySheet extends ConsumerWidget {
  const DayEntrySheet({super.key, this.date});
  final DateTime? date;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lea = context.lea;
    final day = _dateOnly(date ?? DateTime.now());

    final categories = ref.watch(visibleCategoriesProvider);
    final allOptions = ref.watch(allOptionsProvider);
    final selected = ref.watch(selectedOptionsProvider(day));

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, controller) => Container(
        decoration: BoxDecoration(
          color: lea.background,
          borderRadius: LeaRadius.sheetTopBR,
        ),
        child: Column(
          children: [
            const SizedBox(height: LeaSpace.md),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: lea.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: LeaSpace.md),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: LeaSpace.xl),
              child: Row(
                children: [
                  Text(_title(day),
                      style: LeaType.h2.copyWith(color: lea.textPrimary)),
                  const Spacer(),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text('Готово',
                        style: LeaType.button.copyWith(color: lea.accent)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: LeaSpace.sm),
            Expanded(
              child: (categories.isLoading || allOptions.isLoading)
                  ? Center(child: CircularProgressIndicator(color: lea.accent))
                  : ListView(
                      controller: controller,
                      padding: const EdgeInsets.fromLTRB(
                          LeaSpace.xl, 0, LeaSpace.xl, LeaSpace.xxxl),
                      children: [
                        for (final cat in categories.value ?? const [])
                          _CategoryBlock(
                            category: cat,
                            options: (allOptions.value ?? const {})[cat.id] ??
                                const [],
                            selectedIds: selected.value ?? const {},
                            date: day,
                          ),
                        const SizedBox(height: LeaSpace.lg),
                        _NoteField(date: day),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  String _title(DateTime d) {
    final today = _dateOnly(DateTime.now());
    if (d == today) return 'Сегодня';
    const m = [
      'января', 'февраля', 'марта', 'апреля', 'мая', 'июня',
      'июля', 'августа', 'сентября', 'октября', 'ноября', 'декабря',
    ];
    return '${d.day} ${m[d.month - 1]}';
  }

  static DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);
}

/// Блок одной категории. Тип ввода зависит от category.type.
class _CategoryBlock extends ConsumerWidget {
  const _CategoryBlock({
    required this.category,
    required this.options,
    required this.selectedIds,
    required this.date,
  });

  final TrackingCategory category;
  final List<TrackingOption> options;
  final Set<int> selectedIds;
  final DateTime date;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lea = context.lea;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: LeaSpace.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(L.t(category.titleKey).toUpperCase(),
              style: LeaType.sectionLabel
                  .copyWith(color: lea.textTertiary)),
          const SizedBox(height: LeaSpace.md),
          if (category.type == TrackingType.numeric)
            _NumericInput(category: category, date: date)
          else
            LayoutBuilder(
              builder: (context, constraints) {
                // 3 карточки в ряд с отступами между ними
                const cols = 3;
                const gap = LeaSpace.sm;
                final cardW =
                    (constraints.maxWidth - gap * (cols - 1)) / cols;
                return Wrap(
                  spacing: gap,
                  runSpacing: gap,
                  children: [
                    for (final opt in options)
                      SizedBox(
                        width: cardW,
                        child: _OptionCard(
                          label: L.t(opt.titleKey),
                          iconRef: opt.iconRef,
                          selected: selectedIds.contains(opt.id),
                          onTap: () async {
                            final db = ref.read(databaseProvider);
                            if (category.type == TrackingType.singleChoice) {
                              for (final o in options) {
                                if (o.id != opt.id &&
                                    selectedIds.contains(o.id)) {
                                  await db.toggleLog(date, o.id);
                                }
                              }
                            }
                            await db.toggleLog(date, opt.id);
                            ref.invalidate(selectedOptionsProvider(date));
                            // periodDaysStreamProvider НЕ трогаем — симптомы
                            // не влияют на дни цикла, а его инвалидация
                            // перерисовывает календарь под шторкой (мигание).
                          },
                        ),
                      ),
                  ],
                );
              },
            ),
        ],
      ),
    );
  }
}

class _OptionCard extends StatefulWidget {
  const _OptionCard({
    required this.label,
    required this.selected,
    required this.onTap,
    this.iconRef,
  });
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final String? iconRef;

  @override
  State<_OptionCard> createState() => _OptionCardState();
}

class _OptionCardState extends State<_OptionCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final lea = context.lea;
    final ref = widget.iconRef;
    final hasEmoji = ref != null && ref.isNotEmpty;
    return Material(
      color: widget.selected ? lea.accentSoft : lea.surface,
      borderRadius: LeaRadius.cardBR,
      child: InkWell(
        borderRadius: LeaRadius.cardBR,
        onTap: () {
          // проиграть анимацию и вернуться на видимый первый кадр
          _controller.forward(from: 0).then((_) {
            if (mounted) _controller.value = 0;
          });
          widget.onTap();
        },
        child: Container(
          height: 104,
          padding: const EdgeInsets.symmetric(
              horizontal: 6, vertical: LeaSpace.sm),
          decoration: BoxDecoration(
            borderRadius: LeaRadius.cardBR,
            border: Border.all(
              color: widget.selected ? lea.accent : lea.border,
              width: widget.selected ? 2 : 1,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                height: 40,
                width: 40,
                child: hasEmoji
                    ? Lottie.asset(
                        'assets/noto/$ref.json',
                        controller: _controller,
                        onLoaded: (composition) {
                          _controller.duration = composition.duration;
                          // стоим на первом кадре (эмодзи виден),
                          // анимация проигрывается только по тапу
                          _controller.value = 0;
                        },
                        errorBuilder: (context, error, stack) =>
                            const Icon(Icons.circle_outlined, size: 28),
                      )
                    : const Icon(Icons.circle_outlined, size: 28),
              ),
              const SizedBox(height: 6),
              Text(
                widget.label,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: LeaType.caption.copyWith(
                  color: widget.selected ? lea.accent : lea.textSecondary,
                  fontWeight: widget.selected ? FontWeight.w700 : FontWeight.w500,
                  height: 1.1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Числовой ввод (вес, БТ, вода).
class _NumericInput extends ConsumerStatefulWidget {
  const _NumericInput({required this.category, required this.date});
  final TrackingCategory category;
  final DateTime date;

  @override
  ConsumerState<_NumericInput> createState() => _NumericInputState();
}

class _NumericInputState extends ConsumerState<_NumericInput> {
  late final TextEditingController _ctrl;

  String get _unit => switch (widget.category.code) {
        'weight' => 'кг',
        'bbt' => '°C',
        'water' => 'л',
        _ => '',
      };

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController();
    // подтянуть существующее значение
    Future.microtask(() async {
      final map = await ref.read(measurementsProvider(widget.date).future);
      final v = map[widget.category.code];
      if (v != null && mounted) _ctrl.text = _fmt(v);
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  String _fmt(double v) => v == v.roundToDouble() ? '${v.toInt()}' : '$v';

  Future<void> _save(String raw) async {
    final value = double.tryParse(raw.replaceAll(',', '.'));
    if (value == null) return;
    final db = ref.read(databaseProvider);
    await db.setMeasurement(widget.date, widget.category.code, value, _unit);
    ref.invalidate(measurementsProvider(widget.date));
  }

  @override
  Widget build(BuildContext context) {
    final lea = context.lea;
    return SizedBox(
      width: 160,
      child: TextField(
        controller: _ctrl,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        style: LeaType.body.copyWith(color: lea.textPrimary),
        onSubmitted: _save,
        onTapOutside: (_) => _save(_ctrl.text),
        decoration: InputDecoration(
          suffixText: _unit,
          filled: true,
          fillColor: lea.surface,
          contentPadding: const EdgeInsets.symmetric(
              horizontal: LeaSpace.lg, vertical: LeaSpace.md),
          enabledBorder: OutlineInputBorder(
            borderRadius: LeaRadius.inputBR,
            borderSide: BorderSide(color: lea.border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: LeaRadius.inputBR,
            borderSide: BorderSide(color: lea.accent, width: 1.5),
          ),
        ),
      ),
    );
  }
}

/// Поле заметки на день.
class _NoteField extends ConsumerStatefulWidget {
  const _NoteField({required this.date});
  final DateTime date;

  @override
  ConsumerState<_NoteField> createState() => _NoteFieldState();
}

class _NoteFieldState extends ConsumerState<_NoteField> {
  late final TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController();
    Future.microtask(() async {
      final text = await ref.read(noteProvider(widget.date).future);
      if (mounted) _ctrl.text = text;
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final db = ref.read(databaseProvider);
    await db.setNote(widget.date, _ctrl.text.trim());
    ref.invalidate(noteProvider(widget.date));
  }

  @override
  Widget build(BuildContext context) {
    final lea = context.lea;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('ЗАМЕТКА',
            style: LeaType.sectionLabel.copyWith(color: lea.textTertiary)),
        const SizedBox(height: LeaSpace.sm),
        TextField(
          controller: _ctrl,
          maxLines: 3,
          style: LeaType.body.copyWith(color: lea.textPrimary),
          onTapOutside: (_) => _save(),
          onEditingComplete: _save,
          decoration: InputDecoration(
            hintText: 'Как прошёл день…',
            hintStyle: LeaType.body.copyWith(color: lea.textTertiary),
            filled: true,
            fillColor: lea.surface,
            contentPadding: const EdgeInsets.all(LeaSpace.lg),
            enabledBorder: OutlineInputBorder(
              borderRadius: LeaRadius.inputBR,
              borderSide: BorderSide(color: lea.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: LeaRadius.inputBR,
              borderSide: BorderSide(color: lea.accent, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }
}
