import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../safety/application/safety_providers.dart';
import '../../safety/domain/safety_alert.dart';
import '../../safety/presentation/alert_visuals.dart';
import '../../safety/presentation/safety_alert_banner.dart';
import '../../safety/presentation/safety_status_card.dart';
import '../../sos/presentation/sos_action_bar.dart';
import '../application/trip_providers.dart';
import '../application/trip_state.dart';
import '../domain/trip_status.dart';
import 'widgets/driver_card.dart';
import 'widgets/journey_progress_card.dart';
import 'widgets/map_overlays.dart';
import 'widgets/trip_header.dart';
import 'widgets/trip_map_view.dart';
import 'widgets/trip_metrics_row.dart';

/// The single screen this prototype is about: a parent watching their child
/// travel home.
///
/// Layout intent — the header and the safety banner are pinned outside the
/// scroll view, everything else scrolls. A safety alert that can be scrolled
/// out of sight is an alert that gets missed, and the SOS button that a parent
/// reaches for in a panic must never require a scroll to find.
class ActiveTripScreen extends ConsumerWidget {
  const ActiveTripScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    _listenForSafetyEvents(context, ref);
    _listenForArrival(context, ref);

    final trip = ref.watch(tripControllerProvider);
    final rules = ref.watch(safetyRulesProvider);
    final route = ref.watch(routeProvider);
    final driver = ref.watch(driverProvider);
    final school = ref.watch(schoolProvider);
    final dropOff = ref.watch(dropOffProvider);

    final accent = AlertVisuals.accentFor(trip.primaryAlert);
    final isOverspeeding = trip.snapshot.speedKmh > rules.speedLimitKmh;
    final isStalled = trip.alerts.any(
      (alert) =>
          alert.isActive && alert.type == SafetyAlertType.locationStopped,
    );

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            TripHeader(
              onOpenAlerts: () => context.push('/alerts'),
              onRestart: () =>
                  ref.read(tripControllerProvider.notifier).restart(),
              onSimulateOverspeeding: () => ref
                  .read(tripControllerProvider.notifier)
                  .simulateOverspeeding(),
              onSimulateSignalLoss: () => ref
                  .read(tripControllerProvider.notifier)
                  .simulateSignalLoss(),
              onToggleRunning: () =>
                  ref.read(tripControllerProvider.notifier).toggleRunning(),
            ),
            SafetyAlertBanner(
              alert: trip.primaryAlert,
              onTap: () => context.push('/alerts'),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                children: [
                  _MapSection(
                    trip: trip,
                    accent: accent,
                    routeTotalMeters: route.totalMeters,
                  ),
                  const SizedBox(height: 14),
                  JourneyProgressCard(
                    origin: school,
                    destination: dropOff,
                    progress: trip.snapshot.progress,
                    elapsed: trip.snapshot.elapsed,
                    arrivalTime: trip.snapshot.arrivalTime,
                    accentColor: accent,
                    isComplete: trip.status.isFinished,
                  ),
                  const SizedBox(height: 12),
                  TripMetricsRow(
                    snapshot: trip.snapshot,
                    accentColor: accent,
                    isOverspeeding: isOverspeeding,
                    speedLimitKmh: rules.speedLimitKmh,
                  ),
                  const SizedBox(height: 12),
                  DriverCard(
                    driver: driver,
                    onContact: (action) => _showSnack(context, '$action…'),
                  ),
                  const SizedBox(height: 12),
                  SafetyStatusCard(
                    alerts: trip.alerts,
                    isOverspeeding: isOverspeeding,
                    isStalled: isStalled,
                    onViewHistory: () => context.push('/alerts'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const SosActionBar(),
    );
  }

  /// Fires haptics the moment an alert is raised, and confirms out loud when
  /// one clears — a banner silently disappearing leaves the parent unsure
  /// whether it was resolved or they imagined it.
  void _listenForSafetyEvents(BuildContext context, WidgetRef ref) {
    ref.listen<TripState>(tripControllerProvider, (previous, next) {
      if (previous == null || previous.eventSequence == next.eventSequence) {
        return;
      }

      final raised = next.lastRaised;
      if (raised != null && raised.id != previous.lastRaised?.id) {
        HapticFeedback.heavyImpact();
        return;
      }

      final resolved = next.lastResolved;
      if (resolved != null && resolved.id != previous.lastResolved?.id) {
        HapticFeedback.lightImpact();
        _showSnack(context, switch (resolved.type) {
          SafetyAlertType.overspeeding => 'Speed is back within the limit',
          SafetyAlertType.locationStopped => 'The vehicle is moving again',
        }, icon: Icons.check_circle_rounded);
      }
    });
  }

  void _listenForArrival(BuildContext context, WidgetRef ref) {
    ref.listen<TripStatus>(
      tripControllerProvider.select((state) => state.status),
      (previous, next) {
        if (previous == next || !next.isFinished) return;
        HapticFeedback.mediumImpact();
        _showSnack(
          context,
          'Dropped off safely at home',
          icon: Icons.celebration_rounded,
        );
      },
    );
  }

  void _showSnack(BuildContext context, String message, {IconData? icon}) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          duration: const Duration(seconds: 3),
          content: Row(
            children: [
              if (icon != null) ...[
                Icon(icon, size: 18, color: AppColors.safe),
                const SizedBox(width: 10),
              ],
              Expanded(child: Text(message)),
            ],
          ),
        ),
      );
  }
}

class _MapSection extends StatelessWidget {
  const _MapSection({
    required this.trip,
    required this.accent,
    required this.routeTotalMeters,
  });

  final TripState trip;
  final Color accent;
  final double routeTotalMeters;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 290,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F0C1B33),
            blurRadius: 18,
            offset: Offset(0, 6),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Consumer(
            builder: (context, ref, _) => TripMapView(
              route: ref.watch(routeProvider),
              travelledMeters: trip.snapshot.distanceTravelledMeters,
              driverLocation: trip.snapshot.driverLocation,
              headingDegrees: trip.snapshot.headingDegrees,
              accentColor: accent,
              isStationary: trip.snapshot.isStationary,
            ),
          ),
          Positioned(
            top: 12,
            left: 12,
            child: MapStatusChip(status: trip.status),
          ),
          Positioned(
            top: 12,
            right: 12,
            child: LiveIndicator(isRunning: trip.isRunning),
          ),
          Positioned(
            bottom: 12,
            left: 12,
            child: MapProgressChip(
              travelledLabel: Formatters.distance(
                trip.snapshot.distanceTravelledMeters,
              ),
              totalLabel: Formatters.distance(routeTotalMeters),
            ),
          ),
        ],
      ),
    );
  }
}
