import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lea_design/lea_design.dart';

import '../database/app_database.dart';
import '../database/db_key_manager.dart';
import '../database/settings_keys.dart';
import '../prediction/cycle_prediction.dart';
import '../prediction/predict_cycle.dart';
import '../prediction/cycle_history.dart';
import '../notifications/notification_service.dart';
import '../backup/yandex_auth.dart';

/// БД переопределяется в main() после готовности (нужен ключ из secure storage).
final databaseProvider = Provider<AppDatabase>((ref) {
  throw UnimplementedError('databaseProvider должен быть переопределён в main()');
});

/// Создаёт зашифрованную БД: ключ из Keystore -> SQLCipher.
Future<AppDatabase> createDatabase() async {
  final key = await DbKeyManager().getOrCreateKey();
  return AppDatabase(openEncryptedDatabase(key));
}

/// Пройден ли онбординг.
final onboardingDoneProvider = FutureProvider<bool>((ref) async {
  final db = ref.watch(databaseProvider);
  final v = await db.getSetting(SettingsKeys.onboardingDone);
  return v == 'true';
});

/// Заявленные в онбординге значения (длина цикла / месячных).
final statedCycleProvider =
    FutureProvider<({int? cycle, int? period})>((ref) async {
  final db = ref.watch(databaseProvider);
  final c = await db.getSetting(SettingsKeys.statedCycleLength);
  final p = await db.getSetting(SettingsKeys.statedPeriodLength);
  return (
    cycle: c == null ? null : int.tryParse(c),
    period: p == null ? null : int.tryParse(p),
  );
});

/// Поток дней менструации — общий источник реактивности.
final periodDaysStreamProvider = StreamProvider((ref) {
  final db = ref.watch(databaseProvider);
  return db.watchPeriodDays();
});

/// Даты начала циклов (для прогноза).
final cycleStartsProvider = FutureProvider<List<DateTime>>((ref) async {
  final db = ref.watch(databaseProvider);
  ref.watch(periodDaysStreamProvider); // реакция на изменения
  return db.cycleStartDates();
});

/// Текущий прогноз цикла — на лету, с учётом заявленных значений.
final predictionProvider = FutureProvider<CyclePrediction>((ref) async {
  final starts = await ref.watch(cycleStartsProvider.future);
  final stated = await ref.watch(statedCycleProvider.future);
  return predictCycle(
    periodStartDates: starts,
    userStatedCycleLength: stated.cycle,
    userStatedPeriodLength: stated.period,
  );
});

/// Видимые категории трекинга (экран ввода дня).
final visibleCategoriesProvider = FutureProvider((ref) async {
  final db = ref.watch(databaseProvider);
  return db.visibleCategories();
});

/// Текущая тема. Дефолт — «Тёплый крем».
/// СОХРАНЯЕТСЯ в БД: раньше была StateProvider и сбрасывалась при каждом
/// перезапуске приложения (ключ в SettingsKeys был, но не использовался).
class ThemeIdNotifier extends Notifier<LeaThemeId> {
  @override
  LeaThemeId build() {
    _load();
    return LeaThemeId.cream;
  }

  Future<void> _load() async {
    final db = ref.read(databaseProvider);
    final raw = await db.getSetting(SettingsKeys.themeId);
    if (raw == null) return;
    final found = LeaThemeId.values.where((e) => e.name == raw);
    if (found.isNotEmpty) state = found.first;
  }

  Future<void> set(LeaThemeId id) async {
    state = id;
    final db = ref.read(databaseProvider);
    await db.setSetting(SettingsKeys.themeId, id.name);
  }
}

final themeIdProvider =
    NotifierProvider<ThemeIdNotifier, LeaThemeId>(ThemeIdNotifier.new);

/// Тёмная тема вкл/выкл. Тоже СОХРАНЯЕТСЯ в БД.
class DarkModeNotifier extends Notifier<bool> {
  @override
  bool build() {
    _load();
    return false;
  }

  Future<void> _load() async {
    final db = ref.read(databaseProvider);
    final raw = await db.getSetting(SettingsKeys.darkMode);
    if (raw != null) state = raw == 'true';
  }

  Future<void> set(bool v) async {
    state = v;
    final db = ref.read(databaseProvider);
    await db.setSetting(SettingsKeys.darkMode, v.toString());
  }
}

final darkModeProvider =
    NotifierProvider<DarkModeNotifier, bool>(DarkModeNotifier.new);

/// Все опции категорий разом (для экрана ввода).
final allOptionsProvider = FutureProvider((ref) async {
  final db = ref.watch(databaseProvider);
  return db.allOptionsByCategory();
});

/// Выбранные опции за конкретный день (id) — для подсветки чипов.
final selectedOptionsProvider =
    FutureProvider.family<Set<int>, DateTime>((ref, date) async {
  final db = ref.watch(databaseProvider);
  return db.selectedOptionIds(date);
});

/// Заметка за день.
final noteProvider =
    FutureProvider.family<String, DateTime>((ref, date) async {
  final db = ref.watch(databaseProvider);
  final n = await db.noteForDate(date);
  return n?.note ?? '';
});

/// Замеры за день (мапа typeCode -> значение).
final measurementsProvider =
    FutureProvider.family<Map<String, double>, DateTime>((ref, date) async {
  final db = ref.watch(databaseProvider);
  final list = await db.measurementsForDate(date);
  return {for (final m in list) m.typeCode: m.value};
});

/// Даты, у которых есть записи (для точек-меток на календаре).
final datesWithEntriesProvider = FutureProvider<Set<DateTime>>((ref) async {
  final db = ref.watch(databaseProvider);
  ref.watch(periodDaysStreamProvider); // обновлять при изменениях
  return db.datesWithEntries();
});

/// Интенсивность менструации по дням (день → код: light/medium/heavy/clots).
/// ОТДЕЛЬНЫЙ провайдер, НЕ завязан на periodDaysStreamProvider: изменение
/// интенсивности не меняет состав дней цикла, и инвалидация потока дней
/// приводила бы к перерисовке (миганию) календаря под шторкой.
final flowByDateProvider = FutureProvider<Map<DateTime, String>>((ref) async {
  final db = ref.watch(databaseProvider);
  return db.flowByDate();
});

/// Показывать ли номер дня цикла на клетках календаря.
/// По умолчанию ВЫКЛЮЧЕНО: не всем нужно, а без номеров календарь читается
/// чище. Настройка сохраняется в БД (переживает перезапуск).
final showCycleDayProvider = FutureProvider<bool>((ref) async {
  final db = ref.watch(databaseProvider);
  final v = await db.getSetting(SettingsKeys.showCycleDay);
  return v == 'true';
});

/// Средства гигиены, которыми пользуется человек (pads/tampons/cup).
/// Пустой набор — счётчики не показываем вовсе (по умолчанию).
final hygieneProductsProvider = FutureProvider<Set<String>>((ref) async {
  final db = ref.watch(databaseProvider);
  final v = await db.getSetting(SettingsKeys.hygieneProducts);
  if (v == null || v.isEmpty) return {};
  return v.split(',').where((e) => e.isNotEmpty).toSet();
});

/// Весь расход средств гигиены по дням — грузится ОДНИМ запросом.
/// Экран статистики берёт данные отсюда и суммирует по диапазонам локально,
/// вместо запроса к БД на каждую строку истории.
final hygieneAllByDateProvider =
    FutureProvider<Map<DateTime, Map<String, int>>>((ref) async {
  final db = ref.watch(databaseProvider);
  return db.hygieneAllByDate();
});

/// Итог расхода средств гигиены за ТЕКУЩИЕ месячные.
/// Считается от первого дня последней непрерывной серии отмеченных дней.
/// Пусто — если месячные не идут или расход не вводился.
final currentPeriodHygieneProvider =
    FutureProvider<Map<String, int>>((ref) async {
  final rows = await ref.watch(periodDaysStreamProvider.future);
  if (rows.isEmpty) return {};
  // Берём общую карту — тот же кэш, что использует статистика.
  final all = await ref.watch(hygieneAllByDateProvider.future);
  if (all.isEmpty) return {};

  final days = rows
      .map((r) => DateTime(r.date.year, r.date.month, r.date.day))
      .toSet()
      .toList()
    ..sort();

  // Начало последней непрерывной серии отмеченных дней.
  final last = days.last;
  var start = last;
  while (days.contains(start.subtract(const Duration(days: 1)))) {
    start = start.subtract(const Duration(days: 1));
  }

  final total = <String, int>{};
  for (var d = start;
      !d.isAfter(last);
      d = d.add(const Duration(days: 1))) {
    final m = all[d];
    if (m == null) continue;
    for (final e in m.entries) {
      total[e.key] = (total[e.key] ?? 0) + e.value;
    }
  }
  return total;
});

/// Дата, до которой пользователь отклонил подтверждение предполагаемых дней.
/// null — не отклонял.
final assumedDismissedProvider = FutureProvider<DateTime?>((ref) async {
  final db = ref.watch(databaseProvider);
  final v = await db.getSetting(SettingsKeys.assumedDismissedUntil);
  if (v == null) return null;
  final parts = v.split('-');
  if (parts.length != 3) return null;
  final y = int.tryParse(parts[0]);
  final m = int.tryParse(parts[1]);
  final d = int.tryParse(parts[2]);
  if (y == null || m == null || d == null) return null;
  return DateTime(y, m, d);
});

/// Настройки уведомлений (из settings, JSON).
final notificationSettingsProvider =
    FutureProvider<NotificationSettings>((ref) async {
  final db = ref.watch(databaseProvider);
  final raw = await db.getSetting('notification_settings');
  if (raw == null) return const NotificationSettings();
  try {
    return NotificationSettings.fromJson(
        jsonDecode(raw) as Map<String, dynamic>);
  } catch (_) {
    return const NotificationSettings();
  }
});

/// Подключён ли Яндекс.Диск (есть сохранённый токен).
final yandexConnectedProvider = FutureProvider<bool>((ref) async {
  return YandexAuthService().isConnected;
});

/// История циклов (детали каждого цикла) — для статистики и истории.
final cycleHistoryProvider = FutureProvider<CycleStats>((ref) async {
  ref.watch(periodDaysStreamProvider); // реакция на изменения
  final db = ref.watch(databaseProvider);
  final rows = await db.select(db.periodDays).get();
  final days = rows.map((r) => r.date).toList();
  final records = buildCycleHistory(days);
  return computeCycleStats(records);
});

/// Идёт ли сейчас операция бэкапа (для блокировки кнопок от двойного тапа).
final backupBusyProvider = StateProvider<bool>((ref) => false);
