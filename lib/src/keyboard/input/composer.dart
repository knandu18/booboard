// SPDX-License-Identifier: GPL-3.0-or-later
//
// CONTRACT (orchestrator-owned, Wave 4): input methods that keep their own buffer and turn it into
// text through candidates: Chinese pinyin (Wave 4-A) and Japanese kana/kanji conversion (Wave 4-B).
//
// While a language feature sets `InputController.composer` and the field allows it (a text field,
// not a password, the letters page, not forceAscii), every key goes to the composer first:
// characters (letters, kana, punctuation and popup alternatives), space, enter, backspace, custom
// keys (`KeyType.custom` with a `code`) and candidate taps. The controller then:
//   1. commits `ComposerStep.commit` (replacing the composing region),
//   2. shows `ComposerState.preedit` as the composing text (underlined in the editor),
//   3. publishes the state on `InputController.composerState` for the candidate strip and grid.
// A step with `handled: false` lets the controller do its normal work for that key (for example
// backspace with an empty buffer deletes the character before the cursor, and space with nothing
// composing types a space). Swipe typing, autocorrect and the predictor are off while a composer is
// set; `SuggestionDecorator`s are not applied to candidates.
//
// When the cursor moves elsewhere, the field changes or the keyboard hides, the controller calls
// `reset()` and finishes the composing text (the preedit stays in the field as typed).
//
// PRIVACY: composers never log the buffer, the preedit or the candidates. Learned phrases are
// stored only through SecureBlobStore, and only when `InputController.learningAllowed`.
// Budget (the plan's "CJK conversion update"): a call returns within 30 ms p95 on a mid-range phone,
// and a plain letter key well under that. Dictionary loading belongs in an isolate, with
// `ComposerState.loading` shown meanwhile.
import 'package:flutter/foundation.dart';

/// Codes the controller and layouts send to [TextComposer.onCustomKey]. Layouts may define more
/// (`{"type": "custom", "code": "..."}`); these are the shared ones.
abstract final class ComposerKeys {
  /// The cursor keys and space-bar cursor drag while the composer holds text (Japanese: move
  /// between segments). Not handled = the preedit is kept as typed and the cursor moves.
  static const String cursorLeft = 'cursor_left';
  static const String cursorRight = 'cursor_right';

  /// Japanese segment resize (shorter, longer), for layouts that offer it.
  static const String segmentShorter = 'segment_shorter';
  static const String segmentLonger = 'segment_longer';

  /// 12-key: toggle dakuten/handakuten/small form of the last kana (か→が, は→ば→ぱ, つ→っ).
  static const String kanaModifier = 'kana_modifier';

  /// 12-key: undo the last multi-tap step (あ←い).
  static const String undoCycle = 'undo_cycle';
}

/// One conversion candidate.
@immutable
class ComposerCandidate {
  const ComposerCandidate(this.text, {this.annotation, this.consumes});

  /// What is committed when picked (你好, 日本語, a full-width mark, an emoji...).
  final String text;

  /// Small text shown with it in the grid (a reading, "Traditional", a source); may be null.
  final String? annotation;

  /// How much of the buffer this candidate converts, in the composer's own units (Chinese picks
  /// that convert only the first syllables leave the rest composing). Informational for the view.
  final int? consumes;

  @override
  bool operator ==(Object other) =>
      other is ComposerCandidate && other.text == text && other.annotation == annotation && other.consumes == consumes;

  @override
  int get hashCode => Object.hash(text, annotation, consumes);
}

/// What the strip, the grid and the editor show.
@immutable
class ComposerState {
  const ComposerState({
    this.preedit = '',
    this.reading = '',
    this.candidates = const [],
    this.highlighted = -1,
    this.loading = false,
  });

  static const ComposerState empty = ComposerState();

  /// The composing text in the editor (pinyin "ni hao", kana "にほんご", or the selected
  /// conversion "日本語" while converting). Empty when nothing is composing.
  final String preedit;

  /// Shown at the start of the candidate strip when it differs from [preedit] (for example the
  /// segmented pinyin "ni'hao" or the kana reading during conversion). May be empty.
  final String reading;

  /// Best first. May be non-empty with an empty [preedit]: predictions after a commit (联想),
  /// which a tap commits.
  final List<ComposerCandidate> candidates;

  /// The candidate space or enter would commit, highlighted in the strip; -1 for none.
  final int highlighted;

  /// The composer is still loading its dictionary (the strip shows a small progress mark).
  final bool loading;

  bool get isComposing => preedit.isNotEmpty;
  bool get isEmpty => preedit.isEmpty && candidates.isEmpty;

  @override
  bool operator ==(Object other) =>
      other is ComposerState &&
      other.preedit == preedit &&
      other.reading == reading &&
      other.highlighted == highlighted &&
      other.loading == loading &&
      listEquals(other.candidates, candidates);

  @override
  int get hashCode => Object.hash(preedit, reading, highlighted, loading, Object.hashAll(candidates));
}

/// The result of one key: text to commit now, and whether the composer took the key.
@immutable
class ComposerStep {
  const ComposerStep({this.commit = '', this.handled = true});

  /// The composer ignored the key: the controller handles it as if no composer were set.
  static const ComposerStep notHandled = ComposerStep(handled: false);

  /// The key changed only the composer's state.
  static const ComposerStep consumed = ComposerStep();

  /// Text committed to the editor before the new preedit (may be empty).
  final String commit;
  final bool handled;
}

/// A Chinese or Japanese input method. Synchronous: the controller reads [state] after every call.
abstract class TextComposer {
  /// The current state. Must not change except during a call below, or before [changes] fires.
  ComposerState get state;

  /// Fires when [state] changes outside a key call (an async dictionary load finished). The
  /// controller then republishes the state and the preedit. Default: never.
  Listenable? get changes => null;

  /// A character key (already cased by the view), a popup alternative or a flick output.
  ComposerStep onText(String text);
  ComposerStep onSpace();
  ComposerStep onEnter();
  ComposerStep onBackspace();

  /// A `KeyType.custom` key with this `code` (12-key: dakuten toggle, small kana, undo flick).
  ComposerStep onCustomKey(String code) => ComposerStep.notHandled;

  /// The user tapped `state.candidates[index]`.
  ComposerStep selectCandidate(int index);

  /// Forget the buffer (the cursor moved away, the field or the language changed). The controller
  /// finishes the composing text itself.
  void reset();
}
