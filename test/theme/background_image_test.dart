// SPDX-License-Identifier: GPL-3.0-or-later
//
// Photo backgrounds: the crop maths, the size checks, and the one-time render (crop plus blur) on
// a small synthetic image.
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';
import 'package:booboard/src/theme/custom/background_image.dart';

/// A small gradient image, drawn on the engine (so this runs inside runAsync).
Future<ui.Image> _gradient(int w, int h) async {
  final recorder = ui.PictureRecorder();
  final canvas = ui.Canvas(recorder, ui.Rect.fromLTWH(0, 0, w.toDouble(), h.toDouble()));
  final paint = ui.Paint()
    ..shader = ui.Gradient.linear(ui.Offset.zero, ui.Offset(w.toDouble(), h.toDouble()), const [
      ui.Color(0xFFFF0000),
      ui.Color(0xFF0000FF),
    ]);
  canvas.drawRect(ui.Rect.fromLTWH(0, 0, w.toDouble(), h.toDouble()), paint);
  final picture = recorder.endRecording();
  final image = await picture.toImage(w, h);
  picture.dispose();
  return image;
}

Future<Uint8List> _png(ui.Image image) async {
  final data = await image.toByteData(format: ui.ImageByteFormat.png);
  return data!.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
}

void main() {
  group('PhotoCrop', () {
    test('centred crop covers the frame', () {
      final crop = PhotoCrop.centered(sourceWidth: 400, sourceHeight: 300, frameWidth: 412, frameHeight: 268);
      expect(crop.scale, greaterThanOrEqualTo(412 / 400));
      expect(crop.sourceWidth * crop.scale, greaterThanOrEqualTo(412 - 0.001));
      expect(crop.sourceHeight * crop.scale, greaterThanOrEqualTo(268 - 0.001));
      expect(crop.dx, lessThanOrEqualTo(0));
      expect(crop.dy, lessThanOrEqualTo(0));
    });

    test('zoom keeps the point under the focus fixed', () {
      final crop = PhotoCrop.centered(sourceWidth: 400, sourceHeight: 300, frameWidth: 400, frameHeight: 300);
      const focalX = 150.0;
      const focalY = 120.0;
      final before = ((focalX - crop.dx) / crop.scale, (focalY - crop.dy) / crop.scale);
      final zoomed = crop.zoomedAround(2.5, focalX, focalY);
      expect(zoomed.zoom, 2.5);
      final after = ((focalX - zoomed.dx) / zoomed.scale, (focalY - zoomed.dy) / zoomed.scale);
      expect(after.$1, closeTo(before.$1, 1e-6));
      expect(after.$2, closeTo(before.$2, 1e-6));
    });

    test('pan and zoom are clamped so the photo always covers the frame', () {
      final crop = PhotoCrop.centered(sourceWidth: 400, sourceHeight: 300, frameWidth: 400, frameHeight: 300);
      final far = crop.pannedBy(10000, 10000);
      expect(far.dx, 0);
      expect(far.dy, 0);
      final farOther = crop.pannedBy(-10000, -10000);
      expect(farOther.sourceWidth * farOther.scale + farOther.dx, closeTo(400, 1e-6));
      expect(crop.zoomedAround(99, 0, 0).zoom, PhotoCrop.maxZoom);
      expect(crop.zoomedAround(0.1, 0, 0).zoom, 1);
    });

    test('output width is the screen width in pixels, capped at 1440', () {
      expect(backgroundWidthFor(412, 2.625), 1082);
      expect(backgroundWidthFor(412, 4), kMaxBackgroundWidth);
      expect(backgroundWidthFor(0.2, 1), 1);
    });
  });

  testWidgets('a photo above 20 megapixels or a non-image is rejected before decoding', (tester) async {
    await tester.runAsync(() async {
      await expectLater(probePhotoSize(Uint8List.fromList([1, 2, 3, 4])), throwsA(isA<PhotoRejected>()));
      await expectLater(decodePhotoForEditing(Uint8List.fromList([9, 9])), throwsA(isA<PhotoRejected>()));
    });
    expect(kMaxPhotoPixels, 20000000);
  });

  testWidgets('decoding downscales the longest side, and probing reads the size', (tester) async {
    await tester.runAsync(() async {
      final wide = await _gradient(2600, 100);
      final bytes = await _png(wide);
      wide.dispose();

      final size = await probePhotoSize(bytes);
      expect(size, (2600, 100));

      final decoded = await decodePhotoForEditing(bytes);
      expect(decoded.width, kEditingMaxSide);
      expect(decoded.height, (100 * kEditingMaxSide / 2600).round());
      decoded.dispose();
    });
  });

  testWidgets('the crop render is one PNG at the requested width, with the frame aspect ratio', (tester) async {
    await tester.runAsync(() async {
      final source = await _gradient(64, 48);
      final crop = PhotoCrop.centered(sourceWidth: 64, sourceHeight: 48, frameWidth: 412, frameHeight: 268);
      final png = await renderCropPng(source: source, crop: crop, outWidth: 206);
      expect(png.length, greaterThan(0));
      final (w, h) = await probePhotoSize(png);
      expect(w, 206);
      expect(h, (268 * 206 / 412).round());

      final blurred = await renderCropPng(source: source, crop: crop, outWidth: 206, blur: 8);
      expect(blurred, isNot(equals(png)), reason: 'the blur layer changes the picture');
      source.dispose();
    });
  });
}
