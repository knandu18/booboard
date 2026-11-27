// SPDX-License-Identifier: GPL-3.0-or-later
//
// Custom themes on disk: ids, round trip, migration, broken files, duplicate and delete, and
// resolving `custom:<uuid>` ids through resolveKeyboardTheme (revision bumps, image paths).
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:booboard/src/settings/sections/appearance_settings.dart';
import 'package:booboard/src/theme/custom/custom_theme_store.dart';
import 'package:booboard/src/theme/keyboard_theme_data.dart';
import 'package:booboard/src/theme/presets.dart';
import 'package:booboard/src/theme/theme_resolver.dart';
import 'package:booboard/src/theme/theme_spec.dart';

const String kUuid = '1b4e28ba-2fa1-41d2-883f-0016d3cca427';
const String kPhoto = '7c9e6679-7425-40de-944b-e07fc1f90ae7';

ThemeSpec _spec({String name = 'Mine', int seed = 0xFF0B79C4, ThemeBackgroundSpec? background}) => ThemeSpec(
  id: CustomThemeIds.idFor(kUuid),
  name: name,
  colorSource: ThemeColorSource.seed,
  seedColor: seed,
  background: background ?? const ThemeBackgroundSpec(),
);

void main() {
  group('ids', () {
    test('custom ids carry a well-formed uuid only', () {
      expect(CustomThemeIds.isCustom('custom:$kUuid'), isTrue);
      expect(CustomThemeIds.uuidOf('custom:$kUuid'), kUuid);
      for (final bad in [
        'custom:../../etc/passwd',
        'custom:$kUuid/../x',
        'custom:${kUuid.toUpperCase()}',
        'custom:',
        'custom:not-a-uuid',
        'booboard_gold',
        '../custom:$kUuid',
      ]) {
        expect(CustomThemeIds.uuidOf(bad), isNull, reason: bad);
      }
    });

    test('new uuids are version 4 and distinct', () {
      final a = CustomThemeIds.newUuid();
      final b = CustomThemeIds.newUuid();
      expect(a, isNot(b));
      expect(CustomThemeIds.uuidOf(CustomThemeIds.idFor(a)), a);
      expect(a[14], '4');
    });
  });

  late Directory root;
  late String themes;

  setUp(() {
    root = Directory.systemTemp.createTempSync('booboard_custom_theme_');
    themes = '${root.path}/themes';
  });

  tearDown(() {
    if (root.existsSync()) root.deleteSync(recursive: true);
  });

  group('store', () {
    test('round trip, list and atomic write', () async {
      final store = CustomThemeStore(themes);
      final spec = _spec();
      await store.write(spec);

      expect(File('$themes/$kUuid.json').existsSync(), isTrue);
      expect(File('$themes/$kUuid.json.tmp').existsSync(), isFalse);
      expect(await store.read(spec.id), spec);
      expect(await store.list(), [spec]);
    });

    test('write refuses an id that is not a custom id', () async {
      final store = CustomThemeStore(themes);
      await expectLater(store.write(ThemePresets.booboardGold), throwsArgumentError);
    });

    test('a version 0 file is migrated on read', () async {
      Directory(themes).createSync(recursive: true);
      File('$themes/$kUuid.json').writeAsStringSync(
        jsonEncode({'name': 'Old', 'radius': 0.2, 'gap': 4, 'seed': 0xFF8F6FD8, 'scheme': 'vibrant'}),
      );
      final spec = await CustomThemeStore(themes).read(CustomThemeIds.idFor(kUuid));
      expect(spec, isNotNull);
      expect(spec!.id, CustomThemeIds.idFor(kUuid));
      expect(spec.name, 'Old');
      expect(spec.keyRadius, 0.2);
      expect(spec.keyGap, 4);
      expect(spec.seedColor, 0xFF8F6FD8);
      expect(spec.variant, ThemeSchemeVariant.vibrant);
    });

    test('broken, non-object and oversized files give null, never a throw', () async {
      Directory(themes).createSync(recursive: true);
      final store = CustomThemeStore(themes);
      final id = CustomThemeIds.idFor(kUuid);

      File('$themes/$kUuid.json').writeAsStringSync('{ not json');
      expect(await store.read(id), isNull);

      File('$themes/$kUuid.json').writeAsStringSync('[1, 2, 3]');
      expect(await store.read(id), isNull);

      File('$themes/$kUuid.json').writeAsStringSync(jsonEncode({'name': 'x' * (CustomThemeStore.maxSpecBytes + 10)}));
      expect(await store.read(id), isNull);

      expect(await store.read('custom:../../secret'), isNull);
      expect(await store.list(), isEmpty);
    });

    test('a rewrite is seen even when the modified time matches', () async {
      final store = CustomThemeStore(themes);
      await store.write(_spec(seed: 0xFF0B79C4));
      expect((await store.read(CustomThemeIds.idFor(kUuid)))!.seedColor, 0xFF0B79C4);
      await store.write(_spec(seed: 0xFFD6336C));
      expect((await store.read(CustomThemeIds.idFor(kUuid)))!.seedColor, 0xFFD6336C);
    });

    test('duplicate copies the photo under a new id', () async {
      final store = CustomThemeStore(themes);
      final bytes = Uint8List.fromList(List<int>.generate(64, (i) => i));
      await store.writeImage(kPhoto, bytes);
      final source = _spec(
        background: ThemeBackgroundSpec(
          type: ThemeBackgroundType.image,
          imagePath: CustomThemeStore.imageRelativePath(kPhoto),
        ),
      );
      await store.write(source);

      final copy = await store.duplicate(source, 'Mine copy');
      expect(copy.id, isNot(source.id));
      expect(copy.name, 'Mine copy');
      final newPhoto = CustomThemeStore.photoUuidOf(copy.background.imagePath);
      expect(newPhoto, isNotNull);
      expect(newPhoto, isNot(kPhoto));
      expect(File(store.imageFileFor(newPhoto!)).readAsBytesSync(), bytes);
      expect(await store.list(), hasLength(2));
    });

    test('duplicate with a missing photo gives a solid copy', () async {
      final store = CustomThemeStore(themes);
      final source = _spec(
        background: ThemeBackgroundSpec(
          type: ThemeBackgroundType.image,
          imagePath: CustomThemeStore.imageRelativePath(kPhoto),
        ),
      );
      final copy = await store.duplicate(source, 'Copy');
      expect(copy.background.type, ThemeBackgroundType.solid);
      expect(copy.background.imagePath, isNull);
    });

    test('delete removes the spec and its photo, and tolerates missing files', () async {
      final store = CustomThemeStore(themes);
      await store.writeImage(kPhoto, Uint8List.fromList([1, 2, 3]));
      await store.write(
        _spec(
          background: ThemeBackgroundSpec(
            type: ThemeBackgroundType.image,
            imagePath: CustomThemeStore.imageRelativePath(kPhoto),
          ),
        ),
      );
      await store.delete(CustomThemeIds.idFor(kUuid));
      expect(File('$themes/$kUuid.json').existsSync(), isFalse);
      expect(File(store.imageFileFor(kPhoto)).existsSync(), isFalse);
      await store.delete(CustomThemeIds.idFor(kUuid)); // already gone
    });

    test('photo names must match images/<uuid>.png', () {
      expect(CustomThemeStore.photoUuidOf('images/$kPhoto.png'), kPhoto);
      expect(CustomThemeStore.photoUuidOf('../$kPhoto.png'), isNull);
      expect(CustomThemeStore.photoUuidOf('images/../$kPhoto.png'), isNull);
      expect(CustomThemeStore.photoUuidOf('/abs/$kPhoto.png'), isNull);
      expect(CustomThemeStore.photoUuidOf(null), isNull);
    });
  });

  group('resolution by id', () {
    test('specForId: custom ids read the file; missing, broken or malformed give the default (Dark Glass)', () async {
      await CustomThemeStore(themes).write(_spec(name: 'Saved'));
      expect(specForId('custom:$kUuid', themes).name, 'Saved');
      expect(specForId('custom:$kPhoto', themes).id, ThemePresets.defaultPreset.id);
      expect(specForId('custom:../x', themes).id, ThemePresets.defaultPreset.id);
      expect(specForId('custom:$kUuid', null).id, ThemePresets.defaultPreset.id);
      expect(specForId('lavender', themes).id, 'lavender');
    });

    test('a custom theme resolves to its own id', () async {
      await CustomThemeStore(themes).write(_spec());
      final t = resolveKeyboardTheme(
        appearance: AppearanceSettings(themeId: CustomThemeIds.idFor(kUuid)),
        systemColors: null,
        systemDark: false,
        disableAnimations: false,
        customThemesDirectory: themes,
      );
      expect(t.id, CustomThemeIds.idFor(kUuid));
    });

    test('a missing custom theme falls back to the default (Dark Glass)', () {
      final t = resolveKeyboardTheme(
        appearance: AppearanceSettings(themeId: CustomThemeIds.idFor(kUuid)),
        systemColors: null,
        systemDark: false,
        disableAnimations: false,
        customThemesDirectory: themes,
      );
      expect(t.id, ThemePresets.defaultPreset.id);
    });

    test('a revision bump re-resolves, and an edited file is picked up', () async {
      final store = CustomThemeStore(themes);
      await store.write(_spec(seed: 0xFF0B79C4));
      KeyboardThemeData resolve(int revision) => resolveKeyboardTheme(
        appearance: AppearanceSettings(themeId: CustomThemeIds.idFor(kUuid), customThemeRevision: revision),
        systemColors: null,
        systemDark: false,
        disableAnimations: false,
        customThemesDirectory: themes,
      );
      final before = resolve(0);
      expect(identical(before, resolve(0)), isTrue, reason: 'same inputs hit the cache');
      await store.write(_spec(seed: 0xFFD6336C));
      final sameRevision = resolve(0);
      expect(sameRevision.letterKey.fill, isNot(before.letterKey.fill), reason: 'the edited file is re-read');
      final bumped = resolve(1);
      expect(identical(bumped, sameRevision), isFalse);
    });

    test('a photo becomes an absolute path; a missing photo or a bad path becomes solid', () async {
      final store = CustomThemeStore(themes);
      await store.writeImage(kPhoto, Uint8List.fromList([0]));
      await store.write(
        _spec(
          background: ThemeBackgroundSpec(
            type: ThemeBackgroundType.image,
            imagePath: CustomThemeStore.imageRelativePath(kPhoto),
            dim: 0.4,
          ),
        ),
      );
      final t = resolveKeyboardTheme(
        appearance: AppearanceSettings(themeId: CustomThemeIds.idFor(kUuid)),
        systemColors: null,
        systemDark: false,
        disableAnimations: false,
        customThemesDirectory: themes,
      );
      expect(t.backgroundImagePath, isNotNull);
      expect(File(t.backgroundImagePath!).isAbsolute, isTrue);
      expect(File(t.backgroundImagePath!).existsSync(), isTrue);
      expect(t.backgroundImageDim, 0.4);

      final missing = withAbsoluteImage(
        _spec(
          background: const ThemeBackgroundSpec(type: ThemeBackgroundType.image, imagePath: 'images/$kUuid.png'),
        ),
        themes,
      );
      expect(missing.background.type, ThemeBackgroundType.solid);

      final bad = withAbsoluteImage(
        _spec(
          background: const ThemeBackgroundSpec(type: ThemeBackgroundType.image, imagePath: '../x.png'),
        ),
        themes,
      );
      expect(bad.background.type, ThemeBackgroundType.solid);
    });
  });
}
