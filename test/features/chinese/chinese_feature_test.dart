// SPDX-License-Identifier: GPL-3.0-or-later
import 'package:flutter_test/flutter_test.dart';
import 'package:booboard/src/core/input_field_info.dart';
import 'package:booboard/src/engine/lang/chinese/pinyin_composer.dart';
import 'package:booboard/src/engine/lang/chinese/s2twp.dart';
import 'package:booboard/src/engine/lang/chinese/zh_lexicon.dart';
import 'package:booboard/src/features/chinese/chinese_feature.dart';
import 'package:booboard/src/keyboard/keyboard_app.dart';
import 'package:booboard/src/keyboard/keyboard_session.dart';
import 'package:booboard/src/settings/booboard_settings.dart';

import '../../engine/lang/chinese/zh_fixture.dart';
import '../../keyboard/support/app_harness.dart';

const BooBoardSettings _zh = BooBoardSettings(
  languages: LanguageSettings(enabled: ['zh', 'en'], active: 'zh'),
);

ZhLoaded _fixturePack() => ZhLoaded(
  dictionary: fixtureDictionary(),
  converter: S2twpConverter.parse(fixtureTsv),
  pack: const ZhPackInfo(id: 'dict-zh-fixture', name: 'Fixture', sizeBytes: 1),
);

class _Probe extends KeyboardFeature {
  KeyboardSession? session;

  @override
  KeyboardHooks attach(KeyboardSession s) {
    session = s;
    return const KeyboardHooks();
  }
}

/// Lets an async pack load finish: a real zero-delay turn, then a frame.
Future<void> _settle(WidgetTester tester) async {
  await tester.runAsync(() => Future<void>.delayed(Duration.zero));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 20));
}

void main() {
  testWidgets('with Chinese active and a pack, letters compose and the best candidate is offered', (tester) async {
    final h = AppHarness(settings: _zh);
    final probe = _Probe();
    await h.pump(
      tester,
      features: [
        probe,
        ChineseFeature(loader: () async => _fixturePack()),
      ],
    );
    await h.focus(tester);
    await _settle(tester);
    final s = probe.session!;
    expect(s.input.composer.value, isA<PinyinComposer>());
    for (final ch in 'nihao'.split('')) {
      s.input.onText(ch);
    }
    await tester.pump();
    expect(s.input.composerState.value.candidates.first.text, '你好');
    expect(s.input.composerState.value.reading, "ni'hao");
  });

  testWidgets('no composer in password fields', (tester) async {
    final h = AppHarness(settings: _zh);
    final probe = _Probe();
    await h.pump(
      tester,
      features: [
        probe,
        ChineseFeature(loader: () async => _fixturePack()),
      ],
    );
    await h.focus(tester, editorInfo(inputType: AndroidInputType.classText | AndroidInputType.textVariationPassword));
    await _settle(tester);
    expect(probe.session!.input.composerActive, isFalse);
  });

  testWidgets('without a pack, the composer stays off and a chip points at model packs', (tester) async {
    final h = AppHarness(settings: _zh);
    final probe = _Probe();
    await h.pump(
      tester,
      features: [
        probe,
        ChineseFeature(loader: () async => null),
      ],
    );
    await h.focus(tester);
    await _settle(tester);
    final s = probe.session!;
    expect(s.input.composer.value, isNull);
    expect(s.stripChips.value.map((c) => c.id), contains(ChineseFeature.packChipId));
    for (final ch in 'ni'.split('')) {
      s.input.onText(ch);
    }
    await tester.pump();
    expect(s.input.composerState.value.isEmpty, isTrue, reason: 'no composer: letters are not composed');
    expect(h.editor.text, 'ni', reason: 'letters type as English');
  });

  testWidgets('switching to English removes the composer and its chip', (tester) async {
    final h = AppHarness(settings: _zh);
    final probe = _Probe();
    await h.pump(
      tester,
      features: [
        probe,
        ChineseFeature(loader: () async => _fixturePack()),
      ],
    );
    await h.focus(tester);
    await _settle(tester);
    final s = probe.session!;
    expect(s.input.composer.value, isNotNull);
    await s.switchLanguage('en');
    await tester.pump();
    expect(s.input.composer.value, isNull);
  });
}
