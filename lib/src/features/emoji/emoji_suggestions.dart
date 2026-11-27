// SPDX-License-Identifier: GPL-3.0-or-later
//
// OWNER: Wave 2-D. Emoji suggestions in the suggestion strip. When the word being typed is exactly a
// keyword or short name ("pizza", "love", "प्यार"), one emoji is added at the end of the strip.
// Next-word predictions never get an emoji. The lookup is a precomputed map: well under 0.3 ms.
import '../../engine/contracts.dart';
import '../../keyboard/input/input_controller.dart';
import 'emoji_data.dart';
import 'emoji_repository.dart';
import 'emoji_store.dart';

class EmojiSuggestions {
  EmojiSuggestions({required this.repository, required this.store, required this.enabled, required this.languages});

  final EmojiRepository repository;
  final EmojiStore store;

  /// `TypingSettings.emojiSuggestions`.
  final bool Function() enabled;

  /// The languages to match in: the enabled ones, with English always.
  final List<String> Function() languages;

  /// The decorator the keyboard runs on every suggestion update.
  SuggestionDecorator get decorator => decorate;

  List<Suggestion> decorate(List<Suggestion> base, SuggestionQuery query) {
    final composing = query.composing;
    if (composing.isEmpty || !enabled()) return base;
    final wanted = languages();
    final index = repository.current;
    if (index == null || !_sameLanguages(index.languages, wanted)) {
      repository.warm(wanted);
      return base;
    }
    final ref = index.exactRef(composing.toLowerCase());
    if (ref < 0) return base;
    final text = index.data.textOf(displayRef(index.data, store, ref ~/ refStride));
    if (store.isHidden(text)) return base;
    return [...base, Suggestion(text, kind: SuggestionKind.emoji)];
  }

  static bool _sameLanguages(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
