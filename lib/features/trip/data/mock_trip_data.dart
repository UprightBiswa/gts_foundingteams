import '../../../core/geo/geo_point.dart';
import '../../../core/geo/route_path.dart';
import '../domain/child.dart';
import '../domain/driver.dart';
import '../domain/speed_keyframe.dart';
import '../domain/trip_place.dart';

/// Every tunable value behind the demo lives here.
///
/// The rest of the app treats this as a repository would: it asks for a route,
/// a child and a driver, and never learns that they were hard-coded. Swapping
/// this for a real API is a one-file change.
abstract final class MockTripData {
  static const Child child = Child(
    name: 'Aarav Sharma',
    grade: 'Grade 4 · Section B',
    avatarInitials: 'AS',
  );

  static const Driver driver = Driver(
    name: 'Ramesh Kulkarni',
    rating: 4.8,
    totalTrips: 1284,
    vehicleModel: 'Toyota Hiace · White',
    vehiclePlate: 'GTS 4821',
    phoneNumber: '+91 98765 43210',
    avatarInitials: 'RK',
    isVerified: true,
  );

  static const TripPlace school = TripPlace(
    name: 'Riverdale Public School',
    addressLine: 'Wilson Road, North Campus',
    location: GeoPoint(51.24500, -0.58900),
  );

  static const TripPlace dropOff = TripPlace(
    name: 'Home · Maple Residency',
    addressLine: 'Block C, Maple Residency',
    location: GeoPoint(51.22800, -0.56100),
  );

  /// Waypoints from the school gate to the drop-off point (~2.9 km).
  ///
  /// Real coordinates keep the haversine distance, bearing and ETA maths
  /// meaningful — the map projection derives everything from these points.
  static final RoutePath route = RoutePath(const [
    GeoPoint(51.24500, -0.58900),
    GeoPoint(51.24460, -0.58620),
    GeoPoint(51.24380, -0.58310),
    GeoPoint(51.24210, -0.58120),
    GeoPoint(51.23980, -0.58050),
    GeoPoint(51.23760, -0.57980),
    GeoPoint(51.23590, -0.57720),
    GeoPoint(51.23480, -0.57390),
    GeoPoint(51.23310, -0.57150),
    GeoPoint(51.23090, -0.57020),
    GeoPoint(51.22940, -0.56780),
    GeoPoint(51.22860, -0.56420),
    GeoPoint(51.22800, -0.56100),
  ]);

  /// The scripted journey, in simulated seconds since pickup.
  ///
  /// It is deliberately shaped so a reviewer sees both safety scenarios without
  /// touching anything:
  ///   ~50 s  speed climbs past the 50 km/h limit  -> overspeeding alert
  ///   ~80 s  driver slows back to normal          -> alert resolves
  ///  ~128 s  vehicle stops and stays put          -> location-stopped alert
  ///  ~170 s  movement resumes                     -> alert resolves
  static const List<SpeedKeyframe> speedProfile = [
    SpeedKeyframe(0, 0),
    SpeedKeyframe(6, 32),
    SpeedKeyframe(40, 34),
    SpeedKeyframe(46, 38),
    SpeedKeyframe(56, 66),
    SpeedKeyframe(72, 68),
    SpeedKeyframe(82, 36),
    SpeedKeyframe(120, 33),
    SpeedKeyframe(128, 0),
    SpeedKeyframe(170, 0),
    SpeedKeyframe(178, 30),
    SpeedKeyframe(400, 34),
  ];

  /// Wall-clock interval between simulator ticks.
  static const Duration tickInterval = Duration(milliseconds: 250);

  /// Simulated seconds advanced per tick.
  ///
  /// 4x real time: the full ~5.8 minute journey plays out in ~90 seconds, which
  /// fits inside a 2–3 minute demo recording without rushing the narration.
  static const double simulatedSecondsPerTick = 1.0;
}
