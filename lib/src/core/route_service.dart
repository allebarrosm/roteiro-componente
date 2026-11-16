import 'geo_point.dart';

/// Contrato de cálculo de rota (OSRM ou outro provedor).
abstract interface class RouteService {
  Future<List<GeoPoint>> route(List<GeoPoint> waypoints);
}
