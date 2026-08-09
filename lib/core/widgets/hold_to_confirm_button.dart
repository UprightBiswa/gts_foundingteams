import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// A button that only fires after a sustained press.
///
/// Used for the SOS confirmation. A dedicated confirmation screen already stops
/// accidental taps from the trip screen; requiring a deliberate hold on the
/// final action means a pocket-tap or a mis-aimed thumb on *this* screen cannot
/// dispatch an emergency either. Releasing early rewinds the progress, so the
/// gesture is always reversible right up to the moment it completes.
class HoldToConfirmButton extends StatefulWidget {
  const HoldToConfirmButton({
    super.key,
    required this.label,
    required this.holdingLabel,
    required this.icon,
    required this.color,
    required this.onConfirmed,
    this.duration = const Duration(milliseconds: 900),
  });

  final String label;
  final String holdingLabel;
  final IconData icon;
  final Color color;
  final VoidCallback onConfirmed;
  final Duration duration;

  @override
  State<HoldToConfirmButton> createState() => _HoldToConfirmButtonState();
}

class _HoldToConfirmButtonState extends State<HoldToConfirmButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: widget.duration,
  )..addStatusListener(_onStatus);

  bool _fired = false;

  void _onStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed && !_fired) {
      _fired = true;
      HapticFeedback.heavyImpact();
      widget.onConfirmed();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _start() {
    if (_fired) return;
    HapticFeedback.selectionClick();
    _controller.forward();
  }

  void _cancel() {
    if (_fired) return;
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _start(),
      onTapUp: (_) => _cancel(),
      onTapCancel: _cancel,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          final progress = _controller.value;
          final isHolding = progress > 0.02;

          return Transform.scale(
            scale: 1 - 0.02 * progress,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Stack(
                children: [
                  Container(height: 56, color: widget.color),
                  Positioned.fill(
                    child: FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: progress,
                      child: ColoredBox(
                        color: Colors.white.withValues(alpha: 0.26),
                      ),
                    ),
                  ),
                  SizedBox(
                    height: 56,
                    width: double.infinity,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(widget.icon, color: Colors.white, size: 20),
                        const SizedBox(width: 9),
                        Text(
                          isHolding ? widget.holdingLabel : widget.label,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
