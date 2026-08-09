import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'safety_monitor.dart';

/// Thresholds for the safety rules, exposed as a provider so the simulator,
/// the monitor and the UI all read the same limit — the speed tile turns red
/// at exactly the number the alert is measured against.
final safetyRulesProvider = Provider<SafetyRules>((ref) => const SafetyRules());
