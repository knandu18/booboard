// SPDX-License-Identifier: GPL-3.0-or-later
//
// Fakes for the keyboard tests: a scripted predictor and gesture decoder, and
// a pack repository that reads layouts straight from assets/ on disk.
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:booboard/src/engine/contracts.dart';
import 'package:booboard/src/packs/pack_repository.dart';

class FakePredictor implements TextPredictor {
  FakePredictor({
    this.known = const {'hello', 'world', 'the', 'is', 'this', 'a', 'test'},
    this.corrections = const {'teh': 'the', 'helo': 'hello'},
    this.completions = const {},
    this.next = const ['the', 'a', 'I'],
  });

  Set<String> known;

  /// typed -> auto-correction.
  Map<String, String> corrections;

  /// prefix -> completions.
  Map<String, List<String>> completions;
  List<String> next;

  final List<String> committed = [];
  final List<List<String>> committedContext = [];
  final List<bool> committedAllowLearning = [];
  final List<(String, String)> reverted = [];
  int suggestCalls = 0;
  KeyboardGeometry? geometry;
  List<LanguageId> languages = const [];

  @override
  Future<void> setActiveLanguages(List<LanguageId> languages) async => this.languages = languages;

  @override
  void setGeometry(KeyboardGeometry geometry) => this.geometry = geometry;

  @override
  SuggestionResult suggest(TypingContext context) {
    suggestCalls++;
    final lower = context.composing.toLowerCase();
    final list = <Suggestion>[Suggestion(context.composing, kind: SuggestionKind.typed)];
    for (final c in completions[lower] ?? const <String>[]) {
      list.add(Suggestion(c, kind: SuggestionKind.completion));
    }
    Suggestion? auto;
    final fix = corrections[lower];
    if (fix != null) {
      auto = Suggestion(fix, kind: SuggestionKind.correction);
      list.insert(0, auto);
    }
    return SuggestionResult(suggestions: list, autoCorrection: auto);
  }

  @override
  List<Suggestion> predictNext(List<String> previousWords, {int max = 3}) => [
    for (final w in next.take(max)) Suggestion(w, kind: SuggestionKind.prediction),
  ];

  @override
  bool isKnownWord(String word) => known.contains(word.toLowerCase());

  @override
  void onWordCommitted(String word, {required List<String> previousWords, required bool allowLearning}) {
    committed.add(word);
    committedContext.add(List.of(previousWords));
    committedAllowLearning.add(allowLearning);
  }

  @override
  void onAutoCorrectionReverted({required String original, required String correction}) =>
      reverted.add((original, correction));

  @override
  void blockWord(String word) {}

  @override
  void forgetWord(String word) {}

  @override
  Iterable<LexiconEntry> learnedWords(LanguageId language) => const [];

  @override
  Future<void> flush() async {}

  @override
  Future<void> clearLearnedData() async {}

  int reloads = 0;

  @override
  Future<void> reloadLearnedData() async => reloads++;

  @override
  void trimMemory() {}
}

class FakeGestureDecoder implements GestureDecoder {
  /// Returned by [decode].
  List<String> result = const [];
  String? previewResult;
  final List<GesturePath> decoded = [];
  final List<List<String>> decodedContext = [];
  int prepareCalls = 0;
  KeyboardGeometry? lastGeometry;
  List<LanguageId>? lastLanguages;
  int previewCalls = 0;

  @override
  Future<void> prepare({
    required KeyboardGeometry geometry,
    required List<LanguageId> languages,
    Iterable<LexiconEntry> extraWords = const [],
  }) async {
    prepareCalls++;
    lastGeometry = geometry;
    lastLanguages = languages;
  }

  @override
  Future<List<Suggestion>> decode(GesturePath path, {List<String> previousWords = const [], int maxResults = 6}) async {
    decoded.add(path);
    decodedContext.add(List.of(previousWords));
    return [for (final w in result) Suggestion(w, kind: SuggestionKind.gesture)];
  }

  @override
  Future<String?> preview(GesturePath partialPath) async {
    previewCalls++;
    return previewResult;
  }

  @override
  void trimMemory() {}

  @override
  void dispose() {}
}

/// Reads `assets/<path>` from the repository on disk (tests run from the project root).
/// Reads are synchronous so widget tests (fake async) can await them.
class DiskPackRepository implements PackRepository {
  @override
  Future<ByteData> load(String path) async => ByteData.sublistView(File('assets/$path').readAsBytesSync());

  @override
  Future<String> loadString(String path) => Future.value(File('assets/$path').readAsStringSync());

  @override
  Future<bool> exists(String path) async => File('assets/$path').existsSync();
}
