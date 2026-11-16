// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'roteiro_store.dart';

// **************************************************************************
// StoreGenerator
// **************************************************************************

// ignore_for_file: non_constant_identifier_names, unnecessary_brace_in_string_interps, unnecessary_lambdas, prefer_expression_function_bodies, lines_longer_than_80_chars, avoid_as, avoid_annotating_with_dynamic, no_leading_underscores_for_local_identifiers

mixin _$RoteiroStore on RoteiroStoreBase, Store {
  late final _$clientsAtom =
      Atom(name: 'RoteiroStoreBase.clients', context: context);

  @override
  ObservableList<RoteiroClient> get clients {
    _$clientsAtom.reportRead();
    return super.clients;
  }

  @override
  set clients(ObservableList<RoteiroClient> value) {
    _$clientsAtom.reportWrite(value, super.clients, () {
      super.clients = value;
    });
  }

  late final _$visibleClientsAtom =
      Atom(name: 'RoteiroStoreBase.visibleClients', context: context);

  @override
  ObservableList<RoteiroClient> get visibleClients {
    _$visibleClientsAtom.reportRead();
    return super.visibleClients;
  }

  @override
  set visibleClients(ObservableList<RoteiroClient> value) {
    _$visibleClientsAtom.reportWrite(value, super.visibleClients, () {
      super.visibleClients = value;
    });
  }

  late final _$markersAtom =
      Atom(name: 'RoteiroStoreBase.markers', context: context);

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

  late final _$polylinesAtom =
      Atom(name: 'RoteiroStoreBase.polylines', context: context);

  @override
  Set<Polyline> get polylines {
    _$polylinesAtom.reportRead();
    return super.polylines;
  }

  @override
  set polylines(Set<Polyline> value) {
    _$polylinesAtom.reportWrite(value, super.polylines, () {
      super.polylines = value;
    });
  }

  late final _$titlesAtom =
      Atom(name: 'RoteiroStoreBase.titles', context: context);

  @override
  ObservableList<FloatingMarkerTitleInfo> get titles {
    _$titlesAtom.reportRead();
    return super.titles;
  }

  @override
  set titles(ObservableList<FloatingMarkerTitleInfo> value) {
    _$titlesAtom.reportWrite(value, super.titles, () {
      super.titles = value;
    });
  }

  late final _$selectedAtom =
      Atom(name: 'RoteiroStoreBase.selected', context: context);

  @override
  RoteiroClient? get selected {
    _$selectedAtom.reportRead();
    return super.selected;
  }

  @override
  set selected(RoteiroClient? value) {
    _$selectedAtom.reportWrite(value, super.selected, () {
      super.selected = value;
    });
  }

  late final _$showClientsAtom =
      Atom(name: 'RoteiroStoreBase.showClients', context: context);

  @override
  bool get showClients {
    _$showClientsAtom.reportRead();
    return super.showClients;
  }

  @override
  set showClients(bool value) {
    _$showClientsAtom.reportWrite(value, super.showClients, () {
      super.showClients = value;
    });
  }

  late final _$showSequenceAtom =
      Atom(name: 'RoteiroStoreBase.showSequence', context: context);

  @override
  bool get showSequence {
    _$showSequenceAtom.reportRead();
    return super.showSequence;
  }

  @override
  set showSequence(bool value) {
    _$showSequenceAtom.reportWrite(value, super.showSequence, () {
      super.showSequence = value;
    });
  }

  late final _$showRouteAtom =
      Atom(name: 'RoteiroStoreBase.showRoute', context: context);

  @override
  bool get showRoute {
    _$showRouteAtom.reportRead();
    return super.showRoute;
  }

  @override
  set showRoute(bool value) {
    _$showRouteAtom.reportWrite(value, super.showRoute, () {
      super.showRoute = value;
    });
  }

  late final _$filterAtom =
      Atom(name: 'RoteiroStoreBase.filter', context: context);

  @override
  RoteiroFilter get filter {
    _$filterAtom.reportRead();
    return super.filter;
  }

  @override
  set filter(RoteiroFilter value) {
    _$filterAtom.reportWrite(value, super.filter, () {
      super.filter = value;
    });
  }

  late final _$isLoadingAtom =
      Atom(name: 'RoteiroStoreBase.isLoading', context: context);

  @override
  bool get isLoading {
    _$isLoadingAtom.reportRead();
    return super.isLoading;
  }

  @override
  set isLoading(bool value) {
    _$isLoadingAtom.reportWrite(value, super.isLoading, () {
      super.isLoading = value;
    });
  }

  late final _$errorMessageAtom =
      Atom(name: 'RoteiroStoreBase.errorMessage', context: context);

  @override
  String? get errorMessage {
    _$errorMessageAtom.reportRead();
    return super.errorMessage;
  }

  @override
  set errorMessage(String? value) {
    _$errorMessageAtom.reportWrite(value, super.errorMessage, () {
      super.errorMessage = value;
    });
  }

  @override
  String toString() {
    return '''
clients: ${clients},
visibleClients: ${visibleClients},
markers: ${markers},
polylines: ${polylines},
titles: ${titles},
selected: ${selected},
showClients: ${showClients},
showSequence: ${showSequence},
showRoute: ${showRoute},
filter: ${filter},
isLoading: ${isLoading},
errorMessage: ${errorMessage}
    ''';
  }
}
