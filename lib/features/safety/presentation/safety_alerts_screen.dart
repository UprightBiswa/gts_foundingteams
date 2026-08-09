import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/gts_card.dart';
import '../../trip/application/trip_providers.dart';
import '../domain/safety_alert.dart';
import 'alert_visuals.dart';

/// The full alert log for the journey — active and already-resolved.
///
/// Resolved alerts are kept rather than discarded: "it happened and then it
/// stopped" is the answer to the question a parent asks after the fact, and
/// deleting the record would leave them with only a vague memory of a banner.
class SafetyAlertsScreen extends ConsumerWidget {
  const SafetyAlertsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final alerts = ref.watch(
      tripControllerProvider.select((state) => state.alerts),
    );
    final child = ref.watch(childProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Safety alerts',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        ),
      ),
      body: alerts.isEmpty
          ? _EmptyState(childName: child.firstName)
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
              itemCount: alerts.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, index) => _AlertTile(alert: alerts[index]),
            ),
    );
  }
}

class _AlertTile extends StatelessWidget {
  const _AlertTile({required this.alert});

  final SafetyAlert alert;

  @override
  Widget build(BuildContext context) {
    final color = alert.isActive
        ? AlertVisuals.color(alert.severity)
        : AppColors.inkMuted;

    return GtsCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: alert.isActive
                      ? AlertVisuals.softColor(alert.severity)
                      : AppColors.canvas,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  AlertVisuals.icon(alert.type),
                  size: 19,
                  color: color,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      alert.headline,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.2,
                        color: alert.isActive
                            ? AppColors.ink
                            : AppColors.inkSecondary,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      alert.detail,
                      style: const TextStyle(
                        fontSize: 13,
                        height: 1.35,
                        color: AppColors.inkSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              GtsPill(
                label: alert.isActive ? 'Active' : 'Resolved',
                dense: true,
                color: alert.isActive ? color : AppColors.safe,
                background: alert.isActive
                    ? AlertVisuals.softColor(alert.severity)
                    : AppColors.safeSoft,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
            decoration: BoxDecoration(
              color: AppColors.canvas,
              borderRadius: BorderRadius.circular(11),
            ),
            child: Text(
              alert.advice,
              style: const TextStyle(
                fontSize: 12.5,
                height: 1.4,
                color: AppColors.inkSecondary,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(
                Icons.schedule_rounded,
                size: 13,
                color: AppColors.inkMuted,
              ),
              const SizedBox(width: 5),
              Text(
                'Raised at ${Formatters.clockTime(alert.raisedAt)} · '
                '${Formatters.stopwatch(alert.raisedAtTripTime)} into the trip',
                style: const TextStyle(
                  fontSize: 11.5,
                  color: AppColors.inkMuted,
                ),
              ),
            ],
          ),
          if (alert.resolvedAt != null) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(
                  Icons.check_circle_outline_rounded,
                  size: 13,
                  color: AppColors.safe,
                ),
                const SizedBox(width: 5),
                Text(
                  'Resolved at ${Formatters.clockTime(alert.resolvedAt!)}',
                  style: const TextStyle(
                    fontSize: 11.5,
                    color: AppColors.safe,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.childName});

  final String childName;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: const BoxDecoration(
                color: AppColors.safeSoft,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.verified_user_outlined,
                size: 34,
                color: AppColors.safe,
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'No safety alerts',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            Text(
              "$childName's journey has been normal so far. We'll alert you the "
              'moment anything changes.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                height: 1.45,
                color: AppColors.inkMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
