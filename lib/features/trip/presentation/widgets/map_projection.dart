import 'dart:math' as math;

import 'package:flutter/painting.dart';

import '../../../../core/geo/geo_point.dart';

/// Projects latitude/longitude onto canvas pixels.
///
/// An equirectangular projection with a `cos(latitude)` correction on the
/// longitude axis. At city scale the distortion is invisible, and it keeps the
/// route's real shape — a naive lat/lng-to-x/y mapping visibly stretches
/// east–west at these latitudes.
class MapProjection {
  MapProjection({
    required this.bounds,
    required this.size,
    this.padding = const EdgeInsets.all(44),
  }) {
    _longitudeScale = math.cos(bounds.centerLatitude * math.pi / 180);

    final minX = bounds.minLongitude * _longitudeScale;
    final maxX = bounds.maxLongitude * _longitudeScale;
    final minY = -bounds.maxLatitude;
    final maxY = -bounds.minLatitude;

    _minX = minX;
    _minY = minY;

    final rawWidth = math.max(maxX - minX, 1e-9);
    final rawHeight = math.max(maxY - minY, 1e-9);

    final availableWidth = math.max(size.width - padding.horizontal, 1.0);
    final availableHeight = math.max(size.height - padding.vertical, 1.0);

    _scale = math.min(availableWidth / rawWidth, availableHeight / rawHeight);

    _offsetX = padding.left + (availableWidth - rawWidth * _scale) / 2;
    _offsetY = padding.top + (availableHeight - rawHeight * _scale) / 2;
  }

  final GeoBounds bounds;
  final Size size;
  final EdgeInsets padding;

  late final double _longitudeScale;
  late final double _scale;
  late final double _minX;
  late final double _minY;
  late final double _offsetX;
  late final double _offsetY;

  Offset project(GeoPoint point) {
    final x = point.longitude * _longitudeScale;
    final y = -point.latitude;
    return Offset(
      _offsetX + (x - _minX) * _scale,
      _offsetY + (y - _minY) * _scale,
    );
  }

  List<Offset> projectAll(List<GeoPoint> points) =>
      points.map(project).toList(growable: false);

  /// Ground meters represented by one logical pixel — used to size the
  /// arrival geofence so it stays geographically honest at any screen size.
  double get metersPerPixel => 111320 / _scale;
}
