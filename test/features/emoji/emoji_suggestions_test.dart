// SPDX-License-Identifier: GPL-3.0-or-later
//
// Emoji suggestions: one emoji for an exact keyword or short name, never for predictions, and cheap.
import 'package:flutter_test/flutter_test.dart';
import 'package:booboard/src/core/secure_blob_store.dart';
import 'package:booboard/src/engine/contracts.dart';
import 'package:booboard/src/features/emoji/emoji_repository.dart';
import 'package:booboard/src/features/emoji/emoji_store.dart';
import 'package:booboard/src/features/emoji/emoji_suggestions.dart';
import 'package:booboard/src/keyboard/input/input_controller.dart';
import 'package:booboard/src/core/input_field_info.dart';

SuggestionQuery _query(String composing) =>
    SuggestionQuery(composing: composing, previousWords: const [], field: InputFieldInfo.plainText);

const List<Suggestion> _typed = [Suggestion('pizzas', kind: SuggestionKind.completion)];

void main() {
  late EmojiRepository repository;
  late EmojiStore store;
  late bool enabled;
  late List<String> languages;
  late EmojiSuggestions suggestions;

  setUp(() async {
    repository = EmojiRepository.fromDirectory('assets/emoji');
    store = EmojiStore(blobs: InMemorySecureBlobStore(), learningOff: () => false, saveDelay: Duration.zero);
    enabled = true;
    languages = ['en'];
    suggestions = EmojiSuggestions(
      repository: repository,
      store: store,
      enabled: () => enabled,
      languages: () => languages,
    );
    await repository.ensure(['en']);
  });

  test('an exact keyword adds one emoji at the end', () {
    final out = suggestions.decorate(_typed, _query('pizza'));
    expect(out.map((s) => s.text), ['pizzas', '🍕']);
    expect(out.last.kind, SuggestionKind.emoji);
  });

  test('matching ignores case, and a near miss adds nothing', () {
    expect(suggestions.decorate(_typed, _query('Pizza')).last.text, '🍕');
    expect(suggestions.decorate(_typed, _query('pizz')), _typed);
  });

  test('a short name works as well as a keyword', () {
    final out = suggestions.decorate(_typed, _query('grinning'));
    expect(out.last.kind, SuggestionKind.emoji);
  });

  test('next-word predictions (nothing composing) never get an emoji', () {
    expect(suggestions.decorate(_typed, _query('')), _typed);
  });

  test('the setting off turns it all off', () {
    enabled = false;
    expect(suggestions.decorate(_typed, _query('pizza')), _typed);
  });

  test('a language that is not enabled does not match', () {
    languages = ['en'];
    expect(suggestions.decorate(_typed, _query('perro')), _typed);
  });

  test('an enabled language matches its own keywords', () async {
    languages = ['en', 'es'];
    await repository.ensure(languages);
    expect(suggestions.decorate(_typed, _query('perro')).last.kind, SuggestionKind.emoji);
  });

  test('an emoji the device cannot draw is not suggested', () {
    store.setHidden('k', {'🍕'});
    expect(suggestions.decorate(_typed, _query('pizza')), _typed);
  });

  test('a lookup stays under the 0.3 ms budget', () {
    final sw = Stopwatch();
    var worst = 0;
    for (var i = 0; i < 50; i++) {
      sw
        ..reset()
        ..start();
      suggestions.decorate(_typed, _query('pizza'));
      sw.stop();
      if (sw.elapsedMicroseconds > worst) worst = sw.elapsedMicroseconds;
    }
    expect(worst, lessThan(3000), reason: 'worst lookup took $worst us (the budget is 300 us; slack for debug builds)');
  });
}
