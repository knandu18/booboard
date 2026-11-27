// SPDX-License-Identifier: GPL-3.0-or-later
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:booboard/src/engine/learn/learned_data.dart';
import 'package:booboard/src/security/backup/backup_payload.dart';
import 'package:booboard/src/security/shortcuts_store.dart';
import 'package:booboard/src/settings/booboard_settings.dart';

Uint8List _bytes(String s) => Uint8List.fromList(utf8.encode(s));

Uint8List _learnedBlob() {
  final d = LearnedData('en')
    ..commitWord('hello', 'hello', 1000, novel: false)
    ..commitWord('world', 'world', 1000, novel: false)
    ..blocked.add('spam');
  return d.encode();
}

/// A minimal valid root document; tests change one part at a time.
Map<String, Object?> _root({Map<String, Object?>? sections, Object? format = 1, Object? createdAt}) => {
  'format': format,
  'createdAt': createdAt ?? '2026-11-21T10:00:00.000Z',
  'appVersion': '1.0.0+1',
  'sections': sections ?? <String, Object?>{},
};

/// The rule name the decoder reports, or 'ok'.
String _rule(Object root) {
  try {
    BackupPayload.decode(_bytes(jsonEncode(root)));
    return 'ok';
  } on BackupFormatException catch (e) {
    return e.rule;
  }
}

void main() {
  group('round trip', () {
    test('every section survives encode then decode', () {
      final contents = BackupContents(
        settings: BooBoardSettings(privacy: const PrivacySettings(learning: false)).toJson(),
        learned: {'learned_en': _learnedBlob()},
        shortcuts: const [PersonalShortcut(trigger: 'omw', expansion: 'on my way')],
        clipboard: const [BackupClipItem(text: 'pinned text', timestampMillis: 42)],
        emoji: _bytes('recents'),
        themes: {'ocean.json': _bytes('{"name":"Ocean"}')},
      );
      final created = DateTime.utc(2026, 11, 21, 10);
      final sealedPlain = BackupPayload(createdAt: created, appVersion: '1.0.0+1', contents: contents).encode();

      final back = BackupPayload.decode(sealedPlain);
      expect(back.createdAt, created);
      expect(back.appVersion, '1.0.0+1');
      final c = back.contents;
      expect(c.settings!['privacy'], isA<Map<dynamic, dynamic>>());
      expect(BooBoardSettings.fromJson(c.settings!).privacy.learning, isFalse);
      expect(c.learned['learned_en'], _learnedBlob());
      expect(c.shortcuts!.single.trigger, 'omw');
      expect(c.clipboard!.single.text, 'pinned text');
      expect(c.clipboard!.single.timestampMillis, 42);
      expect(c.emoji, _bytes('recents'));
      expect(c.themes['ocean.json'], _bytes('{"name":"Ocean"}'));
      expect(c.present, BackupSection.values.toSet());
    });

    test('summary counts learned words, shortcuts and themes', () {
      final back = BackupPayload.decode(
        BackupPayload(
          createdAt: DateTime.utc(2026),
          appVersion: '1',
          contents: BackupContents(
            learned: {'learned_en': _learnedBlob()},
            shortcuts: const [PersonalShortcut(trigger: 'a', expansion: 'b')],
            themes: {'a.json': _bytes('{}'), 'b.png': _bytes('x')},
          ),
        ).encode(),
      ).contents.summary();
      expect(back.learnedWords, 2);
      expect(back.learnedLanguages, 1);
      expect(back.shortcuts, 1);
      expect(back.themes, 2);
    });

    test('an absent section stays absent', () {
      final c = BackupPayload.decode(
        BackupPayload(createdAt: DateTime.utc(2026), appVersion: '1', contents: const BackupContents()).encode(),
      ).contents;
      expect(c.settings, isNull);
      expect(c.shortcuts, isNull);
      expect(c.clipboard, isNull);
      expect(c.emoji, isNull);
      expect(c.present, isEmpty);
    });
  });

  group('strict decoding', () {
    test('a valid document is accepted', () {
      expect(_rule(_root()), 'ok');
    });

    test('rejects non-JSON, a non-object root and bad headers', () {
      expect(() => BackupPayload.decode(_bytes('not json')), throwsA(isA<BackupFormatException>()));
      expect(() => BackupPayload.decode(_bytes('[]')), throwsA(isA<BackupFormatException>()));
      expect(_rule(_root(format: 2)), 'newer_format');
      expect(_rule(_root(format: '1')), 'bad_format');
      expect(_rule(_root(createdAt: 'yesterday')), 'bad_created_at');
      expect(
        _rule({
          'format': 1,
          'createdAt': '2026-11-21T10:00:00Z',
          'appVersion': 'x' * 65,
          'sections': <String, Object?>{},
        }),
        'bad_app_version',
      );
      expect(_rule({'format': 1, 'createdAt': '2026-11-21T10:00:00Z', 'appVersion': '1'}), 'bad_sections');
    });

    test('learned blob names must match learned_<language> and the name rule', () {
      final blob = base64.encode(_learnedBlob());
      expect(
        _rule(
          _root(
            sections: {
              'learned': {'learned_../etc': blob},
            },
          ),
        ),
        'bad_learned_name',
      );
      expect(
        _rule(
          _root(
            sections: {
              'learned': {'other': blob},
            },
          ),
        ),
        'bad_learned_name',
      );
      expect(
        _rule(
          _root(
            sections: {
              'learned': {'learned_EN': blob},
            },
          ),
        ),
        'bad_learned_name',
      );
      expect(
        _rule(
          _root(
            sections: {
              'learned': {'learned_en': '!!not base64!!'},
            },
          ),
        ),
        'bad_learned_blob',
      );
      expect(
        _rule(
          _root(
            sections: {
              'learned': {'learned_en': blob},
            },
          ),
        ),
        'ok',
      );
    });

    test('shortcuts: invalid, duplicate or too many entries are rejected', () {
      expect(
        _rule(
          _root(
            sections: {
              'shortcuts': [
                {'trigger': 'a b', 'expansion': 'x'},
              ],
            },
          ),
        ),
        'bad_shortcut',
      );
      expect(
        _rule(
          _root(
            sections: {
              'shortcuts': [
                {'trigger': 'omw', 'expansion': ''},
              ],
            },
          ),
        ),
        'bad_shortcut',
      );
      expect(
        _rule(
          _root(
            sections: {
              'shortcuts': [
                {'trigger': 'omw', 'expansion': 'on my way'},
                {'trigger': 'OMW', 'expansion': 'other'},
              ],
            },
          ),
        ),
        'duplicate_shortcut',
      );
      final many = [
        for (var i = 0; i < ShortcutRules.maxShortcuts + 1; i++) {'trigger': 't$i', 'expansion': 'x'},
      ];
      expect(_rule(_root(sections: {'shortcuts': many})), 'too_many_shortcuts');
    });

    test('theme names cannot escape the folder or use other extensions', () {
      final blob = base64.encode(_bytes('{}'));
      expect(
        _rule(
          _root(
            sections: {
              'themes': {'../evil.json': blob},
            },
          ),
        ),
        'bad_theme_name',
      );
      expect(
        _rule(
          _root(
            sections: {
              'themes': {'a/b.json': blob},
            },
          ),
        ),
        'bad_theme_name',
      );
      expect(
        _rule(
          _root(
            sections: {
              'themes': {'a..b.json': blob},
            },
          ),
        ),
        'bad_theme_name',
      );
      expect(
        _rule(
          _root(
            sections: {
              'themes': {'run.exe': blob},
            },
          ),
        ),
        'bad_theme_name',
      );
      expect(
        _rule(
          _root(
            sections: {
              'themes': {'ocean.json': blob},
            },
          ),
        ),
        'ok',
      );
    });

    test('size caps apply per item', () {
      final big = base64.encode(Uint8List(300 * 1024));
      expect(
        _rule(
          _root(
            sections: {
              'themes': {'big.json': big},
            },
          ),
        ),
        'bad_theme_file_too_large',
      );
      final bigEmoji = base64.encode(Uint8List(BackupLimits.maxEmojiBytes + 1));
      expect(_rule(_root(sections: {'emoji': bigEmoji})), 'bad_emoji_too_large');
    });

    test('clipboard items need text and a timestamp', () {
      expect(
        _rule(
          _root(
            sections: {
              'clipboard': [
                {'text': '', 'ts': 1},
              ],
            },
          ),
        ),
        'bad_clip',
      );
      expect(
        _rule(
          _root(
            sections: {
              'clipboard': [
                {'text': 'x'},
              ],
            },
          ),
        ),
        'bad_clip',
      );
      expect(
        _rule(
          _root(
            sections: {
              'clipboard': [
                {'text': 'x', 'ts': 1},
              ],
            },
          ),
        ),
        'ok',
      );
    });

    test('settings must be an object', () {
      expect(_rule(_root(sections: {'settings': 'nope'})), 'bad_settings');
    });

    test('a file over the import cap is refused before parsing', () {
      expect(
        () => BackupPayload.decode(Uint8List(kMaxBackupBytes + 1)),
        throwsA(isA<BackupFormatException>().having((e) => e.rule, 'rule', 'too_large')),
      );
    });
  });
}
