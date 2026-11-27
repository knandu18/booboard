// SPDX-License-Identifier: GPL-3.0-or-later
//
// OWNER: Wave 2-D. Loads the bundled emoji data on demand. Reads the assets on the UI isolate (cheap)
// and decodes them in a background isolate (Isolate.run), so the keyboard never waits on a parse.
// The index is cached per language set; a change of enabled languages loads only what is missing.
import 'dart:async';
import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:flutter/services.dart' show rootBundle;

import '../../core/log.dart';
import 'emoji_index.dart';

/// The files are gzip data named `.dat`: Android's asset packager strips a `.gz` suffix (and inflates
/// the file), so `emoji.gz` would not be found by that name in the APK.
const String emojiAssetDir = 'assets/emoji';

/// Reads the raw bytes for [languages]. Injected so tests can read files from disk.
typedef EmojiByteReader = Future<EmojiBytes> Function(List<String> languages);

/// Builds the index from bytes. The app runs it in an isolate; tests run it inline.
typedef EmojiIndexBuilder = Future<EmojiIndex> Function(EmojiBytes bytes, List<String> languages);

class EmojiRepository {
  EmojiRepository({required this.readBytes, required this.build});

  /// The app's repository: rootBundle for the bytes and Isolate.run for the decode.
  factory EmojiRepository.assets() => EmojiRepository(
    readBytes: _readAssets,
    build: (bytes, languages) => Isolate.run(
      () => buildEmojiIndex(
        emojiGz: bytes.emojiGz,
        languages: languages,
        keywordGz: [for (final l in languages) bytes.keywordGz[l]!],
      ),
    ),
  );

  /// A repository that reads [dir] (the assets folder) synchronously, for tests and tools.
  factory EmojiRepository.fromDirectory(String dir) => EmojiRepository(
    readBytes: (languages) async => (
      emojiGz: File('$dir/emoji.dat').readAsBytesSync(),
      keywordGz: {for (final l in languages) l: File('$dir/keywords_$l.dat').readAsBytesSync()},
    ),
    build: (bytes, languages) async => buildEmojiIndex(
      emojiGz: bytes.emojiGz,
      languages: languages,
      keywordGz: [for (final l in languages) bytes.keywordGz[l]!],
    ),
  );

  final EmojiByteReader readBytes;
  final EmojiIndexBuilder build;

  EmojiIndex? _index;
  String _key = '';
  Future<EmojiIndex>? _pending;
  String _pendingKey = '';

  /// The index for the last [ensure] call, or null before it finishes.
  EmojiIndex? get current => _index;

  /// Loads (or reuses) the index for [languages]. Concurrent calls for the same languages share one load.
  Future<EmojiIndex> ensure(List<String> languages) {
    final known = languages.where(_known).toList();
    final wanted = known.isEmpty ? const ['en'] : known;
    final key = wanted.join(',');
    final index = _index;
    if (index != null && key == _key) return Future.value(index);
    if (_pending != null && key == _pendingKey) return _pending!;
    final sw = Stopwatch()..start();
    final future = () async {
      final bytes = await readBytes(wanted);
      final built = await build(bytes, wanted);
      _index = built;
      _key = key;
      BooBoardLog.d('Emoji', 'index for ${wanted.length} languages in ${sw.elapsedMilliseconds} ms');
      return built;
    }();
    _pending = future;
    _pendingKey = key;
    future.whenComplete(() {
      if (identical(_pending, future)) _pending = null;
    }).ignore();
    return future;
  }

  /// Starts a load in the background (for example when a suggestion needs emoji), without waiting.
  void warm(List<String> languages) {
    unawaited(
      ensure(languages)
          .then<void>((_) {}, onError: (Object e) => BooBoardLog.w('Emoji', 'index load failed', e.runtimeType)),
    );
  }

  /// True when the assets have a keyword table for [lang].
  static bool supports(String lang) => _supported.contains(lang);

  static bool _known(String lang) => supports(lang);

  static const Set<String> _supported = {
    'en', 'es', 'fr', 'de', 'pt', 'id', 'hi', 'mr', 'bn', 'ta', 'te', 'ar', 'ur', 'ru', 'uk', 'zh', 'ja', 'fil', //
  };
}

Future<EmojiBytes> _readAssets(List<String> languages) async {
  Future<Uint8List> read(String name) async {
    final data = await rootBundle.load('$emojiAssetDir/$name');
    return data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
  }

  final emoji = await read('emoji.dat');
  final keywords = <String, Uint8List>{};
  for (final lang in languages) {
    keywords[lang] = await read('keywords_$lang.dat');
  }
  return (emojiGz: emoji, keywordGz: keywords);
}
