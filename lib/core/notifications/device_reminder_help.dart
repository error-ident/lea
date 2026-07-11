import 'dart:io' show Platform;

import 'package:android_intent_plus/android_intent.dart';
import 'package:android_intent_plus/flag.dart';
import 'package:device_info_plus/device_info_plus.dart';

/// Помощь с доставкой уведомлений на «агрессивных» прошивках (EMUI/MIUI и т.п.).
///
/// ВАЖНО, честно: ни один из методов НЕ гарантирует доставку. Huawei/Xiaomi
/// на уровне ОС выгружают приложение из памяти и отменяют его будильники ради
/// батареи. Программно это не обходится — можно лишь ОТКРЫТЬ пользователю
/// нужные системные экраны, где он вручную снимает ограничения. Это стандартная
/// практика: так же поступают мессенджеры и трекеры.
///
/// Порядок отдачи: батарея (макс эффект) → точные будильники → автозапуск.
abstract final class DeviceReminderHelp {
  static final _deviceInfo = DeviceInfoPlugin();

  /// Вендор прошивки в нижнем регистре (huawei / xiaomi / honor / oppo / ...).
  /// Пусто на не-Android или при ошибке.
  static Future<String> vendor() async {
    if (!Platform.isAndroid) return '';
    try {
      final info = await _deviceInfo.androidInfo;
      return info.manufacturer.toLowerCase().trim();
    } catch (_) {
      return '';
    }
  }

  /// true, если вендор известен своей агрессивной оптимизацией батареи.
  /// Для таких стоит показать подсказку про автозапуск.
  static Future<bool> isAggressiveVendor() async {
    final v = await vendor();
    const aggressive = [
      'huawei',
      'honor',
      'xiaomi',
      'redmi',
      'poco',
      'oppo',
      'vivo',
      'realme',
      'oneplus',
      'meizu',
    ];
    return aggressive.any(v.contains);
  }

  /// Открыть системный диалог «исключить из оптимизации батареи».
  /// Наибольший эффект: мешает ОС убивать процесс и отменять будильники.
  static Future<void> openBatteryOptimization() async {
    if (!Platform.isAndroid) return;
    // Диалог, привязанный к пакету приложения (сразу про Лею, не общий список).
    const intent = AndroidIntent(
      action: 'android.settings.REQUEST_IGNORE_BATTERY_OPTIMIZATIONS',
      data: 'package:ru.lea.app', // applicationId; при отличии — поправить
      flags: <int>[Flag.FLAG_ACTIVITY_NEW_TASK],
    );
    try {
      await intent.launch();
    } catch (_) {
      // если конкретный диалог недоступен — общий экран настроек батареи
      await _safeLaunch(
        'android.settings.IGNORE_BATTERY_OPTIMIZATION_SETTINGS',
      );
    }
  }

  /// Открыть экран разрешения точных будильников (Android 12+).
  static Future<void> openExactAlarmSettings() async {
    if (!Platform.isAndroid) return;
    await _safeLaunch(
      'android.settings.REQUEST_SCHEDULE_EXACT_ALARM',
      data: 'package:ru.lea.app',
    );
  }

  /// Открыть общий экран настроек уведомлений приложения — универсальный
  /// запасной вариант, если специфичные экраны недоступны.
  static Future<void> openAppNotificationSettings() async {
    if (!Platform.isAndroid) return;
    const intent = AndroidIntent(
      action: 'android.settings.APP_NOTIFICATION_SETTINGS',
      arguments: <String, dynamic>{
        'android.provider.extra.APP_PACKAGE': 'ru.lea.app',
      },
      flags: <int>[Flag.FLAG_ACTIVITY_NEW_TASK],
    );
    try {
      await intent.launch();
    } catch (_) {
      await _safeLaunch('android.settings.APPLICATION_DETAILS_SETTINGS',
          data: 'package:ru.lea.app');
    }
  }

  static Future<void> _safeLaunch(String action, {String? data}) async {
    try {
      final intent = AndroidIntent(
        action: action,
        data: data,
        flags: const <int>[Flag.FLAG_ACTIVITY_NEW_TASK],
      );
      await intent.launch();
    } catch (_) {
      // молча — не критично, пользователь может открыть настройки руками
    }
  }
}
