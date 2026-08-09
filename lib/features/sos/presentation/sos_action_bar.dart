import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../application/sos_controller.dart';

/// The persistent SOS affordance.
///
/// It stays docked to the bottom of the trip screen — always reachable by
/// thumb, never scrolled away — and switches to a status strip once an SOS is
/// live so the parent can get back to the dispatch screen in one tap.
class SosActionBar extends ConsumerWidget {
  const SosActionBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isActive = ref.watch(
      sosControllerProvider.select((state) => state.isActive),
    );

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: isActive ? const _ActiveSosStrip() : const _RaiseSosButton(),
        ),
      ),
    );
  }
}

class _RaiseSosButton extends StatelessWidget {
  const _RaiseSosButton();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Emergency help for this journey',
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.w500,
            color: AppColors.inkMuted.withValues(alpha: 0.9),
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 56,
          child: FilledButton.icon(
            onPressed: () => context.push('/sos'),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.sos,
              foregroundColor: Colors.white,
              elevation: 0,
            ),
            icon: const Icon(Icons.sos_rounded, size: 24),
            label: const Text(
              'SOS',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.2,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ActiveSosStrip extends StatelessWidget {
  const _ActiveSosStrip();

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.dangerSoft,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: () => context.push('/sos-raised'),
        borderRadius: BorderRadius.circular(14),
        child: Container(
          height: 56,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.sos.withValues(alpha: 0.4)),
          ),
          child: Row(
            children: [
              const Icon(Icons.sos_rounded, color: AppColors.sos, size: 22),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'SOS is active — GTS is on this journey',
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.sos,
                  ),
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: AppColors.sos),
            ],
          ),
        ),
      ),
    );
  }
}
