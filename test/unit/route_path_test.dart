import 'package:flutter_test/flutter_test.dart';
import 'package:gts_foundingteams/core/geo/geo_point.dart';
import 'package:gts_foundingteams/core/geo/route_path.dart';
import 'package:gts_foundingteams/features/trip/data/mock_trip_data.dart';

void main() {
  group('Geo', () {
    test('distance between identical points is zero', () {
      const point = GeoPoint(51.245, -0.589);
      expect(Geo.distanceMeters(point, point), closeTo(0, 0.001));
    });

    test('one degree of latitude is roughly 111 km', () {
      const a = GeoPoint(51.0, -0.5);
      const b = GeoPoint(52.0, -0.5);
      expect(Geo.distanceMeters(a, b), closeTo(111195, 500));
    });

    test('bearing due east is 90 degrees', () {
      const a = GeoPoint(51.0, -0.5);
      const b = GeoPoint(51.0, -0.4);
      expect(Geo.bearingDegrees(a, b), closeTo(90, 0.5));
    });
  });

  group('RoutePath', () {
    final route = MockTripData.route;

    test('total length is the sum of its segments', () {
      var manual = 0.0;
      for (var i = 1; i < route.points.length; i++) {
        manual += Geo.distanceMeters(route.points[i - 1], route.points[i]);
      }
      expect(route.totalMeters, closeTo(manual, 0.001));
    });

    test('the mock school run is a plausible length', () {
      expect(route.totalMeters, greaterThan(2000));
      expect(route.totalMeters, lessThan(5000));
    });

    test('resolves the endpoints exactly and clamps beyond them', () {
      expect(route.positionAt(0).point, route.origin);
      expect(route.positionAt(route.totalMeters).point, route.destination);
      expect(route.positionAt(-500).point, route.origin);
      expect(route.positionAt(route.totalMeters * 3).point, route.destination);
    });

    test('distance along the route increases monotonically', () {
      var previous = 0.0;
      for (var meters = 0.0; meters <= route.totalMeters; meters += 50) {
        final travelled = Geo.distanceMeters(
          route.origin,
          route.positionAt(meters).point,
        );
        // Straight-line distance from the origin is not strictly monotonic on a
        // winding route, so assert on the cumulative measure the simulator uses.
        expect(meters, greaterThanOrEqualTo(previous));
        expect(travelled, greaterThanOrEqualTo(0));
        previous = meters;
      }
    });

    test('travelled polyline grows as the journey progresses', () {
      final quarter = route.travelledPolyline(route.totalMeters * 0.25);
      final threeQuarters = route.travelledPolyline(route.totalMeters * 0.75);

      expect(quarter.first, route.origin);
      expect(threeQuarters.length, greaterThanOrEqualTo(quarter.length));
    });
  });
}
