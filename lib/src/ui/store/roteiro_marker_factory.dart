import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../core/periodicity.dart';
import '../../core/roteiro_client.dart';
import '../../core/visity_day.dart';

/// Cria marcadores com o ícone do dia/periodicidade.
///
/// O ícone é carregado do asset do pacote uma única vez por caminho e
/// redimensionado para [iconSize] (mesmo resultado do
/// `resizeAndCreateBitmapDescriptor` dos apps).
class RoteiroMarkerFactory {
  RoteiroMarkerFactory({this.iconSize = 40});

  final int iconSize;
  final Map<String, Future<BitmapDescriptor>> _iconCache =
      <String, Future<BitmapDescriptor>>{};

  Future<Marker?> build(RoteiroClient client, {VoidCallback? onTap}) async {
    final coordinate = client.coordinate;
    if (coordinate == null) return null;

    final icon = await _iconFor(client);

    return Marker(
      markerId: MarkerId(client.personCode),
      position: LatLng(coordinate.latitude, coordinate.longitude),
      icon: icon,
      infoWindow: InfoWindow.noText,
      onTap: onTap,
    );
  }

  String iconPathFor(RoteiroClient client) {
    final day = client.day;
    if (day == null) return VisityDay.defaultIconAsset;

    final icons = day.periodicityIcons;

    return switch (client.periodicity) {
      Periodicity.weekly => icons[0],
      Periodicity.fortnightly => client.firstWeek ? icons[1] : icons[2],
      Periodicity.monthly => icons[3],
      Periodicity.days21 => icons[4],
      null => day.iconAsset,
    };
  }

  Future<BitmapDescriptor> _iconFor(RoteiroClient client) {
    final path = iconPathFor(client);
    return _iconCache.putIfAbsent(path, () => _loadIcon(path));
  }

  Future<BitmapDescriptor> _loadIcon(String asset) async {
    final data = await rootBundle.load(asset);
    final codec = await ui.instantiateImageCodec(
      data.buffer.asUint8List(),
      targetWidth: iconSize,
      targetHeight: iconSize,
    );
    final frame = await codec.getNextFrame();
    final bytes = await frame.image.toByteData(format: ui.ImageByteFormat.png);
    frame.image.dispose();
    codec.dispose();

    if (bytes == null) {
      throw StateError('Falha ao converter o ícone $asset');
    }

    // `BitmapDescriptor.bytes` só existe nas versões novas; usamos fromBytes
    // para continuar compatível com google_maps_flutter 2.14.
    // ignore: deprecated_member_use
    return BitmapDescriptor.fromBytes(bytes.buffer.asUint8List());
  }
}
