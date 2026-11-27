// SPDX-License-Identifier: GPL-3.0-or-later
//
// CONTRACT (Wave 0). All language/emoji/voice data is loaded through here so
// packaging (bundled asset vs. installed pack) can change without code changes.
import 'package:flutter/services.dart';

abstract interface class PackRepository {
  /// [path] is relative to the data root, e.g. 'dict/en.mdict' or 'layouts/qwerty.json'.
  Future<ByteData> load(String path);
  Future<String> loadString(String path);
  Future<bool> exists(String path);
}

/// Reads from the app's bundled assets (`assets/<path>`).
class BundledPackRepository implements PackRepository {
  BundledPackRepository({AssetBundle? bundle}) : _bundle = bundle ?? rootBundle;

  final AssetBundle _bundle;
  static const _root = 'assets/';

  @override
  Future<ByteData> load(String path) => _bundle.load('$_root$path');

  @override
  Future<String> loadString(String path) => _bundle.loadString('$_root$path', cache: false);

  @override
  Future<bool> exists(String path) async {
    try {
      await _bundle.load('$_root$path');
      return true;
    } on Object {
      return false;
    }
  }
}
