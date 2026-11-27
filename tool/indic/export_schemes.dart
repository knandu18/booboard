// SPDX-License-Identifier: GPL-3.0-or-later
//
// OWNER: Wave 3-B. Prints the romanisation schemes (lib/src/engine/lang/indic/scheme.dart) as JSON
// for tool/indic/build_data.py, so the table builder and the app use one set of letters.
//
//   dart run tool/indic/export_schemes.dart > <scratch>/schemes.json
import 'dart:convert';

import 'package:booboard/src/engine/lang/indic/scheme.dart';

void main() {
  final out = <String, Object?>{};
  for (final lang in ['hi', 'mr', 'bn', 'ta', 'te']) {
    final s = schemeFor(lang)!;
    out[lang] = {
      'consonants': s.consonants,
      'vowels': {
        for (final e in s.vowels.entries) e.key: [e.value.$1, e.value.$2],
      },
      'virama': s.virama,
      'anusvara': s.anusvara,
    };
  }
  // ignore: avoid_print
  print(const JsonEncoder.withIndent('  ').convert(out));
}
