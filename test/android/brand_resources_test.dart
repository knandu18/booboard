// SPDX-License-Identifier: GPL-3.0-or-later
//
// The brand's Android resources: launcher PNG sizes, adaptive icon layers, the Android 12+ splash and
// the manifest's icon reference. Run from the project root, as flutter test does.
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';

const String _res = 'android/app/src/main/res';

/// Width and height from a PNG's IHDR chunk.
(int, int) _pngSize(String path) {
  final bytes = File(path).readAsBytesSync();
  expect(bytes.sublist(1, 4), Uint8List.fromList('PNG'.codeUnits), reason: '$path is not a PNG');
  final data = ByteData.sublistView(bytes);
  return (data.getUint32(16), data.getUint32(20));
}

String _read(String path) => File(path).readAsStringSync();

void main() {
  test('every launcher PNG is the right pixel size for its density', () {
    const expected = {'mdpi': 48, 'hdpi': 72, 'xhdpi': 96, 'xxhdpi': 144, 'xxxhdpi': 192};
    for (final entry in expected.entries) {
      final path = '$_res/mipmap-${entry.key}/ic_launcher.png';
      expect(File(path).existsSync(), isTrue, reason: path);
      expect(_pngSize(path), (entry.value, entry.value), reason: path);
    }
  });

  test('the adaptive icon and its round variant have background, foreground and a monochrome layer', () {
    for (final name in ['ic_launcher.xml', 'ic_launcher_round.xml']) {
      final xml = _read('$_res/mipmap-anydpi-v26/$name');
      expect(xml, contains('<adaptive-icon'));
      expect(xml, contains('<background android:drawable="@drawable/ic_launcher_background"'));
      expect(xml, contains('<foreground android:drawable="@drawable/ic_launcher_foreground"'));
      expect(xml, contains('<monochrome android:drawable="@drawable/ic_launcher_monochrome"'));
    }
  });

  test('every drawable the adaptive icon references exists and is a vector or shape', () {
    for (final name in ['ic_launcher_background', 'ic_launcher_foreground', 'ic_launcher_monochrome']) {
      final file = File('$_res/drawable/$name.xml');
      expect(file.existsSync(), isTrue, reason: file.path);
    }
    final foreground = _read('$_res/drawable/ic_launcher_foreground.xml');
    final monochrome = _read('$_res/drawable/ic_launcher_monochrome.xml');
    expect(foreground, contains('<vector'));
    expect(foreground, contains('android:viewportWidth="108"'));
    expect(monochrome, contains('<vector'));
    expect(monochrome, contains('android:fillType="evenOdd"'));
    final background = _read('$_res/drawable/ic_launcher_background.xml');
    expect(background, contains('<vector'));
    expect(background, contains('#E3F794')); // the lime tile behind black Boo
  });

  test('the manifest icon resolves to the adaptive icon', () {
    final manifest = _read('android/app/src/main/AndroidManifest.xml');
    expect(manifest, contains('android:icon="@mipmap/ic_launcher"'));
    expect(File('$_res/mipmap-anydpi-v26/ic_launcher.xml').existsSync(), isTrue);
  });

  test('values-v31 sets the Android 12+ splash items to the ghost and the splash colour', () {
    final styles = _read('$_res/values-v31/styles.xml');
    expect(styles, contains('name="LaunchTheme"'));
    expect(styles, contains('android:windowSplashScreenBackground">@color/booboard_splash_background<'));
    expect(styles, contains('android:windowSplashScreenAnimatedIcon">@drawable/splash_ghost<'));
    expect(File('$_res/drawable/splash_ghost.xml').existsSync(), isTrue);
    final dark = _read('$_res/values-night-v31/styles.xml');
    expect(dark, contains('android:windowSplashScreenBackground">@color/booboard_splash_background<'));
    expect(dark, contains('android:windowSplashScreenAnimatedIcon">@drawable/splash_ghost<'));
  });

  test('the splash colour exists in light and dark, and the launch and normal themes survive', () {
    expect(_read('$_res/values/colors.xml'), contains('name="booboard_splash_background"'));
    expect(_read('$_res/values-night/colors.xml'), contains('name="booboard_splash_background"'));
    for (final dir in ['values', 'values-night']) {
      final styles = _read('$_res/$dir/styles.xml');
      expect(styles, contains('name="LaunchTheme"'), reason: dir);
      expect(styles, contains('name="NormalTheme"'), reason: dir);
      expect(styles, contains('@drawable/launch_background'), reason: dir);
    }
    final launch = _read('$_res/drawable/launch_background.xml');
    expect(launch, contains('@drawable/splash_ghost'));
    expect(launch, contains('@color/booboard_splash_background'));
  });

  test('the store icon is 512 x 512', () {
    expect(_pngSize('docs/brand/play_icon_512.png'), (512, 512));
    expect(_pngSize('docs/brand/feature_graphic_1024x500.png'), (1024, 500));
  });
}
