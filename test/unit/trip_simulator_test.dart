import 'package:flutter_test/flutter_test.dart';
import 'package:gts_foundingteams/features/trip/data/mock_trip_data.dart';
import 'package:gts_foundingteams/features/trip/data/trip_simulator.dart';
import 'package:gts_foundingteams/features/trip/domain/trip_snapshot.dart';
import 'package:gts_foundingteams/features/trip/domain/trip_status.dart';

/// The simulator owns no timer, so a full journey replays instantly here.
void main() {
  TripSimulator buildSimulator() => TripSimulator(
    route: MockTripData.route,
    speedProfile: MockTripData.speedProfile,
  );

  List<TripSnapshot> runJourney(TripSimulator simulator, {int maxTicks = 900}) {
    final snapshots = <TripSnapshot>[];
    for (var i = 0; i < maxTicks; i++) {
      snapshots.add(simulator.advance(1));
      if (simulator.isComplete) break;
    }
    return snapshots;
  }

  test('starts stationary at the school gate', () {
    final simulator = buildSimulator();
    final snapshot = simulator.snapshot;

    expect(snapshot.distanceTravelledMeters, 0);
    expect(snapshot.driverLocation, MockTripData.route.origin);
    expect(snapshot.speedKmh, 0);
    expect(snapshot.progress, 0);
  });

  test('completes the journey and reports arrival', () {
    final simulator = buildSimulator();
    final snapshots = runJourney(simulator);

    expect(simulator.isComplete, isTrue);
    expect(snapshots.last.status, TripStatus.completed);
    expect(snapshots.last.distanceRemainingMeters, closeTo(0, 0.5));
    expect(snapshots.last.progress, closeTo(1, 0.001));
    expect(snapshots.last.driverLocation, MockTripData.route.destination);
  });

  test('the vehicle reads as stopped once it has arrived', () {
    final simulator = buildSimulator();
    final snapshots = runJourney(simulator);

    expect(snapshots.last.speedKmh, 0);
    expect(snapshots.last.isStationary, isTrue);

    // And it stays stopped if the feed keeps ticking after arrival.
    expect(simulator.advance(1).speedKmh, 0);
  });

  test('distance travelled never decreases', () {
    final snapshots = runJourney(buildSimulator());

    var previous = 0.0;
    for (final snapshot in snapshots) {
      expect(snapshot.distanceTravelledMeters, greaterThanOrEqualTo(previous));
      previous = snapshot.distanceTravelledMeters;
    }
  });

  test('the scripted profile breaches the speed limit at some point', () {
    final snapshots = runJourney(buildSimulator());
    expect(snapshots.any((snapshot) => snapshot.speedKmh > 50), isTrue);
  });

  test(
    'the scripted profile brings the vehicle to a full stop mid-journey',
    () {
      final snapshots = runJourney(buildSimulator());
      final stopped = snapshots.where(
        (snapshot) =>
            snapshot.isStationary &&
            snapshot.distanceTravelledMeters > 100 &&
            !snapshot.status.isFinished,
      );
      expect(stopped, isNotEmpty);
    },
  );

  test('ETA stays finite and bounded while the vehicle is stopped', () {
    final snapshots = runJourney(buildSimulator());
    final whileStopped = snapshots.where(
      (snapshot) => snapshot.isStationary && !snapshot.status.isFinished,
    );

    for (final snapshot in whileStopped) {
      expect(snapshot.eta.inMinutes, lessThan(60));
      expect(snapshot.eta, greaterThan(Duration.zero));
    }
  });

  test(
    'the speed burst override pushes the driver over the limit on demand',
    () {
      final simulator = buildSimulator();
      simulator.advance(1);
      simulator.triggerSpeedBurst();

      final snapshot = simulator.advance(1);
      expect(snapshot.speedKmh, greaterThan(50));
    },
  );

  test('the signal loss override freezes the vehicle on demand', () {
    final simulator = buildSimulator();
    for (var i = 0; i < 30; i++) {
      simulator.advance(1);
    }
    simulator.triggerSignalLoss();

    final before = simulator.advance(1);
    final after = simulator.advance(5);

    expect(after.speedKmh, 0);
    expect(
      after.distanceTravelledMeters,
      closeTo(before.distanceTravelledMeters, 0.001),
    );
  });

  test('reset returns the simulator to the school gate', () {
    final simulator = buildSimulator();
    runJourney(simulator);
    simulator.reset();

    expect(simulator.isComplete, isFalse);
    expect(simulator.snapshot.distanceTravelledMeters, 0);
    expect(simulator.snapshot.driverLocation, MockTripData.route.origin);
  });
}
