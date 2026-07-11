import 'package:flutter_test/flutter_test.dart';
import 'package:lea/core/backup/backup_date_codec.dart';

void main() {
  group('BackupDateCodec — календарные даты без сдвига пояса', () {
    test('encode даёт YYYY-MM-DD', () {
      expect(BackupDateCodec.encode(DateTime(2026, 1, 15)), '2026-01-15');
      expect(BackupDateCodec.encode(DateTime(2026, 12, 5)), '2026-12-05');
      // время в дате игнорируется — берётся только день
      expect(BackupDateCodec.encode(DateTime(2026, 1, 15, 23, 59)), '2026-01-15');
    });

    test('round-trip: encode → decode возвращает тот же календарный день', () {
      for (final d in [
        DateTime(2026, 1, 15),
        DateTime(2025, 2, 28),
        DateTime(2024, 2, 29), // високосный
        DateTime(2026, 12, 31),
      ]) {
        final s = BackupDateCodec.encode(d);
        final back = BackupDateCodec.decode(s);
        expect(back, DateTime(d.year, d.month, d.day),
            reason: 'день должен сохраниться для $s');
      }
    });

    test('decode строки не зависит от времени суток в исходной дате', () {
      // Ключевой инвариант против старого бага: какой бы момент ни был,
      // день в бэкапе — это чистая календарная строка.
      final s = BackupDateCodec.encode(DateTime(2026, 1, 15, 21, 0));
      expect(BackupDateCodec.decode(s), DateTime(2026, 1, 15));
    });

    test('decode понимает ISO-строку со временем (берёт только день)', () {
      expect(
        BackupDateCodec.decode('2026-01-15T21:00:00.000Z'),
        DateTime(2026, 1, 15),
      );
    });

    test('обратная совместимость: decode старого epoch (v1) → календарный день',
        () {
      // epoch-миллисекунды локальной полуночи 15 янв 2026.
      final ms = DateTime(2026, 1, 15).millisecondsSinceEpoch;
      expect(BackupDateCodec.decode(ms), DateTime(2026, 1, 15));
      // epoch-секунды (v1 мог хранить и так).
      final secs = ms ~/ 1000;
      expect(BackupDateCodec.decode(secs), DateTime(2026, 1, 15));
    });

    test('decode строки-числа тоже работает', () {
      final ms = DateTime(2026, 1, 15).millisecondsSinceEpoch;
      expect(BackupDateCodec.decode(ms.toString()), DateTime(2026, 1, 15));
    });
  });
}
