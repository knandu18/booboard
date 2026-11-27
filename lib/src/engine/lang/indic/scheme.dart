// SPDX-License-Identifier: GPL-3.0-or-later
//
// OWNER: Wave 3-B. Rule-based romanisation to native script ("namaste" -> नमस्ते) for any typed
// word the translation table does not know. The table (translit_table.dart) gives the common
// words; this scheme makes every typed word convert.
//
// The scheme is ITRANS/Harvard-Kyoto-like, written for English letters:
//   * consonants: "kh" ख, "gh" घ, "chh" छ, "sh" श, "shh" ष, retroflex "tt" ट, "dd" ड, "nn" ण
//   * vowels: "aa" आ, "ii"/"ee" ई, "uu"/"oo" ऊ, "ri" ऋ, "ai" ऐ, "au" औ
//   * an unwritten "a" after a consonant is the inherent vowel; a word-final "a" after a consonant
//     is long ("kya" -> क्या)
//   * a consonant followed by another consonant gets a virama (conjunct)
//   * a word-final consonant gets a virama in Tamil and Telugu; in Hindi, Marathi and Bengali
//     the inherent vowel is silent by convention and is written without one
//   * "n" before a consonant becomes an anusvara (ं) in Devanagari, Bengali and Telugu
/// The scripts BooBoard romanises. Each has its own letters and conventions.
class IndicScheme {
  IndicScheme({
    required this.language,
    required this.consonants,
    required this.vowels,
    required this.virama,
    required this.anusvara,
    required this.finalVirama,
    required this.finalAaAfterConsonant,
    required this.nasalAnusvara,
  });

  final String language;

  /// Roman key -> native consonant (a cluster such as "क्ष" ends in a consonant, so a matra can follow).
  final Map<String, String> consonants;

  /// Roman key -> (independent vowel, vowel sign). The sign is '' for the inherent vowel.
  final Map<String, (String, String)> vowels;
  final String virama;
  final String? anusvara;

  /// Tamil and Telugu write a word-final consonant with a virama.
  final bool finalVirama;

  /// A word-final "a" after a consonant is long (क्या, राजा).
  final bool finalAaAfterConsonant;

  /// "n" followed by a consonant is written as an anusvara (only when [anusvara] is set).
  final bool nasalAnusvara;

  /// Native text for a word typed in English letters. Non-letters pass through unchanged. Never
  /// throws and never returns an empty string for a non-empty input.
  String convert(String latin) {
    final units = _tokenize(latin.toLowerCase());
    final out = StringBuffer();
    var open = false; // a consonant whose inherent vowel has not been replaced yet
    for (final u in units) {
      switch (u.kind) {
        case _Kind.consonant:
          if (open) out.write(virama);
          out.write(u.text);
          open = true;
        case _Kind.vowel:
          if (open) {
            out.write(u.sign);
          } else {
            out.write(u.text);
          }
          open = false;
        case _Kind.nasal:
          out.write(anusvara ?? '');
          open = false;
        case _Kind.literal:
          if (open) {
            if (finalVirama) out.write(virama);
            open = false;
          }
          out.write(u.text);
      }
    }
    if (open && finalVirama) out.write(virama);
    final s = out.toString();
    return s.isEmpty ? latin : s;
  }

  // ---- tokenizer -------------------------------------------------------------

  late final List<String> _consonantKeys = (consonants.keys.toList()..sort((a, b) => b.length.compareTo(a.length)));
  late final List<String> _vowelKeys = (vowels.keys.toList()..sort((a, b) => b.length.compareTo(a.length)));

  List<_Unit> _tokenize(String s) {
    final units = <_Unit>[];
    var i = 0;
    while (i < s.length) {
      final c = s.codeUnitAt(i);
      if (!_isAsciiLetter(c)) {
        units.add(_Unit(_Kind.literal, s[i]));
        i++;
        continue;
      }
      final cons = _matchAt(s, i, _consonantKeys);
      if (cons != null) {
        // "n" before another consonant is an anusvara: "sangh" -> संघ (not नंघ).
        if (nasalAnusvara && anusvara != null && cons == 'n') {
          final next = _matchAt(s, i + 1, _consonantKeys);
          if (next != null && !_noAnusvaraBefore.contains(next) && !_startsVowel(s, i + 1)) {
            units.add(const _Unit(_Kind.nasal, ''));
            i += 1;
            continue;
          }
        }
        units.add(_Unit(_Kind.consonant, consonants[cons]!));
        i += cons.length;
        continue;
      }
      final vowel = _matchAt(s, i, _vowelKeys);
      if (vowel != null) {
        final (indep, sign) = vowels[vowel]!;
        units.add(_Unit(_Kind.vowel, indep, sign: sign));
        i += vowel.length;
        continue;
      }
      units.add(_Unit(_Kind.literal, s[i]));
      i++;
    }
    // A word-final "a" after a consonant is long: "kya" -> क्या.
    if (finalAaAfterConsonant && units.length >= 2) {
      final last = units.last;
      final prev = units[units.length - 2];
      if (last.kind == _Kind.vowel && last.text == vowels['a']!.$1 && prev.kind == _Kind.consonant) {
        units[units.length - 1] = _Unit(_Kind.vowel, vowels['aa']!.$1, sign: vowels['aa']!.$2);
      }
    }
    return units;
  }

  /// The longest key of [keys] that starts at [i], or null.
  String? _matchAt(String s, int i, List<String> keys) {
    for (final k in keys) {
      if (i + k.length <= s.length && s.startsWith(k, i)) return k;
    }
    return null;
  }

  bool _startsVowel(String s, int i) => _matchAt(s, i, _vowelKeys) != null;

  /// "n" before these starts a word part of its own (dhanyavaad, anna): no anusvara.
  static const _noAnusvaraBefore = {'n', 'y', 'v', 'h', 'w'};

  static bool _isAsciiLetter(int c) => (c >= 0x61 && c <= 0x7A);
}

enum _Kind { consonant, vowel, nasal, literal }

class _Unit {
  const _Unit(this.kind, this.text, {this.sign = ''});

  final _Kind kind;

  /// Consonant or literal text, or the independent vowel for a vowel.
  final String text;

  /// The vowel sign for a vowel (empty for the inherent vowel).
  final String sign;
}

// ---------------------------------------------------------------------------
// Scripts. The consonant and vowel letters follow the Unicode blocks; the keys are English letters.
// ---------------------------------------------------------------------------

const Map<String, String> _devanagariConsonants = {
  'k': 'क',
  'kh': 'ख',
  'g': 'ग',
  'gh': 'घ',
  'c': 'क',
  'ch': 'च',
  'chh': 'छ',
  'j': 'ज',
  'jh': 'झ',
  't': 'त',
  'th': 'थ',
  'tt': 'ट',
  'tth': 'ठ',
  'd': 'द',
  'dh': 'ध',
  'dd': 'ड',
  'ddh': 'ढ',
  'n': 'न',
  'nn': 'ण',
  'p': 'प',
  'ph': 'फ',
  'f': 'फ',
  'b': 'ब',
  'bh': 'भ',
  'm': 'म',
  'y': 'य',
  'r': 'र',
  'rr': 'ड़',
  'l': 'ल',
  'v': 'व',
  'w': 'व',
  'sh': 'श',
  'shh': 'ष',
  's': 'स',
  'h': 'ह',
  'q': 'क',
  'z': 'ज',
  'x': 'क्स',
  'ksh': 'क्ष',
  'gy': 'ज्ञ',
  'tr': 'त्र',
};

const Map<String, (String, String)> _devanagariVowels = {
  'a': ('अ', ''),
  'aa': ('आ', 'ा'),
  'i': ('इ', 'ि'),
  'ii': ('ई', 'ी'),
  'ee': ('ई', 'ी'),
  'u': ('उ', 'ु'),
  'uu': ('ऊ', 'ू'),
  'oo': ('ऊ', 'ू'),
  'ri': ('ऋ', 'ृ'),
  'e': ('ए', 'े'),
  'ei': ('ए', 'े'),
  'ai': ('ऐ', 'ै'),
  'o': ('ओ', 'ो'),
  'au': ('औ', 'ौ'),
  'ou': ('औ', 'ौ'),
};

/// Hindi: Devanagari with schwa deletion at the end of words.
final IndicScheme hindiScheme = IndicScheme(
  language: 'hi',
  consonants: _devanagariConsonants,
  vowels: _devanagariVowels,
  virama: '्',
  anusvara: 'ं',
  finalVirama: false,
  finalAaAfterConsonant: true,
  nasalAnusvara: true,
);

/// Marathi: as Hindi, with the retroflex lateral ळ.
final IndicScheme marathiScheme = IndicScheme(
  language: 'mr',
  consonants: {..._devanagariConsonants, 'lh': 'ळ'},
  vowels: _devanagariVowels,
  virama: '्',
  anusvara: 'ं',
  finalVirama: false,
  finalAaAfterConsonant: true,
  nasalAnusvara: true,
);

final IndicScheme bengaliScheme = IndicScheme(
  language: 'bn',
  consonants: {
    'k': 'ক',
    'kh': 'খ',
    'g': 'গ',
    'gh': 'ঘ',
    'c': 'ক',
    'ch': 'চ',
    'chh': 'ছ',
    'j': 'জ',
    'jh': 'ঝ',
    't': 'ত',
    'th': 'থ',
    'tt': 'ট',
    'tth': 'ঠ',
    'd': 'দ',
    'dh': 'ধ',
    'dd': 'ড',
    'ddh': 'ঢ',
    'n': 'ন',
    'nn': 'ণ',
    'p': 'প',
    'ph': 'ফ',
    'f': 'ফ',
    'b': 'ব',
    'bh': 'ভ',
    'v': 'ভ',
    'm': 'ম',
    'y': 'য',
    'r': 'র',
    'rr': 'ড়',
    'l': 'ল',
    'sh': 'শ',
    'shh': 'ষ',
    's': 'স',
    'h': 'হ',
    'q': 'ক',
    'z': 'জ',
    'x': 'ক্স',
    'ksh': 'ক্ষ',
    'gy': 'জ্ঞ',
    'tr': 'ত্র',
  },
  vowels: {
    'a': ('অ', ''),
    'aa': ('আ', 'া'),
    'i': ('ই', 'ি'),
    'ii': ('ঈ', 'ী'),
    'ee': ('ঈ', 'ী'),
    'u': ('উ', 'ু'),
    'uu': ('ঊ', 'ূ'),
    'oo': ('ঊ', 'ূ'),
    'ri': ('ঋ', 'ৃ'),
    'e': ('এ', 'ে'),
    'ei': ('এ', 'ে'),
    'ai': ('ঐ', 'ৈ'),
    'o': ('ও', 'ো'),
    'au': ('ঔ', 'ৌ'),
    'ou': ('ঔ', 'ৌ'),
  },
  virama: '্',
  anusvara: 'ং',
  finalVirama: false,
  finalAaAfterConsonant: true,
  nasalAnusvara: true,
);

final IndicScheme tamilScheme = IndicScheme(
  language: 'ta',
  consonants: {
    // Tamil has five stops per place of articulation; the letters are shared (க for k, g, kh, gh).
    'k': 'க', 'kh': 'க', 'g': 'க', 'gh': 'க', 'c': 'க', 'ch': 'ச', 'chh': 'ச', 'j': 'ஜ', 'jh': 'ஜ',
    'ny': 'ஞ', 'ng': 'ங', 't': 'த', 'th': 'த', 'tt': 'ட', 'tth': 'ட', 'd': 'த', 'dh': 'த', 'dd': 'ட',
    'ddh': 'ட', 'n': 'ந', 'nn': 'ண', 'p': 'ப', 'ph': 'ப', 'f': 'ப', 'b': 'ப', 'bh': 'ப', 'm': 'ம',
    'y': 'ய', 'r': 'ர', 'rr': 'ற', 'l': 'ல', 'lh': 'ள', 'zh': 'ழ', 'v': 'வ', 'w': 'வ', 'sh': 'ஷ',
    'shh': 'ஷ', 's': 'ஸ', 'h': 'ஹ', 'q': 'க', 'z': 'ஸ', 'x': 'க்ஸ', 'ksh': 'க்ஷ', 'gy': 'ஜ', 'tr': 'த்ர',
  },
  vowels: {
    'a': ('அ', ''),
    'aa': ('ஆ', 'ா'),
    'i': ('இ', 'ி'),
    'ii': ('ஈ', 'ீ'),
    'ee': ('ஈ', 'ீ'),
    'u': ('உ', 'ு'),
    'uu': ('ஊ', 'ூ'),
    'oo': ('ஊ', 'ூ'),
    'e': ('ஏ', 'ே'),
    'ae': ('எ', 'ெ'),
    'ai': ('ஐ', 'ை'),
    'o': ('ஒ', 'ொ'),
    'oa': ('ஓ', 'ோ'),
    'au': ('ஔ', 'ௌ'),
    'ou': ('ஔ', 'ௌ'),
  },
  virama: '்',
  anusvara: null,
  finalVirama: true,
  finalAaAfterConsonant: false,
  nasalAnusvara: false,
);

final IndicScheme teluguScheme = IndicScheme(
  language: 'te',
  consonants: {
    'k': 'క',
    'kh': 'ఖ',
    'g': 'గ',
    'gh': 'ఘ',
    'c': 'క',
    'ch': 'చ',
    'chh': 'ఛ',
    'j': 'జ',
    'jh': 'ఝ',
    't': 'త',
    'th': 'థ',
    'tt': 'ట',
    'tth': 'ఠ',
    'd': 'ద',
    'dh': 'ధ',
    'dd': 'డ',
    'ddh': 'ఢ',
    'n': 'న',
    'nn': 'ణ',
    'p': 'ప',
    'ph': 'ఫ',
    'f': 'ఫ',
    'b': 'బ',
    'bh': 'భ',
    'm': 'మ',
    'y': 'య',
    'r': 'ర',
    'rr': 'ఱ',
    'l': 'ల',
    'lh': 'ళ',
    'v': 'వ',
    'w': 'వ',
    'sh': 'శ',
    'shh': 'ష',
    's': 'స',
    'h': 'హ',
    'q': 'క',
    'z': 'జ',
    'x': 'క్స',
    'ksh': 'క్ష',
    'gy': 'జ్ఞ',
    'tr': 'త్ర',
  },
  vowels: {
    'a': ('అ', ''),
    'aa': ('ఆ', 'ా'),
    'i': ('ఇ', 'ి'),
    'ii': ('ఈ', 'ీ'),
    'ee': ('ఈ', 'ీ'),
    'u': ('ఉ', 'ు'),
    'uu': ('ఊ', 'ూ'),
    'oo': ('ఊ', 'ూ'),
    'ri': ('ఋ', 'ృ'),
    'e': ('ఏ', 'ే'),
    'ae': ('ఎ', 'ె'),
    'ai': ('ఐ', 'ై'),
    'o': ('ఒ', 'ొ'),
    'oa': ('ఓ', 'ో'),
    'au': ('ఔ', 'ౌ'),
    'ou': ('ఔ', 'ౌ'),
  },
  virama: '్',
  anusvara: 'ం',
  finalVirama: true,
  finalAaAfterConsonant: true,
  nasalAnusvara: true,
);

/// The scheme for an Indic language id, or null when it has none.
IndicScheme? schemeFor(String language) => switch (language) {
  'hi' => hindiScheme,
  'mr' => marathiScheme,
  'bn' => bengaliScheme,
  'ta' => tamilScheme,
  'te' => teluguScheme,
  _ => null,
};
