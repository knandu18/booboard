// SPDX-License-Identifier: GPL-3.0-or-later
//
// The Chinese screen writes the chinese section, and clearing learned phrases deletes their blob.
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:booboard/src/app/chinese/chinese_screen.dart';
import 'package:booboard/src/app/l10n.dart';
import 'package:booboard/src/engine/lang/chinese/learned_phrases.dart';
import 'package:booboard/src/settings/booboard_settings.dart';
import 'package:material_ui/material_ui.dart';

import '../support/app_fakes.dart';

Future<AppFakes> _pump(WidgetTester tester, {BooBoardSettings settings = const BooBoardSettings()}) async {
  final fakes = AppFakes(settings: settings);
  await pumpWithServices(
    tester,
    fakes.services,
    const MaterialApp(localizationsDelegates: booboardLocalizationsDelegates, home: ChineseScreen()),
  );
  return fakes;
}

void main() {
  testWidgets('the Traditional switch writes the chinese section', (tester) async {
    final fakes = await _pump(tester);
    await tapText(tester, 'Traditional characters');
    final next = capturedUpdate(fakes.store, SettingsSection.chinese)(const BooBoardSettings());
    expect(next.chinese.traditional, isTrue);
  });

  testWidgets('the fuzzy pinyin switch is on by default and writes off', (tester) async {
    final fakes = await _pump(tester);
    await tapText(tester, 'Fuzzy pinyin');
    final next = capturedUpdate(fakes.store, SettingsSection.chinese)(const BooBoardSettings());
    expect(next.chinese.fuzzyPinyin, isFalse);
  });

  testWidgets('clearing learned phrases asks first, then deletes the blob', (tester) async {
    final fakes = await _pump(tester);
    await fakes.services.secureStore.write(learnedZhBlobName, Uint8List.fromList('{"v":1,"p":{}}'.codeUnits));
    await tapText(tester, 'Clear learned phrases');
    expect(find.text('Clear learned phrases?'), findsOneWidget);
    await tapText(tester, 'Cancel');
    expect(await fakes.services.secureStore.read(learnedZhBlobName), isNotNull);

    await tapText(tester, 'Clear learned phrases');
    await tapText(tester, 'Clear');
    await tester.pumpAndSettle();
    expect(await fakes.services.secureStore.read(learnedZhBlobName), isNull);
  });
}
