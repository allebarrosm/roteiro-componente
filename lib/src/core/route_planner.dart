import 'geo_point.dart';
import 'roteiro_client.dart';
import 'route_service.dart';
import 'visity_day.dart';

/// Uma perna de rota: dia + quinzena/semana.
class RoteiroRoute {
  const RoteiroRoute({
    required this.day,
    required this.firstWeek,
    required this.points,
  });

  final VisityDay day;
  final bool firstWeek;
  final List<GeoPoint> points;

  @override
  String toString() =>
      'RoteiroRoute(${day.name}, firstWeek: $firstWeek, ${points.length} pts)';
}

/// Agrupa clientes por dia e por quinzena/semana, ordena por `visitOrder` e
/// chama o [RouteService] apenas quando há pelo menos dois pontos.
class RoutePlanner {
  const RoutePlanner(this.routeService);

  final RouteService routeService;

  Future<List<RoteiroRoute>> plan(Iterable<RoteiroClient> clients) async {
    final withCoordinate = clients
        .where((client) => client.coordinate != null)
        .toList(growable: false);

    final routes = <RoteiroRoute>[];

    for (final day in VisityDay.values) {
      final dayClients = withCoordinate
          .where((client) => client.day == day)
          .toList(growable: false);

      if (dayClients.length < 2) continue;

      for (final firstWeek in const [true, false]) {
        final weekClients = dayClients
            .where((client) => client.firstWeek == firstWeek)
            .toList();

        if (weekClients.length < 2) continue;

        weekClients.sort((a, b) {
          final byOrder = a.visitOrder.compareTo(b.visitOrder);
          if (byOrder != 0) return byOrder;
          return a.personCode.compareTo(b.personCode);
        });

        final waypoints = weekClients
            .map((client) => client.coordinate!)
            .toList(growable: false);

        final points = await routeService.route(waypoints);
        if (points.length < 2) continue;

        routes.add(
          RoteiroRoute(day: day, firstWeek: firstWeek, points: points),
        );
      }
    }

    return routes;
  }
}
