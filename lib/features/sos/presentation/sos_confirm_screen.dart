import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/gts_card.dart';
import '../../../core/widgets/hold_to_confirm_button.dart';
import '../../trip/application/trip_providers.dart';
import '../application/sos_controller.dart';
import '../domain/sos_state.dart';

/// Step two of the SOS flow: confirm.
///
/// A full screen rather than a dialog. Raising an emergency alert deserves the
/// parent's whole attention, and it is the natural place to answer the two
/// questions they will have — what exactly happens, and is this the right
/// journey — before anything is dispatched.
class SosConfirmScreen extends ConsumerWidget {
  const SosConfirmScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final child = ref.watch(childProvider);
    final driver = ref.watch(driverProvider);
    final dropOff = ref.watch(dropOffProvider);
    final snapshot = ref.watch(
      tripControllerProvider.select((state) => state.snapshot),
    );

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => context.pop(),
          tooltip: 'Close',
        ),
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
                children: [
                  Center(
                    child: Container(
                      width: 76,
                      height: 76,
                      decoration: const BoxDecoration(
                        color: AppColors.dangerSoft,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.emergency_rounded,
                        size: 36,
                        color: AppColors.sos,
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    'Raise an emergency SOS?',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 23,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.6,
                      color: AppColors.ink,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Use this if you believe ${child.firstName} is in immediate '
                    'danger. GTS will treat it as a live incident.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 14,
                      height: 1.45,
                      color: AppColors.inkSecondary,
                    ),
                  ),
                  const SizedBox(height: 22),
                  GtsCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'This journey',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.7,
                            color: AppColors.inkMuted,
                          ),
                        ),
                        const SizedBox(height: 10),
                        _ContextRow(
                          icon: Icons.child_care_rounded,
                          label: 'Child',
                          value: '${child.name} · ${child.grade}',
                        ),
                        _ContextRow(
                          icon: Icons.person_rounded,
                          label: 'Driver',
                          value:
                              '${driver.name} · ${driver.ratingLabel}★ · '
                              '${driver.vehiclePlate}',
                        ),
                        _ContextRow(
                          icon: Icons.place_rounded,
                          label: 'Heading to',
                          value: dropOff.name,
                        ),
                        _ContextRow(
                          icon: Icons.schedule_rounded,
                          label: 'Currently',
                          value:
                              '${Formatters.distance(snapshot.distanceRemainingMeters)} '
                              'away · ${Formatters.duration(snapshot.eta)} to go',
                          isLast: true,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  GtsCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'What happens immediately',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.7,
                            color: AppColors.inkMuted,
                          ),
                        ),
                        const SizedBox(height: 10),
                        for (final channel in SosChannel.values)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 9),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Padding(
                                  padding: EdgeInsets.only(top: 2),
                                  child: Icon(
                                    Icons.arrow_right_rounded,
                                    size: 18,
                                    color: AppColors.sos,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: RichText(
                                    text: TextSpan(
                                      style: const TextStyle(
                                        fontSize: 13.5,
                                        height: 1.35,
                                        color: AppColors.inkSecondary,
                                      ),
                                      children: [
                                        TextSpan(
                                          text: '${channel.label} — ',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w700,
                                            color: AppColors.ink,
                                          ),
                                        ),
                                        TextSpan(text: channel.detail),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
              child: Column(
                children: [
                  HoldToConfirmButton(
                    label: 'Hold to raise SOS',
                    holdingLabel: 'Keep holding…',
                    icon: Icons.sos_rounded,
                    color: AppColors.sos,
                    onConfirmed: () {
                      ref.read(sosControllerProvider.notifier).raise();
                      context.pushReplacement('/sos-raised');
                    },
                  ),
                  const SizedBox(height: 10),
                  OutlinedButton(
                    onPressed: () => context.pop(),
                    child: const Text('Cancel'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ContextRow extends StatelessWidget {
  const _ContextRow({
    required this.icon,
    required this.label,
    required this.value,
    this.isLast = false,
  });

  final IconData icon;
  final String label;
  final String value;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 17, color: AppColors.inkMuted),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 11.5,
                    color: AppColors.inkMuted,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    height: 1.3,
                    color: AppColors.ink,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
