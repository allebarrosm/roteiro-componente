import 'package:flutter_test/flutter_test.dart';
import 'package:roteiro/roteiro.dart';

import '../support/fixtures.dart';

void main() {
  group('RoteiroFilter', () {
    test('filtra por dia', () {
      final monday = client(
        code: '1',
        day: VisityDay.monday,
        periodicity: Periodicity.weekly,
      );
      final tuesday = client(
        code: '2',
        day: VisityDay.tuesday,
        periodicity: Periodicity.weekly,
      );

      const filter = RoteiroFilter(days: {VisityDay.monday});

      expect(filter.matches(monday), isTrue);
      expect(filter.matches(tuesday), isFalse);
    });

    test('sem filtro de dia aceita todos os dias', () {
      final monday = client(
        code: '1',
        day: VisityDay.monday,
        periodicity: Periodicity.weekly,
      );
      final sunday = client(
        code: '2',
        day: VisityDay.sunday,
        periodicity: Periodicity.monthly,
      );

      expect(RoteiroFilter.empty.matches(monday), isTrue);
      expect(RoteiroFilter.empty.matches(sunday), isTrue);
    });

    test('cliente sem dia só entra com noScheduling ligado', () {
      final noDay = client(code: '1', periodicity: Periodicity.weekly);

      expect(
        const RoteiroFilter(noScheduling: false).matches(noDay),
        isFalse,
      );
      expect(
        const RoteiroFilter(noScheduling: true).matches(noDay),
        isTrue,
      );
    });

    test('noScheduling ignora o filtro de dia para cliente sem dia', () {
      final noDay = client(code: '1');

      const filter = RoteiroFilter(
        days: {VisityDay.friday},
        noScheduling: true,
      );

      expect(filter.matches(noDay), isTrue);
    });

    test('separa quinzenal 1/3 e 2/4', () {
      final first = client(
        code: '1',
        day: VisityDay.monday,
        periodicity: Periodicity.fortnightly,
        firstWeek: true,
      );
      final last = client(
        code: '2',
        day: VisityDay.monday,
        periodicity: Periodicity.fortnightly,
        firstWeek: false,
      );

      const firstFilter = RoteiroFilter(
        periodicities: {PeriodicityFilter.firstWeek},
      );
      const lastFilter = RoteiroFilter(
        periodicities: {PeriodicityFilter.lastWeek},
      );

      expect(firstFilter.matches(first), isTrue);
      expect(firstFilter.matches(last), isFalse);
      expect(lastFilter.matches(last), isTrue);
      expect(lastFilter.matches(first), isFalse);
    });

    test('filtra semanal, mensal e 21 dias', () {
      final weekly = client(
        code: '1',
        day: VisityDay.monday,
        periodicity: Periodicity.weekly,
      );
      final monthly = client(
        code: '2',
        day: VisityDay.monday,
        periodicity: Periodicity.monthly,
      );
      final days21 = client(
        code: '3',
        day: VisityDay.monday,
        periodicity: Periodicity.days21,
      );

      const filter = RoteiroFilter(
        periodicities: {PeriodicityFilter.monthly},
      );

      expect(filter.matches(monthly), isTrue);
      expect(filter.matches(weekly), isFalse);
      expect(filter.matches(days21), isFalse);
    });

    test('apply mantém a ordem original', () {
      final clients = [
        client(code: '1', day: VisityDay.monday),
        client(code: '2', day: VisityDay.tuesday),
        client(code: '3', day: VisityDay.monday),
      ];

      const filter = RoteiroFilter(days: {VisityDay.monday});

      expect(
        filter.apply(clients).map((client) => client.personCode),
        ['1', '3'],
      );
    });
  });
}
