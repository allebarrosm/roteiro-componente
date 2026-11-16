import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:mobx/mobx.dart';

import 'roteiro_street_view_service.dart';

part 'roteiro_map_controller.g.dart';

/// Estado do mapa: câmera, marcadores visíveis (clustering), tipo de mapa e
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
  })  : streetViewService =
            streetViewService ?? const AlwaysAvailableStreetViewService(),
        onError = onError ?? ((message) => debugPrint('[roteiro] $message')),
        zoomMap = initialZoom;

  final RoteiroStreetViewService streetViewService;
  final void Function(String message) onError;

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
      visibleMarkers = Set<Marker>.of(markers);
    }
  }

  void setMarkers(Iterable<Marker> value, {bool? clustering}) {
    markers = Set<Marker>.of(value);
    if (clustering != null) this.clustering = clustering;
    if (this.clustering) {
      updatedMarkers();
    } else {
      visibleMarkers = Set<Marker>.of(markers);
    }
  }

  /// Cluster simples por zoom (o mesmo "skip" usado hoje no EASYMART).
  ///
  /// Mantido no pacote para paridade Android/Web; um cluster nativo pode
  /// substituir isso no futuro sem mudar a API do widget.
  void updatedMarkers() {
    if (markers.isEmpty) {
      visibleMarkers = <Marker>{};
      return;
    }

    final skip = _markersToSkip(lastZoom ?? 17, markers.length);
    if (skip <= 0) {
      visibleMarkers = Set<Marker>.of(markers);
      return;
    }

    final list = markers.toList(growable: false);
    final visible = <Marker>{};
    for (var index = 0; index < list.length; index += skip) {
      visible.add(list[index]);
    }
    visible.add(list.last);
    visibleMarkers = visible;
  }

  int _markersToSkip(double zoom, int total) {
    final double ratio;
    if (zoom >= 16) {
      return 0;
    } else if (zoom >= 14) {
      ratio = 0.005;
    } else if (zoom >= 12) {
      ratio = 0.007;
    } else if (zoom >= 10) {
      ratio = 0.02;
    } else if (zoom >= 8) {
      ratio = 0.08;
    } else if (zoom >= 6) {
      ratio = 0.09;
    } else if (zoom >= 5) {
      ratio = 0.1;
    } else {
      ratio = 0.2;
    }
    return (total * ratio).toInt();
  }

  void onCameraMove(CameraPosition position) {
    final zoomChanged =
        lastZoom == null || (lastZoom! - position.zoom).abs() > 0.01;
    lastZoom = position.zoom;
    if (clustering && zoomChanged) {
      updatedMarkers();
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
