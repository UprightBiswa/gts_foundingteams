import 'package:flutter/material.dart';

import '../../../../core/geo/geo_point.dart';
import '../../../../core/geo/route_path.dart';
import 'trip_map_painter.dart';

/// Hosts the map painter and owns the marker's pulse animation.
///
/// The pulse runs on its own [AnimationController] and is handed to the painter
/// as the `repaint` listenable, so the halo animates at 60fps without the trip
/// state rebuilding the widget tree — the simulator only ticks 4x a second.
class TripMapView extends StatefulWidget {
  const TripMapView({
    super.key,
    required this.route,
    required this.travelledMeters,
    required this.driverLocation,
    required this.headingDegrees,
    required this.accentColor,
    required this.isStationary,
  });

  final RoutePath route;
  final double travelledMeters;
  final GeoPoint driverLocation;
  final double headingDegrees;
  final Color accentColor;
  final bool isStationary;

  @override
  State<TripMapView> createState() => _TripMapViewState();
}

class _TripMapViewState extends State<TripMapView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;
  late final Animation<double> _pulse;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat();
    _pulse = CurvedAnimation(parent: _pulseController, curve: Curves.easeOut);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: CustomPaint(
        painter: TripMapPainter(
          route: widget.route,
          travelledMeters: widget.travelledMeters,
          driverLocation: widget.driverLocation,
          headingDegrees: widget.headingDegrees,
          accentColor: widget.accentColor,
          isStationary: widget.isStationary,
          pulse: _pulse,
        ),
        size: Size.infinite,
      ),
    );
  }
}
