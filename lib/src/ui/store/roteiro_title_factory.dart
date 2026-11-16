import 'package:flutter/material.dart';
import 'package:flutter_floating_map_marker_titles_core/model/floating_marker_title_info.dart';
import 'package:latlong2/latlong.dart' as latlong;

import '../../core/roteiro_client.dart';

/// Monta os títulos flutuantes exibidos sobre os marcadores.
class RoteiroTitleFactory {
  const RoteiroTitleFactory();

  List<FloatingMarkerTitleInfo> build(
    Iterable<RoteiroClient> clients, {
    required bool showSequence,
    required bool showName,
  }) {
    final result = <FloatingMarkerTitleInfo>[];

    for (final client in clients) {
      final coordinate = client.coordinate;
      if (coordinate == null) continue;

      final title = _titleFor(
        client,
        showSequence: showSequence,
        showName: showName,
      );
      if (title.isEmpty) continue;

      result.add(
        FloatingMarkerTitleInfo(
          id: int.tryParse(client.personCode.trim()) ??
              client.personCode.hashCode,
          title: title,
          color: Colors.yellow,
          latLng: latlong.LatLng(
            coordinate.latitude,
            coordinate.longitude,
          ),
        ),
      );
    }

    return result;
  }

  String _titleFor(
    RoteiroClient client, {
    required bool showSequence,
    required bool showName,
  }) {
    if (showSequence && showName) {
      return '${client.visitOrder} - ${client.displayName}';
    }
    if (showSequence) return '${client.visitOrder}';
    if (showName) return client.displayName;
    return '';
  }
}
