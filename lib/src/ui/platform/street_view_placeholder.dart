import 'package:flutter/material.dart';

import '../map/roteiro_street_view_request.dart';

/// Fallback exibido quando não há builder nativo injetado.
class RoteiroStreetViewPlaceholder extends StatelessWidget {
  const RoteiroStreetViewPlaceholder({
    super.key,
    required this.request,
    this.message,
  });

  final RoteiroStreetViewRequest request;
  final String? message;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: const Color(0xFF111827),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Center(
            child: Padding(
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
                  Text(
                    message ??
                        'Injete um RoteiroStreetViewBuilder no RoteiroMap '
                            'para exibir o plugin nativo (Android).',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white70),
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
          SafeArea(
            child: Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: IconButton(
                  onPressed: request.onClose,
                  icon: const Icon(Icons.close, color: Colors.white),
                  tooltip: 'Fechar Street View',
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
