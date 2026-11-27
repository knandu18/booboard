// SPDX-License-Identifier: GPL-3.0-or-later
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:booboard/src/engine/dictionary/lexicon_factory.dart';
import 'package:booboard/src/engine/dictionary/mdict_lexicon.dart';
import 'package:booboard/src/engine/dictionary/mdict_writer.dart';
import 'package:booboard/src/engine/dictionary/text_fold.dart';
import 'package:booboard/src/packs/pack_repository.dart';

MdictLexicon _small() {
  final bytes = buildMdict(
    DictSource(
      language: 'en',
      words: const [
        DictWord('the', -2.9),
        DictWord('thank', -8.0),
        DictWord('thanks', -7.5),
        DictWord('you', -4.0),
        DictWord('I', -3.5),
        DictWord('café', -9.0),
        DictWord('God', -7.0),
        DictWord('damn', -9.5, offensive: true),
      ],
      bigrams: const [DictBigram('thank', 'you', -1.0), DictBigram('the', 'thank', -5.0)],
      corrections: const {'dont': "don't"},
    ),
  );
  return MdictLexicon.fromBytes(bytes);
}

void main() {
  group('text folding', () {
    test('folds case and accents, composes combining marks', () {
      expect(foldKey('Café'), 'cafe');
      expect(foldKey('Café', stripAccents: false), 'café');
      expect(normalizeNfc('é'), 'é');
      expect(foldKey('Straße'), 'strasse');
    });

    test('applies the typed case pattern', () {
      expect(applyCasePattern('Hel', 'hello'), 'Hello');
      expect(applyCasePattern('HEL', 'hello'), 'HELLO');
      expect(applyCasePattern('hel', 'hello'), 'hello');
      expect(applyCasePattern('hel', 'John'), 'John');
    });
  });

  group('builder and reader', () {
    test('round-trips words, probabilities, offensive flag and case', () {
      final lex = _small();
      expect(lex.size, 8);
      expect(lex.language, 'en');
      expect(lex.logProb('the'), closeTo(-2.9, 0.06));
      expect(lex.logProb('THE'), closeTo(-2.9, 0.06));
      expect(lex.logProb('cafe'), closeTo(-9.0, 0.06));
      expect(lex.logProb('café'), closeTo(-9.0, 0.06));
      expect(lex.logProb('god'), closeTo(-7.0, 0.06));
      expect(lex.logProb('zebra'), isNull);
      final entries = lex.entries().toList();
      expect(entries.first.word, 'the');
      expect(entries.map((e) => e.word), containsAll(['café', 'God', 'I']));
      expect(entries.firstWhere((e) => e.word == 'damn').isOffensive, isTrue);
      expect(entries.firstWhere((e) => e.word == 'the').isOffensive, isFalse);
      expect(lex.entries(limit: 3), hasLength(3));
      // Most frequent first.
      final probs = entries.map((e) => e.logProb).toList();
      final sortedProbs = [...probs]..sort((double a, double b) => b.compareTo(a));
      expect(probs, orderedEquals(sortedProbs));
    });

    test('bigram lookup with stupid backoff', () {
      final lex = _small();
      expect(lex.bigramLogProb('thank', 'you'), closeTo(-1.0, 0.06));
      expect(lex.bigramLogProb('Thank', 'You'), closeTo(-1.0, 0.06));
      expect(lex.bigramLogProb('you', 'the'), closeTo(-2.9 + math.log(0.4), 0.06));
      final thank = lex.idOf('thank');
      expect(lex.successors(thank).map((s) => lex.wordOf(s.$1)), ['you']);
    });

    test('trie walk and prefix subtree bound', () {
      final lex = _small();
      final node = lex.nodeForKey('than');
      expect(node, isNonNegative);
      expect(lex.isTerminal(node), isFalse);
      expect(lex.bestQ(node), 75); // thanks: -7.5
      expect(lex.nodeForKey('thanx'), -1);
    });

    test('corrections survive the round-trip', () {
      expect(_small().corrections['dont'], "don't");
    });

    test('rejects garbage', () {
      expect(() => MdictLexicon.fromBytes(Uint8List.fromList([1, 2, 3, 4, 5, 6])), throwsFormatException);
    });

    test('compressed form is smaller and equivalent', () {
      const source = [DictWord('hello', -9.0), DictWord('world', -9.5)];
      final raw = buildMdict(DictSource(language: 'en', words: source));
      final packed = buildMdict(DictSource(language: 'en', words: source), compress: true);
      expect(MdictLexicon.fromBytes(packed).logProb('world'), MdictLexicon.fromBytes(raw).logProb('world'));
    });

    test('indexes an arbitrary Lexicon', () {
      final lex = MdictLexicon.fromLexicon(_small());
      expect(lex.logProb('thank'), isNotNull);
    });
  });

  group('build_dictionary tool', () {
    test('turns a .combined list into a loadable dictionary', () async {
      final dir = Directory.systemTemp.createTempSync('booboard_dict_test');
      addTearDown(() => dir.deleteSync(recursive: true));
      final input = File('${dir.path}/tiny.combined')
        ..writeAsStringSync(
          [
            'dictionary=main:en_us,locale=en_US,description=English (US),date=1,version=54',
            ' word=the,f=200,flags=,originalFreq=200',
            '  bigram=other,f=1',
            ' word=other,f=150,flags=,originalFreq=150',
            ' word=damn,f=120,flags=,originalFreq=120,possibly_offensive=true',
            ' word=Hello,f=130,flags=,originalFreq=130',
            ' word=hello,f=100,flags=,originalFreq=100',
            ' word=café,f=90,flags=,originalFreq=90',
            ' word=ai.type,f=25,flags=hand-added,originalFreq=25',
            ' word=http://x.y,f=60,flags=,originalFreq=60',
            ' word=MP3,f=60,flags=abbreviation,originalFreq=60',
            ' word=q,f=80,flags=,originalFreq=80',
            ' word=im,f=0,not_a_word=true',
            "  shortcut=I'm,f=whitelist",
            ' word=cant,f=70,flags=,originalFreq=73',
            "  shortcut=can't,f=whitelist",
            '',
          ].join('\n'),
          encoding: utf8,
        );
      final out = '${dir.path}/tiny.mdict';
      final result = await Process.run('dart', [
        'run',
        'tool/build_dictionary.dart',
        '--input',
        input.path,
        '--lang',
        'en',
        '--out',
        out,
      ], runInShell: Platform.isWindows);
      expect(result.exitCode, 0, reason: '${result.stdout}${result.stderr}');
      final lex = MdictLexicon.fromBytes(File(out).readAsBytesSync());
      final words = lex.entries().map((e) => e.word).toList();
      expect(words, containsAll(['the', 'other', 'damn', 'hello', 'cant']));
      expect(words, isNot(contains('ai.type')));
      expect(words, isNot(contains('MP3')));
      expect(words, isNot(contains('q')));
      expect(words.where((w) => w.toLowerCase() == 'hello'), hasLength(1)); // case variants merge
      expect(lex.entries().firstWhere((e) => e.word == 'damn').isOffensive, isTrue);
      expect(lex.logProb('the')!, greaterThan(lex.logProb('other')!));
      expect(lex.bigramBetween(lex.idOf('the'), lex.idOf('other')), isNotNull);
      expect(lex.corrections['im'], "I'm");
      expect(lex.corrections['cant'], "can't");
      expect(lex.corrections['dont'], "don't"); // built-in English contractions
    }, timeout: const Timeout(Duration(minutes: 2)));
  });

  group('shipped English dictionary', () {
    final file = File('assets/dict/en.mdict');

    test('exists and is within the size budget', () {
      expect(file.existsSync(), isTrue);
      expect(file.lengthSync(), lessThanOrEqualTo(4 * 1024 * 1024));
    });

    test('loads quickly and answers lookups', () {
      final bytes = file.readAsBytesSync();
      final stopwatch = Stopwatch()..start();
      final lex = MdictLexicon.fromBytes(bytes);
      final ms = stopwatch.elapsedMilliseconds;
      // ignore: avoid_print
      print(
        'en.mdict: ${lex.size} words, ${lex.bigramCount} bigrams, loaded in $ms ms, '
        '${(lex.memoryBytes / 1024 / 1024).toStringAsFixed(1)} MiB resident',
      );
      expect(ms, lessThan(300));
      expect(lex.size, lessThanOrEqualTo(150000));
      expect(lex.logProb('hello'), isNotNull);
      expect(lex.logProb('receive'), isNotNull);
      expect(lex.idOf('xqzvbw'), -1);
      expect(lex.logProb('the')!, greaterThan(lex.logProb('hello')!));
      final thank = lex.idOf('thank');
      expect(lex.successors(thank).map((s) => lex.wordOf(s.$1)), contains('you'));
      expect(lex.corrections['dont'], "don't");
      expect(lex.corrections['im'], "I'm");
      expect(lex.corrections['youre'], "you're");
      // No junk keys.
      for (final e in lex.entries(limit: 5000)) {
        expect(e.word, matches(RegExp(r"^[\p{L}\p{M}'\-]+$", unicode: true)));
      }
      // Offensive words are flagged.
      expect(lex.entries().where((e) => e.isOffensive).length, greaterThan(100));
    });

    test('is loadable through the lexicon source with caching and eviction', () async {
      final repo = _FileRepo();
      final source = createLexiconSource(packs: repo, maxLoaded: 1);
      final a = await source.load('en');
      expect(source.isLoaded('en'), isTrue);
      expect(identical(await source.load('en'), a), isTrue);
      source.evict('en');
      expect(source.isLoaded('en'), isFalse);
      await expectLater(source.load('xx'), throwsStateError);
    });
  });
}

class _FileRepo implements PackRepository {
  @override
  Future<ByteData> load(String path) async {
    final bytes = File('assets/$path').readAsBytesSync();
    return ByteData.sublistView(bytes);
  }

  @override
  Future<String> loadString(String path) async => File('assets/$path').readAsStringSync();

  @override
  Future<bool> exists(String path) async => File('assets/$path').existsSync();
}
