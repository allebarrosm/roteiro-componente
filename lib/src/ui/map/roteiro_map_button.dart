import 'package:flutter/widgets.dart';

class RoteiroMapButton {
  const RoteiroMapButton({
    required this.icon,
    this.onTap,
    this.active = false,
    this.tooltip,
  });

  final IconData icon;
  final VoidCallback? onTap;
  final bool active;
  final String? tooltip;
}
