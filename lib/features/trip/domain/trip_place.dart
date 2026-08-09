import '../../../core/geo/geo_point.dart';

/// A named endpoint of the journey — the school it started at, or the
/// drop-off point it is heading to.
class TripPlace {
  const TripPlace({
    required this.name,
    required this.addressLine,
    required this.location,
  });

  final String name;
  final String addressLine;
  final GeoPoint location;
}
