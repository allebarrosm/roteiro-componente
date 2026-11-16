import 'package:flutter_test/flutter_test.dart';
import 'package:roteiro/roteiro.dart';

void main() {
  group('GeoPoint.fromNullable', () {
    test('aceita coordenada válida', () {
      final point = GeoPoint.fromNullable(-8.05, -34.9);
      expect(point, isNotNull);
      expect(point!.latitude, -8.05);
      expect(point.longitude, -34.9);
    });

    test('rejeita nulo, zero e não finito', () {
      expect(GeoPoint.fromNullable(null, -34.9), isNull);
      expect(GeoPoint.fromNullable(0, 0), isNull);
      expect(GeoPoint.fromNullable(double.nan, -34.9), isNull);
      expect(GeoPoint.fromNullable(double.infinity, -34.9), isNull);
    });

    test('corrige coordenada sem separador decimal', () {
      final point = GeoPoint.fromNullable(-235489337.0, -465589337.0);
      expect(point, isNotNull);
      expect(point!.latitude, closeTo(-23.5489337, 1e-9));
      expect(point.longitude, closeTo(-46.5589337, 1e-9));
    });

    test('normaliza valor grande até a faixa válida', () {
      expect(GeoPoint.fromNullable(12345, 12345), isNotNull);
    });
  });
}
