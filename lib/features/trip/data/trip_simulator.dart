import 'dart:math' as math;

import '../../../core/geo/route_path.dart';
import '../domain/speed_keyframe.dart';
import '../domain/trip_snapshot.dart';
import '../domain/trip_status.dart';

/// A manual override injected by the demo controls, so the two safety
/// scenarios can be shown on demand instead of only on the scripted schedule.
enum _OverrideKind { speedBurst, signalLoss }

/// Turns a scripted speed profile into a stream of [TripSnapshot]s.
///
/// Design note: this class owns **no timer**. It exposes `advance(seconds)` and
/// is driven from outside, which means the whole journey — including both
/// safety scenarios — can be replayed instantly in a unit test without waiting
/// for wall-clock time.
///
/// Position is derived by integrating speed into "meters travelled" and then
/// resolving that distance against the route polyline, rather than hopping
/// between waypoints. That is what makes the movement look continuous and
/// keeps speed, distance and ETA consistent with each other by construction.
class TripSimulator {
  TripSimulator({
    required this.route,
    required this.speedProfile,
    this.speedLimitKmh = 50,
    DateTime Function() clock = DateTime.now,
  }) : _clock = clock;

  final RoutePath route;
  final List<SpeedKeyframe> speedProfile;

  /// Only used to shape the burst override; the safety rules live in the monitor.
  final double speedLimitKmh;

  final DateTime Function() _clock;

  double _tripSeconds = 0;
  double _distanceMeters = 0;
  double _currentSpeedKmh = 0;

  /// Exponential moving average of speed, used for a stable ETA. A raw
  /// instantaneous speed makes the ETA jitter on every tick, which reads as
  /// unreliable to a parent even when the underlying data is fine.
  double _averageSpeedKmh = 30;

  _OverrideKind? _overrideKind;
  double _overrideEndsAtSecond = 0;

  static const double _etaFloorKmh = 15;
  static const double _etaCeilingKmh = 70;
  static const double _emaAlpha = 0.08;

  bool get isComplete => _distanceMeters >= route.totalMeters;

  /// Advances the simulation by [deltaSeconds] of *simulated* journey time.
  TripSnapshot advance(double deltaSeconds) {
    if (!isComplete) {
      _tripSeconds += deltaSeconds;
      _currentSpeedKmh = _resolveSpeedKmh(_tripSeconds);
      _distanceMeters = math.min(
        route.totalMeters,
        _distanceMeters + (_currentSpeedKmh / 3.6) * deltaSeconds,
      );

      // The vehicle has arrived, so it is stopped — whatever the speed profile
      // says about the next second. Without this the final snapshot freezes at
      // the last cruising speed, and the screen reads "Arrived safely" beside a
      // live 33 km/h.
      if (_distanceMeters >= route.totalMeters) _currentSpeedKmh = 0;
    } else {
      _currentSpeedKmh = 0;
    }

    _averageSpeedKmh =
        _averageSpeedKmh * (1 - _emaAlpha) + _currentSpeedKmh * _emaAlpha;

    return snapshot;
  }

  /// The current reading, without advancing time.
  TripSnapshot get snapshot {
    final position = route.positionAt(_distanceMeters);
    final remaining = math.max(0.0, route.totalMeters - _distanceMeters);
    final eta = _estimateArrival(remaining);

    return TripSnapshot(
      elapsed: Duration(milliseconds: (_tripSeconds * 1000).round()),
      driverLocation: position.point,
      headingDegrees: position.headingDegrees,
      speedKmh: _currentSpeedKmh,
      distanceTravelledMeters: _distanceMeters,
      distanceRemainingMeters: remaining,
      routeLengthMeters: route.totalMeters,
      eta: eta,
      arrivalTime: _clock().add(eta),
      status: _resolveStatus(remaining),
    );
  }

  void reset() {
    _tripSeconds = 0;
    _distanceMeters = 0;
    _currentSpeedKmh = 0;
    _averageSpeedKmh = 30;
    _overrideKind = null;
    _overrideEndsAtSecond = 0;
  }

  /// Demo control: push the driver over the speed limit for a few seconds.
  void triggerSpeedBurst({double seconds = 14}) =>
      _applyOverride(_OverrideKind.speedBurst, seconds);

  /// Demo control: freeze the vehicle so the location-stopped rule fires.
  void triggerSignalLoss({double seconds = 45}) =>
      _applyOverride(_OverrideKind.signalLoss, seconds);

  void _applyOverride(_OverrideKind kind, double seconds) {
    _overrideKind = kind;
    _overrideEndsAtSecond = _tripSeconds + seconds;
  }

  double _resolveSpeedKmh(double second) {
    if (_overrideKind != null) {
      if (second < _overrideEndsAtSecond) {
        return switch (_overrideKind!) {
          _OverrideKind.speedBurst => speedLimitKmh + 18,
          _OverrideKind.signalLoss => 0,
        };
      }
      _overrideKind = null;
    }
    return _interpolateProfile(second);
  }

  /// Linear interpolation across the keyframe table, holding the end values.
  double _interpolateProfile(double second) {
    if (speedProfile.isEmpty) return 0;
    if (second <= speedProfile.first.second) return speedProfile.first.speedKmh;

    for (var i = 0; i < speedProfile.length - 1; i++) {
      final current = speedProfile[i];
      final next = speedProfile[i + 1];
      if (second <= next.second) {
        final span = next.second - current.second;
        if (span <= 0) return next.speedKmh;
        final t = (second - current.second) / span;
        return current.speedKmh + (next.speedKmh - current.speedKmh) * t;
      }
    }
    return speedProfile.last.speedKmh;
  }

  Duration _estimateArrival(double remainingMeters) {
    if (remainingMeters <= 0) return Duration.zero;

    // Clamping keeps the ETA meaningful while the vehicle is stopped: it stops
    // counting down rather than diverging to infinity, and the `delayed` status
    // is what actually communicates the problem to the parent.
    final referenceKmh = _averageSpeedKmh.clamp(_etaFloorKmh, _etaCeilingKmh);
    final seconds = remainingMeters / (referenceKmh / 3.6);
    return Duration(seconds: seconds.round());
  }

  TripStatus _resolveStatus(double remainingMeters) {
    if (remainingMeters <= 0.5) return TripStatus.completed;
    if (_distanceMeters < 60) return TripStatus.pickedUp;
    if (remainingMeters < 350) return TripStatus.arriving;
    return TripStatus.enRoute;
  }
}
