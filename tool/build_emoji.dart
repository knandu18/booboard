// SPDX-License-Identifier: GPL-3.0-or-later
//
// Dev-time tool, never part of the app and never run on a device. Builds the offline emoji data
// in assets/emoji/ from the Unicode emoji test file and the CLDR annotations.
//
//   dart run tool/build_emoji.dart [--cache=.dart_tool/emoji_src] [--out=assets/emoji] [--cldr-tag=release-49]
//
// Sources are downloaded once into --cache (reused on later runs). Data: Unicode License v3,
// see docs/notices/emoji.md for the exact versions, URLs and sizes.
//
// Output:
//   emoji.dat               gzipped JSON: groups, subgroups and every base emoji in display order.
//                          An item is [text, unicodeVersion x10, group, subgroup, englishName, tones?].
//                          `tones` holds the five skin-tone variants (null where Unicode has none).
//   keywords_<lang>.dat     gzipped JSON per language: `short` [[ref, shortName]...] and `keys`
//                          {keyword: [ref...]}. A ref is item * 6 + tone (tone 0 = the base emoji).
import 'dart:convert';
import 'dart:io';

const String emojiTestUrl = 'https://unicode.org/Public/emoji/latest/emoji-test.txt';
const String cldrRawUrl = 'https://raw.githubusercontent.com/unicode-org/cldr';
const String defaultCldrTag = 'release-49';
const List<String> emojiLanguages = [
  'en', 'es', 'fr', 'de', 'pt', 'id', 'hi', 'mr', 'bn', 'ta', 'te', 'ar', 'ur', 'ru', 'uk', 'zh', 'ja', 'fil', //
];

/// Skin-tone modifiers U+1F3FB..U+1F3FF are the five tones 1..5.
const int skinToneFirst = 0x1F3FB;
const int skinToneLast = 0x1F3FF;
const int toneCount = 5;

/// Refs are item * refStride + tone.
const int refStride = toneCount + 1;

/// Budget for everything in assets/emoji together.
const int sizeBudgetBytes = 2500 * 1024;

Future<void> main(List<String> args) async {
  final options = _parseArgs(args);
  final cache = Directory(options['cache'] ?? '.dart_tool/emoji_src')..createSync(recursive: true);
  final out = Directory(options['out'] ?? 'assets/emoji')..createSync(recursive: true);
  final tag = options['cldr-tag'] ?? defaultCldrTag;

  final testSource = await _fetchCached(emojiTestUrl, '${cache.path}/emoji-test.txt');
  final lines = parseEmojiTest(testSource);
  final unicodeVersion = _unicodeVersionOf(testSource);
  final catalog = buildCatalog(lines, unicodeVersion: unicodeVersion);
  final refs = buildRefIndex(catalog.items);
  stdout.writeln(
    'Unicode $unicodeVersion: ${lines.length} fully-qualified lines, ${catalog.items.length} items, '
    '${catalog.orphanVariants} orphan skin-tone variants',
  );

  final emojiBytes = encodeGz(utf8.encode(jsonEncode(catalog.toJson())));
  final sizes = <String, int>{'emoji.dat': emojiBytes.length};
  File('${out.path}/emoji.dat').writeAsBytesSync(emojiBytes);

  for (final lang in emojiLanguages) {
    final annotations = await _fetchCached(
      '$cldrRawUrl/$tag/common/annotations/$lang.xml',
      '${cache.path}/$lang.annotations.xml',
    );
    final derived = await _fetchCached(
      '$cldrRawUrl/$tag/common/annotationsDerived/$lang.xml',
      '${cache.path}/$lang.annotationsDerived.xml',
    );
    final index = buildKeywords(lang: lang, annotations: annotations, derived: derived, refs: refs);
    final bytes = encodeGz(utf8.encode(index.toText()));
    final name = 'keywords_$lang.dat';
    File('${out.path}/$name').writeAsBytesSync(bytes);
    sizes[name] = bytes.length;
    stdout.writeln('$lang: ${index.keys.length} keys, ${index.shortNames.length} short names, ${bytes.length} bytes');
  }

  final total = sizes.values.fold<int>(0, (a, b) => a + b);
  stdout.writeln('Total $total bytes (budget $sizeBudgetBytes)');
  if (total > sizeBudgetBytes) {
    stderr.writeln('Over the size budget');
    exitCode = 1;
  }
}

Map<String, String> _parseArgs(List<String> args) {
  final map = <String, String>{};
  for (final a in args) {
    if (!a.startsWith('--')) continue;
    final eq = a.indexOf('=');
    if (eq < 0) {
      map[a.substring(2)] = 'true';
    } else {
      map[a.substring(2, eq)] = a.substring(eq + 1);
    }
  }
  return map;
}

Future<String> _fetchCached(String url, String path) async {
  final file = File(path);
  if (file.existsSync()) return file.readAsStringSync();
  final client = HttpClient();
  try {
    final request = await client.getUrl(Uri.parse(url));
    final response = await request.close();
    if (response.statusCode != 200) {
      throw HttpException('HTTP ${response.statusCode} for $url', uri: Uri.parse(url));
    }
    final body = await response.transform(utf8.decoder).join();
    file.writeAsStringSync(body);
    return body;
  } finally {
    client.close();
  }
}

List<int> encodeGz(List<int> bytes) => gzip.encode(bytes);

// ---------------------------------------------------------------------------
// emoji-test.txt
// ---------------------------------------------------------------------------

/// One fully-qualified line of emoji-test.txt.
class EmojiLine {
  EmojiLine({
    required this.text,
    required this.codepoints,
    required this.version,
    required this.group,
    required this.subgroup,
    required this.name,
  });

  final String text;
  final List<int> codepoints;

  /// Emoji version times ten, so E15.1 is 151.
  final int version;
  final String group;
  final String subgroup;

  /// English name, for example "waving hand: light skin tone".
  final String name;
}

final RegExp _emojiVersion = RegExp(r'^E(\d+)\.(\d+)$');

/// Parses emoji-test.txt. Only fully-qualified lines are kept (the forms a keyboard should offer).
List<EmojiLine> parseEmojiTest(String source) {
  final out = <EmojiLine>[];
  var group = '';
  var subgroup = '';
  for (final raw in const LineSplitter().convert(source)) {
    final line = raw.trimRight();
    if (line.startsWith('# group:')) {
      group = line.substring('# group:'.length).trim();
      continue;
    }
    if (line.startsWith('# subgroup:')) {
      subgroup = line.substring('# subgroup:'.length).trim();
      continue;
    }
    if (line.isEmpty || line.startsWith('#')) continue;
    final semi = line.indexOf(';');
    final hash = line.indexOf('#');
    if (semi < 0 || hash < semi) continue;
    if (line.substring(semi + 1, hash).trim() != 'fully-qualified') continue;
    final codepoints = [
      for (final hex in line.substring(0, semi).trim().split(RegExp(r'\s+'))) int.parse(hex, radix: 16),
    ];
    // The comment is "<emoji> E<major>.<minor> <english name>".
    final parts = line.substring(hash + 1).trim().split(' ');
    final versionAt = parts.indexWhere((p) => _emojiVersion.hasMatch(p));
    if (versionAt < 1) continue;
    final match = _emojiVersion.firstMatch(parts[versionAt])!;
    final version = int.parse(match.group(1)!) * 10 + int.parse(match.group(2)!);
    out.add(
      EmojiLine(
        text: String.fromCharCodes(codepoints),
        codepoints: codepoints,
        version: version,
        group: group,
        subgroup: subgroup,
        name: parts.sublist(versionAt + 1).join(' '),
      ),
    );
  }
  return out;
}

String _unicodeVersionOf(String source) {
  final match = RegExp(r'^# Version: (\S+)', multiLine: true).firstMatch(source);
  return match?.group(1) ?? 'unknown';
}

/// 0 for no skin tone, 1..5 for exactly one skin-tone modifier, -1 for several (couples, families).
int skinToneIndex(List<int> codepoints) {
  var count = 0;
  var tone = 0;
  for (final cp in codepoints) {
    if (cp >= skinToneFirst && cp <= skinToneLast) {
      count++;
      tone = cp - skinToneFirst + 1;
    }
  }
  if (count == 0) return 0;
  return count == 1 ? tone : -1;
}

/// Identity of an emoji for grouping. U+FE0F is ignored, because a base may be "1F590 FE0F" while its
/// skin-tone variant drops the selector: "1F590 1F3FB" minus the tone is "1F590".
String _keyOf(Iterable<int> codepoints) =>
    codepoints.where((c) => c != 0xFE0F).map((c) => c.toRadixString(16)).join(' ');

bool _isSkinTone(int cp) => cp >= skinToneFirst && cp <= skinToneLast;

// ---------------------------------------------------------------------------
// Catalog: base emoji with their skin-tone variants grouped under them
// ---------------------------------------------------------------------------

class CatalogItem {
  CatalogItem({
    required this.text,
    required this.version,
    required this.group,
    required this.subgroup,
    required this.name,
  });

  final String text;
  final int version;
  final int group;
  final int subgroup;
  final String name;

  /// Skin tones 1..5 in order; null entries where Unicode has no variant. Null when there are none.
  List<String?>? tones;
}

class EmojiCatalog {
  EmojiCatalog({
    required this.unicodeVersion,
    required this.groups,
    required this.subgroups,
    required this.items,
    required this.orphanVariants,
  });

  final String unicodeVersion;
  final List<String> groups;
  final List<String> subgroups;
  final List<CatalogItem> items;

  /// Skin-tone lines whose base was missing. They become items of their own.
  final int orphanVariants;

  Map<String, Object?> toJson() => {
    'format': 1,
    'unicode': unicodeVersion,
    'groups': groups,
    'subgroups': subgroups,
    'items': [
      for (final i in items) [i.text, i.version, i.group, i.subgroup, i.name, i.tones],
    ],
  };
}

/// Groups the skin-tone variants under their base emoji. The Component group (skin-tone swatches
/// and hair styles) is not offered and is dropped.
EmojiCatalog buildCatalog(List<EmojiLine> lines, {required String unicodeVersion}) {
  final groups = <String>[];
  final subgroups = <String>[];
  int indexIn(List<String> list, String name) {
    final i = list.indexOf(name);
    if (i >= 0) return i;
    list.add(name);
    return list.length - 1;
  }

  final items = <CatalogItem>[];
  final baseByKey = <String, int>{};
  final variants = <EmojiLine>[];
  for (final line in lines) {
    if (line.group == 'Component') continue;
    if (skinToneIndex(line.codepoints) > 0) {
      variants.add(line);
      continue;
    }
    baseByKey[_keyOf(line.codepoints)] = items.length;
    items.add(
      CatalogItem(
        text: line.text,
        version: line.version,
        group: indexIn(groups, line.group),
        subgroup: indexIn(subgroups, line.subgroup),
        name: line.name,
      ),
    );
  }
  var orphans = 0;
  for (final v in variants) {
    final baseKey = _keyOf(v.codepoints.where((c) => !_isSkinTone(c)));
    final base = baseByKey[baseKey];
    if (base == null) {
      orphans++;
      items.add(
        CatalogItem(
          text: v.text,
          version: v.version,
          group: indexIn(groups, v.group),
          subgroup: indexIn(subgroups, v.subgroup),
          name: v.name,
        ),
      );
      continue;
    }
    final item = items[base];
    final tone = skinToneIndex(v.codepoints);
    final tones = item.tones ??= List<String?>.filled(toneCount, null);
    tones[tone - 1] = v.text;
  }
  return EmojiCatalog(
    unicodeVersion: unicodeVersion,
    groups: groups,
    subgroups: subgroups,
    items: items,
    orphanVariants: orphans,
  );
}

/// Strips U+FE0F (variation selector 16), as CLDR does in its `cp` values.
String stripVariationSelector(String s) => s.replaceAll('️', '');

/// Maps each emoji text (without U+FE0F) to its ref.
Map<String, int> buildRefIndex(List<CatalogItem> items) {
  final refs = <String, int>{};
  for (var i = 0; i < items.length; i++) {
    refs.putIfAbsent(stripVariationSelector(items[i].text), () => i * refStride);
    final tones = items[i].tones;
    if (tones == null) continue;
    for (var t = 0; t < toneCount; t++) {
      final text = tones[t];
      if (text == null) continue;
      refs.putIfAbsent(stripVariationSelector(text), () => i * refStride + t + 1);
    }
  }
  return refs;
}

// ---------------------------------------------------------------------------
// CLDR annotations
// ---------------------------------------------------------------------------

class KeywordIndex {
  KeywordIndex({required this.lang, required this.shortNames, required this.keys});

  final String lang;

  /// Ref to the CLDR short name ("grinning face").
  final Map<int, String> shortNames;

  /// Normalised keyword or word to the refs it finds.
  final Map<String, List<int>> keys;

  /// Compact UTF-8 text, gzipped by the caller:
  ///   `[short]` then `<ref base36>\t<short name>` lines,
  ///   `[keys]` then `<keyword>\t<refs>` lines, where refs are base-36 deltas from the previous ref.
  String toText() {
    final out = StringBuffer()..write('[short]\n');
    final shorts = shortNames.keys.toList()..sort();
    for (final r in shorts) {
      out
        ..write(r.toRadixString(36))
        ..write('\t')
        ..write(shortNames[r])
        ..write('\n');
    }
    out.write('[keys]\n');
    final sortedKeys = keys.keys.toList()..sort();
    for (final k in sortedKeys) {
      final refs = keys[k]!.toList()..sort();
      out
        ..write(k)
        ..write('\t');
      var previous = 0;
      for (var i = 0; i < refs.length; i++) {
        if (i > 0) out.write(' ');
        out.write((refs[i] - previous).toRadixString(36));
        previous = refs[i];
      }
      out.write('\n');
    }
    return out.toString();
  }
}

final RegExp _annotationElement = RegExp(r'<annotation\s([^>]*)>([^<]*)</annotation>');
final RegExp _cpAttribute = RegExp(r'cp="([^"]*)"');
final RegExp _typeAttribute = RegExp(r'type="([^"]*)"');

String unescapeXml(String s) => s
    .replaceAll('&quot;', '"')
    .replaceAll('&apos;', "'")
    .replaceAll('&lt;', '<')
    .replaceAll('&gt;', '>')
    .replaceAll('&amp;', '&');

/// Normalises a keyword: lower case, single spaces.
String normaliseKeyword(String s) => s.trim().toLowerCase().split(RegExp(r'\s+')).where((w) => w.isNotEmpty).join(' ');

/// Builds one language's index from its base and derived annotation files. Derived annotations add
/// the keywords of skin-tone variants. A phrase such as "grinning face" is also indexed word by word,
/// so prefix search finds it from either word.
KeywordIndex buildKeywords({
  required String lang,
  required String annotations,
  String? derived,
  required Map<String, int> refs,
}) {
  final shortNames = <int, String>{};
  final keys = <String, Set<int>>{};

  void addKey(String phrase, int ref) {
    final p = normaliseKeyword(phrase);
    if (p.isEmpty) return;
    keys.putIfAbsent(p, () => <int>{}).add(ref);
    if (p.contains(' ')) {
      for (final word in p.split(' ')) {
        keys.putIfAbsent(word, () => <int>{}).add(ref);
      }
    }
  }

  void readFile(String xml) {
    for (final m in _annotationElement.allMatches(xml)) {
      final attrs = m.group(1)!;
      final cpMatch = _cpAttribute.firstMatch(attrs);
      if (cpMatch == null) continue;
      final cp = stripVariationSelector(unescapeXml(cpMatch.group(1)!));
      final ref = refs[cp];
      if (ref == null) continue;
      final value = unescapeXml(m.group(2)!);
      final type = _typeAttribute.firstMatch(attrs)?.group(1);
      if (type == 'tts') {
        shortNames.putIfAbsent(ref, () => value.trim());
        addKey(value, ref);
      } else {
        for (final kw in value.split('|')) {
          addKey(kw, ref);
        }
      }
    }
  }

  readFile(annotations);
  if (derived != null) readFile(derived);
  return KeywordIndex(
    lang: lang,
    shortNames: shortNames,
    keys: {for (final e in keys.entries) e.key: e.value.toList()},
  );
}
