import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/gts_card.dart';
import '../../trip/application/trip_providers.dart';
import '../application/sos_controller.dart';
import '../domain/sos_state.dart';

/// Step three: the success state.
///
/// "Alert sent" on its own is a claim a frightened parent has no reason to
/// trust. Acknowledging each channel separately, as it lands, plus a quotable
/// reference number, turns it into something they can verify and act on.
class SosRaisedScreen extends ConsumerWidget {
  const SosRaisedScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sos = ref.watch(sosControllerProvider);
    final child = ref.watch(childProvider);

    // Guard against landing here with no active SOS (e.g. after a cancel).
    if (!sos.isActive) {
      return const _NoActiveSos();
    }

    final isRaised = sos.isRaised;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        actions: [
          TextButton(
            onPressed: () => context.go('/'),
            child: const Text('Back to journey'),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
                children: [
                  Center(child: _StatusBadge(isRaised: isRaised)),
                  const SizedBox(height: 18),
                  Text(
                    isRaised ? 'SOS alert raised' : 'Raising SOS…',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.6,
                      color: AppColors.ink,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    isRaised
                        ? 'Everyone below has been notified about '
                              "${child.firstName}'s journey."
                        : 'Contacting your safety network now.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 14,
                      height: 1.45,
                      color: AppColors.inkSecondary,
                    ),
                  ),
                  if (sos.referenceId != null && sos.raisedAt != null) ...[
                    const SizedBox(height: 14),
                    Center(
                      child: GtsPill(
                        label:
                            '${sos.referenceId}  ·  '
                            '${Formatters.clockTime(sos.raisedAt!)}',
                        icon: Icons.confirmation_number_outlined,
                        color: AppColors.inkSecondary,
                      ),
                    ),
                  ],
                  const SizedBox(height: 22),
                  GtsCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Who has been notified',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.7,
                            color: AppColors.inkMuted,
                          ),
                        ),
                        const SizedBox(height: 12),
                        for (final channel in SosChannel.values)
                          _ChannelRow(
                            channel: channel,
                            isNotified: sos.notifiedChannels.contains(channel),
                            isLast: channel == SosChannel.values.last,
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  GtsCard(
                    color: AppColors.brandSoft,
                    borderColor: AppColors.brand.withValues(alpha: 0.22),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.support_agent_rounded,
                          color: AppColors.brandDark,
                          size: 20,
                        ),
                        const SizedBox(width: 11),
                        Expanded(
                          child: Text(
                            'A GTS safety agent is watching '
                            "${child.firstName}'s live location and will call "
                            'you on this number. Keep the app open.',
                            style: const TextStyle(
                              fontSize: 13,
                              height: 1.4,
                              fontWeight: FontWeight.w500,
                              color: AppColors.brandDark,
                            ),
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
                  FilledButton.icon(
                    onPressed: () => _showSnack(
                      context,
                      'Connecting to the GTS 24/7 safety line…',
                    ),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.sos,
                      foregroundColor: Colors.white,
                      elevation: 0,
                    ),
                    icon: const Icon(Icons.call_rounded, size: 20),
                    label: const Text('Call GTS safety line'),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () => _confirmCancel(context, ref),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.inkMuted,
                      minimumSize: const Size.fromHeight(44),
                    ),
                    child: const Text("Cancel SOS — it's a false alarm"),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmCancel(BuildContext context, WidgetRef ref) async {
    final shouldCancel = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text('Stand down the SOS?'),
        content: const Text(
          'GTS will stop treating this journey as an active incident and '
          'everyone notified will be told it was a false alarm.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Keep SOS active'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: FilledButton.styleFrom(
              minimumSize: const Size(0, 44),
              backgroundColor: AppColors.sos,
            ),
            child: const Text('Stand down'),
          ),
        ],
      ),
    );

    if (shouldCancel != true || !context.mounted) return;

    ref.read(sosControllerProvider.notifier).cancel();
    context.go('/');
    _showSnack(
      context,
      'SOS cancelled. The journey is being tracked normally.',
    );
  }

  void _showSnack(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.isRaised});

  final bool isRaised;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 420),
      switchInCurve: Curves.easeOutBack,
      transitionBuilder: (child, animation) =>
          ScaleTransition(scale: animation, child: child),
      child: Container(
        key: ValueKey(isRaised),
        width: 84,
        height: 84,
        decoration: BoxDecoration(
          color: isRaised ? AppColors.safeSoft : AppColors.dangerSoft,
          shape: BoxShape.circle,
        ),
        child: Icon(
          isRaised ? Icons.check_rounded : Icons.emergency_rounded,
          size: 42,
          color: isRaised ? AppColors.safe : AppColors.sos,
        ),
      ),
    );
  }
}

class _ChannelRow extends StatelessWidget {
  const _ChannelRow({
    required this.channel,
    required this.isNotified,
    required this.isLast,
  });

  final SosChannel channel;
  final bool isNotified;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 22,
            height: 22,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              transitionBuilder: (child, animation) =>
                  ScaleTransition(scale: animation, child: child),
              child: isNotified
                  ? const Icon(
                      Icons.check_circle_rounded,
                      key: ValueKey('done'),
                      size: 22,
                      color: AppColors.safe,
                    )
                  : const Padding(
                      key: ValueKey('pending'),
                      padding: EdgeInsets.all(3),
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.inkMuted,
                      ),
                    ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  channel.label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: isNotified ? AppColors.ink : AppColors.inkMuted,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  isNotified ? channel.detail : 'Notifying…',
                  style: const TextStyle(
                    fontSize: 12.5,
                    color: AppColors.inkMuted,
                    height: 1.3,
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

class _NoActiveSos extends StatelessWidget {
  const _NoActiveSos();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.shield_outlined,
                size: 44,
                color: AppColors.inkMuted,
              ),
              const SizedBox(height: 14),
              const Text(
                'No active SOS',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 18),
              OutlinedButton(
                onPressed: () => context.go('/'),
                child: const Text('Back to journey'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
