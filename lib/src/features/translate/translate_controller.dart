// SPDX-License-Identifier: GPL-3.0-or-later
//
// OWNER: Wave 3-T. The translate panel's state: the source text the keyboard types, the translation
// (debounced, about 300 ms after the last key), and Insert. Pure Dart: the bridge and the input are
// injected, so the logic is tested without a device.
//
// PRIVACY: the source and the translation live in memory only. Neither is logged, stored, learned or
// put in the clipboard history; Insert commits the translation through insertText, which does not learn.
import 'dart:async';

import 'package:characters/characters.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show PlatformException;

enum TranslateStatus {
  /// Nothing typed.
  idle,

  /// Typed; the translation is due (progress dot).
  waiting,

  /// The translation is ready to insert.
  ready,

  /// No installed pack covers the pair.
  noPack,

  /// The engine failed; nothing is shown and nothing is inserted.
  failed,
}

typedef TranslateCall = Future<String> Function(String text, String from, String to);

class TranslateController extends ChangeNotifier {
  TranslateController({
    required this.translate,
    required this.insert,
    required this.from,
    required this.to,
    this.debounce = const Duration(milliseconds: 300),
  });

  /// Calls the engine (`ImeHostApi.translate`).
  final TranslateCall translate;

  /// Commits text into the app (`InputController.insertText`).
  final void Function(String text) insert;

  /// BooBoard language ids of the pair being translated.
  final String from;
  final String to;

  final Duration debounce;

  String _source = '';
  String? _translation;
  TranslateStatus _status = TranslateStatus.idle;
  Timer? _timer;
  int _generation = 0;
  bool _disposed = false;

  String get source => _source;
  String? get translation => _translation;
  TranslateStatus get status => _status;

  /// True when Insert has something to commit.
  bool get canInsert => _status == TranslateStatus.ready && (_translation ?? '').isNotEmpty;

  /// Replaces the source text and schedules a translation.
  void setSource(String text) {
    if (_disposed || text == _source) return;
    _source = text;
    _generation++;
    _timer?.cancel();
    if (text.trim().isEmpty) {
      _translation = null;
      _status = TranslateStatus.idle;
    } else {
      _status = TranslateStatus.waiting;
      _timer = Timer(debounce, _run);
    }
    notifyListeners();
  }

  void append(String text) => setSource(_source + text);

  void backspace() {
    if (_source.isEmpty) return;
    setSource(_source.characters.skipLast(1).string);
  }

  /// Commits the translation, then clears the source box. Returns false when there was nothing to insert.
  bool insertTranslation() {
    if (!canInsert) return false;
    final text = _translation!;
    _timer?.cancel();
    _generation++;
    _source = '';
    _translation = null;
    _status = TranslateStatus.idle;
    insert(text);
    notifyListeners();
    return true;
  }

  /// Empties the source box without inserting anything (the live translation was already kept in the app).
  void clear() {
    if (_disposed) return;
    _timer?.cancel();
    _generation++;
    _source = '';
    _translation = null;
    _status = TranslateStatus.idle;
    notifyListeners();
  }

  Future<void> _run() async {
    final generation = _generation;
    final text = _source;
    try {
      final out = await translate(text, from, to);
      if (_disposed || generation != _generation) return;
      _translation = out;
      _status = out.trim().isEmpty ? TranslateStatus.failed : TranslateStatus.ready;
    } on PlatformException catch (e) {
      if (_disposed || generation != _generation) return;
      _translation = null;
      _status = e.code == 'no_pack' ? TranslateStatus.noPack : TranslateStatus.failed;
    } on Object {
      if (_disposed || generation != _generation) return;
      _translation = null;
      _status = TranslateStatus.failed;
    }
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _timer?.cancel();
    super.dispose();
  }
}
