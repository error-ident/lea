import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lea_design/lea_design.dart';

import '../../core/database/app_database.dart';
import '../../core/providers/providers.dart';
import '../../l10n/strings.dart';

/// Настройка дневника: какие категории показывать и в каком порядке.
///
/// ЧТО МОЖНО: скрыть ненужное и переставить. Добавлять свои категории и
/// опции нельзя — у встроенных есть анимированные эмодзи, а у самодельных
/// их не будет, и дневник станет выглядеть сломанным. Лучше меньше, но
/// цельно.
///
/// ВАЖНО ПРО ДАННЫЕ: скрытие категории НЕ удаляет записи. Всё отмеченное
/// остаётся в БД и вернётся, если включить категорию обратно. Скрытие —
/// про интерфейс, а не про удаление.
class DiarySetupScreen extends ConsumerWidget {
  const DiarySetupScreen({super.key});

  /// Категории, которые скрывать нельзя: без них трекер цикла теряет смысл.
  static const _required = {'flow'};

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lea = context.lea;
    final cats = ref.watch(allCategoriesProvider).valueOrNull;

    return Scaffold(
      backgroundColor: lea.background,
      appBar: AppBar(title: const Text('Дневник')),
      body: cats == null
          ? const SizedBox.expand()
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    LeaSpace.xl,
                    LeaSpace.lg,
                    LeaSpace.xl,
                    LeaSpace.sm,
                  ),
                  child: Text(
                    'Отключите то, что не отслеживаете, и расставьте разделы '
                    'в удобном порядке. Записи скрытых разделов сохранятся — '
                    'если включите обратно, всё будет на месте.',
                    style: LeaType.label.copyWith(color: lea.textSecondary),
                  ),
                ),
                Expanded(
                  child: ReorderableListView.builder(
                    padding: const EdgeInsets.symmetric(
                      horizontal: LeaSpace.xl,
                      vertical: LeaSpace.sm,
                    ),
                    itemCount: cats.length,
                    // onReorderItem (вместо устаревшего onReorder) сам
                    // корректирует newIndex при перемещении вниз — ручная
                    // поправка «if (newIndex > oldIndex) newIndex -= 1»
                    // больше не нужна.
                    onReorderItem: (oldIndex, newIndex) async {
                      final list = [...cats];
                      final moved = list.removeAt(oldIndex);
                      list.insert(newIndex, moved);
                      final db = ref.read(databaseProvider);
                      await db.reorderCategories([for (final c in list) c.id]);
                      ref.invalidate(allCategoriesProvider);
                      ref.invalidate(visibleCategoriesProvider);
                    },
                    itemBuilder: (context, i) {
                      final c = cats[i];
                      final locked = _required.contains(c.code);
                      return _CategoryTile(
                        key: ValueKey(c.id),
                        category: c,
                        locked: locked,
                        index: i,
                        onToggle: (visible) async {
                          final db = ref.read(databaseProvider);
                          await db.setCategoryHidden(c.id, !visible);
                          ref.invalidate(allCategoriesProvider);
                          ref.invalidate(visibleCategoriesProvider);
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }
}

class _CategoryTile extends StatelessWidget {
  const _CategoryTile({
    super.key,
    required this.category,
    required this.locked,
    required this.index,
    required this.onToggle,
  });

  final TrackingCategory category;
  final bool locked;
  final int index;
  final ValueChanged<bool> onToggle;

  @override
  Widget build(BuildContext context) {
    final lea = context.lea;
    final visible = !category.isHidden;

    return Container(
      margin: const EdgeInsets.only(bottom: LeaSpace.sm),
      decoration: BoxDecoration(
        color: lea.surface,
        borderRadius: LeaRadius.cardBR,
        border: Border.all(color: lea.border),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.only(
          left: LeaSpace.lg,
          right: LeaSpace.sm,
        ),
        title: Text(
          L.t(category.titleKey),
          style: LeaType.subtitle.copyWith(
            color: visible ? lea.textPrimary : lea.textTertiary,
          ),
        ),
        subtitle: locked
            ? Text('нужен для расчёта цикла',
                style: LeaType.caption.copyWith(color: lea.textTertiary))
            : null,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Switch(
              value: visible,
              activeThumbColor: lea.accent,
              onChanged: locked ? null : onToggle,
            ),
            ReorderableDragStartListener(
              index: index,
              child: Padding(
                padding: const EdgeInsets.only(left: LeaSpace.xs),
                child: Icon(Icons.drag_handle, color: lea.textTertiary),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
