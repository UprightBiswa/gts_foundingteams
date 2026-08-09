import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/gts_card.dart';
import '../domain/safety_alert.dart';

/// The reassurance panel.
///
/// Naming the checks that are running — and showing them green — is what turns
/// "nothing is on screen" into "nothing is wrong". Silence is ambiguous;
/// an explicit all-clear is not.
class SafetyStatusCard extends StatelessWidget {
  const SafetyStatusCard({
    super.key,
    required this.alerts,
    required this.isOverspeeding,
    required this.isStalled,
    required this.onViewHistory,
  });

  final List<SafetyAlert> alerts;
  final bool isOverspeeding;
  final bool isStalled;
  final VoidCallback onViewHistory;

  @override
  Widget build(BuildContext context) {
    final activeCount = alerts.where((alert) => alert.isActive).length;
    final allClear = activeCount == 0;
    final tint = allClear ? AppColors.safe : AppColors.danger;

    return GtsCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: allClear ? AppColors.safeSoft : AppColors.dangerSoft,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  allClear ? Icons.shield_outlined : Icons.gpp_maybe_outlined,
                  size: 19,
                  color: tint,
                ),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      allClear
                          ? 'All safety checks normal'
                          : '$activeCount active safety '
                                '${activeCount == 1 ? 'alert' : 'alerts'}',
                      style: TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.2,
                        color: allClear ? AppColors.ink : tint,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      allClear
                          ? 'Monitoring speed and location continuously'
                          : 'Review the details and contact the driver if needed',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.inkMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _Check(label: 'Speed', isHealthy: !isOverspeeding),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _Check(label: 'Location', isHealthy: !isStalled),
              ),
              const SizedBox(width: 8),
              const Expanded(child: _Check(label: 'Route', isHealthy: true)),
            ],
          ),
          if (alerts.isNotEmpty) ...[
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 4),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: onViewHistory,
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 4,
                  ),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  foregroundColor: AppColors.brandDark,
                ),
                icon: const Icon(Icons.history_rounded, size: 16),
                label: Text(
                  'View alert history (${alerts.length})',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _Check extends StatelessWidget {
  const _Check({required this.label, required this.isHealthy});

  final String label;
  final bool isHealthy;

  @override
  Widget build(BuildContext context) {
    final color = isHealthy ? AppColors.safe : AppColors.danger;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 9),
      decoration: BoxDecoration(
        color: isHealthy ? AppColors.safeSoft : AppColors.dangerSoft,
        borderRadius: BorderRadius.circular(11),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isHealthy ? Icons.check_circle_rounded : Icons.error_rounded,
            size: 14,
            color: color,
          ),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
