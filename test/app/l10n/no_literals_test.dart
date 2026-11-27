// SPDX-License-Identifier: GPL-3.0-or-later
//
// Scans the settings app sources for user-visible English written as a literal (Text('...'),
// title: '...', tooltip: '...' and similar). Strings belong in lib/l10n/app_en.arb. The allow-list is
// short on purpose: numbers, units and native language names, which are never translated.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Places where a user sees text. The literal that follows is checked.
final _sink = RegExp(
  r'\b(Text|title|subtitle|label|tooltip|hintText|labelText|helperText|errorText|valueText|'
  r'semanticLabel|semanticsLabel|message|content|placeholder|description|_message|_show|_snack|_info)'
  r"\s*[:(]\s*(?:const\s+)?(?:Text\(\s*)?'((?:[^'\\\n]|\\.)*)'",
  multiLine: true,
);

/// Literals that may stay in English: the app name, and native names of languages.
const _allowed = {'BooBoard', '中文 (Chinese)', '日本語 (Japanese)'};

/// Files that are not the settings app's own screens: the Chinese and Japanese screens (agents A
/// and B write them in English), the mascot (agent E), and the localisation glue itself.
bool _excluded(String path) =>
    path.contains('/chinese/') ||
    path.contains('/japanese/') ||
    path.endsWith('booboard_mascot.dart') ||
    path.endsWith('/l10n.dart');

void main() {
  test('no user-visible English literal is left in lib/src/app', () {
    final problems = <String>[];
    final files = Directory('lib/src/app')
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('.dart'))
        .where((f) => !_excluded(f.path.replaceAll('\\', '/')));
    for (final file in files) {
      final text = file.readAsStringSync();
      for (final m in _sink.allMatches(text)) {
        final literal = m.group(2)!;
        // Interpolations such as "#${hexOf(c)}" are values, not words: only the text around them counts.
        final words = literal.replaceAll(RegExp(r'\$\{[^}]*\}|\$\w+'), '');
        // Numbers, symbols and one-letter units ("%", "x" for a zoom factor) may stay as they are.
        if (!RegExp('[A-Za-z]{2,}').hasMatch(words)) continue;
        if (_allowed.contains(literal)) continue;
        final line = '\n'.allMatches(text.substring(0, m.start)).length + 1;
        problems.add('${file.path.replaceAll('\\', '/')}:$line  ${m.group(1)} "$literal"');
      }
    }
    expect(problems, isEmpty, reason: problems.join('\n'));
  });
}
