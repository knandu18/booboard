// SPDX-License-Identifier: GPL-3.0-or-later
//
// CONTRACT (Wave 0). Kotlin -> Dart IME events as listenables and streams.
import 'dart:async';

import 'package:flutter/foundation.dart';

import '../core/input_field_info.dart';
import 'messages.g.dart';

@immutable
class StartInputEvent {
  const StartInputEvent({required this.field, required this.restarting, required this.inputView});

  final InputFieldInfo field;
  final bool restarting;

  /// true for onStartInputView (keyboard becoming visible for this field),
  /// false for onStartInput (connection only).
  final bool inputView;
}

class ImeEvents implements ImeFlutterApi {
  /// The focused field (updated on every onStartInput/onStartInputView).
  final ValueNotifier<InputFieldInfo> field = ValueNotifier(InputFieldInfo.plainText);

  /// Between onStartInputView and onFinishInputView.
  final ValueNotifier<bool> inputViewActive = ValueNotifier(false);

  /// IME window shown on screen.
  final ValueNotifier<bool> windowVisible = ValueNotifier(false);
  final ValueNotifier<WindowMetricsMessage?> metrics = ValueNotifier(null);
  final ValueNotifier<int> inlineSuggestionCount = ValueNotifier(0);

  final _startInput = StreamController<StartInputEvent>.broadcast(sync: true);
  final _finishInput = StreamController<void>.broadcast(sync: true);
  final _selection = StreamController<SelectionMessage>.broadcast(sync: true);
  final _clipboard = StreamController<ClipMessage>.broadcast();
  final _settings = StreamController<List<String>>.broadcast();
  final _trimMemory = StreamController<int>.broadcast();
  final _systemColors = StreamController<void>.broadcast();
  final _voice = StreamController<VoiceEventMessage>.broadcast(sync: true);
  final _images = StreamController<ImageEventMessage>.broadcast(sync: true);

  Stream<StartInputEvent> get startInput => _startInput.stream;
  Stream<void> get finishInput => _finishInput.stream;
  Stream<SelectionMessage> get selection => _selection.stream;
  Stream<ClipMessage> get clipboard => _clipboard.stream;
  Stream<List<String>> get settingsChanged => _settings.stream;
  Stream<int> get trimMemory => _trimMemory.stream;
  Stream<void> get systemColorsChanged => _systemColors.stream;

  /// Voice typing events (Wave 3-D), in the order Kotlin sent them.
  Stream<VoiceEventMessage> get voice => _voice.stream;

  /// Picture making events (Images), in the order Kotlin sent them. The last one is done, cancelled or error.
  Stream<ImageEventMessage> get images => _images.stream;

  /// Registers this object as the receiver of Kotlin callbacks.
  void attach() => ImeFlutterApi.setUp(this);

  void detach() => ImeFlutterApi.setUp(null);

  @override
  Future<void> onStartInput(EditorInfoMessage info, bool restarting) async {
    final f = InputFieldInfo.fromMessage(info);
    field.value = f;
    _startInput.add(StartInputEvent(field: f, restarting: restarting, inputView: false));
  }

  @override
  Future<void> onStartInputView(EditorInfoMessage info, bool restarting) async {
    final f = InputFieldInfo.fromMessage(info);
    field.value = f;
    inputViewActive.value = true;
    _startInput.add(StartInputEvent(field: f, restarting: restarting, inputView: true));
  }

  @override
  Future<void> onFinishInputView(bool finishingInput) async {
    inputViewActive.value = false;
  }

  @override
  Future<void> onFinishInput() async => _finishInput.add(null);

  @override
  Future<void> onUpdateSelection(SelectionMessage selection) async => _selection.add(selection);

  @override
  Future<void> onWindowShown() async => windowVisible.value = true;

  @override
  Future<void> onWindowHidden() async => windowVisible.value = false;

  @override
  Future<void> onClipboardChanged(ClipMessage clip) async => _clipboard.add(clip);

  @override
  Future<void> onConfigurationChanged(WindowMetricsMessage metrics) async => this.metrics.value = metrics;

  @override
  Future<void> onSystemColorsChanged() async => _systemColors.add(null);

  @override
  Future<void> onTrimMemory(int level) async => _trimMemory.add(level);

  @override
  Future<void> onSettingsChanged(List<String> sections) async => _settings.add(sections);

  @override
  Future<void> onInlineSuggestionsChanged(int count) async => inlineSuggestionCount.value = count;

  @override
  Future<void> onVoiceEvent(VoiceEventMessage event) async => _voice.add(event);

  @override
  Future<void> onImageEvent(ImageEventMessage event) async => _images.add(event);
}
