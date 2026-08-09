import '../../safety/domain/safety_alert.dart';
import '../domain/trip_snapshot.dart';
import '../domain/trip_status.dart';

/// Everything the Active Trip screen renders, as one immutable value.
class TripState {
  const TripState({
    required this.snapshot,
    required this.status,
    required this.alerts,
    required this.primaryAlert,
    required this.isRunning,
    this.lastRaised,
    this.lastResolved,
    this.eventSequence = 0,
  });

  final TripSnapshot snapshot;

  /// The status shown to the parent. This is *not* always
  /// `snapshot.status`: when the safety monitor has an open "stopped" alert,
  /// the journey is reported as delayed. The simulator reports what the vehicle
  /// is doing; the monitor decides what it means; the controller composes both.
  final TripStatus status;

  /// Full alert log, newest first — active and already-resolved.
  final List<SafetyAlert> alerts;

  /// The alert the banner should surface, or null when all is well.
  final SafetyAlert? primaryAlert;

  final bool isRunning;

  final SafetyAlert? lastRaised;
  final SafetyAlert? lastResolved;

  /// Bumped whenever an alert is raised or resolved, so the UI can react to
  /// *events* with `ref.listen` instead of trying to diff two alert lists.
  final int eventSequence;

  bool get hasActiveAlert => primaryAlert != null;

  int get activeAlertCount => alerts.where((alert) => alert.isActive).length;

  TripState copyWith({
    TripSnapshot? snapshot,
    TripStatus? status,
    List<SafetyAlert>? alerts,
    SafetyAlert? primaryAlert,
    bool clearPrimaryAlert = false,
    bool? isRunning,
    SafetyAlert? lastRaised,
    SafetyAlert? lastResolved,
    int? eventSequence,
  }) {
    return TripState(
      snapshot: snapshot ?? this.snapshot,
      status: status ?? this.status,
      alerts: alerts ?? this.alerts,
      primaryAlert: clearPrimaryAlert
          ? null
          : (primaryAlert ?? this.primaryAlert),
      isRunning: isRunning ?? this.isRunning,
      lastRaised: lastRaised ?? this.lastRaised,
      lastResolved: lastResolved ?? this.lastResolved,
      eventSequence: eventSequence ?? this.eventSequence,
    );
  }
}
