// SPDX-License-Identifier: GPL-3.0-or-later
//
// GestureDecoder facade: a request/response client for one long-lived
// background isolate that owns the word templates. The UI isolate only packs
// the finger path, sends it and re-ranks a handful of candidates with the
// bigram model.
import 'dart:async';
import 'dart:isolate';
import 'dart:typed_data';

import '../../core/log.dart';
import '../contracts.dart';
import 'gesture_engine.dart';
import 'gesture_isolate.dart';
import 'template_index.dart';

/// How many of a language's most frequent words get a template.
const int kGestureWordsPerLanguage = 60000;

class IsolateGestureDecoder implements GestureDecoder {
  IsolateGestureDecoder({required LexiconSource lexicons, this.tuning = const GestureTuning()}) : _source = lexicons;

  final LexiconSource _source;
  final GestureTuning tuning;

  Isolate? _isolate;
  SendPort? _send;
  ReceivePort? _recv;
  ReceivePort? _errors;
  Future<void>? _starting;
  int _nextId = 0;
  final Map<int, Completer<Object?>> _pending = {};
  bool _disposed = false;

  // What the isolate currently holds.
  String? _baseSig;
  String? _extrasSig;
  List<Lexicon?> _lexicons = const [];

  _PrepareArgs? _lastArgs;
  Future<void> _prepareQueue = Future<void>.value();
  int _preparing = 0;

  // Live preview: latest request wins.
  bool _previewInFlight = false;
  Completer<String?>? _queuedPreview;
  Float64List? _queuedPreviewXy;

  /// Number of templates the isolate reported after the last prepare.
  int templateCount = 0;

  bool get isDisposed => _disposed;

  // -------------------------------------------------------------------------
  // prepare
  // -------------------------------------------------------------------------

  @override
  Future<void> prepare({
    required KeyboardGeometry geometry,
    required List<LanguageId> languages,
    Iterable<LexiconEntry> extraWords = const [],
  }) {
    if (_disposed) return Future<void>.value();
    final args = _PrepareArgs(geometry, List<LanguageId>.of(languages), List<LexiconEntry>.of(extraWords));
    _lastArgs = args;
    return _enqueuePrepare(args);
  }

  Future<void> _enqueuePrepare(_PrepareArgs args) {
    _preparing++;
    final next = _prepareQueue.then((_) => _doPrepare(args)).whenComplete(() => _preparing--);
    _prepareQueue = next.catchError((Object _) {});
    return next.catchError((Object e) {
      BooBoardLog.w('gesture', 'prepare failed', e.runtimeType);
    });
  }

  Future<void> _doPrepare(_PrepareArgs args) async {
    if (_disposed) return;
    final baseSig = '${args.geometry.cacheKey}|${args.languages.join(',')}';
    final extrasSig = '$baseSig|${_hashExtras(args.extras)}';
    if (_send != null && baseSig == _baseSig && extrasSig == _extrasSig) return;
    final sw = Stopwatch()..start();
    await _ensureIsolate();
    if (_disposed || _send == null) return;

    final baseChanged = baseSig != _baseSig || _send == null;
    List<Object?>? keysPacked;
    List<Object?>? basePacked;
    var lexicons = _lexicons;
    if (baseChanged) {
      keysPacked = _packKeys(args.geometry);
      final packed = <Object?>[];
      lexicons = [];
      for (final language in args.languages) {
        final Lexicon lexicon;
        try {
          lexicon = await _source.load(language);
        } catch (e) {
          BooBoardLog.w('gesture', 'no lexicon for a language', e.runtimeType);
          continue;
        }
        final words = <String>[];
        final lps = <double>[];
        var i = 0;
        for (final entry in lexicon.entries(limit: kGestureWordsPerLanguage)) {
          words.add(entry.word);
          lps.add(entry.logProb);
          // Keep the UI isolate responsive while copying a big lexicon.
          if (++i % 8000 == 0) await Future<void>.delayed(Duration.zero);
          if (_disposed) return;
        }
        packed.add(packWordList(lexicons.length, words, Float64List.fromList(lps)));
        lexicons.add(lexicon);
      }
      basePacked = packed;
    }
    final extrasPacked = <Object?>[];
    if (args.extras.isNotEmpty) {
      final words = <String>[];
      final lps = <double>[];
      for (final e in args.extras) {
        if (e.word.isEmpty) continue;
        words.add(e.word);
        lps.add(e.logProb);
      }
      extrasPacked.add(packWordList(-1, words, Float64List.fromList(lps)));
    }
    final result = await _request(GestureMsg.prepare, [keysPacked, basePacked, extrasPacked]);
    if (_disposed) return;
    if (result is int) {
      _baseSig = baseSig;
      _extrasSig = extrasSig;
      _lexicons = lexicons;
      templateCount = result;
      BooBoardLog.d('gesture', 'prepared $result templates in ${sw.elapsedMilliseconds} ms');
    }
  }

  List<Object?> _packKeys(KeyboardGeometry geometry) {
    final chars = <String>[];
    final rects = <double>[];
    geometry.keys.forEach((char, rect) {
      if (!GestureKeys.isLetterKey(char)) return;
      chars.add(char);
      rects
        ..add(rect.left)
        ..add(rect.top)
        ..add(rect.right)
        ..add(rect.bottom);
    });
    return [
      chars,
      TransferableTypedData.fromList([Float64List.fromList(rects)]),
      geometry.keyWidth,
    ];
  }

  static int _hashExtras(List<LexiconEntry> extras) {
    var h = extras.length;
    for (final e in extras) {
      h = Object.hash(h, e.word, e.logProb);
    }
    return h;
  }

  // -------------------------------------------------------------------------
  // decode / preview
  // -------------------------------------------------------------------------

  @override
  Future<List<Suggestion>> decode(GesturePath path, {List<String> previousWords = const [], int maxResults = 6}) async {
    if (_disposed) return const [];
    final xy = _packPath(path);
    final args = _lastArgs;
    if (xy == null || args == null) return const [];
    _dropQueuedPreview();
    // Rebuilds lazily after trimMemory(); returns at once when up to date.
    await _enqueuePrepare(args);
    if (_disposed || _baseSig == null) return const [];
    final want = maxResults.clamp(1, 20);
    final raw = await _request(GestureMsg.decode, [xy, (want * 3).clamp(12, 48)]);
    if (raw is! List<Object?> || raw.isEmpty) return const [];
    return _rerank(raw, previousWords, want);
  }

  List<Suggestion> _rerank(List<Object?> flat, List<String> previousWords, int maxResults) {
    final previous = previousWords.isEmpty ? null : previousWords.last;
    final scored = <(double, Suggestion)>[];
    for (var i = 0; i + 4 < flat.length; i += 5) {
      final word = flat[i]! as String;
      final langIndex = flat[i + 1]! as int;
      final geo = flat[i + 2]! as double;
      final unigram = flat[i + 3]! as double;
      final learned = flat[i + 4]! as bool;
      final lexicon = langIndex >= 0 && langIndex < _lexicons.length ? _lexicons[langIndex] : null;
      var lp = unigram;
      if (previous != null && lexicon != null && !learned) {
        try {
          lp = lexicon.bigramLogProb(previous, word);
        } catch (_) {
          lp = unigram;
        }
      }
      final score = geo + tuning.lambda * lp;
      scored.add((
        score,
        Suggestion(word, kind: SuggestionKind.gesture, score: score, language: lexicon?.language, isLearned: learned),
      ));
    }
    scored.sort((a, b) => b.$1.compareTo(a.$1));
    return [for (final s in scored.take(maxResults)) s.$2];
  }

  @override
  Future<String?> preview(GesturePath partialPath) {
    if (_disposed || _lastArgs == null || (_baseSig == null && _preparing == 0)) return Future<String?>.value();
    final xy = _packPath(partialPath);
    if (xy == null) return Future<String?>.value();
    if (_previewInFlight) {
      _queuedPreview?.complete(null); // superseded
      final completer = Completer<String?>();
      _queuedPreview = completer;
      _queuedPreviewXy = xy;
      return completer.future;
    }
    return _runPreview(xy);
  }

  Future<String?> _runPreview(Float64List xy) async {
    _previewInFlight = true;
    String? word;
    try {
      final result = await _request(GestureMsg.preview, [xy]);
      word = result is String ? result : null;
    } finally {
      _previewInFlight = false;
      final next = _queuedPreview;
      final nextXy = _queuedPreviewXy;
      _queuedPreview = null;
      _queuedPreviewXy = null;
      if (next != null && nextXy != null && !_disposed) {
        unawaited(_runPreview(nextXy).then(next.complete, onError: (Object _) => next.complete(null)));
      } else {
        next?.complete(null);
      }
    }
    return word;
  }

  void _dropQueuedPreview() {
    _queuedPreview?.complete(null);
    _queuedPreview = null;
    _queuedPreviewXy = null;
  }

  Float64List? _packPath(GesturePath path) {
    final points = path.points;
    if (points.length < 2) return null;
    final xy = Float64List(points.length * 2);
    for (var i = 0; i < points.length; i++) {
      xy[i * 2] = points[i].x;
      xy[i * 2 + 1] = points[i].y;
    }
    return xy;
  }

  // -------------------------------------------------------------------------
  // isolate lifecycle
  // -------------------------------------------------------------------------

  Future<void> _ensureIsolate() {
    if (_send != null) return Future<void>.value();
    return _starting ??= _spawn().whenComplete(() => _starting = null);
  }

  Future<void> _spawn() async {
    final recv = ReceivePort();
    final errors = ReceivePort();
    final ready = Completer<SendPort>();
    _recv = recv;
    _errors = errors;
    recv.listen((Object? message) {
      if (message is SendPort) {
        if (!ready.isCompleted) ready.complete(message);
      } else if (message is List<Object?>) {
        _onResponse(message);
      }
    });
    errors.listen((Object? _) {
      // Uncaught error or exit: forget everything; the next prepare respawns.
      if (identical(_errors, errors)) {
        BooBoardLog.w('gesture', 'decoder isolate stopped');
        _stopIsolate();
      }
    });
    try {
      _isolate = await Isolate.spawn(
        gestureIsolateMain,
        GestureIsolateInit(recv.sendPort, tuning),
        onError: errors.sendPort,
        onExit: errors.sendPort,
        debugName: 'booboard-gesture',
      );
      _send = await ready.future.timeout(const Duration(seconds: 10));
    } catch (e) {
      BooBoardLog.w('gesture', 'could not start decoder isolate', e.runtimeType);
      _stopIsolate();
    }
  }

  Future<Object?> _request(int type, List<Object?> payload) {
    final send = _send;
    if (send == null || _disposed) return Future<Object?>.value();
    final id = ++_nextId;
    final completer = Completer<Object?>();
    _pending[id] = completer;
    send.send([type, id, ...payload]);
    return completer.future;
  }

  void _onResponse(List<Object?> message) {
    final id = message[0]! as int;
    final ok = message[1]! as bool;
    final completer = _pending.remove(id);
    if (completer == null) return;
    if (ok) {
      completer.complete(message[2]);
    } else {
      BooBoardLog.w('gesture', 'decoder error ${message[2]}');
      completer.complete(null);
    }
  }

  void _stopIsolate() {
    _isolate?.kill(priority: Isolate.immediate);
    _isolate = null;
    _send = null;
    _recv?.close();
    _recv = null;
    _errors?.close();
    _errors = null;
    _baseSig = null;
    _extrasSig = null;
    _lexicons = const [];
    templateCount = 0;
    final pending = List<Completer<Object?>>.of(_pending.values);
    _pending.clear();
    for (final c in pending) {
      c.complete(null);
    }
    _dropQueuedPreview();
  }

  /// Frees the templates and stops the isolate. The next [decode] rebuilds
  /// them from the last [prepare] arguments.
  @override
  void trimMemory() {
    if (_disposed) return;
    _stopIsolate();
  }

  @override
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    _lastArgs = null;
    _stopIsolate();
  }
}

class _PrepareArgs {
  _PrepareArgs(this.geometry, this.languages, this.extras);

  final KeyboardGeometry geometry;
  final List<LanguageId> languages;
  final List<LexiconEntry> extras;
}
