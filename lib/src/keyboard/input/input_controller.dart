// SPDX-License-Identifier: GPL-3.0-or-later
//
// InputController: the keyboard's typing brain. Pure Dart: it talks to the
// editor only through [InputSink], so it is unit-tested against FakeEditor.
//
// PRIVACY: never log typed text. Only events and sizes go to BooBoardLog.
import 'dart:async';

import 'package:characters/characters.dart';
import 'package:flutter/foundation.dart';

import '../../bridge/input_sink.dart';
import '../../bridge/messages.g.dart';
import '../../core/input_field_info.dart';
import '../../core/log.dart';
import '../../engine/contracts.dart';
import '../../engine/language_rules.dart';
import '../../settings/booboard_settings.dart';
import 'composer.dart';
import 'keyboard_page.dart';

export 'composer.dart';

/// One-shot shift, caps lock, or off.
enum ShiftState { off, once, caps }

/// Receives typed keys instead of the editor while a panel (for example emoji search) has focus.
/// Set [InputController.redirect]; clear it when the panel closes.
abstract interface class KeyRedirect {
  /// A character key, already cased, or a popup alternative.
  void onText(String text);
  void onSpace();
  void onBackspace();
  void onEnter();
}

/// What a [SuggestionDecorator] sees.
@immutable
class SuggestionQuery {
  const SuggestionQuery({required this.composing, required this.previousWords, required this.field});

  /// The word being typed; empty for next-word predictions.
  final String composing;

  /// Up to 3 committed words before the cursor, oldest first.
  final List<String> previousWords;
  final InputFieldInfo field;
}

/// Adds or reorders suggestions from another source (emoji, personal shortcuts). [base] is best
/// first. Return a new list; it must be cheap (runs on every key press, budget 1 ms).
typedef SuggestionDecorator = List<Suggestion> Function(List<Suggestion> base, SuggestionQuery query);

/// Replaces the predictor's result while a language needs it (Wave 3-B: Indic typing in English
/// letters turns "namaste" into नमस्ते). [base] already blends the active languages. A returned
/// `autoCorrection` of kind [SuggestionKind.transliteration] is applied on space even when the user
/// turned autocorrect off (it is the typing method, not a correction); it is still never applied in
/// sensitive fields or fields that disallow autocorrect (email, URL). Budget: 2 ms.
typedef SuggestionTransform = SuggestionResult Function(SuggestionResult base, TypingContext context);

/// Rewrites swipe candidates before the first one is committed (Wave 3-B: romanised swipe to
/// native script). Budget: 2 ms.
typedef SwipeTransform = List<Suggestion> Function(List<Suggestion> candidates);

/// What the suggestion strip shows.
@immutable
class SuggestionBarState {
  const SuggestionBarState({
    this.suggestions = const [],
    this.autoCorrection,
    this.isComposing = false,
    this.typedWordUnknown = false,
    this.fromSwipe = false,
  });

  static const SuggestionBarState empty = SuggestionBarState();

  /// Best first.
  final List<Suggestion> suggestions;

  /// The correction that will be applied on the next separator, if any.
  final Suggestion? autoCorrection;
  final bool isComposing;

  /// The literal typed word is not in any active lexicon (shown in quotes).
  final bool typedWordUnknown;

  /// Alternatives for the word just swiped (the first one is already committed).
  final bool fromSwipe;
}

/// Whether the keyboard window must hide from screenshots.
bool shouldSecureWindow(InputFieldInfo field, PrivacySettings privacy) =>
    field.isSensitive || field.noPersonalizedLearning || privacy.hideFromScreenshots;

enum _SpaceState {
  none,

  /// The user typed a space after a word.
  typedAfterWord,

  /// A space we inserted after a picked suggestion or swipe (punctuation may swallow it).
  autoAfterPick,

  /// A space we inserted after punctuation (a further space press is ignored).
  autoAfterPunct,
}

class _Correction {
  const _Correction({required this.original, required this.corrected, required this.committedLength});

  final String original;
  final String corrected;

  /// UTF-16 length of everything committed for this correction (word + separator output).
  final int committedLength;
}

class _SwipeRecord {
  const _SwipeRecord({required this.leading, required this.word, required this.candidates});

  /// Space inserted before the word (may be empty).
  final String leading;
  final String word;
  final List<Suggestion> candidates;

  /// Word plus its trailing space.
  int get bodyLength => word.length + 1;
}

class InputController {
  InputController({
    required this._input,
    required this._predictor,
    required GestureDecoder gestureDecoder,
    required this._settings,
    this._rulesFor = languageRulesFor,
    LanguageId Function()? language,
    int Function()? clock,
  }) : _decoder = gestureDecoder,
       _language = language ?? (() => 'en'),
       _clock = clock ?? _defaultClock() {
    composer.addListener(_onComposerSet);
  }

  static int Function() _defaultClock() {
    final sw = Stopwatch()..start();
    return () => sw.elapsedMilliseconds;
  }

  /// Selection events this soon after our own edit are assumed to be echoes.
  static const int selfEventGraceMs = 150;

  /// Two shift taps within this time lock caps.
  static const int doubleTapMs = 300;

  final InputSink _input;
  final TextPredictor _predictor;
  final GestureDecoder _decoder;
  final BooBoardSettings Function() _settings;
  final LanguageRulesResolver _rulesFor;
  final LanguageId Function() _language;
  final int Function() _clock;

  // ---- Observable state -------------------------------------------------

  final ValueNotifier<InputFieldInfo> field = ValueNotifier(InputFieldInfo.plainText);
  final ValueNotifier<ShiftState> shift = ValueNotifier(ShiftState.off);
  final ValueNotifier<KeyboardPage> page = ValueNotifier(KeyboardPage.letters);
  final ValueNotifier<SuggestionBarState> bar = ValueNotifier(SuggestionBarState.empty);

  // ---- Wave 2 seams (orchestrator-owned) --------------------------------

  /// While non-null, character, space, enter and backspace keys go here instead of the editor,
  /// and swipe typing is off. Shift and page keys still work.
  final ValueNotifier<KeyRedirect?> redirect = ValueNotifier(null);

  /// Extra suggestion sources, applied in order after the predictor. Only consulted where
  /// suggestions are allowed (never in password or no-suggestion fields).
  final List<SuggestionDecorator> decorators = [];

  // ---- Wave 3 seams (orchestrator-owned) --------------------------------

  /// See [SuggestionTransform]. Set by a language feature for the active language; null otherwise.
  final ValueNotifier<SuggestionTransform?> transform = ValueNotifier(null);

  /// See [SwipeTransform].
  final ValueNotifier<SwipeTransform?> swipeTransform = ValueNotifier(null);

  /// The language whose rules apply now (the session's active language).
  LanguageId get language => _language();

  // ---- Wave 4 seams (orchestrator-owned) --------------------------------

  /// See [TextComposer] (composer.dart). Set by the Chinese or Japanese feature for the active
  /// language and layout; null otherwise. Setting a new one resets the old one.
  final ValueNotifier<TextComposer?> composer = ValueNotifier(null);

  /// What the composer shows now: the candidate strip and grid listen to it. Empty without one.
  final ValueNotifier<ComposerState> composerState = ValueNotifier(ComposerState.empty);

  /// Keys go to [composer] in this field: a text field that is not a password, on a letters-first
  /// field (not email/URL/number), and not forceAscii. A panel's [redirect] still comes first.
  bool get composerActive {
    if (composer.value == null) return false;
    final f = field.value;
    return f.kind == FieldKind.text && !f.isSensitive && !f.forceAscii && f.preferredPage == PreferredPage.letters;
  }

  // ---- Private state ----------------------------------------------------

  String _composing = '';
  final List<KeyTap> _taps = [];

  /// The composer's preedit as last sent to the editor.
  String _shownPreedit = '';
  TextComposer? _attachedComposer;
  SuggestionResult _lastResult = SuggestionResult.empty;

  /// Text just before the cursor, excluding the composing word (a mirror of the editor).
  String _before = '';
  List<String> _previous = const [];

  _SpaceState _space = _SpaceState.none;
  _Correction? _lastCorrection;
  _SwipeRecord? _lastSwipe;
  String? _noCorrectionWord;

  bool _autoShifted = false;
  int _lastShiftTapMs = -100000;

  int _seq = 0;
  int _startGen = 0;
  int _editDepth = 0;
  int _lastEditMs = 0;

  // ---- Derived ----------------------------------------------------------

  InputFieldInfo get currentField => field.value;
  BooBoardSettings get settings => _settings();
  LanguageRules get _rules => _rulesFor(_language());

  /// The word being composed (empty when none). Exposed for tests and the view.
  String get composing => _composing;

  /// Up to 3 words before the cursor, oldest first.
  List<String> get previousWords => List.unmodifiable(_previous);

  bool get _raw => field.value.isRawKeyMode;
  bool get _sensitive => field.value.isSensitive;

  /// Composing text (and suggestions) only in ordinary text fields.
  bool get _composeEnabled => !_raw && field.value.allowsSuggestions;

  /// Smart spacing (double space, punctuation spacing) only where autocorrect would be allowed.
  bool get _smartField => field.value.allowsAutoCorrect;

  bool get isIncognito {
    final p = settings.privacy;
    return p.incognito || (field.value.packageName != null && p.incognitoApps.contains(field.value.packageName));
  }

  bool get learningAllowed => field.value.allowsLearning && settings.privacy.learning && !isIncognito;

  bool get _contextReadable => field.value.kind == FieldKind.text && !_sensitive;

  // ---- Edit bracket -----------------------------------------------------

  void _begin() {
    _editDepth++;
    _seq++;
    _lastEditMs = _clock();
  }

  void _end() {
    _editDepth--;
    _lastEditMs = _clock();
  }

  void _send(Future<Object?> call) {
    unawaited(
      call.then<void>((_) {}, onError: (Object e) => BooBoardLog.w('Input', 'editor call failed', e.runtimeType)),
    );
  }

  void _batch(void Function() body) {
    _send(_input.beginBatchEdit());
    try {
      body();
    } finally {
      _send(_input.endBatchEdit());
    }
  }

  // ---- Mirror helpers ---------------------------------------------------

  void _mirrorAppend(String text) {
    if (_sensitive) return; // never keep password text around
    var next = _before + text;
    if (next.length > 256) next = next.substring(next.length - 128);
    _before = next;
  }

  void _mirrorDeleteUnits(int units) {
    _before = units >= _before.length ? '' : _before.substring(0, _before.length - units);
  }

  String? get _prevChar => _before.isEmpty ? null : _before.characters.last;

  static final RegExp _letterRe = RegExp(r'^[\p{L}\p{M}]', unicode: true);
  static final RegExp _digitRe = RegExp(r'^\p{Nd}', unicode: true);
  static final RegExp _camelRe = RegExp(r'\p{Ll}\p{Lu}', unicode: true);

  bool _isLetter(String c) => _letterRe.hasMatch(c);
  bool _isDigit(String c) => _digitRe.hasMatch(c);

  List<String> _wordsOf(String text) {
    final rules = _rules;
    final words = <String>[];
    final b = StringBuffer();
    for (final ch in text.characters) {
      if (rules.isWordChar(ch)) {
        b.write(ch);
      } else if (b.isNotEmpty) {
        words.add(b.toString());
        b.clear();
      }
    }
    if (b.isNotEmpty) words.add(b.toString());
    return words.length <= 3 ? words : words.sublist(words.length - 3);
  }

  void _pushPrevious(String word) {
    final next = [..._previous, word];
    _previous = next.length <= 3 ? next : next.sublist(next.length - 3);
  }

  bool get _startOfSentence {
    final trimmed = _before.trimRight();
    if (trimmed.isEmpty) return true;
    if (trimmed.length == _before.length) return false;
    return _rules.endsSentence(trimmed.characters.last);
  }

  // ---- Field lifecycle --------------------------------------------------

  /// A field gained focus (or restarted). [restarting] keeps page and shift when the field is unchanged.
  Future<void> startInput(InputFieldInfo f, {bool restarting = false}) async {
    final same = restarting && f == field.value;
    final gen = ++_startGen;
    // A restart keeps what was being typed in the field; a new field starts clean.
    _dropComposer(finish: restarting);
    if (restarting && _composing.isNotEmpty) {
      _composing = '';
      _taps.clear();
      _send(_input.finishComposingText());
    }
    field.value = f;
    _resetTransient();
    _lastEditMs = _clock();
    if (!same) {
      page.value = KeyboardPage.forField(f.preferredPage);
      shift.value = ShiftState.off;
      _autoShifted = false;
    }
    _before = '';
    _previous = const [];
    _setBar(SuggestionBarState.empty);
    final req = _capsRequest();
    if (req != 0 && !same) _applyCaps(f.initialCapsMode & req);
    if (!_contextReadable) return;
    final text = await _input.getTextBeforeCursor(64);
    if (gen != _startGen) return;
    _before = text ?? '';
    _previous = _wordsOf(_before);
    _updateSuggestions();
    await _refreshCaps();
  }

  /// The connection ended: commit what is composing and forget it.
  void finishInput() {
    _startGen++;
    _dropComposer();
    if (_composing.isNotEmpty) {
      _composing = '';
      _taps.clear();
      _send(_input.finishComposingText());
    }
    _resetTransient();
    _setBar(SuggestionBarState.empty);
  }

  void _resetTransient() {
    _seq++;
    _composing = '';
    _taps.clear();
    _lastResult = SuggestionResult.empty;
    _space = _SpaceState.none;
    _lastCorrection = null;
    _lastSwipe = null;
    _noCorrectionWord = null;
  }

  /// Feed `events.selection` here.
  void onSelectionChanged(SelectionMessage m) {
    if (_editDepth > 0) return;
    if (_clock() - _lastEditMs < selfEventGraceMs) return;
    if (_composing.isNotEmpty || _shownPreedit.isNotEmpty) {
      final consistent = m.newSelStart == m.newSelEnd && m.candidatesStart >= 0 && m.newSelStart == m.candidatesEnd;
      if (consistent) return;
    }
    _onExternalChange();
  }

  void _onExternalChange() {
    _begin();
    try {
      _dropComposer();
      if (_composing.isNotEmpty) {
        _composing = '';
        _taps.clear();
        _send(_input.finishComposingText());
      }
      _resetTransient();
      _setBar(SuggestionBarState.empty);
    } finally {
      _end();
    }
    unawaited(_resyncContext());
  }

  Future<void> _resyncContext() async {
    if (!_contextReadable) return;
    final seq = _seq;
    final text = await _input.getTextBeforeCursor(64);
    if (seq != _seq) return;
    _before = text ?? '';
    _previous = _wordsOf(_before);
    _updateSuggestions();
    await _refreshCaps();
  }

  // ---- Pages and shift --------------------------------------------------

  void setPage(KeyboardPage p) {
    if (page.value == p) return;
    page.value = p;
  }

  /// Tap on the shift key: one-shot, or caps lock on a quick second tap.
  void onShiftTap() {
    final now = _clock();
    final quick = now - _lastShiftTapMs <= doubleTapMs;
    _lastShiftTapMs = now;
    _autoShifted = false;
    switch (shift.value) {
      case ShiftState.off:
        shift.value = ShiftState.once;
      case ShiftState.once:
        shift.value = quick ? ShiftState.caps : ShiftState.off;
      case ShiftState.caps:
        shift.value = ShiftState.off;
    }
  }

  void _consumeShift() {
    if (shift.value == ShiftState.once) {
      shift.value = ShiftState.off;
      _autoShifted = false;
    }
  }

  int _capsRequest() {
    final f = field.value;
    final s = settings;
    if (!s.typing.autoCapitalize || !_rules.hasCase || _raw || _sensitive || f.kind != FieldKind.text) return 0;
    var req = 0;
    if (f.capCharacters) req |= AndroidCapsMode.characters;
    if (f.capWords) req |= AndroidCapsMode.words;
    if (f.capSentences) req |= AndroidCapsMode.sentences;
    return req;
  }

  void _applyCaps(int mode) {
    if (mode == 0) {
      if (_autoShifted && shift.value == ShiftState.once) shift.value = ShiftState.off;
      _autoShifted = false;
      return;
    }
    if (mode & AndroidCapsMode.characters != 0) {
      shift.value = ShiftState.caps;
      return;
    }
    if (shift.value == ShiftState.off) {
      shift.value = ShiftState.once;
      _autoShifted = true;
    }
  }

  Future<void> _refreshCaps() async {
    final req = _capsRequest();
    if (req == 0) return;
    final seq = _seq;
    final mode = await _input.getCursorCapsMode(req);
    if (seq != _seq) return;
    _applyCaps(mode & req);
  }

  // ---- Typing -----------------------------------------------------------

  bool _isComposable(String text) {
    if (!_rules.isWordChar(text)) return false;
    if (_composing.isNotEmpty) return true;
    // A word starts with a letter: digits, apostrophes and dashes alone are not words.
    return _isLetter(text);
  }

  /// A character key (already cased by the view) or a popup alternative.
  void onText(String text, {TouchPoint? point}) {
    if (text.isEmpty) return;
    final r = redirect.value;
    if (r != null) {
      r.onText(text);
      _consumeShift();
      return;
    }
    _begin();
    try {
      if (_toComposer((c) => c.onText(text))) {
        _consumeShift();
        return;
      }
      _lastCorrection = null;
      _lastSwipe = null;
      final single = text.characters.length == 1;
      if (!single) {
        _commitLiteral(text);
      } else if (_composeEnabled && _isComposable(text)) {
        _composing += text;
        _taps.add(KeyTap(text, point));
        _space = _SpaceState.none;
        _send(_input.setComposingText(_composing));
        _updateSuggestions();
      } else if (_composeEnabled) {
        _onSeparator(text);
      } else {
        _commitPlain(text);
      }
      _consumeShift();
    } finally {
      _end();
    }
  }

  void _commitPlain(String text) {
    _send(_input.commitText(text));
    _mirrorAppend(text);
    _space = _SpaceState.none;
  }

  /// Multi-character outputs such as ".com" or "R$".
  void _commitLiteral(String text) {
    if (_composing.isNotEmpty || _shownPreedit.isNotEmpty) _commitComposingAsTyped();
    _commitPlain(text);
    _updateSuggestions();
  }

  /// Transliteration is the typing method itself, so the autocorrect setting does not turn it off.
  bool _canApply(Suggestion s, String word) {
    if (s.kind != SuggestionKind.transliteration) return _canAutoCorrect(word);
    return field.value.allowsAutoCorrect && !_sensitive && _noCorrectionWord != word;
  }

  bool _canAutoCorrect(String word) {
    if (!settings.typing.autoCorrect || !field.value.allowsAutoCorrect || _sensitive) return false;
    if (_noCorrectionWord == word) return false;
    if (word.characters.any(_isDigit)) return false;
    // Never touch handles, tags, paths and camelCase tokens.
    final before = _prevChar;
    if (before == '@' || before == '#' || before == '/') return false;
    if (_camelRe.hasMatch(word)) return false;
    return true;
  }

  void _learn(String word) {
    if (word.isEmpty) return;
    _predictor.onWordCommitted(word, previousWords: List.of(_previous), allowLearning: learningAllowed);
    _pushPrevious(word);
  }

  /// Leaves the composing word in the editor as typed.
  void _commitComposingAsTyped() {
    _dropComposer();
    final word = _composing;
    if (word.isEmpty) return;
    _composing = '';
    _taps.clear();
    _send(_input.finishComposingText());
    _mirrorAppend(word);
    _learn(word);
    _lastResult = SuggestionResult.empty;
  }

  void _onSeparator(String sep) {
    if (sep == ' ') {
      _onSpaceInner();
      return;
    }
    final rules = _rules;
    final smart = _smartField && settings.typing.smartPunctuation;
    final hadComposing = _composing.isNotEmpty;
    var out = sep;
    var deleteBefore = 0;
    var nextSpace = _SpaceState.none;

    var word = _composing;
    Suggestion? applied;
    if (hadComposing) {
      final corr = _lastResult.autoCorrection;
      if (corr != null && corr.text != word && _canApply(corr, word)) {
        applied = corr;
        word = corr.text;
      }
    }

    if (!hadComposing && smart && _space == _SpaceState.autoAfterPick && rules.removesSpaceBefore(sep)) {
      deleteBefore = 1;
      if (rules.addsSpaceAfter(sep)) {
        out = '$sep ';
        nextSpace = _SpaceState.autoAfterPunct;
      }
    } else if (smart) {
      final thin = rules.spaceBefore(sep);
      final lastChar = hadComposing ? word.characters.last : _prevChar;
      if (thin != null && lastChar != null && (rules.isWordChar(lastChar))) out = '$thin$sep';
    }

    final original = _composing;
    if (hadComposing) {
      _composing = '';
      _taps.clear();
      _lastResult = SuggestionResult.empty;
      _send(_input.commitText('$word$out'));
      _mirrorAppend('$word$out');
      _learn(word);
      if (applied != null) {
        _lastCorrection = _Correction(original: original, corrected: word, committedLength: word.length + out.length);
      }
    } else if (deleteBefore > 0) {
      _batch(() {
        _send(_input.deleteSurroundingText(deleteBefore, 0));
        _send(_input.commitText(out));
      });
      _mirrorDeleteUnits(deleteBefore);
      _mirrorAppend(out);
    } else {
      _send(_input.commitText(out));
      _mirrorAppend(out);
    }
    _space = nextSpace;
    if (applied == null) _lastCorrection = null;
    _updateSuggestions();
    unawaited(_refreshCaps());
  }

  /// The space key.
  void onSpace() {
    final r = redirect.value;
    if (r != null) return r.onSpace();
    _begin();
    try {
      if (_toComposer((c) => c.onSpace())) {
        if (page.value.isSymbols) page.value = KeyboardPage.letters;
        _consumeShift();
        return;
      }
      _lastCorrection = null;
      _lastSwipe = null;
      if (!_composeEnabled) {
        _commitPlain(' ');
      } else {
        _onSpaceInner();
      }
      if (page.value.isSymbols) page.value = KeyboardPage.letters;
      _consumeShift();
    } finally {
      _end();
    }
  }

  void _onSpaceInner() {
    final s = settings.typing;
    final hadComposing = _composing.isNotEmpty;
    if (!hadComposing && _space == _SpaceState.autoAfterPunct) return;

    // Double space becomes ". ".
    if (!hadComposing &&
        s.doubleSpacePeriod &&
        _smartField &&
        (_space == _SpaceState.typedAfterWord || _space == _SpaceState.autoAfterPick) &&
        _before.endsWith(' ') &&
        _charBeforeLastSpaceIsWord()) {
      _batch(() {
        _send(_input.deleteSurroundingText(1, 0));
        _send(_input.commitText('. '));
      });
      _mirrorDeleteUnits(1);
      _mirrorAppend('. ');
      _space = _SpaceState.autoAfterPunct;
      _updateSuggestions();
      unawaited(_refreshCaps());
      return;
    }

    var word = _composing;
    Suggestion? applied;
    if (hadComposing) {
      final corr = _lastResult.autoCorrection;
      if (corr != null && corr.text != word && _canApply(corr, word)) {
        applied = corr;
        word = corr.text;
      }
      final original = _composing;
      _composing = '';
      _taps.clear();
      _lastResult = SuggestionResult.empty;
      _send(_input.commitText('$word '));
      _mirrorAppend('$word ');
      _learn(word);
      _lastCorrection = applied == null
          ? null
          : _Correction(original: original, corrected: word, committedLength: word.length + 1);
      _space = _SpaceState.typedAfterWord;
    } else {
      final prev = _prevChar;
      _send(_input.commitText(' '));
      _mirrorAppend(' ');
      _space = prev != null && prev != ' ' && prev != '\n' && (_rules.isWordChar(prev))
          ? _SpaceState.typedAfterWord
          : _SpaceState.none;
    }
    _updateSuggestions();
    unawaited(_refreshCaps());
  }

  bool _charBeforeLastSpaceIsWord() {
    final chars = _before.characters;
    if (chars.length < 2) return false;
    final c = chars.skipLast(1).last;
    return _rules.isWordChar(c);
  }

  /// The enter / action key.
  void onEnter() {
    final r = redirect.value;
    if (r != null) return r.onEnter();
    _begin();
    try {
      if (_toComposer((c) => c.onEnter())) return;
      _lastCorrection = null;
      _lastSwipe = null;
      _commitComposingAsTyped();
      final f = field.value;
      if (_raw) {
        _send(_input.sendDownUpKeyEvent(AndroidKeyCode.enter));
      } else if (f.enterInsertsNewline) {
        _send(_input.commitText('\n'));
        _mirrorAppend('\n');
      } else {
        _send(_input.performEditorAction(f.editorActionId));
      }
      _space = _SpaceState.none;
      _updateSuggestions();
      unawaited(_refreshCaps());
    } finally {
      _end();
    }
  }

  /// Long-press on enter in a multi-line field.
  void onEnterLongPress() {
    if (redirect.value != null) return;
    final f = field.value;
    if (_raw || !f.enterInsertsNewline || f.editorActionId == 0) return;
    _begin();
    try {
      _commitComposingAsTyped();
      _send(_input.performEditorAction(f.editorActionId));
    } finally {
      _end();
    }
  }

  // ---- Backspace --------------------------------------------------------

  void onBackspace() {
    final r = redirect.value;
    if (r != null) return r.onBackspace();
    _begin();
    try {
      if (_toComposer((c) => c.onBackspace())) return;
      _space = _SpaceState.none;
      if (_raw) {
        _send(_input.sendDownUpKeyEvent(AndroidKeyCode.del));
        return;
      }
      if (_composing.isNotEmpty) {
        _lastCorrection = null;
        _lastSwipe = null;
        _composing = _composing.characters.skipLast(1).string;
        if (_taps.isNotEmpty) _taps.removeLast();
        if (_composing.isEmpty) {
          _send(_input.commitText(''));
        } else {
          _send(_input.setComposingText(_composing));
        }
        _updateSuggestions();
        return;
      }
      final corr = _lastCorrection;
      if (corr != null) {
        _revertCorrection(corr);
        return;
      }
      final swipe = _lastSwipe;
      if (swipe != null) {
        _deleteSwipe(swipe);
        return;
      }
      _send(_input.sendDownUpKeyEvent(AndroidKeyCode.del));
      if (_before.isNotEmpty) _before = _before.characters.skipLast(1).string;
      _afterPlainDelete();
    } finally {
      _end();
    }
  }

  void _afterPlainDelete() {
    _updateSuggestions();
    unawaited(_resyncContext());
  }

  void _revertCorrection(_Correction c) {
    _lastCorrection = null;
    _batch(() {
      _send(_input.deleteSurroundingText(c.committedLength, 0));
      _send(_input.setComposingText(c.original));
    });
    _mirrorDeleteUnits(c.committedLength);
    _composing = c.original;
    _taps
      ..clear()
      ..addAll([for (final ch in c.original.characters) KeyTap(ch)]);
    _noCorrectionWord = c.original;
    _predictor.onAutoCorrectionReverted(original: c.original, correction: c.corrected);
    _updateSuggestions();
  }

  void _deleteSwipe(_SwipeRecord s) {
    _lastSwipe = null;
    final n = s.leading.length + s.bodyLength;
    _send(_input.deleteSurroundingText(n, 0));
    _mirrorDeleteUnits(n);
    if (_previous.isNotEmpty) _previous = _previous.sublist(0, _previous.length - 1);
    _updateSuggestions();
    unawaited(_resyncContext());
  }

  /// Backspace held for a long time: deletes a whole word (Wave 2 also uses this for swipe-to-delete).
  void deleteWordBackward() {
    final r = redirect.value;
    if (r != null) return r.onBackspace();
    _begin();
    try {
      // While a composer holds text, a held backspace deletes from its buffer one step at a time.
      if (_shownPreedit.isNotEmpty && _toComposer((c) => c.onBackspace())) return;
      _space = _SpaceState.none;
      _lastCorrection = null;
      _lastSwipe = null;
      if (_composing.isNotEmpty) {
        _composing = '';
        _taps.clear();
        _send(_input.commitText(''));
        _updateSuggestions();
        return;
      }
      if (_raw || _before.isEmpty) {
        _send(_input.sendDownUpKeyEvent(AndroidKeyCode.del));
        return;
      }
      final rules = _rules;
      final chars = _before.characters.toList();
      var i = chars.length;
      while (i > 0 && chars[i - 1].trim().isEmpty) {
        i--;
      }
      if (i > 0) {
        final wordy = rules.isWordChar(chars[i - 1]);
        while (i > 0 && chars[i - 1].trim().isNotEmpty && rules.isWordChar(chars[i - 1]) == wordy) {
          i--;
        }
      }
      final units = chars.sublist(i).join().length;
      if (units == 0) {
        _send(_input.sendDownUpKeyEvent(AndroidKeyCode.del));
        return;
      }
      _send(_input.deleteSurroundingText(units, 0));
      _mirrorDeleteUnits(units);
      _afterPlainDelete();
    } finally {
      _end();
    }
  }

  /// The Tab key (hardware-style key event).
  void sendTab() {
    _begin();
    try {
      _commitComposingAsTyped();
      _space = _SpaceState.none;
      _lastCorrection = null;
      _lastSwipe = null;
      _send(_input.sendDownUpKeyEvent(AndroidKeyCode.tab));
    } finally {
      _end();
    }
  }

  /// Moves the cursor by [delta] characters (hook for Wave 2's space-bar cursor control).
  void moveCursor(int delta) {
    if (delta == 0) return;
    _begin();
    try {
      if (_shownPreedit.isNotEmpty) {
        final code = delta < 0 ? ComposerKeys.cursorLeft : ComposerKeys.cursorRight;
        var handled = true;
        for (var i = 0; i < delta.abs() && handled; i++) {
          handled = _toComposer((c) => c.onCustomKey(code));
        }
        if (handled) return;
      }
      _commitComposingAsTyped();
      _space = _SpaceState.none;
      _lastCorrection = null;
      _lastSwipe = null;
      final key = delta < 0 ? AndroidKeyCode.dpadLeft : AndroidKeyCode.dpadRight;
      for (var i = 0; i < delta.abs(); i++) {
        _send(_input.sendDownUpKeyEvent(key));
      }
    } finally {
      _end();
    }
    unawaited(_resyncContext());
  }

  // ---- Panel editing API (Wave 2 seams) ----------------------------------

  /// Inserts literal text at the cursor (an emoji, a clipboard item). A word being typed is kept
  /// as typed first. Works in every field type, including passwords (no learning happens).
  void insertText(String text) {
    if (text.isEmpty) return;
    _begin();
    try {
      _lastCorrection = null;
      _lastSwipe = null;
      _commitLiteral(text);
      _consumeShift();
    } finally {
      _end();
    }
    unawaited(_refreshCaps());
  }

  /// Inserts a phrase that stands on its own (a translation): like [insertText], but a space goes first when
  /// the text before the cursor ends in a word or punctuation, so the phrase never sticks to it.
  void insertPhrase(String text) {
    final phrase = text.trim();
    if (phrase.isEmpty) return;
    final last = _composing.isNotEmpty || _shownPreedit.isNotEmpty ? 'x' : _prevChar;
    final glued = last != null && last.trim().isNotEmpty;
    insertText(glued ? ' $phrase' : phrase);
  }

  /// Ends composing (the word stays as typed). Call before editing through [editor] directly.
  void finishComposing() {
    if (_composing.isEmpty && _shownPreedit.isEmpty) return;
    _begin();
    try {
      _commitComposingAsTyped();
      _updateSuggestions();
    } finally {
      _end();
    }
  }

  /// Raw editor access for panels (selection, key events, context-menu actions). Call
  /// [finishComposing] first and [resyncAfterExternalEdit] after, so the controller's mirror of
  /// the text stays right.
  InputSink get editor => _input;

  /// Re-reads the text around the cursor after a panel changed it through [editor].
  void resyncAfterExternalEdit() => _onExternalChange();

  // ---- Suggestions ------------------------------------------------------

  void _setBar(SuggestionBarState s) => bar.value = s;

  /// Recomputes the strip. Call when suggestion-related settings change.
  void refreshSuggestions() => _updateSuggestions();

  void _updateSuggestions() {
    if (composerActive) {
      _setBar(SuggestionBarState(isComposing: composerState.value.isComposing));
      return;
    }
    final s = settings.typing;
    if (!_composeEnabled || !s.showSuggestions) {
      _lastResult = SuggestionResult.empty;
      _setBar(SuggestionBarState.empty);
      return;
    }
    if (_composing.isNotEmpty) {
      final context = TypingContext(
        composing: _composing,
        taps: List.unmodifiable(_taps),
        previousWords: List.unmodifiable(_previous),
        isStartOfSentence: _startOfSentence,
        field: field.value,
      );
      var result = _predictor.suggest(context);
      final t = transform.value;
      if (t != null) {
        try {
          result = t(result, context);
        } on Object catch (e) {
          BooBoardLog.w('Input', 'suggestion transform failed', e.runtimeType);
        }
      }
      _lastResult = result;
      final auto = result.autoCorrection;
      _setBar(
        SuggestionBarState(
          suggestions: _decorate(result.suggestions, _composing),
          autoCorrection: auto != null && _canApply(auto, _composing) ? auto : null,
          isComposing: true,
          typedWordUnknown: !_predictor.isKnownWord(_composing),
        ),
      );
      return;
    }
    _lastResult = SuggestionResult.empty;
    // Next-word predictions are prose ("The", "I", "Thanks"): only in fields where autocorrect is allowed,
    // never in email, URL, filter or similar fields.
    if (s.nextWordPrediction && _smartField) {
      _setBar(SuggestionBarState(suggestions: _decorate(_predictor.predictNext(List.of(_previous)), '')));
    } else {
      _setBar(SuggestionBarState.empty);
    }
  }

  List<Suggestion> _decorate(List<Suggestion> base, String composing) {
    if (decorators.isEmpty) return base;
    final q = SuggestionQuery(composing: composing, previousWords: List.unmodifiable(_previous), field: field.value);
    var out = base;
    for (final d in decorators) {
      try {
        out = d(out, q);
      } on Object catch (e) {
        BooBoardLog.w('Input', 'suggestion decorator failed', e.runtimeType);
      }
    }
    return out;
  }

  /// Emoji and multi-word phrases (personal shortcuts) are inserted but never learned as words.
  bool _learnable(Suggestion s) => s.kind != SuggestionKind.emoji && !s.text.contains(' ');

  /// A tap on a suggestion in the strip.
  void onSuggestionPicked(Suggestion s) {
    if (_sensitive || _raw) return;
    _begin();
    try {
      final swipe = _lastSwipe;
      if (swipe != null && _composing.isEmpty) {
        _replaceSwipe(swipe, s);
        return;
      }
      _lastCorrection = null;
      _lastSwipe = null;
      if (_composing.isNotEmpty && s.kind == SuggestionKind.emoji) {
        // "pizza" + 🍕 -> "pizza 🍕 ": the typed word stays and the emoji follows it.
        _commitComposingAsTyped();
        _send(_input.commitText(' ${s.text} '));
        _mirrorAppend(' ${s.text} ');
      } else if (_composing.isNotEmpty) {
        final word = s.text;
        _composing = '';
        _taps.clear();
        _lastResult = SuggestionResult.empty;
        _send(_input.commitText('$word '));
        _mirrorAppend('$word ');
        if (_learnable(s)) {
          _learn(word);
        } else {
          _pushPrevious(word);
        }
      } else {
        final prev = _prevChar;
        final lead = prev != null && prev != ' ' && prev != '\n' && _rules.isWordChar(prev) ? ' ' : '';
        _send(_input.commitText('$lead${s.text} '));
        _mirrorAppend('$lead${s.text} ');
        if (_learnable(s)) _learn(s.text);
      }
      _space = _SpaceState.autoAfterPick;
      _consumeShift();
      _updateSuggestions();
      unawaited(_refreshCaps());
    } finally {
      _end();
    }
  }

  void _replaceSwipe(_SwipeRecord swipe, Suggestion pick) {
    var text = pick.text;
    if (text == swipe.word) return;
    final first = swipe.word.characters.isEmpty ? '' : swipe.word.characters.first;
    if (first.isNotEmpty && first != first.toLowerCase() && text.isNotEmpty) {
      final chars = text.characters;
      text = '${chars.first.toUpperCase()}${chars.skip(1)}';
    }
    _batch(() {
      _send(_input.deleteSurroundingText(swipe.bodyLength, 0));
      _send(_input.commitText('$text '));
    });
    _mirrorDeleteUnits(swipe.bodyLength);
    _mirrorAppend('$text ');
    if (_previous.isNotEmpty) _previous = _previous.sublist(0, _previous.length - 1);
    _learn(text);
    _lastSwipe = _SwipeRecord(leading: swipe.leading, word: text, candidates: swipe.candidates);
    _setBar(SuggestionBarState(suggestions: _lastSwipe!.candidates, fromSwipe: true));
  }

  // ---- Gesture typing ---------------------------------------------------

  /// Decodes and commits a swiped path. Safe to call without checking the
  /// field: password and raw fields ignore it.
  Future<void> commitSwipe(GesturePath path) async {
    if (!field.value.allowsSwipe || _raw || !settings.swipe.enabled || redirect.value != null || composerActive) {
      return;
    }
    var candidates = await _decoder.decode(path, previousWords: List.of(_previous));
    final t = swipeTransform.value;
    if (t != null) {
      try {
        candidates = t(candidates);
      } on Object catch (e) {
        BooBoardLog.w('Input', 'swipe transform failed', e.runtimeType);
      }
    }
    if (candidates.isEmpty) return;
    _begin();
    try {
      _lastCorrection = null;
      if (_composing.isNotEmpty) _commitComposingAsTyped();
      var word = candidates.first.text;
      switch (shift.value) {
        case ShiftState.once:
          final chars = word.characters;
          if (chars.isNotEmpty) word = '${chars.first.toUpperCase()}${chars.skip(1)}';
        case ShiftState.caps:
          word = word.toUpperCase();
        case ShiftState.off:
          break;
      }
      final prev = _prevChar;
      final needsLead = prev != null && (_isLetter(prev) || _isDigit(prev) || _rules.addsSpaceAfter(prev));
      final lead = needsLead ? ' ' : '';
      _send(_input.commitText('$lead$word '));
      _mirrorAppend('$lead$word ');
      _learn(word);
      _space = _SpaceState.autoAfterPick;
      _lastSwipe = _SwipeRecord(leading: lead, word: word, candidates: candidates);
      _consumeShift();
      _setBar(SuggestionBarState(suggestions: candidates, fromSwipe: true));
      unawaited(_refreshCaps());
    } finally {
      _end();
    }
  }

  // ---- Composer (Wave 4) --------------------------------------------------

  /// A `KeyType.custom` key. Only composers use them today; otherwise nothing happens.
  void onCustomKey(String code) {
    if (code.isEmpty || redirect.value != null) return;
    _begin();
    try {
      _toComposer((c) => c.onCustomKey(code));
    } finally {
      _end();
    }
  }

  /// A tap on `composerState.value.candidates[index]` (the candidate strip or grid).
  void selectCandidate(int index) {
    if (index < 0 || index >= composerState.value.candidates.length) return;
    _begin();
    try {
      _toComposer((c) => c.selectCandidate(index));
    } finally {
      _end();
    }
  }

  /// Runs one composer call. Returns false when there is no active composer or it did not take the
  /// key, so the caller handles it as usual.
  bool _toComposer(ComposerStep Function(TextComposer c) call) {
    if (!composerActive) return false;
    final c = composer.value!;
    if (_composing.isNotEmpty) _commitComposingAsTyped();
    ComposerStep step;
    try {
      step = call(c);
    } on Object catch (e) {
      BooBoardLog.w('Input', 'composer failed', e.runtimeType);
      _dropComposer();
      return false;
    }
    if (!step.handled) return false;
    _applyComposer(step.commit, c.state);
    return true;
  }

  void _applyComposer(String commit, ComposerState next) {
    _batch(() {
      if (commit.isNotEmpty) {
        // commitText replaces the composing region (the old preedit).
        _send(_input.commitText(commit));
        _mirrorAppend(commit);
      }
      if (next.preedit.isNotEmpty) {
        _send(_input.setComposingText(next.preedit));
      } else if (commit.isEmpty && _shownPreedit.isNotEmpty) {
        _send(_input.commitText(''));
      }
    });
    _shownPreedit = next.preedit;
    _space = _SpaceState.none;
    _lastCorrection = null;
    _lastSwipe = null;
    composerState.value = next;
    _setBar(SuggestionBarState(isComposing: next.isComposing));
  }

  /// Ends the composer's buffer: the preedit stays in the field as typed (unless [finish] is false,
  /// for a new field), and the strip clears.
  void _dropComposer({bool finish = true}) {
    final c = _attachedComposer;
    if (_shownPreedit.isNotEmpty) {
      if (finish) {
        _send(_input.finishComposingText());
        _mirrorAppend(_shownPreedit);
      }
      _shownPreedit = '';
    }
    if (c != null) {
      try {
        c.reset();
      } on Object catch (e) {
        BooBoardLog.w('Input', 'composer reset failed', e.runtimeType);
      }
    }
    if (!composerState.value.isEmpty) composerState.value = ComposerState.empty;
  }

  void _onComposerSet() {
    final old = _attachedComposer;
    if (identical(old, composer.value)) return;
    _begin();
    try {
      _dropComposer();
      old?.changes?.removeListener(_onComposerChanges);
      _attachedComposer = composer.value;
      _attachedComposer?.changes?.addListener(_onComposerChanges);
      _updateSuggestions();
    } finally {
      _end();
    }
  }

  /// The composer's state changed on its own (a dictionary finished loading).
  void _onComposerChanges() {
    final c = _attachedComposer;
    if (c == null || !composerActive) return;
    _begin();
    try {
      _applyComposer('', c.state);
    } finally {
      _end();
    }
  }

  void dispose() {
    _attachedComposer?.changes?.removeListener(_onComposerChanges);
    composer.removeListener(_onComposerSet);
    composer.dispose();
    composerState.dispose();
    field.dispose();
    shift.dispose();
    page.dispose();
    bar.dispose();
    redirect.dispose();
    transform.dispose();
    swipeTransform.dispose();
  }
}
