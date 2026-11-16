import 'package:flutter_test/flutter_test.dart';
import 'package:roteiro/roteiro.dart';

import '../support/fakes.dart';
import '../support/fixtures.dart';

RoteiroStore _store({
  bool editableVisits = false,
  Future<void> Function(RoteiroVisitChange change)? onSaveVisit,
}) {
  return RoteiroStore(
    editableVisits: editableVisits,
    onSaveVisit: onSaveVisit,
    markerFactory: FakeMarkerFactory(),
    routePlanner: RoutePlanner(EchoRouteService()),
  );
}

void main() {
  group('RoteiroStore.saveVisit', () {
    test('desabilitado por padrão não altera nada', () async {
      final store = _store();
      await store.setClients([
        client(
          code: '1',
          day: VisityDay.monday,
          periodicity: Periodicity.weekly,
          visitOrder: 1,
        ),
      ]);

      final change = RoteiroVisitChange(
        client: store.clients.first,
        day: VisityDay.friday,
        periodicity: PeriodicityFilter.weekly,
        visitOrder: 4,
      );

      expect(await store.saveVisit(change), isFalse);
      expect(store.clients.first.day, VisityDay.monday);
      expect(store.clients.first.visitOrder, 1);
    });

    test('habilitado persiste, atualiza e reaplica filtros/rotas', () async {
      final saved = <RoteiroVisitChange>[];
      final store = _store(
        editableVisits: true,
        onSaveVisit: (change) async => saved.add(change),
      );

      await store.setClients([
        client(
          code: '1',
          name: 'Ana',
          day: VisityDay.monday,
          periodicity: Periodicity.weekly,
          visitOrder: 1,
          lat: -8.01,
        ),
        client(
          code: '2',
          name: 'Bruno',
          day: VisityDay.monday,
          periodicity: Periodicity.weekly,
          visitOrder: 2,
          lat: -8.02,
        ),
      ]);

      store.select(store.clients.first);

      final change = RoteiroVisitChange(
        client: store.clients.first,
        day: VisityDay.friday,
        periodicity: PeriodicityFilter.firstWeek,
        visitOrder: 7,
        dateBase: DateTime(2026, 12, 4),
      );

      expect(await store.saveVisit(change), isTrue);

      expect(saved, hasLength(1));
      expect(saved.single.client.personCode, '1');

      final updated = store.clients.first;
      expect(updated.day, VisityDay.friday);
      expect(updated.periodicity, Periodicity.fortnightly);
      expect(updated.firstWeek, isTrue);
      expect(updated.visitOrder, 7);
      expect(updated.dateBase, DateTime(2026, 12, 4));

      expect(store.selected?.day, VisityDay.friday);
      expect(store.visibleClients, hasLength(2));
      expect(store.markers, hasLength(2));

      // Cada dia ficou com um cliente: não há rota com 2+ pontos.
      expect(store.polylines, isEmpty);
    });

    test('falha do onSaveVisit mantém o estado anterior', () async {
      final store = _store(
        editableVisits: true,
        onSaveVisit: (change) async => throw StateError('offline'),
      );

      await store.setClients([
        client(
          code: '1',
          day: VisityDay.monday,
          periodicity: Periodicity.weekly,
          visitOrder: 1,
          lat: -8.01,
        ),
      ]);

      final change = RoteiroVisitChange(
        client: store.clients.first,
        day: VisityDay.friday,
        periodicity: PeriodicityFilter.weekly,
        visitOrder: 2,
      );

      expect(await store.saveVisit(change), isFalse);
      expect(store.clients.first.day, VisityDay.monday);
      expect(store.errorMessage, contains('Falha ao salvar'));
    });

    test('aplicar filtro reavalia o cliente editado', () async {
      final store = _store(editableVisits: true);

      await store.setClients([
        client(
          code: '1',
          day: VisityDay.monday,
          periodicity: Periodicity.weekly,
          visitOrder: 1,
          lat: -8.01,
        ),
        client(
          code: '2',
          day: VisityDay.monday,
          periodicity: Periodicity.weekly,
          visitOrder: 2,
          lat: -8.02,
        ),
      ]);

      await store.setFilter(
        const RoteiroFilter(
          days: {VisityDay.friday},
          noScheduling: false,
        ),
      );
      expect(store.visibleClients, isEmpty);

      final change = RoteiroVisitChange(
        client: store.clients.first,
        day: VisityDay.friday,
        periodicity: PeriodicityFilter.weekly,
        visitOrder: 3,
      );

      expect(await store.saveVisit(change), isTrue);
      expect(store.visibleClients, hasLength(1));
      expect(store.visibleClients.single.personCode, '1');
    });
  });
}
