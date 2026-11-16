import 'package:flutter_test/flutter_test.dart';
import 'package:roteiro/roteiro.dart';

import '../support/fakes.dart';
import '../support/fixtures.dart';

void main() {
  late RoteiroStore store;

  setUp(() {
    store = RoteiroStore(
      markerFactory: FakeMarkerFactory(),
      routePlanner: RoutePlanner(EchoRouteService()),
    );
  });

  Future<void> loadClients() {
    return store.setClients([
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
      client(
        code: '3',
        name: 'Carla',
        day: VisityDay.monday,
        periodicity: Periodicity.weekly,
        visitOrder: 3,
        lat: null,
        lon: null,
      ),
      client(
        code: '4',
        name: 'Sem agenda',
        visitOrder: 9,
        lat: -8.04,
      ),
    ]);
  }

  test('monta marcadores, títulos e uma polilinha por dia/quinzena', () async {
    await loadClients();

    expect(store.visibleClients, hasLength(4));
    expect(store.markers, hasLength(3));
    expect(store.titles, hasLength(3));
    expect(store.polylines, hasLength(1));
  });

  test('toggle de rota limpa e recria as polylines', () async {
    await loadClients();
    expect(store.polylines, hasLength(1));

    await store.setShowRoute(false);
    expect(store.showRoute, isFalse);
    expect(store.polylines, isEmpty);

    await store.setShowRoute(true);
    expect(store.polylines, hasLength(1));
  });

  test('desligar nome e sequência limpa os títulos', () async {
    await loadClients();
    expect(store.titles, isNotEmpty);

    store.setShowClients(false);
    store.setShowSequence(false);

    expect(store.titles, isEmpty);
  });

  test('filtro de dia remove o cliente selecionado', () async {
    await loadClients();
    store.select(store.visibleClients.first);

    await store.setFilter(
      const RoteiroFilter(
        days: {VisityDay.tuesday},
        noScheduling: false,
      ),
    );

    expect(store.visibleClients, isEmpty);
    expect(store.selected, isNull);
  });

  test('noScheduling desligado remove clientes sem dia', () async {
    await loadClients();
    expect(
      store.visibleClients.where((client) => client.day == null),
      hasLength(1),
    );

    await store.setNoScheduling(false);

    expect(
      store.visibleClients.where((client) => client.day == null),
      isEmpty,
    );
  });

  test('selecionar e limpar seleção', () async {
    await loadClients();
    final first = store.visibleClients.first;

    store.select(first);
    expect(store.selected, first);

    store.clearSelection();
    expect(store.selected, isNull);
  });
}
