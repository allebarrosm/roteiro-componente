import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roteiro/roteiro.dart';

import '../support/fixtures.dart';

void main() {
  testWidgets('diálogo devolve RoteiroVisitChange ao salvar', (tester) async {
    final roteiroClient = client(
      code: '1001',
      name: 'Mercado Boa Vista',
      day: VisityDay.monday,
      periodicity: Periodicity.weekly,
      visitOrder: 1,
      lat: -8.05,
      lon: -34.9,
    );

    RoteiroVisitChange? result;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () async {
                result = await RoteiroVisitDialog.show(context, roteiroClient);
              },
              child: const Text('abrir'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('abrir'));
    await tester.pumpAndSettle();

    expect(find.text('Dias visita'), findsOneWidget);
    expect(find.text('Frequência'), findsNWidgets(2));

    await tester.tap(find.text('Salvar Alterações'));
    await tester.pumpAndSettle();

    expect(result, isNotNull);
    expect(result!.client.personCode, '1001');
    expect(result!.day, VisityDay.monday);
    expect(result!.periodicity, PeriodicityFilter.weekly);
    expect(result!.visitOrder, 1);
  });
}
