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

  runApp(
    ProviderScope(
      overrides: [
        databaseProvider.overrideWithValue(db),
      ],
      child: const LeaApp(),
    ),
  );
}
