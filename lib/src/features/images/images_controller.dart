// SPDX-License-Identifier: GPL-3.0-or-later
//
// Images: the state of one picture being made. It asks the Kotlin side (makeImage / stopImage) and follows the
// events of the `:images` helper process. The prompt only goes to makeImage; it is never logged or stored here.
// Phase 2 builds the real panel on this; for now a debug-only button in the panel uses it.
import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../bridge/messages.g.dart';

/// Which part of making a picture is running.
enum ImagesPhase { loading, sampling, decoding }

@immutable
sealed class ImagesState {
  const ImagesState();
}

/// Nothing is being made (also after a stop).
final class ImagesIdle extends ImagesState {
  const ImagesIdle();
}

/// A picture is being made. [step] of [steps] is only meaningful while [phase] is sampling.
final class ImagesMaking extends ImagesState {
  const ImagesMaking({required this.phase, this.step = 0, this.steps = 0});

  final ImagesPhase phase;
  final int step;
  final int steps;

  @override
  bool operator ==(Object other) =>
      other is ImagesMaking && other.phase == phase && other.step == step && other.steps == steps;

  @override
  int get hashCode => Object.hash(phase, step, steps);
}

/// The picture is a PNG at [path] in the keyboard's cache (only the last few are kept); it took [millis].
final class ImagesDone extends ImagesState {
  const ImagesDone({required this.path, required this.millis});

  final String path;
  final int millis;

  @override
  bool operator ==(Object other) => other is ImagesDone && other.path == path && other.millis == millis;

  @override
  int get hashCode => Object.hash(path, millis);
}

/// Making failed. [code]: 'no_pack', 'unsupported', 'busy', 'load_failed', 'failed' or 'helper_died'.
final class ImagesFailed extends ImagesState {
  const ImagesFailed(this.code);

  final String code;

  @override
  bool operator ==(Object other) => other is ImagesFailed && other.code == code;

  @override
  int get hashCode => code.hashCode;
}

/// Drives picture making. Create one per panel opening; [dispose] stops a picture still being made.
class ImagesController extends ChangeNotifier {
  ImagesController({required this.host, required this.events}) {
    _subscription = events.listen(_onEvent);
  }

  final ImeHostApi host;
  final Stream<ImageEventMessage> events;

  StreamSubscription<ImageEventMessage>? _subscription;
  ImagesState _state = const ImagesIdle();
  bool _disposed = false;

  ImagesState get state => _state;

  bool get isMaking => _state is ImagesMaking;

  /// Starts a picture from [prompt] ([seed] null: random). Does nothing while one is being made.
  Future<void> make(String prompt, {int? seed}) async {
    if (_disposed || isMaking) return;
    _set(const ImagesMaking(phase: ImagesPhase.loading));
    try {
      final status = await host.makeImage(ImageRequestMessage(prompt: prompt, seed: seed));
      if (_disposed) return;
      // Events can arrive before the answer; only a request that is still waiting is changed here.
      if (status != ImageStartStatus.started && isMaking) _set(ImagesFailed(_startFailureCode(status)));
    } on Object {
      if (!_disposed && isMaking) _set(const ImagesFailed('failed'));
    }
  }

  /// Asks for the picture being made to stop; the state returns to idle when the helper confirms.
  void stop() {
    if (_disposed || !isMaking) return;
    unawaited(_stopQuietly());
  }

  Future<void> _stopQuietly() async {
    try {
      await host.stopImage();
    } on Object {
      // The helper may already be gone: its end event decides the state.
    }
  }

  static String _startFailureCode(ImageStartStatus status) => switch (status) {
    ImageStartStatus.noPack => 'no_pack',
    ImageStartStatus.unsupported => 'unsupported',
    ImageStartStatus.busy => 'busy',
    ImageStartStatus.started => 'failed',
  };

  void _onEvent(ImageEventMessage e) {
    if (_disposed || !isMaking) return;
    switch (e.kind) {
      case ImageEventKind.loading:
        _set(const ImagesMaking(phase: ImagesPhase.loading));
      case ImageEventKind.step:
        _set(ImagesMaking(phase: ImagesPhase.sampling, step: e.step, steps: e.steps));
      case ImageEventKind.decoding:
        _set(const ImagesMaking(phase: ImagesPhase.decoding));
      case ImageEventKind.done:
        final path = e.path;
        _set(path == null ? const ImagesFailed('failed') : ImagesDone(path: path, millis: e.millis ?? 0));
      case ImageEventKind.cancelled:
        _set(const ImagesIdle());
      case ImageEventKind.error:
        _set(ImagesFailed(e.error ?? 'failed'));
    }
  }

  void _set(ImagesState next) {
    if (next == _state) return;
    _state = next;
    notifyListeners();
  }

  @override
  void dispose() {
    if (_disposed) return;
    final wasMaking = isMaking;
    _disposed = true;
    unawaited(_subscription?.cancel());
    _subscription = null;
    if (wasMaking) unawaited(_stopQuietly());
    super.dispose();
  }
}
