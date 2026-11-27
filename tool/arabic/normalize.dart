// SPDX-License-Identifier: GPL-3.0-or-later
//
// Arabic-script normalisation for the ar and ur word lists (Wave 3-C). Shared by the converter
// and the tests. Removes what users rarely type (harakat, tatweel, ZWNJ) and maps the Arabic and
// Persian/Urdu variants of yeh and kaf to the forms each language uses.

/// Letters, marks and tatweel: the characters a word is made of before normalisation.
final RegExp _wordRun = RegExp(r'[\p{L}\p{M}ـ‌‍]+', unicode: true);

/// Only Arabic-script letters (no Latin, digits or punctuation) once the marks are gone.
final RegExp _arabicOnly = RegExp(r'^\p{Script=Arabic}+$', unicode: true);

/// Strips harakat, tatweel and ZWNJ/ZWJ, then maps yeh and kaf for [lang]. Returns null when
/// the result is not a plausible word (Latin letters, too short, too long).
String? normalizeArabicWord(String raw, String lang) {
  var w = raw.replaceAll(RegExp(r'[\p{M}ـ‌‍]', unicode: true), '');
  w = switch (lang) {
    'ar' => w.replaceAll('ی', 'ي').replaceAll('ک', 'ك'),
    'ur' => w.replaceAll('ي', 'ی').replaceAll('ى', 'ی').replaceAll('ك', 'ک'),
    _ => throw ArgumentError.value(lang, 'lang', 'expected ar or ur'),
  };
  if (!_arabicOnly.hasMatch(w)) return null;
  final length = w.runes.length;
  if (length < 2 || length > 20) return null;
  return w;
}

/// Every normalised word in [text] (runs of letters, marks and tatweel).
Iterable<String> arabicWordsIn(String text, String lang) sync* {
  for (final m in _wordRun.allMatches(text)) {
    final w = normalizeArabicWord(m.group(0)!, lang);
    if (w != null) yield w;
  }
}
