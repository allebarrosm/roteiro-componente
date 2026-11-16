import 'periodicity.dart';
import 'roteiro_client.dart';
import 'visity_day.dart';

/// Alteração de um ponto do roteiro: dia, frequência, ordem e data base.
///
/// O app usa este objeto para persistir a edição (API/SQLite) e o store para
/// atualizar a lista local, os marcadores e as rotas.
class RoteiroVisitChange {
  const RoteiroVisitChange({
    required this.client,
    this.day,
    this.periodicity,
    this.visitOrder = 0,
    this.dateBase,
  });

  factory RoteiroVisitChange.fromClient(RoteiroClient client) {
    final PeriodicityFilter? periodicity = switch (client.periodicity) {
      Periodicity.weekly => PeriodicityFilter.weekly,
      Periodicity.fortnightly => client.firstWeek
          ? PeriodicityFilter.firstWeek
          : PeriodicityFilter.lastWeek,
      Periodicity.monthly => PeriodicityFilter.monthly,
      Periodicity.days21 => PeriodicityFilter.days21,
      null => null,
    };

    return RoteiroVisitChange(
      client: client,
      day: client.day,
      periodicity: periodicity,
      visitOrder: client.visitOrder,
      dateBase: client.dateBase,
    );
  }

  final RoteiroClient client;
  final VisityDay? day;
  final PeriodicityFilter? periodicity;
  final int visitOrder;
  final DateTime? dateBase;

  bool get isValid =>
      day != null && periodicity != null && visitOrder > 0;

  /// Aplica a alteração no cliente, mantendo os demais campos.
  RoteiroClient apply() {
    if (!isValid) {
      throw StateError('RoteiroVisitChange inválido: $this');
    }

    return client.copyWith(
      day: day,
      periodicity: periodicity!.periodicity,
      firstWeek: periodicity!.isFirstWeek,
      visitOrder: visitOrder,
      dateBase: dateBase,
    );
  }

  @override
  String toString() => 'RoteiroVisitChange(${client.personCode}, '
      'day: ${day?.name}, periodicity: ${periodicity?.name}, '
      'visitOrder: $visitOrder)';
}
