import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../safety/application/safety_monitor.dart';
import '../../safety/application/safety_providers.dart';
import '../../safety/domain/safety_alert.dart';
import '../data/mock_trip_data.dart';
import '../data/trip_simulator.dart';
import '../domain/trip_snapshot.dart';
import '../domain/trip_status.dart';
import 'trip_state.dart';

/// Orchestrates the journey: drives the simulator on a timer, feeds each
/// snapshot to the safety monitor, and publishes the combined result.
///
/// The two services underneath are plain Dart and timer-free. This class is the
/// only place that knows about wall-clock time, which keeps the interesting
/// logic testable and confines lifecycle concerns (start, stop, dispose) to a
/// single, small surface.
class TripController extends Notifier<TripState> {
  late final TripSimulator _simulator;
  late final SafetyMonitor _monitor;
  Timer? _ticker;

  @override
  TripState build() {
    final rules = ref.read(safetyRulesProvider);
    _simulator = TripSimulator(
      route: MockTripData.route,
      speedProfile: MockTripData.speedProfile,
      speedLimitKmh: rules.speedLimitKmh,
    );
    _monitor = SafetyMonitor(rules: rules);

    ref.onDispose(_stopTicker);

    // Safe to schedule here: `Timer.periodic` first fires after the interval,
    // well after `build` has returned its initial state.
    _startTicker();

    return TripState(
      snapshot: _simulator.snapshot,
      status: _simulator.snapshot.status,
      alerts: const [],
      primaryAlert: null,
      isRunning: true,
    );
  }

  void _startTicker() {
    _ticker?.cancel();
    _ticker = Timer.periodic(MockTripData.tickInterval, (_) => _tick());
  }

  void _stopTicker() {
    _ticker?.cancel();
    _ticker = null;
  }

  void _tick() {
    final snapshot = _simulator.advance(MockTripData.simulatedSecondsPerTick);
    final evaluation = _monitor.evaluate(snapshot);

    state = _compose(snapshot, evaluation, isRunning: !_simulator.isComplete);

    if (_simulator.isComplete) _stopTicker();
  }

  TripState _compose(
    TripSnapshot snapshot,
    SafetyEvaluation evaluation, {
    required bool isRunning,
  }) {
    return TripState(
      snapshot: snapshot,
      status: _displayStatus(snapshot),
      alerts: _monitor.alerts,
      primaryAlert: _monitor.primaryAlert,
      isRunning: isRunning,
      lastRaised: evaluation.raised.isNotEmpty
          ? evaluation.raised.first
          : state.lastRaised,
      lastResolved: evaluation.resolved.isNotEmpty
          ? evaluation.resolved.first
          : state.lastResolved,
      eventSequence: evaluation.hasChanges
          ? state.eventSequence + 1
          : state.eventSequence,
    );
  }

  /// A stopped vehicle only becomes "Delayed" once the monitor has confirmed
  /// it is not just a red light.
  TripStatus _displayStatus(TripSnapshot snapshot) {
    if (snapshot.status.isFinished) return TripStatus.completed;

    final stalled = _monitor.activeAlerts.any(
      (alert) => alert.type == SafetyAlertType.locationStopped,
    );
    return stalled ? TripStatus.delayed : snapshot.status;
  }

  /// Pause/resume the simulated feed — handy while narrating a demo.
  void toggleRunning() {
    if (_simulator.isComplete) return;
    if (state.isRunning) {
      _stopTicker();
      state = state.copyWith(isRunning: false);
    } else {
      _startTicker();
      state = state.copyWith(isRunning: true);
    }
  }

  void restart() {
    _simulator.reset();
    _monitor.reset();
    _startTicker();
    state = TripState(
      snapshot: _simulator.snapshot,
      status: _simulator.snapshot.status,
      alerts: const [],
      primaryAlert: null,
      isRunning: true,
    );
  }

  /// Demo control: force the overspeeding scenario now rather than waiting for
  /// the scripted moment. Keeps a live walkthrough on the reviewer's schedule.
  void simulateOverspeeding() {
    if (_simulator.isComplete) return;
    _simulator.triggerSpeedBurst();
    if (!state.isRunning) toggleRunning();
  }

  /// Demo control: force the location-stopped scenario now.
  void simulateSignalLoss() {
    if (_simulator.isComplete) return;
    _simulator.triggerSignalLoss();
    if (!state.isRunning) toggleRunning();
  }
}
