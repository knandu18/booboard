// SPDX-License-Identifier: GPL-3.0-or-later
//
// OWNER: Wave 3-B. Builds assets/dict/<lang>.mdict from a .combined word list written by
// tool/indic/build_data.py.
//
//   dart run tool/indic/build_indic_dict.dart --input <scratch>/combined/hi.combined --lang hi \
//       --out assets/dict/hi.mdict
//
// Why not tool/build_dictionary.dart: its word cleaning drops every word of three characters or
// fewer that "is upper case" (`w == w.toUpperCase()`), and Indic scripts have no case, so it would
// drop common words such as है, और and में. This tool keeps the same frequency-to-probability mapping
// and the same MDICT writer, and skips the Latin-only cleaning.
import 'dart:io';

import 'package:booboard/src/engine/dictionary/mdict_writer.dart';

// Same mapping as tool/build_dictionary.dart: unigram log-probability from the 0..255 frequency.
double _logProb(int f, int fMax) => -3.0 - (fMax - f) * 0.075;

Future<void> main(List<String> args) async {
  String? input;
  String? lang;
  String? out;
  for (var i = 0; i < args.length; i++) {
    switch (args[i]) {
      case '--input':
        input = args[++i];
      case '--lang':
        lang = args[++i];
      case '--out':
        out = args[++i];
      default:
        stderr.writeln('Unknown argument ${args[i]}');
        exit(64);
    }
  }
  if (input == null || lang == null || out == null) {
    stderr.writeln(
      'Usage: dart run tool/indic/build_indic_dict.dart --input <file> --lang hi --out assets/dict/hi.mdict',
    );
    exit(64);
  }

  final rows = <(String, int)>[];
  for (final line in File(input).readAsLinesSync()) {
    if (!line.startsWith('word=')) continue;
    final comma = line.lastIndexOf(',f=');
    if (comma < 0) continue;
    final word = line.substring(5, comma);
    final f = int.tryParse(line.substring(comma + 3));
    if (word.isEmpty || f == null) continue;
    rows.add((word, f));
  }
  final fMax = rows.isEmpty ? 255 : rows.map((r) => r.$2).reduce((a, b) => a > b ? a : b);
  final source = DictSource(
    language: lang,
    words: [for (final (w, f) in rows) DictWord(w, _logProb(f, fMax))],
    foldAccents: false,
  );
  final bytes = buildMdict(source, compress: true);
  File(out)
    ..createSync(recursive: true)
    ..writeAsBytesSync(bytes);
  stdout.writeln('wrote $out: ${bytes.length} bytes, ${rows.length} words');
}
