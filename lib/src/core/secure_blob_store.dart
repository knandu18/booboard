// SPDX-License-Identifier: GPL-3.0-or-later
//
// CONTRACT (Wave 0). Encrypted storage for anything derived from typing:
// learned words, n-grams, clipboard history, personal shortcuts.
import 'dart:typed_data';

import 'package:flutter/services.dart' show PlatformException;

import '../bridge/messages.g.dart';

abstract interface class SecureBlobStore {
  /// Returns null when missing, or when it cannot be decrypted (for example
  /// while the phone is locked). Callers must treat null as "no data yet".
  Future<Uint8List?> read(String name);

  Future<void> write(String name, Uint8List data);
  Future<void> delete(String name);

  /// Deletes every blob and destroys the encryption key.
  Future<void> wipeAll();
}

/// Thrown by [StrictSecureBlobRead.readStrict] while the phone is locked (the key cannot be used).
class SecureStoreLockedException implements Exception {
  const SecureStoreLockedException();

  @override
  String toString() => 'SecureStoreLockedException';
}

/// A read that tells a locked phone apart from missing or damaged data (SEC-06). Only the backup restore
/// needs it: everywhere else "no data yet" is the right answer for all three.
abstract interface class StrictSecureBlobRead {
  /// Null when the blob is missing or damaged; throws [SecureStoreLockedException] while the phone is locked.
  Future<Uint8List?> readStrict(String name);
}

/// AES-256-GCM via the Android Keystore (Kotlin SecureStore).
class PlatformSecureBlobStore implements SecureBlobStore, StrictSecureBlobRead {
  PlatformSecureBlobStore(this._api);

  final PlatformHostApi _api;

  @override
  Future<Uint8List?> read(String name) async {
    try {
      return await _api.secureRead(name);
    } on Object {
      return null;
    }
  }

  @override
  Future<Uint8List?> readStrict(String name) async {
    try {
      return await _api.secureReadStrict(name);
    } on PlatformException catch (e) {
      if (e.code == _lockedCode) throw const SecureStoreLockedException();
      rethrow;
    }
  }

  static const String _lockedCode = 'secure_store_locked';

  @override
  Future<void> write(String name, Uint8List data) => _api.secureWrite(name, data);

  @override
  Future<void> delete(String name) => _api.secureDelete(name);

  @override
  Future<void> wipeAll() => _api.secureWipeAll();
}

/// For tests and previews.
class InMemorySecureBlobStore implements SecureBlobStore, StrictSecureBlobRead {
  final Map<String, Uint8List> _blobs = {};

  @override
  Future<Uint8List?> read(String name) async => _blobs[name];

  @override
  Future<Uint8List?> readStrict(String name) async => _blobs[name];

  @override
  Future<void> write(String name, Uint8List data) async => _blobs[name] = Uint8List.fromList(data);

  @override
  Future<void> delete(String name) async => _blobs.remove(name);

  @override
  Future<void> wipeAll() async => _blobs.clear();
}
