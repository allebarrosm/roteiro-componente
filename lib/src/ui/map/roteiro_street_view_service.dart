import 'dart:convert';

import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;

/// Resultado da verificação de Street View.
///
/// Quando [available] é `true`, [coordinate] traz a coordenada retornada pela
/// API (o Google pode ajustar levemente o ponto para o panorama mais próximo).
class RoteiroStreetViewResult {
  const RoteiroStreetViewResult({
    required this.available,
    this.coordinate,
  });

  final bool available;
  final LatLng? coordinate;

  static const RoteiroStreetViewResult unavailable =
      RoteiroStreetViewResult(available: false);
}

/// Verifica se existe panorama para o ponto.
abstract interface class RoteiroStreetViewService {
  Future<RoteiroStreetViewResult> verify(LatLng coordinate);
}

/// Libera o botão sem consultar a API.
///
/// Útil quando o app ainda não tem a chave da Street View Metadata API; o
/// plugin nativo decide se exibe o panorama.
class AlwaysAvailableStreetViewService implements RoteiroStreetViewService {
  const AlwaysAvailableStreetViewService();

  @override
  Future<RoteiroStreetViewResult> verify(LatLng coordinate) async =>
      RoteiroStreetViewResult(available: true, coordinate: coordinate);
}

/// Verificação usada pelo Gestão e BackOffice:
/// `GET /maps/api/streetview/metadata?key=...&location=lat,lng`.
///
/// `status == OK` → disponível (usa `location.lat/lng`);
/// qualquer outro status (`ZERO_RESULTS`, `REQUEST_DENIED`, etc.) → indisponível.
class GoogleStreetViewService implements RoteiroStreetViewService {
  GoogleStreetViewService({
    required this.apiKey,
    http.Client? client,
    this.timeout = const Duration(seconds: 10),
  }) : _client = client ?? http.Client();

  final String apiKey;
  final Duration timeout;
  final http.Client _client;

  @override
  Future<RoteiroStreetViewResult> verify(LatLng coordinate) async {
    if (apiKey.trim().isEmpty) {
      return RoteiroStreetViewResult.unavailable;
    }

    try {
      final uri = Uri.https(
        'maps.googleapis.com',
        '/maps/api/streetview/metadata',
        <String, String>{
          'key': apiKey,
          'location': '${coordinate.latitude},${coordinate.longitude}',
        },
      );

      final response = await _client.get(uri).timeout(timeout);
      if (response.statusCode != 200) {
        return RoteiroStreetViewResult.unavailable;
      }

      final decoded = jsonDecode(response.body);
      if (decoded is! Map) {
        return RoteiroStreetViewResult.unavailable;
      }

      if (decoded['status'] != 'OK') {
        return RoteiroStreetViewResult.unavailable;
      }

      final location = decoded['location'];
      if (location is Map) {
        final lat = (location['lat'] as num?)?.toDouble();
        final lng = (location['lng'] as num?)?.toDouble();
        if (lat != null && lng != null) {
          return RoteiroStreetViewResult(
            available: true,
            coordinate: LatLng(lat, lng),
          );
        }
      }

      // A API respondeu OK mas sem location: mantém o ponto selecionado.
      return RoteiroStreetViewResult(
        available: true,
        coordinate: coordinate,
      );
    } catch (_) {
      return RoteiroStreetViewResult.unavailable;
    }
  }
}
