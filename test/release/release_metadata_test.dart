// SPDX-License-Identifier: GPL-3.0-or-later
//
// Checks for the release material: store text limits, the single applicationId, the flavour manifests,
// pinned workflow actions, the documents, and the key generation script. Runs from the repository root.
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

String _read(String path) => File(path).readAsStringSync();

/// Length in Unicode code points (the unit the stores count).
int _runes(String s) => s.trim().runes.length;

final String _applicationId = RegExp(r'val booboardApplicationId = "([^"]+)"')
    .firstMatch(_read('android/app/build.gradle.kts'))!
    .group(1)!;

void main() {
  group('store texts', () {
    const locales = ['en-US', 'es-ES', 'fr-FR', 'de-DE', 'pt-BR', 'id', 'hi-IN'];
    final root = 'fastlane/metadata/android';

    test('every locale has a title and a short description within the store limits', () {
      for (final locale in locales) {
        final title = _read('$root/$locale/title.txt');
        final short = _read('$root/$locale/short_description.txt');
        expect(_runes(title), inInclusiveRange(1, 30), reason: '$locale title');
        expect(_runes(short), inInclusiveRange(1, 80), reason: '$locale short description');
      }
    });

    test('en-US has a full description within 4000 characters and the changelog for build 1', () {
      final full = _read('$root/en-US/full_description.txt');
      expect(_runes(full), inInclusiveRange(1, 4000));
      expect(_runes(_read('$root/en-US/changelogs/1.txt')), inInclusiveRange(1, 500));
    });

    test('the pubspec build number has a changelog in en-US', () {
      final pubspec = _read('pubspec.yaml');
      final build = RegExp(r'^version:\s*[0-9.]+\+(\d+)', multiLine: true).firstMatch(pubspec)!.group(1);
      expect(File('$root/en-US/changelogs/$build.txt').existsSync(), isTrue, reason: 'changelogs/$build.txt');
    });

    test('en-US images are the brand assets, byte for byte', () {
      expect(
        File('$root/en-US/images/icon.png').readAsBytesSync(),
        equals(File('docs/brand/play_icon_512.png').readAsBytesSync()),
      );
      expect(
        File('$root/en-US/images/featureGraphic.png').readAsBytesSync(),
        equals(File('docs/brand/feature_graphic_1024x500.png').readAsBytesSync()),
      );
    });

    test('no store text makes a claim the code does not support (no ads, analytics or accounts promised)', () {
      final full = _read('$root/en-US/full_description.txt').toLowerCase();
      expect(full, contains('no internet permission'));
      expect(full, isNot(contains('sign up')));
      expect(full, isNot(contains('free trial')));
    });
  });

  group('applicationId', () {
    test('the constant is the only applicationId value in the Gradle build', () {
      final gradle = _read('android/app/build.gradle.kts');
      expect(RegExp(r'applicationId\s*=').allMatches(gradle), hasLength(1));
      expect(_applicationId, isNotEmpty);
    });

    test('the F-Droid recipe is named after the applicationId', () {
      expect(File('metadata/$_applicationId.yml').existsSync(), isTrue);
    });

    test('the adb helper and the benchmark use the same applicationId', () {
      expect(_read('tool/adb_ime.ps1'), contains("\$script:Pkg = '$_applicationId'"));
      expect(_read('tool/bench/device_bench.ps1'), contains("[string]\$Package = '$_applicationId'"));
    });

    test('the Kotlin namespace stays app.booboard.keyboard', () {
      expect(_read('android/app/build.gradle.kts'), contains('val booboardNamespace = "app.booboard.keyboard"'));
    });
  });

  group('flavours and manifests', () {
    test('neither flavour nor the main manifest requests the internet', () {
      final files = [
        'android/app/src/main/AndroidManifest.xml',
        'android/app/src/foss/AndroidManifest.xml',
        'android/app/src/play/AndroidManifest.xml',
      ];
      for (final path in files) {
        final f = File(path);
        if (!f.existsSync()) continue;
        expect(f.readAsStringSync(), isNot(contains('android.permission.INTERNET')), reason: path);
      }
    });

    test('both flavours are declared in Gradle on the distribution dimension', () {
      final gradle = _read('android/app/build.gradle.kts');
      expect(gradle, contains('flavorDimensions += "distribution"'));
      expect(gradle, contains('create("foss")'));
      expect(gradle, contains('create("play")'));
    });

    test('each flavour has its distribution resource', () {
      expect(_read('android/app/src/foss/res/values/distribution.xml'), contains('>foss<'));
      expect(_read('android/app/src/play/res/values/distribution.xml'), contains('>play<'));
    });
  });

  group('workflow', () {
    test('every action in release.yml is pinned to a full commit SHA', () {
      final uses = RegExp(
        r'^\s*-?\s*uses:\s*(\S+)',
        multiLine: true,
      ).allMatches(_read('.github/workflows/release.yml')).map((m) => m.group(1)!).toList();
      expect(uses, isNotEmpty);
      for (final ref in uses) {
        expect(ref, matches(RegExp(r'@[0-9a-f]{40}$')), reason: ref);
      }
    });

    test('release.yml never publishes: the release is created as a draft', () {
      final yml = _read('.github/workflows/release.yml');
      expect(yml, contains('--draft'));
      expect(yml, isNot(contains('--latest')));
      expect(yml, isNot(contains('draft: false')));
    });

    test('release.yml refuses debug-signed APKs', () {
      expect(_read('.github/workflows/release.yml'), contains('CN=Android Debug'));
    });
  });

  group('signing ignores', () {
    test('keystores, passwords and key properties are git-ignored', () {
      final gitignore = _read('.gitignore');
      for (final pattern in [
        '*.jks',
        '*.keystore',
        '*.p12',
        '*.password',
        'key.properties',
        'android/key.properties',
      ]) {
        expect(gitignore, contains(pattern), reason: pattern);
      }
    });
  });

  group('documents', () {
    const docs = [
      'docs/release/RELEASING.md',
      'docs/release/privacy-policy.md',
      'docs/release/data-safety.md',
      'docs/release/fdroid.md',
      'docs/release/developer-verification.md',
      'docs/release/store-listing.md',
      'docs/release/checklist.md',
    ];

    test('every release document exists', () {
      for (final d in docs) {
        expect(File(d).existsSync(), isTrue, reason: d);
      }
    });

    test('every tool/release script named in the documents exists', () {
      final named = <String>{};
      for (final d in docs) {
        for (final m in RegExp(r'tool[\\/]release[\\/][A-Za-z0-9_-]+(\.[A-Za-z0-9_-]+)?').allMatches(_read(d))) {
          named.add(m.group(0)!.replaceAll('\\', '/'));
        }
      }
      expect(named, isNotEmpty);
      for (final path in named) {
        expect(File(path).existsSync(), isTrue, reason: path);
      }
    });

    test('the privacy policy states the no-network position and names a public contact', () {
      final policy = _read('docs/release/privacy-policy.md');
      expect(policy, contains('does not send anything you type'));
      expect(policy, isNot(contains('<contact email>')));
      expect(policy, contains('https://github.com/knandu18/booboard/issues'));
    });
  });

  group('make_release_keys.ps1', () {
    test('creates throwaway keys in a temp folder, refuses to overwrite, and never prints a secret', () async {
      if (!Platform.isWindows) return;
      final out = Directory.systemTemp.createTempSync('booboard-keytest-').path;
      final target = '$out${Platform.pathSeparator}keys';
      final script = 'tool/release/make_release_keys.ps1';
      try {
        final first = await Process.run('powershell', [
          '-NoProfile',
          '-ExecutionPolicy',
          'Bypass',
          '-File',
          script,
          '-OutDir',
          target,
        ]);
        expect(first.exitCode, 0, reason: '${first.stderr}');
        for (final name in [
          'booboard-release.p12',
          'release-keystore.password',
          'key.properties',
          'pack-release.pem',
          'pack-release.pub.b64',
        ]) {
          expect(File('$target${Platform.pathSeparator}$name').existsSync(), isTrue, reason: name);
        }
        // SubjectPublicKeyInfo DER for P-256 starts with the same base64 prefix as the dev key in PackKeys.kt.
        final pub = _read('$target${Platform.pathSeparator}pack-release.pub.b64').trim();
        expect(base64.decode(pub).length, 91);
        expect(pub, startsWith('MFkwEwYHKoZIzj0CAQYIKoZIzj0DAQcDQgAE'));

        final output = '${first.stdout}${first.stderr}';
        final password = _read('$target${Platform.pathSeparator}release-keystore.password').trim();
        expect(output, isNot(contains(password)));

        final second = await Process.run('powershell', [
          '-NoProfile',
          '-ExecutionPolicy',
          'Bypass',
          '-File',
          script,
          '-OutDir',
          target,
        ]);
        expect(second.exitCode, isNot(0));
        expect('${second.stdout}${second.stderr}', contains('Refusing to overwrite'));
      } finally {
        Directory(out).deleteSync(recursive: true);
      }
    }, timeout: const Timeout(Duration(minutes: 3)));
  });
}
