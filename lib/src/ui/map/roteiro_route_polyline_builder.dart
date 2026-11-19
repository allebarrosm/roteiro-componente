import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../core/route_planner.dart';
import '../theme/visity_day_ui.dart';

/// Converte as pernas de rota do [RoutePlanner] em polylines do mapa.
///
/// O preview usa IDs com sufixo `_preview` e padrão tracejado; a rota final
/// usa o ID base e linha sólida. IDs diferentes garantem que o mapa remova o
/// preview ao inserir a rota definitiva.
class RoteiroRoutePolylineBuilder {
  const RoteiroRoutePolylineBuilder({
    this.width = 3,
    this.opacity = 0.85,
  });

  final int width;
  final double opacity;

  Set<Polyline> build(
    Iterable<RoteiroRoute> routes, {
    bool preview = false,
  }) {
    return {
      for (final route in routes)
        Polyline(
          polylineId: PolylineId(_id(route, preview: preview)),
          points: [
            for (final point in route.points)
              LatLng(point.latitude, point.longitude),
          ],
          color: (route.firstWeek ? route.day.color2 : route.day.color)
              .withValues(alpha: opacity),
          width: width,
          patterns: preview
              ? [PatternItem.dash(18), PatternItem.gap(10)]
              : const [],
        ),
    };
  }

  String _id(RoteiroRoute route, {required bool preview}) {
    final base = '${route.day.title}'
        '${route.firstWeek ? 'FirstWeek' : 'SecondWeek'}';
    return preview ? '${base}_preview' : base;
  }
}
