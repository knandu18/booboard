// SPDX-License-Identifier: GPL-3.0-or-later
//
// Writes the InScript layouts: assets/layouts/inscript_{hi,mr,bn,ta,te}.json.
// OWNER: orchestrator (Wave 4 setup). Replaces the InScript part of tool/indic/make_layouts.py.
//
//   dart run tool/indic/make_inscript.dart [--check]
//
// Source of the key tables: the BIS InScript standard (IS 13194), as transcribed in
// xkeyboard-config `symbols/in` (layouts "deva", "ben_inscript", "tam", "tel"; MIT licence), checked
// against the Devanagari chart. Each PC key keeps its BIS position and its two levels (unshifted,
// shifted). A phone has 11 columns, not the 12/11/10 keys plus number row of a PC, so:
//   * row 1 = PC keys Q..[ (AD01..AD11), row 2 = A..' (AC01..AC11), in BIS order;
//   * row 3 = Shift, the Z..M and / keys the script uses, the nukta/ञ key (AD12), Backspace;
//   * characters whose PC key has no phone key (the number-row levels, the comma/period shift levels,
//     backslash, grave, rare letters) go into long-press popups on the closest key, listed below.
// Nukta letters use the NFC (decomposed) sequences, like the dictionaries: ड़ = ड + ़.
//
// With --check nothing is written; the exit code is 1 if a file differs from what would be written.
import 'dart:convert';
import 'dart:io';

const zwnj = '‌';
const zwj = '‍';

/// PC key -> [unshifted, shifted]; null = no character on that level.
typedef KeyTable = Map<String, List<String?>>;

/// Devanagari InScript (Hindi, Marathi). xkb "deva".
const KeyTable deva = {
  'TLDE': ['ॊ', 'ऒ'],
  'AE01': [null, 'ऍ'],
  'AE02': [null, 'ॅ'],
  'AE11': [null, 'ः'],
  'AE12': ['ृ', 'ऋ'],
  'BKSL': ['ॉ', 'ऑ'],
  'AD01': ['ौ', 'औ'],
  'AD02': ['ै', 'ऐ'],
  'AD03': ['ा', 'आ'],
  'AD04': ['ी', 'ई'],
  'AD05': ['ू', 'ऊ'],
  'AD06': ['ब', 'भ'],
  'AD07': ['ह', 'ङ'],
  'AD08': ['ग', 'घ'],
  'AD09': ['द', 'ध'],
  'AD10': ['ज', 'झ'],
  'AD11': ['ड', 'ढ'],
  'AD12': ['़', 'ञ'],
  'AC01': ['ो', 'ओ'],
  'AC02': ['े', 'ए'],
  'AC03': ['्', 'अ'],
  'AC04': ['ि', 'इ'],
  'AC05': ['ु', 'उ'],
  'AC06': ['प', 'फ'],
  'AC07': ['र', 'ऱ'],
  'AC08': ['क', 'ख'],
  'AC09': ['त', 'थ'],
  'AC10': ['च', 'छ'],
  'AC11': ['ट', 'ठ'],
  'AB01': ['ॆ', 'ऎ'],
  'AB02': ['ं', 'ँ'],
  'AB03': ['म', 'ण'],
  'AB04': ['न', 'ऩ'],
  'AB05': ['व', 'ऴ'],
  'AB06': ['ल', 'ळ'],
  'AB07': ['स', 'श'],
  'AB08': [',', 'ष'],
  'AB09': ['.', '।'],
  'AB10': ['य', 'य़'],
};

/// Bengali InScript. xkb "ben_inscript" (ZWJ/ZWNJ on the grave key; the virama popup has them).
const KeyTable beng = {
  'AE11': [null, 'ঃ'],
  'AE12': ['ৃ', 'ঋ'],
  'AD01': ['ৌ', 'ঔ'],
  'AD02': ['ৈ', 'ঐ'],
  'AD03': ['া', 'আ'],
  'AD04': ['ী', 'ঈ'],
  'AD05': ['ূ', 'ঊ'],
  'AD06': ['ব', 'ভ'],
  'AD07': ['হ', 'ঙ'],
  'AD08': ['গ', 'ঘ'],
  'AD09': ['দ', 'ধ'],
  'AD10': ['জ', 'ঝ'],
  'AD11': ['ড', 'ঢ'],
  'AD12': ['়', 'ঞ'],
  'AC01': ['ো', 'ও'],
  'AC02': ['ে', 'এ'],
  'AC03': ['্', 'অ'],
  'AC04': ['ি', 'ই'],
  'AC05': ['ু', 'উ'],
  'AC06': ['প', 'ফ'],
  'AC07': ['র', 'ঢ়'],
  'AC08': ['ক', 'খ'],
  'AC09': ['ত', 'থ'],
  'AC10': ['চ', 'ছ'],
  'AC11': ['ট', 'ঠ'],
  'AB01': ['ৎ', null],
  'AB02': ['ং', 'ঁ'],
  'AB03': ['ম', 'ণ'],
  'AB04': ['ন', null],
  'AB05': ['ব', null],
  'AB06': ['ল', null],
  'AB07': ['স', 'শ'],
  'AB08': [',', 'ষ'],
  'AB09': ['.', '।'],
  'AB10': ['য়', 'য'],
};

/// Tamil InScript. xkb "tam" (Tamil has no letters on several Devanagari keys).
const KeyTable taml = {
  'TLDE': ['ொ', 'ஒ'],
  'AE11': [null, 'ஃ'],
  'AD01': ['ௌ', 'ஔ'],
  'AD02': ['ை', 'ஐ'],
  'AD03': ['ா', 'ஆ'],
  'AD04': ['ீ', 'ஈ'],
  'AD05': ['ூ', 'ஊ'],
  'AD07': ['ஹ', 'ங'],
  'AD10': ['ஜ', null],
  'AD12': ['ஞ', null],
  'AC01': ['ோ', 'ஓ'],
  'AC02': ['ே', 'ஏ'],
  'AC03': ['்', 'அ'],
  'AC04': ['ி', 'இ'],
  'AC05': ['ு', 'உ'],
  'AC06': ['ப', null],
  'AC07': ['ர', 'ற'],
  'AC08': ['க', null],
  'AC09': ['த', null],
  'AC10': ['ச', null],
  'AC11': ['ட', null],
  'AB01': ['ெ', 'எ'],
  'AB02': ['ஂ', null],
  'AB03': ['ம', 'ண'],
  'AB04': ['ந', 'ன'],
  'AB05': ['வ', 'ழ'],
  'AB06': ['ல', 'ள'],
  'AB07': ['ஸ', 'ஶ'],
  'AB08': [',', 'ஷ'],
  'AB09': ['.', null],
  'AB10': ['ய', null],
};

/// Telugu InScript. xkb "tel" (visarga is unshifted on the minus key).
const KeyTable telu = {
  'TLDE': ['ొ', 'ఒ'],
  'AE11': ['ః', null],
  'AE12': ['ృ', 'ఋ'],
  'AD01': ['ౌ', 'ఔ'],
  'AD02': ['ై', 'ఐ'],
  'AD03': ['ా', 'ఆ'],
  'AD04': ['ీ', 'ఈ'],
  'AD05': ['ూ', 'ఊ'],
  'AD06': ['బ', 'భ'],
  'AD07': ['హ', 'ఙ'],
  'AD08': ['గ', 'ఘ'],
  'AD09': ['ద', 'ధ'],
  'AD10': ['జ', 'ఝ'],
  'AD11': ['డ', 'ఢ'],
  'AD12': ['ఞ', null],
  'AC01': ['ో', 'ఓ'],
  'AC02': ['ే', 'ఏ'],
  'AC03': ['్', 'అ'],
  'AC04': ['ి', 'ఇ'],
  'AC05': ['ు', 'ఉ'],
  'AC06': ['ప', 'ఫ'],
  'AC07': ['ర', 'ఱ'],
  'AC08': ['క', 'ఖ'],
  'AC09': ['త', 'థ'],
  'AC10': ['చ', 'ఛ'],
  'AC11': ['ట', 'ఠ'],
  'AB01': ['ె', 'ఎ'],
  'AB02': ['ం', 'ఁ'],
  'AB03': ['మ', 'ణ'],
  'AB04': ['న', null],
  'AB05': ['వ', null],
  'AB06': ['ల', 'ళ'],
  'AB07': ['స', 'శ'],
  'AB08': [',', 'ష'],
  'AB09': ['.', null],
  'AB10': ['య', null],
};

/// How one language's InScript layout is placed on the phone.
class InscriptSpec {
  const InscriptSpec({
    required this.lang,
    required this.script,
    required this.table,
    required this.row1,
    required this.row3,
    required this.popups,
    required this.danda,
  });

  final String lang;
  final String script;
  final KeyTable table;

  /// PC keys on phone row 1 (row 2 is always AC01..AC11).
  final List<String> row1;

  /// PC keys on phone row 3, between Shift and Backspace.
  final List<String> row3;

  /// PC key -> long-press characters (the characters without a phone key of their own).
  final Map<String, List<String>> popups;

  /// The danda and double danda lead the period key's popup.
  final bool danda;
}

const _ad = ['AD01', 'AD02', 'AD03', 'AD04', 'AD05', 'AD06', 'AD07', 'AD08', 'AD09', 'AD10', 'AD11'];
const _ac = ['AC01', 'AC02', 'AC03', 'AC04', 'AC05', 'AC06', 'AC07', 'AC08', 'AC09', 'AC10', 'AC11'];

/// Devanagari popups, shared by Hindi and Marathi. BIS puts the conjuncts ्र र् ज्ञ त्र क्ष श्र on the
/// shifted number row (#$%^&*); here they sit on their letters.
Map<String, List<String>> _devaPopups({required bool marathi}) => {
  'AC01': ['ॊ', 'ऒ'], // grave key
  'AC02': ['ॆ', 'ऎ'], // Z key (short e, for Dravidian words)
  'AD03': [if (marathi) 'ॲ', 'ॉ', 'ऑ', 'ॅ', 'ऍ'], // backslash key and the 1/2 shift levels
  'AC03': [zwnj, zwj, 'ऽ'],
  'AC07': ['ृ', 'ऋ', '्र', 'र्'], // = key, and the 3/4 shift levels
  'AB02': ['ः', 'ॐ'], // minus shift level; om
  'AB07': ['ष', 'श्र'], // comma shift level; 8 shift level
  'AC08': ['क्ष'],
  'AD10': ['ज्ञ'],
  'AC09': ['त्र'],
  'AD11': ['ड़', 'ढ़'],
};

final List<InscriptSpec> specs = [
  for (final lang in ['hi', 'mr'])
    InscriptSpec(
      lang: lang,
      script: 'Deva',
      table: deva,
      row1: _ad,
      row3: const ['AB02', 'AB03', 'AB04', 'AB05', 'AB06', 'AB07', 'AB10', 'AD12'],
      popups: _devaPopups(marathi: lang == 'mr'),
      danda: true,
    ),
  const InscriptSpec(
    lang: 'bn',
    script: 'Beng',
    table: beng,
    row1: _ad,
    // AB05 is a second ব (Bengali has one letter for ba and va); it is left out.
    row3: ['AB01', 'AB02', 'AB03', 'AB04', 'AB06', 'AB07', 'AB10', 'AD12'],
    popups: {
      'AC03': [zwnj, zwj, 'ঽ'],
      'AC07': ['ৃ', 'ঋ'],
      'AB02': ['ঃ'],
      'AB07': ['ষ'],
      'AC08': ['ক্ষ'],
      'AD10': ['জ্ঞ'],
      'AD11': ['ড়', 'ঢ়'],
    },
    danda: true,
  ),
  const InscriptSpec(
    lang: 'ta',
    script: 'Taml',
    table: taml,
    // Tamil has no letters on AD06/AD08/AD09/AD11; aytham (minus shift level) joins row 1.
    row1: ['AD01', 'AD02', 'AD03', 'AD04', 'AD05', 'AD07', 'AD10', 'AD12', 'AE11'],
    // ஷ is the comma key's shift level; it is common enough for a key of its own.
    row3: ['AB01', 'AB03', 'AB04', 'AB05', 'AB06', 'AB07', 'AB08', 'AB10'],
    popups: {
      'AC01': ['ொ', 'ஒ'],
      'AC03': [zwnj, zwj],
      'AB03': ['ஂ'],
      'AB07': ['ஸ்ரீ'],
      'AC08': ['க்ஷ'],
    },
    danda: false,
  ),
  const InscriptSpec(
    lang: 'te',
    script: 'Telu',
    table: telu,
    row1: _ad,
    row3: ['AB01', 'AB02', 'AB03', 'AB04', 'AB05', 'AB06', 'AB07', 'AB10'],
    popups: {
      'AC01': ['ొ', 'ఒ'],
      'AC03': [zwnj, zwj, 'ఽ'],
      'AC07': ['ృ', 'ఋ'],
      'AB02': ['ః'],
      'AB07': ['ష'],
      'AC08': ['క్ష'],
      'AD10': ['ఞ', 'జ్ఞ'],
    },
    danda: false,
  ),
];

/// The phone keys of [spec]'s letter rows, in order, as PC key ids (for tests).
List<List<String>> letterRows(InscriptSpec spec) => [spec.row1, _ac, spec.row3];

Map<String, Object?> _letter(InscriptSpec spec, String pcKey, {double width = 1.0}) {
  // A key placed only for its shift level (Tamil AE11 aytham, AB08 ssa) types that character.
  final levels = spec.table[pcKey]!;
  final unshifted = levels[0];
  final shiftLevelOnly = unshifted == null || unshifted == ',' || unshifted == '.';
  final base = shiftLevelOnly ? levels[1]! : unshifted;
  final shifted = shiftLevelOnly ? null : levels[1];
  return {'output': base, 'shiftedOutput': ?shifted, 'popup': ?spec.popups[pcKey], if (width != 1.0) 'width': width};
}

const _punct = [',', '?', '!', "'", '"', ':', ';', '-', '(', ')', '@', '#'];

/// The JSON layout for [spec].
Map<String, Object?> buildLayout(InscriptSpec spec) {
  // Every row is 11 units wide. A 9-key row 1 (Tamil) gets wider keys.
  final row1Width = spec.row1.length == 11 ? 1.0 : 1.2;
  final row1Padding = (11 - row1Width * spec.row1.length) / 2;
  return {
    'id': 'inscript_${spec.lang}',
    'name': 'InScript',
    'script': spec.script,
    'direction': 'ltr',
    'rows': [
      {
        if (row1Padding > 0.0001) 'padding': double.parse(row1Padding.toStringAsFixed(4)),
        'keys': [for (final k in spec.row1) _letter(spec, k, width: row1Width)],
      },
      {
        'keys': [for (final k in _ac) _letter(spec, k)],
      },
      {
        'keys': [
          {'type': 'shift', 'width': 1.5},
          for (final k in spec.row3) _letter(spec, k),
          {'type': 'backspace', 'width': 1.5},
        ],
      },
      {
        'keys': [
          {'type': 'symbols', 'label': '?123', 'width': 1.5},
          {'type': 'emoji', 'width': 1},
          {'type': 'comma', 'output': ','},
          {'type': 'space', 'width': 5},
          {
            'type': 'period',
            'output': '.',
            'popup': [
              if (spec.danda) ...['।', '॥'],
              ..._punct,
            ],
          },
          {'type': 'enter', 'width': 1.5},
        ],
      },
    ],
  };
}

String encodeLayout(Map<String, Object?> layout) => '${const JsonEncoder.withIndent(' ').convert(layout)}\n';

void main(List<String> args) {
  final check = args.contains('--check');
  var differs = false;
  for (final spec in specs) {
    final file = File('assets/layouts/inscript_${spec.lang}.json');
    final text = encodeLayout(buildLayout(spec));
    if (check) {
      final same = file.existsSync() && file.readAsStringSync() == text;
      differs |= !same;
      stdout.writeln('${file.path}: ${same ? 'up to date' : 'differs'}');
    } else {
      file.writeAsStringSync(text);
      stdout.writeln('wrote ${file.path}');
    }
  }
  if (differs) exitCode = 1;
}
