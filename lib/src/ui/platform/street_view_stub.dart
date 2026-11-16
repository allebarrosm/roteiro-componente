import 'package:flutter/widgets.dart';

import '../map/roteiro_street_view_request.dart';
import 'street_view_placeholder.dart';

Widget buildStreetView(
  BuildContext context,
  RoteiroStreetViewRequest request,
) =>
    RoteiroStreetViewPlaceholder(request: request);
