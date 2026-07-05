/// Ключи для таблицы settings (ключ-значение). Централизованно — без магических строк.
abstract final class SettingsKeys {
  static const onboardingDone = 'onboarding_done';
  static const statedCycleLength = 'stated_cycle_length';
  static const statedPeriodLength = 'stated_period_length';
  static const userName = 'user_name';
  static const themeId = 'theme_id';
  static const darkMode = 'dark_mode';
  static const lockType = 'lock_type'; // none / pin / biometric
  static const backupProvider = 'backup_provider';
  static const backupLastSync = 'backup_last_sync';
}
