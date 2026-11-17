import 'dart:convert';

import 'package:http/http.dart' as http;

import 'geo_point.dart';
import 'route_service.dart';

/// Cliente do OSRM (mesmo endpoint público usado hoje pelos três apps).
///
/// O servidor de demonstração (`router.project-osrm.org`) não tem SLA; para
/// produção, injete outro [baseUrl] ou outro [RouteService].
class OsrmRouteService implements RouteService {
  OsrmRouteService({
    this.baseUrl = 'https://router.project-osrm.org',
    this.timeout = const Duration(seconds: 10),
    http.Client? client,
  }) : _client = client ?? http.Client();

  final String baseUrl;
  final Duration timeout;
  final http.Client _client;

  @override
  Future<List<GeoPoint>> route(List<GeoPoint> waypoints) async {
    if (waypoints.length < 2) return const [];

    try {
      final coordinates = waypoints
          .map((point) => '${point.longitude},${point.latitude}')
          .join(';');

      final uri = Uri.parse(
        '$baseUrl/route/v1/driving/$coordinates'
        '?overview=simplified&geometries=geojson&steps=false',
      );

      final response = await _client.get(uri).timeout(timeout);
      if (response.statusCode != 200) return const [];

      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic>) return const [];

      final routes = decoded['routes'];
      if (routes is! List || routes.isEmpty) return const [];

      final first = routes.first;
      if (first is! Map) return const [];

      final geometry = first['geometry'];
      if (geometry is! Map) return const [];

      final coordinatesJson = geometry['coordinates'];
      if (coordinatesJson is! List) return const [];

      return coordinatesJson
          .whereType<List>()
          .map(
            (pair) => GeoPoint(
              (pair[1] as num).toDouble(),
              (pair[0] as num).toDouble(),
            ),
          )
          .toList(growable: false);
    } catch (_) {
      // Igual aos apps: falha de rota não derruba a tela.
      return const [];
    }
  }
}
