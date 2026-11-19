import 'package:flutter_test/flutter_test.dart';
import 'package:roteiro/roteiro.dart';

import '../support/fixtures.dart';

class _EchoRouteService implements RouteService {
  const _EchoRouteService();

  @override
  Future<List<GeoPoint>> route(List<GeoPoint> waypoints) async => waypoints;
}

class _CountingRouteService implements RouteService {
  int calls = 0;

  @override
  Future<List<GeoPoint>> route(List<GeoPoint> waypoints) async {
    calls++;
    return waypoints;
  }
}

class _EmptyRouteService implements RouteService {
  const _EmptyRouteService();

  @override
  Future<List<GeoPoint>> route(List<GeoPoint> waypoints) async => const [];
}

void main() {
  group('RoutePlanner', () {
    test('agrupa por dia/quinzena e junta quinzena isolada', () async {
      final planner = RoutePlanner(const _EchoRouteService());

      final routes = await planner.plan([
        client(
          code: '1',
          day: VisityDay.monday,
          periodicity: Periodicity.fortnightly,
          firstWeek: true,
          visitOrder: 2,
          lat: -8.02,
        ),
        client(
          code: '2',
          day: VisityDay.monday,
          periodicity: Periodicity.fortnightly,
          firstWeek: true,
          visitOrder: 1,
          lat: -8.01,
        ),
        // Segunda, 2ª quinzena, só um cliente: não gera rota.
        client(
          code: '3',
          day: VisityDay.monday,
          periodicity: Periodicity.fortnightly,
          firstWeek: false,
          visitOrder: 1,
        ),
        client(
          code: '4',
          day: VisityDay.tuesday,
          periodicity: Periodicity.weekly,
          visitOrder: 2,
          lat: -8.03,
        ),
        client(
          code: '5',
          day: VisityDay.tuesday,
          periodicity: Periodicity.weekly,
          visitOrder: 1,
          lat: -8.04,
        ),
        // Quarta: um sem coordenada, sobra só um ponto.
        client(
          code: '6',
          day: VisityDay.wednesday,
          visitOrder: 1,
          lat: null,
          lon: null,
        ),
        client(
          code: '7',
          day: VisityDay.wednesday,
          visitOrder: 2,
          lat: -8.05,
        ),
      ]);

      expect(routes, hasLength(2));

      expect(routes[0].day, VisityDay.monday);
      expect(routes[0].firstWeek, isTrue);
      expect(
        routes[0].points.map((point) => point.latitude),
        [-8.01, -8.05, -8.02],
      );

      expect(routes[1].day, VisityDay.tuesday);
      expect(routes[1].firstWeek, isFalse);
      expect(
        routes[1].points.map((point) => point.latitude),
        [-8.04, -8.03],
      );
    });

    test('usa os waypoints quando o OSRM não devolve rota', () async {
      final planner = RoutePlanner(const _EmptyRouteService());
      List<RoteiroRoute>? preview;

      final routes = await planner.plan(
        [
          client(
            code: '1',
            day: VisityDay.monday,
            visitOrder: 2,
            lat: -8.02,
          ),
          client(
            code: '2',
            day: VisityDay.monday,
            visitOrder: 1,
            lat: -8.01,
          ),
        ],
        onPreview: (value) => preview = value,
      );

      expect(preview, hasLength(1));
      expect(preview!.single.points, hasLength(2));
      expect(routes, hasLength(1));
      expect(
        routes.single.points.map((point) => point.latitude),
        [-8.01, -8.02],
      );
    });

    test('não chama o serviço quando há menos de dois pontos', () async {
      final service = _CountingRouteService();
      final planner = RoutePlanner(service);

      final routes = await planner.plan([
        client(code: '1', day: VisityDay.monday, lat: -8.01),
        client(code: '2', day: VisityDay.tuesday, lat: -8.02),
      ]);

      expect(routes, isEmpty);
      expect(service.calls, 0);
    });
  });
}
