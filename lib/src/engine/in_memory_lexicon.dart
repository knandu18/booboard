// SPDX-License-Identifier: GPL-3.0-or-later
//
// Small in-memory lexicon: used by tests and as the Wave 0 placeholder until
// the real dictionary engine lands.
import 'dart:math' as math;

import 'contracts.dart';

class InMemoryLexicon implements Lexicon {
  /// [words] in descending frequency order; probabilities follow Zipf's law
  /// unless [counts] are given.
  InMemoryLexicon(this.language, List<String> words, {List<int>? counts, Map<(String, String), int>? bigrams})
    : _bigrams = bigrams ?? const {} {
    final total = counts?.fold<int>(0, (a, b) => a + b);
    var harmonic = 0.0;
    for (var i = 1; i <= words.length; i++) {
      harmonic += 1 / i;
    }
    for (var i = 0; i < words.length; i++) {
      final p = counts != null ? counts[i] / total! : (1 / (i + 1)) / harmonic;
      _entries.add(LexiconEntry(words[i], math.log(p)));
      _index[words[i]] = _entries.last.logProb;
    }
  }

  @override
  final LanguageId language;
  final List<LexiconEntry> _entries = [];
  final Map<String, double> _index = {};
  final Map<(String, String), int> _bigrams;

  @override
  int get size => _entries.length;

  @override
  Iterable<LexiconEntry> entries({int? limit}) => limit == null ? _entries : _entries.take(limit);

  @override
  double? logProb(String word) => _index[word] ?? _index[word.toLowerCase()];

  @override
  double bigramLogProb(String previous, String word) {
    final unigram = logProb(word) ?? -20;
    final pairCount = _bigrams[(previous.toLowerCase(), word.toLowerCase())];
    if (pairCount == null) return unigram + math.log(0.4); // stupid backoff
    final prevTotal = _bigrams.entries
        .where((e) => e.key.$1 == previous.toLowerCase())
        .fold<int>(0, (a, e) => a + e.value);
    return math.log(pairCount / prevTotal);
  }
}

class InMemoryLexiconSource implements LexiconSource {
  InMemoryLexiconSource(this._lexicons);

  final Map<LanguageId, Lexicon> _lexicons;

  @override
  Future<Lexicon> load(LanguageId language) async {
    final lexicon = _lexicons[language];
    if (lexicon == null) throw StateError('No lexicon for $language');
    return lexicon;
  }

  @override
  bool isLoaded(LanguageId language) => _lexicons.containsKey(language);

  @override
  void evict(LanguageId language) {}
}

/// The 200 most common English words: enough for the Wave 0 placeholder and
/// for unit tests that need realistic frequencies.
const List<String> kStarterEnglishWords = [
  'the', 'be', 'to', 'of', 'and', 'a', 'in', 'that', 'have', 'i', 'it', 'for', 'not', 'on', 'with', //
  'he', 'as', 'you', 'do', 'at', 'this', 'but', 'his', 'by', 'from', 'they', 'we', 'say', 'her', 'she',
  'or', 'an', 'will', 'my', 'one', 'all', 'would', 'there', 'their', 'what', 'so', 'up', 'out', 'if',
  'about', 'who', 'get', 'which', 'go', 'me', 'when', 'make', 'can', 'like', 'time', 'no', 'just', 'him',
  'know', 'take', 'people', 'into', 'year', 'your', 'good', 'some', 'could', 'them', 'see', 'other',
  'than', 'then', 'now', 'look', 'only', 'come', 'its', 'over', 'think', 'also', 'back', 'after', 'use',
  'two', 'how', 'our', 'work', 'first', 'well', 'way', 'even', 'new', 'want', 'because', 'any', 'these',
  'give', 'day', 'most', 'us', 'is', 'was', 'are', 'been', 'has', 'had', 'were', 'said', 'did', 'having',
  'may', 'should', 'hello', 'thanks', 'thank', 'please', 'yes', 'okay', 'love', 'home', 'today',
  'tomorrow', 'tonight', 'morning', 'night', 'here', 'where', 'why', 'very', 'really', 'great', 'nice',
  'right', 'sorry', 'meet', 'call', 'later', 'soon', 'sure', 'need', 'help', 'let', 'keep', 'feel',
  'tell', 'ask', 'show', 'try', 'leave', 'put', 'mean', 'still', 'place', 'little', 'world', 'never',
  'again', 'long', 'thing', 'many', 'life', 'down', 'off', 'while', 'last', 'might', 'old', 'big',
  'high', 'every', 'same', 'another', 'next', 'early', 'young', 'important', 'few', 'public', 'bad',
  'able', 'free', 'happy', 'birthday', 'friend', 'family', 'food', 'water', 'phone', 'message', 'text',
  'keyboard', 'type', 'word', 'write', 'read', 'open', 'close', 'start', 'stop', 'wait', 'done',
];
