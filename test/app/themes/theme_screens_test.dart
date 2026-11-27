// SPDX-License-Identifier: GPL-3.0-or-later
//
// Gallery and editor widgets: selecting a preset writes the theme id, the appearance controls work,
// deleting a selected custom theme falls back, and the editor's preview, save and discard flows work.
// Custom themes and layouts are read for real, so the tests wait outside the fake clock.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mocktail/mocktail.dart';
import 'package:booboard/src/app/l10n.dart';
import 'package:booboard/src/app/app_services.dart';
import 'package:booboard/src/app/themes/theme_editor_screen.dart';
import 'package:booboard/src/app/themes/theme_gallery_screen.dart';
import 'package:booboard/src/bridge/messages.g.dart';
import 'package:booboard/src/core/secure_blob_store.dart';
import 'package:booboard/src/keyboard/preview/keyboard_preview.dart';
import 'package:booboard/src/settings/booboard_settings.dart';
import 'package:booboard/src/settings/settings_store.dart';
import 'package:booboard/src/theme/custom/custom_theme_store.dart';
import 'package:booboard/src/theme/presets.dart';
import 'package:booboard/src/theme/theme_spec.dart';

import '../../theme/theme_test_support.dart';

class _MockPlatform extends Mock implements PlatformHostApi {}

class _MockApp extends Mock implements AppHostApi {}

const String _uuid = '1b4e28ba-2fa1-41d2-883f-0016d3cca427';

late Directory _dataDir;
late _MockPlatform _platform;
late AppServices _services;

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 30; i++) {
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 10)));
    await tester.pump(const Duration(milliseconds: 100));
  }
}

void _setUpServices({List<int>? palettes}) {
  _dataDir = Directory.systemTemp.createTempSync('booboard_theme_screens_');
  _platform = _MockPlatform();
  when(() => _platform.getDataDirectory()).thenAnswer((_) async => _dataDir.path);
  when(() => _platform.getSystemColors())
      .thenAnswer((_) async => palettes == null ? null : SystemColorsMessage(palettes: palettes, isNightMode: false));
  _services = AppServices(
    settings: SettingsStore.memory(),
    secureStore: InMemorySecureBlobStore(),
    platform: _platform,
    app: _MockApp(),
  );
}

void _tearDownServices() {
  if (_dataDir.existsSync()) _dataDir.deleteSync(recursive: true);
}

/// A tall viewport, so the sections are built (sliver lists only build what is near the screen).
void _tallView(WidgetTester tester) {
  tester.view.physicalSize = const Size(800, 3200);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

Future<void> _pumpGallery(WidgetTester tester) async {
  _tallView(tester);
  await tester.pumpWidget(
    AppScope(
      services: _services,
      child: const MaterialApp(localizationsDelegates: booboardLocalizationsDelegates, home: ThemeGalleryScreen()),
    ),
  );
  await _settle(tester);
}

/// Opens the editor from a button, so that saving and leaving pop a real route.
Future<void> _pumpEditor(WidgetTester tester, {String? themeId}) async {
  _tallView(tester);
  await tester.pumpWidget(
    AppScope(
      services: _services,
      child: MaterialApp(
        localizationsDelegates: booboardLocalizationsDelegates,
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: FilledButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => AppScope(
                      services: _services,
                      child: ThemeEditorScreen(themeId: themeId),
                    ),
                  ),
                ),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('open'));
  await _settle(tester);
}

void main() {
  group('theme gallery', () {
    setUp(() => _setUpServices());
    tearDown(_tearDownServices);

    testWidgets('shows the presets, My themes and the Create card', (tester) async {
      await _pumpGallery(tester);
      // The carousel builds the cards near the viewport, so the first three are checked.
      for (final preset in ThemePresets.all.take(3)) {
        expect(find.text(preset.name), findsWidgets, reason: preset.name);
      }
      expect(find.text('My themes'), findsOneWidget);
      expect(find.text('Create theme'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('tapping a preset writes its id', (tester) async {
      await _pumpGallery(tester);
      // Taps the card's InkWell directly: the label sits under a neighbouring card's hit area in the carousel.
      final card = tester.widget<InkWell>(
        find.ancestor(of: find.text(ThemePresets.limeGlass.name), matching: find.byType(InkWell)).first,
      );
      card.onTap!();
      await _settle(tester);
      expect(_services.settings.value.appearance.themeId, ThemePresets.limeGlass.id);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('real taps reach the cards: a preset selects, Create opens the editor', (tester) async {
      // CarouselView covers its items with an InkWell unless enableSplash is false; on a device the
      // cards then never saw a tap. These taps go through hit testing like a finger.
      await _pumpGallery(tester);
      final second = ThemePresets.limeGlass;
      await tester.tap(find.text(second.name).first);
      await _settle(tester);
      expect(_services.settings.value.appearance.themeId, second.id);

      await tester.ensureVisible(find.text('Create theme'));
      await _settle(tester);
      await tester.tap(find.text('Create theme'));
      await _settle(tester);
      expect(find.byType(ThemeEditorScreen), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('a glass theme hides dark mode and pure black; contrast stays', (tester) async {
      await _pumpGallery(tester);
      expect(_services.settings.value.appearance.themeId, ThemePresets.darkGlass.id);
      expect(find.text('Dark'), findsNothing);
      expect(find.text('Pure black'), findsNothing);
      expect(find.text('High'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('dark mode, pure black and contrast write the appearance', (tester) async {
      await tester.runAsync(
        () => _services.settings.update(
          (s) => s.copyWith(appearance: s.appearance.copyWith(themeId: ThemePresets.oceanBlue.id)),
          sections: ['appearance'],
        ),
      );
      await _pumpGallery(tester);
      await tester.tap(find.text('Dark'));
      await _settle(tester);
      expect(_services.settings.value.appearance.darkMode, DarkModePreference.dark);

      await tester.tap(find.text('Pure black'));
      await _settle(tester);
      expect(_services.settings.value.appearance.pureBlack, isTrue);

      await tester.tap(find.text('High'));
      await _settle(tester);
      expect(_services.settings.value.appearance.contrast, ContrastPreference.high);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('the wallpaper note stays hidden for Oceanblue, even with system colours', (tester) async {
      await _pumpGallery(tester);
      expect(find.text('Oceanblue follows your wallpaper'), findsNothing);
      await tester.pumpWidget(const SizedBox());

      _tearDownServices();
      _setUpServices(palettes: syntheticPalettes());
      await _pumpGallery(tester);
      expect(find.text('Oceanblue follows your wallpaper'), findsNothing);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('deleting the selected custom theme asks first and falls back to the default theme', (tester) async {
      final id = CustomThemeIds.idFor(_uuid);
      final store = CustomThemeStore('${_dataDir.path}/themes');
      await tester.runAsync(() => store.write(ThemeSpec(id: id, name: 'Saved look')));
      await tester.runAsync(
        () => _services.settings.update(
          (c) => c.copyWith(appearance: c.appearance.copyWith(themeId: id)),
          sections: const ['appearance'],
        ),
      );

      await _pumpGallery(tester);
      expect(find.text('Saved look'), findsWidgets);

      final menu = find.ancestor(
        of: find.byTooltip('Options for Saved look'),
        matching: find.byWidgetPredicate((w) => w is PopupMenuButton),
      );
      tester.state<PopupMenuButtonState<dynamic>>(menu).showButtonMenu();
      await _settle(tester);
      await tester.tap(find.text('Delete'));
      await _settle(tester);
      expect(find.text('Delete "Saved look"?'), findsOneWidget);

      await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
      await _settle(tester);
      expect(File('${_dataDir.path}/themes/$_uuid.json').existsSync(), isFalse);
      expect(_services.settings.value.appearance.themeId, ThemePresets.defaultPreset.id);
      await tester.pumpWidget(const SizedBox());
    });
  });

  group('theme editor', () {
    setUp(() => _setUpServices());
    tearDown(_tearDownServices);

    testWidgets('changing the seed colour updates the pinned preview', (tester) async {
      final semantics = tester.ensureSemantics();
      await _pumpEditor(tester);
      final before = tester.widget<KeyboardPreview>(find.byType(KeyboardPreview)).theme.letterKey.fill;

      await tester.tap(find.bySemanticsLabel('#D6336C'));
      await _settle(tester);
      final after = tester.widget<KeyboardPreview>(find.byType(KeyboardPreview)).theme.letterKey.fill;
      expect(after, isNot(before));
      await tester.pumpWidget(const SizedBox());
      semantics.dispose();
    });

    testWidgets('saving writes the theme file, selects it and bumps the revision', (tester) async {
      await _pumpEditor(tester);
      expect(find.text('New theme'), findsOneWidget);

      await tester.enterText(find.byType(TextField).first, 'Ocean test');
      await tester.pump(const Duration(milliseconds: 100));
      await tester.tap(find.widgetWithText(FilledButton, 'Save'));
      await _settle(tester);

      final files = Directory('${_dataDir.path}/themes')
          .listSync()
          .whereType<File>()
          .where((f) => f.path.endsWith('.json'));
      expect(files, hasLength(1));
      final saved = await tester.runAsync(() => CustomThemeStore('${_dataDir.path}/themes').list()) ?? const [];
      expect(saved.single.name, 'Ocean test');

      final appearance = _services.settings.value.appearance;
      expect(appearance.themeId, startsWith('custom:'));
      expect(appearance.customThemeRevision, 1);
      expect(find.text('New theme'), findsNothing, reason: 'the editor closes after saving');
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('leaving with unsaved changes asks first, and Keep editing stays', (tester) async {
      await _pumpEditor(tester);
      await tester.enterText(find.byType(TextField).first, 'Half done');
      await tester.pump(const Duration(milliseconds: 100));

      await tester.state<NavigatorState>(find.byType(Navigator)).maybePop();
      await _settle(tester);
      expect(find.text('Discard changes?'), findsOneWidget);

      await tester.tap(find.text('Keep editing'));
      await _settle(tester);
      expect(find.text('New theme'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('editing an existing theme loads its name', (tester) async {
      final store = CustomThemeStore('${_dataDir.path}/themes');
      await tester.runAsync(() => store.write(ThemeSpec(id: CustomThemeIds.idFor(_uuid), name: 'Stored one')));
      await _settle(tester);

      await _pumpEditor(tester, themeId: CustomThemeIds.idFor(_uuid));
      expect(find.text('Edit theme'), findsOneWidget);
      expect(tester.widget<TextField>(find.byType(TextField).first).controller!.text, 'Stored one');
      await tester.pumpWidget(const SizedBox());
    });
  });
}
