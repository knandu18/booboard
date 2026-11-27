// SPDX-License-Identifier: GPL-3.0-or-later
//
// Error-tolerant search over a packed dictionary trie.
//
// The typed key sequence is matched against the trie with up to [maxEdits]
// edits: neighbour substitution (cost from the spatial model), insertion of a
// stray key, omission of a key (cheap when it doubles a letter or is an
// apostrophe) and transposition of two neighbours. Branch-and-bound on the
// accumulated cost keeps the walk small. Nodes reached after consuming all
// typed keys are exact words or prefixes; for prefixes the best completions
// are found best-first using each subtree's best frequency.
import 'dart:typed_data';

import '../dictionary/mdict_lexicon.dart';
import 'spatial_model.dart';

/// Tunable costs (negative log-likelihood units).
class SearchCosts {
  const SearchCosts({
    this.maxEdits = 2,
    this.budget = 7.0,
    this.editPenalty = 0.8,
    this.firstLetterPenalty = 1.6,
    this.insertion = 3.4,
    this.doubledInsertion = 1.0,
    this.deletion = 4.0,
    this.doubledDeletion = 0.9,
    this.transposition = 1.6,
    this.vowelSubstitution = 2.2,
    this.apostropheOmission = 0.3,
    this.completionPerChar = 0.2,
  });

  final int maxEdits;
  final double budget;
  final double editPenalty;
  final double firstLetterPenalty;
  final double insertion;
  final double doubledInsertion;
  final double deletion;
  final double doubledDeletion;
  final double transposition;
  final double vowelSubstitution;
  final double apostropheOmission;
  final double completionPerChar;
}

class SearchCandidate {
  SearchCandidate(this.id, this.cost, this.edits, this.isCompletion, this.extraChars);

  final int id;

  /// Spatial + edit cost (lower is better).
  double cost;
  int edits;

  /// True when the word is longer than what was typed.
  bool isCompletion;
  int extraChars;
}

const int _apostrophe = 0x27;
const List<int> _vowels = [0x61, 0x65, 0x69, 0x6f, 0x75];

bool _isVowel(int c) => c == 0x61 || c == 0x65 || c == 0x69 || c == 0x6f || c == 0x75;

bool _inNeighbours(Int32List chars, int c) {
  for (var k = 0; k < chars.length; k++) {
    if (chars[k] == c) return true;
  }
  return false;
}

class TrieSearcher {
  TrieSearcher(this.lexicon, {this.costs = const SearchCosts()});

  final MdictLexicon lexicon;
  final SearchCosts costs;

  late Int32List _typed;
  late List<PositionCandidates> _pos;
  late Map<int, SearchCandidate> _found;
  int _n = 0;
  int _completionBudget = 8;

  // Completion priority queue (min-heap on key).
  final List<int> _hKey = [];
  final List<int> _hNode = []; // node*2 + (1 when the item stands for the node's own word)
  final List<int> _hDepth = [];

  /// Candidates for [typed] (folded key characters). [maxCompletions] bounds
  /// the completions taken from each prefix node.
  Map<int, SearchCandidate> search(Int32List typed, List<PositionCandidates> positions, {int maxCompletions = 8}) {
    _typed = typed;
    _pos = positions;
    _n = typed.length;
    _found = {};
    _completionBudget = maxCompletions;
    _walk(lexicon.rootNode, 0, 0, 0, 0);
    return _found;
  }

  void _add(int id, double cost, int edits, bool completion, int extra) {
    final old = _found[id];
    if (old == null) {
      _found[id] = SearchCandidate(id, cost, edits, completion, extra);
    } else if (cost < old.cost) {
      old
        ..cost = cost
        ..edits = edits
        ..isCompletion = completion
        ..extraChars = extra;
    }
  }

  void _walk(int node, int i, double cost, int edits, int prevChar) {
    final c = costs;
    if (i == _n) {
      _reachedEnd(node, cost, edits);
      return;
    }
    final lex = lexicon;
    final here = _pos[i];
    final typedChar = _typed[i];

    // Match or substitute with a neighbouring key.
    final chars = here.chars;
    final cs = here.costs;
    for (var k = 0; k < chars.length; k++) {
      final ch = chars[k];
      final child = lex.findChild(node, ch);
      if (child < 0) continue;
      final isEdit = ch != typedChar;
      final ne = edits + (isEdit ? 1 : 0);
      if (ne > c.maxEdits) continue;
      var nc = cost + cs[k];
      if (isEdit) nc += c.editPenalty + (i == 0 ? c.firstLetterPenalty : 0);
      if (nc > c.budget) continue;
      _walk(child, i + 1, nc, ne, ch);
    }

    // Vowels are often confused with each other ("seperate", "definately").
    if (_isVowel(typedChar) && edits < c.maxEdits) {
      final nc = cost + c.vowelSubstitution + c.editPenalty + (i == 0 ? c.firstLetterPenalty : 0);
      if (nc <= c.budget) {
        for (final v in _vowels) {
          if (v == typedChar || _inNeighbours(chars, v)) continue;
          final child = lex.findChild(node, v);
          if (child >= 0) _walk(child, i + 1, nc, edits + 1, v);
        }
      }
    }

    // Free apostrophe omission: "dont" -> "don't".
    final apos = lex.findChild(node, _apostrophe);
    if (apos >= 0 && typedChar != _apostrophe) {
      final nc = cost + c.apostropheOmission;
      if (nc <= c.budget) _walk(apos, i, nc, edits, _apostrophe);
    }

    if (edits >= c.maxEdits) return;
    final firstExtra = i == 0 ? c.firstLetterPenalty : 0;

    // Stray key: skip the typed character.
    final doubled = i > 0 && typedChar == _typed[i - 1];
    final ins = cost + (doubled ? c.doubledInsertion : c.insertion) + c.editPenalty + firstExtra;
    if (ins <= c.budget) _walk(node, i + 1, ins, edits + 1, prevChar);

    // Two keys in the wrong order.
    if (i + 1 < _n && _typed[i + 1] != typedChar) {
      final first = lex.findChild(node, _typed[i + 1]);
      if (first >= 0) {
        final second = lex.findChild(first, typedChar);
        if (second >= 0) {
          final nc = cost + here.ownCost + _pos[i + 1].ownCost + c.transposition + c.editPenalty + firstExtra;
          if (nc <= c.budget) _walk(second, i + 2, nc, edits + 1, typedChar);
        }
      }
    }

    // Missing key: the word has a letter the user did not type.
    final count = lex.childCount(node);
    for (var j = 0; j < count; j++) {
      final ch = lex.childChar(node, j);
      if (ch == _apostrophe) continue;
      final nc = cost + (ch == prevChar ? c.doubledDeletion : c.deletion) + c.editPenalty + firstExtra;
      if (nc > c.budget) continue;
      _walk(lex.childNode(node, j), i, nc, edits + 1, ch);
    }
  }

  void _reachedEnd(int node, double cost, int edits) {
    final lex = lexicon;
    if (lex.isTerminal(node)) _add(lex.wordIdOf(node), cost, edits, false, 0);
    if (edits <= 1 && cost <= 5.0 && lex.childCount(node) > 0) _complete(node, cost, edits);
  }

  // ------------------------------------------------------------ completions

  void _complete(int node, double cost, int edits) {
    final lex = lexicon;
    _hKey.clear();
    _hNode.clear();
    _hDepth.clear();
    _pushChildren(node, 1);
    var emitted = 0;
    while (_hKey.isNotEmpty && emitted < _completionBudget) {
      final item = _hNode[0];
      final depth = _hDepth[0];
      _pop();
      final n = item >> 1;
      if (item & 1 == 1) {
        final id = lex.wordIdOf(n);
        _add(id, cost + costs.completionPerChar * depth, edits, true, depth);
        emitted++;
        continue;
      }
      if (lex.isTerminal(n)) _push(lex.qOfNode(n), (n << 1) | 1, depth);
      _pushChildren(n, depth + 1);
    }
  }

  void _pushChildren(int node, int depth) {
    final lex = lexicon;
    final count = lex.childCount(node);
    for (var j = 0; j < count; j++) {
      final child = lex.childNode(node, j);
      _push(lex.bestQ(child), child << 1, depth);
    }
  }

  void _push(int key, int node, int depth) {
    var i = _hKey.length;
    _hKey.add(key);
    _hNode.add(node);
    _hDepth.add(depth);
    while (i > 0) {
      final parent = (i - 1) >> 1;
      if (_hKey[parent] <= key) break;
      _hKey[i] = _hKey[parent];
      _hNode[i] = _hNode[parent];
      _hDepth[i] = _hDepth[parent];
      i = parent;
    }
    _hKey[i] = key;
    _hNode[i] = node;
    _hDepth[i] = depth;
  }

  void _pop() {
    final last = _hKey.length - 1;
    if (last == 0) {
      _hKey.removeLast();
      _hNode.removeLast();
      _hDepth.removeLast();
      return;
    }
    final key = _hKey[last];
    final node = _hNode[last];
    final depth = _hDepth[last];
    _hKey.removeLast();
    _hNode.removeLast();
    _hDepth.removeLast();
    var i = 0;
    final size = _hKey.length;
    while (true) {
      var child = 2 * i + 1;
      if (child >= size) break;
      if (child + 1 < size && _hKey[child + 1] < _hKey[child]) child++;
      if (_hKey[child] >= key) break;
      _hKey[i] = _hKey[child];
      _hNode[i] = _hNode[child];
      _hDepth[i] = _hDepth[child];
      i = child;
    }
    _hKey[i] = key;
    _hNode[i] = node;
    _hDepth[i] = depth;
  }
}
