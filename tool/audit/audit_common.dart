// SPDX-License-Identifier: GPL-3.0-or-later
//
// Parsers shared by the audit scripts (licences.dart, osv_check.dart). No network, no dependencies
// beyond the Dart SDK.
import 'dart:convert';

final class LockedPackage {
  LockedPackage(this.name, this.version, this.source, this.dependency);

  final String name;
  final String version;

  /// `hosted` (pub.dev), `sdk` (Flutter SDK), `path` (local).
  final String source;

  /// `direct main`, `direct dev` or `transitive`.
  final String dependency;
}

/// Reads pubspec.lock: name, version, source and whether the dependency is direct.
List<LockedPackage> readPubspecLock(String text) {
  final out = <LockedPackage>[];
  var inPackages = false;
  String? name;
  var dependency = '';
  var source = '';
  var version = '';

  void flush() {
    final n = name;
    if (n != null) out.add(LockedPackage(n, version, source, dependency));
    name = null;
  }

  for (final line in const LineSplitter().convert(text)) {
    if (line == 'packages:') {
      inPackages = true;
      continue;
    }
    if (!inPackages) continue;
    if (line.startsWith('  ') && !line.startsWith('   ') && line.trimRight().endsWith(':')) {
      flush();
      name = line.trim().substring(0, line.trim().length - 1);
      dependency = '';
      source = '';
      version = '';
      continue;
    }
    if (line.startsWith('    ') && !line.startsWith('     ')) {
      final t = line.trim();
      if (t.startsWith('dependency:')) dependency = _unquote(t.substring('dependency:'.length));
      if (t.startsWith('source:')) source = _unquote(t.substring('source:'.length));
      if (t.startsWith('version:')) version = _unquote(t.substring('version:'.length));
    }
  }
  flush();
  return out;
}

String _unquote(String s) {
  final t = s.trim();
  if (t.length >= 2 && t.startsWith('"') && t.endsWith('"')) return t.substring(1, t.length - 1);
  return t;
}

/// Gradle coordinates from a `:app:dependencies` tree (lines containing "--- "), as
/// `group:artifact` mapped to the resolved version. A conflict such as `1.1.0 -> 1.18.0` keeps the
/// resolved version.
Map<String, String> gradleCoordinates(String tree) {
  final re = RegExp(r'([A-Za-z0-9_.\-]+):([A-Za-z0-9_.\-]+):([A-Za-z0-9_.\-+]+)(?: -> ([A-Za-z0-9_.\-+]+))?');
  final out = <String, String>{};
  for (final line in const LineSplitter().convert(tree)) {
    if (!line.contains('--- ')) continue;
    final m = re.firstMatch(line);
    if (m == null) continue;
    out['${m.group(1)}:${m.group(2)}'] = m.group(4) ?? m.group(3)!;
  }
  return Map.fromEntries(out.entries.toList()..sort((a, b) => a.key.compareTo(b.key)));
}
