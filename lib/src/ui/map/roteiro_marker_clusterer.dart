import 'dart:math' as math;

import 'package:flutter/widgets.dart' show Offset;
import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Grupo de marcadores próximos que usam o mesmo ícone.
///
/// No mapa ele aparece como um único ponto real do grupo ([representative]),
/// com o mesmo ícone dos clientes, sem contador.
class RoteiroCluster {
  RoteiroCluster({
    required this.id,
    required this.representative,
    required this.members,
  });

  final String id;

  /// Membro mais próximo do centro do grupo; dá posição e ícone ao marcador.
  final Marker representative;
  final List<Marker> members;

  LatLng get position => representative.position;

  int get count => members.length;

  /// Retângulo que envolve todos os membros (usado para "abrir" o grupo).
  LatLngBounds get bounds {
    var minLat = double.infinity;
    var maxLat = -double.infinity;
    var minLng = double.infinity;
    var maxLng = -double.infinity;
    for (final marker in members) {
      final p = marker.position;
      minLat = math.min(minLat, p.latitude);
      maxLat = math.max(maxLat, p.latitude);
      minLng = math.min(minLng, p.longitude);
      maxLng = math.max(maxLng, p.longitude);
    }
    return LatLngBounds(
      southwest: LatLng(minLat, minLng),
      northeast: LatLng(maxLat, maxLng),
    );
  }
}

class RoteiroClusterResult {
  const RoteiroClusterResult({required this.singles, required this.clusters});

  /// Marcadores exibidos individualmente (com título flutuante).
  final List<Marker> singles;

  /// Grupos exibidos como um único ícone.
  final List<RoteiroCluster> clusters;
}

/// Agrupamento em grade por zoom e ícone + recorte pela área visível.
///
/// Mesma ideia de mapas de tráfego em tempo real: só o que está na tela (mais
/// uma margem) é enviado ao mapa e, com o mapa afastado, pontos próximos que
/// usam o mesmo ícone (mesmo dia/periodicidade) aparecem uma vez só. Ícones
/// diferentes na mesma área continuam visíveis. A partir de [maxClusterZoom]
/// todos os pontos visíveis aparecem individualmente.
///
/// É Dart puro e síncrono: o custo é O(n) sobre a lista em memória, que é
/// desprezível perto do custo de criar milhares de marcadores no mapa.
class RoteiroMarkerClusterer {
  const RoteiroMarkerClusterer({
    this.cellSize = 80,
    this.maxClusterZoom = 15,
    this.minClusterSize = 2,
  });

  /// Tamanho da célula da grade, em pixels de tela.
  final double cellSize;

  /// Zoom a partir do qual nada é agrupado.
  final double maxClusterZoom;

  /// Quantidade mínima de pontos numa célula para virar grupo.
  final int minClusterSize;

  RoteiroClusterResult cluster(
    Iterable<Marker> markers, {
    required double zoom,
    LatLngBounds? bounds,
  }) {
    final inView = bounds == null
        ? markers.toList(growable: false)
        : markers.where((m) => contains(bounds, m.position)).toList();

    if (zoom >= maxClusterZoom) {
      return RoteiroClusterResult(singles: inView, clusters: const []);
    }

    // Zoom inteiro deixa as células estáveis durante pequenos ajustes.
    final z = zoom.floor().clamp(0, 30);
    final worldSize = 256.0 * math.pow(2, z);

    // Chave = célula + ícone. Os ícones vêm do cache do RoteiroMarkerFactory,
    // então clientes do mesmo dia/periodicidade compartilham a mesma instância.
    final groups = <String, List<Marker>>{};
    final cellsPerRow = (worldSize / cellSize).ceil() + 1;
    for (final marker in inView) {
      final point = _project(marker.position);
      final cx = (point.dx * worldSize / cellSize).floor();
      final cy = (point.dy * worldSize / cellSize).floor();
      final key = '${cy * cellsPerRow + cx}_${identityHashCode(marker.icon)}';
      groups.putIfAbsent(key, () => <Marker>[]).add(marker);
    }

    final singles = <Marker>[];
    final clusters = <RoteiroCluster>[];
    groups.forEach((key, members) {
      if (members.length < minClusterSize) {
        singles.addAll(members);
        return;
      }
      clusters.add(
        RoteiroCluster(
          id: 'roteiro_cluster_${z}_$key',
          representative: _nearestToCenter(members),
          members: members,
        ),
      );
    });

    return RoteiroClusterResult(singles: singles, clusters: clusters);
  }

  static Marker _nearestToCenter(List<Marker> members) {
    var lat = 0.0;
    var lng = 0.0;
    for (final m in members) {
      lat += m.position.latitude;
      lng += m.position.longitude;
    }
    lat /= members.length;
    lng /= members.length;

    var best = members.first;
    var bestDistance = double.infinity;
    for (final m in members) {
      final dLat = m.position.latitude - lat;
      final dLng = m.position.longitude - lng;
      final distance = dLat * dLat + dLng * dLng;
      if (distance < bestDistance) {
        bestDistance = distance;
        best = m;
      }
    }
    return best;
  }

  /// Aumenta o retângulo em [factor] de cada lado, para que pontos logo fora
  /// da tela já estejam carregados ao arrastar.
  static LatLngBounds expand(LatLngBounds bounds, double factor) {
    final sw = bounds.southwest;
    final ne = bounds.northeast;
    final latPad = (ne.latitude - sw.latitude).abs() * factor;
    var lngSpan = ne.longitude - sw.longitude;
    if (lngSpan < 0) lngSpan += 360;
    final lngPad = lngSpan * factor;

    if (lngSpan + 2 * lngPad >= 360) {
      return LatLngBounds(
        southwest: LatLng(math.max(-90, sw.latitude - latPad), -180),
        northeast: LatLng(math.min(90, ne.latitude + latPad), 180),
      );
    }

    double wrap(double lng) => ((lng + 180) % 360 + 360) % 360 - 180;

    return LatLngBounds(
      southwest: LatLng(
        math.max(-90, sw.latitude - latPad),
        wrap(sw.longitude - lngPad),
      ),
      northeast: LatLng(
        math.min(90, ne.latitude + latPad),
        wrap(ne.longitude + lngPad),
      ),
    );
  }

  /// `contains` que também trata o retângulo cruzando o antimeridiano.
  static bool contains(LatLngBounds bounds, LatLng p) {
    final sw = bounds.southwest;
    final ne = bounds.northeast;
    if (p.latitude < sw.latitude || p.latitude > ne.latitude) return false;
    if (sw.longitude <= ne.longitude) {
      return p.longitude >= sw.longitude && p.longitude <= ne.longitude;
    }
    return p.longitude >= sw.longitude || p.longitude <= ne.longitude;
  }

  /// Web Mercator normalizado (0..1), igual ao usado pelo Google Maps.
  static Offset _project(LatLng p) {
    final x = (p.longitude + 180) / 360;
    final sinY =
        math.sin(p.latitude * math.pi / 180).clamp(-0.9999, 0.9999).toDouble();
    final y = 0.5 - math.log((1 + sinY) / (1 - sinY)) / (4 * math.pi);
    return Offset(x, y);
  }
}
