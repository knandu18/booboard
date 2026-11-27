// SPDX-License-Identifier: GPL-3.0-or-later
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:booboard/src/core/input_field_info.dart';
import 'package:booboard/src/core/secure_blob_store.dart';
import 'package:booboard/src/engine/contracts.dart';
import 'package:booboard/src/engine/dictionary/lexicon_factory.dart';
import 'package:booboard/src/engine/in_memory_lexicon.dart';
import 'package:booboard/src/engine/suggest/text_predictor.dart';

import 'support.dart';

const InputFieldInfo _urlField = InputFieldInfo(
  inputType: AndroidInputType.classText | AndroidInputType.textVariationUri,
  imeOptions: 0,
);
const InputFieldInfo _passwordField = InputFieldInfo(
  inputType: AndroidInputType.classText | AndroidInputType.textVariationPassword,
  imeOptions: 0,
);

void main() {
  late LexiconSource lexicons;
  late BooBoardTextPredictor predictor;
  final geometry = qwertyGeometry();

  Future<BooBoardTextPredictor> makePredictor({
    SecureBlobStore? store,
    DateTime Function()? clock,
    Duration? saveDelay,
  }) async {
    final p = BooBoardTextPredictor(
      lexicons: lexicons,
      store: store ?? InMemorySecureBlobStore(),
      clock: clock,
      saveDelay: saveDelay ?? const Duration(hours: 1),
    );
    await p.setActiveLanguages(['en']);
    p.setGeometry(geometry);
    return p;
  }

  SuggestionResult suggestWord(String word, {List<String> previous = const [], bool taps = true, bool start = false}) {
    return predictor.suggest(
      typing(word, taps: taps ? centreTaps(geometry, word) : const [], previous: previous, startOfSentence: start),
    );
  }

  setUpAll(() {
    lexicons = createLexiconSource(packs: FilePackRepository());
  });

  setUp(() async {
    predictor = await makePredictor();
  });

  group('corrections', () {
    for (final (typo, fix) in [
      ('teh', 'the'),
      ('helo', 'hello'),
      ('thnaks', 'thanks'),
      ('recieve', 'receive'),
      ('adress', 'address'),
      ('wierd', 'weird'),
      ('seperate', 'separate'),
    ]) {
      test('$typo -> $fix', () {
        final result = suggestWord(typo);
        expect(result.autoCorrection?.text, fix);
        expect(result.suggestions.map((s) => s.text), contains(fix));
      });
    }

    test('the typed word stays available and is marked as typed', () {
      final result = suggestWord('teh');
      final typed = result.suggestions.where((s) => s.kind == SuggestionKind.typed).single;
      expect(typed.text, 'teh');
    });

    test('known words are not corrected', () {
      for (final word in ['form', 'hello', 'the', 'thanks', 'receive', 'gonna']) {
        expect(suggestWord(word).autoCorrection, isNull, reason: word);
      }
    });

    test('unknown words that are not near a common word are left alone', () {
      for (final word in ['kaun', 'lol', 'thx', 'omw']) {
        expect(suggestWord(word).autoCorrection, isNull, reason: word);
      }
    });

    test('a user-reverted correction is not applied again this session', () {
      expect(suggestWord('teh').autoCorrection?.text, 'the');
      predictor.onAutoCorrectionReverted(original: 'teh', correction: 'the');
      expect(suggestWord('teh').autoCorrection, isNull);
    });
  });

  group('spatial model', () {
    test('a tap between g and h, nearer h, turns "gello" into hello', () {
      final g = geometry.keys['g']!;
      final taps = centreTaps(geometry, 'gello', nudge: {0: Offset(g.width * 0.62, 0)});
      final result = predictor.suggest(typing('gello', taps: taps));
      expect(result.autoCorrection?.text, 'hello');
    });

    test('hello ranks higher when the tap supports it than when the finger hit the g centre', () {
      final g = geometry.keys['g']!;
      final near = predictor.suggest(
        typing('gello', taps: centreTaps(geometry, 'gello', nudge: {0: Offset(g.width * 0.62, 0)})),
      );
      final centre = predictor.suggest(typing('gello', taps: centreTaps(geometry, 'gello')));
      double scoreOf(SuggestionResult r) => r.suggestions.firstWhere((s) => s.text == 'hello').score;
      expect(scoreOf(near), greaterThan(scoreOf(centre)));
      expect(centre.suggestions.map((s) => s.text), contains('hello'));
    });

    test('works without touch points, using key positions only', () {
      final result = suggestWord('gello', taps: false);
      expect(result.suggestions.map((s) => s.text), contains('hello'));
    });

    test('mismatched tap count falls back to key positions', () {
      final result = predictor.suggest(typing('helo', taps: centreTaps(geometry, 'he')));
      expect(result.autoCorrection?.text, 'hello');
    });
  });

  group('completions and prediction', () {
    test('completes prefixes', () {
      final hel = suggestWord('hel').suggestions.map((s) => s.text).toList();
      expect(hel, containsAll(['help', 'hello']));
      expect(suggestWord('th').suggestions.map((s) => s.text), containsAll(['the', 'this', 'that']));
      final thank = suggestWord('thank');
      expect(thank.suggestions.map((s) => s.text), contains('thanks'));
      expect(thank.autoCorrection, isNull);
    });

    test('prefix suggestions are completions', () {
      final result = suggestWord('hel');
      expect(result.suggestions.firstWhere((s) => s.text == 'help').kind, SuggestionKind.completion);
    });

    test('bigram context ranks "you" first after "thank"', () {
      final result = suggestWord('y', previous: ['thank']);
      final others = result.suggestions.where((s) => s.kind != SuggestionKind.typed).toList();
      expect(others.first.text, 'you');
    });

    test('next word after "thank" is "you"', () {
      final next = predictor.predictNext(['thank']);
      expect(next.first.text, 'you');
      expect(next.every((s) => s.kind == SuggestionKind.prediction), isTrue);
      expect(next.length, lessThanOrEqualTo(3));
    });

    test('predictNext with no context offers sentence starters', () {
      expect(predictor.predictNext(const []).map((s) => s.text), contains('I'));
    });

    test('suggests at most 8 entries', () {
      expect(suggestWord('a').suggestions.length, lessThanOrEqualTo(8));
    });
  });

  group('case and contractions', () {
    test('keeps Hello / HELLO patterns', () {
      expect(suggestWord('Teh', start: true).autoCorrection?.text, 'The');
      expect(suggestWord('TEH').autoCorrection?.text, 'THE');
      expect(suggestWord('Hel').suggestions.map((s) => s.text), contains('Help'));
      expect(suggestWord('HEL').suggestions.map((s) => s.text), contains('HELP'));
    });

    test('capitalised unknown words in mid-sentence are treated as names', () {
      expect(suggestWord('Teh').autoCorrection, isNull);
    });

    test('contractions', () {
      expect(suggestWord('dont').autoCorrection?.text, "don't");
      expect(suggestWord('Dont').autoCorrection?.text, "Don't");
      expect(suggestWord('DONT').autoCorrection?.text, "DON'T");
      expect(suggestWord('im').autoCorrection?.text, "I'm");
      expect(suggestWord('youre').autoCorrection?.text, "you're");
      expect(suggestWord('cant').autoCorrection?.text, "can't");
      expect(suggestWord('i').autoCorrection?.text, 'I');
      expect(suggestWord('thats').autoCorrection?.text, "that's");
    });

    test('already-correct forms are left alone', () {
      expect(suggestWord("don't").autoCorrection, isNull);
      expect(suggestWord("I'm").autoCorrection, isNull);
      expect(suggestWord('I').autoCorrection, isNull);
    });
  });

  group('tokens that are never touched', () {
    test('URLs, emails, handles, tags, digits, camelCase, file names', () {
      for (final token in [
        'https://exa',
        'www.exampel',
        'john@exa',
        '@jonh',
        '#teh',
        'h3llo',
        'myVar',
        'file.txt',
        'a/b',
      ]) {
        final result = suggestWord(token);
        expect(result.autoCorrection, isNull, reason: token);
        expect(result.suggestions.map((s) => s.text), [token], reason: token);
      }
    });

    test('single letters are never autocorrected', () {
      for (final letter in ['a', 'b', 'x']) {
        expect(suggestWord(letter).autoCorrection, isNull);
      }
    });

    test('URL and email fields never autocorrect', () {
      final result = predictor.suggest(typing('teh', taps: centreTaps(geometry, 'teh'), field: _urlField));
      expect(result.autoCorrection, isNull);
    });

    test('password fields give no suggestions at all', () {
      final result = predictor.suggest(typing('teh', field: _passwordField));
      expect(result.suggestions, isEmpty);
      expect(result.autoCorrection, isNull);
    });
  });

  group('offensive words', () {
    test('are never suggested unless typed in full', () {
      final partial = suggestWord('sexu').suggestions.map((s) => s.text);
      expect(partial, isNot(contains('sexual')));
      final full = suggestWord('sexual');
      expect(full.suggestions.first.text, 'sexual'); // the typed word itself stays
      expect(full.autoCorrection, isNull);
    });

    test('can be allowed', () {
      predictor.blockOffensive = false;
      expect(suggestWord('sexu').suggestions.map((s) => s.text), contains('sexual'));
    });
  });

  group('blocklist', () {
    test('a blocked word is never suggested or auto-corrected to', () {
      expect(suggestWord('helo').autoCorrection?.text, 'hello');
      predictor.blockWord('hello');
      final result = suggestWord('helo');
      expect(result.suggestions.map((s) => s.text), isNot(contains('hello')));
      expect(result.autoCorrection?.text, isNot('hello'));
      expect(suggestWord('hel').suggestions.map((s) => s.text), isNot(contains('hello')));
      expect(predictor.predictNext(['say']).map((s) => s.text), isNot(contains('hello')));
    });

    test('the block survives a restart and forgetWord lifts it', () async {
      final store = InMemorySecureBlobStore();
      final first = await makePredictor(store: store);
      first.blockWord('hello');
      await first.flush();
      final second = await makePredictor(store: store);
      expect(second.suggest(typing('hel')).suggestions.map((s) => s.text), isNot(contains('hello')));
      second.forgetWord('hello');
      expect(second.suggest(typing('hel')).suggestions.map((s) => s.text), contains('hello'));
    });
  });

  group('learning', () {
    void commit(BooBoardTextPredictor p, String word, {List<String> previous = const [], bool learn = true}) =>
        p.onWordCommitted(word, previousWords: previous, allowLearning: learn);

    test('a new word becomes known after two commits', () {
      commit(predictor, 'zorbo');
      expect(predictor.isKnownWord('zorbo'), isFalse);
      expect(predictor.suggest(typing('zor')).suggestions.map((s) => s.text), isNot(contains('zorbo')));
      commit(predictor, 'zorbo');
      expect(predictor.isKnownWord('zorbo'), isTrue);
      expect(predictor.suggest(typing('zor')).suggestions.map((s) => s.text), contains('zorbo'));
      expect(predictor.learnedWords('en').map((e) => e.word), ['zorbo']);
      // A learned word is not "corrected" away.
      expect(suggestWord('zorbo').autoCorrection, isNull);
    });

    test('nothing is learned when learning is not allowed', () async {
      final store = InMemorySecureBlobStore();
      final p = await makePredictor(store: store);
      for (var i = 0; i < 5; i++) {
        commit(p, 'zorbo', previous: ['my'], learn: false);
      }
      expect(p.isKnownWord('zorbo'), isFalse);
      expect(p.learnedWords('en'), isEmpty);
      await p.flush();
      expect(await store.read('learned_en'), isNull);
    });

    test('round-trips through the secure store', () async {
      final store = InMemorySecureBlobStore();
      final first = await makePredictor(store: store);
      commit(first, 'zorbo');
      commit(first, 'zorbo', previous: ['my']);
      commit(first, 'zorbo', previous: ['my']);
      await first.flush();
      expect(await store.read('learned_en'), isNotNull);

      final second = await makePredictor(store: store);
      expect(second.isKnownWord('zorbo'), isTrue);
      expect(second.learnedWords('en').single.word, 'zorbo');
      expect(second.predictNext(['my']).first.text, 'zorbo');
    });

    test('saves are debounced and flush() persists at once', () async {
      final store = InMemorySecureBlobStore();
      final p = await makePredictor(store: store, saveDelay: const Duration(milliseconds: 30));
      commit(p, 'zorbo');
      expect(await store.read('learned_en'), isNull);
      await Future<void>.delayed(const Duration(milliseconds: 120));
      expect(await store.read('learned_en'), isNotNull);
      final q = await makePredictor(store: InMemorySecureBlobStore());
      commit(q, 'zorbo');
      await q.flush();
    });

    test('personal bigrams beat the dictionary after repeated use', () {
      for (var i = 0; i < 4; i++) {
        commit(predictor, 'hello', previous: ['quick']);
      }
      expect(predictor.predictNext(['quick']).first.text, 'hello');
      expect(predictor.predictNext(['quick']).first.isLearned, isTrue);
    });

    test('credential-like strings are never learned', () async {
      final store = InMemorySecureBlobStore();
      final p = await makePredictor(store: store);
      for (final secret in [
        'hunter2',
        'xK7pQ9zR2m',
        'Tr0ub4dor',
        'correcthorsebatterystaple',
        'qzxwvbnmlkj',
        'AbCdEfGh',
        'ghp_abcdef',
        'a1b2c3',
        '123456',
        'p@ssw0rd',
        'aaaaaaa',
        'wjxkvqzpmtrb',
      ]) {
        commit(p, secret);
        commit(p, secret);
        expect(p.isKnownWord(secret), isFalse, reason: secret);
      }
      expect(p.learnedWords('en'), isEmpty);
    });

    test('forgetWord removes a learned word; clearLearnedData wipes everything', () async {
      final store = InMemorySecureBlobStore();
      final p = await makePredictor(store: store);
      commit(p, 'zorbo');
      commit(p, 'zorbo');
      commit(p, 'flimby');
      commit(p, 'flimby');
      await p.flush();
      p.forgetWord('zorbo');
      expect(p.isKnownWord('zorbo'), isFalse);
      expect(p.isKnownWord('flimby'), isTrue);
      await p.clearLearnedData();
      expect(p.isKnownWord('flimby'), isFalse);
      expect(p.learnedWords('en'), isEmpty);
      expect(await store.read('learned_en'), isNull);
    });

    test('learned counts decay with time', () {
      var now = DateTime.utc(2026, 1, 1);
      final decaying = BooBoardTextPredictor(
        lexicons: lexicons,
        store: InMemorySecureBlobStore(),
        clock: () => now,
        saveDelay: const Duration(hours: 1),
      );
      return decaying.setActiveLanguages(['en']).then((_) {
        decaying.onWordCommitted('hello', previousWords: ['quick'], allowLearning: true);
        decaying.onWordCommitted('hello', previousWords: ['quick'], allowLearning: true);
        final fresh = decaying.predictNext(['quick']).firstWhere((s) => s.text == 'hello').score;
        now = now.add(const Duration(days: 540));
        final old = decaying.predictNext(['quick']).firstWhere((s) => s.text == 'hello').score;
        expect(old, lessThan(fresh));
      });
    });

    test('corrupt stored data is ignored', () async {
      final store = InMemorySecureBlobStore();
      await store.write('learned_en', Uint8List.fromList([1, 2, 3]));
      final p = await makePredictor(store: store);
      expect(p.learnedWords('en'), isEmpty);
      commit(p, 'zorbo');
      commit(p, 'zorbo');
      expect(p.isKnownWord('zorbo'), isTrue);
    });
  });

  group('lifecycle', () {
    test('trimMemory is safe and suggestions still work afterwards', () {
      predictor.trimMemory();
      expect(suggestWord('teh').autoCorrection?.text, 'the');
      expect(predictor.predictNext(['thank']).first.text, 'you');
    });

    test('isKnownWord covers case and unknown words', () {
      expect(predictor.isKnownWord('Hello'), isTrue);
      expect(predictor.isKnownWord('xqzvbw'), isFalse);
    });

    test('works with a plain Lexicon that is not an MDICT file', () async {
      final p = BooBoardTextPredictor(
        lexicons: InMemoryLexiconSource({
          'en': InMemoryLexicon('en', ['the', 'thanks', 'you', 'hello', 'help'], bigrams: {('thank', 'you'): 5}),
        }),
        store: InMemorySecureBlobStore(),
      );
      await p.setActiveLanguages(['en']);
      expect(p.suggest(typing('teh')).autoCorrection?.text, 'the');
      expect(p.suggest(typing('dont')).autoCorrection?.text, "don't");
      expect(p.isKnownWord('help'), isTrue);
    });

    test('blends up to three languages', () async {
      final p = BooBoardTextPredictor(
        lexicons: InMemoryLexiconSource({
          'en': InMemoryLexicon('en', ['hello', 'world']),
          'es': InMemoryLexicon('es', ['hola', 'mundo']),
          'fr': InMemoryLexicon('fr', ['bonjour', 'monde']),
          'de': InMemoryLexicon('de', ['hallo', 'welt']),
        }),
        store: InMemorySecureBlobStore(),
      );
      await p.setActiveLanguages(['en', 'es', 'fr', 'de']);
      expect(p.isKnownWord('hola'), isTrue);
      expect(p.isKnownWord('bonjour'), isTrue);
      expect(p.isKnownWord('hallo'), isFalse); // the fourth language is ignored
      expect(p.suggest(typing('mund')).suggestions.map((s) => s.text), contains('mundo'));
    });
  });
}
