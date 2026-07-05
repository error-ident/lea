import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:yandex_auth/yandex_auth.dart' as ya;

/// Авторизация в Яндексе через нативный Login SDK (пакет yandex_auth).
///
/// НАСТРОЙКА (один раз):
/// 1. oauth.yandex.ru → приложение, платформа Android: package ru.lea.app,
///    SHA256-отпечаток, право cloud_api:disk.app_folder.
/// 2. В android/app/build.gradle.kts → defaultConfig:
///    manifestPlaceholders += mapOf("YANDEX_CLIENT_ID" to "ВАШ_CLIENT_ID")
///
/// Токен прилетает автоматически после signIn() — без ручного ввода.
class YandexAuthService {
  YandexAuthService([FlutterSecureStorage? storage])
      : _storage = storage ??
            const FlutterSecureStorage(
              aOptions: AndroidOptions(encryptedSharedPreferences: true),
            );

  final FlutterSecureStorage _storage;
  static const _kToken = 'yandex_oauth_token';

  final _auth = ya.YandexAuth();

  Future<String?> getToken() => _storage.read(key: _kToken);
  Future<void> saveToken(String token) =>
      _storage.write(key: _kToken, value: token);
  Future<void> clearToken() => _storage.delete(key: _kToken);
  Future<bool> get isConnected async => (await getToken()) != null;

  /// Запустить нативную авторизацию Яндекса. Возвращает токен или null
  /// (пользователь отменил). Бросает при ошибке настройки/сети.
  Future<String?> signIn() async {
    final result = await _auth.signIn();
    if (result == null) return null; // отменено пользователем
    final token = result.token;
    await saveToken(token);
    return token;
  }
}
