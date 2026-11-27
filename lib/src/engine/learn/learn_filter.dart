// SPDX-License-Identifier: GPL-3.0-or-later
//
// Decides which typed words may be remembered. The point is to never store
// anything that looks like a secret: passwords, tokens, keys, numbers, IDs.
final RegExp _wordShape = RegExp(r"^\p{L}[\p{L}\p{M}'\-]*$", unicode: true);
final RegExp _latinVowel = RegExp(r'[aeiouyàáâãäåèéêëìíîïòóôõöùúûüýÿ]');

/// True when [word] is plain word-like text that is safe to learn.
///
/// Rejects: anything with digits or symbols, camelCase and long all-caps
/// tokens, very short or very long tokens, runs of one repeated letter,
/// implausible consonant clusters and high-entropy letter soup.
bool isLearnableWord(String word) {
  final w = word.replaceAll('’', "'");
  final length = w.runes.length;
  if (length < 2 || length > 24) return false;
  if (!_wordShape.hasMatch(w)) return false;
  if (w.endsWith("'") || w.endsWith('-')) return false;

  var upper = 0;
  var lower = 0;
  String? previous;
  var run = 1;
  var consonantRun = 0;
  var maxConsonantRun = 0;
  final distinct = <int>{};
  for (final r in w.runes) {
    final ch = String.fromCharCode(r);
    final isUpper = ch != ch.toLowerCase();
    final isLower = ch != ch.toUpperCase();
    if (isUpper) upper++;
    if (isLower) lower++;
    // camelCase: a capital right after a lower-case letter.
    if (isUpper && previous != null && previous != previous.toUpperCase()) return false;
    run = previous == ch ? run + 1 : 1;
    if (run >= 4) return false;
    previous = ch;
    distinct.add(r);
    final lowerCh = ch.toLowerCase();
    final isLatin = r < 0x250;
    if (isLatin && isLower || isUpper && isLatin) {
      if (_latinVowel.hasMatch(lowerCh)) {
        consonantRun = 0;
      } else if (lowerCh != "'" && lowerCh != '-') {
        consonantRun++;
        if (consonantRun > maxConsonantRun) maxConsonantRun = consonantRun;
      } else {
        consonantRun = 0;
      }
    }
  }
  if (upper > 1 && lower == 0 && length > 6) return false;
  if (maxConsonantRun >= 6) return false;
  if (length >= 10 && distinct.length / length > 0.78) return false;
  return true;
}
