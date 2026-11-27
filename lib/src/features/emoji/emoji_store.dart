// SPDX-License-Identifier: GPL-3.0-or-later
//
// OWNER: Wave 2-D. Emoji recents, skin-tone choices and the glyph cache, kept in DataBlobs.emoji.
//
// PRIVACY: only emoji and numbers are stored, encrypted through SecureBlobStore. Nothing is recorded
// or written while the keyboard is incognito. A blob that is locked is never overwritten.
import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';

import '../../core/data_sections.dart';
import '../../core/log.dart';
import '../../core/secure_blob_store.dart';
import '../shared/panel_blob.dart';
import 'emoji_data.dart';

/// The ref to show for catalogue item [item]: its remembered skin tone when Unicode has that tone,
/// otherwise the base emoji.
int displayRef(EmojiData data, EmojiStore store, int item) {
  final base = data.items[item].text;
  final ref = item * refStride + store.toneFor(base);
  return data.hasRef(ref) ? ref : item * refStride;
}

class EmojiStore {
  EmojiStore({
    required SecureBlobStore blobs,
    required this.learningOff,
    BlobExists? exists,
    int Function()? clock,
    this.saveDelay = const Duration(seconds: 2),
  }) : _blob = PanelBlob(store: blobs, name: DataBlobs.emoji, exists: exists),
       _clock = clock ?? (() => DateTime.now().millisecondsSinceEpoch);

  /// Recents shown, at most.
  static const int maxRecents = 32;

  /// A use counts half as much after this long.
  static const double halfLifeMs = 7 * 24 * 3600 * 1000.0;

  final PanelBlob _blob;

  /// True when nothing may be learned here (incognito, the learning switch, or a private field).
  final bool Function() learningOff;
  final int Function() _clock;
  final Duration saveDelay;

  final List<_Recent> _recents = [];
  final Map<String, int> _tones = {};
  int _lastTone = 0;

  /// Key of the device and app the glyph cache was made for: `<sdkInt>|<versionName>`.
  String _glyphKey = '';
  Set<String> _hidden = const {};

  bool _loaded = false;
  Future<void>? _loading;
  bool _locked = false;
  bool _dirty = false;
  Timer? _saveTimer;
  bool _disposed = false;

  /// True when the blob is on disk but cannot be read (the phone is locked). Nothing is written then.
  bool get locked => _locked;

  Future<void> load() => _loaded ? Future.value() : (_loading ??= _load());

  Future<void> _load() async {
    try {
      final read = await _blob.read();
      _locked = read.locked;
      final bytes = read.bytes;
      if (bytes != null) _apply(bytes);
    } on Object catch (e) {
      BooBoardLog.w('Emoji', 'recents unreadable', e.runtimeType);
    } finally {
      _loaded = true;
      _loading = null;
    }
  }

  void _apply(Uint8List bytes) {
    _recents.clear();
    _tones.clear();
    try {
      final j = jsonDecode(utf8.decode(bytes)) as Map<String, Object?>;
      for (final r in (j['r'] as List<Object?>? ?? const [])) {
        final row = r! as List<Object?>;
        _recents.add(_Recent(row[0]! as String, (row[1]! as num).toDouble(), (row[2]! as num).toInt()));
      }
      final tones = j['t'] as Map<String, Object?>? ?? const {};
      for (final e in tones.entries) {
        _tones[e.key] = (e.value! as num).toInt();
      }
      _lastTone = (j['lt'] as num?)?.toInt() ?? 0;
      _glyphKey = j['gk'] as String? ?? '';
      _hidden = {for (final h in (j['h'] as List<Object?>? ?? const [])) h! as String};
    } on Object catch (e) {
      BooBoardLog.w('Emoji', 'recents discarded', e.runtimeType);
      _recents.clear();
      _tones.clear();
      _hidden = const {};
      _glyphKey = '';
    }
  }

  /// The settings app or the privacy center changed the emoji data: read it again on next use.
  void reload() {
    _saveTimer?.cancel();
    _saveTimer = null;
    _dirty = false;
    _loaded = false;
    _loading = null;
    unawaited(load());
  }

  /// Recent emoji, best first: the decayed use count, at most [maxRecents].
  List<String> recents() {
    final now = _clock();
    final ranked = [..._recents]..sort((a, b) => b.decayed(now).compareTo(a.decayed(now)));
    return [for (final r in ranked.take(maxRecents)) r.text];
  }

  /// Counts one use of [text] (the emoji as inserted, with its tone). Ignored while learning is off.
  void recordUse(String text) {
    if (learningOff() || _disposed || text.isEmpty) return;
    final now = _clock();
    final i = _recents.indexWhere((r) => r.text == text);
    if (i >= 0) {
      final r = _recents[i];
      r
        ..score = r.decayed(now) + 1
        ..last = now;
    } else {
      _recents.add(_Recent(text, 1, now));
    }
    if (_recents.length > maxRecents * 2) {
      _recents.sort((a, b) => b.decayed(now).compareTo(a.decayed(now)));
      _recents.removeRange(maxRecents, _recents.length);
    }
    _scheduleSave();
  }

  /// The tone (0 for the base emoji, 1..5) to show for the emoji whose base form is [base].
  /// The choice is remembered per emoji; a new emoji starts with the last choice made.
  int toneFor(String base) => _tones[base] ?? _lastTone;

  /// Remembers [tone] for [base] and makes it the default for emoji not chosen yet. Ignored while learning is off.
  void rememberTone(String base, int tone) {
    if (learningOff() || _disposed) return;
    _tones[base] = tone;
    _lastTone = tone;
    _scheduleSave();
  }

  /// True when the device cannot draw [text] (cached by [glyphKey]).
  bool isHidden(String text) => _hidden.contains(text);

  /// The key the glyph cache was made for, or '' when there is none.
  String get glyphKey => _glyphKey;

  /// Stores which emoji the device cannot draw, for [key]. Kept in memory while incognito.
  void setHidden(String key, Set<String> hidden) {
    if (_disposed) return;
    _glyphKey = key;
    _hidden = hidden;
    _scheduleSave();
  }

  void _scheduleSave() {
    _dirty = true;
    _saveTimer ??= Timer(saveDelay, () => unawaited(flush()));
  }

  /// Writes pending changes. Skipped while incognito and while the blob is locked.
  Future<void> flush() async {
    _saveTimer?.cancel();
    _saveTimer = null;
    if (!_dirty || _locked || learningOff()) return;
    _dirty = false;
    final now = _clock();
    final json = jsonEncode({
      'v': 1,
      'r': [
        for (final r in _recents) [r.text, double.parse(r.decayed(now).toStringAsFixed(3)), r.last],
      ],
      't': _tones,
      'lt': _lastTone,
      'gk': _glyphKey,
      'h': _hidden.toList(),
    });
    try {
      await _blob.store.write(DataBlobs.emoji, Uint8List.fromList(utf8.encode(json)));
    } on Object catch (e) {
      _dirty = true;
      BooBoardLog.w('Emoji', 'save failed', e.runtimeType);
    }
  }

  void dispose() {
    _disposed = true;
    unawaited(flush());
  }
}

class _Recent {
  _Recent(this.text, this.score, this.last);

  final String text;
  double score;
  int last;

  /// The score after decay to [now].
  double decayed(int now) {
    final age = math.max(0, now - last);
    return score * math.pow(0.5, age / EmojiStore.halfLifeMs).toDouble();
  }
}
