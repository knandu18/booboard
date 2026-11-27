// SPDX-License-Identifier: GPL-3.0-or-later
//
// CONTRACT (Wave 0). Interfaces between the keyboard UI/controller and the
// language engines. Agents implement these; only the orchestrator changes them.
//
// Coordinates: keyboard-local logical pixels (dp), origin top-left of the key
// area. Times: milliseconds (monotonic).
import 'dart:ui' show Offset, Rect, Size;

import 'package:meta/meta.dart';

import '../core/input_field_info.dart';

/// BCP-47-ish id: 'en', 'es', 'fr', 'de', 'pt-BR', 'pt-PT', 'id', 'hi', 'mr',
/// 'bn', 'ta', 'te', 'ar', 'ur', 'ru', 'uk', 'zh-Hans', 'ja'.
typedef LanguageId = String;

@immutable
class TouchPoint {
  const TouchPoint(this.x, this.y, this.t);

  final double x;
  final double y;
  final int t;

  Offset get offset => Offset(x, y);
}

/// One typed character and where the finger landed (null when not from a
/// touch, e.g. picked from a popup).
@immutable
class KeyTap {
  const KeyTap(this.char, [this.point]);

  final String char;
  final TouchPoint? point;
}

/// Where the character keys are, for spatial autocorrect and gesture typing.
@immutable
class KeyboardGeometry {
  const KeyboardGeometry({required this.layoutId, required this.size, required this.keys});

  final String layoutId;
  final Size size;

  /// Lower-case key output -> key rect (gaps excluded).
  final Map<String, Rect> keys;

  /// Typical character-key width; used to scale distances.
  double get keyWidth {
    if (keys.isEmpty) return 1;
    final widths = keys.values.map((r) => r.width).toList()..sort();
    return widths[widths.length ~/ 2];
  }

  Offset? centerOf(String char) => keys[char]?.center;

  /// Identity for caching (layout + rounded size).
  String get cacheKey => '$layoutId@${size.width.round()}x${size.height.round()}';
}

enum SuggestionKind {
  /// The literal typed word.
  typed,
  correction,
  completion,

  /// Next-word prediction (no composing word).
  prediction,
  emoji,
  gesture,
  transliteration,
  conversion,
}

@immutable
class Suggestion {
  const Suggestion(
    this.text, {
    required this.kind,
    this.score = 0,
    this.display,
    this.language,
    this.isLearned = false,
  });

  /// Text to commit.
  final String text;

  /// Higher is better; comparable only within one result.
  final double score;
  final SuggestionKind kind;

  /// Text to show if different from [text] (e.g. "namaste" for नमस्ते).
  final String? display;
  final LanguageId? language;
  final bool isLearned;

  @override
  String toString() => 'Suggestion(${kind.name}, score: ${score.toStringAsFixed(2)})';
}

@immutable
class SuggestionResult {
  const SuggestionResult({this.suggestions = const [], this.autoCorrection});

  static const SuggestionResult empty = SuggestionResult();

  /// Best first. The UI shows up to 3 (more when expanded).
  final List<Suggestion> suggestions;

  /// Set only when the engine is confident the typed word should be replaced
  /// when the user types a separator (space/punctuation).
  final Suggestion? autoCorrection;
}

@immutable
class TypingContext {
  const TypingContext({
    required this.composing,
    this.taps = const [],
    this.previousWords = const [],
    this.isStartOfSentence = false,
    this.field = InputFieldInfo.plainText,
  });

  /// Current word as typed, with case.
  final String composing;

  /// Per-character taps, aligned with [composing] when known.
  final List<KeyTap> taps;

  /// Up to 3 words before the cursor, oldest first.
  final List<String> previousWords;
  final bool isStartOfSentence;
  final InputFieldInfo field;
}

// ---------------------------------------------------------------------------
// Lexicon: word list with frequencies (implemented by the dictionary engine).
// ---------------------------------------------------------------------------

@immutable
class LexiconEntry {
  const LexiconEntry(this.word, this.logProb, {this.isOffensive = false});

  final String word;

  /// Natural-log unigram probability (<= 0).
  final double logProb;
  final bool isOffensive;
}

abstract interface class Lexicon {
  LanguageId get language;
  int get size;

  /// Words, most frequent first.
  Iterable<LexiconEntry> entries({int? limit});

  /// null when unknown. Case-sensitive lookup falls back to lower case.
  double? logProb(String word);

  /// log P(word | previous) with backoff to the unigram.
  double bigramLogProb(String previous, String word);
}

abstract interface class LexiconSource {
  /// Loads (and caches) a language's lexicon. Throws if the language has no data.
  Future<Lexicon> load(LanguageId language);
  bool isLoaded(LanguageId language);
  void evict(LanguageId language);
}

// ---------------------------------------------------------------------------
// Tap typing: autocorrect, completion, next-word prediction, learning.
// ---------------------------------------------------------------------------

abstract interface class TextPredictor {
  /// Activate languages (lazy load; cheap to call repeatedly). Max 3 blended.
  Future<void> setActiveLanguages(List<LanguageId> languages);

  /// Key positions for the spatial model.
  void setGeometry(KeyboardGeometry geometry);

  /// Suggestions for the composing word. Synchronous; target < 8 ms.
  SuggestionResult suggest(TypingContext context);

  /// Next-word predictions when nothing is being composed.
  List<Suggestion> predictNext(List<String> previousWords, {int max = 3});

  bool isKnownWord(String word);

  /// Called when a word is committed. Learns only when [allowLearning].
  void onWordCommitted(String word, {required List<String> previousWords, required bool allowLearning});

  /// User pressed backspace right after an auto-correction.
  void onAutoCorrectionReverted({required String original, required String correction});

  /// "Never suggest" / "Remove from learned words".
  void blockWord(String word);
  void forgetWord(String word);

  /// Learned words (for the gesture decoder and the settings editor).
  Iterable<LexiconEntry> learnedWords(LanguageId language);

  /// Persist learned data (encrypted). Called on window hidden.
  Future<void> flush();
  Future<void> clearLearnedData();

  /// The settings app changed the stored learned data (editor, wipe, backup restore): discard
  /// unsaved in-memory changes and read it again. Triggered by [DataSections.learned].
  Future<void> reloadLearnedData();

  /// Drop caches on memory pressure.
  void trimMemory();
}

// ---------------------------------------------------------------------------
// Gesture (swipe) typing.
// ---------------------------------------------------------------------------

@immutable
class GesturePath {
  const GesturePath(this.points);

  final List<TouchPoint> points;
}

abstract interface class GestureDecoder {
  /// Build/refresh word templates for this geometry and languages (in a
  /// background isolate). Safe to call repeatedly; cached by geometry key.
  Future<void> prepare({
    required KeyboardGeometry geometry,
    required List<LanguageId> languages,
    Iterable<LexiconEntry> extraWords = const [],
  });

  /// Best candidates first. Target < 40 ms p95.
  Future<List<Suggestion>> decode(GesturePath path, {List<String> previousWords = const [], int maxResults = 6});

  /// Cheap live preview while the finger is still moving; may return null.
  Future<String?> preview(GesturePath partialPath);

  void trimMemory();
  void dispose();
}

// ---------------------------------------------------------------------------
// Language rules: punctuation spacing, capitalization, word characters.
// ---------------------------------------------------------------------------

abstract interface class LanguageRules {
  LanguageId get language;

  /// Script has upper/lower case (false for Devanagari, Arabic, CJK...).
  bool get hasCase;

  /// Part of a word (letters, marks, apostrophe inside words, ...).
  bool isWordChar(String char);

  /// Punctuation that swallows a preceding auto-space (". , ! ? : ;" in English).
  bool removesSpaceBefore(String punctuation);

  /// Punctuation that takes a (thin) space before it (French "; : ! ?").
  String? spaceBefore(String punctuation);

  /// Punctuation after which a space is inserted automatically.
  bool addsSpaceAfter(String punctuation);

  /// Sentence-ending punctuation (for auto-capitalization).
  bool endsSentence(String punctuation);

  /// Opening/closing quotes for this language, e.g. ('“', '”') or ('« ', ' »').
  (String open, String close) get quotes;
}

// ---------------------------------------------------------------------------
// Later waves (declared now so the controller can plan for them).
// ---------------------------------------------------------------------------

/// Indic: type in Latin letters, get native script (Wave 3).
abstract interface class Transliterator {
  LanguageId get language;
  Future<void> load();
  List<Suggestion> transliterate(String latin, {List<String> previousWords = const [], int max = 5});
}

// Chinese pinyin and Japanese kana-kanji conversion (Wave 4): see TextComposer in
// lib/src/keyboard/input/composer.dart.
