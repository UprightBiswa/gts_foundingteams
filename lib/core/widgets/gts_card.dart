import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// The single surface primitive used across the app.
///
/// One card definition (radius, border, shadow) is what keeps a screen built
/// from a dozen separate widgets reading as one product rather than a stack of
/// demo components.
class GtsCard extends StatelessWidget {
  const GtsCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.color = AppColors.surface,
    this.borderColor = AppColors.border,
    this.onTap,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color color;
  final Color borderColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final content = Padding(padding: padding, child: child);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: borderColor),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A0C1B33),
            blurRadius: 16,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: onTap == null
          ? content
          : Material(
              type: MaterialType.transparency,
              child: InkWell(
                onTap: onTap,
                borderRadius: BorderRadius.circular(18),
                child: content,
              ),
            ),
    );
  }
}

/// Small pill used for statuses, plates and counts.
class GtsPill extends StatelessWidget {
  const GtsPill({
    super.key,
    required this.label,
    this.icon,
    this.color = AppColors.inkSecondary,
    this.background = AppColors.canvas,
    this.dense = false,
  });

  final String label;
  final IconData? icon;
  final Color color;
  final Color background;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: dense ? 8 : 10,
        vertical: dense ? 3 : 5,
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: dense ? 12 : 14, color: color),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(
              fontSize: dense ? 11 : 12,
              fontWeight: FontWeight.w600,
              color: color,
              letterSpacing: 0.1,
            ),
          ),
        ],
      ),
    );
  }
}
