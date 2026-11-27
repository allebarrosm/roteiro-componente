import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:mobx/mobx.dart';

import 'roteiro_marker_clusterer.dart';
import 'roteiro_street_view_service.dart';

part 'roteiro_map_controller.g.dart';

/// Estado do mapa: câmera, marcadores visíveis (recorte por área + grupos), tipo de mapa e
/// Street View.
///
/// É separado do store de dados: o mapa não sabe de onde os clientes vieram.
class RoteiroMapController = RoteiroMapControllerBase
    with _$RoteiroMapController;

abstract class RoteiroMapControllerBase with Store {
  RoteiroMapControllerBase({
    RoteiroStreetViewService? streetViewService,
    void Function(String message)? onError,
    double initialZoom = 5,
    this.clusterer = const RoteiroMarkerClusterer(),
    this.viewportMargin = 0.25,
  })  : streetViewService =
            streetViewService ?? const AlwaysAvailableStreetViewService(),
        onError = onError ?? ((message) => debugPrint('[roteiro] $message')),
        zoomMap = initialZoom;

  final RoteiroStreetViewService streetViewService;
  final void Function(String message) onError;

  /// Regras de agrupamento (tamanho da célula, zoom em que tudo abre).
  final RoteiroMarkerClusterer clusterer;

  /// Fração da tela somada em cada lado da área visível ao recortar pontos.
  final double viewportMargin;

  LatLngBounds? _visibleBounds;
  Set<String> _individualKeys = <String>{};
  int _updateRequest = 0;

  @observable
  String? mapStyle;

  @observable
  bool isNormalType = true;

  @observable
  bool isStreetView = false;

  @observable
  LatLng? streetView;

  @observable
  double? lastZoom;

  @observable
  bool isStart = true;

  @observable
  double zoomMap;

  @observable
  bool clustering = true;

  @observable
  bool showCustomItem = false;

  @observable
  Set<Marker> markers = <Marker>{};

  @observable
  Set<Marker> visibleMarkers = <Marker>{};

  @observable
  LatLng? adjustedLocation;

  @observable
  double? adjustedZoom;

  final Completer<GoogleMapController> _controllerCompleter =
      Completer<GoogleMapController>();

  GoogleMapController? _mapController;
  bool _disposed = false;

  GoogleMapController? get mapController => _mapController;

  Future<GoogleMapController> get controller => _controllerCompleter.future;

  void attach(GoogleMapController controller) {
    _mapController = controller;
    if (!_controllerCompleter.isCompleted) {
      _controllerCompleter.complete(controller);
    }
  }

  void setMapStyle(String? value) => mapStyle = value;

  void setNormalType(bool value) => isNormalType = value;

  void toggleMapType() => isNormalType = !isNormalType;

  void setStart(bool value) => isStart = value;

  void setShowCustomItem(bool value) => showCustomItem = value;

  void setClustering(bool value) {
    clustering = value;
    if (value) {
      updatedMarkers();
    } else {
      _updateRequest++;
      visibleMarkers = Set<Marker>.of(markers);
    }
  }

  void setMarkers(Iterable<Marker> value, {bool? clustering}) {
    markers = Set<Marker>.of(value);
    if (clustering != null) this.clustering = clustering;
    if (this.clustering) {
      updatedMarkers();
    } else {
      _updateRequest++;
      visibleMarkers = Set<Marker>.of(markers);
    }
  }

  /// Recalcula o que vai para o mapa: só os pontos da área visível (mais
  /// [viewportMargin]) e, abaixo de [RoteiroMarkerClusterer.maxClusterZoom],
  /// pontos próximos agrupados num marcador com contador.
  ///
  /// Roda quando a câmera para (`onCameraIdle`) e quando os marcadores mudam,
  /// nunca a cada quadro do gesto.
  Future<void> updatedMarkers() async {
    final request = ++_updateRequest;

    if (markers.isEmpty) {
      _individualKeys = <String>{};
      visibleMarkers = <Marker>{};
      return;
    }

    final result = clusterer.cluster(
      markers,
      zoom: lastZoom ?? zoomMap,
      bounds: _visibleBounds,
    );

    // O grupo usa um cliente real como marcador (mesmo ícone, sem contador);
    // o toque aproxima o mapa até abrir o grupo.
    final clusterMarkers = result.clusters.map(
      (cluster) => cluster.representative.copyWith(
        consumeTapEventsParam: true,
        onTapParam: () => zoomToCluster(cluster),
      ),
    );

    if (request != _updateRequest || _disposed || !clustering) return;

    _individualKeys = {
      for (final marker in result.singles) _keyOf(marker.position),
    };
    visibleMarkers = <Marker>{...result.singles, ...clusterMarkers};
  }

  /// `true` quando há um marcador individual (não agrupado) nesse ponto.
  /// Usado para mostrar títulos flutuantes só dos pontos abertos.
  bool isIndividualAt(double latitude, double longitude) =>
      _individualKeys.contains(_keyOfRaw(latitude, longitude));

  static String _keyOf(LatLng p) => _keyOfRaw(p.latitude, p.longitude);

  static String _keyOfRaw(double lat, double lng) =>
      '${lat.toStringAsFixed(6)},${lng.toStringAsFixed(6)}';

  void onCameraMove(CameraPosition position) {
    lastZoom = position.zoom;
  }

  /// A câmera parou: lê a área visível e recarrega os pontos dela.
  Future<void> onCameraIdle() async {
    if (!clustering || _disposed) return;
    final controller = _mapController;
    if (controller != null) {
      try {
        final region = await controller.getVisibleRegion();
        final degenerate =
            region.southwest.latitude == region.northeast.latitude &&
                region.southwest.longitude == region.northeast.longitude;
        _visibleBounds = degenerate
            ? null
            : RoteiroMarkerClusterer.expand(region, viewportMargin);
      } catch (_) {
        _visibleBounds = null;
      }
    }
    if (_disposed) return;
    await updatedMarkers();
  }

  /// Aproxima o mapa até "abrir" o grupo tocado.
  Future<void> zoomToCluster(RoteiroCluster cluster) async {
    final controller = _mapController;
    if (controller == null || _disposed) return;
    final bounds = cluster.bounds;
    final samePoint = bounds.southwest == bounds.northeast;
    try {
      await controller.animateCamera(
        samePoint
            ? CameraUpdate.newLatLngZoom(
                cluster.position,
                clusterer.maxClusterZoom,
              )
            : CameraUpdate.newLatLngBounds(bounds, 60),
      );
    } catch (error) {
      onError('Não foi possível abrir o grupo: $error');
    }
  }

  Future<void> zoomToFit({double padding = 50}) async {
    final controller = _mapController;
    if (controller == null || markers.isEmpty || _disposed) return;

    final bounds = _boundsOf(markers);
    if (bounds == null) return;

    try {
      await controller.animateCamera(
        CameraUpdate.newLatLngBounds(bounds, padding),
      );
    } catch (error) {
      onError('Não foi possível enquadrar os marcadores: $error');
    }
  }

  Future<void> focusOn(LatLng target, {double zoom = 16}) async {
    adjustedLocation = target;
    adjustedZoom = zoom;
    await animateToAdjusted();
  }

  Future<void> animateToAdjusted() async {
    final target = adjustedLocation;
    final controller = _mapController;
    if (target == null || controller == null || _disposed) return;

    try {
      await controller.animateCamera(
        CameraUpdate.newLatLngZoom(target, adjustedZoom ?? 16),
      );
    } catch (error) {
      onError('Não foi possível mover o mapa: $error');
    }
  }

  Future<void> openStreetView(LatLng coordinate) async {
    if (isStreetView) {
      closeStreetView();
      return;
    }

    final result = await streetViewService.verify(coordinate);
    if (!result.available) {
      onError('Street View indisponível para este ponto.');
      return;
    }

    streetView = result.coordinate ?? coordinate;
    isStreetView = true;
  }

  void closeStreetView() {
    isStreetView = false;
    streetView = null;
  }

  LatLngBounds? _boundsOf(Set<Marker> markers) {
    var minLat = double.infinity;
    var maxLat = -double.infinity;
    var minLng = double.infinity;
    var maxLng = -double.infinity;

    for (final marker in markers) {
      final lat = marker.position.latitude;
      final lng = marker.position.longitude;
      if (lat < minLat) minLat = lat;
      if (lat > maxLat) maxLat = lat;
      if (lng < minLng) minLng = lng;
      if (lng > maxLng) maxLng = lng;
    }

    if (!minLat.isFinite || !maxLat.isFinite) return null;

    if (minLat == maxLat && minLng == maxLng) {
      minLat -= 0.001;
      maxLat += 0.001;
      minLng -= 0.001;
      maxLng += 0.001;
    }

    return LatLngBounds(
      southwest: LatLng(minLat, minLng),
      northeast: LatLng(maxLat, maxLng),
    );
  }

  void dispose() {
    _disposed = true;
  }
}
