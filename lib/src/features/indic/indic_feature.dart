// SPDX-License-Identifier: GPL-3.0-or-later
//
// OWNER: Wave 3-B. Indic typing in English letters: sets InputController.transform / swipeTransform and KeyboardSession.gestureWordSources for the active language.
// keyboard_main.dart calls createIndicFeature(); keep that signature.
//
// When the active language is Indic and its layout transliterates (English letters):
//   * the strip shows native candidates for the composing word, plus the Latin word itself;
//   * space commits the best native candidate (an autocorrection of kind transliteration), unless
//     the typed word is a known English word, which then commits as typed;
//   * with Hinglish output, the Latin word commits as typed and the native words are only offered;
//   * swipe over the English letters maps romanised words to native words (not with Hinglish);
//   * never in sensitive fields or fields that disallow autocorrect (URL, email).
// The table loads once per language, off the UI isolate; until then the feature changes nothing.
import '../../core/log.dart';
import '../../engine/contracts.dart';
import '../../engine/lang/indic/indic_transliterator.dart';
import '../../engine/lang/indic/scheme.dart';
import '../../keyboard/keyboard_app.dart';
import '../../keyboard/keyboard_session.dart';

KeyboardFeature createIndicFeature() => _IndicFeature();

/// Swipe templates are built from the most frequent romanised words only.
const int _gestureWordLimit = 20000;

class _IndicFeature extends KeyboardFeature {
  KeyboardSession? _session;
  final Map<LanguageId, IndicTransliterator> _tables = {};
  final Map<LanguageId, List<LexiconEntry>> _gestureWords = {};
  final Map<LanguageId, Map<String, String>> _romanToNative = {};
  final Set<LanguageId> _loading = {};

  @override
  KeyboardHooks attach(KeyboardSession session) {
    _session = session;
    session.activeLanguage.addListener(_sync);
    session.services.settings.addListener(_sync);
    session.gestureWordSources.add(_gestureSource);
    _sync();
    return const KeyboardHooks();
  }

  @override
  void detach() {
    final s = _session;
    if (s == null) return;
    s.activeLanguage.removeListener(_sync);
    s.services.settings.removeListener(_sync);
    s.gestureWordSources.remove(_gestureSource);
    s.input.transform.value = null;
    s.input.swipeTransform.value = null;
    s.spaceLabelOverride.value = null;
    _session = null;
  }

  /// Applies the feature to the active language: installs or clears the transform and the swipe mapping.
  void _sync() {
    final s = _session;
    if (s == null) return;
    final lang = s.activeLanguage.value;
    final layout = s.activeLayout;
    final languages = s.services.settings.value.languages;
    final active = layout.transliterates && schemeFor(lang) != null;
    if (!active) {
      s.input.transform.value = null;
      s.input.swipeTransform.value = null;
      s.spaceLabelOverride.value = null;
      return;
    }
    final hinglish = languages.hinglishOutput;
    s.spaceLabelOverride.value = hinglish ? 'Hinglish' : null;
    s.input.transform.value = (base, context) => _transform(lang, hinglish, base, context);
    s.input.swipeTransform.value = hinglish ? null : (candidates) => _swipe(lang, candidates);
    _ensureLoaded(lang);
  }

  IndicTransliterator _tableFor(LanguageId lang) {
    final s = _session!;
    return _tables.putIfAbsent(lang, () => IndicTransliterator(language: lang, packs: s.services.packs));
  }

  void _ensureLoaded(LanguageId lang) {
    final t = _tableFor(lang);
    if (t.isLoaded || _loading.contains(lang)) return;
    _loading.add(lang);
    final sw = Stopwatch()..start();
    t.load().then<void>(
      (_) {
        _loading.remove(lang);
        BooBoardLog.d('Indic', 'table $lang: ${t.tableSize} entries in ${sw.elapsedMilliseconds} ms');
        final s = _session;
        if (s == null || s.activeLanguage.value != lang) return;
        s.rebuildGestureTemplates();
        s.input.refreshSuggestions();
      },
      onError: (Object err) {
        _loading.remove(lang);
        BooBoardLog.w('Indic', 'table $lang failed to load', err.runtimeType);
      },
    );
  }

  /// Romanised forms of the most frequent native words, for the swipe decoder (English letters only).
  List<LexiconEntry> _gestureSource(List<LanguageId> languages) {
    final s = _session;
    if (s == null || !s.activeLayout.transliterates) return const [];
    final lang = s.activeLanguage.value;
    if (!languages.contains(lang)) return const [];
    final cached = _gestureWords[lang];
    if (cached != null) return cached;
    final table = _tableFor(lang).table;
    if (table == null) return const [];
    final seen = <String>{};
    final out = <LexiconEntry>[];
    final romanToNative = <String, String>{};
    for (final e in table.bestPerNative(max: _gestureWordLimit)) {
      if (!seen.add(e.roman)) continue;
      romanToNative[e.roman] = e.native;
      out.add(LexiconEntry(e.roman, -3.0 - (255 - e.score) * 0.075));
    }
    _romanToNative[lang] = romanToNative;
    _gestureWords[lang] = out;
    return out;
  }

  List<Suggestion> _swipe(LanguageId lang, List<Suggestion> candidates) {
    final map = _romanToNative[lang];
    if (map == null || map.isEmpty) return candidates;
    return [
      for (final c in candidates)
        if (map[c.text.toLowerCase()] case final native?)
          Suggestion(native, kind: c.kind, score: c.score, language: lang)
        else
          c,
    ];
  }

  SuggestionResult _transform(LanguageId lang, bool hinglish, SuggestionResult base, TypingContext context) {
    final s = _session;
    final field = context.field;
    if (s == null || field.isSensitive || !field.allowsAutoCorrect) return base;
    final composing = context.composing;
    if (composing.isEmpty || !_isLatinWord(composing)) return base;
    final table = _tableFor(lang);
    if (!table.isLoaded) {
      _ensureLoaded(lang);
      return base;
    }
    final natives = table.transliterate(composing, max: 3);
    if (natives.isEmpty) return base;

    final english = s.services.predictor.isKnownWord(composing);
    final typed = Suggestion(composing, kind: SuggestionKind.typed);
    final out = <Suggestion>[];
    if (english) {
      // A real English word: the native word comes first in the strip, the English word stays.
      out
        ..add(natives.first)
        ..add(typed)
        ..addAll(base.suggestions.where((b) => b.text != composing))
        ..addAll(natives.skip(1));
    } else {
      out
        ..addAll(natives)
        ..add(typed);
    }
    final dedup = <String>{};
    final list = [
      for (final x in out)
        if (dedup.add(x.text)) x,
    ];
    final Suggestion? auto = (english || hinglish) ? null : natives.first;
    return SuggestionResult(suggestions: list.take(6).toList(), autoCorrection: auto);
  }

  static bool _isLatinWord(String word) {
    for (final unit in word.codeUnits) {
      final isLetter = (unit >= 0x61 && unit <= 0x7A) || (unit >= 0x41 && unit <= 0x5A);
      if (!isLetter && unit != 0x27) return false;
    }
    return true;
  }
}
