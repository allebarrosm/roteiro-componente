import 'package:flutter/material.dart';

/// Card inferior com o cliente selecionado no mapa.
class RoteiroDetailsCard extends StatelessWidget {
  const RoteiroDetailsCard({
    super.key,
    required this.title,
    required this.address,
    this.subtitle,
    this.child,
    this.onClose,
    this.onStreetView,
    this.onNavigate,
    this.maxWidth = 520,
  });

  final String title;
  final String address;
  final String? subtitle;
  final Widget? child;
  final VoidCallback? onClose;
  final VoidCallback? onStreetView;
  final VoidCallback? onNavigate;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Material(
      elevation: 8,
      color: scheme.surface,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 10, 6, 10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        if ((subtitle ?? '').isNotEmpty)
                          Text(
                            subtitle!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: textTheme.bodySmall?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                      ],
                    ),
                  ),
                  if (onClose != null)
                    IconButton(
                      onPressed: onClose,
                      iconSize: 18,
                      visualDensity: VisualDensity.compact,
                      icon: const Icon(Icons.close),
                    ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.only(right: 8, top: 2),
                child: Text(
                  address,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ),
              if (child != null)
                Padding(
                  padding: const EdgeInsets.only(right: 8, top: 8),
                  child: child!,
                ),
              if (onStreetView != null || onNavigate != null)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Wrap(
                    spacing: 4,
                    children: [
                      if (onStreetView != null)
                        TextButton.icon(
                          onPressed: onStreetView,
                          icon: const Icon(Icons.streetview_outlined, size: 18),
                          label: const Text('Street View'),
                        ),
                      if (onNavigate != null)
                        TextButton.icon(
                          onPressed: onNavigate,
                          icon: const Icon(Icons.directions_outlined, size: 18),
                          label: const Text('Rota'),
                        ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
