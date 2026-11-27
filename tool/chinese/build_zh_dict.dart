// SPDX-License-Identifier: GPL-3.0-or-later
//
// OWNER: Wave 4-A. Converts the rime-ice and OpenCC sources into the dict-zh-rime-ice pack files:
//   zh.kdict      the pinyin index (tool/chinese/zh_dict_writer.dart, read by ZhDictionary)
//   s2twp.tsv     the OpenCC Simplified-to-Traditional tables (read by S2twpConverter)
//
//   dart run tool/chinese/build_zh_dict.dart --rime <dir> --opencc <dir> --out <dir> \
//       [--min-base-weight 1000] [--golden <file>]
//
// <dir> for --rime holds base.dict.yaml, ext.dict.yaml and 8105.dict.yaml; --opencc holds
// STPhrases.txt, STCharacters.txt, TWPhrases.txt and TWVariants.txt. tool/packs/chinese/stage_rime_ice.ps1
// downloads them at pinned revisions and calls this. Prints counts and sizes, never dictionary text.
import 'dart:io';

import 'zh_dict_writer.dart';
import 'zh_sources.dart';

Future<void> main(List<String> argv) async {
  final args = _parse(argv);
  String need(String k) => args[k] ?? (throw ArgumentError('missing --$k'));
  final rime = Directory(need('rime'));
  final opencc = Directory(need('opencc'));
  final out = Directory(need('out'));
  final minBase = int.parse(args['min-base-weight'] ?? '1000');
  out.createSync(recursive: true);

  String read(Directory d, String name) => File('${d.path}/$name').readAsStringSync();

  final rimeEntries = entriesFromRime(
    base: read(rime, 'base.dict.yaml'),
    ext: read(rime, 'ext.dict.yaml'),
    chars: read(rime, '8105.dict.yaml'),
    options: RimeOptions(minBaseWeight: minBase),
  );
  stdout.writeln(
    'rows: base dropped ${rimeEntries.baseDropped} below weight $minBase, '
    'ext ${rimeEntries.extRows}, characters ${rimeEntries.charRows}',
  );
  stdout.writeln('kept: ${rimeEntries.words} words, ${rimeEntries.characters} characters');

  final stats = ZhDictStats();
  final bytes = buildZhDictionary(rimeEntries.entries, stats: stats);
  File('${out.path}/zh.kdict').writeAsBytesSync(bytes);
  stdout.writeln(
    'zh.kdict: ${(bytes.length / (1024 * 1024)).toStringAsFixed(1)} MB, ${stats.entries} entries, '
    '${stats.keys} keys, ${stats.initials} initials, ${stats.duplicates} duplicates merged',
  );

  final tsv = s2twpTsv(
    stPhrases: read(opencc, 'STPhrases.txt'),
    stCharacters: read(opencc, 'STCharacters.txt'),
    twPhrases: read(opencc, 'TWPhrases.txt'),
    twVariants: read(opencc, 'TWVariants.txt'),
  );
  File('${out.path}/s2twp.tsv').writeAsStringSync(tsv);
  stdout.writeln('s2twp.tsv: ${(tsv.length / 1024).toStringAsFixed(0)} KB');

  final golden = args['golden'];
  if (golden != null) {
    final goldenMin = int.parse(args['golden-min-weight'] ?? '5000');
    final lines = goldenCorpus(read(rime, 'base.dict.yaml'), minWeight: goldenMin);
    File(golden).writeAsStringSync('${lines.join('\n')}\n');
    stdout.writeln('golden corpus: ${lines.length} phrases');
  }
}

Map<String, String> _parse(List<String> argv) {
  final out = <String, String>{};
  for (var i = 0; i + 1 < argv.length; i += 2) {
    if (!argv[i].startsWith('--')) throw ArgumentError('unexpected ${argv[i]}');
    out[argv[i].substring(2)] = argv[i + 1];
  }
  return out;
}
