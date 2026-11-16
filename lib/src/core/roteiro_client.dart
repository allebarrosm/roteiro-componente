import 'geo_point.dart';
import 'periodicity.dart';
import 'visity_day.dart';

/// Modelo canônico de cliente do Roteiro.
///
/// Cada app converte seu modelo atual (`PlanoVisitaInfoComplement` no
/// EASYMART, `Scheduling` no Gestão/BackOffice) para este tipo, em um único
/// arquivo de mapeamento.
class RoteiroClient {
  const RoteiroClient({
    required this.personCode,
    required this.name,
    this.fantasy,
    this.cnpj = '',
    this.address = '',
    this.agentCode,
    this.supervisorCode,
    this.representativeName,
    this.municipality,
    this.dateBase,
    this.day,
    this.periodicity,
    this.firstWeek = false,
    this.visitOrder = 0,
    this.visitingTime,
    this.scheduled = true,
    this.lastPurchase,
    this.lat,
    this.lon,
  });

  final String personCode;
  final String name;
  final String? fantasy;
  final String cnpj;
  final String address;
  final String? agentCode;
  final String? supervisorCode;
  final String? representativeName;
  final String? municipality;
  final DateTime? dateBase;
  final VisityDay? day;
  final Periodicity? periodicity;

  /// `true` para a primeira quinzena/semana ímpar.
  final bool firstWeek;

  final int visitOrder;
  final String? visitingTime;
  final bool scheduled;
  final DateTime? lastPurchase;
  final double? lat;
  final double? lon;

  GeoPoint? get coordinate => GeoPoint.fromNullable(lat, lon);

  bool get hasCoordinate => coordinate != null;

  String get displayName {
    final value = fantasy?.trim();
    if (value != null && value.isNotEmpty) return value;
    return name;
  }

  /// Linhas exibidas no info window / card de detalhes.
  Map<String, String?> toView() => {
        'Cliente': name,
        'Nome fantasia': fantasy,
        'CNPJ': cnpj.isEmpty ? null : cnpj,
        'Endereço': address.isEmpty ? null : address,
        'Município': municipality,
        'Representante': representativeName,
        'Dia da visita': day?.title,
        'Periodicidade': periodicity?.label,
        'Quinzena': periodicity == Periodicity.fortnightly
            ? (firstWeek ? '1ª e 3ª' : '2ª e 4ª')
            : null,
        'Ordem de visita': visitOrder.toString(),
        'Data base': _formatDate(dateBase),
        'Última compra': _formatDate(lastPurchase),
      };

  static String? _formatDate(DateTime? value) {
    if (value == null) return null;
    final day = value.day.toString().padLeft(2, '0');
    final month = value.month.toString().padLeft(2, '0');
    return '$day/$month/${value.year}';
  }

  RoteiroClient copyWith({
    String? personCode,
    String? name,
    String? fantasy,
    String? cnpj,
    String? address,
    String? agentCode,
    String? supervisorCode,
    String? representativeName,
    String? municipality,
    DateTime? dateBase,
    VisityDay? day,
    Periodicity? periodicity,
    bool? firstWeek,
    int? visitOrder,
    String? visitingTime,
    bool? scheduled,
    DateTime? lastPurchase,
    double? lat,
    double? lon,
  }) {
    return RoteiroClient(
      personCode: personCode ?? this.personCode,
      name: name ?? this.name,
      fantasy: fantasy ?? this.fantasy,
      cnpj: cnpj ?? this.cnpj,
      address: address ?? this.address,
      agentCode: agentCode ?? this.agentCode,
      supervisorCode: supervisorCode ?? this.supervisorCode,
      representativeName: representativeName ?? this.representativeName,
      municipality: municipality ?? this.municipality,
      dateBase: dateBase ?? this.dateBase,
      day: day ?? this.day,
      periodicity: periodicity ?? this.periodicity,
      firstWeek: firstWeek ?? this.firstWeek,
      visitOrder: visitOrder ?? this.visitOrder,
      visitingTime: visitingTime ?? this.visitingTime,
      scheduled: scheduled ?? this.scheduled,
      lastPurchase: lastPurchase ?? this.lastPurchase,
      lat: lat ?? this.lat,
      lon: lon ?? this.lon,
    );
  }

  @override
  String toString() => 'RoteiroClient($personCode, $name)';
}
