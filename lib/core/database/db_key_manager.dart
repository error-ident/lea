import 'dart:convert';
import 'dart:math';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Управляет ключом шифрования БД.
/// Ключ хранится в системном защищённом хранилище (Android Keystore / iOS Keychain),
/// НЕ в самой базе и НЕ в коде. Генерируется один раз при первом запуске.
class DbKeyManager {
  DbKeyManager([FlutterSecureStorage? storage])
      : _storage = storage ??
            const FlutterSecureStorage(
              aOptions: AndroidOptions(encryptedSharedPreferences: true),
            );

  final FlutterSecureStorage _storage;
  static const _keyName = 'lea_db_key';

  /// Возвращает существующий ключ или создаёт новый (256-битный, hex).
  Future<String> getOrCreateKey() async {
    final existing = await _storage.read(key: _keyName);
    if (existing != null && existing.isNotEmpty) return existing;

    final key = _generateKey();
    await _storage.write(key: _keyName, value: key);
    return key;
  }

  String _generateKey() {
    final rng = Random.secure();
    final bytes = List<int>.generate(32, (_) => rng.nextInt(256));
    return base64Url.encode(bytes).replaceAll(RegExp(r'[^A-Za-z0-9]'), '');
  }
}
