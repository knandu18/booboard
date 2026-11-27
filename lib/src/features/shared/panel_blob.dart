// SPDX-License-Identifier: GPL-3.0-or-later
//
// OWNER: Wave 2-D. Reads one encrypted blob for a panel and tells "no data yet" from "exists but
// cannot be decrypted right now" (the Keystore key is locked while the phone is locked). SecureBlobStore
// returns null for both, so the owner asks the platform whether the blob is on disk. An owner must not
// write over a locked blob, or it would silently erase the user's data.
import 'dart:typed_data';

import '../../core/secure_blob_store.dart';

typedef BlobExists = Future<bool> Function(String name);

class PanelBlobRead {
  const PanelBlobRead({this.bytes, this.locked = false});

  /// The decrypted bytes, or null when there is nothing to read.
  final Uint8List? bytes;

  /// True when the blob is on disk but cannot be read now.
  final bool locked;
}

class PanelBlob {
  PanelBlob({required this.store, required this.name, this.exists});

  final SecureBlobStore store;
  final String name;

  /// Asks the platform whether the blob is on disk (for example `PlatformHostApi.secureList`). Null
  /// means "assume not": a null read is then treated as no data.
  final BlobExists? exists;

  Future<PanelBlobRead> read() async {
    final bytes = await store.read(name);
    if (bytes != null) return PanelBlobRead(bytes: bytes);
    final probe = exists;
    if (probe == null) return const PanelBlobRead();
    try {
      return PanelBlobRead(locked: await probe(name));
    } on Object {
      return const PanelBlobRead();
    }
  }
}
