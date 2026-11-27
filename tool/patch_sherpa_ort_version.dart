// SPDX-License-Identifier: GPL-3.0-or-later
//
// Rewrites the onnxruntime symbol-version requirement of the shipped libsherpa-onnx-jni.so files.
// OWNER: orchestrator.
//
//   dart run tool/patch_sherpa_ort_version.dart [--check]
//
// Why: sherpa-onnx v2.0.1 is linked against onnxruntime 1.28.2, so its ELF version-needs table asks
// libonnxruntime.so for `OrtGetApiBase@VERS_1.28.2`. Maven only publishes onnxruntime-android 1.28.0
// (which exports `VERS_1.28.0`) and 1.29.0+ (which ships HTTP telemetry and INTERNET). Android's linker
// enforces symbol versions, so the unpatched library fails with "cannot locate symbol OrtGetApiBase".
// OrtGetApiBase is the only onnxruntime symbol sherpa imports; everything else goes through the
// OrtApi table, whose API level (28) is the same in 1.28.0 and 1.28.2. So the patch only renames the
// required version (same length) and recomputes its ELF hash. Nothing else in the file changes.
//
// The patch is idempotent. With --check it changes nothing and exits 1 if any library needs patching.
import 'dart:io';
import 'dart:typed_data';

const String fromVersion = 'VERS_1.28.2';
const String toVersion = 'VERS_1.28.0';
const String ortLibrary = 'libonnxruntime.so';
const List<String> abis = ['arm64-v8a', 'armeabi-v7a', 'x86_64'];

/// One entry of the version-needs table: the library it refers to and the version it asks for.
class VersionNeed {
  VersionNeed(this.file, this.name, this.nameOffset, this.hashOffset, this.hash);
  final String file;
  final String name;

  /// File offset of the version name in .dynstr.
  final int nameOffset;

  /// File offset of vna_hash.
  final int hashOffset;
  final int hash;
}

/// SysV ELF hash (used for vna_hash).
int elfHash(String name) {
  var h = 0;
  for (final c in name.codeUnits) {
    h = ((h << 4) + c) & 0xffffffff;
    final g = h & 0xf0000000;
    if (g != 0) h ^= g >> 24;
    h &= ~g & 0xffffffff;
  }
  return h;
}

String _cString(Uint8List b, int off) {
  var end = off;
  while (b[end] != 0) {
    end++;
  }
  return String.fromCharCodes(b.sublist(off, end));
}

/// Reads the .gnu.version_r table of a little-endian ELF32/ELF64 shared library.
List<VersionNeed> readVersionNeeds(Uint8List bytes) {
  if (bytes.length < 0x40 || bytes[0] != 0x7f || bytes[1] != 0x45 || bytes[2] != 0x4c || bytes[3] != 0x46) {
    throw const FormatException('not an ELF file');
  }
  if (bytes[5] != 1) throw const FormatException('big-endian ELF is not supported');
  final is64 = bytes[4] == 2;
  final d = ByteData.sublistView(bytes);
  int u16(int o) => d.getUint16(o, Endian.little);
  int u32(int o) => d.getUint32(o, Endian.little);
  int word(int o) => is64 ? d.getUint64(o, Endian.little) : u32(o);

  final shoff = word(is64 ? 0x28 : 0x20);
  final shentsize = u16(is64 ? 0x3a : 0x2e);
  final shnum = u16(is64 ? 0x3c : 0x30);
  int secType(int i) => u32(shoff + i * shentsize + 4);
  int secOffset(int i) => word(shoff + i * shentsize + (is64 ? 0x18 : 0x10));
  int secLink(int i) => u32(shoff + i * shentsize + (is64 ? 0x28 : 0x18));

  const shtGnuVerneed = 0x6ffffffe;
  final needs = <VersionNeed>[];
  for (var i = 0; i < shnum; i++) {
    if (secType(i) != shtGnuVerneed) continue;
    final strtab = secOffset(secLink(i));
    var vn = secOffset(i);
    while (true) {
      final cnt = u16(vn + 2);
      final file = _cString(bytes, strtab + u32(vn + 4));
      var aux = vn + u32(vn + 8);
      for (var k = 0; k < cnt; k++) {
        final nameOff = strtab + u32(aux + 8);
        needs.add(VersionNeed(file, _cString(bytes, nameOff), nameOff, aux, u32(aux)));
        final next = u32(aux + 12);
        if (next == 0) break;
        aux += next;
      }
      final next = u32(vn + 12);
      if (next == 0) break;
      vn += next;
    }
  }
  return needs;
}

/// Patches [bytes] in place. Returns true if something changed.
bool patchOrtVersion(Uint8List bytes) {
  var changed = false;
  for (final n in readVersionNeeds(bytes)) {
    if (n.file != ortLibrary || n.name != fromVersion) continue;
    bytes.setRange(n.nameOffset, n.nameOffset + toVersion.length, toVersion.codeUnits);
    ByteData.sublistView(bytes).setUint32(n.hashOffset, elfHash(toVersion), Endian.little);
    changed = true;
  }
  return changed;
}

/// The onnxruntime versions a library asks for.
List<String> ortVersionsNeeded(Uint8List bytes) => [
  for (final n in readVersionNeeds(bytes))
    if (n.file == ortLibrary) n.name,
];

void main(List<String> args) {
  final check = args.contains('--check');
  var bad = false;
  for (final abi in abis) {
    final f = File('android/app/src/main/jniLibs/$abi/libsherpa-onnx-jni.so');
    final bytes = f.readAsBytesSync();
    if (check) {
      final v = ortVersionsNeeded(bytes);
      final ok = v.length == 1 && v.single == toVersion;
      bad |= !ok;
      stdout.writeln('$abi: ${v.join(', ')}${ok ? '' : '  <- needs patching'}');
      continue;
    }
    final changed = patchOrtVersion(bytes);
    if (changed) f.writeAsBytesSync(bytes);
    final after = readVersionNeeds(bytes).firstWhere((n) => n.file == ortLibrary);
    if (after.name != toVersion || after.hash != elfHash(toVersion)) {
      stderr.writeln('$abi: unexpected version need ${after.name}');
      exitCode = 1;
      return;
    }
    stdout.writeln('$abi: ${changed ? 'patched' : 'already'} $toVersion');
  }
  if (bad) exitCode = 1;
}
