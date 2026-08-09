/// Who gets pulled in when a parent raises an SOS.
///
/// Showing these individually — and filling them in one by one — is the point:
/// "alert sent" is a claim, a list of who received it is evidence.
enum SosChannel {
  safetyTeam('GTS Safety Team', 'A live agent is reviewing this journey'),
  driver('Assigned driver', 'Alerted on the in-vehicle device'),
  emergencyContact('Your emergency contact', 'Notified by call and SMS'),
  school('School transport desk', 'Informed of the active incident');

  const SosChannel(this.label, this.detail);

  final String label;
  final String detail;
}

enum SosStage {
  /// No SOS in progress.
  idle,

  /// Confirmed by the parent; alerts are going out.
  dispatching,

  /// Every channel has acknowledged.
  raised,
}

/// State of the SOS flow.
class SosState {
  const SosState({
    this.stage = SosStage.idle,
    this.raisedAt,
    this.referenceId,
    this.notifiedChannels = const {},
  });

  final SosStage stage;
  final DateTime? raisedAt;

  /// Shown to the parent so they can quote it to a support agent.
  final String? referenceId;

  final Set<SosChannel> notifiedChannels;

  bool get isActive => stage != SosStage.idle;
  bool get isDispatching => stage == SosStage.dispatching;
  bool get isRaised => stage == SosStage.raised;

  SosState copyWith({
    SosStage? stage,
    DateTime? raisedAt,
    String? referenceId,
    Set<SosChannel>? notifiedChannels,
  }) {
    return SosState(
      stage: stage ?? this.stage,
      raisedAt: raisedAt ?? this.raisedAt,
      referenceId: referenceId ?? this.referenceId,
      notifiedChannels: notifiedChannels ?? this.notifiedChannels,
    );
  }
}
