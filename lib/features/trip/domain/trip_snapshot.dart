import '../../../core/geo/geo_point.dart';
import 'trip_status.dart';

/// An immutable reading of the journey at one instant.
///
/// This is the single value the simulator emits and the whole UI renders from.
/// Keeping it immutable means a rebuild can never observe a half-updated trip
/// (position from one tick, speed from the next), and it makes the safety
/// monitor trivial to unit test — feed it snapshots, assert on alerts.
class TripSnapshot {
  const TripSnapshot({
    required this.elapsed,
    required this.driverLocation,
    required this.headingDegrees,
    required this.speedKmh,
    required this.distanceTravelledMeters,
    required this.distanceRemainingMeters,
    required this.routeLengthMeters,
    required this.eta,
    required this.arrivalTime,
    required this.status,
  });

  /// Simulated journey time since pickup (not wall-clock time — the simulator
  /// runs faster than real time so a reviewer can watch a full trip).
  final Duration elapsed;

  final GeoPoint driverLocation;
  final double headingDegrees;
  final double speedKmh;
  final double distanceTravelledMeters;
  final double distanceRemainingMeters;
  final double routeLengthMeters;

  /// Estimated time remaining until drop-off.
  final Duration eta;

  /// Wall-clock time the child is expected to arrive, for the "by 3:42 PM" line.
  final DateTime arrivalTime;

  final TripStatus status;

  /// 0.0 at the school gate, 1.0 at the drop-off point.
  double get progress => routeLengthMeters <= 0
      ? 0
      : (distanceTravelledMeters / routeLengthMeters).clamp(0.0, 1.0);

  /// A stationary vehicle is normal at a junction and abnormal for minutes on
  /// end; the safety monitor decides which, this is just the raw fact.
  bool get isStationary => speedKmh < 1.0;
}
