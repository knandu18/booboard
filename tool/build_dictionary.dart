// SPDX-License-Identifier: GPL-3.0-or-later
//
// Builds a BooBoard dictionary asset (.mdict) from an AOSP/LatinIME ".combined"
// word list.
//
//   dart run tool/build_dictionary.dart --input tool/out/en.combined --lang en --out assets/dict/en.mdict
//
// Options:
//   --max-words N     keep at most N words (default 150000)
//   --max-bigrams N   keep at most N bigrams (default 350000)
//   --no-compress     write the raw payload (for debugging)
//
// The .combined format (one entry per line):
//   word=hello,f=120,flags=,originalFreq=80,possibly_offensive=true
//    bigram=world,f=3            (indented: a likely next word)
//    shortcut=I'm,f=whitelist    (indented: an always-applied correction)
// `f` is 0..255 on a roughly logarithmic scale. Bigram `f` is either a small
// rank (1..3, higher = better) or the same 0..255 scale.
//
// The file format is documented in lib/src/engine/dictionary/mdict_format.dart.
import 'dart:io';
import 'dart:math' as math;

import 'package:booboard/src/engine/dictionary/english_contractions.dart';
import 'package:booboard/src/engine/dictionary/mdict_writer.dart';
import 'package:booboard/src/engine/dictionary/text_fold.dart';

class _Entry {
  _Entry(this.word, this.f, {required this.offensive, required this.notAWord});

  final String word;
  final int f;
  final bool offensive;
  final bool notAWord;
  final List<(String, int)> bigrams = [];
  final List<String> shortcuts = [];
}

// Letters, marks, apostrophes and hyphens; ZWNJ/ZWJ appear inside Indic and Persian-script words.
final RegExp _wordPattern = RegExp(r"^\p{L}[\p{L}\p{M}'’\-‌‍]*$", unicode: true);

String? _cleanWord(String raw) {
  final w = normalizeNfc(raw.trim().replaceAll('’', "'"));
  if (w.isEmpty || w.length > 40) return null;
  if (!_wordPattern.hasMatch(w)) return null;
  if (w.endsWith("'") || w.endsWith('-') || w.contains("''") || w.contains('--')) return null;
  if (w.runes.length == 1 && w != 'a' && w != 'A' && w != 'I') return null;
  // Single capital letters and odd all-caps tokens are noise in the AOSP list.
  // Caseless scripts (Devanagari, Arabic, ...) never look like all-caps tokens.
  if (w.length <= 3 && w != w.toLowerCase() && w == w.toUpperCase() && w != 'I' && w != 'A') return null;
  return w;
}

Future<void> main(List<String> args) async {
  String? input;
  String? lang;
  String? out;
  var maxWords = 150000;
  var maxBigrams = 350000;
  var compress = true;
  for (var i = 0; i < args.length; i++) {
    switch (args[i]) {
      case '--input':
        input = args[++i];
      case '--lang':
        lang = args[++i];
      case '--out':
        out = args[++i];
      case '--max-words':
        maxWords = int.parse(args[++i]);
      case '--max-bigrams':
        maxBigrams = int.parse(args[++i]);
      case '--no-compress':
        compress = false;
      default:
        stderr.writeln('Unknown argument ${args[i]}');
        exit(64);
    }
  }
  if (input == null || lang == null || out == null) {
    stderr.writeln('Usage: dart run tool/build_dictionary.dart --input <file> --lang en --out assets/dict/en.mdict');
    exit(64);
  }

  // 1. Parse.
  final entries = <_Entry>[];
  _Entry? current;
  var skipped = 0;
  for (final line in File(input).readAsLinesSync()) {
    if (line.startsWith('dictionary=')) continue;
    final trimmed = line.trim();
    if (trimmed.isEmpty) continue;
    final attrs = _attributes(trimmed);
    if (!line.startsWith('  ') && attrs.containsKey('word')) {
      final word = attrs['word'];
      final f = int.tryParse(attrs['f'] ?? '');
      if (word == null || f == null) {
        current = null;
        skipped++;
        continue;
      }
      current = _Entry(
        word,
        f,
        offensive: attrs['possibly_offensive'] == 'true',
        notAWord: attrs['not_a_word'] == 'true',
      );
      entries.add(current);
    } else if (attrs.containsKey('bigram') && current != null) {
      current.bigrams.add((attrs['bigram']!, int.tryParse(attrs['f'] ?? '') ?? 0));
    } else if (attrs.containsKey('shortcut') && current != null) {
      if (attrs['f'] == 'whitelist') current.shortcuts.add(attrs['shortcut']!);
    }
  }

  // 2. Clean words; collect corrections.
  final kept = <_Entry, String>{};
  final corrections = <String, String>{};
  var junk = 0;
  for (final e in entries) {
    final typedKey = foldKey(e.word);
    if (e.shortcuts.isNotEmpty) {
      final target = _cleanTarget(e.shortcuts.first);
      if (target != null && foldKey(target) != typedKey) {
        final isContraction = foldKey(target.replaceAll("'", '')) == typedKey;
        // Real words are only corrected when the fix is just the apostrophe.
        if (e.notAWord || isContraction) corrections[typedKey] = target;
      }
    }
    if (e.notAWord) continue;
    final word = _cleanWord(e.word);
    if (word == null) {
      junk++;
      continue;
    }
    kept[e] = word;
  }
  if (lang == 'en') corrections.addAll(kEnglishContractions);

  // 3. Cap the word list by frequency.
  final ranked = kept.keys.toList()..sort((a, b) => b.f.compareTo(a.f));
  final top = ranked.take(maxWords).toList();
  final fMax = top.isEmpty ? 255 : top.map((e) => e.f).reduce(math.max);
  double unigramLogProb(int f) => -3.0 - (fMax - f) * 0.075;

  final words = [for (final e in top) DictWord(kept[e]!, unigramLogProb(e.f), offensive: e.offensive)];
  final keptKeys = {for (final w in words) foldKey(w.surface)};

  // 4. Bigrams: strongest first, only between kept words.
  var bigramFMax = 0;
  for (final e in top) {
    for (final b in e.bigrams) {
      bigramFMax = math.max(bigramFMax, b.$2);
    }
  }
  double bigramLogProb(int f) {
    if (bigramFMax <= 15) {
      // Rank-style data: 1..3, higher is a more likely successor.
      final p = math.min(0.6, 0.06 * math.pow(2.2, f - 1));
      return math.log(p);
    }
    return math.min(-0.1, -0.5 - (bigramFMax - f) * 0.075);
  }

  final bigrams = <DictBigram>[];
  for (final e in top) {
    final prev = kept[e]!;
    for (final b in e.bigrams) {
      final next = _cleanWord(b.$1);
      if (next == null || !keptKeys.contains(foldKey(next))) continue;
      bigrams.add(DictBigram(prev, next, bigramLogProb(b.$2)));
    }
  }
  bigrams.sort((a, b) => b.logProb.compareTo(a.logProb));
  final cappedBigrams = bigrams.take(maxBigrams).toList();

  // 5. Write.
  final source = DictSource(language: lang, words: words, bigrams: cappedBigrams, corrections: corrections);
  final bytes = buildMdict(source, compress: compress);
  File(out)
    ..createSync(recursive: true)
    ..writeAsBytesSync(bytes);
  stdout.writeln(
    'wrote $out: ${bytes.length} bytes | words ${words.length} (of ${entries.length} parsed, '
    '$junk junk, $skipped unparsable) | offensive ${words.where((w) => w.offensive).length} | '
    'bigrams ${cappedBigrams.length} | corrections ${corrections.length}',
  );
}

/// Strips quotes/odd spacing from a shortcut target; null if unusable.
String? _cleanTarget(String raw) {
  final t = normalizeNfc(raw.trim().replaceAll('’', "'"));
  if (t.isEmpty || t.length > 40) return null;
  return t;
}

/// Parses "a=b,c=d" attribute lists. The first key is the line's subject.
Map<String, String> _attributes(String line) {
  final map = <String, String>{};
  for (final part in line.split(',')) {
    final eq = part.indexOf('=');
    if (eq <= 0) continue;
    map.putIfAbsent(part.substring(0, eq).trim(), () => part.substring(eq + 1));
  }
  return map;
}
