/// Кодек календарных дат для бэкапа — вынесен отдельно, чтобы быть
/// публичным и покрытым тестами.
///
/// ПРИНЦИП: дата в бэкапе — это КАЛЕНДАРНЫЙ ДЕНЬ, а не момент времени.
/// Сериализуем как строку 'YYYY-MM-DD' без привязки к часовому поясу.
/// Это устраняет сдвиг дня на ±1 при переносе копии между телефонами
/// в разных поясах (старый формат хранил UTC-epoch и «съезжал»).
abstract final class BackupDateCodec {
  /// Дата → 'YYYY-MM-DD' (берётся только календарный день, время игнорируется).
  static String encode(DateTime d) {
    final y = d.year.toString().padLeft(4, '0');
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '$y-$m-$day';
  }

  /// Разбор даты из бэкапа. Возвращает ЛОКАЛЬНУЮ полночь (день не сдвигается).
  ///
  /// Поддерживает:
  /// - v2: строку 'YYYY-MM-DD' (основной формат);
  /// - ISO-строку со временем (берём только день);
  /// - v1: epoch-число (секунды или миллисекунды) — для старых копий.
  static DateTime decode(Object? v) {
    if (v is String) {
      final parts = v.split('-');
      if (parts.length == 3) {
        final y = int.tryParse(parts[0]);
        final m = int.tryParse(parts[1]);
        final d = int.tryParse(parts[2]);
        if (y != null && m != null && d != null) {
          return DateTime(y, m, d);
        }
      }
      final parsed = DateTime.tryParse(v);
      if (parsed != null) {
        return DateTime(parsed.year, parsed.month, parsed.day);
      }
    }
    if (v is int) {
      final dt = _fromEpoch(v);
      return DateTime(dt.year, dt.month, dt.day);
    }
    final s = v?.toString() ?? '';
    final asInt = int.tryParse(s);
    if (asInt != null) {
      final dt = _fromEpoch(asInt);
      return DateTime(dt.year, dt.month, dt.day);
    }
    final parsed = DateTime.parse(s);
    return DateTime(parsed.year, parsed.month, parsed.day);
  }

  /// Эвристика: > 10^11 — миллисекунды, иначе секунды.
  static DateTime _fromEpoch(int v) => v > 100000000000
      ? DateTime.fromMillisecondsSinceEpoch(v)
      : DateTime.fromMillisecondsSinceEpoch(v * 1000);
}
