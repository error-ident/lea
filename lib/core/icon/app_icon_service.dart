import 'package:flutter_dynamic_icon_plus/flutter_dynamic_icon_plus.dart';

/// Варианты иконки приложения.
///
/// ВАЖНО: имя алиаса должно быть ПОЛНЫМ (с пакетом), т.к. пакет передаёт
/// строку напрямую в setComponentEnabledSetting, который требует
/// полное имя класса. Короткое имя ('MainActivityDark') приводит к краху:
/// "Component class MainActivityDark does not exist in ru.lea.app".
///
/// cream — основная MainActivity (aliasName == null, сброс на дефолт).
/// blush/dark — activity-alias из манифеста.
enum AppIconVariant {
  cream(null, 'Кремовая'),
  blush('ru.lea.app.MainActivityBlush', 'Румянец'),
  dark('ru.lea.app.MainActivityDark', 'Тёмная');

  const AppIconVariant(this.aliasName, this.title);
  final String? aliasName;
  final String title;
}

/// Переключение иконки без перезапуска (DONT_KILL_APP внутри пакета).
class AppIconService {
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
    try {
      if (!await FlutterDynamicIconPlus.supportsAlternateIcons) {
        return false;
      }
      // cream → сброс на основную иконку (aliasName == null)
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
    }
  }
}
