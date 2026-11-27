// SPDX-License-Identifier: GPL-3.0-or-later
//
// Text folding shared by the dictionary builder, the reader and the predictor.
//
// Dart has no built-in Unicode normalization, so this file carries a small
// table (generated from Unicode data) that covers the Latin letters with one
// combining accent: enough for English, Spanish, French, German, Portuguese
// and Indonesian. Other scripts pass through unchanged.

/// `precomposed:base:mark` triples in hexadecimal.
const String _kDecompositions =
    'C0:41:300,C1:41:301,C2:41:302,C3:41:303,C4:41:308,C5:41:30A,C7:43:327,C8:45:300,C9:45:301,CA:45:302,'
    'CB:45:308,CC:49:300,CD:49:301,CE:49:302,CF:49:308,D1:4E:303,D2:4F:300,D3:4F:301,D4:4F:302,D5:4F:303,'
    'D6:4F:308,D9:55:300,DA:55:301,DB:55:302,DC:55:308,DD:59:301,E0:61:300,E1:61:301,E2:61:302,E3:61:303,'
    'E4:61:308,E5:61:30A,E7:63:327,E8:65:300,E9:65:301,EA:65:302,EB:65:308,EC:69:300,ED:69:301,EE:69:302,'
    'EF:69:308,F1:6E:303,F2:6F:300,F3:6F:301,F4:6F:302,F5:6F:303,F6:6F:308,F9:75:300,FA:75:301,FB:75:302,'
    'FC:75:308,FD:79:301,FF:79:308,100:41:304,101:61:304,102:41:306,103:61:306,104:41:328,105:61:328,'
    '106:43:301,107:63:301,108:43:302,109:63:302,10A:43:307,10B:63:307,10C:43:30C,10D:63:30C,10E:44:30C,'
    '10F:64:30C,112:45:304,113:65:304,114:45:306,115:65:306,116:45:307,117:65:307,118:45:328,119:65:328,'
    '11A:45:30C,11B:65:30C,11C:47:302,11D:67:302,11E:47:306,11F:67:306,120:47:307,121:67:307,122:47:327,'
    '123:67:327,124:48:302,125:68:302,128:49:303,129:69:303,12A:49:304,12B:69:304,12C:49:306,12D:69:306,'
    '12E:49:328,12F:69:328,130:49:307,134:4A:302,135:6A:302,136:4B:327,137:6B:327,139:4C:301,13A:6C:301,'
    '13B:4C:327,13C:6C:327,13D:4C:30C,13E:6C:30C,143:4E:301,144:6E:301,145:4E:327,146:6E:327,147:4E:30C,'
    '148:6E:30C,14C:4F:304,14D:6F:304,14E:4F:306,14F:6F:306,150:4F:30B,151:6F:30B,154:52:301,155:72:301,'
    '156:52:327,157:72:327,158:52:30C,159:72:30C,15A:53:301,15B:73:301,15C:53:302,15D:73:302,15E:53:327,'
    '15F:73:327,160:53:30C,161:73:30C,162:54:327,163:74:327,164:54:30C,165:74:30C,168:55:303,169:75:303,'
    '16A:55:304,16B:75:304,16C:55:306,16D:75:306,16E:55:30A,16F:75:30A,170:55:30B,171:75:30B,172:55:328,'
    '173:75:328,174:57:302,175:77:302,176:59:302,177:79:302,178:59:308,179:5A:301,17A:7A:301,17B:5A:307,'
    '17C:7A:307,17D:5A:30C,17E:7A:30C,1A0:4F:31B,1A1:6F:31B,1AF:55:31B,1B0:75:31B,1CD:41:30C,1CE:61:30C,'
    '1CF:49:30C,1D0:69:30C,1D1:4F:30C,1D2:6F:30C,1D3:55:30C,1D4:75:30C,1E6:47:30C,1E7:67:30C,1E8:4B:30C,'
    '1E9:6B:30C,1EA:4F:328,1EB:6F:328,1F0:6A:30C,1F4:47:301,1F5:67:301,1F8:4E:300,1F9:6E:300,200:41:30F,'
    '201:61:30F,202:41:311,203:61:311,204:45:30F,205:65:30F,206:45:311,207:65:311,208:49:30F,209:69:30F,'
    '20A:49:311,20B:69:311,20C:4F:30F,20D:6F:30F,20E:4F:311,20F:6F:311,210:52:30F,211:72:30F,212:52:311,'
    '213:72:311,214:55:30F,215:75:30F,216:55:311,217:75:311,218:53:326,219:73:326,21A:54:326,21B:74:326,'
    '21E:48:30C,21F:68:30C,226:41:307,227:61:307,228:45:327,229:65:327,22E:4F:307,22F:6F:307,232:59:304,'
    '233:79:304,1E00:41:325,1E01:61:325,1E02:42:307,1E03:62:307,1E04:42:323,1E05:62:323,1E06:42:331,'
    '1E07:62:331,1E0A:44:307,1E0B:64:307,1E0C:44:323,1E0D:64:323,1E0E:44:331,1E0F:64:331,1E10:44:327,'
    '1E11:64:327,1E12:44:32D,1E13:64:32D,1E18:45:32D,1E19:65:32D,1E1A:45:330,1E1B:65:330,1E1E:46:307,'
    '1E1F:66:307,1E20:47:304,1E21:67:304,1E22:48:307,1E23:68:307,1E24:48:323,1E25:68:323,1E26:48:308,'
    '1E27:68:308,1E28:48:327,1E29:68:327,1E2A:48:32E,1E2B:68:32E,1E2C:49:330,1E2D:69:330,1E30:4B:301,'
    '1E31:6B:301,1E32:4B:323,1E33:6B:323,1E34:4B:331,1E35:6B:331,1E36:4C:323,1E37:6C:323,1E3A:4C:331,'
    '1E3B:6C:331,1E3C:4C:32D,1E3D:6C:32D,1E3E:4D:301,1E3F:6D:301,1E40:4D:307,1E41:6D:307,1E42:4D:323,'
    '1E43:6D:323,1E44:4E:307,1E45:6E:307,1E46:4E:323,1E47:6E:323,1E48:4E:331,1E49:6E:331,1E4A:4E:32D,'
    '1E4B:6E:32D,1E54:50:301,1E55:70:301,1E56:50:307,1E57:70:307,1E58:52:307,1E59:72:307,1E5A:52:323,'
    '1E5B:72:323,1E5E:52:331,1E5F:72:331,1E60:53:307,1E61:73:307,1E62:53:323,1E63:73:323,1E6A:54:307,'
    '1E6B:74:307,1E6C:54:323,1E6D:74:323,1E6E:54:331,1E6F:74:331,1E70:54:32D,1E71:74:32D,1E72:55:324,'
    '1E73:75:324,1E74:55:330,1E75:75:330,1E76:55:32D,1E77:75:32D,1E7C:56:303,1E7D:76:303,1E7E:56:323,'
    '1E7F:76:323,1E80:57:300,1E81:77:300,1E82:57:301,1E83:77:301,1E84:57:308,1E85:77:308,1E86:57:307,'
    '1E87:77:307,1E88:57:323,1E89:77:323,1E8A:58:307,1E8B:78:307,1E8C:58:308,1E8D:78:308,1E8E:59:307,'
    '1E8F:79:307,1E90:5A:302,1E91:7A:302,1E92:5A:323,1E93:7A:323,1E94:5A:331,1E95:7A:331,1E96:68:331,'
    '1E97:74:308,1E98:77:30A,1E99:79:30A,1EA0:41:323,1EA1:61:323,1EA2:41:309,1EA3:61:309,1EB8:45:323,'
    '1EB9:65:323,1EBA:45:309,1EBB:65:309,1EBC:45:303,1EBD:65:303,1EC8:49:309,1EC9:69:309,1ECA:49:323,'
    '1ECB:69:323,1ECC:4F:323,1ECD:6F:323,1ECE:4F:309,1ECF:6F:309,1EE4:55:323,1EE5:75:323,1EE6:55:309,'
    '1EE7:75:309,1EF2:59:300,1EF3:79:300,1EF4:59:323,1EF5:79:323,1EF6:59:309,1EF7:79:309,1EF8:59:303,'
    '1EF9:79:303';

/// Letters that fold to a different Latin base without a combining mark.
const Map<int, String> _kSpecialFolds = {
  0xF8: 'o', 0xD8: 'o', 0x142: 'l', 0x141: 'l', 0x111: 'd', 0x110: 'd', 0x127: 'h', 0x126: 'h', //
  0x131: 'i', 0xE6: 'ae', 0xC6: 'ae', 0x153: 'oe', 0x152: 'oe', 0xDF: 'ss',
};

final Map<int, int> _baseOf = {};
final Map<int, int> _composed = {};
bool _tablesReady = false;

void _ensureTables() {
  if (_tablesReady) return;
  for (final triple in _kDecompositions.split(',')) {
    final p = triple.split(':');
    final cp = int.parse(p[0], radix: 16);
    final base = int.parse(p[1], radix: 16);
    final mark = int.parse(p[2], radix: 16);
    _baseOf[cp] = base;
    _composed[(base << 16) | mark] = cp;
  }
  _tablesReady = true;
}

/// Base letter of a precomposed Latin letter ('é' -> 'e'), or [rune] itself.
int baseRune(int rune) {
  if (rune < 0xC0) return rune;
  _ensureTables();
  return _baseOf[rune] ?? rune;
}

bool _isCombining(int rune) => rune >= 0x300 && rune <= 0x36F;

/// Arabic harakat (U+064B..U+065F), superscript alef (U+0670) and tatweel (U+0640): dictionaries store
/// bare words, so a word typed with vowel marks still matches.
bool _isArabicMark(int rune) => (rune >= 0x64B && rune <= 0x65F) || rune == 0x670 || rune == 0x640;

/// Canonical composition for the supported Latin letters ("e" + U+0301 -> "é").
String normalizeNfc(String text) {
  var hasCombining = false;
  for (final unit in text.codeUnits) {
    if (_isCombining(unit)) {
      hasCombining = true;
      break;
    }
  }
  if (!hasCombining) return text;
  _ensureTables();
  final out = StringBuffer();
  final runes = text.runes.toList();
  for (var i = 0; i < runes.length; i++) {
    var r = runes[i];
    while (i + 1 < runes.length && _isCombining(runes[i + 1])) {
      final composed = _composed[(r << 16) | runes[i + 1]];
      if (composed == null) break;
      r = composed;
      i++;
    }
    out.writeCharCode(r);
  }
  return out.toString();
}

/// Lower-cases [text] and, with [stripAccents], maps accented Latin letters to
/// their base letters. Dictionary keys and typed words are compared in this
/// folded form.
String foldKey(String text, {bool stripAccents = true}) {
  // Apostrophe-like marks match each other: Ukrainian ʼ (U+02BC) and ’ find words written with '.
  final lower = normalizeNfc(text).toLowerCase().replaceAll('ʼ', "'").replaceAll('’', "'");
  if (!stripAccents) return lower;
  var ascii = true;
  for (final unit in lower.codeUnits) {
    if (unit >= 0xC0) {
      ascii = false;
      break;
    }
  }
  if (ascii) return lower;
  final out = StringBuffer();
  for (final r in lower.runes) {
    if (r < 0xC0) {
      out.writeCharCode(r);
    } else if (_kSpecialFolds[r] case final special?) {
      out.write(special);
    } else if (_isCombining(r) || _isArabicMark(r)) {
      continue;
    } else {
      out.writeCharCode(baseRune(r));
    }
  }
  return out.toString();
}

/// How typed text is cased relative to a dictionary word.
enum CasePattern { lower, capitalized, upper, mixed }

CasePattern casePatternOf(String text) {
  var upper = 0;
  var lower = 0;
  var firstUpper = false;
  var index = 0;
  for (final r in text.runes) {
    final ch = String.fromCharCode(r);
    final isUp = ch != ch.toLowerCase();
    final isLow = ch != ch.toUpperCase();
    if (isUp) {
      upper++;
      if (index == 0) firstUpper = true;
    } else if (isLow) {
      lower++;
    }
    index++;
  }
  if (upper == 0) return CasePattern.lower;
  if (lower == 0) return upper > 1 ? CasePattern.upper : CasePattern.capitalized;
  if (firstUpper && upper == 1) return CasePattern.capitalized;
  return CasePattern.mixed;
}

String _capitalize(String s) {
  if (s.isEmpty) return s;
  final first = String.fromCharCode(s.runes.first);
  return first.toUpperCase() + s.substring(first.length);
}

/// Re-cases dictionary word [surface] to follow how the user typed [typed]:
/// "Hello" -> capitalized, "HELLO" -> upper case, otherwise the dictionary
/// form (proper nouns keep their capital letter).
String applyCasePattern(String typed, String surface) {
  switch (casePatternOf(typed)) {
    case CasePattern.upper:
      return surface.toUpperCase();
    case CasePattern.capitalized:
      return _capitalize(surface);
    case CasePattern.lower:
    case CasePattern.mixed:
      return surface;
  }
}
