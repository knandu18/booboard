// SPDX-License-Identifier: GPL-3.0-or-later
//
// OWNER: Wave 4-A. Chinese pinyin typing: sets InputController.composer to a PinyinComposer while the
// active language is 'zh' and its layout composes, and clears it otherwise. keyboard_main.dart calls
// createChineseFeature(); keep that signature.
//
// The dictionary is the installed dict-zh-rime-ice pack, read off the UI isolate the first time the
// language is active (the composer shows "loading" meanwhile). With no pack the composer stays off,
// letters type as English, and a strip chip points at Model packs. Learned picks are kept in memory
// and saved to the encrypted blob `learned_zh_phrases` a few seconds after a change.
//
// PRIVACY: nothing here logs text, candidates or picks. Learning happens only through the composer,
// which checks InputController.learningAllowed.
import 'dart:async';
import 'dart:isolate';

import 'package:material_ui/material_ui.dart';

import '../../app/routes.dart';
import '../../bridge/messages.g.dart';
import '../../core/data_sections.dart';
import '../../core/log.dart';
import '../../engine/lang/chinese/learned_phrases.dart';
import '../../engine/lang/chinese/pinyin_composer.dart';
import '../../engine/lang/chinese/zh_lexicon.dart';
import '../../keyboard/keyboard_app.dart';
import '../../keyboard/keyboard_session.dart';
import '../../packs/installed_packs.dart';

/// Loads the Chinese pack, or null when none is installed. Tests replace it.
typedef ChinesePackLoader = Future<ZhLoaded?> Function();

KeyboardFeature createChineseFeature() => ChineseFeature();

/// Reads the installed rime-ice dictionary pack, off the UI isolate.
Future<ZhLoaded?> loadInstalledChinesePack(PlatformHostApi platform) async {
  final found = await InstalledPacks(platform).open('zh', engine: 'rime-ice');
  if (found == null) return null;
  final (info, dir) = found;
  final pack = ZhPackInfo(id: info.id, name: info.name, sizeBytes: info.sizeBytes);
  final path = dir.path;
  return Isolate.run(() => readZhPackFiles(path, pack));
}

class ChineseFeature extends KeyboardFeature {
  ChineseFeature({this.loader});

  /// The strip chip shown when no pack is installed.
  static const String packChipId = 'chinese.pack';

  /// How long after a learned change the phrases are saved.
  static const Duration saveDelay = Duration(seconds: 3);

  /// Loads the pack; null uses the installed pack. Tests replace it.
  final ChinesePackLoader? loader;

  KeyboardSession? _s;
  final ZhLexicon lexicon = ZhLexicon();
  final LearnedPhrases _learned = LearnedPhrases();
  PinyinComposer? _composer;
  StreamSubscription<List<String>>? _sub;
  Timer? _saveTimer;
  bool _loadingPack = false;
  bool _packMissing = false;

  @override
  KeyboardHooks attach(KeyboardSession session) {
    _s = session;
    session.activeLanguage.addListener(_sync);
    session.services.settings.addListener(_sync);
    _sub = session.services.events.settingsChanged.listen(_onDataChanged);
    unawaited(_loadLearned());
    _sync();
    return const KeyboardHooks();
  }

  @override
  void detach() {
    final s = _s;
    if (s == null) return;
    s.activeLanguage.removeListener(_sync);
    s.services.settings.removeListener(_sync);
    _sub?.cancel();
    _sub = null;
    _saveTimer?.cancel();
    unawaited(_saveLearned());
    _detachComposer(s);
    s.removeChip(packChipId);
    _s = null;
  }

  /// Applies the feature to the active language: installs or removes the composer and the chip.
  void _sync() {
    final s = _s;
    if (s == null) return;
    final active = s.activeLanguage.value == 'zh' && s.activeLayout.composes;
    if (!active) {
      _detachComposer(s);
      s.removeChip(packChipId);
      return;
    }
    if (_packMissing) {
      _detachComposer(s);
      _showPackChip(s);
      return;
    }
    s.removeChip(packChipId);
    _attachComposer(s);
    _ensurePack();
  }

  void _attachComposer(KeyboardSession s) {
    final composer = _composer ??= PinyinComposer(
      lexicon: lexicon,
      options: () {
        final c = s.services.settings.value.chinese;
        return PinyinOptions(fuzzy: c.fuzzyPinyin, traditional: c.traditional);
      },
      learned: _learned,
      learningAllowed: () => s.input.learningAllowed,
      onLearned: _scheduleSave,
    );
    if (!identical(s.input.composer.value, composer)) s.input.composer.value = composer;
  }

  void _detachComposer(KeyboardSession s) {
    final composer = _composer;
    _composer = null;
    if (composer != null && identical(s.input.composer.value, composer)) s.input.composer.value = null;
  }

  void _showPackChip(KeyboardSession s) {
    s.showChip(
      StripChip(
        id: packChipId,
        label: 'Chinese needs a dictionary pack',
        icon: Icons.inventory_2_outlined,
        semanticLabel: 'Chinese needs a dictionary pack. Open model packs.',
        priority: 1,
        onTap: () => unawaited(s.services.host.openSettings(BooBoardRoutes.packs)),
      ),
    );
  }

  /// Reads the pack the first time it is needed. Until it arrives, the composer is attached and
  /// shows the loading state.
  void _ensurePack() {
    if (_loadingPack || lexicon.isLoaded) return;
    _loadingPack = true;
    lexicon.setLoading(true);
    unawaited(_loadPack());
  }

  Future<void> _loadPack() async {
    final s = _s;
    if (s == null) {
      _loadingPack = false;
      return;
    }
    ZhLoaded? loaded;
    try {
      final custom = loader;
      loaded = custom != null ? await custom() : await loadInstalledChinesePack(s.services.platform);
    } on Object catch (e) {
      BooBoardLog.w('Chinese', 'pack load failed', e.runtimeType);
      loaded = null;
    }
    _loadingPack = false;
    if (_s == null) return;
    if (loaded == null) {
      _packMissing = true;
      lexicon.setLoading(false);
      _sync();
      return;
    }
    lexicon.install(loaded);
    BooBoardLog.d('Chinese', 'pack loaded: ${loaded.dictionary.entryCount} entries');
    _sync();
  }

  void _onDataChanged(List<String> sections) {
    if (DataSections.affects(sections, DataSections.learned)) unawaited(_loadLearned());
    if (DataSections.affects(sections, DataSections.packs)) {
      _packMissing = false;
      lexicon.clear();
      _sync();
    }
  }

  Future<void> _loadLearned() async {
    final s = _s;
    if (s == null) return;
    try {
      final bytes = await s.services.secureStore.read(learnedZhBlobName);
      if (_s == null) return;
      _learned.replaceWith(LearnedPhrases.decode(bytes));
    } on Object catch (e) {
      BooBoardLog.w('Chinese', 'learned phrases unreadable', e.runtimeType);
    }
  }

  void _scheduleSave() {
    _saveTimer?.cancel();
    _saveTimer = Timer(saveDelay, () => unawaited(_saveLearned()));
  }

  Future<void> _saveLearned() async {
    final s = _s;
    if (s == null || !_learned.dirty) return;
    try {
      await s.services.secureStore.write(learnedZhBlobName, _learned.encode());
      _learned.dirty = false;
    } on Object catch (e) {
      BooBoardLog.w('Chinese', 'learned phrases not saved', e.runtimeType);
    }
  }
}
