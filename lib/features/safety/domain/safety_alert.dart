/// The safety scenarios the prototype detects.
enum SafetyAlertType {
  overspeeding('Overspeeding'),
  locationStopped('Location stopped');

  const SafetyAlertType(this.label);

  final String label;
}

/// How loudly the parent should be interrupted.
///
/// `warning` is recoverable and self-resolving (traffic, a brief signal drop);
/// `critical` means the parent should consider acting now.
enum SafetyAlertSeverity { warning, critical }

/// A single safety event raised during the journey.
///
/// Alerts are immutable and are *resolved* by replacing them, so the alert log
/// keeps a full history of what happened and when — which is exactly what a
/// parent wants to scroll back through after a trip.
class SafetyAlert {
  const SafetyAlert({
    required this.id,
    required this.type,
    required this.severity,
    required this.headline,
    required this.detail,
    required this.advice,
    required this.raisedAt,
    required this.raisedAtTripTime,
    this.resolvedAt,
  });

  final String id;
  final SafetyAlertType type;
  final SafetyAlertSeverity severity;

  /// Plain-language summary — no jargon, no units a parent has to decode.
  final String headline;

  /// The measurement behind the alert, e.g. "Reached 68 km/h in a 50 km/h zone".
  final String detail;

  /// What the parent can actually do about it.
  final String advice;

  final DateTime raisedAt;
  final Duration raisedAtTripTime;
  final DateTime? resolvedAt;

  bool get isActive => resolvedAt == null;

  SafetyAlert resolve(DateTime at) => SafetyAlert(
    id: id,
    type: type,
    severity: severity,
    headline: headline,
    detail: detail,
    advice: advice,
    raisedAt: raisedAt,
    raisedAtTripTime: raisedAtTripTime,
    resolvedAt: at,
  );
}

/// Outcome of one monitor tick, so the controller knows when to fire haptics
/// or surface a transient "resolved" confirmation.
class SafetyEvaluation {
  const SafetyEvaluation({required this.raised, required this.resolved});

  static const SafetyEvaluation none = SafetyEvaluation(
    raised: [],
    resolved: [],
  );

  final List<SafetyAlert> raised;
  final List<SafetyAlert> resolved;

  bool get hasChanges => raised.isNotEmpty || resolved.isNotEmpty;
}
