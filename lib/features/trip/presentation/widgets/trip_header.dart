import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../application/trip_providers.dart';

/// Top of the screen: who is being tracked, plus access to alerts and the
/// demo controls.
class TripHeader extends ConsumerWidget {
  const TripHeader({
    super.key,
    required this.onOpenAlerts,
    required this.onRestart,
    required this.onSimulateOverspeeding,
    required this.onSimulateSignalLoss,
    required this.onToggleRunning,
  });

  final VoidCallback onOpenAlerts;
  final VoidCallback onRestart;
  final VoidCallback onSimulateOverspeeding;
  final VoidCallback onSimulateSignalLoss;
  final VoidCallback onToggleRunning;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final child = ref.watch(childProvider);
    final school = ref.watch(schoolProvider);

    // `select` keeps this row off the 4x-per-second rebuild path: it only
    // rebuilds when the badge count or the run state actually changes.
    final activeAlerts = ref.watch(
      tripControllerProvider.select((state) => state.activeAlertCount),
    );
    final isRunning = ref.watch(
      tripControllerProvider.select((state) => state.isRunning),
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 12, 12),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: AppColors.brandSoft,
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.brand.withValues(alpha: 0.25),
              ),
            ),
            alignment: Alignment.center,
            child: Text(
              child.avatarInitials,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                color: AppColors.brandDark,
                fontSize: 15,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  child.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.4,
                    color: AppColors.ink,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${child.grade} · ${school.name}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12.5,
                    color: AppColors.inkMuted,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          _AlertsButton(count: activeAlerts, onTap: onOpenAlerts),
          _DemoMenu(
            isRunning: isRunning,
            onRestart: onRestart,
            onSimulateOverspeeding: onSimulateOverspeeding,
            onSimulateSignalLoss: onSimulateSignalLoss,
            onToggleRunning: onToggleRunning,
          ),
        ],
      ),
    );
  }
}

class _AlertsButton extends StatelessWidget {
  const _AlertsButton({required this.count, required this.onTap});

  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onTap,
      tooltip: 'Safety alerts',
      icon: Stack(
        clipBehavior: Clip.none,
        children: [
          const Icon(
            Icons.notifications_none_rounded,
            color: AppColors.inkSecondary,
          ),
          if (count > 0)
            Positioned(
              right: -3,
              top: -3,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                constraints: const BoxConstraints(minWidth: 16),
                decoration: BoxDecoration(
                  color: AppColors.danger,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.canvas, width: 1.5),
                ),
                alignment: Alignment.center,
                child: Text(
                  '$count',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    height: 1.3,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Demo controls.
///
/// Both safety scenarios fire on their own schedule, but a reviewer watching
/// live should not have to wait for them — these force each scenario on demand.
class _DemoMenu extends StatelessWidget {
  const _DemoMenu({
    required this.isRunning,
    required this.onRestart,
    required this.onSimulateOverspeeding,
    required this.onSimulateSignalLoss,
    required this.onToggleRunning,
  });

  final bool isRunning;
  final VoidCallback onRestart;
  final VoidCallback onSimulateOverspeeding;
  final VoidCallback onSimulateSignalLoss;
  final VoidCallback onToggleRunning;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      tooltip: 'Demo controls',
      icon: const Icon(Icons.more_vert_rounded, color: AppColors.inkSecondary),
      position: PopupMenuPosition.under,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      onSelected: (value) => switch (value) {
        'restart' => onRestart(),
        'overspeed' => onSimulateOverspeeding(),
        'signal' => onSimulateSignalLoss(),
        'toggle' => onToggleRunning(),
        _ => null,
      },
      itemBuilder: (context) => [
        PopupMenuItem(
          value: 'toggle',
          child: _MenuRow(
            icon: isRunning ? Icons.pause_rounded : Icons.play_arrow_rounded,
            label: isRunning ? 'Pause journey' : 'Resume journey',
          ),
        ),
        const PopupMenuItem(
          value: 'overspeed',
          child: _MenuRow(
            icon: Icons.speed_rounded,
            label: 'Simulate overspeeding',
          ),
        ),
        const PopupMenuItem(
          value: 'signal',
          child: _MenuRow(
            icon: Icons.location_disabled_rounded,
            label: 'Simulate location stopped',
          ),
        ),
        const PopupMenuDivider(),
        const PopupMenuItem(
          value: 'restart',
          child: _MenuRow(icon: Icons.replay_rounded, label: 'Restart journey'),
        ),
      ],
    );
  }
}

class _MenuRow extends StatelessWidget {
  const _MenuRow({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.inkSecondary),
        const SizedBox(width: 10),
        Text(label, style: const TextStyle(fontSize: 14)),
      ],
    );
  }
}
