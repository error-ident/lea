import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';

enum LockType { none, pin, biometric }

/// Управляет блокировкой приложения: PIN (хэш в secure storage) и биометрия.
/// PIN никогда не хранится в открытом виде — только соль+хэш.
class LockService {
  LockService([FlutterSecureStorage? storage, LocalAuthentication? auth])
      : _storage = storage ??
            const FlutterSecureStorage(
              aOptions: AndroidOptions(encryptedSharedPreferences: true),
            ),
        _auth = auth ?? LocalAuthentication();

  final FlutterSecureStorage _storage;
  final LocalAuthentication _auth;

  static const _kType = 'lock_type';
  static const _kPinHash = 'lock_pin_hash';
  static const _kPinSalt = 'lock_pin_salt';

  Future<LockType> currentType() async {
    final v = await _storage.read(key: _kType);
    return switch (v) {
      'pin' => LockType.pin,
      'biometric' => LockType.biometric,
      _ => LockType.none,
    };
  }

  Future<bool> isLockEnabled() async => (await currentType()) != LockType.none;

  // ---- PIN ----

  Future<void> setPin(String pin) async {
    final salt = DateTime.now().microsecondsSinceEpoch.toString();
    final hash = _hashPin(pin, salt);
    await _storage.write(key: _kPinSalt, value: salt);
    await _storage.write(key: _kPinHash, value: hash);
    await _storage.write(key: _kType, value: 'pin');
  }

  Future<bool> verifyPin(String pin) async {
    final salt = await _storage.read(key: _kPinSalt);
    final hash = await _storage.read(key: _kPinHash);
    if (salt == null || hash == null) return false;
    return _hashPin(pin, salt) == hash;
  }

  String _hashPin(String pin, String salt) {
    final bytes = utf8.encode('$salt:$pin');
    return sha256.convert(bytes).toString();
  }

  // ---- Биометрия ----

  Future<bool> canUseBiometric() async {
    try {
      final supported = await _auth.isDeviceSupported();
      final canCheck = await _auth.canCheckBiometrics;
      return supported && canCheck;
    } catch (_) {
      return false;
    }
  }

  Future<void> enableBiometric() async =>
      _storage.write(key: _kType, value: 'biometric');

  Future<bool> authenticateBiometric() async {
    try {
      return await _auth.authenticate(
        localizedReason: 'Подтвердите, чтобы открыть Лею',
        options: const AuthenticationOptions(
          stickyAuth: true,
          // biometricOnly: false — разрешаем и PIN/паттерн устройства как запас,
          // иначе на части устройств (в т.ч. Nothing) диалог не появляется.
          biometricOnly: false,
        ),
      );
    } catch (_) {
      return false;
    }
  }

  // ---- Отключение ----

  Future<void> disable() async {
    await _storage.delete(key: _kType);
    await _storage.delete(key: _kPinHash);
    await _storage.delete(key: _kPinSalt);
  }
}
