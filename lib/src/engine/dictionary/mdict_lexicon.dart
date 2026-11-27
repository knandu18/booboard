// SPDX-License-Identifier: GPL-3.0-or-later
// ignore_for_file: prefer_initializing_formals
//
// Runtime reader for the MDICT format (see mdict_format.dart). The whole
// dictionary lives in a few typed-data views over one buffer; there is no
// per-word object. All lookups are allocation-free except those that return
// strings.
import 'dart:convert';
import 'dart:io' show ZLibDecoder;
import 'dart:math' as math;
import 'dart:typed_data';

import '../contracts.dart';
import 'mdict_format.dart';
import 'mdict_writer.dart';
import 'text_fold.dart';

/// The most an `MDZ1` payload may inflate to. The largest bundled dictionary is a few MB; the cap only stops
/// a corrupt or hostile file from filling memory (SEC-10).
const int _maxInflatedBytes = 64 * 1024 * 1024;

/// A sink that collects inflated chunks and refuses to hold more than [_maxInflatedBytes].
class _CappedSink implements Sink<List<int>> {
  final BytesBuilder _out = BytesBuilder(copy: false);

  @override
  void add(List<int> data) {
    if (_out.length + data.length > _maxInflatedBytes) {
      throw const FormatException('MDICT payload inflates to more than the allowed size');
    }
    _out.add(data);
  }

  @override
  void close() {}

  Uint8List takeBytes() => _out.takeBytes();
}

Uint8List _inflate(Uint8List compressed) {
  final sink = _CappedSink();
  final decoder = ZLibDecoder().startChunkedConversion(sink);
  decoder.add(compressed);
  decoder.close();
  return sink.takeBytes();
}

/// Inflates an `MDZ1` file to the raw payload (cheap to run in an isolate).
/// Raw payloads are returned unchanged.
Uint8List inflateMdict(Uint8List bytes) {
  if (bytes.length < 4 || ascii.decode(bytes.sublist(0, 4), allowInvalid: true) != kMdictMagicZlib) return bytes;
  return _inflate(Uint8List.sublistView(bytes, 4));
}

class MdictLexicon implements Lexicon {
  MdictLexicon._({
    required this.language,
    required this.foldsAccents,
    required this.size,
    required Uint8List trie,
    required int rootNode,
    required Uint8List words,
    required Uint8List wordIndex,
    required Uint8List bigramCounts,
    required Uint8List bigramData,
    required this.bigramCount,
    required this.corrections,
  }) : _trie = trie,
       _root = rootNode,
       _words = words,
       _wordIndex = wordIndex,
       _bigramCounts = bigramCounts,
       _bigramData = bigramData {
    // Prefix sums of bigram counts: 4 bytes per word, built once.
    final starts = Uint32List(size + 1);
    var total = 0;
    for (var i = 0; i < size; i++) {
      starts[i] = total;
      total += bigramCounts[i];
    }
    starts[size] = total;
    _bigramStart = starts;
  }

  /// Parses raw or zlib-compressed MDICT bytes.
  factory MdictLexicon.fromBytes(Uint8List bytes) {
    if (bytes.length < 4) throw const FormatException('Not an MDICT file');
    var data = bytes;
    final magic = ascii.decode(bytes.sublist(0, 4), allowInvalid: true);
    if (magic == kMdictMagicZlib) {
      data = _inflate(Uint8List.sublistView(bytes, 4));
    } else if (magic != kMdictMagicRaw) {
      throw const FormatException('Not an MDICT file');
    }
    // The fixed header is 37 bytes plus the language code; every section is checked against the file length.
    if (data.length < 37) throw const FormatException('MDICT file is truncated');
    final version = data[4];
    if (version != kMdictVersion) throw FormatException('Unsupported MDICT version $version');
    final flags = data[5];
    final n = readU32(data, 8);
    final trieLen = readU32(data, 12);
    final rootOffset = readU32(data, 16);
    final wordsLen = readU32(data, 20);
    final bigramCount = readU32(data, 24);
    final bigramLen = readU32(data, 28);
    final corrLen = readU32(data, 32);
    final langLen = data[36];
    if (37 + langLen > data.length) throw const FormatException('MDICT file is truncated');
    final language = ascii.decode(data.sublist(37, 37 + langLen));
    var pos = 37 + langLen;
    Uint8List take(int len) {
      if (len < 0 || pos + len > data.length) throw const FormatException('MDICT file is truncated');
      final view = Uint8List.sublistView(data, pos, pos + len);
      pos += len;
      return view;
    }

    final trie = take(trieLen);
    final words = take(wordsLen);
    final wordIndex = take(4 * ((n + kWordIndexStride - 1) ~/ kWordIndexStride + 1));
    final bigramCounts = take(n);
    final bigramData = take(bigramLen);
    final corrBytes = take(corrLen);
    final corrections = <String, String>{};
    if (corrLen > 0) {
      for (final line in utf8.decode(corrBytes).split('\n')) {
        final tab = line.indexOf('\t');
        if (tab > 0) corrections[line.substring(0, tab)] = line.substring(tab + 1);
      }
    }
    return MdictLexicon._(
      language: language,
      foldsAccents: flags & 1 != 0,
      size: n,
      trie: trie,
      rootNode: rootOffset,
      words: words,
      wordIndex: wordIndex,
      bigramCounts: bigramCounts,
      bigramData: bigramData,
      bigramCount: bigramCount,
      corrections: Map.unmodifiable(corrections),
    );
  }

  /// Indexes any [Lexicon] (used for lexicons not loaded from an asset).
  /// Bigrams are not available through the [Lexicon] interface, so the result
  /// delegates [bigramLogProb] to [source].
  factory MdictLexicon.fromLexicon(Lexicon source, {Map<String, String> corrections = const {}}) {
    final words = [for (final e in source.entries()) DictWord(e.word, e.logProb, offensive: e.isOffensive)];
    final bytes = buildMdict(DictSource(language: source.language, words: words, corrections: corrections));
    final lexicon = MdictLexicon.fromBytes(bytes);
    lexicon._delegate = source;
    return lexicon;
  }

  @override
  final LanguageId language;

  /// Whether dictionary keys fold accents (café -> cafe).
  final bool foldsAccents;

  @override
  final int size;

  final int bigramCount;

  /// typed (folded) -> replacement, e.g. "dont" -> "don't".
  final Map<String, String> corrections;

  final Uint8List _trie;
  final int _root;
  final Uint8List _words;
  final Uint8List _wordIndex;
  final Uint8List _bigramCounts;
  final Uint8List _bigramData;
  late final Uint32List _bigramStart;
  Lexicon? _delegate;
  Int32List? _freqOrder;

  /// True when bigrams come from another [Lexicon] rather than this file.
  bool get hasDelegate => _delegate != null;

  /// Approximate bytes held by this lexicon.
  int get memoryBytes =>
      _trie.length +
      _words.length +
      _wordIndex.length +
      _bigramCounts.length +
      _bigramData.length +
      _bigramStart.lengthInBytes +
      (_freqOrder?.lengthInBytes ?? 0);

  void trimMemory() => _freqOrder = null;

  // ---------------------------------------------------------------- trie

  int get rootNode => _root;
  bool isTerminal(int node) => _trie[node] & kNodeTerminal != 0;
  bool isOffensiveNode(int node) => _trie[node] & kNodeOffensive != 0;
  int childCount(int node) => _trie[node + 1];

  /// Lowest quantised cost of any word in the subtree (including the node).
  int bestQ(int node) => _trie[node + 2];

  /// Only valid for terminal nodes.
  int wordIdOf(int node) => readU24(_trie, node + 3);
  int qOfNode(int node) => _trie[node + 6];

  int _entriesStart(int node) => node + 3 + (_trie[node] & kNodeTerminal != 0 ? 4 : 0);

  /// Key character of child [index] of [node].
  int childChar(int node, int index) => readU16(_trie, _entriesStart(node) + index * 5);

  /// Node offset of child [index] of [node].
  int childNode(int node, int index) => readU24(_trie, _entriesStart(node) + index * 5 + 2);

  /// The child of [node] for [char], or -1.
  int findChild(int node, int char) {
    final count = _trie[node + 1];
    if (count == 0) return -1;
    final start = _entriesStart(node);
    var lo = 0;
    var hi = count - 1;
    while (lo <= hi) {
      final mid = (lo + hi) >> 1;
      final o = start + mid * 5;
      final c = _trie[o] | (_trie[o + 1] << 8);
      if (c == char) return readU24(_trie, o + 2);
      if (c < char) {
        lo = mid + 1;
      } else {
        hi = mid - 1;
      }
    }
    return -1;
  }

  /// Node for a folded key, or -1.
  int nodeForKey(String foldedKey) {
    var node = _root;
    for (var i = 0; i < foldedKey.length; i++) {
      node = findChild(node, foldedKey.codeUnitAt(i));
      if (node < 0) return -1;
    }
    return node;
  }

  /// Folds [word] the way this dictionary's keys are folded.
  String fold(String word) => foldKey(word, stripAccents: foldsAccents);

  /// Word id for [word] (any case/accents), or -1.
  int idOf(String word) {
    final node = nodeForKey(fold(word));
    return node >= 0 && isTerminal(node) ? wordIdOf(node) : -1;
  }

  // --------------------------------------------------------------- words

  int _recordOffset(int id) {
    var o = readU32(_wordIndex, (id ~/ kWordIndexStride) * 4);
    for (var i = id - id % kWordIndexStride; i < id; i++) {
      o += 3 + _words[o];
    }
    return o;
  }

  /// Display spelling of word [id].
  String wordOf(int id) {
    final o = _recordOffset(id);
    return utf8.decode(Uint8List.sublistView(_words, o + 3, o + 3 + _words[o]));
  }

  int qOfId(int id) => _words[_recordOffset(id) + 1];
  bool isOffensiveId(int id) => _words[_recordOffset(id) + 2] & 1 != 0;

  @override
  Iterable<LexiconEntry> entries({int? limit}) sync* {
    final order = _frequencyOrder();
    final count = limit == null ? order.length : math.min(limit, order.length);
    for (var i = 0; i < count; i++) {
      final id = order[i];
      final o = _recordOffset(id);
      yield LexiconEntry(
        utf8.decode(Uint8List.sublistView(_words, o + 3, o + 3 + _words[o])),
        dequantize(_words[o + 1]),
        isOffensive: _words[o + 2] & 1 != 0,
      );
    }
  }

  Int32List _frequencyOrder() {
    final cached = _freqOrder;
    if (cached != null) return cached;
    // Counting sort by q (stable by id).
    final qs = Uint8List(size);
    final counts = Int32List(kQMax + 2);
    var o = 0;
    for (var id = 0; id < size; id++) {
      final q = _words[o + 1];
      qs[id] = q;
      counts[q + 1]++;
      o += 3 + _words[o];
    }
    for (var i = 1; i < counts.length; i++) {
      counts[i] += counts[i - 1];
    }
    final order = Int32List(size);
    for (var id = 0; id < size; id++) {
      order[counts[qs[id]]++] = id;
    }
    return _freqOrder = order;
  }

  @override
  double? logProb(String word) {
    final node = nodeForKey(fold(word));
    if (node < 0 || !isTerminal(node)) return null;
    return dequantize(qOfNode(node));
  }

  // ------------------------------------------------------------- bigrams

  /// Successors of word [id] as (successorId, logProb) pairs.
  Iterable<(int, double)> successors(int id) sync* {
    if (id < 0 || id >= size) return;
    final start = _bigramStart[id];
    final end = _bigramStart[id + 1];
    for (var i = start; i < end; i++) {
      final o = i * 4;
      yield (readU24(_bigramData, o), dequantize(_bigramData[o + 3]));
    }
  }

  int successorCount(int id) => id < 0 || id >= size ? 0 : _bigramCounts[id];

  /// P(next | previous) if the pair is in the dictionary, else null.
  double? bigramBetween(int previousId, int nextId) {
    if (previousId < 0 || previousId >= size || nextId < 0) return null;
    var lo = _bigramStart[previousId];
    var hi = _bigramStart[previousId + 1] - 1;
    while (lo <= hi) {
      final mid = (lo + hi) >> 1;
      final o = mid * 4;
      final id = readU24(_bigramData, o);
      if (id == nextId) return dequantize(_bigramData[o + 3]);
      if (id < nextId) {
        lo = mid + 1;
      } else {
        hi = mid - 1;
      }
    }
    return null;
  }

  @override
  double bigramLogProb(String previous, String word) {
    final delegate = _delegate;
    if (delegate != null) return delegate.bigramLogProb(previous, word);
    final unigram = logProb(word) ?? -20;
    final p = idOf(previous);
    final x = idOf(word);
    if (p >= 0 && x >= 0) {
      final hit = bigramBetween(p, x);
      if (hit != null) return hit;
    }
    return unigram + _kBackoff;
  }

  /// Stupid-backoff factor 0.4.
  static final double _kBackoff = math.log(0.4);
}
