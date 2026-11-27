// SPDX-License-Identifier: GPL-3.0-or-later
//
// OWNER: Wave 4-B (Japanese). Kana tools: hiragana and katakana, full-width ASCII, the 12-key
// multi-tap groups (あ→い→う→え→お) and the dakuten / handakuten / small-kana cycles.
// Pure Dart, no state.

/// Hiragana (ぁ..ゖ, ゝゞ) to katakana. Other characters are unchanged.
String toKatakana(String s) {
  final out = StringBuffer();
  for (final r in s.runes) {
    out.writeCharCode(isHiragana(r) ? r + 0x60 : r);
  }
  return out.toString();
}

/// ASCII letters, digits and symbols to their full-width forms (ＡＢＣ１２３). A space becomes U+3000.
String toFullWidthAscii(String s) {
  final out = StringBuffer();
  for (final r in s.runes) {
    if (r == 0x20) {
      out.writeCharCode(0x3000);
    } else if (r >= 0x21 && r <= 0x7E) {
      out.writeCharCode(r + 0xFEE0);
    } else {
      out.writeCharCode(r);
    }
  }
  return out.toString();
}

/// True for hiragana code points: ぁ (U+3041) to ゖ (U+3096), and ゝゞ.
bool isHiragana(int r) => (r >= 0x3041 && r <= 0x3096) || r == 0x309D || r == 0x309E;

/// True for a character a kana key can type: hiragana or the long vowel mark ー.
bool isKanaInput(int r) => isHiragana(r) || r == 0x30FC;

/// 12-key multi-tap order for each key's centre kana, matching the flick directions of
/// `kana12_ja.json` (centre, left, up, right, down). Tapping the centre again within a second
/// steps through the list. Keys not listed here do not cycle.
const Map<String, List<String>> kanaTapCycles = {
  'あ': ['あ', 'い', 'う', 'え', 'お'],
  'か': ['か', 'き', 'く', 'け', 'こ'],
  'さ': ['さ', 'し', 'す', 'せ', 'そ'],
  'た': ['た', 'ち', 'つ', 'て', 'と'],
  'な': ['な', 'に', 'ぬ', 'ね', 'の'],
  'は': ['は', 'ひ', 'ふ', 'へ', 'ほ'],
  'ま': ['ま', 'み', 'む', 'め', 'も'],
  'や': ['や', 'ゆ', 'よ'],
  'ら': ['ら', 'り', 'る', 'れ', 'ろ'],
  'わ': ['わ', 'を', 'ん', 'ー'],
};

/// The dakuten, handakuten and small-kana cycles that `kana_modifier` (゛゜小) steps through.
/// Each row is one cycle: pressing the key moves to the next form and wraps around.
const List<List<String>> kanaModifierCycles = [
  ['か', 'が'],
  ['き', 'ぎ'],
  ['く', 'ぐ'],
  ['け', 'げ'],
  ['こ', 'ご'],
  ['さ', 'ざ'],
  ['し', 'じ'],
  ['す', 'ず'],
  ['せ', 'ぜ'],
  ['そ', 'ぞ'],
  ['た', 'だ'],
  ['ち', 'ぢ'],
  ['つ', 'っ', 'づ'],
  ['て', 'で'],
  ['と', 'ど'],
  ['は', 'ば', 'ぱ'],
  ['ひ', 'び', 'ぴ'],
  ['ふ', 'ぶ', 'ぷ'],
  ['へ', 'べ', 'ぺ'],
  ['ほ', 'ぼ', 'ぽ'],
  ['う', 'ゔ'],
  ['あ', 'ぁ'],
  ['い', 'ぃ'],
  ['う', 'ぅ'],
  ['え', 'ぇ'],
  ['お', 'ぉ'],
  ['や', 'ゃ'],
  ['ゆ', 'ゅ'],
  ['よ', 'ょ'],
  ['わ', 'ゎ'],
];

final Map<String, (List<String>, int)> _modifierIndex = () {
  final m = <String, (List<String>, int)>{};
  for (final group in kanaModifierCycles) {
    for (var i = 0; i < group.length; i++) {
      // A character in two groups (う) keeps the first one: 'う' → 'ゔ' before 'ぅ'.
      m.putIfAbsent(group[i], () => (group, i));
    }
  }
  return m;
}();

/// The form `kana_modifier` turns [kana] into, or null when it has no dakuten or small form.
String? nextKanaModifier(String kana) {
  final hit = _modifierIndex[kana];
  if (hit == null) return null;
  final (group, i) = hit;
  return group[(i + 1) % group.length];
}

/// The next character in the 12-key multi-tap cycle that [kana] belongs to, or null when [kana]
/// is not in one of [kanaTapCycles].
String? nextTapKana(String kana) {
  for (final group in kanaTapCycles.values) {
    final i = group.indexOf(kana);
    if (i >= 0) return group[(i + 1) % group.length];
  }
  return null;
}

/// The multi-tap cycle that starts with [centre], or null.
List<String>? tapCycleFor(String centre) => kanaTapCycles[centre];
