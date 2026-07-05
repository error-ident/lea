import 'package:flutter_dynamic_icon_plus/flutter_dynamic_icon_plus.dart';

/// Варианты иконки приложения.
/// cream — основная MainActivity (aliasName == null, сброс на дефолт).
/// blush/dark — activity-alias из манифеста.
enum AppIconVariant {
  cream(null, 'Кремовая'),
  blush('MainActivityBlush', 'Румянец'),
  dark('MainActivityDark', 'Тёмная');

  const AppIconVariant(this.aliasName, this.title);
  final String? aliasName;
  final String title;
}

/// Переключение иконки без перезапуска (DONT_KILL_APP внутри пакета).
class AppIconService {
  static Future<AppIconVariant> current() async {
    try {
      final name = await FlutterDynamicIconPlus.alternateIconName;
      if (name == null) return AppIconVariant.cream;
      return AppIconVariant.values.firstWhere(
        (v) => v.aliasName == name,
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
      await FlutterDynamicIconPlus.setAlternateIconName(
        iconName: variant.aliasName,
      );
      return true;
    } catch (_) {
      return false;
    }
  }
}
