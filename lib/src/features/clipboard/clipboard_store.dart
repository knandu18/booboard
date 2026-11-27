// SPDX-License-Identifier: GPL-3.0-or-later
//
// OWNER: Wave 2-D. Clipboard history in DataBlobs.clipboard: text only, at most `maxItems` items,
// unpinned items expire after `expiryMinutes`, pinned items never do.
//
// PRIVACY: nothing is recorded while incognito or for sensitive clips (that is decided by the caller,
// see ClipboardController). Items are encrypted through SecureBlobStore. A locked blob is never written,
// so a locked phone cannot wipe the user's history.
import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import '../../core/data_sections.dart';
import '../../core/log.dart';
import '../../core/secure_blob_store.dart';
import '../../settings/sections/clipboard_settings.dart';
import '../shared/panel_blob.dart';

class ClipItem {
  const ClipItem({required this.id, required this.text, required this.time, this.pinned = false});

  final String id;
  final String text;

  /// Copy time, milliseconds since the epoch.
  final int time;
  final bool pinned;

  ClipItem withPinned(bool value) => ClipItem(id: id, text: text, time: time, pinned: value);
}

class ClipboardStore {
  ClipboardStore({
    required SecureBlobStore blobs,
    required this.settings,
    BlobExists? exists,
    int Function()? clock,
    this.saveDelay = const Duration(seconds: 2),
  }) : _blob = PanelBlob(store: blobs, name: DataBlobs.clipboard, exists: exists),
       _clock = clock ?? (() => DateTime.now().millisecondsSinceEpoch);

  /// Longest clip kept (Kotlin already caps the clip at this size).
  static const int maxTextLength = 20000;

  final PanelBlob _blob;
  final ClipboardSettings Function() settings;
  final int Function() _clock;
  final Duration saveDelay;

  /// Newest first.
  List<ClipItem> _items = [];
  int _sequence = 0;
  bool _loaded = false;
  bool _locked = false;
  bool _dirty = false;
  Timer? _saveTimer;
  Future<void>? _loading;

  /// Items, newest first.
  List<ClipItem> get items => List.unmodifiable(_items);

  /// True when the history exists but cannot be read now (the phone is locked). Nothing is written then.
  bool get locked => _locked;

  /// Reads the history once (again when [force], or after a locked read). Expired items are dropped.
  Future<void> load({bool force = false}) {
    if (_loading != null) return _loading!;
    if (_loaded && !force && !_locked) return Future.value();
    return _loading = _load().whenComplete(() => _loading = null);
  }

  Future<void> _load() async {
    try {
      final read = await _blob.read();
      _locked = read.locked;
      final bytes = read.bytes;
      _items = bytes == null ? [] : _decode(bytes);
      _loaded = !_locked;
      prune();
    } on Object catch (e) {
      BooBoardLog.w('Clipboard', 'history unreadable', e.runtimeType);
    }
  }

  List<ClipItem> _decode(Uint8List bytes) {
    try {
      final j = jsonDecode(utf8.decode(bytes)) as Map<String, Object?>;
      final out = <ClipItem>[];
      for (final row in (j['items'] as List<Object?>? ?? const [])) {
        final m = row! as Map<String, Object?>;
        final text = m['text'];
        final id = m['id'];
        final time = m['time'];
        if (text is! String || id is! String || time is! num || text.isEmpty) continue;
        if (text.length > maxTextLength) continue;
        out.add(ClipItem(id: id, text: text, time: time.toInt(), pinned: m['pinned'] == true));
      }
      return out;
    } on Object catch (e) {
      BooBoardLog.w('Clipboard', 'history discarded', e.runtimeType);
      return [];
    }
  }

  /// The settings app or the privacy center changed the history: read it again.
  void reload() {
    _saveTimer?.cancel();
    _saveTimer = null;
    _dirty = false;
    _loaded = false;
    unawaited(load(force: true));
  }

  /// Drops unpinned items older than the expiry. Returns how many went. Called on load and whenever the panel opens.
  int prune([int? now]) {
    final cutoff = (now ?? _clock()) - settings().expiryMinutes * 60000;
    final before = _items.length;
    _items = [
      for (final i in _items)
        if (i.pinned || i.time >= cutoff) i,
    ];
    final removed = before - _items.length;
    if (removed > 0) _scheduleSave();
    return removed;
  }

  /// Adds a copied text. A copy of something already in the history moves it to the top. When full,
  /// the oldest unpinned item makes room. Returns false when nothing was stored (locked, empty, too long,
  /// or the history is full of pinned items).
  bool add(String text) {
    if (_locked || text.isEmpty || text.length > maxTextLength) return false;
    final now = _clock();
    final existing = _items.indexWhere((i) => i.text == text);
    if (existing >= 0) {
      final old = _items.removeAt(existing);
      _items.insert(0, ClipItem(id: old.id, text: text, time: now, pinned: old.pinned));
    } else {
      final max = settings().maxItems;
      while (_items.length >= max) {
        final oldest = _items.lastIndexWhere((i) => !i.pinned);
        if (oldest < 0) return false;
        _items.removeAt(oldest);
      }
      _items.insert(0, ClipItem(id: '$now-${_sequence++}', text: text, time: now));
    }
    _scheduleSave();
    return true;
  }

  void setPinned(String id, bool pinned) {
    final i = _items.indexWhere((e) => e.id == id);
    if (i < 0 || _items[i].pinned == pinned) return;
    _items[i] = _items[i].withPinned(pinned);
    _scheduleSave();
  }

  void delete(String id) {
    final before = _items.length;
    _items.removeWhere((e) => e.id == id);
    if (_items.length != before) _scheduleSave();
  }

  /// "Clear all": removes every unpinned item and keeps the pinned ones.
  void clearUnpinned() {
    final before = _items.length;
    _items.removeWhere((e) => !e.pinned);
    if (_items.length != before) _scheduleSave();
  }

  void _scheduleSave() {
    _dirty = true;
    _saveTimer ??= Timer(saveDelay, () => unawaited(flush()));
  }

  /// Writes pending changes. Skipped while the blob is locked. Callers guard incognito for new recordings.
  Future<void> flush() async {
    _saveTimer?.cancel();
    _saveTimer = null;
    if (!_dirty || _locked) return;
    _dirty = false;
    final json = jsonEncode({
      'v': 1,
      'items': [
        for (final i in _items) {'id': i.id, 'text': i.text, 'time': i.time, 'pinned': i.pinned},
      ],
    });
    try {
      await _blob.store.write(DataBlobs.clipboard, Uint8List.fromList(utf8.encode(json)));
    } on Object catch (e) {
      _dirty = true;
      BooBoardLog.w('Clipboard', 'save failed', e.runtimeType);
    }
  }

  void dispose() => unawaited(flush());
}
