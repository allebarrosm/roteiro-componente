import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_street_view/flutter_street_view.dart';

import '../map/roteiro_street_view_request.dart';
import 'street_view_placeholder.dart';

Widget buildStreetView(
  BuildContext context,
  RoteiroStreetViewRequest request,
) {
  if (defaultTargetPlatform != TargetPlatform.android) {
    return RoteiroStreetViewPlaceholder(
      request: request,
      message: 'Street View nativo disponível no Android.',
    );
  }

  // Mesmo widget/parâmetros do Gestão.
  return FlutterStreetView(
    latitude: request.latitude,
    longitude: request.longitude,
    zoom: -5,
    tilt: 10,
    bearing: 10,
  );
}
