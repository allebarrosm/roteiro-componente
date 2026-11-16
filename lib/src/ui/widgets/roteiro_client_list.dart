import 'package:flutter/material.dart';

import '../../core/roteiro_client.dart';

/// Lista de clientes do Roteiro (bottom sheet no mobile, painel no desktop).
class RoteiroClientList extends StatelessWidget {
  const RoteiroClientList({
    super.key,
    required this.clients,
    required this.onTap,
    this.selected,
    this.padding = const EdgeInsets.symmetric(vertical: 8),
  });

  final List<RoteiroClient> clients;
  final ValueChanged<RoteiroClient> onTap;
  final RoteiroClient? selected;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    if (clients.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text('Nenhum cliente para os filtros selecionados.'),
        ),
      );
    }

    final scheme = Theme.of(context).colorScheme;

    return ListView.separated(
      padding: padding,
      itemCount: clients.length,
      separatorBuilder: (context, index) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final client = clients[index];
        final isSelected = selected?.personCode == client.personCode;
        final subtitle = [
          client.day?.title ?? 'Sem agenda',
          client.periodicity?.label ?? 'Sem periodicidade',
        ].join(' · ');

        return ListTile(
          selected: isSelected,
          selectedTileColor: scheme.primaryContainer.withValues(alpha: 0.35),
          leading: CircleAvatar(
            radius: 18,
            child: Text(
              '${client.visitOrder}',
              style: const TextStyle(fontSize: 12),
            ),
          ),
          title: Text(
            client.displayName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Text(
            subtitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          trailing: Icon(
            client.hasCoordinate
                ? Icons.location_on_outlined
                : Icons.location_off_outlined,
            size: 18,
          ),
          onTap: () => onTap(client),
        );
      },
    );
  }
}
