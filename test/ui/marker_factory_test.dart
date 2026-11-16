import 'package:flutter_test/flutter_test.dart';
import 'package:roteiro/roteiro.dart';

import '../support/fixtures.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('escolhe o ícone por dia e periodicidade', () {
    final factory = RoteiroMarkerFactory();

    String path({
      VisityDay? day = VisityDay.monday,
      Periodicity? periodicity,
      bool firstWeek = false,
    }) {
      return factory.iconPathFor(
        client(
          code: '1',
          day: day,
          periodicity: periodicity,
          firstWeek: firstWeek,
        ),
      );
    }

    expect(path(periodicity: Periodicity.weekly), contains('/semanal/'));
    expect(
      path(periodicity: Periodicity.fortnightly, firstWeek: true),
      contains('/quinzenal_1_3/'),
    );
    expect(
      path(periodicity: Periodicity.fortnightly, firstWeek: false),
      contains('/quinzenal_2_4/'),
    );
    expect(path(periodicity: Periodicity.monthly), contains('/mensal/'));
    expect(path(periodicity: Periodicity.days21), contains('/21dias/'));
    expect(path(), contains('place-red.png'));
    expect(path(day: null), contains('place-default.png'));
  });

  testWidgets('carrega o asset real empacotado', (tester) async {
    final factory = RoteiroMarkerFactory(iconSize: 20);

    final marker = await tester.runAsync(
      () => factory.build(
        client(
          code: '1',
          day: VisityDay.monday,
          periodicity: Periodicity.weekly,
          lat: -8.05,
          lon: -34.9,
        ),
      ),
    );

    expect(marker, isNotNull);
    expect(marker!.position.latitude, -8.05);
    expect(marker.position.longitude, -34.9);
  });
}
