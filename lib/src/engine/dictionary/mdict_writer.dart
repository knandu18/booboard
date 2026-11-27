// SPDX-License-Identifier: GPL-3.0-or-later
//
// Serialises a word list into the MDICT format (see mdict_format.dart). Used by
// tool/build_dictionary.dart and, at runtime, to index lexicons that were not
// loaded from an .mdict asset (tests, previews).
import 'dart:convert';
import 'dart:io' show ZLibCodec;
import 'dart:typed_data';

import 'mdict_format.dart';
import 'text_fold.dart';

class DictWord {
  const DictWord(this.surface, this.logProb, {this.offensive = false});

  final String surface;

  /// Natural-log unigram probability (<= 0).
  final double logProb;
  final bool offensive;
}

class DictBigram {
  const DictBigram(this.previous, this.next, this.logProb);

  /// Surface or folded forms; both are folded before use.
  final String previous;
  final String next;
  final double logProb;
}

class DictSource {
  DictSource({
    required this.language,
    required this.words,
    this.bigrams = const [],
    this.corrections = const {},
    this.foldAccents = true,
  });

  final String language;
  final List<DictWord> words;
  final List<DictBigram> bigrams;

  /// typed (folded) -> replacement text.
  final Map<String, String> corrections;
  final bool foldAccents;
}

class _Node {
  _Node(this.depth);

  final int depth;
  int? wordId;
  int q = 0;
  bool offensive = false;
  final List<int> chars = [];
  final List<_Node> kids = [];
  int bestQ = 255;
  int offset = 0;
}

/// Builds the payload bytes. Pass [compress] to get the on-disk form.
Uint8List buildMdict(DictSource source, {bool compress = false}) {
  // 1. Fold and deduplicate: the most frequent spelling of a key wins.
  final best = <String, DictWord>{};
  for (final w in source.words) {
    if (w.surface.isEmpty) continue;
    final key = foldKey(w.surface, stripAccents: source.foldAccents);
    final old = best[key];
    if (old == null) {
      best[key] = w;
      continue;
    }
    // Case/accent variants of one key share the highest probability; the
    // spelling shown is the lower-case one if there is one (sentence-initial
    // capitals are noise), otherwise the more frequent.
    final newLower = w.surface == w.surface.toLowerCase();
    final oldLower = old.surface == old.surface.toLowerCase();
    final DictWord shown = newLower != oldLower ? (newLower ? w : old) : (w.logProb > old.logProb ? w : old);
    best[key] = DictWord(shown.surface, w.logProb > old.logProb ? w.logProb : old.logProb, offensive: shown.offensive);
  }
  final keys = best.keys.toList()..sort();
  final n = keys.length;
  final idOf = <String, int>{for (var i = 0; i < n; i++) keys[i]: i};

  // 2. Trie.
  final root = _Node(0);
  for (var id = 0; id < n; id++) {
    var node = root;
    final key = keys[id];
    for (var i = 0; i < key.length; i++) {
      final c = key.codeUnitAt(i);
      if (node.chars.isNotEmpty && node.chars.last == c) {
        node = node.kids.last;
      } else {
        final kid = _Node(node.depth + 1);
        node.chars.add(c);
        node.kids.add(kid);
        node = kid;
      }
    }
    final w = best[key]!;
    node.wordId = id;
    node.q = quantizeLogProb(w.logProb);
    node.offensive = w.offensive;
  }
  final trie = BytesBuilder(copy: false);
  var rootOffset = 0;
  // Post-order: children first, so parents can store child offsets.
  void emit(_Node node) {
    var bestQ = node.wordId != null ? node.q : 255;
    for (final kid in node.kids) {
      emit(kid);
      if (kid.bestQ < bestQ) bestQ = kid.bestQ;
    }
    node.bestQ = bestQ;
    node.offset = trie.length;
    if (node.kids.length > 255) throw StateError('Too many children');
    final terminal = node.wordId != null;
    trie.addByte((terminal ? kNodeTerminal : 0) | (node.offensive ? kNodeOffensive : 0));
    trie.addByte(node.kids.length);
    trie.addByte(bestQ);
    if (terminal) {
      _addU24(trie, node.wordId!);
      trie.addByte(node.q);
    }
    for (var i = 0; i < node.kids.length; i++) {
      final c = node.chars[i];
      trie.addByte(c & 0xff);
      trie.addByte((c >> 8) & 0xff);
      _addU24(trie, node.kids[i].offset);
    }
    if (trie.length > 0xffffff) throw StateError('Trie too large');
  }

  emit(root);
  rootOffset = root.offset;

  // 3. Words blob and index.
  final words = BytesBuilder(copy: false);
  final wordIndex = BytesBuilder(copy: false);
  for (var id = 0; id < n; id++) {
    if (id % kWordIndexStride == 0) _addU32(wordIndex, words.length);
    final w = best[keys[id]]!;
    final bytes = utf8.encode(normalizeNfc(w.surface));
    if (bytes.length > 255) throw StateError('Word too long');
    words.addByte(bytes.length);
    words.addByte(quantizeLogProb(w.logProb));
    words.addByte(w.offensive ? 1 : 0);
    words.add(bytes);
  }
  _addU32(wordIndex, words.length);

  // 4. Bigrams.
  final perWord = List<List<(int, int)>>.generate(n, (_) => <(int, int)>[]);
  var bigramCount = 0;
  for (final b in source.bigrams) {
    final p = idOf[foldKey(b.previous, stripAccents: source.foldAccents)];
    final x = idOf[foldKey(b.next, stripAccents: source.foldAccents)];
    if (p == null || x == null || p == x) continue;
    final list = perWord[p];
    if (list.any((e) => e.$1 == x)) continue;
    if (list.length >= 255) continue;
    list.add((x, quantizeLogProb(b.logProb)));
    bigramCount++;
  }
  final bigramCounts = Uint8List(n);
  final bigramData = BytesBuilder(copy: false);
  for (var id = 0; id < n; id++) {
    final list = perWord[id]..sort((a, b) => a.$1.compareTo(b.$1));
    bigramCounts[id] = list.length;
    for (final e in list) {
      _addU24(bigramData, e.$1);
      bigramData.addByte(e.$2);
    }
  }

  // 5. Corrections.
  final corr = StringBuffer();
  for (final e in source.corrections.entries) {
    corr
      ..write(e.key)
      ..write('\t')
      ..write(e.value)
      ..write('\n');
  }
  final corrBytes = utf8.encode(corr.toString());

  // 6. Header + assemble.
  final lang = ascii.encode(source.language);
  final trieBytes = trie.takeBytes();
  final wordBytes = words.takeBytes();
  final indexBytes = wordIndex.takeBytes();
  final bigramDataBytes = bigramData.takeBytes();
  final out = BytesBuilder(copy: false);
  out.add(ascii.encode(kMdictMagicRaw));
  out.addByte(kMdictVersion);
  out.addByte(source.foldAccents ? 1 : 0);
  out.addByte(0);
  out.addByte(0);
  _addU32(out, n);
  _addU32(out, trieBytes.length);
  _addU32(out, rootOffset);
  _addU32(out, wordBytes.length);
  _addU32(out, bigramCount);
  _addU32(out, bigramDataBytes.length);
  _addU32(out, corrBytes.length);
  out.addByte(lang.length);
  out.add(lang);
  out.add(trieBytes);
  out.add(wordBytes);
  out.add(indexBytes);
  out.add(bigramCounts);
  out.add(bigramDataBytes);
  out.add(corrBytes);
  final payload = out.takeBytes();
  if (!compress) return payload;
  final packed = ZLibCodec(level: 9).encode(payload);
  final result = BytesBuilder(copy: false)
    ..add(ascii.encode(kMdictMagicZlib))
    ..add(packed);
  return result.takeBytes();
}

void _addU24(BytesBuilder b, int v) {
  b
    ..addByte(v & 0xff)
    ..addByte((v >> 8) & 0xff)
    ..addByte((v >> 16) & 0xff);
}

void _addU32(BytesBuilder b, int v) {
  b
    ..addByte(v & 0xff)
    ..addByte((v >> 8) & 0xff)
    ..addByte((v >> 16) & 0xff)
    ..addByte((v >> 24) & 0xff);
}
