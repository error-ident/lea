import 'package:flutter_dynamic_icon_plus/flutter_dynamic_icon_plus.dart';

/// Варианты иконки приложения.
///
/// ВАЖНО: имя алиаса — ПОЛНОЕ (с пакетом), т.к. пакет передаёт строку
/// напрямую в setComponentEnabledSetting, который требует полное имя класса.
///
/// Все три варианта — activity-alias, включая кремовую (дефолтную).
/// ПОЧЕМУ: если бы дефолтом была сама MainActivity с LAUNCHER-фильтром, то
/// при включении другого алиаса она оставалась бы включённой и в лаунчере
/// появлялись бы ДВЕ иконки. Каноническая схема — MainActivity без LAUNCHER,
/// каждая иконка отдельный alias.
enum AppIconVariant {
  cream(null, 'Кремовая'), // основная MainActivity
  blush('ru.lea.app.MainActivityBlush', 'Румянец'),
  dark('ru.lea.app.MainActivityDark', 'Тёмная');

  const AppIconVariant(this.aliasName, this.title);
  final String? aliasName;
  final String title;
}

/// Переключение иконки без перезапуска (DONT_KILL_APP внутри пакета).
class AppIconService {
  /// Защита на уровне сервиса: не даём наложиться двум сменам иконки.
  /// Пакет применяет иконку асинхронно (перезапуск активности), и
  /// параллельные вызовы setComponentEnabledSetting роняют приложение.
  static bool _changing = false;

  static Future<AppIconVariant> current() async {
    try {
      final name = await FlutterDynamicIconPlus.alternateIconName;
      if (name == null || name.isEmpty) return AppIconVariant.cream;
      // Система может вернуть как полное имя (ru.lea.app.MainActivityDark),
      // так и короткое (MainActivityDark) — сравниваем по последнему сегменту.
      final short = name.split('.').last;
      return AppIconVariant.values.firstWhere(
        (v) => v.aliasName != null && v.aliasName!.split('.').last == short,
        orElse: () => AppIconVariant.cream,
      );
    } catch (_) {
      return AppIconVariant.cream;
    }
  }

  static Future<bool> set(AppIconVariant variant) async {
    // Уже идёт смена — отклоняем. Параллельные вызовы роняют приложение.
    if (_changing) return false;
    _changing = true;
    try {
      if (!await FlutterDynamicIconPlus.supportsAlternateIcons) {
        return false;
      }
      // Все варианты — полноценные алиасы (включая кремовую).
      //
      // blacklist* — для устройств, где onTaskRemoved не вызывается
      // (Huawei/Xiaomi и клоны). Для них пакет использует старый подход
      // (принудительный перезапуск), иначе иконка не применяется вовсе.
      await FlutterDynamicIconPlus.setAlternateIconName(
        iconName: variant.aliasName,
        blacklistBrands: const [
          'Redmi',
          'POCO',
          'HONOR',
          'Huawei',
        ],
        blacklistManufactures: const [
          'Xiaomi',
          'HUAWEI',
          'HONOR',
          'OPPO',
          'vivo',
        ],
      );
      return true;
    } catch (_) {
      return false;
    } finally {
      // Отпускаем замок с задержкой: система применяет иконку асинхронно,
      // и немедленный повторный вызов попадёт в момент перезапуска.
      Future<void>.delayed(const Duration(seconds: 3), () {
        _changing = false;
      });
    }
  }
}
