// SPDX-License-Identifier: GPL-3.0-or-later
//
// Wires the keyboard to the platform: IME events, settings, layouts, the
// text engines' geometry, secure window and feedback configuration.
// Owned by KeyboardApp; no widgets here.
import 'dart:async';

import 'package:flutter/foundation.dart';

import '../bridge/messages.g.dart';
import '../core/input_field_info.dart';
import '../core/keyboard_services.dart';
import '../core/data_sections.dart';
import '../core/log.dart';
import '../core/seen_apps.dart';
import '../engine/contracts.dart';
import '../engine/lang/registry.dart';
import '../engine/suggest/text_predictor.dart' show BooBoardTextPredictor;
import '../settings/booboard_settings.dart';
import 'input/input_controller.dart';
import 'input/keyboard_page.dart';
import 'layout/layout_engine.dart';
import 'layout/layout_model.dart';
import 'layout/layout_repository.dart';
import 'panels/keyboard_panel.dart';

class KeyboardSession {
  KeyboardSession(this.services) {
    activeLanguage = ValueNotifier(services.settings.value.languages.active);
    _languageKey = _languageSignature();
    input = InputController(
      input: services.input,
      predictor: services.predictor,
      gestureDecoder: services.gestureDecoder,
      settings: () => services.settings.value,
      rulesFor: services.rulesFor,
      language: () => activeLanguage.value,
    );
    layouts = LayoutRepository(services.packs);
    seenApps = SeenAppsStore(services.secureStore);
    _start();
  }

  final KeyboardServices services;
  late final InputController input;
  late final LayoutRepository layouts;

  /// Bumped when layouts finish loading, so the view rebuilds.
  final ValueNotifier<int> layoutVersion = ValueNotifier(0);

  /// Material You palette from the system (null before it is fetched or below Android 12).
  final ValueNotifier<SystemColorsMessage?> systemColors = ValueNotifier(null);

  // ---- Wave 2 seams (orchestrator-owned) --------------------------------

  /// The open panel, or null for the normal strip and keys.
  final ValueNotifier<KeyboardPanel?> panel = ValueNotifier(null);

  /// Chips for the strip, highest priority first (see [StripChip]).
  final ValueNotifier<List<StripChip>> stripChips = ValueNotifier(const []);

  /// Apps the keyboard was used in (for the incognito picker).
  late final SeenAppsStore seenApps;

  final Map<String, Timer> _chipTimers = {};
  String? _ownPackage;

  /// Shows [panel] (replacing any open one). Panels open in every field, private ones included (2026-11-26:
  /// BooBoard is offline and encrypted everywhere; nothing typed in a private field is learned either way).
  void openPanel(KeyboardPanel next) {
    if (_disposed) return;
    final old = panel.value;
    if (identical(old, next)) return;
    input.redirect.value = null;
    panel.value = next;
    if (next.placement == PanelPlacement.strip) input.redirect.value = next.keyRedirect;
    if (old != null) _notifyClosed(old);
  }

  void closePanel() {
    final old = panel.value;
    if (old == null) return;
    input.redirect.value = null;
    panel.value = null;
    _notifyClosed(old);
  }

  void _notifyClosed(KeyboardPanel p) {
    try {
      p.onClosed();
    } on Object catch (e) {
      BooBoardLog.w('Keyboard', 'panel close failed', e.runtimeType);
    }
  }

  /// Adds or replaces (same id) a strip chip.
  void showChip(StripChip chip) {
    if (_disposed) return;
    _chipTimers.remove(chip.id)?.cancel();
    final list = [...stripChips.value.where((c) => c.id != chip.id), chip]
      ..sort((a, b) => b.priority.compareTo(a.priority));
    stripChips.value = List.unmodifiable(list);
    final ttl = chip.expiresAfter;
    if (ttl != null) _chipTimers[chip.id] = Timer(ttl, () => removeChip(chip.id));
  }

  void removeChip(String id) {
    _chipTimers.remove(id)?.cancel();
    if (_disposed || !stripChips.value.any((c) => c.id == id)) return;
    stripChips.value = List.unmodifiable(stripChips.value.where((c) => c.id != id));
  }

  final List<StreamSubscription<Object?>> _subs = [];
  final Map<String, KeyboardLayoutDef> _variantCache = {};
  FeedbackSettings? _pushedFeedback;
  bool? _secure;
  String? _geometryKey;
  bool _disposed = false;

  // ---- Wave 3 seams (orchestrator-owned): languages ----------------------

  /// The language whose layout is showing (`LanguageSettings.active`).
  late final ValueNotifier<LanguageId> activeLanguage;

  /// Text drawn on the space bar (the language's name when more than one is enabled), or null.
  final ValueNotifier<String?> spaceLabel = ValueNotifier(null);

  /// Set by a feature to replace [spaceLabel] (for example 'Hinglish'); null restores it.
  final ValueNotifier<String?> spaceLabelOverride = ValueNotifier(null);

  /// Extra words for the swipe decoder (Wave 3-B: romanised Indic words), asked with the blended
  /// languages each time templates are built. Call [rebuildGestureTemplates] after they change.
  final List<Iterable<LexiconEntry> Function(List<LanguageId> languages)> gestureWordSources = [];

  String _languageKey = '';
  LaidOutKeyboard? _lastLetters;

  /// Languages the predictor and decoder blend: the active one first (see [blendedLanguages]).
  List<LanguageId> get activeLanguages => blendedLanguages(services.settings.value.languages);

  LanguageInfo get activeInfo => languageInfo(activeLanguage.value);

  /// The layout choice of the active language.
  LayoutChoice get activeLayout => layoutChoiceFor(services.settings.value.languages, activeLanguage.value);

  bool get canSwitchLanguage => services.settings.value.languages.enabled.length > 1;

  /// Shows [to], or the next enabled language (in the user's order) when null. Saved to settings,
  /// so the settings app and the next keyboard start agree.
  Future<void> switchLanguage([LanguageId? to]) async {
    final l = services.settings.value.languages;
    if (l.enabled.isEmpty) return;
    final target = to ?? l.enabled[(l.enabled.indexOf(l.active) + 1) % l.enabled.length];
    if (target == l.active || !l.enabled.contains(target)) return;
    try {
      await services.settings.update(
        (s) => s.copyWith(languages: s.languages.copyWith(active: target)),
        sections: [SettingsSection.languages],
      );
    } on Object catch (err) {
      BooBoardLog.w('Keyboard', 'language switch failed', err.runtimeType);
    }
  }

  /// Rebuilds swipe templates with the current [gestureWordSources].
  void rebuildGestureTemplates() {
    final laid = _lastLetters;
    _geometryKey = null;
    if (laid != null) onLayout(laid, KeyboardPage.letters);
  }

  String _languageSignature() {
    final l = services.settings.value.languages;
    final layouts = [for (final e in l.layouts.entries) '${e.key}=${e.value}'].join(',');
    return [l.active, l.enabled.join(','), layouts, l.multilingual].join('|');
  }

  void _applyLanguage() {
    final l = services.settings.value.languages;
    activeLanguage.value = l.active;
    spaceLabel.value = l.enabled.length > 1 || l.active != 'en' ? activeInfo.spaceBarLabel : null;
  }

  Future<void> _start() async {
    final e = services.events;
    _subs
      ..add(
        e.startInput.listen((ev) {
          if (!ev.restarting || ev.field.isSensitive) closePanel();
          unawaited(input.startInput(ev.field, restarting: ev.restarting));
          _applySecure(ev.field);
          if (!ev.restarting) unawaited(_recordApp(ev.field));
        }),
      )
      ..add(e.settingsChanged.listen(_onDataChanged))
      ..add(e.selection.listen(input.onSelectionChanged))
      ..add(e.finishInput.listen((_) => input.finishInput()))
      ..add(e.trimMemory.listen((_) => _trimMemory()))
      ..add(e.systemColorsChanged.listen((_) => unawaited(_refreshSystemColors())));
    e.windowVisible.addListener(_onWindowVisible);
    services.settings.addListener(_onSettings);

    _pushFeedback();
    _applyBlockOffensive();
    _applyLanguage();
    _applySecure(e.field.value);
    unawaited(input.startInput(e.field.value));
    unawaited(_refreshSystemColors());
    unawaited(_setLanguages());
    unawaited(_loadLayouts());
  }

  Future<void> _setLanguages() async {
    try {
      await services.predictor.setActiveLanguages(activeLanguages);
    } on Object catch (err) {
      BooBoardLog.w('Keyboard', 'could not activate languages', err.runtimeType);
    }
  }

  Future<void> _loadLayouts() async {
    final l = services.settings.value.languages;
    // Every enabled language's letters, so switching never waits for a file.
    final letters = {_letterLayoutId(), for (final id in l.enabled) layoutChoiceFor(l, id).id};
    await layouts.preload([...letters, ...kAuxiliaryLayoutIds]);
    if (_disposed) return;
    _variantCache.clear();
    layoutVersion.value++;
  }

  Future<void> _refreshSystemColors() async {
    try {
      final colors = await services.platform.getSystemColors();
      if (!_disposed) systemColors.value = colors;
    } on Object catch (err) {
      BooBoardLog.w('Keyboard', 'system colors unavailable', err.runtimeType);
    }
  }

  void _onWindowVisible() {
    if (services.events.windowVisible.value) return;
    closePanel();
    unawaited(services.predictor.flush());
    unawaited(seenApps.flush());
  }

  /// The settings app changed stored data: reload what the keyboard keeps in memory.
  void _onDataChanged(List<String> sections) {
    if (DataSections.affects(sections, DataSections.learned)) {
      unawaited(
        services.predictor.reloadLearnedData().catchError(
          (Object e) => BooBoardLog.w('Keyboard', 'learned reload failed', e.runtimeType),
        ),
      );
    }
    if (DataSections.affects(sections, DataSections.seenApps)) seenApps.invalidate();
  }

  /// Remembers the app for the incognito picker: never while incognito, never BooBoard itself.
  Future<void> _recordApp(InputFieldInfo field) async {
    final pkg = field.packageName;
    if (pkg == null || pkg.isEmpty || input.isIncognito) return;
    try {
      _ownPackage ??= (await services.platform.getAppInfo()).packageName;
    } on Object {
      return;
    }
    if (pkg == _ownPackage || _disposed) return;
    await seenApps.record(pkg, labelOf: () => services.host.getAppLabel(pkg));
  }

  void _applyBlockOffensive() {
    final p = services.predictor;
    if (p is BooBoardTextPredictor) p.blockOffensive = services.settings.value.typing.blockOffensiveWords;
  }

  void _trimMemory() {
    services.predictor.trimMemory();
    services.gestureDecoder.trimMemory();
  }

  void _onSettings() {
    final languageKey = _languageSignature();
    if (languageKey != _languageKey) {
      _languageKey = languageKey;
      input.finishComposing();
      _applyLanguage();
      _geometryKey = null;
      unawaited(_setLanguages());
      unawaited(_loadLayouts());
    }
    _pushFeedback();
    _applyBlockOffensive();
    _applySecure(input.currentField);
    input.refreshSuggestions();
    _variantCache.clear();
  }

  void _pushFeedback() {
    final f = services.settings.value.feedback;
    final last = _pushedFeedback;
    if (last != null &&
        last.haptics == f.haptics &&
        last.hapticStrength == f.hapticStrength &&
        last.sounds == f.sounds &&
        last.soundVolume == f.soundVolume) {
      return;
    }
    _pushedFeedback = f;
    try {
      unawaited(
        services.host
            .setFeedbackConfig(
              FeedbackConfigMessage(
                hapticsEnabled: f.haptics,
                hapticStrength: f.hapticStrength,
                soundsEnabled: f.sounds,
                soundVolume: f.soundVolume,
              ),
            )
            .catchError((Object err) => BooBoardLog.w('Keyboard', 'feedback config failed', err.runtimeType)),
      );
    } on Object catch (err) {
      BooBoardLog.w('Keyboard', 'feedback config failed', err.runtimeType);
    }
  }

  /// FLAG_SECURE while a password field is focused, otherwise the user's setting.
  void _applySecure(InputFieldInfo field) {
    final secure = shouldSecureWindow(field, services.settings.value.privacy);
    if (secure == _secure) return;
    _secure = secure;
    try {
      unawaited(
        services.host.setSecureWindow(secure).catchError((Object err) {
          BooBoardLog.w('Keyboard', 'secure window failed', err.runtimeType);
          _secure = null;
        }),
      );
    } on Object catch (err) {
      BooBoardLog.w('Keyboard', 'secure window failed', err.runtimeType);
      _secure = null;
    }
  }

  // ---- Layouts ----------------------------------------------------------

  String _letterLayoutId() => activeLayout.id;

  /// The layout to show for [page], adapted to [field], the active language and the settings;
  /// null until loaded.
  KeyboardLayoutDef? layoutFor(KeyboardPage page, InputFieldInfo field, BooBoardSettings settings) {
    final id = layoutIdForPage(page, letters: _letterLayoutId());
    final base = layouts.peek(id);
    if (base == null) return null;
    final info = activeInfo;
    // Native digits only where text goes in; number, phone and date fields keep ASCII digits.
    final digits = settings.languages.nativeDigits && field.kind == FieldKind.text ? info.nativeDigits : null;
    final globe = canSwitchLanguage;
    final key = '$id|${info.id}|${field.preferredPage.name}|${settings.typing.numberRow}|$digits|$globe';
    return _variantCache[key] ??= () {
      switch (page) {
        case KeyboardPage.letters:
          var l = LayoutVariants.forField(base, field.preferredPage, domains: info.domains);
          if (settings.typing.numberRow) l = LayoutVariants.withNumberRow(l);
          if (globe) l = LayoutVariants.withLanguageKey(l);
          if (digits != null) l = LayoutVariants.withDigits(l, digits);
          return l;
        case KeyboardPage.symbols:
        case KeyboardPage.symbols2:
          var l = LayoutVariants.withCurrency(base, info.currency);
          if (digits != null) l = LayoutVariants.withDigits(l, digits);
          return l;
        case KeyboardPage.numpad:
        case KeyboardPage.phone:
        case KeyboardPage.datetime:
          return base;
      }
    }();
  }

  /// The view laid out [laid]. Letters layouts feed the spatial model and swipe decoder.
  void onLayout(LaidOutKeyboard laid, KeyboardPage page) {
    if (page != KeyboardPage.letters) return;
    _lastLetters = laid;
    final geometry = laid.toGeometry(layoutId: '${laid.layout.id}/g${laid.keyGap.toStringAsFixed(1)}');
    final key = '${geometry.cacheKey}|${activeLanguages.join(',')}';
    if (key == _geometryKey) return;
    _geometryKey = key;
    final sw = Stopwatch()..start();
    try {
      services.predictor.setGeometry(geometry);
      unawaited(
        services.gestureDecoder
            .prepare(
              geometry: geometry,
              languages: activeLanguages,
              extraWords: [
                for (final l in activeLanguages) ...services.predictor.learnedWords(l),
                for (final source in gestureWordSources) ...source(activeLanguages),
              ],
            )
            .catchError((Object err) => BooBoardLog.w('Keyboard', 'decoder prepare failed', err.runtimeType)),
      );
    } on Object catch (err) {
      BooBoardLog.w('Keyboard', 'geometry update failed', err.runtimeType);
    }
    BooBoardLog.d('Keyboard', 'geometry pushed (${geometry.keys.length} keys) in ${sw.elapsedMicroseconds} us');
  }

  void dispose() {
    _disposed = true;
    for (final s in _subs) {
      unawaited(s.cancel());
    }
    services.events.windowVisible.removeListener(_onWindowVisible);
    services.settings.removeListener(_onSettings);
    closePanel();
    for (final t in _chipTimers.values) {
      t.cancel();
    }
    _chipTimers.clear();
    unawaited(seenApps.flush());
    panel.dispose();
    stripChips.dispose();
    input.dispose();
    layoutVersion.dispose();
    systemColors.dispose();
    activeLanguage.dispose();
    spaceLabel.dispose();
    spaceLabelOverride.dispose();
  }
}
