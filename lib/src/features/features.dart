// SPDX-License-Identifier: GPL-3.0-or-later
//
// OWNER: Wave 2-D. Entry point for the emoji, clipboard and editing panels.
// keyboard_main.dart calls createPanelsFeature(); keep that signature.
//
// Wiring: one feature per keyboard session. It owns the emoji and clipboard stores, the emoji
// suggestion decorator, the clipboard watcher and the selection chips, and returns the toolbar hooks
// that open the panels.
import 'dart:async';

import '../bridge/messages.g.dart';
import '../core/data_sections.dart';
import '../keyboard/keyboard_app.dart';
import '../keyboard/keyboard_session.dart';
import 'clipboard/clipboard_controller.dart';
import 'clipboard/clipboard_panel.dart';
import 'clipboard/clipboard_store.dart';
import 'editing/editing_panel.dart';
import 'editing/selection_chips.dart';
import 'emoji/emoji_glyphs.dart';
import 'emoji/emoji_panel.dart';
import 'emoji/emoji_repository.dart';
import 'emoji/emoji_store.dart';
import 'emoji/emoji_suggestions.dart';
import 'images/images_panel.dart';

/// Emoji, clipboard and editing panels, emoji suggestions and clipboard chips.
KeyboardFeature createPanelsFeature({EmojiRepository? emojiRepository}) => _PanelsFeature(emojiRepository);

class _PanelsFeature extends KeyboardFeature {
  _PanelsFeature(this._emojiRepository);

  /// Null in the app (the assets are read and decoded off the UI isolate). Tests pass one that reads the files.
  final EmojiRepository? _emojiRepository;

  EmojiServices? _emoji;
  ClipboardStore? _clipboard;
  SelectionChips? _selection;
  StreamSubscription<ClipMessage>? _clipSub;
  StreamSubscription<List<String>>? _dataSub;

  @override
  KeyboardHooks attach(KeyboardSession session) {
    final services = session.services;
    final platform = services.platform;
    Future<bool> onDevice(String name) async {
      final blobs = await platform.secureList();
      return blobs.any((b) => b.name == name);
    }

    final store = EmojiStore(
      blobs: services.secureStore,
      learningOff: () => !session.input.learningAllowed,
      exists: onDevice,
    );
    final repository = _emojiRepository ?? EmojiRepository.assets();
    final emoji = EmojiServices(
      session: session,
      repository: repository,
      store: store,
      glyphs: EmojiGlyphs(platform: platform, store: store),
    );
    _emoji = emoji;

    final clipboard = ClipboardStore(
      blobs: services.secureStore,
      settings: () => services.settings.value.clipboard,
      exists: onDevice,
    );
    _clipboard = clipboard;
    final clips = ClipboardController(session: session, store: clipboard);
    _clipSub = services.events.clipboard.listen(clips.onClip);

    final suggestions = EmojiSuggestions(
      repository: repository,
      store: store,
      enabled: () => services.settings.value.typing.emojiSuggestions,
      languages: () => emoji.languages,
    );
    session.input.decorators.add(suggestions.decorator);

    _selection = SelectionChips(session)..attach();
    _dataSub = services.events.settingsChanged.listen(_onDataChanged);

    return KeyboardHooks(
      onEmoji: () => session.openPanel(EmojiPanel(emoji)),
      onClipboard: () => session.openPanel(ClipboardPanel(session: session, store: clipboard)),
      onEditing: () => session.openPanel(EditingPanel(session)),
      onImages: () => session.openPanel(ImagesPanel()),
    );
  }

  /// Another engine (the settings app) changed the data: read it again.
  void _onDataChanged(List<String> sections) {
    if (DataSections.affects(sections, DataSections.emoji)) _emoji?.store.reload();
    if (DataSections.affects(sections, DataSections.clipboard)) _clipboard?.reload();
  }

  @override
  void detach() {
    unawaited(_clipSub?.cancel());
    unawaited(_dataSub?.cancel());
    _selection?.detach();
    _emoji?.store.dispose();
    _clipboard?.dispose();
  }
}
