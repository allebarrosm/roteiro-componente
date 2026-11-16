import 'package:flutter/material.dart';

import '../../core/periodicity.dart';
import '../../core/roteiro_client.dart';
import '../../core/roteiro_visit_change.dart';
import '../../core/visity_day.dart';

/// Diálogo de edição de um ponto do roteiro (dia, frequência, ordem e data).
///
/// Retorna [RoteiroVisitChange] via `Navigator.pop`; quem chamou decide se
/// persiste (`RoteiroStore.saveVisit`).
class RoteiroVisitDialog extends StatefulWidget {
  const RoteiroVisitDialog({
    super.key,
    required this.client,
    this.title = 'Editar visita',
  });

  final RoteiroClient client;
  final String title;

  static Future<RoteiroVisitChange?> show(
    BuildContext context,
    RoteiroClient client, {
    String title = 'Editar visita',
  }) {
    return showDialog<RoteiroVisitChange>(
      context: context,
      builder: (_) => RoteiroVisitDialog(client: client, title: title),
    );
  }

  @override
  State<RoteiroVisitDialog> createState() => _RoteiroVisitDialogState();
}

class _RoteiroVisitDialogState extends State<RoteiroVisitDialog> {
  late VisityDay? _day;
  late PeriodicityFilter? _periodicity;
  late final TextEditingController _order;
  DateTime? _dateBase;
  String? _error;

  @override
  void initState() {
    super.initState();
    final initial = RoteiroVisitChange.fromClient(widget.client);
    _day = initial.day;
    _periodicity = initial.periodicity;
    _dateBase = initial.dateBase;
    _order = TextEditingController(text: '${initial.visitOrder}');
  }

  @override
  void dispose() {
    _order.dispose();
    super.dispose();
  }

  void _save() {
    final order = int.tryParse(_order.text.trim());

    if (_day == null || _periodicity == null || order == null || order <= 0) {
      setState(() {
        _error = 'Informe dia, frequência e uma ordem maior que zero.';
      });
      return;
    }

    Navigator.of(context).pop(
      RoteiroVisitChange(
        client: widget.client,
        day: _day,
        periodicity: _periodicity,
        visitOrder: order,
        dateBase: _dateBase,
      ),
    );
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dateBase ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );

    if (picked == null || !mounted) return;

    setState(() {
      _dateBase = picked;
      // Mesma regra do VisityDialog: a data base define o dia da visita.
      _day = VisityDay.fromWeekDay(picked.weekday);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final client = widget.client;

    return AlertDialog(
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(widget.title),
          const SizedBox(height: 4),
          Text(
            '${client.personCode} - ${client.displayName}',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.primary,
            ),
          ),
          if (client.address.isNotEmpty)
            Text(
              client.address,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          if ((client.representativeName ?? '').isNotEmpty)
            Text(
              'Representante: ${client.representativeName}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
        ],
      ),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _dropdownField<VisityDay>(
                label: 'Dia da visita',
                value: _day,
                hint: 'Selecione o dia',
                items: [
                  for (final day in VisityDay.values)
                    DropdownMenuItem(value: day, child: Text(day.title)),
                ],
                onChanged: (value) => setState(() => _day = value),
              ),
              const SizedBox(height: 12),
              _dropdownField<PeriodicityFilter>(
                label: 'Frequência',
                value: _periodicity,
                hint: 'Selecione a frequência',
                items: [
                  for (final periodicity in PeriodicityFilter.values)
                    DropdownMenuItem(
                      value: periodicity,
                      child: Text(periodicity.label),
                    ),
                ],
                onChanged: (value) =>
                    setState(() => _periodicity = value),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _order,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Ordem de visita',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              InkWell(
                onTap: _pickDate,
                borderRadius: BorderRadius.circular(4),
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Data base',
                    border: OutlineInputBorder(),
                    suffixIcon: Icon(Icons.calendar_today_outlined),
                  ),
                  child: Text(
                    _dateBase == null ? 'Selecionar data' : _formatDate(_dateBase!),
                  ),
                ),
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    _error!,
                    style: TextStyle(color: theme.colorScheme.error),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: _save,
          child: const Text('Salvar alterações'),
        ),
      ],
    );
  }

  Widget _dropdownField<T>({
    required String label,
    required T? value,
    required String hint,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?> onChanged,
  }) {
    return InputDecorator(
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          isExpanded: true,
          value: value,
          hint: Text(hint),
          items: items,
          onChanged: onChanged,
        ),
      ),
    );
  }

  static String _formatDate(DateTime value) {
    final day = value.day.toString().padLeft(2, '0');
    final month = value.month.toString().padLeft(2, '0');
    return '$day/$month/${value.year}';
  }
}
