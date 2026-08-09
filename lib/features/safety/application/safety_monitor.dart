import '../../../core/geo/geo_point.dart';
import '../../../core/geo/route_path.dart';
import '../../trip/domain/trip_snapshot.dart';
import '../domain/safety_alert.dart';

/// Tunable thresholds for the safety rules.
class SafetyRules {
  const SafetyRules({
    this.speedLimitKmh = 50,
    this.speedClearKmh = 45,
    this.overspeedSustain = const Duration(seconds: 4),
    this.overspeedClearAfter = const Duration(seconds: 6),
    this.stallWindow = const Duration(seconds: 20),
    this.stallDistanceMeters = 8,
  });

  /// Speed above which the driver counts as overspeeding.
  final double speedLimitKmh;

  /// Speed the driver must fall back below before the alert clears. The gap
  /// between this and [speedLimitKmh] is deliberate hysteresis — without it, a
  /// driver hovering at exactly 50 km/h would flap the alert on and off every
  /// tick, which is how parents learn to ignore alerts.
  final double speedClearKmh;

  /// How long the limit must be exceeded before alerting, so a brief
  /// overtaking manoeuvre does not panic anyone.
  final Duration overspeedSustain;

  /// How long the driver must stay below [speedClearKmh] before clearing.
  final Duration overspeedClearAfter;

  /// Rolling window used to decide the vehicle has stopped moving.
  final Duration stallWindow;

  /// Movement below this distance across [stallWindow] counts as stopped.
  final double stallDistanceMeters;
}

class _PositionSample {
  const _PositionSample(this.atSeconds, this.point);

  final double atSeconds;
  final GeoPoint point;
}

/// Watches the trip feed and raises/resolves safety alerts.
///
/// Deliberately knows nothing about widgets or timers: it consumes
/// [TripSnapshot]s and returns alerts, so the rules can be verified by pushing
/// synthetic snapshots through it in a unit test.
class SafetyMonitor {
  SafetyMonitor({
    this.rules = const SafetyRules(),
    DateTime Function() clock = DateTime.now,
  }) : _clock = clock;

  final SafetyRules rules;
  final DateTime Function() _clock;

  final List<SafetyAlert> _alerts = [];
  final List<_PositionSample> _positionHistory = [];

  double _overLimitSeconds = 0;
  double _underLimitSeconds = 0;
  double? _lastElapsedSeconds;
  int _idCounter = 0;

  /// Full log, newest first.
  List<SafetyAlert> get alerts => List.unmodifiable(_alerts);

  List<SafetyAlert> get activeAlerts =>
      _alerts.where((alert) => alert.isActive).toList(growable: false);

  /// The alert the banner should show: critical outranks warning, and within a
  /// severity the most recent wins.
  SafetyAlert? get primaryAlert {
    final active = activeAlerts;
    if (active.isEmpty) return null;
    active.sort((a, b) {
      final bySeverity = b.severity.index.compareTo(a.severity.index);
      if (bySeverity != 0) return bySeverity;
      return b.raisedAt.compareTo(a.raisedAt);
    });
    return active.first;
  }

  SafetyEvaluation evaluate(TripSnapshot snapshot) {
    final elapsedSeconds = snapshot.elapsed.inMilliseconds / 1000;
    final delta = _lastElapsedSeconds == null
        ? 0.0
        : elapsedSeconds - _lastElapsedSeconds!;
    _lastElapsedSeconds = elapsedSeconds;

    // Once the child is dropped off, a parked vehicle is the expected outcome,
    // not an incident. Clear anything still open and stop evaluating.
    if (snapshot.status.isFinished) {
      return _resolveAll();
    }

    final raised = <SafetyAlert>[];
    final resolved = <SafetyAlert>[];

    _evaluateOverspeeding(snapshot, delta, raised, resolved);
    _evaluateStall(snapshot, elapsedSeconds, raised, resolved);

    return raised.isEmpty && resolved.isEmpty
        ? SafetyEvaluation.none
        : SafetyEvaluation(raised: raised, resolved: resolved);
  }

  void reset() {
    _alerts.clear();
    _positionHistory.clear();
    _overLimitSeconds = 0;
    _underLimitSeconds = 0;
    _lastElapsedSeconds = null;
    _idCounter = 0;
  }

  void _evaluateOverspeeding(
    TripSnapshot snapshot,
    double delta,
    List<SafetyAlert> raised,
    List<SafetyAlert> resolved,
  ) {
    if (snapshot.speedKmh > rules.speedLimitKmh) {
      _overLimitSeconds += delta;
      _underLimitSeconds = 0;
    } else if (snapshot.speedKmh <= rules.speedClearKmh) {
      _underLimitSeconds += delta;
      _overLimitSeconds = 0;
    }
    // Between speedClearKmh and speedLimitKmh neither timer moves: that dead
    // zone is what stops the alert flapping.

    final active = _activeOfType(SafetyAlertType.overspeeding);

    if (active == null) {
      if (_overLimitSeconds >= rules.overspeedSustain.inSeconds) {
        raised.add(
          _raise(
            type: SafetyAlertType.overspeeding,
            severity: SafetyAlertSeverity.critical,
            headline: 'Driver is going too fast',
            detail:
                'Reached ${snapshot.speedKmh.round()} km/h where the limit is '
                '${rules.speedLimitKmh.round()} km/h.',
            advice:
                'GTS has flagged this to the driver automatically. Call them '
                'if the speed does not come down.',
            tripTime: snapshot.elapsed,
          ),
        );
      }
    } else if (_underLimitSeconds >= rules.overspeedClearAfter.inSeconds) {
      resolved.add(_resolve(active));
    }
  }

  void _evaluateStall(
    TripSnapshot snapshot,
    double elapsedSeconds,
    List<SafetyAlert> raised,
    List<SafetyAlert> resolved,
  ) {
    _positionHistory.add(
      _PositionSample(elapsedSeconds, snapshot.driverLocation),
    );

    final windowStart = elapsedSeconds - rules.stallWindow.inSeconds;
    // Keep one sample older than the window so the span stays >= the window.
    while (_positionHistory.length > 2 &&
        _positionHistory[1].atSeconds < windowStart) {
      _positionHistory.removeAt(0);
    }

    final oldest = _positionHistory.first;
    final spansWindow =
        elapsedSeconds - oldest.atSeconds >= rules.stallWindow.inSeconds;
    final movedMeters = Geo.distanceMeters(
      oldest.point,
      snapshot.driverLocation,
    );

    final active = _activeOfType(SafetyAlertType.locationStopped);

    if (active == null) {
      if (spansWindow && movedMeters < rules.stallDistanceMeters) {
        raised.add(
          _raise(
            type: SafetyAlertType.locationStopped,
            severity: SafetyAlertSeverity.warning,
            headline: 'Vehicle has stopped moving',
            detail:
                'No movement for ${rules.stallWindow.inSeconds} seconds at the '
                'current location.',
            advice:
                'This is often traffic or a weak signal. Message the driver if '
                'it continues for a few more minutes.',
            tripTime: snapshot.elapsed,
          ),
        );
      }
    } else if (movedMeters >= rules.stallDistanceMeters * 2) {
      resolved.add(_resolve(active));
    }
  }

  SafetyEvaluation _resolveAll() {
    final resolved = activeAlerts.map(_resolve).toList(growable: false);
    return resolved.isEmpty
        ? SafetyEvaluation.none
        : SafetyEvaluation(raised: const [], resolved: resolved);
  }

  SafetyAlert? _activeOfType(SafetyAlertType type) {
    for (final alert in _alerts) {
      if (alert.type == type && alert.isActive) return alert;
    }
    return null;
  }

  SafetyAlert _raise({
    required SafetyAlertType type,
    required SafetyAlertSeverity severity,
    required String headline,
    required String detail,
    required String advice,
    required Duration tripTime,
  }) {
    final alert = SafetyAlert(
      id: '${type.name}-${_idCounter++}',
      type: type,
      severity: severity,
      headline: headline,
      detail: detail,
      advice: advice,
      raisedAt: _clock(),
      raisedAtTripTime: tripTime,
    );
    _alerts.insert(0, alert);
    return alert;
  }

  SafetyAlert _resolve(SafetyAlert alert) {
    final index = _alerts.indexWhere((candidate) => candidate.id == alert.id);
    final resolved = alert.resolve(_clock());
    if (index != -1) _alerts[index] = resolved;
    return resolved;
  }
}
