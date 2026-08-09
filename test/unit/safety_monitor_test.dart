import 'package:flutter_test/flutter_test.dart';
import 'package:gts_foundingteams/core/geo/geo_point.dart';
import 'package:gts_foundingteams/features/safety/application/safety_monitor.dart';
import 'package:gts_foundingteams/features/safety/domain/safety_alert.dart';
import 'package:gts_foundingteams/features/trip/domain/trip_snapshot.dart';
import 'package:gts_foundingteams/features/trip/domain/trip_status.dart';

/// The monitor consumes snapshots and nothing else, so every rule — including
/// the hysteresis that stops alerts flapping — is verifiable with synthetic
/// data and no timers.
void main() {
  const start = GeoPoint(51.2450, -0.5890);

  /// Moves [meters] north of [start] — enough to exercise the movement window.
  GeoPoint northOf(double meters) =>
      GeoPoint(start.latitude + meters / 111320, start.longitude);

  TripSnapshot snapshot({
    required double atSecond,
    required double speedKmh,
    required GeoPoint location,
    TripStatus status = TripStatus.enRoute,
  }) {
    return TripSnapshot(
      elapsed: Duration(milliseconds: (atSecond * 1000).round()),
      driverLocation: location,
      headingDegrees: 0,
      speedKmh: speedKmh,
      distanceTravelledMeters: 500,
      distanceRemainingMeters: 1500,
      routeLengthMeters: 2000,
      eta: const Duration(minutes: 4),
      arrivalTime: DateTime(2026, 8, 9, 15, 42),
      status: status,
    );
  }

  group('overspeeding', () {
    test('does not fire on a brief burst above the limit', () {
      final monitor = SafetyMonitor();

      // Two seconds over the limit — under the four-second sustain threshold.
      for (var second = 1; second <= 3; second++) {
        monitor.evaluate(
          snapshot(
            atSecond: second.toDouble(),
            speedKmh: 62,
            location: northOf(second * 15),
          ),
        );
      }

      expect(monitor.activeAlerts, isEmpty);
    });

    test('fires once the limit is exceeded for the sustain window', () {
      final monitor = SafetyMonitor();

      for (var second = 1; second <= 6; second++) {
        monitor.evaluate(
          snapshot(
            atSecond: second.toDouble(),
            speedKmh: 62,
            location: northOf(second * 15),
          ),
        );
      }

      expect(monitor.activeAlerts, hasLength(1));
      final alert = monitor.activeAlerts.single;
      expect(alert.type, SafetyAlertType.overspeeding);
      expect(alert.severity, SafetyAlertSeverity.critical);
      expect(alert.detail, contains('62'));
    });

    test('stays raised in the hysteresis band between clear and limit', () {
      final monitor = SafetyMonitor();
      var second = 1;

      for (; second <= 6; second++) {
        monitor.evaluate(
          snapshot(
            atSecond: second.toDouble(),
            speedKmh: 62,
            location: northOf(second * 15),
          ),
        );
      }
      expect(monitor.activeAlerts, hasLength(1));

      // 48 km/h is under the 50 limit but above the 45 clear threshold, so the
      // alert must neither re-fire nor resolve.
      for (var i = 0; i < 15; i++, second++) {
        monitor.evaluate(
          snapshot(
            atSecond: second.toDouble(),
            speedKmh: 48,
            location: northOf(second * 13),
          ),
        );
      }

      expect(monitor.activeAlerts, hasLength(1));
      expect(monitor.alerts, hasLength(1));
    });

    test('resolves after sustained driving below the clear threshold', () {
      final monitor = SafetyMonitor();
      var second = 1;

      for (; second <= 6; second++) {
        monitor.evaluate(
          snapshot(
            atSecond: second.toDouble(),
            speedKmh: 62,
            location: northOf(second * 15),
          ),
        );
      }

      SafetyEvaluation? resolution;
      for (var i = 0; i < 10; i++, second++) {
        final result = monitor.evaluate(
          snapshot(
            atSecond: second.toDouble(),
            speedKmh: 32,
            location: northOf(second * 9),
          ),
        );
        if (result.resolved.isNotEmpty) resolution = result;
      }

      expect(resolution, isNotNull);
      expect(monitor.activeAlerts, isEmpty);
      // The alert is kept in the log rather than deleted.
      expect(monitor.alerts, hasLength(1));
      expect(monitor.alerts.single.resolvedAt, isNotNull);
      expect(monitor.alerts.single.isActive, isFalse);
    });
  });

  group('location stopped', () {
    test('does not fire before the movement window has elapsed', () {
      final monitor = SafetyMonitor();

      for (var second = 1; second <= 15; second++) {
        monitor.evaluate(
          snapshot(atSecond: second.toDouble(), speedKmh: 0, location: start),
        );
      }

      expect(monitor.activeAlerts, isEmpty);
    });

    test('fires when the vehicle has not moved across the window', () {
      final monitor = SafetyMonitor();

      for (var second = 1; second <= 22; second++) {
        monitor.evaluate(
          snapshot(atSecond: second.toDouble(), speedKmh: 0, location: start),
        );
      }

      expect(monitor.activeAlerts, hasLength(1));
      final alert = monitor.activeAlerts.single;
      expect(alert.type, SafetyAlertType.locationStopped);
      expect(alert.severity, SafetyAlertSeverity.warning);
    });

    test('resolves once the vehicle moves again', () {
      final monitor = SafetyMonitor();
      var second = 1;

      for (; second <= 22; second++) {
        monitor.evaluate(
          snapshot(atSecond: second.toDouble(), speedKmh: 0, location: start),
        );
      }
      expect(monitor.activeAlerts, hasLength(1));

      final result = monitor.evaluate(
        snapshot(
          atSecond: (++second).toDouble(),
          speedKmh: 30,
          location: northOf(60),
        ),
      );

      expect(result.resolved, hasLength(1));
      expect(monitor.activeAlerts, isEmpty);
    });

    test('a moving vehicle never triggers the rule', () {
      final monitor = SafetyMonitor();

      for (var second = 1; second <= 60; second++) {
        monitor.evaluate(
          snapshot(
            atSecond: second.toDouble(),
            speedKmh: 34,
            location: northOf(second * 9.4),
          ),
        );
      }

      expect(monitor.alerts, isEmpty);
    });
  });

  test('a parked vehicle after drop-off is not an incident', () {
    final monitor = SafetyMonitor();

    // Raise a stall alert first...
    for (var second = 1; second <= 22; second++) {
      monitor.evaluate(
        snapshot(atSecond: second.toDouble(), speedKmh: 0, location: start),
      );
    }
    expect(monitor.activeAlerts, hasLength(1));

    // ...then arrive. Everything open should clear, and nothing new should fire.
    for (var second = 23; second <= 60; second++) {
      monitor.evaluate(
        snapshot(
          atSecond: second.toDouble(),
          speedKmh: 0,
          location: start,
          status: TripStatus.completed,
        ),
      );
    }

    expect(monitor.activeAlerts, isEmpty);
    expect(monitor.alerts, hasLength(1));
  });

  test('reset clears the log and the rule state', () {
    final monitor = SafetyMonitor();
    for (var second = 1; second <= 22; second++) {
      monitor.evaluate(
        snapshot(atSecond: second.toDouble(), speedKmh: 0, location: start),
      );
    }
    expect(monitor.alerts, isNotEmpty);

    monitor.reset();

    expect(monitor.alerts, isEmpty);
    expect(monitor.activeAlerts, isEmpty);
    expect(monitor.primaryAlert, isNull);
  });

  test('critical alerts outrank warnings in the banner slot', () {
    final monitor = SafetyMonitor();
    var second = 1;

    // Stall first (warning)...
    for (; second <= 22; second++) {
      monitor.evaluate(
        snapshot(atSecond: second.toDouble(), speedKmh: 0, location: start),
      );
    }
    expect(monitor.primaryAlert?.type, SafetyAlertType.locationStopped);

    // ...then overspeed (critical) while the stall is still open. Position is
    // held so the stall rule does not clear.
    for (var i = 0; i < 6; i++, second++) {
      monitor.evaluate(
        snapshot(atSecond: second.toDouble(), speedKmh: 70, location: start),
      );
    }

    expect(monitor.activeAlerts, hasLength(2));
    expect(monitor.primaryAlert?.type, SafetyAlertType.overspeeding);
  });
}
