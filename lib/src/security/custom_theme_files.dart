// SPDX-License-Identifier: GPL-3.0-or-later
//
// Custom themes are plain files in `<dataDirectory>/themes` (JSON specs plus optional background
// images in its `images/` subfolder, as `CustomThemeStore` writes them). This class is the only
// place that touches that folder from the settings app, so the name rules are enforced in one spot.
// A name is a safe basename, or `images/` plus a safe image basename; never "..".
import 'dart:io';
import 'dart:typed_data';

import '../core/log.dart';

class CustomThemeFile {
  const CustomThemeFile({required this.name, required this.sizeBytes, required this.modifiedMillis});

  final String name;
  final int sizeBytes;
  final int modifiedMillis;

  bool get isImage => CustomThemeFiles.isImageName(name);
}

class CustomThemeFiles {
  CustomThemeFiles(this.directory);

  /// Folder for a data directory, as the keyboard resolves it.
  factory CustomThemeFiles.forDataDirectory(String dataDirectory) =>
      CustomThemeFiles('$dataDirectory${Platform.pathSeparator}themes');

  /// Subfolder for background photos, matching `CustomThemeStore.imagesFolder`.
  static const String imagesFolder = 'images';
  static const int maxJsonBytes = 256 * 1024;
  static const int maxImageBytes = 8 * 1024 * 1024;
  static const Set<String> _jsonExtensions = {'json'};
  static const Set<String> _imageExtensions = {'png', 'jpg', 'jpeg', 'webp'};
  static final RegExp _namePattern = RegExp(r'^[A-Za-z0-9][A-Za-z0-9 _.\-]{0,79}$');

  final String directory;

  /// True for a file name BooBoard will write or export: a safe basename with a known extension.
  static bool isSafeName(String name) {
    const prefix = '$imagesFolder/';
    if (name.startsWith(prefix)) {
      final base = name.substring(prefix.length);
      return _namePattern.hasMatch(base) && !base.contains('..') && isImageName(base);
    }
    if (!_namePattern.hasMatch(name)) return false;
    if (name.contains('..')) return false;
    final ext = _extension(name);
    return _jsonExtensions.contains(ext) || _imageExtensions.contains(ext);
  }

  static bool isImageName(String name) => _imageExtensions.contains(_extension(name));

  static String _extension(String name) {
    final dot = name.lastIndexOf('.');
    return dot < 0 ? '' : name.substring(dot + 1).toLowerCase();
  }

  /// Largest size BooBoard accepts for a file of this kind.
  static int maxBytesFor(String name) => isImageName(name) ? maxImageBytes : maxJsonBytes;

  Future<List<CustomThemeFile>> list() async {
    final out = <CustomThemeFile>[];
    await _listInto(Directory(directory), '', out);
    await _listInto(Directory('$directory${Platform.pathSeparator}$imagesFolder'), '$imagesFolder/', out);
    out.sort((a, b) => a.name.compareTo(b.name));
    return out;
  }

  Future<void> _listInto(Directory dir, String prefix, List<CustomThemeFile> out) async {
    if (!await dir.exists()) return;
    await for (final entity in dir.list(followLinks: false)) {
      if (entity is! File) continue;
      final name = '$prefix${entity.uri.pathSegments.last}';
      try {
        final stat = await entity.stat();
        out.add(
          CustomThemeFile(name: name, sizeBytes: stat.size, modifiedMillis: stat.modified.millisecondsSinceEpoch),
        );
      } on FileSystemException catch (e) {
        BooBoardLog.w('Themes', 'stat failed', e.runtimeType);
      }
    }
  }

  Future<int> totalBytes() async {
    var total = 0;
    for (final f in await list()) {
      total += f.sizeBytes;
    }
    return total;
  }

  Future<Uint8List?> read(String name) async {
    if (!isSafeName(name)) return null;
    final file = File('$directory${Platform.pathSeparator}$name');
    if (!await file.exists()) return null;
    return file.readAsBytes();
  }

  /// Writes [bytes] under [name]. Throws [ArgumentError] for an unsafe name or an oversize file.
  Future<void> write(String name, Uint8List bytes) async {
    if (!isSafeName(name)) throw ArgumentError.value(name, 'name', 'unsafe theme file name');
    if (bytes.length > maxBytesFor(name)) throw ArgumentError.value(bytes.length, 'bytes', 'theme file too large');
    final target = File('$directory${Platform.pathSeparator}$name');
    if (!await target.parent.exists()) await target.parent.create(recursive: true);
    final tmp = File('${target.path}.tmp');
    await tmp.writeAsBytes(bytes, flush: true);
    await tmp.rename(target.path);
  }

  Future<bool> exists(String name) => File('$directory${Platform.pathSeparator}$name').exists();

  /// Deletes every file in the folder, and the folder itself.
  Future<void> deleteAll() async {
    final dir = Directory(directory);
    if (await dir.exists()) await dir.delete(recursive: true);
  }
}
