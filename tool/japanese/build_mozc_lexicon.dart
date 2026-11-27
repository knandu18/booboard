// SPDX-License-Identifier: GPL-3.0-or-later
//
// OWNER: Wave 4-B (Japanese). Converts the Mozc open-source dictionary (BSD-3-Clause; see
// docs/notices/japanese.md) into the dict-ja-mozc pack files japanese.lex and japanese.conn.
//
//   dart run tool/japanese/build_mozc_lexicon.dart --src <dir> --out <dir> [--transpose]
//
// <dir> holds the files from src/data/dictionary_oss/ of the pinned Mozc commit: dictionary00.txt to
// dictionary09.txt, connection_single_column.txt and id.def. tool/packs/japanese/stage_mozc.ps1 downloads
// them and calls this tool.
//
// Readings are normalised to hiragana (katakana readings are folded). Entries whose reading has any
// other character (latin, digits, symbols) are dropped: the keyboard looks words up by kana.
// --transpose stores the connection matrix transposed; it exists to check the orientation.
import 'dart:io';

import 'lexicon_writer.dart';

const String _unknownName = '名詞,一般,*,*,*,*,*';

Future<void> main(List<String> argv) async {
  final args = _parse(argv);
  final src = Directory(args['src'] ?? (throw ArgumentError('missing --src')));
  final out = Directory(args['out'] ?? (throw ArgumentError('missing --out')));
  final transpose = argv.contains('--transpose');
  out.createSync(recursive: true);

  final unknownId = _unknownId(File('${src.path}/id.def'));
  stdout.writeln('unknown word id: $unknownId');

  final conn = _readMatrix(File('${src.path}/connection_single_column.txt'));
  final n = conn.$1;
  var costs = conn.$2;
  stdout.writeln('connection matrix: $n x $n');
  if (transpose) {
    final t = List<int>.filled(n * n, 0);
    for (var r = 0; r < n; r++) {
      for (var c = 0; c < n; c++) {
        t[c * n + r] = costs[r * n + c];
      }
    }
    costs = t;
  }

  final entries = <LexiconEntry>[];
  var skipped = 0;
  var read = 0;
  for (var i = 0; i <= 9; i++) {
    final file = File('${src.path}/dictionary0$i.txt');
    if (!file.existsSync()) throw StateError('missing ${file.path}');
    for (final line in file.readAsLinesSync()) {
      read++;
      final f = line.split('\t');
      if (f.length != 5) {
        skipped++;
        continue;
      }
      final reading = _toHiragana(f[0]);
      final lid = int.tryParse(f[1]);
      final rid = int.tryParse(f[2]);
      final cost = int.tryParse(f[3]);
      if (reading == null || lid == null || rid == null || cost == null || f[4].isEmpty) {
        skipped++;
        continue;
      }
      if (lid >= n || rid >= n) {
        skipped++;
        continue;
      }
      entries.add(LexiconEntry(reading: reading, surface: f[4], lid: lid, rid: rid, cost: cost));
    }
  }
  stdout.writeln('dictionary lines read: $read, kept: ${entries.length}, skipped: $skipped');

  final lex = buildLexiconBytes(entries, unknownId: unknownId);
  final conData = buildConnectionBytes(n, costs);
  // The pack ships both files gzip-compressed (the keyboard inflates them once at load).
  final lexGz = gzip.encode(lex);
  final connGz = gzip.encode(conData);
  File('${out.path}/japanese.lex.gz').writeAsBytesSync(lexGz);
  File('${out.path}/japanese.conn.gz').writeAsBytesSync(connGz);
  stdout.writeln(
    'japanese.lex.gz ${lexGz.length} bytes (from ${lex.length}); '
    'japanese.conn.gz ${connGz.length} bytes (from ${conData.length})',
  );
}

/// The id of the unknown-word node, from id.def ("1851 名詞,一般,*,*,*,*,*").
int _unknownId(File idDef) {
  for (final line in idDef.readAsLinesSync()) {
    final sp = line.indexOf(' ');
    if (sp > 0 && line.substring(sp + 1) == _unknownName) {
      return int.parse(line.substring(0, sp));
    }
  }
  throw StateError('no $_unknownName in id.def');
}

/// Reads "N" then N*N integers (one per line in the Mozc file), without building a list of lines.
(int, List<int>) _readMatrix(File file) {
  final bytes = file.readAsBytesSync();
  var pos = 0;
  int next() {
    while (pos < bytes.length && (bytes[pos] < 0x30 || bytes[pos] > 0x39) && bytes[pos] != 0x2D) {
      pos++;
    }
    var negative = false;
    if (pos < bytes.length && bytes[pos] == 0x2D) {
      negative = true;
      pos++;
    }
    var v = 0;
    var any = false;
    while (pos < bytes.length && bytes[pos] >= 0x30 && bytes[pos] <= 0x39) {
      v = v * 10 + (bytes[pos] - 0x30);
      pos++;
      any = true;
    }
    if (!any) throw StateError('connection matrix ends early');
    return negative ? -v : v;
  }

  final n = next();
  final costs = List<int>.filled(n * n, 0);
  for (var i = 0; i < n * n; i++) {
    costs[i] = next();
  }
  return (n, costs);
}

/// Hiragana with katakana folded to hiragana; null when the reading has any other character.
String? _toHiragana(String reading) {
  if (reading.isEmpty) return null;
  final out = StringBuffer();
  for (final r in reading.runes) {
    if (r >= 0x30A1 && r <= 0x30F6) {
      out.writeCharCode(r - 0x60);
    } else if ((r >= 0x3041 && r <= 0x3096) || r == 0x30FC) {
      out.writeCharCode(r);
    } else {
      return null;
    }
  }
  return out.toString();
}

Map<String, String> _parse(List<String> argv) {
  final out = <String, String>{};
  for (var i = 0; i + 1 < argv.length; i++) {
    if (argv[i].startsWith('--') && argv[i + 1] != '--transpose' && !argv[i + 1].startsWith('--')) {
      out[argv[i].substring(2)] = argv[i + 1];
    }
  }
  return out;
}
