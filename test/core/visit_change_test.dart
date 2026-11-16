import 'package:flutter_test/flutter_test.dart';
import 'package:roteiro/roteiro.dart';

import '../support/fixtures.dart';

void main() {
  group('RoteiroVisitChange', () {
    test('mapeia as frequências do cliente', () {
      expect(
        RoteiroVisitChange.fromClient(
          client(code: '1', periodicity: Periodicity.weekly),
        ).periodicity,
        PeriodicityFilter.weekly,
      );
      expect(
        RoteiroVisitChange.fromClient(
          client(
            code: '1',
            periodicity: Periodicity.fortnightly,
            firstWeek: true,
          ),
        ).periodicity,
        PeriodicityFilter.firstWeek,
      );
      expect(
        RoteiroVisitChange.fromClient(
          client(
            code: '1',
            periodicity: Periodicity.fortnightly,
            firstWeek: false,
          ),
        ).periodicity,
        PeriodicityFilter.lastWeek,
      );
      expect(
        RoteiroVisitChange.fromClient(
          client(code: '1', periodicity: Periodicity.monthly),
        ).periodicity,
        PeriodicityFilter.monthly,
      );
      expect(
        RoteiroVisitChange.fromClient(
          client(code: '1', periodicity: Periodicity.days21),
        ).periodicity,
        PeriodicityFilter.days21,
      );
      expect(
        RoteiroVisitChange.fromClient(client(code: '1')).periodicity,
        isNull,
      );
    });

    test('apply altera dia, quinzena, ordem e data sem mutar o original', () {
      final original = client(
        code: '1',
        day: VisityDay.monday,
        periodicity: Periodicity.weekly,
        visitOrder: 1,
      );

      final change = RoteiroVisitChange(
        client: original,
        day: VisityDay.thursday,
        periodicity: PeriodicityFilter.lastWeek,
        visitOrder: 7,
        dateBase: DateTime(2026, 12, 3),
      );

      expect(change.isValid, isTrue);

      final updated = change.apply();
      expect(updated.day, VisityDay.thursday);
      expect(updated.periodicity, Periodicity.fortnightly);
      expect(updated.firstWeek, isFalse);
      expect(updated.visitOrder, 7);
      expect(updated.dateBase, DateTime(2026, 12, 3));

      expect(original.day, VisityDay.monday);
      expect(original.visitOrder, 1);
    });

    test('inválido quando falta dia/frequência ou a ordem é zero', () {
      expect(RoteiroVisitChange(client: client(code: '1')).isValid, isFalse);
      expect(
        RoteiroVisitChange(
          client: client(code: '1'),
          day: VisityDay.monday,
          periodicity: PeriodicityFilter.weekly,
          visitOrder: 0,
        ).isValid,
        isFalse,
      );
    });

    test('converte PeriodicityFilter em Periodicity', () {
      expect(PeriodicityFilter.firstWeek.periodicity, Periodicity.fortnightly);
      expect(PeriodicityFilter.lastWeek.periodicity, Periodicity.fortnightly);
      expect(PeriodicityFilter.weekly.periodicity, Periodicity.weekly);
      expect(PeriodicityFilter.monthly.periodicity, Periodicity.monthly);
      expect(PeriodicityFilter.days21.periodicity, Periodicity.days21);

      expect(PeriodicityFilter.firstWeek.isFirstWeek, isTrue);
      expect(PeriodicityFilter.lastWeek.isFirstWeek, isFalse);
    });
  });
}
