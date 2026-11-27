// SPDX-License-Identifier: GPL-3.0-or-later
//
// Builds, signs, verifies and identifies .boopack model packs (format: android/.../packs/PackStore.kt).
// OWNER: Wave 5-C (pack key rotation). Needs `openssl` on PATH (Git for Windows ships it).
//
//   Build and sign (the key is required):
//     dart run tool/make_pack.dart --dir <staging folder> --id translate-en-es --kind translation \
//       --name "English → Spanish" --languages en,es --engine opus-mt-onnx --license CC-BY-4.0 \
//       --key <private key .pem> [--version 1] --out build/packs/translate-en-es.boopack
//   Check a pack against one public key (nothing is installed):
//     dart run tool/make_pack.dart --verify <pack.boopack> --pubkey <public key .pem>
//   Print a key's id (first 8 bytes of SHA-256 over its DER public key, as 16 hex digits):
//     dart run tool/make_pack.dart --key-id <private or public key .pem>
//
// --key has no default. Without it the tool refuses, so a release pack cannot be signed with the dev key
// by accident. Only with BOOBOARD_ALLOW_DEV_KEY=1 does it sign with the development key
// (%USERPROFILE%/.booboard/keys/pack-dev.pem, outside the repository). Dev-signed packs are for debug builds.
//
// Exit codes: 0 ok, 1 verification failed, 2 usage or input error.
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

const _magic = 'BOOPACK1';
const _formatVersion = 1;
const _maxManifest = 64 * 1024;
const _maxSignature = 512;
const _maxFiles = 64;
const _keyIdHexDigits = 16;

class PackToolError implements Exception {
  PackToolError(this.message, {this.code = 2});
  final String message;
  final int code;

  @override
  String toString() => message;
}

Future<void> main(List<String> argv) async {
  try {
    exitCode = await _run(_parse(argv));
  } on PackToolError catch (e) {
    stderr.writeln('make_pack: ${e.message}');
    exitCode = e.code;
  }
}

Future<int> _run(Map<String, String> args) async {
  if (args.containsKey('key-id')) {
    stdout.writeln(await _keyId(args['key-id']!));
    return 0;
  }
  if (args.containsKey('verify')) {
    final pubkey = args['pubkey'] ?? (throw PackToolError('--verify needs --pubkey <public key .pem>'));
    return _verify(File(args['verify']!), pubkey);
  }
  return _build(args);
}

String _need(Map<String, String> args, String key) => args[key] ?? (throw PackToolError('missing --$key'));

Future<int> _build(Map<String, String> args) async {
  final dir = Directory(_need(args, 'dir'));
  final out = File(_need(args, 'out'));
  if (!dir.existsSync()) throw PackToolError('staging folder not found: ${dir.path}');

  final keyArg = args['key'];
  final String keyPath;
  if (keyArg != null) {
    keyPath = keyArg;
  } else {
    if (Platform.environment['BOOBOARD_ALLOW_DEV_KEY'] != '1') {
      throw PackToolError(
        'refusing to sign without --key. Give the signing key, or set BOOBOARD_ALLOW_DEV_KEY=1 '
        'to sign with the development key (debug packs only).',
      );
    }
    final home = Platform.environment['USERPROFILE'] ?? Platform.environment['HOME'] ?? '.';
    keyPath = '$home/.booboard/keys/pack-dev.pem';
    stderr.writeln('WARNING: signing with the DEVELOPMENT key. This pack is for debug builds only.');
  }
  if (!File(keyPath).existsSync()) throw PackToolError('key file not found: $keyPath');

  final files = dir.listSync(recursive: true).whereType<File>().toList()..sort((a, b) => a.path.compareTo(b.path));
  if (files.isEmpty) throw PackToolError('no files in ${dir.path}');
  if (files.length > _maxFiles) throw PackToolError('a pack holds at most $_maxFiles files, found ${files.length}');

  final entries = <Map<String, Object>>[];
  for (final f in files) {
    final rel = f.path.substring(dir.path.length + 1).replaceAll(r'\', '/');
    entries.add({'path': rel, 'size': f.lengthSync(), 'sha256': await _sha256File(f.path)});
    stdout.writeln('  $rel  ${f.lengthSync()} bytes');
  }
  final manifest = utf8.encode(
    jsonEncode({
      'id': _need(args, 'id'),
      'kind': _need(args, 'kind'),
      'name': _need(args, 'name'),
      'version': int.parse(args['version'] ?? '1'),
      'languages': _need(args, 'languages').split(','),
      'engine': _need(args, 'engine'),
      'license': _need(args, 'license'),
      'files': entries,
    }),
  );
  if (manifest.length > _maxManifest) throw PackToolError('manifest is larger than $_maxManifest bytes');

  out.parent.createSync(recursive: true);
  final tmp = Directory.systemTemp.createTempSync('boopack');
  try {
    final manifestFile = File('${tmp.path}/manifest.json')..writeAsBytesSync(manifest);
    final sigFile = File('${tmp.path}/manifest.sig');
    final r = await Process.run('openssl', [
      'dgst',
      '-sha256',
      '-sign',
      keyPath,
      '-out',
      sigFile.path,
      manifestFile.path,
    ]);
    if (r.exitCode != 0) throw PackToolError('openssl sign failed: ${r.stderr}');
    final sig = sigFile.readAsBytesSync();
    if (sig.length > _maxSignature) throw PackToolError('signature is larger than $_maxSignature bytes');

    final sink = out.openWrite();
    Uint8List u32(int v) => Uint8List(4)..buffer.asByteData().setUint32(0, v);
    sink
      ..add(ascii.encode(_magic))
      ..add(u32(_formatVersion))
      ..add(u32(manifest.length))
      ..add(manifest)
      ..add(u32(sig.length))
      ..add(sig);
    for (final f in files) {
      await sink.addStream(f.openRead());
    }
    await sink.close();
    stdout.writeln('wrote ${out.path} (${out.lengthSync()} bytes, ${files.length} files)');
    stdout.writeln('signed by key id ${await _keyId(keyPath)}');
    return 0;
  } finally {
    tmp.deleteSync(recursive: true);
  }
}

/// Checks the container, the signature over the manifest with [pubkeyPath], and every file's size and hash.
Future<int> _verify(File pack, String pubkeyPath) async {
  if (!pack.existsSync()) throw PackToolError('pack not found: ${pack.path}');
  if (!File(pubkeyPath).existsSync()) throw PackToolError('public key not found: $pubkeyPath');
  final raf = await pack.open();
  try {
    final fileLength = await raf.length();
    final magic = await _readExact(raf, _magic.length);
    if (String.fromCharCodes(magic) != _magic) return _fail('not a BooBoard pack');
    final version = _u32(await _readExact(raf, 4));
    if (version != _formatVersion) return _fail('unsupported format version $version');
    final manifestLen = _u32(await _readExact(raf, 4));
    if (manifestLen < 2 || manifestLen > _maxManifest) return _fail('bad manifest length');
    final manifest = await _readExact(raf, manifestLen);
    final sigLen = _u32(await _readExact(raf, 4));
    if (sigLen < 8 || sigLen > _maxSignature) return _fail('bad signature length');
    final sig = await _readExact(raf, sigLen);

    final tmp = Directory.systemTemp.createTempSync('booboardverify');
    try {
      final manifestFile = File('${tmp.path}/manifest.json')..writeAsBytesSync(manifest);
      final sigFile = File('${tmp.path}/manifest.sig')..writeAsBytesSync(sig);
      final r = await Process.run('openssl', [
        'dgst',
        '-sha256',
        '-verify',
        pubkeyPath,
        '-signature',
        sigFile.path,
        manifestFile.path,
      ]);
      if (r.exitCode != 0) return _fail('not signed by the given key');
    } finally {
      tmp.deleteSync(recursive: true);
    }

    final json = jsonDecode(utf8.decode(manifest)) as Map<String, Object?>;
    final files = (json['files'] as List).cast<Map<String, Object?>>();
    if (files.isEmpty || files.length > _maxFiles) return _fail('bad file count');
    final seen = <String>{};
    var total = 0;
    var damaged = 0;
    for (final f in files) {
      final path = f['path'] as String;
      if (path.startsWith('/') || path.split('/').any((p) => p.isEmpty || p == '..' || p == '.')) {
        return _fail('bad file path in manifest');
      }
      if (!seen.add(path)) return _fail('duplicate file path in manifest');
      final size = f['size'] as int;
      if (await raf.position() + size > fileLength) return _fail('file data is truncated');
      final hash = await _sha256Stream(_chunks(raf, size));
      if (hash != f['sha256']) {
        damaged++;
        stderr.writeln('  damaged: $path');
      }
      total += size;
    }
    if (await raf.position() != fileLength) return _fail('trailing data after the files');
    if (damaged > 0) return _fail('$damaged file(s) do not match their hashes');
    stdout.writeln(
      'OK ${json['id']} v${json['version']}: ${files.length} files, $total bytes, '
      'signed by key id ${await _keyId(pubkeyPath)}',
    );
    return 0;
  } finally {
    await raf.close();
  }
}

int _fail(String why) {
  stdout.writeln('FAILED: $why');
  return 1;
}

Future<List<int>> _readExact(RandomAccessFile raf, int n) async {
  final bytes = await raf.read(n);
  if (bytes.length != n) throw PackToolError('file is truncated', code: 1);
  return bytes;
}

int _u32(List<int> b) => ByteData.sublistView(Uint8List.fromList(b)).getUint32(0);

/// Reads [n] bytes from the current position in chunks of at most 1 MiB, without holding the file in memory.
Stream<List<int>> _chunks(RandomAccessFile raf, int n) async* {
  var left = n;
  while (left > 0) {
    final chunk = await raf.read(left < 1 << 20 ? left : 1 << 20);
    if (chunk.isEmpty) throw PackToolError('file is truncated', code: 1);
    left -= chunk.length;
    yield chunk;
  }
}

/// Key id: the first 8 bytes of SHA-256 over the DER public key (what the app computes), as 16 hex digits.
Future<String> _keyId(String keyPath) async {
  var der = await Process.run('openssl', ['pkey', '-in', keyPath, '-pubout', '-outform', 'DER'], stdoutEncoding: null);
  if (der.exitCode != 0) {
    der = await Process.run('openssl', ['pkey', '-pubin', '-in', keyPath, '-outform', 'DER'], stdoutEncoding: null);
  }
  if (der.exitCode != 0) throw PackToolError('not an EC key file: $keyPath');
  final hex = await _sha256Stream(Stream.value(der.stdout as List<int>));
  return hex.substring(0, _keyIdHexDigits);
}

Future<String> _sha256File(String path) async {
  final r = await Process.run('openssl', ['dgst', '-sha256', '-r', path]);
  if (r.exitCode != 0) throw PackToolError('openssl hash failed: ${r.stderr}');
  return (r.stdout as String).split(' ').first.trim().toLowerCase();
}

/// SHA-256 (lowercase hex) of a stream, computed by openssl reading stdin.
Future<String> _sha256Stream(Stream<List<int>> data) async {
  final p = await Process.start('openssl', ['dgst', '-sha256', '-r']);
  final out = p.stdout.transform(utf8.decoder).join();
  await p.stdin.addStream(data);
  await p.stdin.close();
  final text = await out;
  if (await p.exitCode != 0) throw PackToolError('openssl hash failed');
  return text.split(' ').first.trim().toLowerCase();
}

Map<String, String> _parse(List<String> argv) {
  final out = <String, String>{};
  for (var i = 0; i < argv.length; i++) {
    final a = argv[i];
    if (!a.startsWith('--')) throw PackToolError('unexpected argument $a');
    final value = (i + 1 < argv.length && !argv[i + 1].startsWith('--')) ? argv[++i] : '';
    out[a.substring(2)] = value;
  }
  return out;
}
