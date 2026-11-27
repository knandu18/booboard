// SPDX-License-Identifier: GPL-3.0-or-later
//
// Crop screen for a photo background. The frame has the keyboard's size (screen width times the
// keyboard's content height). Drag to pan, pinch or use the zoom slider, and set the blur. "Use photo"
// renders the crop once with its blur and saves `images/<uuid>.png`. The dim is not baked in: the
// keyboard paints it live from the theme.
import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:material_ui/material_ui.dart';

import '../../core/log.dart';
import '../../theme/custom/background_image.dart';
import '../../theme/custom/custom_theme_store.dart';

import 'package:booboard/src/app/l10n.dart';

/// Blur slider range, in logical pixels of the frame.
const double kMaxBlur = 24;

class PhotoCropResult {
  const PhotoCropResult({required this.uuid, required this.blur});

  /// The saved image is `images/<uuid>.png` in the themes folder.
  final String uuid;
  final double blur;
}

class PhotoCropScreen extends StatefulWidget {
  const PhotoCropScreen({
    super.key,
    required this.photo,
    required this.store,
    required this.photoUuid,
    required this.frameWidth,
    required this.frameHeight,
    required this.devicePixelRatio,
    this.initialBlur = 0,
  });

  /// Encoded photo bytes, as picked. They are checked and decoded here, not in the editor.
  final Uint8List photo;
  final CustomThemeStore store;

  /// Name of the PNG to write, decided by the caller so that a discarded edit can be cleaned up.
  final String photoUuid;

  /// The keyboard's size on this screen, in logical pixels.
  final double frameWidth;
  final double frameHeight;
  final double devicePixelRatio;
  final double initialBlur;

  @override
  State<PhotoCropScreen> createState() => _PhotoCropScreenState();
}

class _PhotoCropScreenState extends State<PhotoCropScreen> {
  ui.Image? _image;
  PhotoCrop? _crop;
  late double _blur = widget.initialBlur;
  String? _error;
  bool _saving = false;

  // Gesture bookkeeping: the scale and focal point of the previous update.
  double _lastScale = 1;
  Offset _lastFocal = Offset.zero;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  Future<void> _load() async {
    try {
      final image = await decodePhotoForEditing(widget.photo);
      if (!mounted) {
        image.dispose();
        return;
      }
      setState(() {
        _image = image;
        _crop = PhotoCrop.centered(
          sourceWidth: image.width,
          sourceHeight: image.height,
          frameWidth: widget.frameWidth,
          frameHeight: widget.frameHeight,
        );
      });
    } on PhotoRejected catch (e) {
      if (mounted) setState(() => _error = e.reason);
    }
  }

  @override
  void dispose() {
    _image?.dispose();
    super.dispose();
  }

  void _onScaleStart(ScaleStartDetails d) {
    _lastScale = 1;
    _lastFocal = d.localFocalPoint;
  }

  void _onScaleUpdate(ScaleUpdateDetails d) {
    final crop = _crop;
    if (crop == null) return;
    final focal = d.localFocalPoint;
    var next = crop.pannedBy(focal.dx - _lastFocal.dx, focal.dy - _lastFocal.dy);
    final delta = d.scale / _lastScale;
    if (delta != 1) next = next.zoomedAround(next.zoom * delta, focal.dx, focal.dy);
    _lastScale = d.scale;
    _lastFocal = focal;
    setState(() => _crop = next);
  }

  void _setZoom(double zoom) {
    final crop = _crop;
    if (crop == null) return;
    setState(() => _crop = crop.zoomedAround(zoom, widget.frameWidth / 2, widget.frameHeight / 2));
  }

  Future<void> _useCrop() async {
    final image = _image;
    final crop = _crop;
    if (image == null || crop == null || _saving) return;
    setState(() => _saving = true);
    try {
      final png = await renderCropPng(
        source: image,
        crop: crop,
        outWidth: backgroundWidthFor(widget.frameWidth, widget.devicePixelRatio),
        blur: _blur,
      );
      await widget.store.writeImage(widget.photoUuid, png);
      if (!mounted) return;
      Navigator.of(context).pop(PhotoCropResult(uuid: widget.photoUuid, blur: _blur));
    } on Object catch (e) {
      BooBoardLog.w(context.l10n.onboardingThemeTitle, 'photo render failed', e.runtimeType);
      if (mounted) {
        setState(() {
          _saving = false;
          _error = context.l10n.themeCropSaveFailed;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final image = _image;
    final crop = _crop;
    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.themeCropTitle),
        actions: [
          TextButton(
            onPressed: image == null || _saving ? null : _useCrop,
            child: _saving
                ? const SizedBox.square(dimension: 18, child: CircularProgressIndicator(strokeWidth: 2))
                : Text(context.l10n.themeUsePhoto),
          ),
        ],
      ),
      body: _error != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  _error!,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: scheme.error),
                ),
              ),
            )
          : image == null || crop == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: EdgeInsets.zero,
              children: [
                Semantics(
                  label: context.l10n.themeCropSemantics,
                  container: true,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onScaleStart: _onScaleStart,
                    onScaleUpdate: _onScaleUpdate,
                    child: ClipRect(
                      child: SizedBox(
                        width: widget.frameWidth,
                        height: widget.frameHeight,
                        child: CustomPaint(
                          painter: _CropPainter(image: image, crop: crop, blur: _blur),
                          size: Size(widget.frameWidth, widget.frameHeight),
                        ),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _CropSlider(
                        label: context.l10n.themeCropZoom,
                        value: crop.zoom,
                        min: 1,
                        max: PhotoCrop.maxZoom,
                        valueText: '${crop.zoom.toStringAsFixed(1)}x',
                        onChanged: _setZoom,
                      ),
                      _CropSlider(
                        label: context.l10n.themeCropBlur,
                        value: _blur,
                        min: 0,
                        max: kMaxBlur,
                        valueText: _blur == 0 ? context.l10n.off : context.l10n.dpValue(_blur.round()),
                        onChanged: (v) => setState(() => _blur = v),
                      ),
                      const SizedBox(height: 8),
                      Text(context.l10n.themeCropNote, style: TextStyle(color: scheme.onSurfaceVariant)),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}

class _CropSlider extends StatelessWidget {
  const _CropSlider({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.valueText,
    required this.onChanged,
  });

  final String label;
  final double value;
  final double min;
  final double max;
  final String valueText;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      SizedBox(width: 56, child: Text(label)),
      Expanded(
        child: Semantics(
          slider: true,
          label: label,
          value: valueText,
          child: Slider(value: value.clamp(min, max), min: min, max: max, label: valueText, onChanged: onChanged),
        ),
      ),
      SizedBox(width: 56, child: Text(valueText, textAlign: TextAlign.end)),
    ],
  );
}

/// Draws the photo in the frame, with the same blur layer as the rendered file.
class _CropPainter extends CustomPainter {
  _CropPainter({required this.image, required this.crop, required this.blur});

  final ui.Image image;
  final PhotoCrop crop;
  final double blur;

  @override
  void paint(ui.Canvas canvas, ui.Size size) {
    final bounds = ui.Offset.zero & size;
    canvas.drawRect(bounds, ui.Paint()..color = const ui.Color(0xFF000000));
    final src = ui.Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble());
    final dst = ui.Rect.fromLTWH(crop.dx, crop.dy, crop.sourceWidth * crop.scale, crop.sourceHeight * crop.scale);
    if (blur > 0) {
      canvas.saveLayer(
        bounds,
        ui.Paint()..imageFilter = ui.ImageFilter.blur(sigmaX: blur, sigmaY: blur, tileMode: ui.TileMode.clamp),
      );
    }
    canvas.drawImageRect(image, src, dst, ui.Paint()..filterQuality = ui.FilterQuality.medium);
    if (blur > 0) canvas.restore();
  }

  @override
  bool shouldRepaint(_CropPainter old) => !identical(old.crop, crop) || old.image != image || old.blur != blur;
}
