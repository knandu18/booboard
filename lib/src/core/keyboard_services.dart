// SPDX-License-Identifier: GPL-3.0-or-later
//
// CONTRACT (Wave 0). Everything the keyboard engine needs, created once in
// keyboardMain(). Tests build KeyboardServices with fakes.
import 'dart:async';

import '../bridge/ime_events.dart';
import '../bridge/input_sink.dart';
import '../bridge/messages.g.dart';
import '../engine/contracts.dart';
import '../engine/dictionary/lexicon_factory.dart';
import '../engine/gesture/decoder_factory.dart';
import '../engine/language_rules.dart';
import '../engine/suggest/predictor_factory.dart';
import '../packs/pack_repository.dart';
import '../settings/settings_store.dart';
import 'input_field_info.dart';
import 'secure_blob_store.dart';

class KeyboardServices {
  KeyboardServices({
    required this.input,
    required this.host,
    required this.platform,
    required this.events,
    required this.settings,
    required this.secureStore,
    required this.packs,
    required this.lexicons,
    required this.predictor,
    required this.gestureDecoder,
    this.rulesFor = languageRulesFor,
    this.dataDirectory,
  });

  /// Edits the focused field.
  final InputSink input;

  /// Window, feedback, clipboard, IME switching.
  final ImeHostApi host;
  final PlatformHostApi platform;
  final ImeEvents events;
  final SettingsStore settings;
  final SecureBlobStore secureStore;
  final PackRepository packs;
  final LexiconSource lexicons;
  final TextPredictor predictor;
  final GestureDecoder gestureDecoder;
  final LanguageRulesResolver rulesFor;

  /// App-private, no-backup directory for plain data files. Custom themes and their images live in
  /// `<dataDirectory>/themes`. Null in tests.
  final String? dataDirectory;

  static Future<KeyboardServices> create() async {
    final host = ImeHostApi();
    final platform = PlatformHostApi();
    final events = ImeEvents()..attach();

    final dataDir = await platform.getDataDirectory();
    final settings = await SettingsStore.open(directory: dataDir, notifyOther: platform.notifySettingsChanged);
    // 'data.*' ids are encrypted-data changes (KeyboardSession handles them), not settings.
    events.settingsChanged.listen((sections) {
      if (sections.any((s) => !s.startsWith('data.'))) unawaited(settings.reload());
    });

    final secure = PlatformSecureBlobStore(platform);
    final packs = BundledPackRepository();
    final lexicons = createLexiconSource(packs: packs);

    final services = KeyboardServices(
      input: PigeonInputSink(host),
      host: host,
      platform: platform,
      events: events,
      settings: settings,
      secureStore: secure,
      packs: packs,
      lexicons: lexicons,
      predictor: createTextPredictor(packs: packs, lexicons: lexicons, store: secure),
      gestureDecoder: createGestureDecoder(lexicons: lexicons),
      dataDirectory: dataDir,
    );

    // Kotlin may have delivered onStartInputView before Dart attached: resync.
    final info = await host.getCurrentEditorInfo();
    if (info != null) events.field.value = InputFieldInfo.fromMessage(info);
    events.metrics.value = await host.getWindowMetrics();
    events.inputViewActive.value = await host.isInputViewShown();
    events.windowVisible.value = events.inputViewActive.value;
    return services;
  }
}
