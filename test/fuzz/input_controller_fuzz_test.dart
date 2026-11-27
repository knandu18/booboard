// SPDX-License-Identifier: GPL-3.0-or-later
//
// Seeded random sequences over InputController (Wave 4-D, QA). Each seed generates 10k operations
// (typing, space, backspace, enter, word delete, cursor moves, user selection changes, field
// changes, suggestion picks, shift, pages, custom keys, learning and incognito toggles, and a fake
// Chinese-style composer being set and cleared). After every operation these invariants must hold:
//
//   1. no exception;
//   2. the editor's selection is inside the text;
//   3. the editor's composing text equals the controller's composing word, and while a composer
//      holds a preedit, equals that preedit;
//   4. nothing is learned when learning is not allowed (password fields, incognito, learning off);
//   5. letters, digits, emoji, combining marks, Indic and Arabic typed with a collapsed selection
//      and no composer are never lost (the text grows by exactly their length).
//
// On a failure the test prints the seed, the failing invariant and a shortest failing sequence it
// can reduce to (chunked delta-debugging over a replay from an empty field). Rerun one seed by
// setting FUZZ_SEED in the environment to reproduce it.
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:booboard/src/core/input_field_info.dart';
import 'package:booboard/src/engine/contracts.dart';
import 'package:booboard/src/keyboard/input/input_controller.dart';
import 'package:booboard/src/keyboard/input/keyboard_page.dart';
import 'package:booboard/src/settings/booboard_settings.dart';

import '../keyboard/support/fakes.dart';
import '../support/fake_editor.dart';

const int kStepsPerSeed = 10000;
const List<int> kSeeds = [1, 2, 3, 4, 5];

/// Text the fuzzer types. Single code points or short clusters.
const List<String> _letters = [
  'a', 'b', 'c', 'e', 'h', 'i', 'n', 'o', 's', 't', 'w', 'x', 'z', //
  'A', 'E', 'I', 'T', 'Q',
];
const List<String> _digits = ['0', '1', '7', '9'];
const List<String> _punct = ['.', ',', '!', '?', "'", '-', '@', '/', '(', ')', ':', '"'];
const List<String> _exotic = [
  '😀', '👍🏽', '🇮🇳', 'é', 'é', 'ñ', // emoji, ZWJ-free emoji, flags, precomposed and combining
  'क', 'ि', 'ं', 'ा', 'ह', // Devanagari, with vowel signs and anusvara
  'ب', 'ة', 'ـ', 'ا', // Arabic letters and tatweel
  '好', '日', 'ß', 'İ', // CJK and case-mapping oddities
];
const List<String> _words = ['hello', 'the', 'teh', 'helo', 'world', 'it\'s', 'नमस्ते', 'مرحبا', '日本語', '😀', 'a', 'I'];
const List<String> _fieldNames = ['plain', 'password', 'url', 'number', 'noSuggestions', 'email', 'forceAscii'];

enum _Kind {
  text,
  space,
  backspace,
  enter,
  deleteWord,
  moveCursor,
  userSelect,
  startInput,
  finishInput,
  pick,
  insertText,
  shift,
  page,
  customKey,
  selectCandidate,
  composerOn,
  composerOff,
  learning,
  incognito,
}

/// One operation with its arguments. Arguments are fixed at generation time (fractions and
/// indexes, not absolute positions) so a sequence replays the same way from an empty field.
@immutable
class _Op {
  const _Op(this.kind, [this.text = '', this.a = 0, this.b = 0]);

  final _Kind kind;
  final String text;
  final double a;
  final double b;

  @override
  String toString() {
    switch (kind) {
      case _Kind.text:
        return 'onText(${_show(text)})';
      case _Kind.insertText:
        return 'insertText(${_show(text)})';
      case _Kind.moveCursor:
        return 'moveCursor(${a.round()})';
      case _Kind.userSelect:
        return 'userSelect(${a.toStringAsFixed(2)}, ${b.toStringAsFixed(2)})';
      case _Kind.startInput:
        return 'startInput($text, restart ${a < 0.5})';
      case _Kind.pick:
        return 'pick(${_show(text)}, kind ${a.round()})';
      case _Kind.customKey:
        return 'customKey($text)';
      case _Kind.selectCandidate:
        return 'selectCandidate(${a.round()})';
      case _Kind.learning:
        return 'learning(${a > 0.5})';
      case _Kind.incognito:
        return 'incognito(${a > 0.5})';
      case _Kind.page:
        return 'page(${a.round()})';
      case _Kind.shift:
      case _Kind.space:
      case _Kind.backspace:
      case _Kind.enter:
      case _Kind.deleteWord:
      case _Kind.finishInput:
      case _Kind.composerOn:
      case _Kind.composerOff:
        return '${kind.name}()';
    }
  }
}

/// A small composer: letters build a buffer, space commits the first candidate, enter commits the
/// letters. Its only job is to exercise the composer routing in the controller.
class _FuzzComposer extends TextComposer {
  String _buffer = '';

  @override
  ComposerState get state => _buffer.isEmpty
      ? ComposerState.empty
      : ComposerState(
          preedit: _buffer,
          candidates: [ComposerCandidate('${_buffer}X', consumes: _buffer.length)],
          highlighted: 0,
        );

  @override
  ComposerStep onText(String text) {
    if (RegExp('^[a-z]\$').hasMatch(text)) {
      _buffer += text;
      return ComposerStep.consumed;
    }
    final out = '$_buffer$text';
    _buffer = '';
    return ComposerStep(commit: out);
  }

  @override
  ComposerStep onSpace() {
    if (_buffer.isEmpty) return ComposerStep.notHandled;
    return selectCandidate(0);
  }

  @override
  ComposerStep onEnter() {
    if (_buffer.isEmpty) return ComposerStep.notHandled;
    final raw = _buffer;
    _buffer = '';
    return ComposerStep(commit: raw);
  }

  @override
  ComposerStep onBackspace() {
    if (_buffer.isEmpty) return ComposerStep.notHandled;
    _buffer = _buffer.substring(0, _buffer.length - 1);
    return ComposerStep.consumed;
  }

  @override
  ComposerStep onCustomKey(String code) => _buffer.isEmpty ? ComposerStep.notHandled : ComposerStep.consumed;

  @override
  ComposerStep selectCandidate(int index) {
    if (_buffer.isEmpty) return ComposerStep.notHandled;
    final text = '${_buffer}X';
    _buffer = '';
    return ComposerStep(commit: text);
  }

  @override
  void reset() => _buffer = '';
}

/// Everything one run needs. A fresh world is built for every replay.
class _World {
  _World() {
    editor = FakeEditor();
    predictor = FakePredictor(
      completions: const {
        'he': ['hello', 'help'],
      },
    );
    controller = InputController(
      input: editor,
      predictor: predictor,
      gestureDecoder: FakeGestureDecoder(),
      settings: () => settings,
      clock: () => now,
    );
    editor.onSelectionChanged = controller.onSelectionChanged;
  }

  late final FakeEditor editor;
  late final FakePredictor predictor;
  late final InputController controller;
  BooBoardSettings settings = const BooBoardSettings();

  /// Fake milliseconds. Frozen during an operation (so the controller's own edits count as echoes)
  /// and advanced between operations.
  int now = 0;
  bool learning = true;
  bool incognito = false;
  String fieldName = 'plain';

  InputFieldInfo fieldFor(String name) {
    switch (name) {
      case 'password':
        return const InputFieldInfo(
          inputType: AndroidInputType.classText | AndroidInputType.textVariationPassword,
          imeOptions: 0,
        );
      case 'url':
        return const InputFieldInfo(
          inputType: AndroidInputType.classText | AndroidInputType.textVariationUri,
          imeOptions: 0,
        );
      case 'number':
        return const InputFieldInfo(inputType: AndroidInputType.classNumber, imeOptions: 0);
      case 'noSuggestions':
        return const InputFieldInfo(
          inputType: AndroidInputType.classText | AndroidInputType.textFlagNoSuggestions,
          imeOptions: 0,
        );
      case 'email':
        return const InputFieldInfo(
          inputType: AndroidInputType.classText | AndroidInputType.textVariationEmailAddress,
          imeOptions: 0,
        );
      case 'forceAscii':
        return const InputFieldInfo(
          inputType: AndroidInputType.classText,
          imeOptions: AndroidImeOptions.flagForceAscii,
        );
      default:
        return InputFieldInfo.plainText;
    }
  }

  void syncSettings() {
    settings = BooBoardSettings(
      privacy: PrivacySettings(learning: learning, incognito: incognito),
    );
  }

  /// Whether learning must be off right now, from the field and the privacy settings alone.
  bool get mustNotLearn {
    final f = fieldFor(fieldName);
    return f.isSensitive || !learning || incognito || !f.allowsLearning;
  }

  Future<void> apply(_Op op) async {
    final c = controller;
    switch (op.kind) {
      case _Kind.text:
        c.onText(op.text);
      case _Kind.insertText:
        // Inserting over a composer's preedit keeps the preedit as typed (fixed after Wave 4-D).
        c.insertText(op.text);
      case _Kind.space:
        c.onSpace();
      case _Kind.backspace:
        c.onBackspace();
      case _Kind.enter:
        c.onEnter();
      case _Kind.deleteWord:
        c.deleteWordBackward();
      case _Kind.moveCursor:
        c.moveCursor(op.a.round());
      case _Kind.userSelect:
        // A user-driven selection change arrives long after our own edits: not an echo.
        now += 1000;
        final len = editor.text.length;
        final start = (op.a * (len + 1)).floor().clamp(0, len);
        final end = (op.b * (len + 1)).floor().clamp(0, len);
        await editor.setSelection(start < end ? start : end, start < end ? end : start);
      case _Kind.startInput:
        // Half the time the same field restarts over whatever is composing (kept as typed); otherwise
        // the old connection ends first, as the framework does for a field change.
        if (op.a < 0.5) {
          await c.startInput(fieldFor(fieldName), restarting: true);
        } else {
          fieldName = op.text;
          c.finishInput();
          await c.startInput(fieldFor(fieldName));
        }
      case _Kind.finishInput:
        c.finishInput();
      case _Kind.pick:
        // The suggestion bar is empty while a composer is active (it shows the composer's candidates
        // instead), so a suggestion pick cannot happen then.
        if (c.composerActive) return;
        final kinds = SuggestionKind.values;
        c.onSuggestionPicked(Suggestion(op.text, kind: kinds[op.a.round() % kinds.length]));
      case _Kind.shift:
        c.onShiftTap();
      case _Kind.page:
        c.setPage(KeyboardPage.values[op.a.round() % KeyboardPage.values.length]);
      case _Kind.customKey:
        c.onCustomKey(op.text);
      case _Kind.selectCandidate:
        c.selectCandidate(op.a.round());
      case _Kind.composerOn:
        c.composer.value = _FuzzComposer();
      case _Kind.composerOff:
        c.composer.value = null;
      case _Kind.learning:
        learning = op.a > 0.5;
        syncSettings();
      case _Kind.incognito:
        incognito = op.a > 0.5;
        syncSettings();
    }
    await Future<void>.delayed(Duration.zero);
  }

  /// Returns the first violated structural invariant, or null.
  String? check() {
    final sel = editor.selectionStart;
    final selEnd = editor.selectionEnd;
    final len = editor.text.length;
    if (sel < 0 || selEnd < 0 || sel > len || selEnd > len || sel > selEnd) {
      return 'selection $sel..$selEnd outside text of length $len';
    }
    final composing = controller.composing;
    if (composing.isNotEmpty && (editor.composing ?? '') != composing) {
      return 'editor composing "${editor.composing}" != controller composing "$composing"';
    }
    final state = controller.composerState.value;
    if (controller.composerActive && state.preedit.isNotEmpty && editor.composing != state.preedit) {
      return 'editor composing "${editor.composing}" != composer preedit "${state.preedit}"';
    }
    return null;
  }
}

/// Characters whose case mapping changes their length (under caps), so they are exempt from the
/// "text never loses characters" check.
const Set<String> _lengthChangingOnCaps = {'ß', 'İ'};

/// Whether an operation must keep every character: a letter, digit, emoji, mark, Indic or Arabic
/// character typed with a collapsed selection and no composer. Punctuation and spaces are excluded
/// because smart punctuation may remove the space before them.
bool _keepsCharacters(_Op op, _World w) =>
    op.kind == _Kind.text &&
    op.text.isNotEmpty &&
    !_punct.contains(op.text) &&
    op.text != ' ' &&
    !_lengthChangingOnCaps.contains(op.text) &&
    !w.controller.composerActive &&
    w.editor.selectionStart == w.editor.selectionEnd &&
    w.controller.redirect.value == null;

String _show(String s) => '"${s.replaceAll('\n', r'\n')}"';

class _Failure {
  _Failure(this.index, this.message);
  final int index;
  final String message;
}

/// Replays [ops] on a fresh world; returns the first failure.
Future<_Failure?> _replay(List<_Op> ops) async {
  final w = _World();
  for (var i = 0; i < ops.length; i++) {
    final op = ops[i];
    try {
      // Snapshot what the invariants compare before the operation.
      final before = w.editor.text.length;
      final learnedBefore = w.predictor.committedAllowLearning.length;
      final mustNotLearnBefore = w.mustNotLearn;
      final keeps = _keepsCharacters(op, w);
      final codeUnits = op.text.length;

      await w.apply(op);

      if (keeps) {
        final grown = w.editor.text.length - before;
        if (grown != codeUnits) {
          return _Failure(i, 'typed ${_show(op.text)} but the text grew by $grown (expected $codeUnits)');
        }
      }
      final flags = w.predictor.committedAllowLearning.sublist(learnedBefore);
      if (flags.any((allowed) => allowed) && (mustNotLearnBefore || w.mustNotLearn)) {
        return _Failure(i, 'a word was learned while learning is not allowed (field, incognito or setting)');
      }
      final message = w.check();
      if (message != null) return _Failure(i, message);
    } catch (e, st) {
      return _Failure(i, 'exception ${e.runtimeType}: $st');
    }
  }
  return null;
}

/// Shortest failing sequence found: truncate after the failing step, then remove chunks of
/// shrinking size while the failure still reproduces.
Future<(List<_Op>, _Failure)> _shrink(List<_Op> failing, _Failure first) async {
  var ops = List.of(failing);
  var failure = first;
  var chunk = math.max(1, ops.length ~/ 2);
  while (chunk >= 1) {
    var removed = false;
    var start = 0;
    while (start < ops.length) {
      final candidate = [...ops.sublist(0, start), ...ops.sublist(math.min(ops.length, start + chunk))];
      final f = await _replay(candidate);
      if (f != null) {
        ops = candidate.sublist(0, f.index + 1);
        failure = f;
        removed = true;
      } else {
        start += chunk;
      }
    }
    if (!removed) chunk ~/= 2;
  }
  return (ops, failure);
}

List<_Op> _generate(int seed) {
  final rnd = math.Random(seed);
  String pick(List<String> pool) => pool[rnd.nextInt(pool.length)];
  String typed() {
    final r = rnd.nextInt(100);
    if (r < 55) return pick(_letters);
    if (r < 70) return pick(_digits);
    if (r < 78) return pick(_punct);
    if (r < 80) return pick(_letters);
    return pick(_exotic);
  }

  // Weights: text dominates, like typing.
  const weights = <_Kind, int>{
    _Kind.text: 300,
    _Kind.space: 60,
    _Kind.backspace: 60,
    _Kind.enter: 12,
    _Kind.deleteWord: 8,
    _Kind.moveCursor: 25,
    _Kind.userSelect: 12,
    _Kind.startInput: 10,
    _Kind.finishInput: 6,
    _Kind.pick: 25,
    _Kind.insertText: 10,
    _Kind.shift: 12,
    _Kind.page: 6,
    _Kind.customKey: 6,
    _Kind.selectCandidate: 6,
    _Kind.composerOn: 4,
    _Kind.composerOff: 4,
    _Kind.learning: 4,
    _Kind.incognito: 4,
  };
  final total = weights.values.fold<int>(0, (a, b) => a + b);

  _Kind nextKind() {
    var r = rnd.nextInt(total);
    for (final e in weights.entries) {
      r -= e.value;
      if (r < 0) return e.key;
    }
    return _Kind.text;
  }

  final ops = <_Op>[];
  for (var i = 0; i < kStepsPerSeed; i++) {
    final kind = nextKind();
    switch (kind) {
      case _Kind.text:
        ops.add(_Op(kind, typed()));
      case _Kind.insertText:
        ops.add(_Op(kind, pick(_words)));
      case _Kind.moveCursor:
        ops.add(_Op(kind, '', rnd.nextInt(7).toDouble() - 3));
      case _Kind.userSelect:
        ops.add(_Op(kind, '', rnd.nextDouble(), rnd.nextDouble()));
      case _Kind.startInput:
        ops.add(_Op(kind, pick(_fieldNames), rnd.nextDouble()));
      case _Kind.pick:
        ops.add(_Op(kind, pick(_words), rnd.nextInt(10).toDouble()));
      case _Kind.page:
        ops.add(_Op(kind, '', rnd.nextInt(10).toDouble()));
      case _Kind.customKey:
        ops.add(_Op(kind, pick(const ['kana_modifier', 'undo_cycle', 'cursor_left', 'cursor_right'])));
      case _Kind.selectCandidate:
        ops.add(_Op(kind, '', rnd.nextInt(4).toDouble()));
      case _Kind.learning:
      case _Kind.incognito:
        ops.add(_Op(kind, '', rnd.nextBool() ? 1 : 0));
      default:
        ops.add(_Op(kind));
    }
  }
  return ops;
}

void main() {
  // FUZZ_SEED=<n> runs only that seed (to reproduce a reported failure).
  final only = int.tryParse(Platform.environment['FUZZ_SEED'] ?? '') ?? -1;
  for (final seed in kSeeds) {
    if (only >= 0 && seed != only) continue;
    test('InputController survives $kStepsPerSeed random operations (seed $seed)', () async {
      final ops = _generate(seed);
      final failure = await _replay(ops);
      if (failure != null) {
        final (shortest, shrunk) = await _shrink(ops.sublist(0, failure.index + 1), failure);
        final lines = [for (var i = 0; i < shortest.length; i++) '  $i: ${shortest[i]}'];
        fail(
          'seed $seed failed at step ${shrunk.index}: ${shrunk.message}\n'
          'shortest failing sequence (${shortest.length} steps):\n${lines.join('\n')}',
        );
      }
    });
  }

  test('Fixed (Wave 4-D finding): restarting the input over a live composing word loses the word', () async {
    // Expected: the composing "Q" is kept as typed when the field restarts, so the result is "Q7".
    // Actual: startInput drops the controller's composing word without finishing the editor's
    // composing region, so the next commit replaces "Q" and the text is "7".
    final editor = FakeEditor();
    final c = InputController(
      input: editor,
      predictor: FakePredictor(),
      gestureDecoder: FakeGestureDecoder(),
      settings: () => const BooBoardSettings(),
      clock: () => 0,
    );
    editor.onSelectionChanged = c.onSelectionChanged;
    c.onText('Q');
    await c.startInput(InputFieldInfo.plainText, restarting: true);
    c.onText('7');
    expect(editor.text, 'Q7');
  });

  test(
    'Fixed (Wave 4-D finding): insertText over a composer preedit leaves the composer holding the old buffer',
    () async {
      // Expected: the preedit "x" is kept as typed, so the field reads "xhelo" and the composer is empty.
      // Actual: _commitLiteral only finishes the controller's own composing word, so the editor's
      // composing "x" is replaced by "helo" while the composer still holds "x". The field shows
      // "helo" and the composer's next key brings the "x" back.
      final editor = FakeEditor();
      final c = InputController(
        input: editor,
        predictor: FakePredictor(),
        gestureDecoder: FakeGestureDecoder(),
        settings: () => const BooBoardSettings(),
        clock: () => 0,
      );
      editor.onSelectionChanged = c.onSelectionChanged;
      final composer = _FuzzComposer();
      c.composer.value = composer;
      c.onText('x');
      c.insertText('helo');
      expect(editor.text, 'xhelo');
      expect(composer.state.isEmpty, isTrue);
    },
  );
}
