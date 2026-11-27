// SPDX-License-Identifier: GPL-3.0-or-later
//
// OWNER: Wave 4-A. Simplified to Traditional (Taiwan standard, with Taiwanese phrases), the OpenCC
// `s2twp` conversion, applied to the candidates when settings.chinese.traditional is on.
//
// The pack's `s2twp.tsv` holds four OpenCC tables, one per line as `section<TAB>from<TAB>to`:
//   A  STPhrases.txt     B  STCharacters.txt   (chain 1: phrases first, then characters)
//   C  TWPhrases.txt     D  TWVariants.txt     (chain 2: the same order)
// Each table keeps the first target of OpenCC's list. Conversion is greedy longest match.
import 'dart:math' as math;

class S2twpConverter {
  S2twpConverter({
    required Map<String, String> stPhrases,
    required Map<String, String> stChars,
    required Map<String, String> twPhrases,
    required Map<String, String> twVariants,
  }) : _chain1 = _Chain(stPhrases, stChars),
       _chain2 = _Chain(twPhrases, twVariants);

  /// Parses the `s2twp.tsv` text. Unknown or malformed lines are skipped.
  factory S2twpConverter.parse(String tsv) {
    final tables = {
      for (final s in ['A', 'B', 'C', 'D']) s: <String, String>{},
    };
    for (final line in tsv.split('\n')) {
      final parts = line.split('\t');
      if (parts.length != 3) continue;
      final table = tables[parts[0]];
      if (table == null || parts[1].isEmpty || parts[2].isEmpty) continue;
      table.putIfAbsent(parts[1], () => parts[2]);
    }
    return S2twpConverter(
      stPhrases: tables['A']!,
      stChars: tables['B']!,
      twPhrases: tables['C']!,
      twVariants: tables['D']!,
    );
  }

  final _Chain _chain1;
  final _Chain _chain2;

  /// Converts Simplified [text] to Traditional (Taiwan). Other characters pass through unchanged.
  String convert(String text) {
    if (text.isEmpty) return text;
    return _chain2.apply(_chain1.apply(text));
  }
}

class _Chain {
  _Chain(this._phrases, this._chars) : _maxPhrase = _phrases.keys.fold<int>(1, (m, k) => math.max(m, k.runes.length));

  final Map<String, String> _phrases;
  final Map<String, String> _chars;
  final int _maxPhrase;

  String apply(String text) {
    final runes = text.runes.toList();
    final out = StringBuffer();
    var i = 0;
    while (i < runes.length) {
      var matched = false;
      final longest = math.min(_maxPhrase, runes.length - i);
      for (var len = longest; len >= 2; len--) {
        final key = String.fromCharCodes(runes, i, i + len);
        final hit = _phrases[key];
        if (hit != null) {
          out.write(hit);
          i += len;
          matched = true;
          break;
        }
      }
      if (matched) continue;
      final ch = String.fromCharCode(runes[i]);
      out.write(_chars[ch] ?? ch);
      i++;
    }
    return out.toString();
  }
}
