// SPDX-License-Identifier: GPL-3.0-or-later
//
// Advisory check (Wave 5-A): sends the pub.dev and Maven coordinates of BooBoard's release build to the
// OSV database (https://api.osv.dev, query API) and prints the known advisories.
//
// Usage, from the repository root (after `flutter pub get`):
//   dart run tool/audit/osv_check.dart [--gradle <classpath.txt>]
//
// <classpath.txt> is the output of: cd android && ./gradlew :app:dependencies --configuration releaseRuntimeClasspath
//
// Exit codes: 0 no advisories, 1 advisories found, 3 OSV unreachable, 2 usage error.
// This is the only network access in the audit tools, and it runs on a developer machine or in the
// CI audit job. Only package names and versions are sent. The app itself never uses the network.
import 'dart:convert';
import 'dart:io';

import 'audit_common.dart';

const _osv = 'https://api.osv.dev/v1';
const _maxDetailLookups = 200;

final class _Query {
  _Query(this.label, this.ecosystem, this.name, this.version);

  final String label;
  final String ecosystem;
  final String name;
  final String version;

  Map<String, Object?> toJson() => {
    'package': {'name': name, 'ecosystem': ecosystem},
    'version': version,
  };
}

Future<Map<String, dynamic>> _postJson(HttpClient client, Uri uri, Object body) async {
  final request = await client.postUrl(uri);
  request.headers.contentType = ContentType.json;
  request.write(jsonEncode(body));
  final response = await request.close();
  final text = await utf8.decodeStream(response);
  if (response.statusCode != 200) {
    throw HttpException('OSV returned HTTP ${response.statusCode} for ${uri.path}');
  }
  return jsonDecode(text) as Map<String, dynamic>;
}

Future<Map<String, dynamic>> _getJson(HttpClient client, Uri uri) async {
  final request = await client.getUrl(uri);
  final response = await request.close();
  final text = await utf8.decodeStream(response);
  if (response.statusCode != 200) {
    throw HttpException('OSV returned HTTP ${response.statusCode} for ${uri.path}');
  }
  return jsonDecode(text) as Map<String, dynamic>;
}

Future<void> main(List<String> args) async {
  final gradleIndex = args.indexOf('--gradle');
  final gradleFile = gradleIndex >= 0 && gradleIndex + 1 < args.length ? args[gradleIndex + 1] : null;

  final lock = File('pubspec.lock');
  if (!lock.existsSync()) {
    stderr.writeln('pubspec.lock missing: run flutter pub get first');
    exitCode = 2;
    return;
  }

  final queries = <_Query>[];
  for (final p in readPubspecLock(lock.readAsStringSync())) {
    // SDK packages are versioned with the SDK itself; OSV has no entries for them.
    if (p.source != 'hosted') continue;
    queries.add(_Query('pub ${p.name} ${p.version}', 'Pub', p.name, p.version));
  }
  if (gradleFile != null) {
    final coords = gradleCoordinates(File(gradleFile).readAsStringSync());
    for (final entry in coords.entries) {
      queries.add(_Query('maven ${entry.key} ${entry.value}', 'Maven', entry.key, entry.value));
    }
  }

  final client = HttpClient()..connectionTimeout = const Duration(seconds: 30);
  try {
    final hitsByQuery = <int, List<String>>{};
    const batch = 500;
    for (var start = 0; start < queries.length; start += batch) {
      final end = start + batch > queries.length ? queries.length : start + batch;
      final slice = queries.sublist(start, end);
      final result = await _postJson(client, Uri.parse('$_osv/querybatch'), {
        'queries': [for (final q in slice) q.toJson()],
      });
      final results = (result['results'] as List<dynamic>?) ?? const [];
      for (var i = 0; i < results.length; i++) {
        final vulns = ((results[i] as Map<String, dynamic>)['vulns'] as List<dynamic>?) ?? const [];
        if (vulns.isEmpty) continue;
        hitsByQuery[start + i] = [for (final v in vulns) (v as Map<String, dynamic>)['id'] as String];
      }
    }

    final ids = <String>{for (final list in hitsByQuery.values) ...list};
    final details = <String, Map<String, dynamic>>{};
    for (final id in ids.take(_maxDetailLookups)) {
      details[id] = await _getJson(client, Uri.parse('$_osv/vulns/$id'));
    }

    stdout.writeln('Checked ${queries.length} components against OSV.');
    if (hitsByQuery.isEmpty) {
      stdout.writeln('No known advisories.');
      return;
    }
    stdout.writeln('');
    stdout.writeln('| Component | Advisory | Summary |');
    stdout.writeln('|---|---|---|');
    final keys = hitsByQuery.keys.toList()..sort();
    for (final k in keys) {
      for (final id in hitsByQuery[k]!) {
        final summary = (details[id]?['summary'] as String?) ?? (details[id]?['details'] as String? ?? '');
        final oneLine = summary.replaceAll(RegExp(r'\s+'), ' ').replaceAll('|', '/');
        stdout.writeln(
          '| ${queries[k].label} | $id | ${oneLine.length > 160 ? '${oneLine.substring(0, 157)}...' : oneLine} |',
        );
      }
    }
    stdout.writeln('');
    stdout.writeln('${hitsByQuery.length} component(s) with advisories, ${ids.length} advisory id(s).');
    exitCode = 1;
  } on SocketException catch (e) {
    stderr.writeln('OSV unreachable: ${e.message}');
    exitCode = 3;
  } on HttpException catch (e) {
    stderr.writeln(e.message);
    exitCode = 3;
  } finally {
    client.close(force: true);
  }
}
