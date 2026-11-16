import 'package:flutter/widgets.dart';

import '../map/roteiro_street_view_request.dart';
import 'street_view_stub.dart'
    if (dart.library.js_interop) 'street_view_web.dart'
    if (dart.library.io) 'street_view_io.dart' as impl;

/// Builder padrão do Street View.
///
/// - Android: plugin nativo (`flutter_street_view`, fork do Gestão).
/// - Web: fallback com link para abrir o ponto no Google Maps (os apps também
///   não têm panorama nativo no Web).
/// - Demais plataformas: placeholder.
Widget buildDefaultStreetView(
  BuildContext context,
  RoteiroStreetViewRequest request,
) =>
    impl.buildStreetView(context, request);
