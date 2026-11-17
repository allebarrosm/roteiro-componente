import 'dart:js_interop';
import 'dart:js_interop_unsafe';
import 'dart:ui_web' as ui_web;

import 'package:flutter/material.dart';
import 'package:web/web.dart' as web;

import '../map/roteiro_street_view_request.dart';

/// Panorama do Google Maps no Web.
///
/// O mapa do componente já carrega a Maps JavaScript API, então usamos o
/// mesmo `google.maps.StreetViewPanorama` em vez de abrir uma nova aba.
@JS('google.maps.StreetViewPanorama')
extension type _StreetViewPanorama._(JSObject _) implements JSObject {
  external _StreetViewPanorama(JSObject container, JSObject options);

  external void setPosition(JSObject position);
  external void setPov(JSObject pov);
  external void setVisible(bool visible);
}

Widget buildStreetView(
  BuildContext context,
  RoteiroStreetViewRequest request,
) =>
    _WebStreetView(request: request);

class _WebStreetView extends StatefulWidget {
  const _WebStreetView({required this.request});

  final RoteiroStreetViewRequest request;

  @override
  State<_WebStreetView> createState() => _WebStreetViewState();
}

class _WebStreetViewState extends State<_WebStreetView> {
  late final String _viewType;
  _StreetViewPanorama? _panorama;
  bool _loading = true;
  bool _failed = false;
  bool _disposed = false;

  @override
  void initState() {
    super.initState();
    _viewType = 'roteiro-street-view-${DateTime.now().microsecondsSinceEpoch}';

    ui_web.platformViewRegistry.registerViewFactory(_viewType, (int viewId) {
      final div = web.document.createElement('div') as web.HTMLDivElement;
      div.style
        ..width = '100%'
        ..height = '100%'
        ..position = 'absolute'
        ..top = '0'
        ..left = '0';

      if (!_disposed) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!_disposed) _createPanorama(div);
        });
      }
      return div;
    });
  }

  Future<void> _createPanorama(web.HTMLDivElement div) async {
    final options = _panoramaOptions(widget.request);

    // A Maps JS API pode ter acabado de ser carregada pelo mapa; tenta por
    // alguns segundos antes de mostrar o fallback.
    for (var attempt = 0; attempt < 20; attempt++) {
      if (_disposed) return;
      try {
        final panorama = _StreetViewPanorama(div, options);
        _panorama = panorama;
        if (!_disposed && mounted) {
          setState(() => _loading = false);
        }
        return;
      } catch (_) {
        await Future<void>.delayed(const Duration(milliseconds: 150));
      }
    }

    if (!_disposed && mounted) {
      setState(() {
        _loading = false;
        _failed = true;
      });
    }
  }

  JSObject _panoramaOptions(RoteiroStreetViewRequest request) {
    final position = JSObject();
    position.setProperty('lat'.toJS, request.latitude.toJS);
    position.setProperty('lng'.toJS, request.longitude.toJS);

    final pov = JSObject();
    pov.setProperty('heading'.toJS, 0.toJS);
    pov.setProperty('pitch'.toJS, 0.toJS);

    final options = JSObject();
    options.setProperty('position'.toJS, position);
    options.setProperty('pov'.toJS, pov);
    options.setProperty('zoom'.toJS, 1.toJS);
    options.setProperty('visible'.toJS, true.toJS);
    options.setProperty('disableDefaultUI'.toJS, false.toJS);
    options.setProperty('fullscreenControl'.toJS, true.toJS);
    options.setProperty('addressControl'.toJS, true.toJS);
    options.setProperty('linksControl'.toJS, true.toJS);
    options.setProperty('panControl'.toJS, true.toJS);
    options.setProperty('zoomControl'.toJS, true.toJS);
    options.setProperty('motionTracking'.toJS, false.toJS);
    return options;
  }

  @override
  void didUpdateWidget(covariant _WebStreetView oldWidget) {
    super.didUpdateWidget(oldWidget);

    final panorama = _panorama;
    if (panorama == null) return;

    if (oldWidget.request.latitude != widget.request.latitude ||
        oldWidget.request.longitude != widget.request.longitude) {
      final position = JSObject();
      position.setProperty('lat'.toJS, widget.request.latitude.toJS);
      position.setProperty('lng'.toJS, widget.request.longitude.toJS);
      panorama.setPosition(position);
    }
  }

  @override
  void dispose() {
    _disposed = true;
    try {
      _panorama?.setVisible(false);
    } catch (_) {
      // A API pode já ter sido removida com a view.
    }
    _panorama = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_failed) {
      return _WebStreetViewFallback(request: widget.request);
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        HtmlElementView(viewType: _viewType),
        if (_loading)
          const ColoredBox(
            color: Color(0xCC000000),
            child: Center(child: CircularProgressIndicator()),
          ),
      ],
    );
  }
}

class _WebStreetViewFallback extends StatelessWidget {
  const _WebStreetViewFallback({required this.request});

  final RoteiroStreetViewRequest request;

  void _openGoogleMaps() {
    final url = Uri.https(
      'www.google.com',
      '/maps/@',
      <String, String>{
        'api': '1',
        'map_action': 'pano',
        'viewpoint': '${request.latitude},${request.longitude}',
      },
    ).toString();

    web.window.open(url, '_blank');
  }

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: const Color(0xFF111827),
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.streetview_outlined,
                size: 56,
                color: Colors.white70,
              ),
              const SizedBox(height: 12),
              const Text(
                'Street View',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Não foi possível carregar o panorama agora. '
                'Você pode abrir o ponto no Google Maps.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 16),
              FilledButton.tonalIcon(
                onPressed: _openGoogleMaps,
                icon: const Icon(Icons.open_in_new),
                label: const Text('Abrir no Google Maps'),
              ),
              const SizedBox(height: 12),
              Text(
                '${request.latitude.toStringAsFixed(5)}, '
                '${request.longitude.toStringAsFixed(5)}',
                style: const TextStyle(color: Colors.white38, fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
