import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:roteiro/roteiro.dart';

class _FakeStreetViewService implements RoteiroStreetViewService {
  _FakeStreetViewService(this.result);

  final RoteiroStreetViewResult result;
  int calls = 0;

  @override
  Future<RoteiroStreetViewResult> verify(LatLng coordinate) async {
    calls++;
    return result;
  }
}

void main() {
  const coordinate = LatLng(-8.05, -34.9);

  group('GoogleStreetViewService', () {
    test('status OK devolve disponível e a coordenada ajustada', () async {
      final service = GoogleStreetViewService(
        apiKey: 'test-key',
        client: MockClient((request) async {
          expect(request.url.host, 'maps.googleapis.com');
          expect(request.url.path, '/maps/api/streetview/metadata');
          expect(request.url.queryParameters['key'], 'test-key');
          expect(request.url.queryParameters['location'], '-8.05,-34.9');

          return http.Response(
            jsonEncode(<String, Object?>{
              'status': 'OK',
              'location': <String, Object?>{
                'lat': -8.051,
                'lng': -34.901,
              },
            }),
            200,
          );
        }),
      );

      final result = await service.verify(coordinate);

      expect(result.available, isTrue);
      expect(result.coordinate, const LatLng(-8.051, -34.901));
    });

    test('ZERO_RESULTS fica indisponível', () async {
      final service = GoogleStreetViewService(
        apiKey: 'test-key',
        client: MockClient(
          (_) async => http.Response(
            jsonEncode(<String, Object?>{'status': 'ZERO_RESULTS'}),
            200,
          ),
        ),
      );

      final result = await service.verify(coordinate);

      expect(result.available, isFalse);
      expect(result.coordinate, isNull);
    });

    test('REQUEST_DENIED fica indisponível', () async {
      final service = GoogleStreetViewService(
        apiKey: 'test-key',
        client: MockClient(
          (_) async => http.Response(
            jsonEncode(<String, Object?>{'status': 'REQUEST_DENIED'}),
            200,
          ),
        ),
      );

      expect((await service.verify(coordinate)).available, isFalse);
    });

    test('erro HTTP fica indisponível', () async {
      final service = GoogleStreetViewService(
        apiKey: 'test-key',
        client: MockClient((_) async => http.Response('erro', 500)),
      );

      expect((await service.verify(coordinate)).available, isFalse);
    });

    test('JSON inválido fica indisponível', () async {
      final service = GoogleStreetViewService(
        apiKey: 'test-key',
        client: MockClient((_) async => http.Response('not-json', 200)),
      );

      expect((await service.verify(coordinate)).available, isFalse);
    });

    test('sem chave não chama a API', () async {
      var calls = 0;
      final service = GoogleStreetViewService(
        apiKey: '  ',
        client: MockClient((_) async {
          calls++;
          return http.Response('', 200);
        }),
      );

      final result = await service.verify(coordinate);

      expect(result.available, isFalse);
      expect(calls, 0);
    });

    test('AlwaysAvailable devolve a própria coordenada', () async {
      const service = AlwaysAvailableStreetViewService();

      final result = await service.verify(coordinate);

      expect(result.available, isTrue);
      expect(result.coordinate, coordinate);
    });
  });

  group('RoteiroMapController.openStreetView', () {
    test('ativa com a coordenada verificada e fecha no segundo toque', () async {
      final service = _FakeStreetViewService(
        const RoteiroStreetViewResult(
          available: true,
          coordinate: LatLng(-8.06, -34.91),
        ),
      );
      final controller = RoteiroMapController(streetViewService: service);

      await controller.openStreetView(coordinate);

      expect(controller.isStreetView, isTrue);
      expect(controller.streetView, const LatLng(-8.06, -34.91));
      expect(service.calls, 1);

      await controller.openStreetView(coordinate);

      expect(controller.isStreetView, isFalse);
      expect(controller.streetView, isNull);
      expect(service.calls, 1);
    });

    test('indisponível mantém o mapa e reporta erro', () async {
      String? error;
      final controller = RoteiroMapController(
        streetViewService: _FakeStreetViewService(
          RoteiroStreetViewResult.unavailable,
        ),
        onError: (message) => error = message,
      );

      await controller.openStreetView(coordinate);

      expect(controller.isStreetView, isFalse);
      expect(controller.streetView, isNull);
      expect(error, contains('indisponível'));
    });
  });
}
