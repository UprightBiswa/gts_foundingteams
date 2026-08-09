import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/geo/geo_point.dart';
import '../../../../core/geo/route_path.dart';
import '../../../../core/theme/app_colors.dart';
import 'map_projection.dart';

/// Draws the whole journey view: a stylised street map, the route, both
/// endpoints and the live driver marker.
///
/// Why a `CustomPainter` instead of Google Maps: the brief allows a
/// "convincing map-like visualisation", and hand-drawing it removes an API key,
/// a network dependency and a platform-view from the reviewer's setup — the app
/// runs offline on a fresh clone. It also means the marker, the travelled trail
/// and the safety colouring are all driven by the same trip state, with no
/// bridge to keep in sync.
class TripMapPainter extends CustomPainter {
  TripMapPainter({
    required this.route,
    required this.travelledMeters,
    required this.driverLocation,
    required this.headingDegrees,
    required this.accentColor,
    required this.isStationary,
    required this.pulse,
  }) : super(repaint: pulse);

  final RoutePath route;
  final double travelledMeters;
  final GeoPoint driverLocation;
  final double headingDegrees;

  /// Tracks the safety state — blue when healthy, amber/red when alerting.
  final Color accentColor;

  final bool isStationary;
  final Animation<double> pulse;

  static const double _streetRotation = -0.19;
  static const double _cellSize = 62;
  static const double _arrivalGeofenceMeters = 150;

  @override
  void paint(Canvas canvas, Size size) {
    final projection = MapProjection(
      bounds: GeoBounds.fromPoints(route.points),
      size: size,
      padding: const EdgeInsets.fromLTRB(46, 52, 46, 60),
    );

    _paintBase(canvas, size);
    _paintCityBlocks(canvas, size);
    _paintRiver(canvas, size);
    _paintRoute(canvas, projection);
    _paintArrivalZone(canvas, projection);
    _paintEndpoints(canvas, projection);
    _paintDriver(canvas, projection);
    _paintEdgeFade(canvas, size);
  }

  // ---------------------------------------------------------------- backdrop

  void _paintBase(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = AppColors.mapRoad);
  }

  /// City blocks are drawn as inset rounded rectangles on a light background —
  /// the *gaps* between them read as the street grid, which is far cheaper than
  /// drawing roads and buildings separately.
  void _paintCityBlocks(Canvas canvas, Size size) {
    final random = math.Random(7);
    final span = size.longestSide * 1.8;
    final area = Rect.fromCenter(
      center: size.center(Offset.zero),
      width: span,
      height: span,
    );

    canvas.save();
    canvas.translate(size.width / 2, size.height / 2);
    canvas.rotate(_streetRotation);
    canvas.translate(-size.width / 2, -size.height / 2);

    final paint = Paint();
    for (var y = area.top; y < area.bottom; y += _cellSize) {
      var x = area.left;
      while (x < area.right) {
        final roll = random.nextDouble();
        // Occasionally merge two cells so the grid does not read as graph paper.
        final wide = roll > 0.82;
        final width = (wide ? _cellSize * 2 : _cellSize) - 11;

        paint.color = switch (roll) {
          < 0.10 => AppColors.mapPark,
          < 0.55 => AppColors.mapBlock,
          _ => AppColors.mapBlockAlt,
        };

        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(x + 5, y + 5, width, _cellSize - 11),
            const Radius.circular(3),
          ),
          paint,
        );

        x += wide ? _cellSize * 2 : _cellSize;
      }
    }
    canvas.restore();
  }

  void _paintRiver(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(size.width * 0.52, -size.height * 0.08)
      ..quadraticBezierTo(
        size.width * 0.78,
        size.height * 0.10,
        size.width * 0.80,
        size.height * 0.26,
      )
      ..quadraticBezierTo(
        size.width * 0.82,
        size.height * 0.38,
        size.width * 1.08,
        size.height * 0.46,
      );

    canvas.drawPath(
      path,
      Paint()
        ..color = AppColors.mapWater
        ..style = PaintingStyle.stroke
        ..strokeWidth = 30
        ..strokeCap = StrokeCap.round,
    );
  }

  // ------------------------------------------------------------------- route

  void _paintRoute(Canvas canvas, MapProjection projection) {
    final fullPath = _smoothPath(projection.projectAll(route.points));

    // White casing underneath makes the route legible over dark blocks.
    canvas.drawPath(
      fullPath,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 12
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );

    canvas.drawPath(
      fullPath,
      Paint()
        ..color = AppColors.routeIdle
        ..style = PaintingStyle.stroke
        ..strokeWidth = 7
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );

    if (travelledMeters <= 1) return;

    final travelled = projection.projectAll(
      route.travelledPolyline(travelledMeters),
    );
    if (travelled.length < 2) return;

    final travelledPath = _smoothPath(travelled);
    final bounds = travelledPath.getBounds();

    canvas.drawPath(
      travelledPath,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [accentColor.withValues(alpha: 0.55), accentColor],
        ).createShader(bounds.inflate(1))
        ..style = PaintingStyle.stroke
        ..strokeWidth = 7
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  /// Quadratic curves through segment midpoints — rounds off the waypoint
  /// corners so the route reads as a road rather than a polyline.
  Path _smoothPath(List<Offset> points) {
    final path = Path();
    if (points.isEmpty) return path;

    path.moveTo(points.first.dx, points.first.dy);
    if (points.length < 3) {
      for (final point in points.skip(1)) {
        path.lineTo(point.dx, point.dy);
      }
      return path;
    }

    for (var i = 1; i < points.length - 1; i++) {
      final midpoint = Offset(
        (points[i].dx + points[i + 1].dx) / 2,
        (points[i].dy + points[i + 1].dy) / 2,
      );
      path.quadraticBezierTo(
        points[i].dx,
        points[i].dy,
        midpoint.dx,
        midpoint.dy,
      );
    }
    path.lineTo(points.last.dx, points.last.dy);
    return path;
  }

  // --------------------------------------------------------------- endpoints

  void _paintArrivalZone(Canvas canvas, MapProjection projection) {
    final center = projection.project(route.destination);
    final radius = _arrivalGeofenceMeters / projection.metersPerPixel;

    canvas.drawCircle(
      center,
      radius,
      Paint()..color = AppColors.safe.withValues(alpha: 0.10),
    );
    _drawDashedCircle(canvas, center, radius, AppColors.safe);
  }

  void _drawDashedCircle(
    Canvas canvas,
    Offset center,
    double radius,
    Color color,
  ) {
    final paint = Paint()
      ..color = color.withValues(alpha: 0.45)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round;

    const dashes = 26;
    const sweep = (math.pi * 2) / dashes;
    for (var i = 0; i < dashes; i++) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        i * sweep,
        sweep * 0.55,
        false,
        paint,
      );
    }
  }

  void _paintEndpoints(Canvas canvas, MapProjection projection) {
    _paintPlaceMarker(
      canvas,
      projection.project(route.origin),
      Icons.school_rounded,
      AppColors.inkSecondary,
      'School',
    );
    _paintPlaceMarker(
      canvas,
      projection.project(route.destination),
      Icons.home_rounded,
      AppColors.safe,
      'Home',
    );
  }

  void _paintPlaceMarker(
    Canvas canvas,
    Offset center,
    IconData icon,
    Color color,
    String label,
  ) {
    const radius = 15.0;

    canvas.drawCircle(
      center.translate(0, 2),
      radius + 1,
      Paint()
        ..color = Colors.black.withValues(alpha: 0.14)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
    );
    canvas.drawCircle(center, radius, Paint()..color = Colors.white);
    canvas.drawCircle(center, radius - 3, Paint()..color = color);

    _paintIcon(canvas, center, icon, Colors.white, 15);
    _paintLabelChip(canvas, center.translate(0, radius + 13), label);
  }

  void _paintDriver(Canvas canvas, MapProjection projection) {
    final center = projection.project(driverLocation);
    final value = pulse.value;

    // A stationary vehicle gets a slow, tight pulse; a moving one radiates
    // further. The marker itself communicates motion before any number does.
    final maxHalo = isStationary ? 20.0 : 34.0;
    canvas.drawCircle(
      center,
      16 + maxHalo * value,
      Paint()..color = accentColor.withValues(alpha: 0.26 * (1 - value)),
    );

    canvas.drawCircle(
      center.translate(0, 3),
      17,
      Paint()
        ..color = accentColor.withValues(alpha: 0.32)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
    );
    canvas.drawCircle(center, 17, Paint()..color = Colors.white);
    canvas.drawCircle(center, 13, Paint()..color = accentColor);

    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(headingDegrees * math.pi / 180);
    _paintIcon(
      canvas,
      Offset.zero,
      isStationary ? Icons.pause_rounded : Icons.navigation_rounded,
      Colors.white,
      15,
    );
    canvas.restore();
  }

  // ------------------------------------------------------------------ shared

  void _paintIcon(
    Canvas canvas,
    Offset center,
    IconData icon,
    Color color,
    double size,
  ) {
    final painter = TextPainter(
      text: TextSpan(
        text: String.fromCharCode(icon.codePoint),
        style: TextStyle(
          fontSize: size,
          fontFamily: icon.fontFamily,
          package: icon.fontPackage,
          color: color,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    painter.paint(
      canvas,
      center - Offset(painter.width / 2, painter.height / 2),
    );
  }

  void _paintLabelChip(Canvas canvas, Offset center, String label) {
    final painter = TextPainter(
      text: TextSpan(
        text: label,
        style: const TextStyle(
          fontSize: 10.5,
          fontWeight: FontWeight.w700,
          color: AppColors.inkSecondary,
          letterSpacing: 0.2,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    final rect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: center,
        width: painter.width + 14,
        height: painter.height + 7,
      ),
      const Radius.circular(20),
    );

    canvas.drawRRect(
      rect.shift(const Offset(0, 1)),
      Paint()
        ..color = Colors.black.withValues(alpha: 0.10)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
    );
    canvas.drawRRect(rect, Paint()..color = Colors.white);
    painter.paint(
      canvas,
      center - Offset(painter.width / 2, painter.height / 2),
    );
  }

  /// Softens the top and bottom edges so the floating status chips stay legible
  /// wherever the map happens to be busy underneath them.
  void _paintEdgeFade(Canvas canvas, Size size) {
    canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.white.withValues(alpha: 0.55),
            Colors.white.withValues(alpha: 0.0),
            Colors.white.withValues(alpha: 0.0),
            Colors.white.withValues(alpha: 0.35),
          ],
          stops: const [0.0, 0.18, 0.80, 1.0],
        ).createShader(Offset.zero & size),
    );
  }

  @override
  bool shouldRepaint(TripMapPainter oldDelegate) {
    return oldDelegate.travelledMeters != travelledMeters ||
        oldDelegate.driverLocation != driverLocation ||
        oldDelegate.headingDegrees != headingDegrees ||
        oldDelegate.accentColor != accentColor ||
        oldDelegate.isStationary != isStationary;
  }
}
