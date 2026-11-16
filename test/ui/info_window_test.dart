import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roteiro/roteiro.dart';

void main() {
  testWidgets('popup mostra o lápis e chama onEdit', (tester) async {
    var edited = false;
    var closed = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: RoteiroInfoWindow(
              data: const RoteiroInfoWindowData(
                title: 'Mercado Boa Vista',
                subtitle: 'Rua da Aurora, 100',
              ),
              onEdit: () => edited = true,
              onClose: () => closed = true,
            ),
          ),
        ),
      ),
    );

    expect(find.byIcon(Icons.edit_outlined), findsOneWidget);
    expect(find.byTooltip('Editar roteiro'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.edit_outlined));
    expect(edited, isTrue);
    expect(closed, isFalse);
  });

  testWidgets('sem onEdit não mostra o lápis', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: RoteiroInfoWindow(
            data: const RoteiroInfoWindowData(title: 'Cliente'),
            onClose: () {},
          ),
        ),
      ),
    );

    expect(find.byIcon(Icons.edit_outlined), findsNothing);
  });
}
