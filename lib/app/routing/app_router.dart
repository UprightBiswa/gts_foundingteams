import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/safety/presentation/safety_alerts_screen.dart';
import '../../features/sos/presentation/sos_confirm_screen.dart';
import '../../features/sos/presentation/sos_raised_screen.dart';
import '../../features/trip/presentation/active_trip_screen.dart';

/// Route names, kept as constants so navigation calls never depend on a
/// stringly-typed path spelled correctly at every call site.
abstract final class AppRoutes {
  static const String trip = '/';
  static const String alerts = '/alerts';
  static const String sosConfirm = '/sos';
  static const String sosRaised = '/sos-raised';
}

/// The app's router.
///
/// The SOS steps are real routes rather than dialogs on purpose: they get their
/// own entries in the back stack and their own full-screen presentation, which
/// is the right weight for an emergency action and keeps the confirm → raised
/// progression explicit instead of hidden inside one widget's local state.
final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: AppRoutes.trip,
    routes: [
      GoRoute(
        path: AppRoutes.trip,
        builder: (context, state) => const ActiveTripScreen(),
      ),
      GoRoute(
        path: AppRoutes.alerts,
        builder: (context, state) => const SafetyAlertsScreen(),
      ),
      GoRoute(
        path: AppRoutes.sosConfirm,
        pageBuilder: (context, state) =>
            _slideUpPage(state: state, child: const SosConfirmScreen()),
      ),
      GoRoute(
        path: AppRoutes.sosRaised,
        pageBuilder: (context, state) =>
            _slideUpPage(state: state, child: const SosRaisedScreen()),
      ),
    ],
  );
});

/// Modal-style slide-up, so the SOS flow reads as a deliberate interruption of
/// the journey rather than a sideways step within it.
CustomTransitionPage<void> _slideUpPage({
  required GoRouterState state,
  required Widget child,
}) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    child: child,
    transitionDuration: const Duration(milliseconds: 280),
    reverseTransitionDuration: const Duration(milliseconds: 220),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return SlideTransition(
        position: Tween<Offset>(begin: const Offset(0, 0.06), end: Offset.zero)
            .animate(
              CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
            ),
        child: FadeTransition(opacity: animation, child: child),
      );
    },
  );
}
