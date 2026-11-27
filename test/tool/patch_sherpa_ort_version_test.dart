// SPDX-License-Identifier: GPL-3.0-or-later
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../../tool/patch_sherpa_ort_version.dart';

void main() {
  for (final abi in abis) {
    test('$abi: elfHash matches every hash the linker stored', () {
      final bytes = File('android/app/src/main/jniLibs/$abi/libsherpa-onnx-jni.so').readAsBytesSync();
      final needs = readVersionNeeds(bytes);
      expect(needs.map((n) => n.file), containsAll(['libonnxruntime.so', 'libc.so', 'libm.so', 'libdl.so']));
      for (final n in needs) {
        expect(n.hash, elfHash(n.name), reason: '${n.file} ${n.name}');
      }
    });

    test('$abi libsherpa-onnx-jni.so asks for the onnxruntime version we ship', () {
      final bytes = File('android/app/src/main/jniLibs/$abi/libsherpa-onnx-jni.so').readAsBytesSync();
      final ort = readVersionNeeds(bytes).where((n) => n.file == ortLibrary).toList();
      expect(ort.map((n) => n.name), [toVersion], reason: 'run dart run tool/patch_sherpa_ort_version.dart');
      expect(ort.single.hash, elfHash(toVersion));
      // Patching again changes nothing.
      expect(patchOrtVersion(bytes), isFalse);
    });
  }
}
