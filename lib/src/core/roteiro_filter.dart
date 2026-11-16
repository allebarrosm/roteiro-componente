import 'periodicity.dart';
import 'roteiro_client.dart';
import 'visity_day.dart';

/// Regras de filtro do Roteiro, compartilhadas pelos três apps.
class RoteiroFilter {
  const RoteiroFilter({
    this.days = const <VisityDay>{},
    this.periodicities = const <PeriodicityFilter>{},
    this.noScheduling = true,
  });

  final Set<VisityDay> days;
  final Set<PeriodicityFilter> periodicities;

  /// Inclui clientes sem dia de visita definido (`day == null`).
  final bool noScheduling;

  static const RoteiroFilter empty = RoteiroFilter();

  bool get isEmpty => days.isEmpty && periodicities.isEmpty;

  RoteiroFilter copyWith({
    Set<VisityDay>? days,
    Set<PeriodicityFilter>? periodicities,
    bool? noScheduling,
  }) {
    return RoteiroFilter(
      days: days ?? this.days,
      periodicities: periodicities ?? this.periodicities,
      noScheduling: noScheduling ?? this.noScheduling,
    );
  }

  /// Mesma semântica do Gestão/BackOffice:
  ///
  /// - cliente sem dia: só entra se [noScheduling] estiver ligado;
  /// - filtro de dia vazio: todos os dias;
  /// - filtro de periodicidade vazio: todas as periodicidades.
  bool matches(RoteiroClient client) {
    final day = client.day;
    if (day == null) return noScheduling;

    if (days.isNotEmpty && !days.contains(day)) return false;

    if (periodicities.isNotEmpty &&
        !periodicities.any((filter) => filter.matches(client))) {
      return false;
    }

    return true;
  }

  List<RoteiroClient> apply(Iterable<RoteiroClient> clients) =>
      clients.where(matches).toList(growable: false);
}

extension PeriodicityFilterMatch on PeriodicityFilter {
  bool matches(RoteiroClient client) {
    return switch (this) {
      PeriodicityFilter.weekly => client.periodicity == Periodicity.weekly,
      PeriodicityFilter.firstWeek =>
        client.periodicity == Periodicity.fortnightly && client.firstWeek,
      PeriodicityFilter.lastWeek =>
        client.periodicity == Periodicity.fortnightly && !client.firstWeek,
      PeriodicityFilter.days21 => client.periodicity == Periodicity.days21,
      PeriodicityFilter.monthly => client.periodicity == Periodicity.monthly,
    };
  }
}
