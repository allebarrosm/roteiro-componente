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
    this.nextSequence,
  });

  final RoteiroClient client;

  /// Quando informado, mostra o botão "Excluir Agenda".
  final Future<bool> Function()? onDelete;

  /// Recalcula a sequência ao escolher data/dia/frequência, como o
  /// `getSeq` do BackOffice.
  final int Function(VisityDay day)? nextSequence;

  static Future<RoteiroVisitChange?> show(
    BuildContext context,
    RoteiroClient client, {
    Future<bool> Function()? onDelete,
    int Function(VisityDay day)? nextSequence,
  }) {
    return showDialog<RoteiroVisitChange>(
      context: context,
      builder: (_) => RoteiroVisitDialog(
        client: client,
        onDelete: onDelete,
        nextSequence: nextSequence,
      ),
    );
  }

  @override
  State<RoteiroVisitDialog> createState() => _RoteiroVisitDialogState();
}

class _RoteiroVisitDialogState extends State<RoteiroVisitDialog> {
  late VisityDay? _day;
  late PeriodicityFilter? _periodicity;
  late int _visitOrder;
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
    _visitOrder = initial.visitOrder > 0 ? initial.visitOrder : 1;
  }

  void _save() {
    if (_day == null || _periodicity == null || _visitOrder <= 0) {
      setState(() {
        _error = 'Selecione o dia, a frequência e a sequência.';
      });
      return;
    }

    Navigator.of(context).pop(
      RoteiroVisitChange(
        client: widget.client,
        day: _day,
        periodicity: _periodicity,
        visitOrder: _visitOrder,
        dateBase: _dateBase,
      ),
    );
  }

  void _applyNextSequence() {
    final resolver = widget.nextSequence;
    final day = _day;
    if (resolver == null || day == null) return;

    final value = resolver(day);
    if (value > 0) _visitOrder = value;
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
      _applyNextSequence();
    });
  }

  Future<void> _pickDay() async {
    final selected = await showModalBottomSheet<VisityDay>(
      context: context,
      showDragHandle: true,
      backgroundColor: _sheetBackground(context),
      builder: (context) {
        final textColor = _sheetTextColor(context);
        return SafeArea(
          child: ListView(
            shrinkWrap: true,
            children: [
              for (final day in VisityDay.values)
                ListTile(
                  leading: Image.asset(day.iconAsset, width: 20, height: 20),
                  title: Text(
                    day.title,
                    style: TextStyle(color: textColor),
                  ),
                  iconColor: textColor,
                  trailing: _day == day
                      ? Icon(Icons.check, color: Theme.of(context).colorScheme.primary)
                      : null,
                  onTap: () => Navigator.of(context).pop(day),
                ),
            ],
          ),
        );
      },
    );

    if (selected != null && mounted) {
      setState(() {
        _day = selected;
        _applyNextSequence();
      });
    }
  }

  Future<void> _pickPeriodicity() async {
    final selected = await showModalBottomSheet<PeriodicityFilter>(
      context: context,
      showDragHandle: true,
      backgroundColor: _sheetBackground(context),
      builder: (context) {
        final textColor = _sheetTextColor(context);
        return SafeArea(
          child: ListView(
            shrinkWrap: true,
            children: [
              for (final periodicity in PeriodicityFilter.values)
                ListTile(
                  title: Text(
                    periodicity.label,
                    style: TextStyle(color: textColor),
                  ),
                  trailing: _periodicity == periodicity
                      ? Icon(Icons.check, color: Theme.of(context).colorScheme.primary)
                      : null,
                  onTap: () => Navigator.of(context).pop(periodicity),
                ),
            ],
          ),
        );
      },
    );

    if (selected != null && mounted) {
      setState(() {
        _periodicity = selected;
        _applyNextSequence();
      });
    }
  }

  Future<void> _pickSequence() async {
    final count = _visitOrder + 10 < 50 ? 50 : _visitOrder + 10;
    final selected = await showModalBottomSheet<int>(
      context: context,
      showDragHandle: true,
      backgroundColor: _sheetBackground(context),
      builder: (context) {
        final textColor = _sheetTextColor(context);
        return SafeArea(
          child: ListView.builder(
            itemCount: count,
            itemBuilder: (context, index) {
              final value = index + 1;
              return ListTile(
                title: Text(
                  '$value',
                  style: TextStyle(color: textColor),
                ),
                trailing: _visitOrder == value
                    ? Icon(Icons.check, color: Theme.of(context).colorScheme.primary)
                    : null,
                onTap: () => Navigator.of(context).pop(value),
              );
            },
          ),
        );
      },
    );

    if (selected != null && mounted) {
      setState(() => _visitOrder = selected);
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
    final textColor =
        theme.brightness == Brightness.dark ? Colors.white : Colors.black;

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
              Align(
                alignment: Alignment.topRight,
                child: IconButton(
                  tooltip: 'Fechar',
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: () => Navigator.of(context).pop(),
                  icon: Icon(Icons.close, color: textColor),
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Expanded(
                    child: _summaryField(
                      label: 'Data base',
                      value: _dateBase == null
                          ? 'Selecionar'
                          : _formatDate(_dateBase!),
                      textColor: textColor,
                      onTap: _pickDate,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _summaryField(
                      label: 'Sequência',
                      value: '$_visitOrder',
                      textColor: textColor,
                      onTap: _pickSequence,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _selectionRow(
                label: 'Dias visita',
                value: _day?.title,
                textColor: textColor,
                onTap: _pickDay,
              ),
              const SizedBox(height: 12),
              _selectionRow(
                label: 'Frequência',
                value: _periodicity?.label,
                textColor: textColor,
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
    required Color textColor,
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
          style: theme.textTheme.bodyMedium?.copyWith(color: textColor),
        ),
      ),
    );
  }

  Widget _selectionRow({
    required String label,
    String? value,
    required Color textColor,
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
                    color: textColor,
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
                      color: textColor,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
              ],
              Icon(Icons.chevron_right, color: textColor),
            ],
          ),
        ),
      ),
    );
  }

  Color _sheetBackground(BuildContext context) {
    return Theme.of(context).colorScheme.surface;
  }

  Color _sheetTextColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? Colors.white
        : Colors.black;
  }

  static String _formatDate(DateTime value) {
    final day = value.day.toString().padLeft(2, '0');
    final month = value.month.toString().padLeft(2, '0');
    return '$day/$month/${value.year}';
  }
}
