import 'package:flutter/material.dart';

/// Dados exibidos no balão sobre o mapa.
class RoteiroInfoWindowData {
  const RoteiroInfoWindowData({
    required this.title,
    this.subtitle,
    this.rows = const <String, String?>{},
  });

  final String title;
  final String? subtitle;
  final Map<String, String?> rows;
}

class RoteiroInfoWindow extends StatelessWidget {
  const RoteiroInfoWindow({
    super.key,
    required this.data,
    this.onClose,
    this.onEdit,
    this.maxWidth = 320,
    this.maxHeight = 300,
  });

  final RoteiroInfoWindowData data;
  final VoidCallback? onClose;

  /// Ação de editar o roteiro exibida ao lado do nome/endereço (ícone de lápis).
  final VoidCallback? onEdit;

  final double maxWidth;
  final double maxHeight;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    final bodySmall = textTheme.bodySmall ?? const TextStyle(fontSize: 12);

    final rows = data.rows.entries
        .where((entry) => (entry.value ?? '').trim().isNotEmpty)
        .toList(growable: false);

    return Material(
      elevation: 6,
      color: scheme.surface,
      borderRadius: BorderRadius.circular(14),
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth, maxHeight: maxHeight),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 6, 0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          data.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        if ((data.subtitle ?? '').isNotEmpty)
                          Text(
                            data.subtitle!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: bodySmall.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                      ],
                    ),
                  ),
                  if (onEdit != null)
                    IconButton(
                      onPressed: onEdit,
                      iconSize: 18,
                      visualDensity: VisualDensity.compact,
                      color: scheme.primary,
                      tooltip: 'Editar roteiro',
                      icon: const Icon(Icons.edit_outlined),
                    ),
                  if (onClose != null)
                    IconButton(
                      onPressed: onClose,
                      iconSize: 18,
                      visualDensity: VisualDensity.compact,
                      tooltip: 'Fechar',
                      icon: const Icon(Icons.close),
                    ),
                ],
              ),
            ),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(14, 6, 14, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (final row in rows)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 5),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(
                              width: 104,
                              child: Text(
                                row.key,
                                style: bodySmall.copyWith(
                                  color: scheme.onSurfaceVariant,
                                ),
                              ),
                            ),
                            Expanded(
                              child: Text(
                                row.value!,
                                style: bodySmall.copyWith(
                                  color: scheme.onSurface,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
