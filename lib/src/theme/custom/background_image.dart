// SPDX-License-Identifier: GPL-3.0-or-later
//
// Photo backgrounds for custom themes: size checks, decoding for the crop
// screen, and the one-time render of the crop with its blur (dart:ui only, no
// new dependencies). The dim is not baked in: the keyboard paints it live.
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:meta/meta.dart';

/// Largest photo the editor accepts, in pixels (width times height), checked before decoding.
const int kMaxPhotoPixels = 20000000;

/// Widest saved background, in pixels. Above this the image is only sharper, never clearer on a
/// phone, and it costs disk and memory.
const int kMaxBackgroundWidth = 1440;

/// Longest side of the copy kept in memory while cropping.
const int kEditingMaxSide = 2048;

/// The photo cannot be used (too large, not an image). The message is safe to show.
class PhotoRejected implements Exception {
  const PhotoRejected(this.reason);

  final String reason;

  @override
  String toString() => 'PhotoRejected: $reason';
}

/// The pixel size of an encoded image, read from its header without decoding pixels.
/// Throws [PhotoRejected] if the image is not decodable or has more than [kMaxPhotoPixels].
Future<(int, int)> probePhotoSize(Uint8List bytes) async {
  final buffer = await ui.ImmutableBuffer.fromUint8List(bytes);
  ui.ImageDescriptor? descriptor;
  try {
    descriptor = await ui.ImageDescriptor.encoded(buffer);
    final w = descriptor.width;
    final h = descriptor.height;
    if (w <= 0 || h <= 0) throw const PhotoRejected('empty image');
    if (w * h > kMaxPhotoPixels) throw const PhotoRejected('image has too many pixels');
    return (w, h);
  } on PhotoRejected {
    rethrow;
  } on Object {
    throw const PhotoRejected('not a readable image');
  } finally {
    descriptor?.dispose();
    buffer.dispose();
  }
}

/// Decodes [bytes] for the crop screen, downscaled so its longest side is at most [maxSide].
/// Checks the size first (see [probePhotoSize]).
Future<ui.Image> decodePhotoForEditing(Uint8List bytes, {int maxSide = kEditingMaxSide}) async {
  final buffer = await ui.ImmutableBuffer.fromUint8List(bytes);
  ui.ImageDescriptor? descriptor;
  ui.Codec? codec;
  try {
    descriptor = await ui.ImageDescriptor.encoded(buffer);
    final w = descriptor.width;
    final h = descriptor.height;
    if (w <= 0 || h <= 0) throw const PhotoRejected('empty image');
    if (w * h > kMaxPhotoPixels) throw const PhotoRejected('image has too many pixels');
    final scale = math.min(1.0, maxSide / math.max(w, h));
    codec = await descriptor.instantiateCodec(
      targetWidth: math.max(1, (w * scale).round()),
      targetHeight: math.max(1, (h * scale).round()),
    );
    final frame = await codec.getNextFrame();
    return frame.image;
  } on PhotoRejected {
    rethrow;
  } on Object {
    throw const PhotoRejected('not a readable image');
  } finally {
    codec?.dispose();
    descriptor?.dispose();
    buffer.dispose();
  }
}

/// Where the photo sits in the keyboard-sized frame, in logical pixels. [dx] and [dy] are the
/// photo's top-left corner in the frame; [zoom] is 1 for "covers the frame".
@immutable
class PhotoCrop {
  const PhotoCrop({
    required this.sourceWidth,
    required this.sourceHeight,
    required this.frameWidth,
    required this.frameHeight,
    this.zoom = 1,
    this.dx = 0,
    this.dy = 0,
  });

  /// A crop that covers the frame and is centred.
  factory PhotoCrop.centered({
    required int sourceWidth,
    required int sourceHeight,
    required double frameWidth,
    required double frameHeight,
  }) {
    final base = PhotoCrop(
      sourceWidth: sourceWidth,
      sourceHeight: sourceHeight,
      frameWidth: frameWidth,
      frameHeight: frameHeight,
    );
    final s = base.scale;
    return base.copyWith(dx: (frameWidth - sourceWidth * s) / 2, dy: (frameHeight - sourceHeight * s) / 2);
  }

  static const double maxZoom = 4;

  final int sourceWidth;
  final int sourceHeight;
  final double frameWidth;
  final double frameHeight;
  final double zoom;
  final double dx;
  final double dy;

  /// Logical pixels per source pixel at zoom 1 (the smallest scale that covers the frame).
  double get baseScale => math.max(frameWidth / sourceWidth, frameHeight / sourceHeight);

  /// Logical pixels per source pixel.
  double get scale => baseScale * zoom;

  /// The same crop with [zoom] and the pan clamped so the photo always covers the frame. The
  /// zoom is applied around [focalX], [focalY] (frame coordinates), so the point under the fingers stays put.
  PhotoCrop zoomedAround(double newZoom, double focalX, double focalY) {
    final z = newZoom.clamp(1.0, maxZoom);
    final oldScale = scale;
    final newScale = baseScale * z;
    // Keep the source point under the focal point fixed.
    final sx = (focalX - dx) / oldScale;
    final sy = (focalY - dy) / oldScale;
    return copyWith(zoom: z, dx: focalX - sx * newScale, dy: focalY - sy * newScale).clamped();
  }

  /// The same crop panned by ([ddx], [ddy]), clamped.
  PhotoCrop pannedBy(double ddx, double ddy) => copyWith(dx: dx + ddx, dy: dy + ddy).clamped();

  PhotoCrop clamped() {
    final s = scale;
    final w = sourceWidth * s;
    final h = sourceHeight * s;
    final minDx = math.min(0.0, frameWidth - w);
    final minDy = math.min(0.0, frameHeight - h);
    return copyWith(dx: dx.clamp(minDx, 0.0), dy: dy.clamp(minDy, 0.0));
  }

  PhotoCrop copyWith({double? zoom, double? dx, double? dy}) => PhotoCrop(
    sourceWidth: sourceWidth,
    sourceHeight: sourceHeight,
    frameWidth: frameWidth,
    frameHeight: frameHeight,
    zoom: zoom ?? this.zoom,
    dx: dx ?? this.dx,
    dy: dy ?? this.dy,
  );
}

/// Output size for a frame [frameWidth] logical pixels wide on a screen with [devicePixelRatio]:
/// the screen width in pixels, capped at [kMaxBackgroundWidth].
int backgroundWidthFor(double frameWidth, double devicePixelRatio) =>
    math.min(kMaxBackgroundWidth, math.max(1, (frameWidth * devicePixelRatio).round()));

/// Renders [source] cropped by [crop] into a PNG [outWidth] pixels wide (height follows the frame
/// aspect ratio), blurred by [blur] logical pixels. The blur is one `ImageFilter.blur` layer, and
/// the result is rendered once, not on every frame.
Future<Uint8List> renderCropPng({
  required ui.Image source,
  required PhotoCrop crop,
  required int outWidth,
  double blur = 0,
}) async {
  final k = outWidth / crop.frameWidth;
  final outHeight = math.max(1, (crop.frameHeight * k).round());
  final bounds = ui.Rect.fromLTWH(0, 0, outWidth.toDouble(), outHeight.toDouble());

  final recorder = ui.PictureRecorder();
  final canvas = ui.Canvas(recorder, bounds);
  canvas.drawRect(bounds, ui.Paint()..color = const ui.Color(0xFF000000));
  final sigma = blur * k;
  if (sigma > 0) {
    canvas.saveLayer(
      bounds,
      ui.Paint()..imageFilter = ui.ImageFilter.blur(sigmaX: sigma, sigmaY: sigma, tileMode: ui.TileMode.clamp),
    );
  }
  canvas
    ..translate(crop.dx * k, crop.dy * k)
    ..scale(crop.scale * k)
    ..drawImage(source, ui.Offset.zero, ui.Paint()..filterQuality = ui.FilterQuality.medium);
  if (sigma > 0) canvas.restore();

  final picture = recorder.endRecording();
  final image = await picture.toImage(outWidth, outHeight);
  try {
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    if (data == null) throw StateError('png encoding failed');
    return data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
  } finally {
    image.dispose();
    picture.dispose();
  }
}
