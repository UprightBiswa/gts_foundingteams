import 'dart:math' as math;

/// A plain latitude/longitude pair.
///
/// The prototype runs on mock data, but keeping real coordinates (rather than
/// arbitrary screen offsets) means distance, speed and ETA stay believable —
/// and a real GPS stream could replace the simulator without touching any
/// widget that consumes it.
class GeoPoint {
  const GeoPoint(this.latitude, this.longitude);

  final double latitude;
  final double longitude;

  GeoPoint lerpTo(GeoPoint other, double t) => GeoPoint(
    latitude + (other.latitude - latitude) * t,
    longitude + (other.longitude - longitude) * t,
  );

  @override
  bool operator ==(Object other) =>
      other is GeoPoint &&
      other.latitude == latitude &&
      other.longitude == longitude;

  @override
  int get hashCode => Object.hash(latitude, longitude);

  @override
  String toString() =>
      'GeoPoint(${latitude.toStringAsFixed(5)}, ${longitude.toStringAsFixed(5)})';
}

/// Axis-aligned bounding box over a set of points, used by the map projection.
class GeoBounds {
  const GeoBounds({
    required this.minLatitude,
    required this.maxLatitude,
    required this.minLongitude,
    required this.maxLongitude,
  });

  factory GeoBounds.fromPoints(List<GeoPoint> points) {
    assert(points.isNotEmpty, 'Cannot compute bounds of an empty point list');

    var minLat = points.first.latitude;
    var maxLat = points.first.latitude;
    var minLng = points.first.longitude;
    var maxLng = points.first.longitude;

    for (final point in points) {
      minLat = math.min(minLat, point.latitude);
      maxLat = math.max(maxLat, point.latitude);
      minLng = math.min(minLng, point.longitude);
      maxLng = math.max(maxLng, point.longitude);
    }

    return GeoBounds(
      minLatitude: minLat,
      maxLatitude: maxLat,
      minLongitude: minLng,
      maxLongitude: maxLng,
    );
  }

  final double minLatitude;
  final double maxLatitude;
  final double minLongitude;
  final double maxLongitude;

  double get centerLatitude => (minLatitude + maxLatitude) / 2;
  double get centerLongitude => (minLongitude + maxLongitude) / 2;
}
