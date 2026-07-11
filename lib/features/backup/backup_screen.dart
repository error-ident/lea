import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lea_design/lea_design.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/backup/backup_service.dart';
import '../../core/backup/yandex_disk_client.dart';
import '../../core/backup/yandex_auth.dart';
import '../../core/notifications/notification_service.dart';
import '../../core/providers/providers.dart';

/// Экран резервной копии. Экспорт — зашифрованный паролем файл, который
/// пользователь сам кладёт куда хочет (его облако/телеграм/диск).
/// Сервер разработчика НЕ участвует — приватность сохраняется.
class BackupScreen extends ConsumerWidget {
  const BackupScreen({super.key});

  /// Полная инвалидация кэша после восстановления данных.
  /// Критично: включает onboardingDoneProvider — иначе после восстановления
  /// на новом телефоне снова показывался онбординг, хотя флаг уже в БД.
  /// Также обновляет прогноз, историю, настройки, замеры и заметки.
  static void _invalidateAfterRestore(WidgetRef ref) {
    ref.invalidate(onboardingDoneProvider);
    ref.invalidate(statedCycleProvider);
    ref.invalidate(cycleStartsProvider);
    ref.invalidate(periodDaysStreamProvider);
    ref.invalidate(predictionProvider);
    ref.invalidate(cycleHistoryProvider);
    ref.invalidate(datesWithEntriesProvider);
    ref.invalidate(visibleCategoriesProvider);
    ref.invalidate(notificationSettingsProvider);
    ref.invalidate(themeIdProvider);
    ref.invalidate(darkModeProvider);
  }

  /// Перепланировать уведомления о цикле по восстановленному прогнозу.
  /// Без этого после restore напоминания оставались привязаны к старым/пустым
  /// данным и не срабатывали, пока пользователь вручную не зайдёт в настройки.
  static Future<void> _rescheduleAfterRestore(WidgetRef ref) async {
    try {
      final pred = await ref.read(predictionProvider.future);
      final settings = await ref.read(notificationSettingsProvider.future);
      await NotificationService().reschedule(pred, settings);
    } catch (_) {
      // не критично для восстановления данных — молча пропускаем
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lea = context.lea;

    return Scaffold(
      backgroundColor: lea.background,
      appBar: AppBar(title: const Text('Резервная копия')),
      body: ListView(
        padding: const EdgeInsets.all(LeaSpace.xl),
        children: [
          Container(
            padding: const EdgeInsets.all(LeaSpace.lg),
            decoration: BoxDecoration(
              color: lea.surface,
              borderRadius: LeaRadius.cardBR,
            ),
            child: Text(
              'Копия шифруется паролем и сохраняется в выбранную вами папку '
              '(например, Загрузки). Запомните место и пароль — они нужны для '
              'восстановления. Лея не хранит ваши данные на серверах.',
              style: LeaType.body.copyWith(color: lea.textSecondary),
            ),
          ),
          const SizedBox(height: LeaSpace.xxl),
          _ActionTile(
            icon: Icons.save_alt,
            title: 'Создать копию',
            subtitle: 'Зашифровать и сохранить файл',
            onTap: () => _createBackup(context, ref),
          ),
          _ActionTile(
            icon: Icons.restore,
            title: 'Восстановить из копии',
            subtitle: 'Выбрать файл и ввести пароль',
            onTap: () => _restoreBackup(context, ref),
          ),
          const SizedBox(height: LeaSpace.xxl),
          Row(
            children: [
              Text('ЯНДЕКС.ДИСК',
                  style:
                      LeaType.sectionLabel.copyWith(color: lea.textTertiary)),
              const Spacer(),
              Consumer(builder: (context, ref, _) {
                final connected = ref.watch(yandexConnectedProvider);
                return connected.maybeWhen(
                  data: (yes) => yes
                      ? TextButton(
                          onPressed: () => _disconnectYandex(context, ref),
                          child: Text('Отключить',
                              style: LeaType.caption
                                  .copyWith(color: lea.error)),
                        )
                      : Text('не подключён',
                          style: LeaType.caption
                              .copyWith(color: lea.textTertiary)),
                  orElse: () => const SizedBox.shrink(),
                );
              }),
            ],
          ),
          const SizedBox(height: LeaSpace.md),
          Container(
            padding: const EdgeInsets.all(LeaSpace.lg),
            decoration: BoxDecoration(
              color: lea.surface,
              borderRadius: LeaRadius.cardBR,
            ),
            child: Text(
              'Авто-копия в вашу личную папку приложения на Яндекс.Диске. '
              'Лея видит только эту папку — не остальные файлы. '
              'Копия так же зашифрована вашим паролем.',
              style: LeaType.label.copyWith(color: lea.textSecondary),
            ),
          ),
          const SizedBox(height: LeaSpace.md),
          Consumer(builder: (context, ref, _) {
            final busy = ref.watch(backupBusyProvider);
            return Column(
              children: [
                _ActionTile(
                  icon: Icons.cloud_upload_outlined,
                  title: 'Сохранить на Яндекс.Диск',
                  subtitle: busy
                      ? 'Идёт операция…'
                      : 'Зашифровать и выгрузить в облако',
                  enabled: !busy,
                  onTap: () => _yandexUpload(context, ref),
                ),
                _ActionTile(
                  icon: Icons.cloud_download_outlined,
                  title: 'Восстановить с Яндекс.Диска',
                  subtitle: busy ? 'Идёт операция…' : 'Скачать последнюю копию',
                  enabled: !busy,
                  onTap: () => _yandexDownload(context, ref),
                ),
              ],
            );
          }),
        ],
      ),
    );
  }

  /// Показать понятную ошибку (BackupException — как есть, прочее — обобщённо).
  void _showError(BuildContext context, Object e) {
    if (!context.mounted) return;
    final msg = e is BackupException ? e.message : 'Не удалось выполнить операцию.';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: context.lea.error),
    );
  }

  /// Отключение Яндекса: удаляем токен локально (Яндекс это рекомендует
  /// для обычных токенов) + поясняем, что полный отзыв — в Яндекс ID.
  Future<void> _disconnectYandex(BuildContext context, WidgetRef ref) async {
    await YandexAuthService().clearToken();
    ref.invalidate(yandexConnectedProvider);
    if (!context.mounted) return;

    final lea = context.lea;
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: lea.surface,
        title: Text('Диск отключён',
            style: LeaType.h2.copyWith(color: lea.textPrimary)),
        content: Text(
          'Доступ к Яндекс.Диску удалён из приложения. '
          'Чтобы полностью отозвать доступ в аккаунте Яндекса, '
          'откройте Яндекс ID → «Доступы к данным».',
          style: LeaType.body.copyWith(color: lea.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Понятно',
                style: LeaType.label.copyWith(color: lea.textSecondary)),
          ),
          TextButton(
            onPressed: () {
              launchUrl(
                Uri.parse('https://id.yandex.ru/personal/data-access'),
                mode: LaunchMode.externalApplication,
              );
              Navigator.pop(ctx);
            },
            child: Text('Открыть Яндекс ID',
                style: LeaType.label.copyWith(color: lea.accent)),
          ),
        ],
      ),
    );
  }

  Future<void> _createBackup(BuildContext context, WidgetRef ref) async {
    final password = await _askPassword(context, confirm: true);
    if (password == null || password.isEmpty) return;

    final db = ref.read(databaseProvider);
    final bytes = await BackupService(db).createEncryptedBackup(password);

    final stamp = DateTime.now().toIso8601String().split('T').first;
    final fileName = 'lea-backup-$stamp.leabak';

    // системный диалог "сохранить как" — пользователь сам выбирает папку
    // (Загрузки/Документы) и видит, куда сохранил.
    final path = await FilePicker.platform.saveFile(
      dialogTitle: 'Сохранить резервную копию',
      fileName: fileName,
      bytes: bytes,
    );

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(path != null
              ? 'Копия сохранена. Запомните, куда — она понадобится для восстановления.'
              : 'Сохранение отменено'),
        ),
      );
    }
  }

  Future<void> _restoreBackup(BuildContext context, WidgetRef ref) async {
    final picked = await FilePicker.platform.pickFiles(
      type: FileType.any,
      withData: true,
    );
    if (picked == null || picked.files.isEmpty) return;
    final bytes = picked.files.first.bytes;
    if (bytes == null) return;

    if (!context.mounted) return;
    final password = await _askPassword(context, confirm: false);
    if (password == null || password.isEmpty) return;

    final db = ref.read(databaseProvider);
    try {
      await BackupService(db).restoreEncryptedBackup(
        Uint8List.fromList(bytes),
        password,
      );
      _invalidateAfterRestore(ref);
      await _rescheduleAfterRestore(ref);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Данные восстановлены')),
        );
        // Если экран открыт поверх онбординга — возвращаемся к корню,
        // чтобы приложение перерисовалось уже как «онбординг пройден».
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    } catch (e) {
      if (context.mounted) _showError(context, e);
    }
  }

  // --- Яндекс.Диск ---

  Future<void> _yandexUpload(BuildContext context, WidgetRef ref) async {
    if (ref.read(backupBusyProvider)) return; // защита от двойного тапа
    final token = await _ensureYandexToken(context, ref);
    if (token == null) return;
    if (!context.mounted) return;

    final password = await _askPassword(context, confirm: true);
    if (password == null || password.isEmpty) return;

    ref.read(backupBusyProvider.notifier).state = true;
    final db = ref.read(databaseProvider);
    try {
      final bytes = await BackupService(db).createEncryptedBackup(password);
      await YandexDiskClient(token).uploadBackup(bytes);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Сохранено на Яндекс.Диск')),
        );
      }
    } catch (e) {
      if (context.mounted) _showError(context, e);
    } finally {
      ref.read(backupBusyProvider.notifier).state = false;
    }
  }

  Future<void> _yandexDownload(BuildContext context, WidgetRef ref) async {
    if (ref.read(backupBusyProvider)) return; // защита от двойного тапа
    final token = await _ensureYandexToken(context, ref);
    if (token == null) return;

    ref.read(backupBusyProvider.notifier).state = true;
    try {
      final bytes = await YandexDiskClient(token).downloadBackup();
      if (bytes == null) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Копий на Диске пока нет')),
          );
        }
        return;
      }
      if (!context.mounted) return;
      final password = await _askPassword(context, confirm: false);
      if (password == null || password.isEmpty) return;

      final db = ref.read(databaseProvider);
      await BackupService(db).restoreEncryptedBackup(bytes, password);
      _invalidateAfterRestore(ref);
      await _rescheduleAfterRestore(ref);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Восстановлено с Яндекс.Диска')),
        );
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    } catch (e) {
      if (context.mounted) _showError(context, e);
    } finally {
      ref.read(backupBusyProvider.notifier).state = false;
    }
  }

  /// Подключение Яндекса через нативный Login SDK — токен автоматически.
  Future<String?> _ensureYandexToken(BuildContext context, WidgetRef ref) async {
    final auth = YandexAuthService();
    final existing = await auth.getToken();
    if (existing != null) return existing;

    try {
      final token = await auth.signIn();
      if (token != null) {
        // обновить статус «подключено» в UI
        ref.invalidate(yandexConnectedProvider);
      } else if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Авторизация отменена')),
        );
      }
      return token;
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Не удалось войти в Яндекс: $e')),
        );
      }
      return null;
    }
  }

  Future<String?> _askPassword(BuildContext context,
      {required bool confirm}) async {
    final ctrl = TextEditingController();
    final ctrl2 = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (ctx) {
        final lea = ctx.lea;
        String? err;
        return StatefulBuilder(
          builder: (ctx, setState) => AlertDialog(
            backgroundColor: lea.surface,
            title: Text(confirm ? 'Пароль для копии' : 'Пароль копии',
                style: LeaType.h2.copyWith(color: lea.textPrimary)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: ctrl,
                  obscureText: true,
                  decoration: const InputDecoration(hintText: 'Пароль'),
                ),
                if (confirm)
                  TextField(
                    controller: ctrl2,
                    obscureText: true,
                    decoration: const InputDecoration(hintText: 'Повторите'),
                  ),
                if (err != null)
                  Padding(
                    padding: const EdgeInsets.only(top: LeaSpace.sm),
                    child: Text(err!,
                        style: LeaType.caption.copyWith(color: lea.error)),
                  ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Отмена'),
              ),
              TextButton(
                onPressed: () {
                  if (ctrl.text.isEmpty) {
                    setState(() => err = 'Введите пароль');
                    return;
                  }
                  if (confirm && ctrl.text != ctrl2.text) {
                    setState(() => err = 'Пароли не совпадают');
                    return;
                  }
                  Navigator.pop(ctx, ctrl.text);
                },
                child: const Text('OK'),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.enabled = true,
  });
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final lea = context.lea;
    return Padding(
      padding: const EdgeInsets.only(bottom: LeaSpace.md),
      child: Material(
        color: lea.surface,
        borderRadius: LeaRadius.cardSmBR,
        child: InkWell(
          borderRadius: LeaRadius.cardSmBR,
          onTap: enabled ? onTap : null,
          child: Opacity(
            opacity: enabled ? 1 : 0.5,
            child: Padding(
              padding: const EdgeInsets.all(LeaSpace.lg),
              child: Row(
                children: [
                  Icon(icon, color: lea.accent, size: LeaIconSize.md),
                  const SizedBox(width: LeaSpace.lg),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title,
                            style: LeaType.subtitle
                                .copyWith(color: lea.textPrimary)),
                        Text(subtitle,
                            style: LeaType.caption
                                .copyWith(color: lea.textSecondary)),
                      ],
                    ),
                  ),
                  if (!enabled)
                    SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: lea.accent),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
