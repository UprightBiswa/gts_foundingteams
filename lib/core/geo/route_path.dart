import 'dart:math' as math;

import 'geo_point.dart';

/// Geodesic helpers shared by the simulator, the safety monitor and the map.
abstract final class Geo {
  static const double earthRadiusMeters = 6371000;

  static double _radians(double degrees) => degrees * math.pi / 180;
  static double _degrees(double radians) => radians * 180 / math.pi;

  /// Great-circle (haversine) distance between two points, in meters.
  static double distanceMeters(GeoPoint a, GeoPoint b) {
    final dLat = _radians(b.latitude - a.latitude);
    final dLng = _radians(b.longitude - a.longitude);
    final lat1 = _radians(a.latitude);
    final lat2 = _radians(b.latitude);

    final h =
        math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(lat1) *
            math.cos(lat2) *
            math.sin(dLng / 2) *
            math.sin(dLng / 2);

    return 2 * earthRadiusMeters * math.asin(math.min(1, math.sqrt(h)));
  }

  /// Initial bearing from [a] to [b], in degrees clockwise from north.
  static double bearingDegrees(GeoPoint a, GeoPoint b) {
    final lat1 = _radians(a.latitude);
    final lat2 = _radians(b.latitude);
    final dLng = _radians(b.longitude - a.longitude);

    final y = math.sin(dLng) * math.cos(lat2);
    final x =
        math.cos(lat1) * math.sin(lat2) -
        math.sin(lat1) * math.cos(lat2) * math.cos(dLng);

    return (_degrees(math.atan2(y, x)) + 360) % 360;
  }
}

/// A point resolved somewhere along a [RoutePath].
class RoutePosition {
  const RoutePosition({
    required this.point,
    required this.headingDegrees,
    required this.segmentIndex,
  });

  final GeoPoint point;
  final double headingDegrees;
  final int segmentIndex;
}

/// A polyline with pre-computed cumulative distances.
///
/// This is what lets the simulator work in "meters travelled" rather than
/// "waypoint index": a speed profile can be integrated over time and then
/// mapped onto a real position, which is how a live tracking feed behaves.
class RoutePath {
  RoutePath(List<GeoPoint> points)
    : assert(points.length >= 2, 'A route needs at least two points'),
      points = List.unmodifiable(points),
      _cumulativeMeters = _buildCumulative(points);

  final List<GeoPoint> points;
  final List<double> _cumulativeMeters;

  static List<double> _buildCumulative(List<GeoPoint> points) {
    final cumulative = <double>[0];
    for (var i = 1; i < points.length; i++) {
      cumulative.add(
        cumulative[i - 1] + Geo.distanceMeters(points[i - 1], points[i]),
      );
    }
    return List.unmodifiable(cumulative);
  }

  /// Total length of the route, in meters.
  double get totalMeters => _cumulativeMeters.last;

  GeoPoint get origin => points.first;
  GeoPoint get destination => points.last;

  /// Resolves the position [meters] along the route, clamped to the endpoints.
  RoutePosition positionAt(double meters) {
    final target = meters.clamp(0.0, totalMeters);

    // Routes here are a dozen waypoints long, so a linear scan beats the
    // overhead of a binary search and keeps the intent obvious.
    var segment = 0;
    while (segment < _cumulativeMeters.length - 2 &&
        _cumulativeMeters[segment + 1] < target) {
      segment++;
    }

    final segmentStart = _cumulativeMeters[segment];
    final segmentLength = _cumulativeMeters[segment + 1] - segmentStart;
    final t = segmentLength <= 0
        ? 0.0
        : ((target - segmentStart) / segmentLength).clamp(0.0, 1.0);

    return RoutePosition(
      point: points[segment].lerpTo(points[segment + 1], t),
      headingDegrees: Geo.bearingDegrees(points[segment], points[segment + 1]),
      segmentIndex: segment,
    );
  }

  /// The portion of the route already driven, for painting the travelled trail.
  List<GeoPoint> travelledPolyline(double meters) {
    final position = positionAt(meters);
    return [...points.take(position.segmentIndex + 1), position.point];
  }
}
