// SPDX-License-Identifier: GPL-3.0-or-later
//
// OWNER: Wave 4-B. Japanese typing: while the active language is 'ja' and its layout composes, sets
// InputController.composer to a JapaneseComposer (romaji or 12-key kana, with kana-kanji conversion),
// and clears it otherwise. Loads the dict-ja-mozc pack off the UI isolate and the learned picks from
// the encrypted blob `learned_ja_words`. keyboard_main.dart calls createJapaneseFeature(); keep that
// signature.
//
// PRIVACY: nothing typed is logged; learned picks are saved only through SecureBlobStore and only
// when learning is allowed (the composer checks it on each commit).
import 'dart:async';
import 'dart:isolate';

import 'package:material_ui/material_ui.dart';

import '../../core/data_sections.dart';
import '../../core/log.dart';
import '../../engine/lang/japanese/japanese_composer.dart';
import '../../engine/lang/japanese/japanese_dictionary.dart';
import '../../engine/lang/japanese/japanese_learning.dart';
import '../../keyboard/keyboard_app.dart';
import '../../keyboard/keyboard_session.dart';
import '../../packs/installed_packs.dart';

KeyboardFeature createJapaneseFeature() => _JapaneseFeature();

/// The engine name of the Japanese dictionary pack (`dict-ja-mozc`).
const String _engine = 'mozc';

/// Loads the dictionary on another isolate. A top-level function, so the closure sent to the isolate
/// captures only [dir]: a closure made inside the feature would drag the composer (and its futures) along.
Future<JapaneseDictionary> _loadDictionaryInIsolate(String dir) => Isolate.run(() => JapaneseDictionary.load(dir));

/// The pack route in the settings app (BooBoardRoutes.packs).
const String _packsRoute = 'packs';

final Stopwatch _clock = Stopwatch()..start();

class _JapaneseFeature extends KeyboardFeature {
  KeyboardSession? _session;
  JapaneseComposer? _composer;
  final JapaneseLearning _learning = JapaneseLearning();
  final List<StreamSubscription<Object?>> _subs = [];

  bool _learnedLoaded = false;
  bool _dictLoading = false;
  bool _dictReloadQueued = false;
  JapaneseDictionary? _dict;

  @override
  KeyboardHooks attach(KeyboardSession session) {
    _session = session;
    session.activeLanguage.addListener(_sync);
    session.services.settings.addListener(_sync);
    _subs.add(
      session.services.events.settingsChanged.listen((sections) {
        if (DataSections.affects(sections, DataSections.packs)) _reloadDictionary();
        if (DataSections.affects(sections, DataSections.learned)) _reloadLearned();
      }),
    );
    _sync();
    return const KeyboardHooks();
  }

  @override
  void detach() {
    final s = _session;
    if (s == null) return;
    s.activeLanguage.removeListener(_sync);
    s.services.settings.removeListener(_sync);
    for (final sub in _subs) {
      unawaited(sub.cancel());
    }
    _subs.clear();
    final c = _composer;
    if (c != null && identical(s.input.composer.value, c)) s.input.composer.value = null;
    _composer = null;
    _session = null;
  }

  /// Sets or clears the composer for the active language and layout.
  void _sync() {
    final s = _session;
    if (s == null) return;
    final active = s.activeLanguage.value == 'ja' && s.activeLayout.composes;
    if (!active) {
      final c = _composer;
      if (c != null && identical(s.input.composer.value, c)) s.input.composer.value = null;
      return;
    }
    final composer = _composer ??= _createComposer(s);
    if (!identical(s.input.composer.value, composer)) s.input.composer.value = composer;
    _ensureLearned();
    _ensureDictionary();
  }

  JapaneseComposer _createComposer(KeyboardSession s) {
    final composer = JapaneseComposer(
      layoutId: () => s.activeLayout.id,
      settings: () => s.services.settings.value,
      learningAllowed: () => s.input.learningAllowed,
      clockMs: () => _clock.elapsedMilliseconds,
      learning: _learning,
      onLearned: _saveLearned,
      onNeedsDictionary: _showPackChip,
    );
    if (_dict != null) composer.setDictionary(_dict);
    return composer;
  }

  // ---- Learned picks --------------------------------------------------------

  void _ensureLearned() {
    if (_learnedLoaded) return;
    _learnedLoaded = true;
    _reloadLearned();
  }

  void _reloadLearned() {
    final s = _session;
    if (s == null) return;
    unawaited(() async {
      try {
        final bytes = await s.services.secureStore.read(JapaneseLearning.blobName);
        // Replace, not add: the blob is the saved truth (the settings app clears it).
        _learning.clear();
        _learning.absorb(JapaneseLearning.fromBytes(bytes));
      } on Object catch (e) {
        BooBoardLog.w('Japanese', 'learned words not read', e.runtimeType);
      }
    }());
  }

  void _saveLearned() {
    final s = _session;
    if (s == null) return;
    final bytes = _learning.toBytes();
    unawaited(
      s.services.secureStore.write(JapaneseLearning.blobName, bytes).catchError((Object e) {
        BooBoardLog.w('Japanese', 'learned words not saved', e.runtimeType);
      }),
    );
  }

  // ---- Dictionary pack -------------------------------------------------------

  void _reloadDictionary() {
    _dict = null;
    final c = _composer;
    if (c != null) c.setDictionary(null);
    if (_dictLoading) {
      _dictReloadQueued = true;
      return;
    }
    _ensureDictionary();
  }

  void _ensureDictionary() {
    final s = _session;
    final composer = _composer;
    if (s == null || composer == null || _dict != null || _dictLoading) return;
    _dictLoading = true;
    composer.setLoading(true);
    unawaited(() async {
      try {
        final found = await InstalledPacks(s.services.platform).open('ja', engine: _engine);
        if (found == null) {
          BooBoardLog.d('Japanese', 'no dictionary pack installed');
        } else {
          final sw = Stopwatch()..start();
          final dir = found.$2.path;
          final dict = await _loadDictionaryInIsolate(dir);
          _dict = dict;
          composer.setDictionary(dict);
          BooBoardLog.d(
            'Japanese',
            'dictionary loaded in ${sw.elapsedMilliseconds} ms: ${dict.entryCount} entries, ${dict.sizeInBytes} bytes',
          );
        }
      } on Object catch (e) {
        BooBoardLog.w('Japanese', 'dictionary not loaded', e.runtimeType);
      } finally {
        _dictLoading = false;
        composer.setLoading(false);
        if (_dictReloadQueued) {
          _dictReloadQueued = false;
          _reloadDictionary();
        }
      }
    }());
  }

  void _showPackChip() {
    final s = _session;
    if (s == null) return;
    s.showChip(
      StripChip(
        id: 'japanese.pack',
        label: 'Japanese needs a dictionary pack for kanji',
        icon: Icons.menu_book_outlined,
        semanticLabel: 'Japanese needs a dictionary pack for kanji. Open model packs',
        priority: 1,
        expiresAfter: const Duration(seconds: 12),
        onTap: () => unawaited(s.services.host.openSettings(_packsRoute)),
      ),
    );
  }
}
