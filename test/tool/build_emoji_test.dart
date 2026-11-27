// SPDX-License-Identifier: GPL-3.0-or-later
//
// Tests for tool/build_emoji.dart: emoji-test parsing, skin-tone grouping, ZWJ sequences and
// CLDR annotation merging, on tiny fixtures (no network).
import 'package:flutter_test/flutter_test.dart';

import '../../tool/build_emoji.dart';

const String _emojiTest = '''
# emoji-test.txt
# Version: 18.0
# group: Smileys & Emotion
# subgroup: face-smiling
1F600                                   ; fully-qualified     # 😀 E1.0 grinning face
1F600                                   ; minimally-qualified # 😀 E1.0 grinning face
# group: People & Body
# subgroup: hand-fingers-open
1F44B                                   ; fully-qualified     # 👋 E0.6 waving hand
1F44B 1F3FB                             ; fully-qualified     # 👋🏻 E1.0 waving hand: light skin tone
1F44B 1F3FD                             ; fully-qualified     # 👋🏽 E1.0 waving hand: medium skin tone
1F590 FE0F                              ; fully-qualified     # 🖐️ E0.7 hand with fingers splayed
1F590 1F3FB                             ; fully-qualified     # 🖐🏻 E1.0 hand with fingers splayed: light skin tone
1F469 200D 2764 FE0F 200D 1F468         ; fully-qualified     # 👩‍❤️‍👨 E1.0 couple with heart: woman, man
1F469 1F3FB 200D 2764 FE0F 200D 1F468 1F3FC ; fully-qualified # 👩🏻‍❤️‍👨🏼 E1.0 couple with heart: woman, man, light skin tone, medium-light skin tone
# group: Component
# subgroup: skin-tone
1F3FB                                   ; component           # 🏻 E1.0 light skin tone
1F3FB                                   ; fully-qualified     # 🏻 E1.0 light skin tone
# group: Flags
# subgroup: flag
1F1E6 1F1FA                             ; fully-qualified     # 🇦🇺 E2.0 flag: Australia
''';

void main() {
  group('parseEmojiTest', () {
    test('keeps fully-qualified lines with group, subgroup, version and English name', () {
      final lines = parseEmojiTest(_emojiTest);
      final grinning = lines.firstWhere((l) => l.name == 'grinning face');
      expect(grinning.text, '😀');
      expect(grinning.version, 10);
      expect(grinning.group, 'Smileys & Emotion');
      expect(grinning.subgroup, 'face-smiling');
      // The minimally-qualified duplicate is skipped.
      expect(lines.where((l) => l.text == '😀'), hasLength(1));
    });

    test('reads Emoji 15.1 style versions as 151 and keeps flags as ZWJ-free sequences', () {
      final flag = parseEmojiTest(_emojiTest).firstWhere((l) => l.name == 'flag: Australia');
      expect(flag.codepoints, [0x1F1E6, 0x1F1FA]);
      expect(flag.version, 20);
      final fixture = parseEmojiTest('# group: X\n# subgroup: y\n1F600 ; fully-qualified # 😀 E15.1 grinning face\n');
      expect(fixture.single.version, 151);
    });
  });

  group('skin tones', () {
    test('counts one modifier as its tone, none as 0 and couples as -1', () {
      expect(skinToneIndex([0x1F44B]), 0);
      expect(skinToneIndex([0x1F44B, 0x1F3FD]), 3);
      expect(skinToneIndex([0x1F469, 0x1F3FB, 0x200D, 0x1F468, 0x1F3FC]), -1);
    });

    test('groups variants under their base and drops the Component group', () {
      final catalog = buildCatalog(parseEmojiTest(_emojiTest), unicodeVersion: '18.0');
      final wave = catalog.items.firstWhere((i) => i.name == 'waving hand');
      expect(wave.text, '👋');
      expect(wave.tones, ['👋🏻', null, '👋🏽', null, null]);
      expect(catalog.items.where((i) => i.name.endsWith(': light skin tone')), isEmpty);
      expect(catalog.items.where((i) => i.text == '🏻'), isEmpty);
      expect(catalog.groups, ['Smileys & Emotion', 'People & Body', 'Flags']);
      expect(catalog.orphanVariants, 0);
    });

    test('matches a base written with U+FE0F to its variants', () {
      final catalog = buildCatalog(parseEmojiTest(_emojiTest), unicodeVersion: '18.0');
      final splayed = catalog.items.firstWhere((i) => i.name == 'hand with fingers splayed');
      expect(splayed.tones!.first, '🖐🏻');
    });

    test('couples with two tones stay as items of their own', () {
      final catalog = buildCatalog(parseEmojiTest(_emojiTest), unicodeVersion: '18.0');
      final couples = catalog.items.where((i) => i.name.startsWith('couple with heart')).toList();
      expect(couples, hasLength(2));
      expect(couples.every((c) => c.tones == null), isTrue);
    });

    test('ref index maps base to item * 6 and each tone to item * 6 + tone', () {
      final catalog = buildCatalog(parseEmojiTest(_emojiTest), unicodeVersion: '18.0');
      final refs = buildRefIndex(catalog.items);
      final wave = catalog.items.indexWhere((i) => i.name == 'waving hand');
      expect(refs['👋'], wave * refStride);
      expect(refs['👋🏽'], wave * refStride + 3);
      expect(refs['🖐'], isNotNull, reason: 'U+FE0F is ignored in the index');
    });
  });

  group('CLDR annotations', () {
    const annotations = '''
<ldml>
  <annotations>
    <annotation cp="😀">cheerful | grin | grinning face &amp; teeth</annotation>
    <annotation cp="😀" type="tts">grinning face</annotation>
    <annotation cp="👋🏻">hand | wave</annotation>
    <annotation cp="🖐">hand | splayed</annotation>
    <annotation cp="🏻" type="tts">light skin tone</annotation>
    <annotation cp="🚫">no entry</annotation>
  </annotations>
</ldml>
''';
    const derived = '''
<ldml><annotations>
  <annotation cp="👋🏻">light skin tone | light</annotation>
</annotations></ldml>
''';

    test('keywords are lower-cased, split on bars and expanded word by word', () {
      final catalog = buildCatalog(parseEmojiTest(_emojiTest), unicodeVersion: '18.0');
      final refs = buildRefIndex(catalog.items);
      final index = buildKeywords(lang: 'en', annotations: annotations, refs: refs);
      final grin = refs['😀']!;
      expect(index.keys['cheerful'], contains(grin));
      expect(index.keys['grinning face'], contains(grin));
      expect(index.keys['grinning'], contains(grin), reason: 'phrase words are indexed');
      expect(index.keys['teeth'], contains(grin));
      expect(index.keys['grinning face & teeth'], contains(grin), reason: 'the whole phrase is a key too');
      expect(index.shortNames[grin], 'grinning face');
    });

    test('derived annotations add tone keywords, and unknown characters are skipped', () {
      final catalog = buildCatalog(parseEmojiTest(_emojiTest), unicodeVersion: '18.0');
      final refs = buildRefIndex(catalog.items);
      final index = buildKeywords(lang: 'en', annotations: annotations, derived: derived, refs: refs);
      final lightWave = refs['👋🏻']!;
      expect(index.keys['light'], contains(lightWave));
      expect(index.keys['light'], isNot(contains(refs['👋']!)), reason: 'tone keywords stay on the tone');
      expect(index.keys.containsKey('no entry'), isFalse, reason: 'U+1F6AB is not in the test emoji list');
    });

    test('text format stores refs as base-36 deltas', () {
      const lines = '''
<ldml><annotations>
  <annotation cp="😀">zeta | alpha</annotation>
  <annotation cp="🖐">alpha</annotation>
</annotations></ldml>
''';
      final catalog = buildCatalog(parseEmojiTest(_emojiTest), unicodeVersion: '18.0');
      final refs = buildRefIndex(catalog.items);
      final text = buildKeywords(lang: 'en', annotations: lines, refs: refs).toText();
      final alphaRefs = [refs['😀']!, refs['🖐']!]..sort();
      final encoded = (alphaRefs[1] - alphaRefs[0]).toRadixString(36);
      final keyLine = text.split('\n').firstWhere((l) => l.startsWith('alpha\t'));
      expect(keyLine, 'alpha\t${alphaRefs[0].toRadixString(36)} $encoded');
      expect(text.startsWith('[short]\n'), isTrue);
      expect(text.contains('[keys]\n'), isTrue);
    });
  });
}
