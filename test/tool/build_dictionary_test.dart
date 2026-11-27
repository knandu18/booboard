// SPDX-License-Identifier: GPL-3.0-or-later
//
// Wave 3-A: the dictionary builder accepts every script. Short words in caseless scripts are kept,
// all-caps Cyrillic noise is dropped, and apostrophe variants are matched.
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:booboard/src/engine/dictionary/mdict_lexicon.dart';
import 'package:booboard/src/engine/dictionary/text_fold.dart';

void main() {
  group('build_dictionary tool, every script', () {
    test('keeps short Devanagari and Cyrillic words, drops all-caps Cyrillic noise', () async {
      final dir = Directory.systemTemp.createTempSync('booboard_dict_scripts');
      addTearDown(() => dir.deleteSync(recursive: true));
      final input = File('${dir.path}/scripts.combined')
        ..writeAsStringSync(
          [
            'dictionary=main:hi,locale=hi,description=test,date=1,version=1',
            ' word=का,f=200,flags=,originalFreq=200',
            ' word=है,f=190,flags=,originalFreq=190',
            ' word=ОН,f=150,flags=,originalFreq=150',
            ' word=он,f=140,flags=,originalFreq=140',
            " word=п'ять,f=120,flags=,originalFreq=120",
            ' word=ёж,f=100,flags=,originalFreq=100',
            '',
          ].join('\n'),
          encoding: utf8,
        );
      final out = '${dir.path}/scripts.mdict';
      final result = await Process.run('dart', [
        'run',
        'tool/build_dictionary.dart',
        '--input',
        input.path,
        '--lang',
        'ru',
        '--out',
        out,
      ], runInShell: Platform.isWindows);
      expect(result.exitCode, 0, reason: '${result.stdout}${result.stderr}');

      final lex = MdictLexicon.fromBytes(File(out).readAsBytesSync());
      final words = lex.entries().map((e) => e.word).toList();
      expect(words, containsAll(['का', 'है', 'он', "п'ять", 'ёж']));
      expect(words, isNot(contains('ОН')));
      // Apostrophe variants are matched through the fold.
      expect(lex.idOf('пʼять'), isNot(-1));
      expect(lex.idOf('п’ять'), isNot(-1));
    }, timeout: const Timeout(Duration(minutes: 2)));
  });

  group('folding', () {
    test('accents and case fold for lookup; ё and е stay separate letters', () {
      expect(foldKey('Café'), 'cafe');
      expect(foldKey('ÉCOLE'), 'ecole');
      expect(foldKey('ё'), isNot(foldKey('е')));
    });

    test('ß folds to ss only for lookup (typed ss finds the ß word, the reverse never happens)', () {
      expect(foldKey('Straße'), 'strasse');
      expect(foldKey('ß'), isNot('ß'));
    });
  });
}
