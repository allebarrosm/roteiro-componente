// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'roteiro_map_controller.dart';

// **************************************************************************
// StoreGenerator
// **************************************************************************

// ignore_for_file: non_constant_identifier_names, unnecessary_brace_in_string_interps, unnecessary_lambdas, prefer_expression_function_bodies, lines_longer_than_80_chars, avoid_as, avoid_annotating_with_dynamic, no_leading_underscores_for_local_identifiers

mixin _$RoteiroMapController on RoteiroMapControllerBase, Store {
  late final _$mapStyleAtom =
      Atom(name: 'RoteiroMapControllerBase.mapStyle', context: context);

  @override
  String? get mapStyle {
    _$mapStyleAtom.reportRead();
    return super.mapStyle;
  }

  @override
  set mapStyle(String? value) {
    _$mapStyleAtom.reportWrite(value, super.mapStyle, () {
      super.mapStyle = value;
    });
  }

  late final _$isNormalTypeAtom =
      Atom(name: 'RoteiroMapControllerBase.isNormalType', context: context);

  @override
  bool get isNormalType {
    _$isNormalTypeAtom.reportRead();
    return super.isNormalType;
  }

  @override
  set isNormalType(bool value) {
    _$isNormalTypeAtom.reportWrite(value, super.isNormalType, () {
      super.isNormalType = value;
    });
  }

  late final _$isStreetViewAtom =
      Atom(name: 'RoteiroMapControllerBase.isStreetView', context: context);

  @override
  bool get isStreetView {
    _$isStreetViewAtom.reportRead();
    return super.isStreetView;
  }

  @override
  set isStreetView(bool value) {
    _$isStreetViewAtom.reportWrite(value, super.isStreetView, () {
      super.isStreetView = value;
    });
  }

  late final _$streetViewAtom =
      Atom(name: 'RoteiroMapControllerBase.streetView', context: context);

  @override
  LatLng? get streetView {
    _$streetViewAtom.reportRead();
    return super.streetView;
  }

  @override
  set streetView(LatLng? value) {
    _$streetViewAtom.reportWrite(value, super.streetView, () {
      super.streetView = value;
    });
  }

  late final _$lastZoomAtom =
      Atom(name: 'RoteiroMapControllerBase.lastZoom', context: context);

  @override
  double? get lastZoom {
    _$lastZoomAtom.reportRead();
    return super.lastZoom;
  }

  @override
  set lastZoom(double? value) {
    _$lastZoomAtom.reportWrite(value, super.lastZoom, () {
      super.lastZoom = value;
    });
  }

  late final _$isStartAtom =
      Atom(name: 'RoteiroMapControllerBase.isStart', context: context);

  @override
  bool get isStart {
    _$isStartAtom.reportRead();
    return super.isStart;
  }

  @override
  set isStart(bool value) {
    _$isStartAtom.reportWrite(value, super.isStart, () {
      super.isStart = value;
    });
  }

  late final _$zoomMapAtom =
      Atom(name: 'RoteiroMapControllerBase.zoomMap', context: context);

  @override
  double get zoomMap {
    _$zoomMapAtom.reportRead();
    return super.zoomMap;
  }

  @override
  set zoomMap(double value) {
    _$zoomMapAtom.reportWrite(value, super.zoomMap, () {
      super.zoomMap = value;
    });
  }

  late final _$clusteringAtom =
      Atom(name: 'RoteiroMapControllerBase.clustering', context: context);

  @override
  bool get clustering {
    _$clusteringAtom.reportRead();
    return super.clustering;
  }

  @override
  set clustering(bool value) {
    _$clusteringAtom.reportWrite(value, super.clustering, () {
      super.clustering = value;
    });
  }

  late final _$showCustomItemAtom =
      Atom(name: 'RoteiroMapControllerBase.showCustomItem', context: context);

  @override
  bool get showCustomItem {
    _$showCustomItemAtom.reportRead();
    return super.showCustomItem;
  }

  @override
  set showCustomItem(bool value) {
    _$showCustomItemAtom.reportWrite(value, super.showCustomItem, () {
      super.showCustomItem = value;
    });
  }

  late final _$markersAtom =
      Atom(name: 'RoteiroMapControllerBase.markers', context: context);

  @override
  Set<Marker> get markers {
    _$markersAtom.reportRead();
    return super.markers;
  }

  @override
  set markers(Set<Marker> value) {
    _$markersAtom.reportWrite(value, super.markers, () {
      super.markers = value;
    });
  }

  late final _$visibleMarkersAtom =
      Atom(name: 'RoteiroMapControllerBase.visibleMarkers', context: context);

  @override
  Set<Marker> get visibleMarkers {
    _$visibleMarkersAtom.reportRead();
    return super.visibleMarkers;
  }

  @override
  set visibleMarkers(Set<Marker> value) {
    _$visibleMarkersAtom.reportWrite(value, super.visibleMarkers, () {
      super.visibleMarkers = value;
    });
  }

  late final _$adjustedLocationAtom =
      Atom(name: 'RoteiroMapControllerBase.adjustedLocation', context: context);

  @override
  LatLng? get adjustedLocation {
    _$adjustedLocationAtom.reportRead();
    return super.adjustedLocation;
  }

  @override
  set adjustedLocation(LatLng? value) {
    _$adjustedLocationAtom.reportWrite(value, super.adjustedLocation, () {
      super.adjustedLocation = value;
    });
  }

  late final _$adjustedZoomAtom =
      Atom(name: 'RoteiroMapControllerBase.adjustedZoom', context: context);

  @override
  double? get adjustedZoom {
    _$adjustedZoomAtom.reportRead();
    return super.adjustedZoom;
  }

  @override
  set adjustedZoom(double? value) {
    _$adjustedZoomAtom.reportWrite(value, super.adjustedZoom, () {
      super.adjustedZoom = value;
    });
  }

  @override
  String toString() {
    return '''
mapStyle: ${mapStyle},
isNormalType: ${isNormalType},
isStreetView: ${isStreetView},
streetView: ${streetView},
lastZoom: ${lastZoom},
isStart: ${isStart},
zoomMap: ${zoomMap},
clustering: ${clustering},
showCustomItem: ${showCustomItem},
markers: ${markers},
visibleMarkers: ${visibleMarkers},
adjustedLocation: ${adjustedLocation},
adjustedZoom: ${adjustedZoom}
    ''';
  }
}
