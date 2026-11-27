// SPDX-License-Identifier: GPL-3.0-or-later
//
// Licence audit for BooBoard (Wave 5-A). Covers the Dart packages in pubspec.lock and the Gradle
// artifacts of the release runtime classpath. Native libraries and bundled data are listed by hand in
// docs/security/licences.md.
//
// Usage, from the repository root (after `flutter pub get`):
//   dart run tool/audit/licences.dart [--gradle <classpath.txt>] [--check]
//
// <classpath.txt> is the output of:
//   cd android && ./gradlew :app:dependencies --configuration releaseRuntimeClasspath
// Gradle POMs are read from the Gradle cache (GRADLE_USER_HOME or ~/.gradle), so run it after a build.
//
// Prints a Markdown report. --check exits 1 when a licence is unknown or incompatible with
// GPL-3.0-or-later. "review" rows are printed but do not fail the check.
//
// Classification is keyword based and reads the text of each LICENSE file. A file that bundles several
// licences (Flutter's sky_engine does) is reported with its earliest licence as the primary one, the
// others listed, and the worst status among them. Check the flagged rows by hand.
//
// No network access. Reads pubspec.lock, .dart_tool/package_config.json, LICENSE files and POM files.
import 'dart:convert';
import 'dart:io';

import 'audit_common.dart';

enum Status {
  ok,
  review,
  fail,
  unknown;

  Status worse(Status other) => index >= other.index ? this : other;
}

final class Licence {
  const Licence(this.spdx, this.status, this.note);

  final String spdx;
  final Status status;
  final String note;
}

final class AuditRow {
  AuditRow(this.area, this.name, this.version, this.use, this.licence, this.where);

  final String area;
  final String name;
  final String version;
  final String use;
  final Licence licence;
  final String where;
}

final class _Rule {
  const _Rule(this.spdx, this.pattern, this.status, this.note);

  final String spdx;
  final RegExp pattern;
  final Status status;
  final String note;
}

final _rules = <_Rule>[
  _Rule('CC-NC', RegExp(r'non-?commercial'), Status.fail, 'non-commercial clause is incompatible with a store and GPL'),
  _Rule('CC-ND', RegExp(r'no-?\s?derivatives'), Status.fail, 'no-derivatives clause'),
  _Rule('AGPL-3.0', RegExp(r'affero general public license'), Status.review, 'network copyleft: ask the user'),
  _Rule('LGPL', RegExp(r'gnu lesser general public license|\blgpl\b'), Status.review, 'weak copyleft: check linking'),
  _Rule('GPL-3.0', RegExp(r'version 3,? 29 june 2007|\bgplv?-?3\b'), Status.ok, 'compatible with GPL-3.0-or-later'),
  _Rule(
    'GPL-2.0',
    RegExp(r'version 2,? june 1991|\bgplv?-?2\b'),
    Status.review,
    'GPL-2.0 only needs the or-later header',
  ),
  _Rule(
    'EPL',
    RegExp(r'eclipse public license|\bepl\b'),
    Status.review,
    'EPL is not compatible with GPL-3.0 by itself',
  ),
  _Rule('MPL-2.0', RegExp(r'mozilla public license|\bmpl-?2\.0\b'), Status.ok, 'file-level copyleft, GPL-compatible'),
  _Rule(
    'CDDL',
    RegExp(r'\bcddl\b|common development and distribution license'),
    Status.review,
    'CDDL is not GPL-compatible',
  ),
  _Rule(
    'Apache-2.0',
    RegExp(r'apache (software )?license,? version 2\.0|apache-2\.0'),
    Status.ok,
    'compatible with GPL-3.0; keep NOTICE',
  ),
  _Rule('MIT', RegExp(r'\bmit license\b|\bmit\b|permission is hereby granted, free of charge'), Status.ok, ''),
  _Rule(
    'ISC',
    RegExp(r'\bisc license\b|permission to use, copy, modify, and/or distribute this software for any purpose'),
    Status.ok,
    '',
  ),
  _Rule('Zlib', RegExp(r'zlib license|zlib/libpng'), Status.ok, ''),
  _Rule('Unicode-3.0', RegExp(r'unicode license|unicode-3\.0|unicode, inc\. license'), Status.ok, ''),
  _Rule('CC-BY', RegExp(r'creative commons|\bcc-by\b|\bcc by\b'), Status.review, 'data licence: attribution must ship'),
];

/// The BSD text itself, or the SPDX-style name a POM uses (`BSD-3-Clause`).
final _bsdPhrase = RegExp(r'redistribution and use in source and binary forms|\bbsd-[23]-clause\b');
final _proprietaryPhrase = RegExp(r'proprietary|all rights reserved');

/// Classifies the text of a LICENSE file or a POM licence name (see the header comment).
Licence classifyText(String raw) {
  final t = raw.toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
  final hits = <({int index, String spdx, Status status, String note})>[];

  for (final rule in _rules) {
    final m = rule.pattern.firstMatch(t);
    if (m == null) continue;
    var spdx = rule.spdx;
    if (spdx == 'CC-BY' && t.contains('sharealike')) spdx = 'CC-BY-SA';
    hits.add((index: m.start, spdx: spdx, status: rule.status, note: rule.note));
  }

  final bsd = _bsdPhrase.firstMatch(t);
  if (bsd != null) {
    final three = t.contains('neither the name') || t.contains('bsd-3-clause');
    hits.add((index: bsd.start, spdx: three ? 'BSD-3-Clause' : 'BSD-2-Clause', status: Status.ok, note: ''));
  }

  if (hits.isEmpty) {
    if (_proprietaryPhrase.hasMatch(t)) {
      return const Licence('proprietary', Status.fail, 'no open licence grant found');
    }
    return const Licence('unknown', Status.unknown, 'licence text not recognised');
  }

  hits.sort((a, b) => a.index.compareTo(b.index));
  final primary = hits.first.spdx;
  final others = <String>{for (final h in hits.skip(1)) h.spdx}..remove(primary);
  var status = Status.ok;
  final notes = <String>{};
  for (final h in hits) {
    status = status.worse(h.status);
    if (h.note.isNotEmpty && (h.status != Status.ok || h.spdx == primary)) notes.add(h.note);
  }
  final label = others.isEmpty ? primary : '$primary (also ${others.join(', ')})';
  return Licence(label, status, notes.join('; '));
}

/// Pub package name to its folder, from .dart_tool/package_config.json.
Map<String, Directory> packageFolders(String configPath) {
  final file = File(configPath);
  final json = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
  final base = file.parent.uri;
  final out = <String, Directory>{};
  for (final p in (json['packages'] as List<dynamic>).cast<Map<String, dynamic>>()) {
    final root = base.resolve(p['rootUri'] as String);
    out[p['name'] as String] = Directory.fromUri(root);
  }
  return out;
}

final _licenceFile = RegExp(r'^(licen[cs]e|copying)(\.[a-z]+)?$', caseSensitive: false);

String _basename(String path) => path.split(RegExp(r'[\\/]')).last;

/// The licence of a package folder. SDK packages ship no LICENSE of their own, so [sdk] lets the
/// lookup climb to the Flutter SDK root (LICENSE at the top of the SDK).
Licence licenceOfFolder(Directory? dir, {bool sdk = false}) {
  if (dir == null || !dir.existsSync()) {
    return const Licence('unknown', Status.unknown, 'package folder not found (run flutter pub get)');
  }
  var folder = dir;
  for (var level = 0; level < (sdk ? 4 : 1); level++) {
    final files = folder.listSync().whereType<File>().where((f) => _licenceFile.hasMatch(_basename(f.path))).toList()
      ..sort((a, b) => a.path.compareTo(b.path));
    if (files.isNotEmpty) {
      final l = classifyText(files.first.readAsStringSync());
      if (level == 0) return l;
      return Licence(l.spdx, l.status, 'licence of the Flutter SDK (LICENSE at ${folder.path})');
    }
    folder = folder.parent;
  }
  return const Licence('unknown', Status.unknown, 'no LICENSE file in the package');
}

String gradleCacheRoot() {
  final env = Platform.environment;
  final home = env['GRADLE_USER_HOME'] ?? '${env['USERPROFILE'] ?? env['HOME'] ?? ''}/.gradle';
  return '$home/caches/modules-2/files-2.1';
}

File? findPom(String group, String artifact, String version) {
  final dir = Directory('${gradleCacheRoot()}/$group/$artifact/$version');
  if (!dir.existsSync()) return null;
  for (final f in dir.listSync(recursive: true)) {
    if (f is File && f.path.endsWith('.pom')) return f;
  }
  return null;
}

/// Licence names declared in a POM, following one parent POM when the child declares none.
Licence licenceOfPom(String group, String artifact, String version, [int depth = 0]) {
  final pom = findPom(group, artifact, version);
  if (pom == null) return const Licence('unknown', Status.unknown, 'no POM in the Gradle cache');
  final text = pom.readAsStringSync();
  final block = RegExp(r'<licenses>([\s\S]*?)</licenses>').firstMatch(text);
  if (block != null) {
    final names = RegExp(r'<name>\s*([\s\S]*?)\s*</name>').allMatches(block.group(1)!).map((m) => m.group(1)!).toList();
    if (names.isNotEmpty) {
      var status = Status.ok;
      final spdx = <String>[];
      for (final n in names) {
        final l = classifyText(n);
        status = status.worse(l.status);
        spdx.add(l.spdx);
      }
      return Licence(spdx.join(' + '), status, names.join('; '));
    }
  }
  final parent = RegExp(r'<parent>([\s\S]*?)</parent>').firstMatch(text);
  if (parent != null && depth < 3) {
    String tag(String t) => RegExp('<$t>\\s*([^<\\s]+)\\s*</$t>').firstMatch(parent.group(1)!)?.group(1) ?? '';
    final g = tag('groupId');
    final a = tag('artifactId');
    final v = tag('version');
    if (g.isNotEmpty && a.isNotEmpty && v.isNotEmpty) {
      return licenceOfPom(g, a, v, depth + 1);
    }
  }
  return const Licence('unknown', Status.unknown, 'POM declares no licence');
}

void main(List<String> args) {
  final check = args.contains('--check');
  final gradleIndex = args.indexOf('--gradle');
  final gradleFile = gradleIndex >= 0 && gradleIndex + 1 < args.length ? args[gradleIndex + 1] : null;

  final rows = <AuditRow>[];

  final lock = File('pubspec.lock');
  final config = File('.dart_tool/package_config.json');
  if (!lock.existsSync() || !config.existsSync()) {
    stderr.writeln('pubspec.lock or .dart_tool/package_config.json missing: run flutter pub get first');
    exitCode = 2;
    return;
  }
  final folders = packageFolders(config.path);
  for (final p in readPubspecLock(lock.readAsStringSync())) {
    final licence = licenceOfFolder(folders[p.name], sdk: p.source == 'sdk');
    final use = p.dependency == 'direct main' || p.dependency == 'direct dev' ? p.dependency : 'transitive';
    final where = p.source == 'sdk' ? 'Flutter SDK' : (p.source == 'path' ? 'local path' : 'pub.dev');
    rows.add(AuditRow('Dart', p.name, p.version, use, licence, where));
  }

  if (gradleFile != null) {
    final tree = File(gradleFile).readAsStringSync();
    // The Flutter engine artifacts (io.flutter) carry no licence in their POMs; they are built from the
    // Flutter SDK, so they take the SDK's own LICENSE.
    final engine = licenceOfFolder(folders['flutter'], sdk: true);
    for (final entry in gradleCoordinates(tree).entries) {
      final parts = entry.key.split(':');
      final licence = parts[0] == 'io.flutter'
          ? Licence(engine.spdx, engine.status, 'Flutter engine: licence from the Flutter SDK LICENSE')
          : licenceOfPom(parts[0], parts[1], entry.value);
      rows.add(AuditRow('Gradle', entry.key, entry.value, 'release runtime', licence, 'Maven Central or Google'));
    }
  }

  stdout.writeln('| Area | Component | Version | Use | Licence | Status | Note |');
  stdout.writeln('|---|---|---|---|---|---|---|');
  for (final r in rows) {
    final note = r.licence.note.replaceAll('|', '/');
    stdout.writeln(
      '| ${r.area} | ${r.name} | ${r.version} | ${r.use} | ${r.licence.spdx} | ${r.licence.status.name} | $note |',
    );
  }

  final counts = <Status, int>{for (final s in Status.values) s: 0};
  for (final r in rows) {
    counts[r.licence.status] = counts[r.licence.status]! + 1;
  }
  stdout.writeln('');
  stdout.writeln(
    'Total ${rows.length}: ok ${counts[Status.ok]}, review ${counts[Status.review]}, '
    'fail ${counts[Status.fail]}, unknown ${counts[Status.unknown]}.',
  );

  final blocking = counts[Status.fail]! + counts[Status.unknown]!;
  if (check && blocking > 0) {
    stderr.writeln('licence check failed: $blocking component(s) are unknown or incompatible');
    exitCode = 1;
  }
}
