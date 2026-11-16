/// Periodicidade do plano de visita.
enum Periodicity {
  weekly('Semanal', '1'),
  fortnightly('Quinzenal', '2'),
  days21('21 Dias', '3'),
  monthly('Mensal', '4');

  const Periodicity(this.label, this.code);

  final String label;
  final String code;

  static Periodicity? fromCode(String? code) {
    for (final value in values) {
      if (value.code == code) return value;
    }
    return null;
  }

  static Periodicity? fromLabel(String? label) {
    for (final value in values) {
      if (value.label == label) return value;
    }
    return null;
  }
}

/// Filtro de periodicidade exibido na UI.
///
/// `Quinzenal` é dividido em 1/3 e 2/4 porque o backend representa as duas
/// quinzenas com o mesmo `PeriodicityType.fortnightly` + um booleano.
enum PeriodicityFilter {
  weekly('Semanal', '1'),
  firstWeek('Quinzenal 1/3', '2'),
  lastWeek('Quinzenal 2/4', '2'),
  days21('21 Dias', '3'),
  monthly('Mensal', '4');

  const PeriodicityFilter(this.label, this.code);

  final String label;
  final String code;

  static PeriodicityFilter? fromLabel(String? label) {
    for (final value in values) {
      if (value.label == label) return value;
    }
    return null;
  }
}

extension PeriodicityFilterConversion on PeriodicityFilter {
  /// Periodicidade "de domínio" equivalente ao filtro.
  Periodicity get periodicity => switch (this) {
        PeriodicityFilter.weekly => Periodicity.weekly,
        PeriodicityFilter.firstWeek || PeriodicityFilter.lastWeek =>
          Periodicity.fortnightly,
        PeriodicityFilter.days21 => Periodicity.days21,
        PeriodicityFilter.monthly => Periodicity.monthly,
      };

  /// `true` para quinzenal 1ª/3ª semana.
  bool get isFirstWeek => this == PeriodicityFilter.firstWeek;
}
