import 'package:flutter_floating_map_marker_titles_core/model/floating_marker_title_info.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:mobx/mobx.dart';

import '../../core/osrm_route_service.dart';
import '../../core/periodicity.dart';
import '../../core/roteiro_client.dart';
import '../../core/roteiro_filter.dart';
import '../../core/roteiro_visit_change.dart';
import '../../core/route_planner.dart';
import '../../core/route_service.dart';
import '../../core/visity_day.dart';
import '../theme/visity_day_ui.dart';
import 'roteiro_marker_factory.dart';
import 'roteiro_title_factory.dart';

part 'roteiro_store.g.dart';

/// Store de apresentação do Roteiro.
///
/// Recebe a lista já carregada (do SQLite no EASYMART ou da API no
/// Gestão/BackOffice) e produz marcadores, títulos e polylines. O acesso a
/// dados fica no app, atrás de um repositório — este store não faz I/O de
/// negócio, só o cálculo da rota no OSRM.
class RoteiroStore = RoteiroStoreBase with _$RoteiroStore;

abstract class RoteiroStoreBase with Store {
  RoteiroStoreBase({
    RoteiroMarkerFactory? markerFactory,
    RoteiroTitleFactory? titleFactory,
    RouteService? routeService,
    RoutePlanner? routePlanner,
    this.editableVisits = false,
    this.onSaveVisit,
  })  : markerFactory = markerFactory ?? RoteiroMarkerFactory(),
        titleFactory = titleFactory ?? const RoteiroTitleFactory(),
        routePlanner =
            routePlanner ?? RoutePlanner(routeService ?? OsrmRouteService());

  final RoteiroMarkerFactory markerFactory;
  final RoteiroTitleFactory titleFactory;
  final RoutePlanner routePlanner;

  /// Habilita a edição de pontos do roteiro (dia/frequência/ordem/data).
  ///
  /// Desligado por padrão: EASYMART e outras telas somente-leitura não devem
  /// exibir a ação de editar.
  final bool editableVisits;

  /// Persiste a alteração no backend/SQLite do app.
  ///
  /// Se for nulo, a edição é apenas local (útil para demo/teste).
  final Future<void> Function(RoteiroVisitChange change)? onSaveVisit;

  @observable
  ObservableList<RoteiroClient> clients = ObservableList<RoteiroClient>();

  @observable
  ObservableList<RoteiroClient> visibleClients =
      ObservableList<RoteiroClient>();

  @observable
  Set<Marker> markers = <Marker>{};

  @observable
  Set<Polyline> polylines = <Polyline>{};

  @observable
  ObservableList<FloatingMarkerTitleInfo> titles =
      ObservableList<FloatingMarkerTitleInfo>();

  @observable
  RoteiroClient? selected;

  @observable
  bool showClients = true;

  @observable
  bool showSequence = true;

  @observable
  bool showRoute = true;

  @observable
  RoteiroFilter filter = RoteiroFilter.empty;

  @observable
  bool isLoading = false;

  @observable
  String? errorMessage;

  int _requestId = 0;

  Future<void> setClients(List<RoteiroClient> value) async {
    clients = ObservableList<RoteiroClient>.of(value);
    await applyFilters();
  }

  Future<void> applyFilters() async {
    final request = ++_requestId;
    isLoading = true;
    errorMessage = null;

    try {
      final visible = filter.apply(clients);

      final builtMarkers = await Future.wait(
        visible.map(
          (client) => markerFactory.build(
            client,
            onTap: () => select(client),
          ),
        ),
      );

      if (request != _requestId) return;

      visibleClients = ObservableList<RoteiroClient>.of(visible);
      markers = builtMarkers.whereType<Marker>().toSet();

      _refreshTitles();

      if (selected != null &&
          !visible.any((client) => client.personCode == selected!.personCode)) {
        selected = null;
      }

      await _rebuildPolylines(visible);
    } catch (error) {
      if (request == _requestId) {
        errorMessage = 'Falha ao montar o roteiro: $error';
      }
    } finally {
      if (request == _requestId) isLoading = false;
    }
  }

  Future<void> _rebuildPolylines(List<RoteiroClient> visible) async {
    if (!showRoute) {
      polylines = <Polyline>{};
      return;
    }

    final routes = await routePlanner.plan(visible);

    polylines = {
      for (final route in routes)
        Polyline(
          polylineId: PolylineId(
            '${route.day.name}-${route.firstWeek ? 'first' : 'second'}',
          ),
          points: [
            for (final point in route.points)
              LatLng(point.latitude, point.longitude),
          ],
          color: (route.firstWeek ? route.day.color2 : route.day.color)
              .withValues(alpha: 0.85),
          width: 3,
        ),
    };
  }

  void _refreshTitles() {
    titles = ObservableList<FloatingMarkerTitleInfo>.of(
      titleFactory.build(
        visibleClients,
        showSequence: showSequence,
        showName: showClients,
      ),
    );
  }

  void select(RoteiroClient client) => selected = client;

  void clearSelection() => selected = null;

  /// Persiste e aplica a edição de um ponto do roteiro.
  ///
  /// Retorna `false` quando a edição está desabilitada, o change é inválido,
  /// o cliente não existe ou o `onSaveVisit` lança.
  Future<bool> saveVisit(RoteiroVisitChange change) async {
    if (!editableVisits || !change.isValid) return false;

    final index = clients.indexWhere(
      (client) => client.personCode == change.client.personCode,
    );
    if (index < 0) return false;

    try {
      await onSaveVisit?.call(change);
    } catch (error) {
      errorMessage = 'Falha ao salvar a visita: $error';
      return false;
    }

    final updated = change.apply();

    final next = List<RoteiroClient>.of(clients);
    next[index] = updated;
    clients = ObservableList<RoteiroClient>.of(next);

    if (selected?.personCode == updated.personCode) {
      selected = updated;
    }

    await applyFilters();
    return true;
  }

  Future<void> setFilter(RoteiroFilter value) {
    filter = value;
    return applyFilters();
  }

  Future<void> toggleDay(VisityDay day) {
    final days = Set<VisityDay>.of(filter.days);
    if (!days.remove(day)) days.add(day);
    return setFilter(filter.copyWith(days: days));
  }

  Future<void> togglePeriodicity(PeriodicityFilter periodicity) {
    final values = Set<PeriodicityFilter>.of(filter.periodicities);
    if (!values.remove(periodicity)) values.add(periodicity);
    return setFilter(filter.copyWith(periodicities: values));
  }

  Future<void> setNoScheduling(bool value) {
    return setFilter(filter.copyWith(noScheduling: value));
  }

  Future<void> clearFilters() {
    return setFilter(RoteiroFilter.empty);
  }

  void setShowClients(bool value) {
    showClients = value;
    _refreshTitles();
  }

  void setShowSequence(bool value) {
    showSequence = value;
    _refreshTitles();
  }

  Future<void> setShowRoute(bool value) async {
    showRoute = value;
    if (!value) {
      polylines = <Polyline>{};
    } else {
      await _rebuildPolylines(visibleClients);
    }
  }
}
