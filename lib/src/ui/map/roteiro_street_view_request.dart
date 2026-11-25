import 'package:flutter/widgets.dart';

/// Coordenada + ação de fechar para o Street View.
class RoteiroStreetViewRequest {
  const RoteiroStreetViewRequest({
    required this.latitude,
    required this.longitude,
    required this.onClose,
    this.showControls = true,
  });

  final double latitude;
  final double longitude;
  final VoidCallback onClose;

  /// Mostra os controles/endereço do panorama do Google no Web.
  ///
  /// `false` deixa só a foto — usado nas miniaturas pequenas (150x100), onde a
  /// UI do Google cobre quase toda a imagem. O Street View em tela cheia
  /// continua usando `true`.
  final bool showControls;
}

/// Permite que cada app injete a implementação nativa (ou outra) de Street
/// View sem que o pacote dependa de um plugin específico.
typedef RoteiroStreetViewBuilder = Widget Function(
  BuildContext context,
  RoteiroStreetViewRequest request,
);
