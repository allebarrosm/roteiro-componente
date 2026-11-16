import 'package:flutter/material.dart';
import 'package:web/web.dart' as web;

import '../map/roteiro_street_view_request.dart';

Widget buildStreetView(
  BuildContext context,
  RoteiroStreetViewRequest request,
) =>
    _WebStreetViewFallback(request: request);

/// No Web, nem o Gestão nem o BackOffice têm panorama nativo.
///
/// Mantemos a mesma limitação, mas com uma saída útil: abrir o ponto no
/// Google Maps (panorama).
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
                'O panorama nativo está disponível no app Android. '
                'No Web, abra o ponto no Google Maps.',
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
