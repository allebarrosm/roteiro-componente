import 'package:flutter/widgets.dart';

/// Coordenada + ação de fechar para o Street View.
class RoteiroStreetViewRequest {
  const RoteiroStreetViewRequest({
    required this.latitude,
    required this.longitude,
    required this.onClose,
  });

  final double latitude;
  final double longitude;
  final VoidCallback onClose;
}

/// Permite que cada app injete a implementação nativa (ou outra) de Street
/// View sem que o pacote dependa de um plugin específico.
typedef RoteiroStreetViewBuilder = Widget Function(
  BuildContext context,
  RoteiroStreetViewRequest request,
);
