import 'package:flutter/material.dart';

class RoteiroCircleButton extends StatelessWidget {
  const RoteiroCircleButton({
    super.key,
    required this.icon,
    this.onTap,
    this.active = false,
    this.tooltip,
    this.size = 46,
  });

  final IconData icon;
  final VoidCallback? onTap;
  final bool active;
  final String? tooltip;
  final double size;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final background =
        active ? scheme.primary : scheme.surface.withValues(alpha: 0.94);
    final foreground = active ? scheme.onPrimary : scheme.onSurface;

    final button = Material(
      color: background,
      elevation: 2,
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          width: size,
          height: size,
          child: Icon(icon, size: 22, color: foreground),
        ),
      ),
    );

    final label = tooltip;
    if (label == null || label.isEmpty) return button;
    return Tooltip(message: label, child: button);
  }
}
