import 'package:flutter/foundation.dart' show setEquals;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_floating_map_marker_titles_core/controller/fmto_controller.dart';
import 'package:flutter_floating_map_marker_titles_core/model/floating_marker_title_info.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_maps_flutter_floating_marker_titles/google_maps_flutter_floating_marker_titles.dart';

import '../platform/street_view.dart';
import '../widgets/roteiro_circle_button.dart';
import '../widgets/roteiro_info_window.dart';
import 'roteiro_map_button.dart';
import 'roteiro_map_controller.dart';
import 'roteiro_street_view_request.dart';

/// Mapa do Roteiro, compartilhado entre Android e Web.
///
/// O widget cuida só da camada de mapa: marcadores, polylines, títulos
/// flutuantes, câmera, tela cheia e Street View. A composição da página
/// (filtros, lista, grid) fica no app que consome o pacote.
class RoteiroMap extends StatefulWidget {
  const RoteiroMap({
    super.key,
    required this.controller,
    this.markers = const <Marker>{},
    this.polylines,
    this.titles = const <FloatingMarkerTitleInfo>[],
    this.initialTarget,
    this.initialZoom = 5,
    this.clustering = true,
    this.streetViewTarget,
    this.streetViewBuilder,
    this.infoWindow,
    this.onCloseInfoWindow,
    this.onEditInfoWindow,
    this.detailsCard,
    this.showDetailsCard = false,
    this.onCloseDetails,
    this.customButton,
    this.customButtonRight,
    this.customItem,
    this.onMapTap,
    this.showFullScreenButton = true,
    this.showMapTypeButton = true,
    this.showStreetViewButton = true,
    this.fullscreen = false,
  });

  final RoteiroMapController controller;
  final Set<Marker> markers;
  final Set<Polyline>? polylines;
  final List<FloatingMarkerTitleInfo> titles;
  final LatLng? initialTarget;
  final double initialZoom;
  final bool clustering;

  /// Coordenada do cliente selecionado; habilita o botão de Street View.
  final LatLng? streetViewTarget;

  /// Sobrescreve o Street View padrão (web) / placeholder (mobile).
  final RoteiroStreetViewBuilder? streetViewBuilder;

  final RoteiroInfoWindowData? infoWindow;
  final VoidCallback? onCloseInfoWindow;

  /// Mostra o botão de editar (lápis) no popup de detalhes do cliente.
  final VoidCallback? onEditInfoWindow;

  final Widget? detailsCard;
  final bool showDetailsCard;
  final VoidCallback? onCloseDetails;

  final RoteiroMapButton? customButton;
  final RoteiroMapButton? customButtonRight;
  final Widget? customItem;
  final ValueChanged<LatLng>? onMapTap;

  final bool showFullScreenButton;
  final bool showMapTypeButton;
  final bool showStreetViewButton;

  /// Usado internamente pelo diálogo de tela cheia.
  final bool fullscreen;

  @override
  State<RoteiroMap> createState() => _RoteiroMapState();
}

class _RoteiroMapState extends State<RoteiroMap> {
  bool _styleRequested = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      widget.controller.setMarkers(
        widget.markers,
        clustering: widget.clustering,
      );
    });
  }

  @override
  void didUpdateWidget(covariant RoteiroMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!setEquals(oldWidget.markers, widget.markers) ||
        oldWidget.clustering != widget.clustering) {
      widget.controller.setMarkers(
        widget.markers,
        clustering: widget.clustering,
      );
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_styleRequested) return;
    _styleRequested = true;

    rootBundle
        .loadString('packages/roteiro/assets/map_style.txt')
        .then((style) {
      if (!mounted) return;
      widget.controller.setMapStyle(style);
      // Mantido por compatibilidade com google_maps_flutter 2.14.
      // ignore: deprecated_member_use
      widget.controller.mapController?.setMapStyle(style).catchError((_) {});
    }).catchError((Object error) {
      debugPrint('[roteiro] map_style não carregado: $error');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Observer(
      builder: (context) {
        final controller = widget.controller;
        return Stack(
          fit: StackFit.expand,
          children: [
            if (controller.isStreetView)
              _buildStreetView(context)
            else
              _buildMap(),
            if (!controller.isStreetView) ..._buildOverlay(context),
          ],
        );
      },
    );
  }

  Widget _buildMap() {
    final controller = widget.controller;
    final target = widget.initialTarget ?? const LatLng(-13.8202, -53.3797);

    return GoogleMapWithFMTO(
      initialCameraPosition: CameraPosition(
        target: target,
        zoom: widget.initialZoom,
      ),
      mapType: controller.isNormalType ? MapType.normal : MapType.satellite,
      markers: controller.visibleMarkers,
      polylines: widget.polylines,
      floatingTitles: widget.titles,
      fmtoOptions: const FMTOOptions(textSize: 10),
      onMapCreated: _onMapCreated,
      onCameraMove: controller.onCameraMove,
      onTap: widget.onMapTap,
      zoomControlsEnabled: false,
      compassEnabled: false,
      mapToolbarEnabled: false,
      tiltGesturesEnabled: true,
      rotateGesturesEnabled: true,
      zoomGesturesEnabled: true,
      scrollGesturesEnabled: true,
    );
  }

  Future<void> _onMapCreated(GoogleMapController controller) async {
    widget.controller.attach(controller);

    final style = widget.controller.mapStyle;
    if (style != null && style.isNotEmpty) {
      try {
        // Mantido por compatibilidade com google_maps_flutter 2.14.
        // ignore: deprecated_member_use
        await controller.setMapStyle(style);
      } catch (error) {
        debugPrint('[roteiro] setMapStyle falhou: $error');
      }
    }

    if (widget.controller.adjustedLocation != null) {
      await widget.controller.animateToAdjusted();
    } else if (widget.controller.isStart) {
      widget.controller.setStart(false);
      await widget.controller.zoomToFit();
    }
  }

  List<Widget> _buildOverlay(BuildContext context) {
    final controller = widget.controller;
    final target = widget.streetViewTarget;

    return [
      if (widget.customButton != null)
        Positioned(
          top: 12,
          left: 12,
          child: SafeArea(
            bottom: false,
            child: RoteiroCircleButton(
              icon: widget.customButton!.icon,
              onTap: widget.customButton!.onTap,
              active: widget.customButton!.active,
              tooltip: widget.customButton!.tooltip,
            ),
          ),
        ),
      Positioned(
        top: 12,
        right: 12,
        child: SafeArea(
          bottom: false,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.showMapTypeButton)
                RoteiroCircleButton(
                  icon: controller.isNormalType
                      ? Icons.satellite_alt_outlined
                      : Icons.map_outlined,
                  tooltip: controller.isNormalType ? 'Satélite' : 'Mapa',
                  onTap: controller.toggleMapType,
                ),
              if (widget.showStreetViewButton && target != null)
                Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: RoteiroCircleButton(
                    icon: Icons.streetview_outlined,
                    tooltip: 'Street View',
                    onTap: () => controller.openStreetView(target),
                  ),
                ),
              if (widget.showFullScreenButton && !widget.fullscreen)
                Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: RoteiroCircleButton(
                    icon: Icons.fullscreen_outlined,
                    tooltip: 'Tela cheia',
                    onTap: _openFullscreen,
                  ),
                ),
              if (widget.customButtonRight != null)
                Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: RoteiroCircleButton(
                    icon: widget.customButtonRight!.icon,
                    onTap: widget.customButtonRight!.onTap,
                    active: widget.customButtonRight!.active,
                    tooltip: widget.customButtonRight!.tooltip,
                  ),
                ),
            ],
          ),
        ),
      ),
      if (widget.infoWindow != null)
        Positioned(
          top: 70,
          left: 12,
          child: SafeArea(
            top: false,
            child: RoteiroInfoWindow(
              data: widget.infoWindow!,
              onClose: widget.onCloseInfoWindow,
              onEdit: widget.onEditInfoWindow,
            ),
          ),
        ),
      if (widget.showDetailsCard && widget.detailsCard != null)
        Positioned(
          left: 12,
          right: 12,
          bottom: 12,
          child: SafeArea(
            top: false,
            child: Align(
              alignment: Alignment.bottomCenter,
              child: widget.detailsCard!,
            ),
          ),
        ),
      if (widget.customItem != null && controller.showCustomItem)
        Positioned.fill(child: widget.customItem!),
    ];
  }

  Widget _buildStreetView(BuildContext context) {
    final coordinate = widget.controller.streetView;
    if (coordinate == null) {
      return const ColoredBox(color: Colors.black);
    }

    final builder = widget.streetViewBuilder ?? buildDefaultStreetView;

    return Stack(
      fit: StackFit.expand,
      children: [
        builder(
          context,
          RoteiroStreetViewRequest(
            latitude: coordinate.latitude,
            longitude: coordinate.longitude,
            onClose: widget.controller.closeStreetView,
          ),
        ),
        SafeArea(
          child: Align(
            alignment: Alignment.topLeft,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: RoteiroCircleButton(
                icon: Icons.arrow_back,
                tooltip: 'Voltar ao mapa',
                onTap: widget.controller.closeStreetView,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _openFullscreen() async {
    final fullController = RoteiroMapController(
      streetViewService: widget.controller.streetViewService,
      onError: widget.controller.onError,
      initialZoom: widget.controller.lastZoom ?? widget.initialZoom,
    );

    await showGeneralDialog<void>(
      context: context,
      barrierDismissible: false,
      barrierLabel: 'Mapa em tela cheia',
      barrierColor: Colors.black,
      transitionDuration: const Duration(milliseconds: 180),
      pageBuilder: (dialogContext, animation, secondaryAnimation) {
        return Scaffold(
          backgroundColor: Colors.black,
          body: RoteiroMap(
            controller: fullController,
            markers: widget.markers,
            polylines: widget.polylines,
            titles: widget.titles,
            initialTarget:
                widget.controller.adjustedLocation ?? widget.initialTarget,
            initialZoom: widget.controller.lastZoom ?? widget.initialZoom,
            clustering: widget.clustering,
            streetViewTarget: widget.streetViewTarget,
            streetViewBuilder: widget.streetViewBuilder,
            infoWindow: widget.infoWindow,
            onCloseInfoWindow: widget.onCloseInfoWindow,
            onEditInfoWindow: widget.onEditInfoWindow,
            detailsCard: widget.detailsCard,
            showDetailsCard: widget.showDetailsCard,
            onCloseDetails: widget.onCloseDetails,
            customButton: widget.customButton,
            customButtonRight: widget.customButtonRight,
            customItem: widget.customItem,
            onMapTap: widget.onMapTap,
            showFullScreenButton: false,
            fullscreen: true,
          ),
        );
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(opacity: animation, child: child);
      },
    );

    fullController.dispose();
  }
}
