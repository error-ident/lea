import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:lea/core/prediction/predict_cycle.dart';

/// Тест согласованности: экран «О приложении» не должен врать про движок.
///
/// ЗАЧЕМ. За время разработки движок менялся несколько раз (фильтр склеек,
/// MAD, динамическая лютеиновая фаза), а описание методики оставалось
/// старым — и в какой-то момент заявляло то, чего в коде нет вообще
/// («пик за 2 дня до овуляции»). Такое расхождение особенно плохо для
/// приложения о здоровье: пользователь принимает решения по описанию.
///
/// КАК РАБОТАЕТ. Тест читает исходник about_screen.dart как ТЕКСТ и ищет
/// в нём числа, которые должны совпадать с константами движка. Если
/// константу поменяли, а описание — нет, тест падает.
///
/// ОГРАНИЧЕНИЕ. Это проверка чисел, а не смысла. Формулировки всё равно
/// нужно перечитывать глазами при изменении методики.
void main() {
  late String aboutSource;

  setUpAll(() {
    final f = File('lib/features/about/about_screen.dart');
    expect(f.existsSync(), true,
        reason: 'Не найден about_screen.dart — проверь путь запуска тестов');
    aboutSource = f.readAsStringSync();
  });

  group('about_screen согласован с движком', () {
    test('лютеиновая фаза: заявленный диапазон совпадает с константами', () {
      const min = CycleConstants.lutealMinDays;
      const max = CycleConstants.lutealMaxDays;
      expect(
        aboutSource.contains('$min–$max'),
        true,
        reason: 'В about должен быть диапазон лютеиновой фазы $min–$max '
            '(из CycleConstants). Сейчас в тексте его нет — либо поменяли '
            'константы и забыли описание, либо наоборот.',
      );
    });

    test('фертильное окно: заявленное число дней ДО совпадает с константой',
        () {
      const before = CycleConstants.fertileBeforeOvulation;
      expect(
        aboutSource.contains('$before дней до овуляции'),
        true,
        reason: 'В about должно быть «$before дней до овуляции» '
            '(fertileBeforeOvulation). Расхождение = описание врёт.',
      );
    });

    test('фертильное окно: день ПОСЛЕ овуляции описан, если он есть в коде',
        () {
      const after = CycleConstants.fertileAfterOvulation;
      if (after > 0) {
        // Если код добавляет день после овуляции — это ОБЯЗАНО быть
        // объяснено в about (мы отступаем от классического окна Mihm 2011).
        expect(
          aboutSource.contains('день после'),
          true,
          reason: 'fertileAfterOvulation = $after, значит окно шире '
              'классического (Mihm 2011: только до дня овуляции). '
              'Это отступление ОБЯЗАНО быть объяснено в about — '
              'иначе мы молча расширяем фертильное окно.',
        );
      } else {
        // Если день после убрали — в about не должно остаться упоминаний.
        expect(
          aboutSource.contains('день после'),
          false,
          reason: 'fertileAfterOvulation = 0, но about всё ещё упоминает '
              '«день после» — описание устарело.',
        );
      }
    });

    test('число циклов для медианы совпадает с константой', () {
      const n = CycleConstants.maxCyclesForMedian;
      expect(
        aboutSource.contains('последних $n циклов'),
        true,
        reason: 'В about должно быть «последних $n циклов» '
            '(maxCyclesForMedian).',
      );
    });

    test('MAD упомянут, раз он используется в движке', () {
      // Интервал прогноза считается через MAD — это ключевая часть методики
      // («честное окно»), и пользователь вправе знать, как она устроена.
      expect(
        aboutSource.contains('MAD'),
        true,
        reason: 'Движок считает разброс через MAD, но about об этом молчит.',
      );
    });

    test('фильтр «склеек» описан, раз он есть в движке', () {
      expect(
        aboutSource.contains('склей'),
        true,
        reason: 'В движке есть _resolveSeams (распознавание пропущенных '
            'отметок), но about об этом не говорит.',
      );
    });

    test('about не заявляет того, чего в движке нет', () {
      // Исторический баг: описание обещало «пик за 2 дня до овуляции»,
      // хотя окно в движке равномерное, без всякого пика.
      expect(
        aboutSource.contains('пик за 2 дня'),
        false,
        reason: 'В about заявлен «пик за 2 дня до овуляции», но движок '
            'строит РАВНОМЕРНОЕ фертильное окно — такой логики в коде нет.',
      );
    });
  });

  group('движок: инварианты методики', () {
    test('лютеиновая фаза всегда в заявленном диапазоне', () {
      for (var len = CycleConstants.minPlausibleCycle;
          len <= CycleConstants.maxPlausibleCycle;
          len++) {
        final l = lutealForCycle(len);
        expect(
          l >= CycleConstants.lutealMinDays &&
              l <= CycleConstants.lutealMaxDays,
          true,
          reason: 'lutealForCycle($len) = $l — вне заявленного диапазона '
              '${CycleConstants.lutealMinDays}–${CycleConstants.lutealMaxDays}',
        );
      }
    });

    test('фертильное окно строится вокруг овуляции с заявленной шириной', () {
      final starts = <DateTime>[
        DateTime(2026, 1, 1),
        DateTime(2026, 1, 29),
        DateTime(2026, 2, 26),
      ];
      final p = predictCycle(
        periodStartDates: starts,
        today: DateTime(2026, 3, 1),
      );
      final ov = p.ovulationWindow.start.add(const Duration(days: 1));
      final expectedStart = ov.subtract(
          const Duration(days: CycleConstants.fertileBeforeOvulation));
      final expectedEnd =
          ov.add(const Duration(days: CycleConstants.fertileAfterOvulation));

      expect(p.fertileWindow.start, expectedStart,
          reason: 'Начало фертильного окна не совпадает с '
              'fertileBeforeOvulation');
      expect(p.fertileWindow.end, expectedEnd,
          reason: 'Конец фертильного окна не совпадает с '
              'fertileAfterOvulation');
    });
  });
}
