// SPDX-License-Identifier: GPL-3.0-or-later
//
// Custom themes are plain files under `<dataDirectory>/themes`:
//   <uuid>.json            the versioned ThemeSpec (see assets/themes/README.txt)
//   images/<uuid>.png      the pre-rendered, cropped and blurred photo background
// The keyboard reads them synchronously through [CustomThemeStore.readSpecSync];
// the theme editor writes them atomically (temp file, then rename). They hold
// no typed text, so they are not in SecureBlobStore.
import 'dart:collection';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import '../../core/log.dart';
import '../theme_spec.dart';

/// Ids of custom themes: `custom:<uuid>`. Anything else is rejected, so an id can never name a
/// path outside the themes folder.
abstract final class CustomThemeIds {
  static const String prefix = 'custom:';

  static final RegExp _uuid = RegExp(r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$');

  static bool isCustom(String id) => id.startsWith(prefix);

  /// The uuid behind a well-formed custom id, else null.
  static String? uuidOf(String id) {
    if (!id.startsWith(prefix)) return null;
    final uuid = id.substring(prefix.length);
    return _uuid.hasMatch(uuid) ? uuid : null;
  }

  static String idFor(String uuid) => '$prefix$uuid';

  /// A random RFC 4122 version 4 uuid (lower case).
  static String newUuid([Random? random]) {
    final r = random ?? Random.secure();
    final b = List<int>.generate(16, (_) => r.nextInt(256));
    b[6] = (b[6] & 0x0f) | 0x40;
    b[8] = (b[8] & 0x3f) | 0x80;
    final hex = [for (final x in b) x.toRadixString(16).padLeft(2, '0')].join();
    return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-${hex.substring(12, 16)}-'
        '${hex.substring(16, 20)}-${hex.substring(20)}';
  }
}

/// Reads and writes custom themes in [directory] (`<dataDirectory>/themes`).
class CustomThemeStore {
  CustomThemeStore(this.directory);

  final String directory;

  /// Largest spec file accepted (bytes).
  static const int maxSpecBytes = 64 * 1024;

  /// Folder of background images, relative to [directory].
  static const String imagesFolder = 'images';

  /// Stored in `ThemeBackgroundSpec.imagePath`: relative to [directory], so a backup restored on
  /// another device or folder still finds the image.
  static String imageRelativePath(String uuid) => '$imagesFolder/$uuid.png';

  static final RegExp imageRelativePattern = RegExp(
    r'^images/[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}\.png$',
  );

  static final String _sep = Platform.pathSeparator;

  static String specPathOf(String directory, String uuid) => '$directory$_sep$uuid.json';

  static String imagePathOf(String directory, String uuid) => '$directory$_sep$imagesFolder$_sep$uuid.png';

  // Parsed specs keyed on file path, checked against the file's modified time.
  static const int _parsedCapacity = 12;
  static final LinkedHashMap<String, (DateTime, int, ThemeSpec)> _parsed = LinkedHashMap();

  /// Reads a custom theme synchronously (the keyboard resolves on the UI thread, only when the
  /// appearance changes). Returns null if the id is malformed, the file is missing, too large or
  /// broken. The log never names the path.
  static ThemeSpec? readSpecSync(String directory, String id) {
    final uuid = CustomThemeIds.uuidOf(id);
    if (uuid == null) return null;
    final path = specPathOf(directory, uuid);
    try {
      final file = File(path);
      if (!file.existsSync()) {
        BooBoardLog.w('Theme', 'custom theme file missing');
        return null;
      }
      final stat = file.statSync();
      if (stat.size > maxSpecBytes) {
        BooBoardLog.w('Theme', 'custom theme file too large');
        return null;
      }
      final hit = _parsed[path];
      if (hit != null && hit.$1 == stat.modified && hit.$2 == stat.size) return hit.$3;
      final decoded = jsonDecode(file.readAsStringSync());
      if (decoded is! Map<String, Object?>) {
        BooBoardLog.w('Theme', 'custom theme file is not an object');
        return null;
      }
      // The file name is the authority for the id, whatever the JSON says.
      final spec = ThemeSpec.fromJson(decoded).copyWith(id: id);
      _parsed.remove(path);
      _parsed[path] = (stat.modified, stat.size, spec);
      if (_parsed.length > _parsedCapacity) _parsed.remove(_parsed.keys.first);
      return spec;
    } on Object catch (e) {
      BooBoardLog.w('Theme', 'custom theme unreadable, using the default', e.runtimeType);
      return null;
    }
  }

  /// Reads a custom theme, or null (see [readSpecSync]).
  Future<ThemeSpec?> read(String id) async => readSpecSync(directory, id);

  /// Every readable custom theme, sorted by name. Broken files are skipped.
  Future<List<ThemeSpec>> list() async {
    final dir = Directory(directory);
    if (!dir.existsSync()) return const [];
    final out = <ThemeSpec>[];
    await for (final entity in dir.list(followLinks: false)) {
      if (entity is! File) continue;
      final name = entity.uri.pathSegments.last;
      if (!name.endsWith('.json')) continue;
      final uuid = name.substring(0, name.length - '.json'.length);
      final spec = readSpecSync(directory, CustomThemeIds.idFor(uuid));
      if (spec != null) out.add(spec);
    }
    out.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    return out;
  }

  /// Saves [spec] (its id must be a custom id). Throws [StateError] if the JSON exceeds
  /// [maxSpecBytes] and [ArgumentError] for a bad id.
  Future<void> write(ThemeSpec spec) async {
    final uuid = CustomThemeIds.uuidOf(spec.id);
    if (uuid == null) throw ArgumentError.value(spec.id, 'id', 'not a custom theme id');
    final bytes = utf8.encode(jsonEncode(spec.toJson()));
    if (bytes.length > maxSpecBytes) throw StateError('theme spec too large');
    await Directory(directory).create(recursive: true);
    final path = specPathOf(directory, uuid);
    await _atomicWrite(path, bytes);
    _parsed.remove(path);
  }

  /// The uuid of the photo named by a stored `imagePath`, or null when there is none or it is malformed.
  static String? photoUuidOf(String? relativePath) {
    if (relativePath == null || !imageRelativePattern.hasMatch(relativePath)) return null;
    return relativePath.substring(imagesFolder.length + 1, relativePath.length - '.png'.length);
  }

  /// Saves a copy of [spec] called [name], under a new id, with its own copy of the photo.
  /// Returns the saved copy. A photo that is missing turns the copy into a solid background.
  Future<ThemeSpec> duplicate(ThemeSpec spec, String name) async {
    final uuid = CustomThemeIds.newUuid();
    var copy = spec.copyWith(id: CustomThemeIds.idFor(uuid), name: name);
    final photo = photoUuidOf(spec.background.imagePath);
    if (photo != null) {
      final source = File(imageFileFor(photo));
      if (source.existsSync()) {
        final newPhoto = CustomThemeIds.newUuid();
        await writeImage(newPhoto, await source.readAsBytes());
        copy = copy.copyWith(background: copy.background.copyWith(imagePath: imageRelativePath(newPhoto)));
      } else {
        copy = copy.copyWith(background: const ThemeBackgroundSpec());
      }
    }
    await write(copy);
    return copy;
  }

  /// Saves the background PNG for [uuid] (see [imageRelativePath]).
  Future<void> writeImage(String uuid, Uint8List png) async {
    if (CustomThemeIds.uuidOf(CustomThemeIds.idFor(uuid)) != uuid) {
      throw ArgumentError.value(uuid, 'uuid', 'not a uuid');
    }
    await Directory('$directory$_sep$imagesFolder').create(recursive: true);
    await _atomicWrite(imagePathOf(directory, uuid), png);
  }

  /// Absolute path of the background image for [uuid] (it may not exist).
  String imageFileFor(String uuid) => imagePathOf(directory, uuid);

  /// Deletes the spec and the photo it uses. Missing files are fine.
  Future<void> delete(String id) async {
    final uuid = CustomThemeIds.uuidOf(id);
    if (uuid == null) return;
    final photo = photoUuidOf(readSpecSync(directory, id)?.background.imagePath);
    final path = specPathOf(directory, uuid);
    _parsed.remove(path);
    await _deleteIfExists(path);
    if (photo != null) await deleteImage(photo);
  }

  /// Deletes only the image of [uuid] (a replaced or abandoned photo).
  Future<void> deleteImage(String uuid) => _deleteIfExists(imagePathOf(directory, uuid));

  static Future<void> _atomicWrite(String path, List<int> bytes) async {
    final tmp = File('$path.tmp');
    await tmp.writeAsBytes(bytes, flush: true);
    await tmp.rename(path);
  }

  static Future<void> _deleteIfExists(String path) async {
    final file = File(path);
    if (file.existsSync()) await file.delete();
  }
}
