// SPDX-License-Identifier: GPL-3.0-or-later
//
// Converts an Arabic-script word list into the ".combined" format that tool/build_dictionary.dart
// reads (Wave 3-C: ar and ur). Words are normalised (see normalize.dart) and capped by frequency.
//
//   ar, from HeliBoard's list (keeps its next-word data):
//     dart run tool/arabic/convert_arabic.dart --lang ar --source heliboard \
//       --input <main_ar__experimental.combined> --out tool/out/ar.combined --max-words 60000
//
//   ur, counted from a Wikipedia articles dump (CC BY-SA 4.0), streamed on stdin:
//     bzip2 -dc urwiki-latest-pages-articles.xml.bz2 | dart run tool/arabic/convert_arabic.dart \
//       --lang ur --source wiki --out tool/out/ur.combined --max-words 40000
//
// Then build the asset (the builder's --max-words keeps each .mdict under 1.5 MB):
//     dart run tool/build_dictionary.dart --input tool/out/ar.combined --lang ar --out assets/dict/ar.mdict
//
// Options: --lang ar|ur, --source heliboard|wiki, --input <file> (heliboard), --out <file>,
// --max-words N (default 60000), --max-bigrams N (default 60000), --min-count N (wiki, default 3).
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'normalize.dart';

Future<void> main(List<String> args) async {
  String? lang;
  String? source;
  String? input;
  String? out;
  var maxWords = 60000;
  var maxBigrams = 60000;
  var minCount = 3;
  for (var i = 0; i < args.length; i++) {
    switch (args[i]) {
      case '--lang':
        lang = args[++i];
      case '--source':
        source = args[++i];
      case '--input':
        input = args[++i];
      case '--out':
        out = args[++i];
      case '--max-words':
        maxWords = int.parse(args[++i]);
      case '--max-bigrams':
        maxBigrams = int.parse(args[++i]);
      case '--min-count':
        minCount = int.parse(args[++i]);
      default:
        stderr.writeln('Unknown argument ${args[i]}');
        exit(64);
    }
  }
  if (lang == null || out == null || (lang != 'ar' && lang != 'ur') || source == null) {
    stderr.writeln('Usage: see the header of tool/arabic/convert_arabic.dart');
    exit(64);
  }

  final words = switch (source) {
    'heliboard' when input != null => _fromHeliboard(File(input), lang),
    'wiki' => await _fromWiki(stdin, lang, minCount),
    _ => throw ArgumentError('--source heliboard needs --input; sources are heliboard and wiki'),
  };

  // Keep the most frequent words; ties keep the source order.
  final ranked = words.entries.toList()..sort((a, b) => b.value.f.compareTo(a.value.f));
  final top = ranked.take(maxWords).toList();
  final kept = {for (final e in top) e.key};

  final buffer = StringBuffer()
    ..writeln('dictionary=main:$lang,locale=$lang,description=BooBoard Arabic-script list (converted),version=18');
  var bigramCount = 0;
  for (final e in top) {
    buffer.writeln('word=${e.key},f=${e.value.f}');
    var written = 0;
    for (final b in e.value.bigrams) {
      if (written >= 8 || bigramCount >= maxBigrams || !kept.contains(b.$1)) continue;
      buffer.writeln('  bigram=${b.$1},f=${b.$2}');
      written++;
      bigramCount++;
    }
  }
  File(out)
    ..createSync(recursive: true)
    ..writeAsStringSync(buffer.toString());
  stderr.writeln('wrote $out: ${top.length} words (of ${words.length} normalised), $bigramCount bigram lines');
}

class _Scored {
  _Scored(this.f);
  int f;
  final List<(String, int)> bigrams = [];
}

/// HeliBoard's ".combined" lists: "word=X,f=N" lines, bigrams indented under their word.
Map<String, _Scored> _fromHeliboard(File file, String lang) {
  final out = <String, _Scored>{};
  _Scored? current;
  var kept = 0;
  var total = 0;
  for (final line in file.readAsLinesSync()) {
    if (line.startsWith('dictionary=')) continue;
    final attrs = _attributes(line.trim());
    if (!line.startsWith('  ') && attrs.containsKey('word')) {
      total++;
      final f = int.tryParse(attrs['f'] ?? '') ?? 0;
      final word = normalizeArabicWord(attrs['word']!, lang);
      current = null;
      if (word == null) continue;
      kept++;
      final existing = out[word];
      if (existing == null) {
        current = out[word] = _Scored(f);
      } else {
        existing.f = math.max(existing.f, f);
        current = existing;
      }
    } else if (attrs.containsKey('bigram') && current != null) {
      final next = normalizeArabicWord(attrs['bigram']!, lang);
      if (next != null) current.bigrams.add((next, int.tryParse(attrs['f'] ?? '') ?? 0));
    }
  }
  stderr.writeln('heliboard: $kept of $total words kept after normalisation');
  return out;
}

/// Word counts from a Wikipedia XML dump on [input]; f is log-scaled to 1..255.
Future<Map<String, _Scored>> _fromWiki(Stdin input, String lang, int minCount) async {
  final counts = <String, int>{};
  final lines = input.transform(utf8.decoder).transform(const LineSplitter());
  await for (final line in lines) {
    for (final w in arabicWordsIn(line, lang)) {
      counts[w] = (counts[w] ?? 0) + 1;
    }
  }
  final ranked = counts.entries.where((e) => e.value >= minCount).toList()..sort((a, b) => b.value.compareTo(a.value));
  if (ranked.isEmpty) return {};
  final cMax = math.log(ranked.first.value);
  final cMin = math.log(ranked.last.value);
  final out = <String, _Scored>{};
  for (final e in ranked) {
    final span = cMax - cMin;
    final scaled = span <= 0 ? 255 : (255 * (math.log(e.value) - cMin) / span).round();
    out[e.key] = _Scored(scaled.clamp(1, 255));
  }
  stderr.writeln('wiki: ${counts.length} distinct words, ${out.length} with count >= $minCount');
  return out;
}

Map<String, String> _attributes(String line) {
  final map = <String, String>{};
  for (final part in line.split(',')) {
    final eq = part.indexOf('=');
    if (eq <= 0) continue;
    map.putIfAbsent(part.substring(0, eq).trim(), () => part.substring(eq + 1).trim());
  }
  return map;
}
