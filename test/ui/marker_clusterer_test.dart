import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:roteiro/roteiro.dart';

final _red = BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed);
final _blue = BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue);

Marker _m(String id, double lat, double lng, [BitmapDescriptor? icon]) =>
    Marker(
      markerId: MarkerId(id),
      position: LatLng(lat, lng),
      icon: icon ?? _red,
    );

void main() {
  const clusterer = RoteiroMarkerClusterer();

  // Dois pontos colados em São Paulo e um em Manaus.
  final markers = [
    _m('a', -23.5500, -46.6300),
    _m('b', -23.5501, -46.6301),
    _m('c', -3.1000, -60.0200),
  ];

  test('agrupa pontos próximos com o mapa afastado', () {
    final result = clusterer.cluster(markers, zoom: 5);

    expect(result.clusters, hasLength(1));
    expect(result.clusters.single.count, 2);
    expect(result.singles.map((m) => m.markerId.value), ['c']);
  });

  test('ícones diferentes na mesma área não se juntam', () {
    final mixed = [
      _m('r1', -23.5500, -46.6300),
      _m('r2', -23.5501, -46.6301),
      _m('r3', -23.5502, -46.6302),
      _m('b1', -23.5503, -46.6303, _blue),
      _m('b2', -23.5504, -46.6304, _blue),
    ];

    final result = clusterer.cluster(mixed, zoom: 5);

    expect(result.singles, isEmpty);
    expect(result.clusters, hasLength(2));
    final byIcon = {
      for (final c in result.clusters) c.representative.icon: c,
    };
    expect(byIcon[_red]!.count, 3);
    expect(byIcon[_blue]!.count, 2);
    // O representante é um ponto real do grupo, com o ícone do grupo.
    expect(byIcon[_red]!.representative.markerId.value, 'r2');
  });

  test('abre todos os pontos a partir do zoom máximo de agrupamento', () {
    final result = clusterer.cluster(markers, zoom: 15);

    expect(result.clusters, isEmpty);
    expect(result.singles, hasLength(3));
  });

  test('recorta pela área visível', () {
    final saoPaulo = LatLngBounds(
      southwest: const LatLng(-24, -47),
      northeast: const LatLng(-23, -46),
    );

    final result = clusterer.cluster(markers, zoom: 16, bounds: saoPaulo);

    expect(
      result.singles.map((m) => m.markerId.value),
      unorderedEquals(['a', 'b']),
    );
  });

  test('expand aumenta a área e trata o antimeridiano', () {
    final bounds = LatLngBounds(
      southwest: const LatLng(-10, 170),
      northeast: const LatLng(10, -170),
    );
    final expanded = RoteiroMarkerClusterer.expand(bounds, 0.25);

    expect(
      RoteiroMarkerClusterer.contains(expanded, const LatLng(0, 179)),
      isTrue,
    );
    expect(
      RoteiroMarkerClusterer.contains(expanded, const LatLng(0, -166)),
      isTrue,
    );
    expect(
      RoteiroMarkerClusterer.contains(expanded, const LatLng(0, 0)),
      isFalse,
    );
  });
}
