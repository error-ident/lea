import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'core/providers/providers.dart';
import 'core/notifications/notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Открываем зашифрованную БД до запуска UI (нужен ключ из Keystore).
  final db = await createDatabase();

  // Инициализируем уведомления (таймзоны, каналы).
  await NotificationService().init();

  // Перепланируем напоминания о лекарствах при каждом старте.
  //
  // ЗАЧЕМ: напоминания живут в системном AlarmManager и теряются после
  // перезагрузки телефона, обновления приложения или очистки системой.
  // Планирование только при изменении списка означало бы, что человек
  // добавил препарат полгода назад, телефон перезагрузился — и напоминания
  // молча пропали. Для лекарств это недопустимо.
  //
  // Ошибки глушим: неудача планирования не должна мешать запуску приложения.
  try {
    final meds = await db.activeMedications();
    await NotificationService().scheduleMedications([
      for (final m in meds)
        (id: m.id, name: m.name, times: m.times, remind: m.remind),
    ]);
  } catch (_) {
    // не критично для запуска
  }

  runApp(
    ProviderScope(
      overrides: [
        databaseProvider.overrideWithValue(db),
      ],
      child: const LeaApp(),
    ),
  );
}
