import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

/// Клиент Яндекс.Диска (REST API) для авто-бэкапа в папку приложения.
///
/// Использует OAuth-токен пользователя. Приложение регистрируется один раз
/// на oauth.yandex.ru (получаешь client_id) — токен добывается через
/// OAuth-флоу (см. YandexAuth ниже, упрощённый).
///
/// Доступ ограничен папкой приложения (app:/) — Лея не видит другие файлы.
/// Эндпоинты REST: https://cloud-api.yandex.net/v1/disk/...
class YandexDiskClient {
  YandexDiskClient(this.token, {http.Client? client})
      : _http = client ?? http.Client();

  final String token;
  final http.Client _http;

  static const _base = 'https://cloud-api.yandex.net/v1/disk';
  static const _backupPath = 'app:/lea-backup.leabak';

  Map<String, String> get _headers => {
        'Authorization': 'OAuth $token',
        'Accept': 'application/json',
      };

  /// Загрузить байты бэкапа на Диск (перезаписывает прошлый).
  Future<void> uploadBackup(Uint8List bytes) async {
    // 1. получить ссылку для загрузки
    final uri = Uri.parse(
        '$_base/resources/upload?path=${Uri.encodeComponent(_backupPath)}&overwrite=true');
    final res = await _http.get(uri, headers: _headers);
    if (res.statusCode != 200) {
      throw YandexDiskException('Не удалось получить ссылку загрузки', res.statusCode);
    }
    final href = (jsonDecode(res.body) as Map<String, dynamic>)['href'] as String;

    // 2. загрузить файл по ссылке (PUT)
    final put = await _http.put(Uri.parse(href), body: bytes);
    if (put.statusCode != 201 && put.statusCode != 202) {
      throw YandexDiskException('Не удалось загрузить файл', put.statusCode);
    }
  }

  /// Скачать последний бэкап с Диска (или null, если его нет).
  Future<Uint8List?> downloadBackup() async {
    final uri = Uri.parse(
        '$_base/resources/download?path=${Uri.encodeComponent(_backupPath)}');
    final res = await _http.get(uri, headers: _headers);
    if (res.statusCode == 404) return null;
    if (res.statusCode != 200) {
      throw YandexDiskException('Не удалось получить ссылку скачивания', res.statusCode);
    }
    final href = (jsonDecode(res.body) as Map<String, dynamic>)['href'] as String;

    final file = await _http.get(Uri.parse(href));
    if (file.statusCode != 200) {
      throw YandexDiskException('Не удалось скачать файл', file.statusCode);
    }
    return file.bodyBytes;
  }

  /// Есть ли бэкап на Диске + дата последнего изменения.
  Future<DateTime?> backupModifiedAt() async {
    final uri = Uri.parse(
        '$_base/resources?path=${Uri.encodeComponent(_backupPath)}&fields=modified');
    final res = await _http.get(uri, headers: _headers);
    if (res.statusCode == 404) return null;
    if (res.statusCode != 200) return null;
    final modified =
        (jsonDecode(res.body) as Map<String, dynamic>)['modified'] as String?;
    return modified == null ? null : DateTime.tryParse(modified);
  }
}

class YandexDiskException implements Exception {
  YandexDiskException(this.message, this.statusCode);
  final String message;
  final int statusCode;
  @override
  String toString() => 'YandexDisk: $message ($statusCode)';
}
