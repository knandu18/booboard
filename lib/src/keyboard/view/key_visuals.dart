// SPDX-License-Identifier: GPL-3.0-or-later
//
// What each key looks like and what it is called to accessibility services.
import 'package:characters/characters.dart';
import 'package:flutter/widgets.dart' show IconData;
import 'package:material_ui/material_ui.dart' show Icons;

import '../../core/input_field_info.dart';
import '../../settings/booboard_settings.dart';
import '../input/input_controller.dart';
import '../input/keyboard_page.dart';
import '../layout/layout_model.dart';
import '../../theme/keyboard_theme_data.dart';

/// Which theme fill a key uses.
enum KeyGroup { letter, function, action, space }

/// Shift icon states: outline (off), filled (one letter), filled with a bar (caps lock).
enum ShiftGlyph { outline, filled, caps }

class KeyVisual {
  const KeyVisual({
    required this.group,
    required this.semantics,
    this.label,
    this.icon,
    this.shiftGlyph,
    this.hint,
    this.smallLabel = false,
  });

  final KeyGroup group;
  final String? label;
  final IconData? icon;
  final ShiftGlyph? shiftGlyph;
  final String? hint;

  /// Multi-character labels ("?123", ".com") use a smaller size.
  final bool smallLabel;
  final String semantics;

  KeyStyle styleOf(KeyboardThemeData theme) => switch (group) {
    KeyGroup.letter => theme.letterKey,
    KeyGroup.function => theme.functionKey,
    KeyGroup.action => theme.actionKey,
    KeyGroup.space => theme.spaceKey,
  };
}

/// Upper-cases one key label or output the way a keyboard should ("ß" becomes "ẞ").
String applyShift(String s) => s == 'ß' ? 'ẞ' : s.toUpperCase();

bool _isSingleLetter(String s) => s.characters.length == 1 && s.toLowerCase() != s.toUpperCase();

/// The text a character key commits right now.
String outputFor(KeyDef def, {required bool shifted}) {
  final out = def.output ?? def.label ?? '';
  if (!shifted) return out;
  if (def.shiftedOutput != null) return def.shiftedOutput!;
  return _isSingleLetter(out) ? applyShift(out) : out;
}

String _enterName(InputFieldInfo f) {
  if (f.enterInsertsNewline) return 'Enter';
  return switch (f.action) {
    ImeAction.search => 'Search',
    ImeAction.send => 'Send',
    ImeAction.go => 'Go',
    ImeAction.next => 'Next',
    ImeAction.done => 'Done',
    ImeAction.previous => 'Previous',
    _ => 'Enter',
  };
}

IconData enterIcon(InputFieldInfo f) {
  if (f.enterInsertsNewline) return Icons.keyboard_return;
  return switch (f.action) {
    ImeAction.search => Icons.search,
    ImeAction.send => Icons.send,
    ImeAction.go => Icons.arrow_forward,
    ImeAction.next => Icons.keyboard_tab,
    ImeAction.done => Icons.check,
    ImeAction.previous => Icons.keyboard_tab,
    _ => Icons.keyboard_return,
  };
}

const Map<String, String> _spoken = {
  ',': 'Comma',
  '.': 'Period',
  '@': 'At sign',
  '#': 'Hash',
  '\$': 'Dollar',
  '%': 'Percent',
  '&': 'Ampersand',
  '-': 'Minus',
  '+': 'Plus',
  '(': 'Open parenthesis',
  ')': 'Close parenthesis',
  '/': 'Slash',
  '*': 'Asterisk',
  '"': 'Quote',
  "'": 'Apostrophe',
  ':': 'Colon',
  ';': 'Semicolon',
  '!': 'Exclamation mark',
  '?': 'Question mark',
  '=': 'Equals',
  '_': 'Underscore',
  '<': 'Less than',
  '>': 'Greater than',
  '[': 'Open bracket',
  ']': 'Close bracket',
  '{': 'Open brace',
  '}': 'Close brace',
  '\\': 'Backslash',
  '|': 'Vertical bar',
  '~': 'Tilde',
  '^': 'Caret',
  '`': 'Backtick',
  // Currency signs.
  '€': 'Euro',
  '£': 'Pound',
  '¥': 'Yen',
  '₹': 'Rupee',
  '₩': 'Won',
  '₽': 'Ruble',
  '₺': 'Lira',
  '₪': 'Shekel',
  '₫': 'Dong',
  '¢': 'Cent',
  '₱': 'Peso',
  '₦': 'Naira',
  '₴': 'Hryvnia',
  // Other symbols and punctuation.
  '©': 'Copyright',
  '®': 'Registered',
  '™': 'Trademark',
  '°': 'Degree',
  '§': 'Section',
  '¶': 'Paragraph',
  '•': 'Bullet',
  '…': 'Ellipsis',
  '–': 'En dash',
  '—': 'Em dash',
  '−': 'Minus',
  '‘': 'Left single quote',
  '’': 'Right single quote',
  '“': 'Left double quote',
  '”': 'Right double quote',
  '«': 'Left guillemet',
  '»': 'Right guillemet',
  '¿': 'Inverted question mark',
  '¡': 'Inverted exclamation mark',
  '×': 'Times',
  '÷': 'Divided by',
  '±': 'Plus or minus',
  '≠': 'Not equal',
  '≈': 'Approximately',
  '≤': 'Less than or equal',
  '≥': 'Greater than or equal',
  '√': 'Square root',
  '∞': 'Infinity',
  'π': 'Pi',
  '¬': 'Not sign',
  '→': 'Right arrow',
  '←': 'Left arrow',
  '↑': 'Up arrow',
  '↓': 'Down arrow',
  // Scripts: Devanagari danda, Arabic punctuation.
  '।': 'Danda',
  '॥': 'Double danda',
  '،': 'Arabic comma',
  '؛': 'Arabic semicolon',
  '؟': 'Arabic question mark',
  '٪': 'Arabic percent sign',
  // CJK punctuation (Chinese and Japanese keys).
  '、': 'Comma',
  '。': 'Full stop',
  'ー': 'Long vowel mark',
  '・': 'Middle dot',
  '〜': 'Wave dash',
  '「': 'Open quote',
  '」': 'Close quote',
  '『': 'Open double quote',
  '』': 'Close double quote',
  '！': 'Exclamation mark',
  '？': 'Question mark',
  '：': 'Colon',
  '；': 'Semicolon',
  '（': 'Open parenthesis',
  '）': 'Close parenthesis',
  '，': 'Comma',
  '．': 'Full stop',
  '.com': 'Dot com',
  '‍': 'Zero width joiner',
  '‌': 'Zero width non-joiner',
};

/// Marks that are spoken by their name (a lone mark is never read as a bare dot or nothing).
/// Indic marks use the names Indian keyboard users know (halant for virama); Arabic harakat by
/// their traditional names.
const Map<int, String> _markNames = {
  0x0901: 'chandrabindu',
  0x0902: 'anusvara',
  0x0903: 'visarga',
  0x093C: 'nukta',
  0x094D: 'halant',
  0x093E: 'vowel sign aa',
  0x093F: 'vowel sign i',
  0x0940: 'vowel sign ii',
  0x0941: 'vowel sign u',
  0x0942: 'vowel sign uu',
  0x0947: 'vowel sign e',
  0x0948: 'vowel sign ai',
  0x094B: 'vowel sign o',
  0x094C: 'vowel sign au',
  0x064B: 'fathatan',
  0x064C: 'dammatan',
  0x064D: 'kasratan',
  0x064E: 'fatha',
  0x064F: 'damma',
  0x0650: 'kasra',
  0x0651: 'shadda',
  0x0652: 'sukun',
  0x0653: 'madda',
  0x0654: 'hamza above',
  0x0655: 'hamza below',
  0x0670: 'superscript alef',
  0x0640: 'tatweel',
};

/// Code point ranges of combining marks in the scripts BooBoard types (Latin accents, Indic vowel
/// signs and viramas, Arabic harakat). Used only to avoid speaking an unnamed mark as a lone glyph.
const List<(int, int)> _combiningRanges = [
  (0x0300, 0x036F),
  (0x0483, 0x0489),
  (0x0591, 0x05BD),
  (0x0610, 0x061A),
  (0x064B, 0x065F),
  (0x0670, 0x0670),
  (0x06D6, 0x06ED),
  (0x0900, 0x0903),
  (0x093A, 0x094F),
  (0x0951, 0x0957),
  (0x0962, 0x0963),
  (0x0981, 0x0983),
  (0x09BC, 0x09CD),
  (0x0A01, 0x0A03),
  (0x0A3C, 0x0A51),
  (0x0A81, 0x0A83),
  (0x0ABC, 0x0ACD),
  (0x0B01, 0x0B03),
  (0x0B3C, 0x0B4D),
  (0x0B82, 0x0B82),
  (0x0BBE, 0x0BCD),
  (0x0C00, 0x0C04),
  (0x0C3E, 0x0C56),
  (0x0CBC, 0x0CCD),
  (0x0D00, 0x0D03),
  (0x0D3B, 0x0D4D),
  (0x0DCA, 0x0DDF),
];

bool _isCombiningMark(int rune) {
  for (final (lo, hi) in _combiningRanges) {
    if (rune >= lo && rune <= hi) return true;
  }
  return false;
}

/// What TalkBack says for [text]: a name from the table, or the text itself. A lone combining
/// mark is spoken by name, or as "combining mark" when it has none.
String spokenName(String text) {
  final named = _spoken[text];
  if (named != null) return named;
  if (text.runes.length == 1) {
    final rune = text.runes.first;
    final mark = _markNames[rune];
    if (mark != null) return mark;
    if (_isCombiningMark(rune)) return 'combining mark';
  }
  return text;
}

/// Invisible format characters get a visible label (popups would otherwise show an empty cell).
const Map<String, String> _formatLabels = {'‍': 'ZWJ', '‌': 'ZWNJ'};

/// What a popup cell shows for [item]; the item itself is what gets typed.
String displayLabel(String item) => _formatLabels[item] ?? item;

KeyVisual resolveKeyVisual(
  KeyDef def, {
  required ShiftState shift,
  required KeyboardPage page,
  required InputFieldInfo field,
  required TypingSettings typing,
  required bool showHints,
  String? spaceLabel,
}) {
  final commitsShifted = shift != ShiftState.off && page == KeyboardPage.letters;
  final shifted = commitsShifted && !typing.lowercaseLabels;
  String? hintFor() => (showHints && typing.hintLabels) ? def.hint : null;

  switch (def.type) {
    case KeyType.character:
    case KeyType.comma:
    case KeyType.period:
      final base = def.label ?? def.output ?? '';
      final out = def.output ?? base;
      String label;
      if (def.type == KeyType.character && shifted) {
        label = def.shiftedLabel ?? def.shiftedOutput ?? (_isSingleLetter(base) ? applyShift(base) : base);
      } else {
        label = base;
      }
      return KeyVisual(
        group: KeyGroup.letter,
        label: label,
        hint: hintFor(),
        smallLabel: label.characters.length > 1,
        // Speak what the key commits now: InScript shift layers use shiftedOutput (not upper case), and
        // lowercase labels change only the label, not what is typed.
        semantics:
            def.spoken ?? spokenName(def.type == KeyType.character ? outputFor(def, shifted: commitsShifted) : out),
      );
    case KeyType.shift:
      return KeyVisual(
        group: KeyGroup.function,
        shiftGlyph: switch (shift) {
          ShiftState.off => ShiftGlyph.outline,
          ShiftState.once => ShiftGlyph.filled,
          ShiftState.caps => ShiftGlyph.caps,
        },
        semantics: switch (shift) {
          ShiftState.off => 'Shift, off',
          ShiftState.once => 'Shift, on',
          ShiftState.caps => 'Shift, caps lock on',
        },
      );
    case KeyType.backspace:
      return const KeyVisual(group: KeyGroup.function, icon: Icons.backspace_outlined, semantics: 'Delete');
    case KeyType.enter:
      return KeyVisual(group: KeyGroup.action, icon: enterIcon(field), semantics: _enterName(field));
    case KeyType.space:
      if (spaceLabel == null || spaceLabel.isEmpty) return const KeyVisual(group: KeyGroup.space, semantics: 'Space');
      return KeyVisual(group: KeyGroup.space, label: spaceLabel, smallLabel: true, semantics: 'Space, $spaceLabel');
    case KeyType.symbols:
      return KeyVisual(group: KeyGroup.function, label: def.label ?? '?123', smallLabel: true, semantics: 'Symbols');
    case KeyType.moreSymbols:
      return KeyVisual(
        group: KeyGroup.function,
        label: def.label ?? '=\\<',
        smallLabel: true,
        semantics: 'More symbols',
      );
    case KeyType.alphabet:
      return KeyVisual(group: KeyGroup.function, label: def.label ?? 'ABC', smallLabel: true, semantics: 'Letters');
    case KeyType.numbers:
      return KeyVisual(group: KeyGroup.function, label: def.label ?? '123', smallLabel: true, semantics: 'Numbers');
    case KeyType.globe:
      return const KeyVisual(group: KeyGroup.function, icon: Icons.language, semantics: 'Switch language');
    case KeyType.emoji:
      return const KeyVisual(group: KeyGroup.function, icon: Icons.emoji_emotions_outlined, semantics: 'Emoji');
    case KeyType.voice:
      return const KeyVisual(group: KeyGroup.function, icon: Icons.mic_none, semantics: 'Voice typing');
    case KeyType.clipboard:
      return const KeyVisual(group: KeyGroup.function, icon: Icons.content_paste, semantics: 'Clipboard');
    case KeyType.settings:
      return const KeyVisual(group: KeyGroup.function, icon: Icons.settings_outlined, semantics: 'Settings');
    case KeyType.tab:
      return const KeyVisual(group: KeyGroup.function, icon: Icons.keyboard_tab, semantics: 'Tab');
    case KeyType.cursorLeft:
      return const KeyVisual(group: KeyGroup.function, icon: Icons.chevron_left, semantics: 'Cursor left');
    case KeyType.cursorRight:
      return const KeyVisual(group: KeyGroup.function, icon: Icons.chevron_right, semantics: 'Cursor right');
    case KeyType.custom:
      return KeyVisual(group: KeyGroup.function, label: def.label, semantics: def.spoken ?? def.label ?? 'Key');
  }
}
