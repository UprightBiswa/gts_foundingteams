import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../domain/trip_snapshot.dart';
import 'metric_tile.dart';

/// The three numbers a parent checks at a glance: when, how far, how fast.
class TripMetricsRow extends StatelessWidget {
  const TripMetricsRow({
    super.key,
    required this.snapshot,
    required this.accentColor,
    required this.isOverspeeding,
    required this.speedLimitKmh,
  });

  final TripSnapshot snapshot;
  final Color accentColor;
  final bool isOverspeeding;
  final double speedLimitKmh;

  @override
  Widget build(BuildContext context) {
    final etaText = snapshot.status.isFinished
        ? 'Done'
        : Formatters.duration(snapshot.eta).replaceAll(' min', '');

    // IntrinsicHeight gives the Row a bounded height so `stretch` can equalise
    // the three tiles. Without it the Row sits unbounded inside the ListView
    // and stretch resolves to an infinite constraint.
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: MetricTile(
              icon: Icons.schedule_rounded,
              label: 'Time to arrive',
              value: etaText,
              unit: snapshot.status.isFinished ? '' : 'min',
              accent: accentColor,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: MetricTile(
              icon: Icons.straighten_rounded,
              label: 'Distance left',
              value: Formatters.distance(
                snapshot.distanceRemainingMeters,
              ).split(' ').first,
              unit: Formatters.distance(
                snapshot.distanceRemainingMeters,
              ).split(' ').last,
              accent: accentColor,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: MetricTile(
              icon: Icons.speed_rounded,
              label: isOverspeeding
                  ? 'Limit ${speedLimitKmh.round()} km/h'
                  : 'Current speed',
              value: Formatters.speed(snapshot.speedKmh),
              unit: 'km/h',
              accent: isOverspeeding ? AppColors.danger : accentColor,
              isAlerting: isOverspeeding,
            ),
          ),
        ],
      ),
    );
  }
}
