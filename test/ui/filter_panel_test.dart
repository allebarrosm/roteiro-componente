import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roteiro/roteiro.dart';

import '../support/fakes.dart';
import '../support/fixtures.dart';

void main() {
  testWidgets('painel aplica filtro de dia no layout dos apps', (tester) async {
    final store = RoteiroStore(
      markerFactory: FakeMarkerFactory(),
      routePlanner: RoutePlanner(EchoRouteService()),
    );

    await store.setClients([
      client(
        code: '1',
        day: VisityDay.monday,
        periodicity: Periodicity.weekly,
        lat: -8.01,
      ),
      client(
        code: '2',
        day: VisityDay.tuesday,
        periodicity: Periodicity.weekly,
        lat: -8.02,
      ),
    ]);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: RoteiroFilterPanel(store: store),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Dias Visitas'), findsOneWidget);
    expect(find.text('Frequência'), findsOneWidget);

    await tester.tap(find.text('Terça-feira'));
    await tester.pump();

    await tester.tap(find.text('Aplicar'));
    await tester.pumpAndSettle();

    expect(store.filter.days, {VisityDay.tuesday});
    expect(store.visibleClients, hasLength(1));
    expect(store.visibleClients.single.personCode, '2');
  });
}
