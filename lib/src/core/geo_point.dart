/// Ponto geográfico puro (sem dependência de Flutter ou do plugin de mapa).
///
/// A normalização replica a correção que já existe nos apps: alguns cadastros
/// gravam a coordenada sem o separador decimal na posição correta
/// (ex.: `-235489337.0`), o que jogaria o marcador para fora do mapa.
class GeoPoint {
  const GeoPoint(this.latitude, this.longitude);

  final double latitude;
  final double longitude;

  /// Cria um ponto válido a partir de valores possivelmente sujos.
  ///
  /// Retorna `null` quando falta coordenada, quando o valor não é finito ou
  /// quando o ponto é `(0, 0)` — o mesmo critério de `temCoordenadaValida`
  /// usado no EASYMART.
  static GeoPoint? fromNullable(double? latitude, double? longitude) {
    final lat = _normalize(latitude, 90);
    final lon = _normalize(longitude, 180);
    if (lat == null || lon == null) return null;
    if (lat == 0 && lon == 0) return null;
    return GeoPoint(lat, lon);
  }

  static double? _normalize(double? value, double maxAbs) {
    if (value == null || !value.isFinite) return null;

    var normalized = value;
    var guard = 0;
    while (normalized.abs() > maxAbs && guard < 15) {
      normalized /= 10;
      guard++;
    }

    if (normalized.abs() > maxAbs) return null;
    return normalized;
  }

  bool get isZero => latitude == 0 && longitude == 0;

  @override
  bool operator ==(Object other) =>
      other is GeoPoint &&
      other.latitude == latitude &&
      other.longitude == longitude;

  @override
  int get hashCode => Object.hash(latitude, longitude);

  @override
  String toString() => 'GeoPoint($latitude, $longitude)';
}
