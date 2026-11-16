import 'package:flutter/foundation.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:roteiro/roteiro.dart';

/// Marcador sem carregar asset (testes de store).
class FakeMarkerFactory extends RoteiroMarkerFactory {
  @override
  Future<Marker?> build(RoteiroClient client, {VoidCallback? onTap}) async {
    final coordinate = client.coordinate;
    if (coordinate == null) return null;

    return Marker(
      markerId: MarkerId(client.personCode),
      position: LatLng(coordinate.latitude, coordinate.longitude),
      onTap: onTap,
    );
  }
}

/// Rota que devolve os próprios waypoints (sem rede).
class EchoRouteService implements RouteService {
  @override
  Future<List<GeoPoint>> route(List<GeoPoint> waypoints) async => waypoints;
}
