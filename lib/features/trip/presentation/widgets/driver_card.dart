import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/gts_card.dart';
import '../../domain/driver.dart';

/// Who is driving, how well they are rated, and how to reach them.
///
/// Contact actions sit here rather than in a menu: when something looks wrong,
/// "call the driver" is the first thing a parent reaches for, and it should
/// never be more than one tap from the live map.
class DriverCard extends StatelessWidget {
  const DriverCard({super.key, required this.driver, required this.onContact});

  final Driver driver;

  /// Reports which action was tapped so the screen can surface a single,
  /// consistent "not wired up in the prototype" message.
  final void Function(String action) onContact;

  @override
  Widget build(BuildContext context) {
    return GtsCard(
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Avatar(initials: driver.avatarInitials),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            driver.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.2,
                              color: AppColors.ink,
                            ),
                          ),
                        ),
                        if (driver.isVerified) ...[
                          const SizedBox(width: 6),
                          const Icon(
                            Icons.verified_rounded,
                            size: 16,
                            color: AppColors.brand,
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 5),
                    Row(
                      children: [
                        const Icon(
                          Icons.star_rounded,
                          size: 16,
                          color: Color(0xFFF5A623),
                        ),
                        const SizedBox(width: 3),
                        Text(
                          driver.ratingLabel,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppColors.ink,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '· ${driver.totalTrips} trips',
                          style: const TextStyle(
                            fontSize: 12.5,
                            color: AppColors.inkMuted,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        GtsPill(
                          label: driver.vehiclePlate,
                          icon: Icons.directions_bus_filled_rounded,
                          dense: true,
                        ),
                        Text(
                          driver.vehicleModel,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.inkMuted,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _ContactAction(
                  icon: Icons.call_rounded,
                  label: 'Call driver',
                  onTap: () => onContact('Calling ${driver.name}'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _ContactAction(
                  icon: Icons.chat_bubble_outline_rounded,
                  label: 'Message',
                  onTap: () => onContact('Messaging ${driver.name}'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.initials});

  final String initials;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48,
      height: 48,
      decoration: const BoxDecoration(
        color: AppColors.canvas,
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Text(
        initials,
        style: const TextStyle(
          fontWeight: FontWeight.w700,
          color: AppColors.inkSecondary,
          fontSize: 16,
        ),
      ),
    );
  }
}

class _ContactAction extends StatelessWidget {
  const _ContactAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.canvas,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 11),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 17, color: AppColors.brandDark),
              const SizedBox(width: 7),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.brandDark,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
