import 'package:roteiro/roteiro.dart';

RoteiroClient client({
  required String code,
  String name = 'Cliente',
  VisityDay? day,
  Periodicity? periodicity,
  bool firstWeek = false,
  int visitOrder = 1,
  double? lat = -8.05,
  double? lon = -34.9,
  bool scheduled = true,
}) {
  return RoteiroClient(
    personCode: code,
    name: name,
    fantasy: name,
    cnpj: '00.000.000/0001-00',
    address: 'Rua de Teste, 100',
    day: day,
    periodicity: periodicity,
    firstWeek: firstWeek,
    visitOrder: visitOrder,
    lat: lat,
    lon: lon,
    scheduled: scheduled,
  );
}
