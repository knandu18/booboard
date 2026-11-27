// SPDX-License-Identifier: GPL-3.0-or-later
//
// Word boundaries for swipe-to-delete. Same rule as the controller's backspace word delete: skip
// spaces, then take a run of word characters or a run of punctuation. Offsets are UTF-16 units.
const int _maxSpaceCode = 0x20;

final RegExp _wordChar = RegExp(r"[\p{L}\p{N}_'’]", unicode: true);

bool _isSpaceUnit(int c) => c <= _maxSpaceCode || (c == 0xA0) || (c == 0x3000) || (c == 0x200B);

bool _isWordUnit(int c) => _wordChar.hasMatch(String.fromCharCode(c));

/// The offset where the [words]th whole word before [end] starts, in [text]. With no words it is [end].
/// Stops at the start of [text] when there are fewer words than asked for.
int wordStartBefore(String text, int end, int words) {
  var i = end.clamp(0, text.length);
  for (var n = 0; n < words && i > 0; n++) {
    while (i > 0 && _isSpaceUnit(text.codeUnitAt(i - 1))) {
      i--;
    }
    if (i == 0) break;
    final wordy = _isWordUnit(text.codeUnitAt(i - 1));
    while (i > 0 && !_isSpaceUnit(text.codeUnitAt(i - 1)) && _isWordUnit(text.codeUnitAt(i - 1)) == wordy) {
      i--;
    }
  }
  return i;
}
