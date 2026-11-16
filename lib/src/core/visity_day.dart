/// Dia de visita e seus assets canônicos.
///
/// Os caminhos usam o prefixo `packages/roteiro/...` porque os ícones passam a
/// ser empacotados com o componente — não ficam mais duplicados em
/// `images/monitoramento` de cada app.
enum VisityDay {
  monday(
    title: 'Segunda-feira',
    shortTitle: 'Segunda',
    weekDay: 1,
    colorValue: 0xFFF44336,
    color2Value: 0xFFFF5757,
    iconAsset: 'packages/roteiro/assets/images/monitoramento/place-red.png',
    periodicityIcons: [
      'packages/roteiro/assets/images/monitoramento/semanal/segunda_semanal.png',
      'packages/roteiro/assets/images/monitoramento/quinzenal_1_3/segunda_1_3.png',
      'packages/roteiro/assets/images/monitoramento/quinzenal_2_4/segunda_2_4.png',
      'packages/roteiro/assets/images/monitoramento/mensal/segunda_mensal.png',
      'packages/roteiro/assets/images/monitoramento/21dias/segunda_21_dias.png',
    ],
  ),
  tuesday(
    title: 'Terça-feira',
    shortTitle: 'Terça',
    weekDay: 2,
    colorValue: 0xFFFFD902,
    color2Value: 0xFFFEFB5A,
    iconAsset: 'packages/roteiro/assets/images/monitoramento/place-yellow.png',
    periodicityIcons: [
      'packages/roteiro/assets/images/monitoramento/semanal/terca_semanal.png',
      'packages/roteiro/assets/images/monitoramento/quinzenal_1_3/terca_1_3.png',
      'packages/roteiro/assets/images/monitoramento/quinzenal_2_4/terca_2_4.png',
      'packages/roteiro/assets/images/monitoramento/mensal/terca_mensal.png',
      'packages/roteiro/assets/images/monitoramento/21dias/terca_21_dias.png',
    ],
  ),
  wednesday(
    title: 'Quarta-feira',
    shortTitle: 'Quarta',
    weekDay: 3,
    colorValue: 0xFF4CAF50,
    color2Value: 0xFF7FFF00,
    iconAsset: 'packages/roteiro/assets/images/monitoramento/place-green.png',
    periodicityIcons: [
      'packages/roteiro/assets/images/monitoramento/semanal/quarta_semanal.png',
      'packages/roteiro/assets/images/monitoramento/quinzenal_1_3/quarta_1_3.png',
      'packages/roteiro/assets/images/monitoramento/quinzenal_2_4/quarta_2_4.png',
      'packages/roteiro/assets/images/monitoramento/mensal/quarta_mensal.png',
      'packages/roteiro/assets/images/monitoramento/21dias/quarta_21_dias.png',
    ],
  ),
  thursday(
    title: 'Quinta-feira',
    shortTitle: 'Quinta',
    weekDay: 4,
    colorValue: 0xFF002AFA,
    color2Value: 0xFF4FA7FF,
    iconAsset: 'packages/roteiro/assets/images/monitoramento/place-blue.png',
    periodicityIcons: [
      'packages/roteiro/assets/images/monitoramento/semanal/quinta_semanal.png',
      'packages/roteiro/assets/images/monitoramento/quinzenal_1_3/quinta_1_3.png',
      'packages/roteiro/assets/images/monitoramento/quinzenal_2_4/quinta_2_4.png',
      'packages/roteiro/assets/images/monitoramento/mensal/quinta_mensal.png',
      'packages/roteiro/assets/images/monitoramento/21dias/quinta_21_dias.png',
    ],
  ),
  friday(
    title: 'Sexta-feira',
    shortTitle: 'Sexta',
    weekDay: 5,
    colorValue: 0xFF9C27B0,
    color2Value: 0xFF9B43F9,
    iconAsset: 'packages/roteiro/assets/images/monitoramento/place-purple.png',
    periodicityIcons: [
      'packages/roteiro/assets/images/monitoramento/semanal/sexta_semanal.png',
      'packages/roteiro/assets/images/monitoramento/quinzenal_1_3/sexta_1_3.png',
      'packages/roteiro/assets/images/monitoramento/quinzenal_2_4/sexta_2_4.png',
      'packages/roteiro/assets/images/monitoramento/mensal/sexta_mensal.png',
      'packages/roteiro/assets/images/monitoramento/21dias/sexta_21_dias.png',
    ],
  ),
  saturday(
    title: 'Sábado',
    shortTitle: 'Sábado',
    weekDay: 6,
    colorValue: 0xFF000000,
    color2Value: 0xFF646464,
    iconAsset: 'packages/roteiro/assets/images/monitoramento/place-black.png',
    periodicityIcons: [
      'packages/roteiro/assets/images/monitoramento/semanal/sabado_semanal.png',
      'packages/roteiro/assets/images/monitoramento/quinzenal_1_3/sabado_1_3.png',
      'packages/roteiro/assets/images/monitoramento/quinzenal_2_4/sabado_2_4.png',
      'packages/roteiro/assets/images/monitoramento/mensal/sabado_mensal.png',
      'packages/roteiro/assets/images/monitoramento/21dias/sabado_21_dias.png',
    ],
  ),
  sunday(
    title: 'Domingo',
    shortTitle: 'Domingo',
    weekDay: 7,
    colorValue: 0xFF9E9E9E,
    color2Value: 0xFFBFBFBF,
    iconAsset: 'packages/roteiro/assets/images/monitoramento/place-gray.png',
    periodicityIcons: [
      'packages/roteiro/assets/images/monitoramento/semanal/domingo_semanal.png',
      'packages/roteiro/assets/images/monitoramento/quinzenal_1_3/domingo_1_3.png',
      'packages/roteiro/assets/images/monitoramento/quinzenal_2_4/domingo_2_4.png',
      'packages/roteiro/assets/images/monitoramento/mensal/domingo_mensal.png',
      'packages/roteiro/assets/images/monitoramento/21dias/domingo_21_dias.png',
    ],
  );

  const VisityDay({
    required this.title,
    required this.shortTitle,
    required this.weekDay,
    required this.colorValue,
    required this.color2Value,
    required this.iconAsset,
    required this.periodicityIcons,
  });

  final String title;
  final String shortTitle;

  /// 1 = segunda ... 7 = domingo.
  final int weekDay;

  /// Cor ARGB usada na rota da segunda semana/quinzena ímpar.
  final int colorValue;

  /// Cor ARGB usada na rota da primeira semana/quinzena par.
  final int color2Value;

  /// Pino padrão do dia (quando o cliente não tem periodicidade definida).
  final String iconAsset;

  /// Ícones por frequência, na mesma ordem do BackOffice:
  /// 0 semanal, 1 quinzenal 1/3, 2 quinzenal 2/4, 3 mensal, 4 21 dias.
  final List<String> periodicityIcons;

  static const String defaultIconAsset =
      'packages/roteiro/assets/images/monitoramento/place-default.png';

  static VisityDay? fromValue(String? value) {
    for (final day in values) {
      if (day.title == value || day.shortTitle == value) return day;
    }
    return null;
  }

  static VisityDay? fromWeekDay(int weekDay) {
    for (final day in values) {
      if (day.weekDay == weekDay) return day;
    }
    return null;
  }
}
