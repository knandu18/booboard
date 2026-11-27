// SPDX-License-Identifier: GPL-3.0-or-later
//
// OWNER: Wave 2-D. The emoji catalogue as shipped in assets/emoji (built by tool/build_emoji.dart):
// groups, base emoji with their skin-tone variants, and per-language keyword tables. Pure Dart; the
// decoders run off the UI isolate (see EmojiRepository).
//
// A "ref" names one displayable emoji: ref = item * [refStride] + tone, where tone 0 is the base
// emoji and 1..5 the skin-tone variants.
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:meta/meta.dart';

/// Refs are item * refStride + tone, so a stride of six leaves room for the base and five tones.
const int refStride = 6;

/// Skin-tone variants per base emoji.
const int toneCount = 5;

/// Skin-tone names for accessibility labels, in tone order 1..5.
const List<String> skinToneNames = [
  'light skin tone',
  'medium-light skin tone',
  'medium skin tone',
  'medium-dark skin tone',
  'dark skin tone',
];

@immutable
class EmojiItem {
  const EmojiItem({
    required this.text,
    required this.version,
    required this.group,
    required this.subgroup,
    required this.name,
    this.tones,
  });

  /// The base emoji as Unicode writes it (fully qualified).
  final String text;

  /// Emoji version times ten (15.1 is 151).
  final int version;
  final int group;
  final int subgroup;

  /// English name, for example "grinning face".
  final String name;

  /// Skin-tone variants 1..5. Null entries where Unicode has none. Null when the item has no variants.
  final List<String?>? tones;
}

/// Everything the emoji panel shows, plus the names used by accessibility labels.
@immutable
class EmojiData {
  const EmojiData({required this.unicodeVersion, required this.groups, required this.subgroups, required this.items});

  final String unicodeVersion;
  final List<String> groups;
  final List<String> subgroups;
  final List<EmojiItem> items;

  /// The text for [ref]. A tone the item does not have falls back to the base.
  String textOf(int ref) {
    final item = items[ref ~/ refStride];
    final tone = ref % refStride;
    if (tone == 0) return item.text;
    return item.tones?[tone - 1] ?? item.text;
  }

  /// True when [ref] names an emoji that exists (a tone the item has).
  bool hasRef(int ref) {
    final i = ref ~/ refStride;
    if (i < 0 || i >= items.length) return false;
    final tone = ref % refStride;
    if (tone == 0) return true;
    return items[i].tones?[tone - 1] != null;
  }

  /// English name for [ref], such as "waving hand: light skin tone".
  String nameOf(int ref) {
    final item = items[ref ~/ refStride];
    final tone = ref % refStride;
    if (tone == 0) return item.name;
    return '${item.name}: ${skinToneNames[tone - 1]}';
  }

  /// Index of the group named [name], or -1.
  int groupIndex(String name) => groups.indexOf(name);
}

/// One language's keyword table. [keys] is sorted (UTF-16 order, as the tool wrote it), so prefix search
/// is a binary search. [refs] is parallel to [keys].
@immutable
class EmojiKeywordTable {
  const EmojiKeywordTable({required this.lang, required this.keys, required this.refs, required this.shortNames});

  final String lang;
  final List<String> keys;
  final List<List<int>> refs;

  /// Ref to the CLDR short name in this language.
  final Map<int, String> shortNames;
}

/// Decodes emoji.dat (gzipped JSON). Expects the format written by tool/build_emoji.dart.
EmojiData decodeEmojiData(Uint8List gz) {
  final json = jsonDecode(utf8.decode(gzip.decode(gz))) as Map<String, Object?>;
  if (json['format'] != 1) throw const FormatException('unsupported emoji format');
  final groups = (json['groups']! as List<Object?>).cast<String>();
  final subgroups = (json['subgroups']! as List<Object?>).cast<String>();
  final rows = json['items']! as List<Object?>;
  final items = <EmojiItem>[];
  for (final r in rows) {
    final row = r! as List<Object?>;
    final tonesJson = row[5];
    items.add(
      EmojiItem(
        text: row[0]! as String,
        version: row[1]! as int,
        group: row[2]! as int,
        subgroup: row[3]! as int,
        name: row[4]! as String,
        tones: tonesJson == null ? null : [for (final t in tonesJson as List<Object?>) t as String?],
      ),
    );
  }
  return EmojiData(unicodeVersion: json['unicode']! as String, groups: groups, subgroups: subgroups, items: items);
}

/// Decodes `keywords_LANG.dat`: `[short]` lines `ref TAB name`, then `[keys]` lines
/// `keyword TAB refs`, where refs are base-36 deltas from the previous ref.
EmojiKeywordTable decodeKeywordTable(String lang, Uint8List gz) {
  final text = utf8.decode(gzip.decode(gz));
  final shortNames = <int, String>{};
  final keys = <String>[];
  final refs = <List<int>>[];
  var inKeys = false;
  for (final line in const LineSplitter().convert(text)) {
    if (line == '[short]') continue;
    if (line == '[keys]') {
      inKeys = true;
      continue;
    }
    final tab = line.indexOf('\t');
    if (tab < 0) continue;
    if (!inKeys) {
      shortNames[int.parse(line.substring(0, tab), radix: 36)] = line.substring(tab + 1);
      continue;
    }
    keys.add(line.substring(0, tab));
    final list = <int>[];
    var previous = 0;
    for (final delta in line.substring(tab + 1).split(' ')) {
      if (delta.isEmpty) continue;
      previous += int.parse(delta, radix: 36);
      list.add(previous);
    }
    refs.add(list);
  }
  return EmojiKeywordTable(lang: lang, keys: keys, refs: refs, shortNames: shortNames);
}
