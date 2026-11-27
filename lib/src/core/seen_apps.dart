// SPDX-License-Identifier: GPL-3.0-or-later
//
// CONTRACT (orchestrator-owned): the apps BooBoard was used in, so the privacy
// center can offer them in the "always incognito" picker without
// QUERY_ALL_PACKAGES. The keyboard records; the settings app lists and clears.
//
// PRIVACY: package names and labels only (never text), encrypted through
// SecureBlobStore, capped at [SeenAppsStore.maxApps], never recorded while
// incognito, and wiped with the other data.
import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';

import 'data_sections.dart';
import 'log.dart';
import 'secure_blob_store.dart';

@immutable
class SeenApp {
  const SeenApp({required this.packageName, required this.label, required this.lastSeenMs});

  final String packageName;

  /// User-visible app name when the keyboard could read it, else null (show the package name).
  final String? label;
  final int lastSeenMs;

  Map<String, Object?> toJson() => {'p': packageName, 'l': label, 't': lastSeenMs};

  static SeenApp? fromJson(Object? j) {
    if (j is! Map) return null;
    final p = j['p'];
    final t = j['t'];
    if (p is! String || p.isEmpty || p.length > 255 || t is! int) return null;
    final l = j['l'];
    return SeenApp(packageName: p, label: l is String && l.length <= 200 ? l : null, lastSeenMs: t);
  }
}

class SeenAppsStore {
  SeenAppsStore(this._store, {int Function()? clock, this._saveDelay = const Duration(seconds: 5)})
    : _clock = clock ?? (() => DateTime.now().millisecondsSinceEpoch);

  static const int maxApps = 60;

  final SecureBlobStore _store;
  final int Function() _clock;
  final Duration _saveDelay;
  final Map<String, SeenApp> _apps = {};
  bool _loaded = false;
  bool _dirty = false;
  Timer? _saveTimer;

  /// Most recently used first.
  Future<List<SeenApp>> list() async {
    await _ensureLoaded();
    return _apps.values.toList()..sort((a, b) => b.lastSeenMs.compareTo(a.lastSeenMs));
  }

  /// Keyboard side: the user started typing in [packageName]. [labelOf] is asked only for apps
  /// not seen before. Writes are debounced.
  Future<void> record(String packageName, {Future<String?> Function()? labelOf}) async {
    if (packageName.isEmpty) return;
    await _ensureLoaded();
    final old = _apps[packageName];
    String? label = old?.label;
    if (old == null && labelOf != null) {
      try {
        label = await labelOf();
      } on Object catch (e) {
        BooBoardLog.w('SeenApps', 'label lookup failed', e.runtimeType);
      }
    }
    _apps[packageName] = SeenApp(packageName: packageName, label: label, lastSeenMs: _clock());
    if (_apps.length > maxApps) {
      final oldest = _apps.values.reduce((a, b) => a.lastSeenMs <= b.lastSeenMs ? a : b);
      _apps.remove(oldest.packageName);
    }
    _dirty = true;
    _saveTimer ??= Timer(_saveDelay, () => unawaited(flush()));
  }

  Future<void> remove(String packageName) async {
    await _ensureLoaded();
    if (_apps.remove(packageName) != null) {
      _dirty = true;
      await flush();
    }
  }

  Future<void> clear() async {
    _saveTimer?.cancel();
    _saveTimer = null;
    _apps.clear();
    _loaded = true;
    _dirty = false;
    await _store.delete(DataBlobs.seenApps);
  }

  /// Drop the in-memory copy (after [DataSections.seenApps] from the other engine).
  void invalidate() {
    _saveTimer?.cancel();
    _saveTimer = null;
    _apps.clear();
    _loaded = false;
    _dirty = false;
  }

  Future<void> flush() async {
    _saveTimer?.cancel();
    _saveTimer = null;
    if (!_dirty) return;
    _dirty = false;
    try {
      final json = jsonEncode([for (final a in _apps.values) a.toJson()]);
      await _store.write(DataBlobs.seenApps, Uint8List.fromList(utf8.encode(json)));
    } on Object catch (e) {
      _dirty = true;
      BooBoardLog.w('SeenApps', 'save failed', e.runtimeType);
    }
  }

  Future<void> _ensureLoaded() async {
    if (_loaded) return;
    _loaded = true;
    try {
      final bytes = await _store.read(DataBlobs.seenApps);
      if (bytes == null) return;
      final decoded = jsonDecode(utf8.decode(bytes));
      if (decoded is! List) return;
      for (final j in decoded.take(maxApps)) {
        final a = SeenApp.fromJson(j);
        if (a != null) _apps[a.packageName] = a;
      }
    } on Object catch (e) {
      BooBoardLog.w('SeenApps', 'load failed', e.runtimeType);
    }
  }
}
