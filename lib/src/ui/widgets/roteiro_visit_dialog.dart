import 'package:flutter/material.dart';

import '../../core/periodicity.dart';
import '../../core/roteiro_client.dart';
import '../../core/roteiro_visit_change.dart';
import '../../core/visity_day.dart';

/// Diálogo de edição de um ponto do roteiro.
///
/// Retorna [RoteiroVisitChange] via `Navigator.pop`; quem chamou decide se
/// persiste (`RoteiroStore.saveVisit`). A exclusão é delegada ao app via
/// [onDelete] para que ele chame a API e atualize o roteiro.
class RoteiroVisitDialog extends StatefulWidget {
  const RoteiroVisitDialog({
    super.key,
    required this.client,
    this.onDelete,
  });

  final RoteiroClient client;

  /// Quando informado, mostra o botão "Excluir Agenda".
  final Future<bool> Function()? onDelete;

  static Future<RoteiroVisitChange?> show(
    BuildContext context,
    RoteiroClient client, {
    Future<bool> Function()? onDelete,
  }) {
    return showDialog<RoteiroVisitChange>(
      context: context,
      builder: (_) => RoteiroVisitDialog(
        client: client,
        onDelete: onDelete,
      ),
    );
  }

  @override
  State<RoteiroVisitDialog> createState() => _RoteiroVisitDialogState();
}

class _RoteiroVisitDialogState extends State<RoteiroVisitDialog> {
  late VisityDay? _day;
  late PeriodicityFilter? _periodicity;
  late final int _initialOrder;
  DateTime? _dateBase;
  String? _error;
  bool _deleting = false;

  @override
  void initState() {
    super.initState();
    final initial = RoteiroVisitChange.fromClient(widget.client);
    _day = initial.day;
    _periodicity = initial.periodicity;
    _dateBase = initial.dateBase;
    _initialOrder = initial.visitOrder;
  }

  void _save() {
    if (_day == null || _periodicity == null) {
      setState(() {
        _error = 'Selecione o dia e a frequência.';
      });
      return;
    }

    Navigator.of(context).pop(
      RoteiroVisitChange(
        client: widget.client,
        day: _day,
        periodicity: _periodicity,
        visitOrder: _initialOrder > 0 ? _initialOrder : 1,
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
      _day = VisityDay.fromWeekDay(picked.weekday);
    });
  }

  Future<void> _pickDay() async {
    final selected = await showModalBottomSheet<VisityDay>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: ListView(
            shrinkWrap: true,
            children: [
              for (final day in VisityDay.values)
                ListTile(
                  leading: Image.asset(day.iconAsset, width: 20, height: 20),
                  title: Text(day.title),
                  trailing: _day == day ? const Icon(Icons.check) : null,
                  onTap: () => Navigator.of(context).pop(day),
                ),
            ],
          ),
        );
      },
    );

    if (selected != null && mounted) {
      setState(() => _day = selected);
    }
  }

  Future<void> _pickPeriodicity() async {
    final selected = await showModalBottomSheet<PeriodicityFilter>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: ListView(
            shrinkWrap: true,
            children: [
              for (final periodicity in PeriodicityFilter.values)
                ListTile(
                  title: Text(periodicity.label),
                  trailing: _periodicity == periodicity
                      ? const Icon(Icons.check)
                      : null,
                  onTap: () => Navigator.of(context).pop(periodicity),
                ),
            ],
          ),
        );
      },
    );

    if (selected != null && mounted) {
      setState(() => _periodicity = selected);
    }
  }

  Future<void> _delete() async {
    final onDelete = widget.onDelete;
    if (onDelete == null || _deleting) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Excluir agenda?'),
        content: const Text('A agenda deste cliente será removida.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _deleting = true);
    final deleted = await onDelete();
    if (!mounted) return;

    if (deleted) {
      Navigator.of(context).pop();
    } else {
      setState(() => _deleting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return AlertDialog(
      backgroundColor: scheme.surface,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      contentPadding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: _summaryField(
                      label: 'Data base',
                      value: _dateBase == null
                          ? 'Selecionar'
                          : _formatDate(_dateBase!),
                      onTap: _pickDate,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _summaryField(
                      label: 'Frequência',
                      value: _periodicity?.label ?? 'Selecionar',
                      onTap: _pickPeriodicity,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _selectionRow(
                label: 'Dias visita',
                value: _day?.title,
                onTap: _pickDay,
              ),
              const SizedBox(height: 12),
              _selectionRow(
                label: 'Frequência',
                value: _periodicity?.label,
                onTap: _pickPeriodicity,
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(
                  _error!,
                  style: TextStyle(color: scheme.error),
                ),
              ],
              if (_deleting) ...[
                const SizedBox(height: 16),
                const LinearProgressIndicator(),
              ],
              const SizedBox(height: 20),
              Row(
                children: [
                  if (widget.onDelete != null) ...[
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _deleting ? null : _delete,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: scheme.primary,
                          side: BorderSide(color: scheme.primary),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: const Text('Excluir Agenda'),
                      ),
                    ),
                    const SizedBox(width: 12),
                  ],
                  Expanded(
                    child: FilledButton(
                      onPressed: _deleting ? null : _save,
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text('Salvar Alterações'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _summaryField({
    required String label,
    required String value,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: scheme.primary),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 10,
            vertical: 8,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(6),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(6),
            borderSide: BorderSide(color: scheme.primary),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(6),
            borderSide: BorderSide(color: scheme.primary, width: 1.5),
          ),
        ),
        child: Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.bodyMedium?.copyWith(color: scheme.onSurface),
        ),
      ),
    );
  }

  Widget _selectionRow({
    required String label,
    String? value,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Material(
      color: scheme.surfaceContainerHigh,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: scheme.onSurface,
                  ),
                ),
              ),
              if ((value ?? '').isNotEmpty) ...[
                Flexible(
                  child: Text(
                    value!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.right,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
              ],
              Icon(Icons.chevron_right, color: scheme.onSurface),
            ],
          ),
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
