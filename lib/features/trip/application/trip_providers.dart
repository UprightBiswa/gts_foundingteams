import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/geo/route_path.dart';
import '../data/mock_trip_data.dart';
import '../domain/child.dart';
import '../domain/driver.dart';
import '../domain/trip_place.dart';
import 'trip_controller.dart';
import 'trip_state.dart';

/// The live journey. `NotifierProvider` is keep-alive by default in Riverpod 3,
/// so the simulation survives navigation into the SOS flow and back.
final tripControllerProvider = NotifierProvider<TripController, TripState>(
  TripController.new,
);

/// Static journey participants. They are separate providers rather than fields
/// on [TripState] so that widgets showing only the driver card do not rebuild
/// four times a second alongside the live metrics.
final childProvider = Provider<Child>((ref) => MockTripData.child);
final driverProvider = Provider<Driver>((ref) => MockTripData.driver);
final schoolProvider = Provider<TripPlace>((ref) => MockTripData.school);
final dropOffProvider = Provider<TripPlace>((ref) => MockTripData.dropOff);
final routeProvider = Provider<RoutePath>((ref) => MockTripData.route);
