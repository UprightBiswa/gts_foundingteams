import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/gts_card.dart';
import '../../domain/trip_place.dart';

/// School → home, with how far along the vehicle is.
///
/// This is the "where is my child in the journey" answer, separate from the
/// map's "where is my child on the ground" answer. Parents ask both.
class JourneyProgressCard extends StatelessWidget {
  const JourneyProgressCard({
    super.key,
    required this.origin,
    required this.destination,
    required this.progress,
    required this.elapsed,
    required this.arrivalTime,
    required this.accentColor,
    required this.isComplete,
  });

  final TripPlace origin;
  final TripPlace destination;
  final double progress;
  final Duration elapsed;
  final DateTime arrivalTime;
  final Color accentColor;
  final bool isComplete;

  @override
  Widget build(BuildContext context) {
    return GtsCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _Endpoint(
                  caption: 'FROM',
                  title: origin.name,
                  subtitle: origin.addressLine,
                  alignment: CrossAxisAlignment.start,
                ),
              ),
              const SizedBox(width: 12),
              Padding(
                padding: const EdgeInsets.only(top: 14),
                child: Icon(
                  Icons.arrow_forward_rounded,
                  size: 16,
                  color: AppColors.inkMuted,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _Endpoint(
                  caption: 'TO',
                  title: destination.name,
                  subtitle: destination.addressLine,
                  alignment: CrossAxisAlignment.end,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _ProgressTrack(progress: progress, accentColor: accentColor),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: _Footnote(
                  icon: Icons.timer_outlined,
                  label: 'Elapsed ${Formatters.stopwatch(elapsed)}',
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: _Footnote(
                  icon: isComplete
                      ? Icons.check_circle_outline_rounded
                      : Icons.flag_outlined,
                  label: isComplete
                      ? 'Arrived safely'
                      : 'Arriving by ${Formatters.clockTime(arrivalTime)}',
                  color: isComplete ? AppColors.safe : AppColors.inkSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Endpoint extends StatelessWidget {
  const _Endpoint({
    required this.caption,
    required this.title,
    required this.subtitle,
    required this.alignment,
  });

  final String caption;
  final String title;
  final String subtitle;
  final CrossAxisAlignment alignment;

  @override
  Widget build(BuildContext context) {
    final textAlign = alignment == CrossAxisAlignment.end
        ? TextAlign.right
        : TextAlign.left;

    return Column(
      crossAxisAlignment: alignment,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          caption,
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.8,
            color: AppColors.inkMuted,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          title,
          textAlign: textAlign,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            height: 1.25,
            letterSpacing: -0.2,
            color: AppColors.ink,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          subtitle,
          textAlign: textAlign,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 11.5, color: AppColors.inkMuted),
        ),
      ],
    );
  }
}

class _ProgressTrack extends StatelessWidget {
  const _ProgressTrack({required this.progress, required this.accentColor});

  final double progress;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        const trackHeight = 8.0;
        const knobRadius = 9.0;
        final clamped = progress.clamp(0.0, 1.0);

        return SizedBox(
          height: knobRadius * 2,
          child: Stack(
            alignment: Alignment.centerLeft,
            children: [
              Container(
                height: trackHeight,
                decoration: BoxDecoration(
                  color: AppColors.canvas,
                  borderRadius: BorderRadius.circular(trackHeight),
                ),
              ),
              // Implicit animation smooths the 4x-per-second discrete jumps
              // into continuous motion.
              TweenAnimationBuilder<double>(
                tween: Tween(begin: clamped, end: clamped),
                duration: const Duration(milliseconds: 260),
                curve: Curves.easeOut,
                builder: (context, value, _) => Container(
                  height: trackHeight,
                  width: (width * value).clamp(trackHeight, width),
                  decoration: BoxDecoration(
                    color: accentColor,
                    borderRadius: BorderRadius.circular(trackHeight),
                  ),
                ),
              ),
              AnimatedPositioned(
                duration: const Duration(milliseconds: 260),
                curve: Curves.easeOut,
                left: (width * clamped - knobRadius).clamp(
                  0.0,
                  width - knobRadius * 2,
                ),
                child: Container(
                  width: knobRadius * 2,
                  height: knobRadius * 2,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(color: accentColor, width: 3),
                    boxShadow: [
                      BoxShadow(
                        color: accentColor.withValues(alpha: 0.30),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _Footnote extends StatelessWidget {
  const _Footnote({
    required this.icon,
    required this.label,
    this.color = AppColors.inkSecondary,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 5),
        Flexible(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ),
      ],
    );
  }
}
