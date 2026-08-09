import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../domain/safety_alert.dart';

/// Maps safety semantics onto colour and iconography.
///
/// Centralised so the banner, the map marker, the speed tile and the alert
/// history can never disagree about what "critical" looks like.
abstract final class AlertVisuals {
  static Color color(SafetyAlertSeverity severity) =>
      severity == SafetyAlertSeverity.critical
      ? AppColors.danger
      : AppColors.warning;

  static Color softColor(SafetyAlertSeverity severity) =>
      severity == SafetyAlertSeverity.critical
      ? AppColors.dangerSoft
      : AppColors.warningSoft;

  static IconData icon(SafetyAlertType type) => switch (type) {
    SafetyAlertType.overspeeding => Icons.speed_rounded,
    SafetyAlertType.locationStopped => Icons.location_disabled_rounded,
  };

  /// Accent used by the map and headline metrics: healthy blue unless an alert
  /// is open, in which case the whole screen shifts to the alert's colour.
  static Color accentFor(SafetyAlert? alert) =>
      alert == null ? AppColors.brand : color(alert.severity);
}
