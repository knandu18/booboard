// SPDX-License-Identifier: GPL-3.0-or-later
//
// OWNER: Wave 4-A. The loaded Chinese pack: the dictionary, the OpenCC converter and the pack's
// identity. The composer reads it; it notifies when a load finishes (the composer's `changes`).
import 'dart:io';

import 'package:flutter/foundation.dart';

import 's2twp.dart';
import 'zh_dictionary.dart';

/// Identity of the installed dictionary pack, for the settings screen.
@immutable
class ZhPackInfo {
  const ZhPackInfo({required this.id, required this.name, required this.sizeBytes});

  final String id;
  final String name;
  final int sizeBytes;
}

/// Everything read from the pack folder. Sendable, so it can come back from an isolate.
@immutable
class ZhLoaded {
  const ZhLoaded({required this.dictionary, required this.converter, required this.pack});

  final ZhDictionary dictionary;
  final S2twpConverter converter;
  final ZhPackInfo pack;
}

/// Reads `zh.kdict` and `s2twp.tsv` from a pack folder. Throws on a missing or invalid file. Call it off
/// the UI isolate (Isolate.run); it reads the whole index into memory.
ZhLoaded readZhPackFiles(String dirPath, ZhPackInfo pack) {
  final dict = ZhDictionary.fromBytes(_readBytes('$dirPath/zh.kdict'));
  final tsv = File('$dirPath/s2twp.tsv').readAsStringSync();
  return ZhLoaded(dictionary: dict, converter: S2twpConverter.parse(tsv), pack: pack);
}

Uint8List _readBytes(String path) => File(path).readAsBytesSync();

/// The Chinese dictionary the composer uses. Null members until a pack has loaded.
class ZhLexicon extends ChangeNotifier {
  ZhDictionary? _dictionary;
  S2twpConverter? _converter;
  ZhPackInfo? _pack;
  bool _loading = false;

  ZhDictionary? get dictionary => _dictionary;
  S2twpConverter? get converter => _converter;
  ZhPackInfo? get pack => _pack;

  /// True while a pack is being read.
  bool get loading => _loading;

  bool get isLoaded => _dictionary != null;

  void setLoading(bool value) {
    if (_loading == value) return;
    _loading = value;
    notifyListeners();
  }

  /// Installs a loaded pack and tells the composer.
  void install(ZhLoaded loaded) {
    _dictionary = loaded.dictionary;
    _converter = loaded.converter;
    _pack = loaded.pack;
    _loading = false;
    notifyListeners();
  }

  /// Forgets the pack (it was deleted, or another one replaced it).
  void clear() {
    if (_dictionary == null && _pack == null && !_loading) return;
    _dictionary = null;
    _converter = null;
    _pack = null;
    _loading = false;
    notifyListeners();
  }
}
