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
/// chama o [RouteService].
///
/// Regras (as mesmas do BackOffice):
/// - quando as duas quinzenas do dia têm mais de um ponto, gera duas rotas;
/// - quando uma delas tem só um ponto, junta os dois grupos em uma rota do dia;
/// - se o OSRM falhar, devolve os próprios waypoints para o mapa desenhar uma
///   linha sólida, nunca deixando o preview pontilhado como resultado final.
class RoutePlanner {
  const RoutePlanner(this.routeService);

  final RouteService routeService;

  Future<List<RoteiroRoute>> plan(
    Iterable<RoteiroClient> clients, {
    void Function(List<RoteiroRoute> preview)? onPreview,
  }) async {
    final withCoordinate = clients
        .where((client) => client.coordinate != null)
        .toList(growable: false);

    final groups = <_RouteGroup>[];

    int compareClients(RoteiroClient a, RoteiroClient b) {
      final byOrder = a.visitOrder.compareTo(b.visitOrder);
      if (byOrder != 0) return byOrder;
      return a.personCode.compareTo(b.personCode);
    }

    for (final day in VisityDay.values) {
      final dayClients = withCoordinate
          .where((client) => client.day == day)
          .toList(growable: false);

      if (dayClients.length < 2) continue;

      final firstWeek = dayClients
          .where((client) => client.firstWeek)
          .toList()
        ..sort(compareClients);
      final lastWeek = dayClients
          .where((client) => !client.firstWeek)
          .toList()
        ..sort(compareClients);

      if (firstWeek.length > 1 && lastWeek.length > 1) {
        groups.add(
          _RouteGroup(
            day: day,
            firstWeek: true,
            waypoints: firstWeek
                .map((client) => client.coordinate!)
                .toList(growable: false),
          ),
        );
        groups.add(
          _RouteGroup(
            day: day,
            firstWeek: false,
            waypoints: lastWeek
                .map((client) => client.coordinate!)
                .toList(growable: false),
          ),
        );
      } else {
        final all = [...firstWeek, ...lastWeek]..sort(compareClients);
        if (all.length < 2) continue;

        groups.add(
          _RouteGroup(
            day: day,
            firstWeek: firstWeek.length >= lastWeek.length,
            waypoints: all
                .map((client) => client.coordinate!)
                .toList(growable: false),
          ),
        );
      }
    }

    final preview = groups
        .map(
          (group) => RoteiroRoute(
            day: group.day,
            firstWeek: group.firstWeek,
            points: group.waypoints,
          ),
        )
        .toList(growable: false);

    onPreview?.call(preview);

    // Os grupos são independentes; dispara todos os OSRM em paralelo.
    return Future.wait(
      groups.map((group) async {
        try {
          final points = await routeService.route(group.waypoints);
          return RoteiroRoute(
            day: group.day,
            firstWeek: group.firstWeek,
            points: points.length >= 2 ? points : group.waypoints,
          );
        } catch (_) {
          // Falha de rota não derruba a tela nem deixa o preview pontilhado.
          return RoteiroRoute(
            day: group.day,
            firstWeek: group.firstWeek,
            points: group.waypoints,
          );
        }
      }),
    );
  }
}

class _RouteGroup {
  const _RouteGroup({
    required this.day,
    required this.firstWeek,
    required this.waypoints,
  });

  final VisityDay day;
  final bool firstWeek;
  final List<GeoPoint> waypoints;
}
