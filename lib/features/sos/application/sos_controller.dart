import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/sos_state.dart';

/// Drives the SOS dispatch sequence.
///
/// There is no real emergency integration here, but the *shape* of the flow is
/// the real one: confirm, dispatch, then acknowledge each channel separately.
/// Filling the channels in one at a time turns an instant, unbelievable
/// "sent!" into visible progress a panicking parent can actually read.
class SosController extends Notifier<SosState> {
  static const Duration _channelInterval = Duration(milliseconds: 550);

  Timer? _sequence;
  bool _disposed = false;

  @override
  SosState build() {
    ref.onDispose(() {
      _disposed = true;
      _sequence?.cancel();
    });
    return const SosState();
  }

  /// Called only after the parent confirms on the dedicated SOS screen.
  void raise({DateTime? now}) {
    if (state.isActive) return;

    final timestamp = now ?? DateTime.now();
    state = SosState(
      stage: SosStage.dispatching,
      raisedAt: timestamp,
      referenceId: _buildReference(timestamp),
      notifiedChannels: const {},
    );

    _notifyNext();
  }

  void _notifyNext() {
    _sequence?.cancel();
    _sequence = Timer(_channelInterval, () {
      if (_disposed || state.stage == SosStage.idle) return;

      final remaining = SosChannel.values
          .where((channel) => !state.notifiedChannels.contains(channel))
          .toList(growable: false);

      if (remaining.isEmpty) {
        state = state.copyWith(stage: SosStage.raised);
        return;
      }

      state = state.copyWith(
        notifiedChannels: {...state.notifiedChannels, remaining.first},
      );
      _notifyNext();
    });
  }

  /// Stand down — the parent resolved the situation themselves.
  void cancel() {
    _sequence?.cancel();
    state = const SosState();
  }

  String _buildReference(DateTime timestamp) {
    final suffix = timestamp.millisecondsSinceEpoch
        .remainder(100000)
        .toString()
        .padLeft(5, '0');
    return 'SOS-$suffix';
  }
}

final sosControllerProvider = NotifierProvider<SosController, SosState>(
  SosController.new,
);
