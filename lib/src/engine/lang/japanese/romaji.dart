// SPDX-License-Identifier: GPL-3.0-or-later
//
// OWNER: Wave 4-B (Japanese). Romaji to kana for the QWERTY romaji layout ("nihongo" → にほんご).
// Written for this project from the common Hepburn and Kunrei spellings; no table is copied.
//
// Rules: "kya" → きゃ, "tt" → っ (and "tchi" → っち), "nn" and "n'" → ん, "n" before a consonant
// → ん, "-" → ー. Letters that do not yet form a kana stay pending (shown raw) until they do.

/// Romaji syllables to kana. Every prefix of a key (other than a key itself) waits for more input.
const Map<String, String> romajiTable = {
  // vowels
  'a': 'あ', 'i': 'い', 'u': 'う', 'e': 'え', 'o': 'お',
  // k, g
  'ka': 'か', 'ki': 'き', 'ku': 'く', 'ke': 'け', 'ko': 'こ',
  'kya': 'きゃ', 'kyi': 'きぃ', 'kyu': 'きゅ', 'kye': 'きぇ', 'kyo': 'きょ',
  'ga': 'が', 'gi': 'ぎ', 'gu': 'ぐ', 'ge': 'げ', 'go': 'ご',
  'gya': 'ぎゃ', 'gyi': 'ぎぃ', 'gyu': 'ぎゅ', 'gye': 'ぎぇ', 'gyo': 'ぎょ',
  // s, z
  'sa': 'さ', 'si': 'し', 'shi': 'し', 'su': 'す', 'se': 'せ', 'so': 'そ',
  'sha': 'しゃ', 'shu': 'しゅ', 'she': 'しぇ', 'sho': 'しょ',
  'sya': 'しゃ', 'syu': 'しゅ', 'sye': 'しぇ', 'syo': 'しょ', 'syi': 'しぃ',
  'za': 'ざ', 'zi': 'じ', 'ji': 'じ', 'zu': 'ず', 'ze': 'ぜ', 'zo': 'ぞ',
  'ja': 'じゃ', 'ju': 'じゅ', 'je': 'じぇ', 'jo': 'じょ',
  'jya': 'じゃ', 'jyu': 'じゅ', 'jye': 'じぇ', 'jyo': 'じょ',
  'zya': 'じゃ', 'zyu': 'じゅ', 'zyo': 'じょ',
  // t, d
  'ta': 'た', 'ti': 'ち', 'chi': 'ち', 'tu': 'つ', 'tsu': 'つ', 'te': 'て', 'to': 'と',
  'cha': 'ちゃ', 'chu': 'ちゅ', 'che': 'ちぇ', 'cho': 'ちょ',
  'cya': 'ちゃ', 'cyu': 'ちゅ', 'cye': 'ちぇ', 'cyo': 'ちょ',
  'tya': 'ちゃ', 'tyu': 'ちゅ', 'tye': 'ちぇ', 'tyo': 'ちょ',
  'tsa': 'つぁ', 'tsi': 'つぃ', 'tse': 'つぇ', 'tso': 'つぉ',
  'da': 'だ', 'di': 'ぢ', 'du': 'づ', 'de': 'で', 'do': 'ど',
  'dya': 'ぢゃ', 'dyu': 'ぢゅ', 'dye': 'ぢぇ', 'dyo': 'ぢょ',
  // n
  'na': 'な', 'ni': 'に', 'nu': 'ぬ', 'ne': 'ね', 'no': 'の',
  'nya': 'にゃ', 'nyu': 'にゅ', 'nye': 'にぇ', 'nyo': 'にょ',
  // h, f, b, p
  'ha': 'は', 'hi': 'ひ', 'hu': 'ふ', 'fu': 'ふ', 'he': 'へ', 'ho': 'ほ',
  'hya': 'ひゃ', 'hyu': 'ひゅ', 'hye': 'ひぇ', 'hyo': 'ひょ',
  'fa': 'ふぁ', 'fi': 'ふぃ', 'fe': 'ふぇ', 'fo': 'ふぉ',
  'ba': 'ば', 'bi': 'び', 'bu': 'ぶ', 'be': 'べ', 'bo': 'ぼ',
  'bya': 'びゃ', 'byu': 'びゅ', 'bye': 'びぇ', 'byo': 'びょ',
  'pa': 'ぱ', 'pi': 'ぴ', 'pu': 'ぷ', 'pe': 'ぺ', 'po': 'ぽ',
  'pya': 'ぴゃ', 'pyu': 'ぴゅ', 'pye': 'ぴぇ', 'pyo': 'ぴょ',
  // m, y, r, w
  'ma': 'ま', 'mi': 'み', 'mu': 'む', 'me': 'め', 'mo': 'も',
  'mya': 'みゃ', 'myu': 'みゅ', 'mye': 'みぇ', 'myo': 'みょ',
  'ya': 'や', 'yu': 'ゆ', 'yo': 'よ',
  'ra': 'ら', 'ri': 'り', 'ru': 'る', 're': 'れ', 'ro': 'ろ',
  'rya': 'りゃ', 'ryu': 'りゅ', 'rye': 'りぇ', 'ryo': 'りょ',
  'wa': 'わ', 'wi': 'うぃ', 'we': 'うぇ', 'wo': 'を',
  // v
  'va': 'ゔぁ', 'vi': 'ゔぃ', 'vu': 'ゔ', 've': 'ゔぇ', 'vo': 'ゔぉ',
  // small kana
  'xa': 'ぁ', 'xi': 'ぃ', 'xu': 'ぅ', 'xe': 'ぇ', 'xo': 'ぉ',
  'la': 'ぁ', 'li': 'ぃ', 'lu': 'ぅ', 'le': 'ぇ', 'lo': 'ぉ',
  'xya': 'ゃ', 'xyu': 'ゅ', 'xyo': 'ょ', 'lya': 'ゃ', 'lyu': 'ゅ', 'lyo': 'ょ',
  'xwa': 'ゎ', 'lwa': 'ゎ', 'xtu': 'っ', 'ltu': 'っ', 'xtsu': 'っ', 'ltsu': 'っ',
};

/// The syllabic n.
const String _nKana = 'ん';

/// Consonants a doubled consonant can start a sokuon (っ) from. "n" is excluded: it is ん.
const String _consonants = 'bcdfghjklmpqrstvwxyz';

final Set<String> _prefixes = () {
  final p = <String>{};
  for (final key in romajiTable.keys) {
    for (var i = 1; i < key.length; i++) {
      p.add(key.substring(0, i));
    }
  }
  return p;
}();

/// Turns romaji letters into kana one key at a time. [kana] is the finished part, [pending] the raw
/// letters still waiting for a vowel or consonant.
class RomajiInput {
  String kana = '';
  String pending = '';

  bool get isEmpty => kana.isEmpty && pending.isEmpty;

  /// Feeds one lowercase ASCII letter, or "'" or "-".
  void add(String ch) {
    if (ch == '-') {
      flush();
      kana += 'ー';
      return;
    }
    if (ch == "'") {
      if (pending == 'n' || pending == 'nn') {
        kana += _nKana;
        pending = '';
      } else {
        flush();
      }
      return;
    }
    _feed(ch);
  }

  void _feed(String ch) {
    if (pending == 'nn') {
      // The first n is ん; the second one starts the next syllable (konnichi → こんにち).
      kana += _nKana;
      pending = 'n';
    }
    if (pending == 'n' && ch == 'n') {
      pending = 'nn';
      return;
    }
    if (pending == 'n' && !'aiueoy'.contains(ch)) {
      kana += _nKana;
      pending = '';
    }
    if (pending.length == 1 && _consonants.contains(pending) && (ch == pending || (pending == 't' && ch == 'c'))) {
      kana += 'っ';
      pending = ch;
      return;
    }
    final p = pending + ch;
    final hit = romajiTable[p];
    if (hit != null) {
      kana += hit;
      pending = '';
      return;
    }
    if (_prefixes.contains(p)) {
      pending = p;
      return;
    }
    // Not a romaji spelling: keep the letters as typed so nothing is lost, and start again.
    kana += pending;
    pending = '';
    final again = romajiTable[ch];
    if (again != null) {
      kana += again;
    } else if (_prefixes.contains(ch)) {
      pending = ch;
    } else {
      kana += ch;
    }
  }

  /// Ends the pending letters: a lone "n" becomes ん, other letters stay as typed.
  void flush() {
    if (pending == 'n' || pending == 'nn') {
      kana += _nKana;
    } else {
      kana += pending;
    }
    pending = '';
  }

  /// Removes the last letter the user typed: a pending letter first, then the last kana.
  void backspace() {
    if (pending.isNotEmpty) {
      pending = pending.substring(0, pending.length - 1);
    } else if (kana.isNotEmpty) {
      kana = kana.substring(0, kana.length - 1);
    }
  }

  /// What is shown while typing: the kana and the pending letters.
  String get text => kana + pending;

  void clear() {
    kana = '';
    pending = '';
  }
}
