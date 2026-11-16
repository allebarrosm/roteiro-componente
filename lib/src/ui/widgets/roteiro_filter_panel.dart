import 'package:flutter/material.dart';

import '../../core/periodicity.dart';
import '../../core/roteiro_filter.dart';
import '../../core/visity_day.dart';
import '../store/roteiro_store.dart';
import '../theme/visity_day_ui.dart';

/// Painel de filtros com o mesmo layout usado nos apps:
/// toggles em checkbox, dias de visita com ícone/legenda e frequência.
///
/// O painel trabalha com um rascunho local e só aplica ao tocar em
/// **Aplicar** — mesma dinâmica do `FilterRoteiro` do Gestão.
class RoteiroFilterPanel extends StatefulWidget {
  const RoteiroFilterPanel({
    super.key,
    required this.store,
    this.onClose,
    this.agentSelector,
  });

  final RoteiroStore store;
  final VoidCallback? onClose;

  /// Slot opcional para o seletor de representante (Gestão/BackOffice).
  final Widget? agentSelector;

  @override
  State<RoteiroFilterPanel> createState() => _RoteiroFilterPanelState();
}

class _RoteiroFilterPanelState extends State<RoteiroFilterPanel> {
  late Set<VisityDay> _days;
  late Set<PeriodicityFilter> _periodicities;
  late bool _showClients;
  late bool _showRoute;
  late bool _showSequence;
  late bool _noScheduling;

  @override
  void initState() {
    super.initState();
    final store = widget.store;
    _days = Set<VisityDay>.of(store.filter.days);
    _periodicities = Set<PeriodicityFilter>.of(store.filter.periodicities);
    _showClients = store.showClients;
    _showRoute = store.showRoute;
    _showSequence = store.showSequence;
    _noScheduling = store.filter.noScheduling;
  }

  void _toggleDay(VisityDay day) {
    setState(() {
      if (!_days.remove(day)) _days.add(day);
    });
  }

  void _togglePeriodicity(PeriodicityFilter periodicity) {
    setState(() {
      if (!_periodicities.remove(periodicity)) _periodicities.add(periodicity);
    });
  }

  void _clear() {
    setState(() {
      _days.clear();
      _periodicities.clear();
      _showClients = true;
      _showRoute = true;
      _showSequence = true;
      _noScheduling = true;
    });
  }

  Future<void> _apply() async {
    final store = widget.store;
    store.setShowClients(_showClients);
    store.setShowSequence(_showSequence);
    store.showRoute = _showRoute;

    await store.setFilter(
      RoteiroFilter(
        days: Set<VisityDay>.of(_days),
        periodicities: Set<PeriodicityFilter>.of(_periodicities),
        noScheduling: _noScheduling,
      ),
    );

    widget.onClose?.call();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: theme.colorScheme.surfaceContainerHigh,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      clipBehavior: Clip.antiAlias,
      child: SafeArea(
        top: false,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(context).height * 0.88,
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Text(
                      'Filtros',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const Spacer(),
                    if (widget.onClose != null)
                      IconButton(
                        onPressed: widget.onClose,
                        tooltip: 'Fechar',
                        icon: const Icon(Icons.close),
                      ),
                  ],
                ),
                if (widget.agentSelector != null) ...[
                  widget.agentSelector!,
                  const SizedBox(height: 8),
                ],
                _toggle('Nome Cliente', _showClients, (value) {
                  setState(() => _showClients = value);
                }),
                _toggle('Percurso', _showRoute, (value) {
                  setState(() => _showRoute = value);
                }),
                _toggle('Sequência', _showSequence, (value) {
                  setState(() => _showSequence = value);
                }),
                _toggle('Sem agendamento', _noScheduling, (value) {
                  setState(() => _noScheduling = value);
                }),
                const Divider(height: 20),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final wide = constraints.maxWidth >= 520;
                    final days = _daysSection(theme);
                    final periodicities = _periodicitySection(theme);

                    if (wide) {
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(child: days),
                          const SizedBox(width: 24),
                          Expanded(child: periodicities),
                        ],
                      );
                    }

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        days,
                        const SizedBox(height: 12),
                        periodicities,
                      ],
                    );
                  },
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    TextButton(
                      onPressed: _clear,
                      child: const Text('Limpar'),
                    ),
                    const Spacer(),
                    FilledButton(
                      onPressed: _apply,
                      child: const Text('Aplicar'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _toggle(String label, bool value, ValueChanged<bool> onChanged) {
    return InkWell(
      onTap: () => onChanged(!value),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          children: [
            SizedBox(
              width: 24,
              height: 24,
              child: Checkbox(
                value: value,
                onChanged: (checked) => onChanged(checked ?? false),
                visualDensity: VisualDensity.compact,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
            const SizedBox(width: 6),
            Text(label, style: const TextStyle(fontSize: 15)),
          ],
        ),
      ),
    );
  }

  Widget _daysSection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Dias Visitas',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        for (final day in VisityDay.values)
          InkWell(
            onTap: () => _toggleDay(day),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 1),
              child: Row(
                children: [
                  SizedBox(
                    width: 24,
                    height: 24,
                    child: Checkbox(
                      value: _days.contains(day),
                      onChanged: (_) => _toggleDay(day),
                      activeColor: day.color,
                      checkColor: Colors.white,
                      visualDensity: VisualDensity.compact,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      day.title,
                      style: TextStyle(fontSize: 13, color: day.color),
                    ),
                  ),
                  Image.asset(day.iconAsset, width: 22, height: 22),
                ],
              ),
            ),
          ),
        const SizedBox(height: 4),
        Row(
          children: [
            const SizedBox(width: 30),
            const Expanded(
              child: Text(
                'Cliente sem agendamento',
                style: TextStyle(fontSize: 12),
              ),
            ),
            Image.asset(
              VisityDay.defaultIconAsset,
              width: 22,
              height: 22,
            ),
          ],
        ),
      ],
    );
  }

  Widget _periodicitySection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Frequência',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        for (final periodicity in PeriodicityFilter.values)
          InkWell(
            onTap: () => _togglePeriodicity(periodicity),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 1),
              child: Row(
                children: [
                  SizedBox(
                    width: 24,
                    height: 24,
                    child: Checkbox(
                      value: _periodicities.contains(periodicity),
                      onChanged: (_) => _togglePeriodicity(periodicity),
                      visualDensity: VisualDensity.compact,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      periodicity.label,
                      style: const TextStyle(fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
