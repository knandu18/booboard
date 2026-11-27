// SPDX-License-Identifier: GPL-3.0-or-later
//
// A colour picker for the theme editor: hue, saturation and brightness sliders plus a hex field.
// Returns an opaque ARGB int, or null when cancelled.
import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';
import 'package:booboard/src/app/l10n.dart';

/// Shows the picker, starting from [initial] (ARGB). Null if the user cancels.
Future<int?> showColorPicker(BuildContext context, {required int initial, required String title}) => showDialog<int>(
  context: context,
  builder: (_) => _ColorPickerDialog(initial: initial, title: title),
);

/// `RRGGBB` for [argb], without alpha.
String hexOf(int argb) => (argb & 0xFFFFFF).toRadixString(16).padLeft(6, '0').toUpperCase();

/// Parses six hex digits (an optional leading `#`). Null if malformed.
int? parseHex(String text) {
  final t = text.trim().replaceFirst('#', '');
  if (!RegExp(r'^[0-9a-fA-F]{6}$').hasMatch(t)) return null;
  return 0xFF000000 | int.parse(t, radix: 16);
}

class _ColorPickerDialog extends StatefulWidget {
  const _ColorPickerDialog({required this.initial, required this.title});

  final int initial;
  final String title;

  @override
  State<_ColorPickerDialog> createState() => _ColorPickerDialogState();
}

class _ColorPickerDialogState extends State<_ColorPickerDialog> {
  late HSVColor _hsv = HSVColor.fromColor(Color(widget.initial | 0xFF000000));
  late final TextEditingController _hex = TextEditingController(text: hexOf(widget.initial));
  bool _hexValid = true;

  @override
  void dispose() {
    _hex.dispose();
    super.dispose();
  }

  void _setHsv(HSVColor v) {
    setState(() {
      _hsv = v;
      _hexValid = true;
      _hex.value = TextEditingValue(
        text: hexOf(v.toColor().toARGB32()),
        selection: const TextSelection.collapsed(offset: 6),
      );
    });
  }

  void _onHexChanged(String text) {
    final argb = parseHex(text);
    setState(() {
      _hexValid = argb != null || text.isEmpty;
      if (argb != null) _hsv = HSVColor.fromColor(Color(argb));
    });
  }

  @override
  Widget build(BuildContext context) {
    final color = _hsv.toColor();
    final scheme = Theme.of(context).colorScheme;
    return AlertDialog(
      title: Text(widget.title),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              height: 56,
              decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(16)),
              alignment: Alignment.center,
              child: Text(
                '#${hexOf(color.toARGB32())}',
                style: TextStyle(
                  color: color.computeLuminance() > 0.5 ? const Color(0xFF000000) : const Color(0xFFFFFFFF),
                ),
              ),
            ),
            const SizedBox(height: 12),
            _hsvSlider(
              label: context.l10n.themeHue,
              value: _hsv.hue,
              max: 360,
              onChanged: (v) => _setHsv(_hsv.withHue(v)),
            ),
            _hsvSlider(
              label: context.l10n.themeSaturation,
              value: _hsv.saturation,
              max: 1,
              onChanged: (v) => _setHsv(_hsv.withSaturation(v)),
            ),
            _hsvSlider(
              label: context.l10n.themeBrightness,
              value: _hsv.value,
              max: 1,
              onChanged: (v) => _setHsv(_hsv.withValue(v)),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _hex,
              maxLength: 7,
              onChanged: _onHexChanged,
              decoration: InputDecoration(
                labelText: context.l10n.themeHexLabel,
                prefixText: '#',
                errorText: _hexValid ? null : context.l10n.themeHexError,
                counterText: '',
              ),
              inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[#0-9a-fA-F]'))],
            ),
            const SizedBox(height: 4),
            Text(context.l10n.themePickShadeHint, style: TextStyle(color: scheme.onSurfaceVariant)),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: Text(context.l10n.cancel)),
        FilledButton(onPressed: () => Navigator.of(context).pop(color.toARGB32()), child: Text(context.l10n.useAction)),
      ],
    );
  }

  Widget _hsvSlider({
    required String label,
    required double value,
    required double max,
    required ValueChanged<double> onChanged,
  }) {
    final shown = value.toStringAsFixed(max > 1 ? 0 : 2);
    return Row(
      children: [
        SizedBox(width: 92, child: Text(label)),
        Expanded(
          child: Semantics(
            slider: true,
            label: label,
            value: shown,
            child: Slider(value: value.clamp(0, max), min: 0, max: max, onChanged: onChanged),
          ),
        ),
      ],
    );
  }
}
