import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/trip_status.dart';

/// Floating chips layered over the map.
///
/// They sit on the map rather than below it because they answer questions
/// about what is on the map — status, freshness, progress — and splitting them
/// into a separate row would cost vertical space the map needs more.
class MapStatusChip extends StatelessWidget {
  const MapStatusChip({super.key, required this.status});

  final TripStatus status;

  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      TripStatus.completed => AppColors.safe,
      TripStatus.delayed => AppColors.warning,
      TripStatus.arriving => AppColors.brand,
      TripStatus.pickedUp || TripStatus.enRoute => AppColors.brand,
    };

    return _Chip(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 7),
          Text(
            status.label,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: color,
              letterSpacing: -0.1,
            ),
          ),
        ],
      ),
    );
  }
}

/// Blinking "LIVE" badge — the cheapest possible signal that the numbers on
/// screen are current rather than a stale last-known position.
class LiveIndicator extends StatefulWidget {
  const LiveIndicator({super.key, required this.isRunning});

  final bool isRunning;

  @override
  State<LiveIndicator> createState() => _LiveIndicatorState();
}

class _LiveIndicatorState extends State<LiveIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isRunning) {
      return const _Chip(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.pause_rounded, size: 13, color: AppColors.inkMuted),
            SizedBox(width: 5),
            Text(
              'PAUSED',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.7,
                color: AppColors.inkMuted,
              ),
            ),
          ],
        ),
      );
    }

    return _Chip(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          FadeTransition(
            opacity: Tween<double>(begin: 1, end: 0.25).animate(_controller),
            child: Container(
              width: 7,
              height: 7,
              decoration: const BoxDecoration(
                color: AppColors.danger,
                shape: BoxShape.circle,
              ),
            ),
          ),
          const SizedBox(width: 6),
          const Text(
            'LIVE',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.7,
              color: AppColors.ink,
            ),
          ),
        ],
      ),
    );
  }
}

/// Progress readout pinned to the bottom of the map.
class MapProgressChip extends StatelessWidget {
  const MapProgressChip({
    super.key,
    required this.travelledLabel,
    required this.totalLabel,
  });

  final String travelledLabel;
  final String totalLabel;

  @override
  Widget build(BuildContext context) {
    return _Chip(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.route_rounded,
            size: 13,
            color: AppColors.inkSecondary,
          ),
          const SizedBox(width: 6),
          Text(
            '$travelledLabel of $totalLabel covered',
            style: const TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              color: AppColors.inkSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1A0C1B33),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }
}
