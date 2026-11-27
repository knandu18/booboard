// SPDX-License-Identifier: GPL-3.0-or-later
//
// OWNER: Wave 3-D. Voice typing: hooks.onVoice opens the mic panel (the toolbar's mic button and a
// KeyType.voice key). Voice typing works in English only: hooks.voiceAvailable is true only while an English
// voice pack (Parakeet) is installed and the keyboard language is English, and the mic is hidden otherwise.
// Never opens in password fields or while incognito. keyboard_main.dart calls createVoiceFeature(); keep
// that signature.
import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../app/routes.dart';
import '../../core/data_sections.dart';
import '../../keyboard/keyboard_app.dart';
import '../../keyboard/keyboard_session.dart';
import 'voice_controller.dart';
import 'voice_panel.dart';

KeyboardFeature createVoiceFeature() => _VoiceFeature();

class _VoiceFeature extends KeyboardFeature {
  KeyboardSession? _session;
  StreamSubscription<List<String>>? _dataSub;

  /// An English voice pack is installed (read at attach and after a pack changed).
  bool _hasEnglishPack = false;
  final ValueNotifier<bool> _available = ValueNotifier(false);

  @override
  KeyboardHooks attach(KeyboardSession session) {
    _session = session;
    session.activeLanguage.addListener(_update);
    _dataSub = session.services.events.settingsChanged.listen(_onDataChanged);
    unawaited(_refreshPacks());
    return KeyboardHooks(onVoice: () => _open(session), voiceAvailable: _available);
  }

  void _update() {
    final session = _session;
    _available.value = session != null && _hasEnglishPack && isVoiceLanguage(session.activeLanguage.value);
  }

  void _onDataChanged(List<String> sections) {
    if (DataSections.affects(sections, DataSections.packs)) unawaited(_refreshPacks());
  }

  Future<void> _refreshPacks() async {
    final session = _session;
    if (session == null) return;
    try {
      _hasEnglishPack = hasEnglishVoicePack(await session.services.platform.listPacks());
    } on Object {
      _hasEnglishPack = false;
    }
    _update();
  }

  void _open(KeyboardSession session) {
    final input = session.input;
    // Voice is off in incognito: nothing is opened and nothing is recorded. Private fields allow it (2026-11-26).
    if (input.isIncognito) return;
    // English only: a voice key outside English does nothing.
    if (!isVoiceLanguage(session.activeLanguage.value)) return;

    final services = session.services;
    final settings = services.settings.value;
    final host = services.host;

    late final VoicePanel panel;
    final controller = VoiceController(
      host: host,
      events: services.events.voice,
      text: InputVoiceTextSink(
        editor: input.editor,
        finish: input.finishComposing,
        resync: input.resyncAfterExternalEdit,
      ),
      packId: settings.voice.modelId,
      enabled: settings.voice.enabled,
      language: session.activeLanguage.value,
    );
    controller.onFinished = () {
      if (identical(session.panel.value, panel)) session.closePanel();
    };
    panel = VoicePanel(
      controller: controller,
      openSettings: () => _openRoute(session, BooBoardRoutes.voice),
      openPacks: () => _openRoute(session, BooBoardRoutes.packs),
    );
    session.openPanel(panel);
    unawaited(controller.begin());
  }

  void _openRoute(KeyboardSession session, String route) {
    unawaited(
      session.services.host.openSettings(route).catchError((Object _) {
        // The settings app could not be opened: the panel keeps its message.
      }),
    );
  }

  @override
  void detach() {
    _session?.activeLanguage.removeListener(_update);
    unawaited(_dataSub?.cancel());
    _dataSub = null;
    _session = null;
  }
}
