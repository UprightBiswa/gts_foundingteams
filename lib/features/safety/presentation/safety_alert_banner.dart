import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../domain/safety_alert.dart';
import 'alert_visuals.dart';

/// The parent-facing safety warning.
///
/// Pinned directly under the header rather than placed in the scrolling body —
/// an alert that can be scrolled out of sight is an alert that gets missed.
/// It animates its own height so appearing and clearing never jump the layout.
class SafetyAlertBanner extends StatelessWidget {
  const SafetyAlertBanner({
    super.key,
    required this.alert,
    required this.onTap,
  });

  final SafetyAlert? alert;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AnimatedSize(
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
      alignment: Alignment.topCenter,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 240),
        switchInCurve: Curves.easeOutCubic,
        transitionBuilder: (child, animation) => FadeTransition(
          opacity: animation,
          child: SizeTransition(
            sizeFactor: animation,
            axisAlignment: -1,
            child: child,
          ),
        ),
        child: alert == null
            ? const SizedBox(width: double.infinity, key: ValueKey('none'))
            : _AlertContent(
                key: ValueKey(alert!.id),
                alert: alert!,
                onTap: onTap,
              ),
      ),
    );
  }
}

class _AlertContent extends StatelessWidget {
  const _AlertContent({super.key, required this.alert, required this.onTap});

  final SafetyAlert alert;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = AlertVisuals.color(alert.severity);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Material(
        color: AlertVisuals.softColor(alert.severity),
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: color.withValues(alpha: 0.35)),
            ),
            padding: const EdgeInsets.fromLTRB(14, 13, 12, 13),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _PulsingIcon(icon: AlertVisuals.icon(alert.type), color: color),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        alert.headline,
                        style: TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.2,
                          color: color,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        alert.detail,
                        style: const TextStyle(
                          fontSize: 12.5,
                          height: 1.35,
                          color: AppColors.inkSecondary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        alert.advice,
                        style: TextStyle(
                          fontSize: 12,
                          height: 1.35,
                          fontWeight: FontWeight.w500,
                          color: AppColors.inkSecondary.withValues(alpha: 0.85),
                        ),
                      ),
                    ],
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.only(top: 2),
                  child: Icon(
                    Icons.chevron_right_rounded,
                    size: 20,
                    color: AppColors.inkMuted,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A slow breathing halo — enough motion to catch peripheral vision without
/// the strobing that makes safety UI feel alarming to use.
class _PulsingIcon extends StatefulWidget {
  const _PulsingIcon({required this.icon, required this.color});

  final IconData icon;
  final Color color;

  @override
  State<_PulsingIcon> createState() => _PulsingIconState();
}

class _PulsingIconState extends State<_PulsingIcon>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) => Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: widget.color.withValues(
            alpha: 0.14 + 0.12 * _controller.value,
          ),
          shape: BoxShape.circle,
        ),
        child: child,
      ),
      child: Icon(widget.icon, size: 19, color: widget.color),
    );
  }
}
