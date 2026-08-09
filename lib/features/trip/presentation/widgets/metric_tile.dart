import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

/// One live number from the journey: ETA, distance remaining or speed.
///
/// The value and its unit share a baseline so the three tiles line up
/// optically even though "8", "1.4" and "66" have different widths.
class MetricTile extends StatelessWidget {
  const MetricTile({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    required this.unit,
    this.accent,
    this.isAlerting = false,
  });

  final IconData icon;
  final String label;
  final String value;
  final String unit;
  final Color? accent;

  /// Repaints the tile in the alert colour — used when speed breaches the limit.
  final bool isAlerting;

  @override
  Widget build(BuildContext context) {
    final tint = accent ?? AppColors.brand;
    final background = isAlerting ? AppColors.dangerSoft : AppColors.surface;
    final borderColor = isAlerting ? AppColors.danger : AppColors.border;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isAlerting ? borderColor.withValues(alpha: 0.45) : borderColor,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: tint),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Flexible(
                child: Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    height: 1,
                    letterSpacing: -0.6,
                    color: AppColors.ink,
                  ),
                ),
              ),
              const SizedBox(width: 3),
              Text(
                unit,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.inkMuted,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w500,
              color: AppColors.inkMuted,
            ),
          ),
        ],
      ),
    );
  }
}
