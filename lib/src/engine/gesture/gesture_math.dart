// SPDX-License-Identifier: GPL-3.0-or-later
//
// Pure geometry helpers for the swipe decoder (no Flutter, runs in the
// background isolate): arc-length resampling and word-to-key folding.
import 'dart:math' as math;
import 'dart:typed_data';

/// Every gesture and every word template is resampled to this many points.
const int kGesturePoints = 64;

/// Resamples the polyline `(xs[i], ys[i])` for `i < n` into [count] points that
/// are equidistant along the arc length. Writes into [outX]/[outY] and returns
/// the total arc length of the input.
double resamplePolyline(Float64List xs, Float64List ys, int n, int count, Float64List outX, Float64List outY) {
  if (n <= 0) {
    for (var k = 0; k < count; k++) {
      outX[k] = 0;
      outY[k] = 0;
    }
    return 0;
  }
  var total = 0.0;
  for (var i = 1; i < n; i++) {
    total += math.sqrt(_sq(xs[i] - xs[i - 1]) + _sq(ys[i] - ys[i - 1]));
  }
  if (n == 1 || total <= 1e-9) {
    for (var k = 0; k < count; k++) {
      outX[k] = xs[0];
      outY[k] = ys[0];
    }
    return 0;
  }
  final step = total / (count - 1);
  outX[0] = xs[0];
  outY[0] = ys[0];
  var seg = 0;
  var segStart = 0.0;
  var segLen = math.sqrt(_sq(xs[1] - xs[0]) + _sq(ys[1] - ys[0]));
  for (var k = 1; k < count - 1; k++) {
    final target = step * k;
    while (seg < n - 2 && segStart + segLen < target) {
      segStart += segLen;
      seg++;
      segLen = math.sqrt(_sq(xs[seg + 1] - xs[seg]) + _sq(ys[seg + 1] - ys[seg]));
    }
    var t = segLen > 0 ? (target - segStart) / segLen : 0.0;
    if (t < 0) t = 0;
    if (t > 1) t = 1;
    outX[k] = xs[seg] + (xs[seg + 1] - xs[seg]) * t;
    outY[k] = ys[seg] + (ys[seg + 1] - ys[seg]) * t;
  }
  outX[count - 1] = xs[n - 1];
  outY[count - 1] = ys[n - 1];
  return total;
}

double _sq(double v) => v * v;

/// Characters that never have a key of their own on the swipe path: a word
/// like "don't" is swiped as "dont".
bool isPathIgnorable(int rune) {
  switch (rune) {
    case 0x27: // '
    case 0x2019: // right single quote
    case 0x2018: // left single quote
    case 0x2BC: // modifier letter apostrophe
    case 0x60: // `
    case 0x2D: // -
    case 0x2010: // hyphen
    case 0x2011: // non-breaking hyphen
    case 0x2E: // .
    case 0x640: // Arabic tatweel
      return true;
  }
  // Arabic harakat and superscript alef.
  return (rune >= 0x64B && rune <= 0x65F) || rune == 0x670;
}

/// Maps an accented or variant letter to the base letter that sits on the
/// key (é -> e, ß -> s). Letters without a mapping return themselves.
int foldToBaseRune(int rune) => _baseRune[rune] ?? rune;

final Map<int, int> _baseRune = _buildBaseRuneTable();

Map<int, int> _buildBaseRuneTable() {
  const groups = <String, String>{
    'a': 'àáâãäåāăąǎǻạảấầẩẫậắằẳẵặæ',
    'c': 'çćĉċč',
    'd': 'ďđ',
    'e': 'èéêëēĕėęěẽẹẻếềểễệ',
    'g': 'ĝğġģ',
    'h': 'ĥħ',
    'i': 'ìíîïĩīĭįıǐịỉ',
    'j': 'ĵ',
    'k': 'ķ',
    'l': 'ĺļľŀł',
    'n': 'ñńņňŉ',
    'o': 'òóôõöøōŏőǒọỏốồổỗộớờởỡợœ',
    'r': 'ŕŗř',
    's': 'śŝşšșß',
    't': 'ţťŧț',
    'u': 'ùúûüũūŭůűųǔụủứừửữự',
    'w': 'ŵ',
    'y': 'ýÿŷỳỵỷỹ',
    'z': 'źżž',
    // Cyrillic
    'е': 'ё',
    'г': 'ґ',
    // Arabic
    'ا': 'أإآٱ',
    'ه': 'ة',
    'ي': 'ى',
  };
  final table = <int, int>{};
  groups.forEach((base, variants) {
    final b = base.runes.first;
    for (final r in variants.runes) {
      table[r] = b;
    }
  });
  return table;
}
