// SPDX-License-Identifier: GPL-3.0-or-later
//
// The theme editor. A static keyboard preview stays pinned at the top and updates as values change.
// Saving writes `<themes>/<uuid>.json` (and its photo), selects a new theme, and bumps
// appearance.customThemeRevision so a theme in use is re-read at once. Leaving with unsaved changes
// asks first, and discards any photo that was only drafted.
import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:image_picker/image_picker.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/log.dart';
import '../../keyboard/preview/keyboard_preview.dart';
import '../../keyboard/view/keyboard_metrics.dart';
import '../../settings/booboard_settings.dart';
import '../../theme/custom/background_image.dart';
import '../../theme/custom/custom_theme_store.dart';
import '../../theme/presets.dart';
import '../../theme/scheme_builder.dart';
import '../../theme/theme_spec.dart';
import '../app_services.dart';
import '../common/settings_widgets.dart';
import 'color_picker_dialog.dart';
import 'photo_crop_screen.dart';
import 'theme_support.dart';

import 'package:booboard/src/app/l10n.dart';

/// Motion presets and the press-animation intensity each maps to (see [ThemeSpec.motionIntensity]).
/// The press-animation intensity of each motion preset, in the order the choices are shown.
const List<double> _motionValues = [0, 0.5, 1, 2];

List<(String, double)> _motionChoices(AppLocalizations l10n) => [
  (l10n.themeMotionOff, 0),
  (l10n.themeMotionSubtle, 0.5),
  (l10n.themeMotionStandard, 1),
  (l10n.themeMotionBouncy, 2),
];

List<(ThemeSchemeVariant, String)> _variantChoices(AppLocalizations l10n) => [
  (ThemeSchemeVariant.tonalSpot, l10n.themeSchemeTonalSpot),
  (ThemeSchemeVariant.vibrant, l10n.themeSchemeVibrant),
  (ThemeSchemeVariant.expressive, l10n.themeSchemeExpressive),
  (ThemeSchemeVariant.fidelity, l10n.themeSchemeFidelity),
  (ThemeSchemeVariant.content, l10n.themeSchemeContent),
  (ThemeSchemeVariant.monochrome, l10n.themeSchemeMonochrome),
  (ThemeSchemeVariant.neutral, l10n.themeSchemeNeutral),
  (ThemeSchemeVariant.rainbow, l10n.themeSchemeRainbow),
  (ThemeSchemeVariant.fruitSalad, l10n.themeSchemeFruitSalad),
];

/// Edits a custom theme. [themeId] null starts a new one.
class ThemeEditorScreen extends StatefulWidget {
  const ThemeEditorScreen({super.key, this.themeId});

  final String? themeId;

  @override
  State<ThemeEditorScreen> createState() => _ThemeEditorScreenState();
}

class _ThemeEditorScreenState extends State<ThemeEditorScreen> {
  final ThemePreviewCache _previews = ThemePreviewCache();
  final TextEditingController _nameController = TextEditingController();

  AppServices? _services;
  CustomThemeStore? _store;
  String? _themesDir;
  List<int>? _palettes;
  String? _loadError;
  bool _started = false;
  bool _loaded = false;

  /// The theme as last saved (or the defaults for a new one).
  late ThemeSpec _saved;

  /// The working copy.
  late ThemeSpec _draft;
  late String _uuid;
  bool _isNew = true;

  /// Photos created in this visit that are not saved yet. Discarded with the draft.
  final Set<String> _draftPhotos = {};

  /// The photo as picked, kept so the crop can be opened again without picking.
  Uint8List? _photoBytes;

  // Global settings this screen also edits. They are written on save.
  DarkModePreference _darkMode = DarkModePreference.system;
  bool _pureBlack = false;
  ContrastPreference _contrast = ContrastPreference.standard;
  double _heightScale = 1;
  bool _hintLabels = true;
  bool _trailOn = true;
  double _trailWidth = 6;
  int _trailFade = 300;

  bool _dirty = false;
  bool _saving = false;
  bool _closing = false;

  @override
  void initState() {
    super.initState();
    _nameController.addListener(_onNameChanged);
  }

  /// Only typing counts as an edit: loading the name sets it while [_loaded] is still false.
  void _onNameChanged() {
    if (!_loaded) return;
    setState(() => _dirty = true);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    _services = AppScope.of(context);
    unawaited(_load());
  }

  @override
  void dispose() {
    _nameController.dispose();
    _previews.clear();
    super.dispose();
  }

  Future<void> _load() async {
    final l10n = context.l10n;
    final services = _services!;
    final settings = services.settings.value;
    _darkMode = settings.appearance.darkMode;
    _pureBlack = settings.appearance.pureBlack;
    _contrast = settings.appearance.contrast;
    _heightScale = settings.appearance.heightScale;
    _hintLabels = settings.typing.hintLabels;
    _trailOn = settings.swipe.showTrail;
    _trailWidth = settings.swipe.trailWidth;
    _trailFade = settings.swipe.trailFadeMs;
    try {
      _palettes = (await services.platform.getSystemColors())?.palettes;
    } on Object catch (e) {
      BooBoardLog.w(l10n.onboardingThemeTitle, 'system colours unavailable', e.runtimeType);
    }
    final dataDir = await services.platform.getDataDirectory();
    _themesDir = themesDirectoryFor(dataDir);
    _store = CustomThemeStore(_themesDir!);

    ThemeSpec? stored;
    final id = widget.themeId;
    if (id != null) {
      stored = await _store!.read(id);
      if (stored == null) {
        if (mounted) setState(() => _loadError = l10n.themeOpenFailed);
        return;
      }
    }
    final spec = stored ?? _newSpec();
    final uuid = CustomThemeIds.uuidOf(spec.id);
    if (uuid == null) {
      if (mounted) setState(() => _loadError = l10n.themeOpenFailed);
      return;
    }
    if (!mounted) return;
    setState(() {
      _saved = spec;
      _draft = spec;
      _uuid = uuid;
      _isNew = stored == null;
      _nameController.text = spec.name;
      _loaded = true;
    });
  }

  /// Defaults for a new theme: the brand seed, tonal spot, a pill-shaped key style.
  ThemeSpec _newSpec() => ThemeSpec(
    id: newCustomThemeId(),
    name: context.l10n.themeDefaultName,
    colorSource: ThemeColorSource.seed,
    seedColor: booboardYellow,
    variant: ThemeSchemeVariant.tonalSpot,
  );

  // ---------------------------------------------------------------------------
  // Editing helpers
  // ---------------------------------------------------------------------------

  void _edit(void Function() change) => setState(() {
    change();
    _dirty = true;
  });

  void _setDraft(ThemeSpec Function(ThemeSpec d) change) => _edit(() => _draft = change(_draft));

  bool _isDark(BuildContext context) =>
      _darkMode == DarkModePreference.dark ||
      (_darkMode == DarkModePreference.system && MediaQuery.platformBrightnessOf(context) == Brightness.dark);

  double get _contrastLevel => switch (_contrast) {
    ContrastPreference.standard => 0,
    ContrastPreference.medium => 0.5,
    ContrastPreference.high => 1,
  };

  /// The colour scheme the draft gives for [dark], including custom roles and pure black.
  ColorScheme _scheme(bool dark) => buildColorScheme(
    _draft,
    dark ? Brightness.dark : Brightness.light,
    palettes: _palettes,
    contrastLevel: _contrastLevel,
    pureBlack: _pureBlack,
  );

  /// The global settings as the draft would leave them (the preview uses these).
  BooBoardSettings _settingsDraft(BooBoardSettings base) => base.copyWith(
    appearance: base.appearance.copyWith(
      darkMode: _darkMode,
      pureBlack: _pureBlack,
      contrast: _contrast,
      heightScale: _heightScale,
    ),
    typing: base.typing.copyWith(hintLabels: _hintLabels),
    swipe: base.swipe.copyWith(showTrail: _trailOn, trailWidth: _trailWidth, trailFadeMs: _trailFade),
  );

  void _snack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.maybeOf(context)?.showSnackBar(SnackBar(content: Text(message)));
  }

  // ---------------------------------------------------------------------------
  // Leaving and saving
  // ---------------------------------------------------------------------------

  Future<void> _leave([ThemeSpec? result]) async {
    // The rebuild that lets PopScope allow the pop happens within a frame; the short delay waits for it.
    setState(() => _closing = true);
    await Future<void>.delayed(const Duration(milliseconds: 100));
    if (mounted) Navigator.of(context).pop(result);
  }

  Future<void> _requestClose() async {
    if (!_dirty) {
      await _leave();
      return;
    }
    final discard = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.l10n.themeDiscardTitle),
        content: Text(context.l10n.themeDiscardBody),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: Text(context.l10n.themeKeepEditing)),
          FilledButton(onPressed: () => Navigator.of(context).pop(true), child: Text(context.l10n.themeDiscard)),
        ],
      ),
    );
    if (discard != true) return;
    await _discardDrafts();
    await _leave();
  }

  Future<void> _discardDrafts() async {
    final store = _store;
    if (store == null) return;
    for (final photo in _draftPhotos) {
      await store.deleteImage(photo);
    }
    _draftPhotos.clear();
  }

  Future<void> _save() async {
    final l10n = context.l10n;
    final services = _services;
    final store = _store;
    final name = _nameController.text.trim();
    if (services == null || store == null || name.isEmpty || _saving) return;
    setState(() => _saving = true);
    final spec = _draft.copyWith(id: CustomThemeIds.idFor(_uuid), name: name);
    try {
      final newPhoto = CustomThemeStore.photoUuidOf(spec.background.imagePath);
      final oldPhoto = CustomThemeStore.photoUuidOf(_saved.background.imagePath);
      await store.write(spec);
      if (oldPhoto != null && oldPhoto != newPhoto) await store.deleteImage(oldPhoto);
      for (final photo in _draftPhotos) {
        if (photo != newPhoto) await store.deleteImage(photo);
      }
      _draftPhotos.clear();
      final wasNew = _isNew;
      await services.settings.update(
        (c) => c.copyWith(
          appearance: c.appearance.copyWith(
            themeId: wasNew ? spec.id : null,
            darkMode: _darkMode,
            pureBlack: _pureBlack,
            contrast: _contrast,
            heightScale: _heightScale,
            customThemeRevision: c.appearance.customThemeRevision + 1,
          ),
          typing: c.typing.copyWith(hintLabels: _hintLabels),
          swipe: c.swipe.copyWith(showTrail: _trailOn, trailWidth: _trailWidth, trailFadeMs: _trailFade),
        ),
        sections: const [SettingsSection.appearance, SettingsSection.typing, SettingsSection.swipe],
      );
      _saved = spec;
      _isNew = false;
      _dirty = false;
    } on Object catch (e) {
      BooBoardLog.w(l10n.onboardingThemeTitle, 'save failed', e.runtimeType);
      if (mounted) setState(() => _saving = false);
      _snack(l10n.themeSaveFailed);
      return;
    }
    if (mounted) setState(() => _saving = false);
    await _leave(spec);
  }

  // ---------------------------------------------------------------------------
  // Photo background
  // ---------------------------------------------------------------------------

  Future<void> _choosePhoto() async {
    final l10n = context.l10n;
    final store = _store;
    if (store == null) return;
    final XFile? picked;
    try {
      picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    } on Object catch (e) {
      BooBoardLog.w(l10n.onboardingThemeTitle, 'photo picker failed', e.runtimeType);
      _snack(l10n.themePhotoPickerFailed);
      return;
    }
    if (picked == null) return;
    final bytes = await picked.readAsBytes();
    try {
      await probePhotoSize(bytes);
    } on PhotoRejected catch (e) {
      _snack(e.reason);
      return;
    }
    _photoBytes = bytes;
    await _openCrop(bytes, _draft.background.blur);
  }

  Future<void> _openCrop(Uint8List bytes, double blur) async {
    final store = _store;
    final services = _services;
    if (store == null || services == null || !mounted) return;
    final size = MediaQuery.sizeOf(context);
    final photoUuid = CustomThemeIds.newUuid();
    final frameHeight = KeyboardMetrics.contentHeight(_settingsDraft(services.settings.value), landscape: false);
    final result = await Navigator.of(context).push<PhotoCropResult>(
      MaterialPageRoute<PhotoCropResult>(
        builder: (_) => PhotoCropScreen(
          photo: bytes,
          store: store,
          photoUuid: photoUuid,
          frameWidth: size.width,
          frameHeight: frameHeight,
          devicePixelRatio: MediaQuery.devicePixelRatioOf(context),
          initialBlur: blur,
        ),
      ),
    );
    if (result == null || !mounted) return;
    final previous = CustomThemeStore.photoUuidOf(_draft.background.imagePath);
    _edit(() {
      _draftPhotos.add(result.uuid);
      _draft = _draft.copyWith(
        background: _draft.background.copyWith(
          type: ThemeBackgroundType.image,
          imagePath: CustomThemeStore.imageRelativePath(result.uuid),
          blur: result.blur,
        ),
      );
    });
    // A photo drafted in this visit that is now replaced can go at once. A saved one waits for Save.
    if (previous != null && _draftPhotos.remove(previous)) await store.deleteImage(previous);
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final services = _services;
    if (!_loaded || services == null) {
      return Scaffold(
        appBar: AppBar(title: Text(context.l10n.onboardingThemeTitle)),
        body: Center(
          child: _loadError != null
              ? Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(_loadError!, textAlign: TextAlign.center),
                )
              : const CircularProgressIndicator(),
        ),
      );
    }
    final dark = _isDark(context);
    final reduce = MediaQuery.disableAnimationsOf(context);
    final previewSettings = _settingsDraft(services.settings.value);
    final theme = _previews.resolve(
      _draft,
      themesDirectory: _themesDir,
      dark: dark,
      pureBlack: _pureBlack,
      contrast: _contrast,
      palettes: _palettes,
      disableAnimations: reduce,
    );
    final scheme = _scheme(dark);
    final canSave = _nameController.text.trim().isNotEmpty && !_saving;
    final previewExtent = KeyboardMetrics.contentHeight(previewSettings, landscape: false) + 16;

    return PopScope(
      canPop: !_dirty || _closing,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) unawaited(_requestClose());
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(_isNew ? context.l10n.themeNewTitle : context.l10n.themeEditTitle),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilledButton(onPressed: canSave ? _save : null, child: Text(context.l10n.save)),
            ),
          ],
        ),
        body: CustomScrollView(
          slivers: [
            SliverPersistentHeader(
              pinned: true,
              delegate: _PreviewHeaderDelegate(
                extent: previewExtent,
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: KeyboardPreview(theme: theme, settings: previewSettings),
                  ),
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
              sliver: SliverList.list(
                children: _sections(context, services, dark: dark, scheme: scheme),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _sections(
    BuildContext context,
    AppServices services, {
    required bool dark,
    required ColorScheme scheme,
  }) {
    final draft = _draft;
    final dynamicSource = draft.colorSource == ThemeColorSource.dynamic;
    final hasPalettes = _palettes != null;
    final bg = draft.background;
    final photoUuid = CustomThemeStore.photoUuidOf(bg.imagePath);
    final store = _store;
    final photoPath = photoUuid == null || store == null ? null : store.imageFileFor(photoUuid);
    final hasPhoto = photoPath != null && File(photoPath).existsSync();

    return [
      SettingsGroup(
        title: context.l10n.themeNameField,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: TextField(
              controller: _nameController,
              maxLength: kThemeNameMax,
              decoration: InputDecoration(
                labelText: context.l10n.themeNameLabel,
                errorText: _nameController.text.trim().isEmpty ? context.l10n.themeNameRequired : null,
              ),
            ),
          ),
        ],
      ),
      SettingsGroup(
        title: context.l10n.themeSectionLook,
        children: [
          _ControlTile(
            title: context.l10n.themeDarkMode,
            child: SegmentedButton<DarkModePreference>(
              segments: [
                ButtonSegment(value: DarkModePreference.system, label: Text(context.l10n.themeChoiceSystem)),
                ButtonSegment(value: DarkModePreference.light, label: Text(context.l10n.themeChoiceLight)),
                ButtonSegment(value: DarkModePreference.dark, label: Text(context.l10n.themeChoiceDark)),
              ],
              selected: {_darkMode},
              onSelectionChanged: (s) => _edit(() => _darkMode = s.first),
            ),
          ),
          SettingsSwitchTile(
            title: context.l10n.themePureBlack,
            subtitle: dark ? context.l10n.themePureBlackBody : context.l10n.themePureBlackOnlyDark,
            icon: Icons.dark_mode_outlined,
            value: _pureBlack,
            onChanged: dark ? (v) => _edit(() => _pureBlack = v) : null,
          ),
          _ControlTile(
            title: context.l10n.themeContrast,
            child: SegmentedButton<ContrastPreference>(
              segments: [
                ButtonSegment(value: ContrastPreference.standard, label: Text(context.l10n.themeChoiceStandard)),
                ButtonSegment(value: ContrastPreference.medium, label: Text(context.l10n.themeChoiceMedium)),
                ButtonSegment(value: ContrastPreference.high, label: Text(context.l10n.themeChoiceHigh)),
              ],
              selected: {_contrast},
              onSelectionChanged: (s) => _edit(() => _contrast = s.first),
            ),
          ),
          _SliderRow(
            label: context.l10n.themeKeyboardHeight,
            value: _heightScale,
            min: 0.7,
            max: 1.5,
            valueText: '${(_heightScale * 100).round()}%',
            onChanged: (v) => _edit(() => _heightScale = v),
          ),
        ],
      ),
      SettingsGroup(
        title: context.l10n.themeSectionColours,
        children: [
          _ControlTile(
            title: context.l10n.themeSource,
            child: SegmentedButton<ThemeColorSource>(
              segments: [
                ButtonSegment(
                  value: ThemeColorSource.dynamic,
                  enabled: hasPalettes,
                  label: Text(context.l10n.themeSourceWallpaper),
                ),
                ButtonSegment(value: ThemeColorSource.seed, label: Text(context.l10n.themeSourceSeed)),
                ButtonSegment(value: ThemeColorSource.custom, label: Text(context.l10n.themeSourcePerRole)),
              ],
              selected: {dynamicSource && !hasPalettes ? ThemeColorSource.seed : draft.colorSource},
              onSelectionChanged: (s) => _setDraft((d) => d.copyWith(colorSource: s.first)),
            ),
          ),
          if (!hasPalettes)
            Padding(
              padding: EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Text(context.l10n.themeWallpaperNeedsAndroid12),
            ),
          if (!dynamicSource) ...[
            _ControlTile(
              title: context.l10n.themeSeedColour,
              child: _SeedSwatches(
                selected: draft.seedColor,
                onPick: (argb) => _setDraft((d) => d.copyWith(seedColor: argb)),
                onCustom: () async {
                  final argb = await showColorPicker(
                    context,
                    initial: draft.seedColor,
                    title: context.l10n.themeSeedColour,
                  );
                  if (argb != null) _setDraft((d) => d.copyWith(seedColor: argb));
                },
              ),
            ),
            _ControlTile(
              title: context.l10n.themeScheme,
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final (variant, label) in _variantChoices(context.l10n))
                    ChoiceChip(
                      label: Text(label),
                      selected: draft.variant == variant,
                      onSelected: (_) => _setDraft((d) => d.copyWith(variant: variant)),
                    ),
                ],
              ),
            ),
          ],
          if (draft.colorSource == ThemeColorSource.custom)
            ExpansionTile(
              title: Text(context.l10n.themeColourRoles),
              subtitle: Text(context.l10n.themeEditingColours(dark ? 'dark' : 'light')),
              children: [
                for (final role in kEditorRoles)
                  _RoleTile(
                    label: _roleLabel(role),
                    color: roleColor(scheme, role),
                    overridden: (dark ? (draft.customRolesDark ?? draft.customRoles) : draft.customRoles).containsKey(
                      role,
                    ),
                    onPick: () async {
                      final argb = await showColorPicker(
                        context,
                        initial: roleColor(scheme, role)?.toARGB32() ?? 0xFF000000,
                        title: _roleLabel(role),
                      );
                      if (argb != null) _setRole(role, argb, dark: dark);
                    },
                    onReset: () => _setRole(role, null, dark: dark),
                  ),
                TextButton(
                  onPressed: () => _setDraft((d) => d.copyWith(customRoles: const {}, customRolesDark: null)),
                  child: Text(context.l10n.themeResetRoles),
                ),
              ],
            ),
        ],
      ),
      SettingsGroup(
        title: context.l10n.typingKeys,
        children: [
          _SliderRow(
            label: context.l10n.themeShape,
            value: 1 - draft.keyRadius * 2,
            min: 0,
            max: 1,
            valueText: _shapeName(draft.keyRadius, context.l10n),
            leftHint: context.l10n.themeShapePill,
            rightHint: context.l10n.themeShapeSquare,
            onChanged: (v) => _setDraft((d) {
              final radius = (1 - v) * 0.5;
              return d.copyWith(keyRadius: radius, fontRoundness: radius * 200);
            }),
          ),
          SettingsSwitchTile(
            title: context.l10n.themeKeyBorders,
            value: draft.borderWidth > 0,
            onChanged: (on) => _setDraft((d) => d.copyWith(borderWidth: on ? 1.0 : 0.0)),
          ),
          if (draft.borderWidth > 0)
            _SliderRow(
              label: context.l10n.themeBorderWidth,
              value: draft.borderWidth,
              min: 1,
              max: 4,
              divisions: 6,
              valueText: context.l10n.dpValue(draft.borderWidth),
              onChanged: (v) => _setDraft((d) => d.copyWith(borderWidth: v)),
            ),
          _SliderRow(
            label: context.l10n.themeKeyGap,
            value: draft.keyGap,
            min: 0,
            max: 16,
            valueText: context.l10n.dpValue(draft.keyGap.round()),
            onChanged: (v) => _setDraft((d) => d.copyWith(keyGap: v)),
          ),
          _SliderRow(
            label: context.l10n.themeFontWeight,
            value: draft.labelWeight.toDouble(),
            min: 100,
            max: 900,
            divisions: 16,
            valueText: '${draft.labelWeight}',
            onChanged: (v) => _setDraft((d) => d.copyWith(labelWeight: v.round())),
          ),
          _SliderRow(
            label: context.l10n.themeFontSize,
            value: draft.labelScale,
            min: 0.7,
            max: 1.5,
            valueText: '${(draft.labelScale * 100).round()}%',
            onChanged: (v) => _setDraft((d) => d.copyWith(labelScale: v)),
          ),
          SettingsSwitchTile(
            title: context.l10n.themeHintCharacters,
            subtitle: context.l10n.themeHintCharactersBody,
            value: _hintLabels,
            onChanged: (v) => _edit(() => _hintLabels = v),
          ),
        ],
      ),
      SettingsGroup(
        title: context.l10n.themeBackground,
        children: [
          _ControlTile(
            title: context.l10n.themeBackgroundType,
            child: SegmentedButton<ThemeBackgroundType>(
              segments: [
                ButtonSegment(value: ThemeBackgroundType.solid, label: Text(context.l10n.themeTypeSolid)),
                ButtonSegment(value: ThemeBackgroundType.gradient, label: Text(context.l10n.themeTypeGradient)),
                ButtonSegment(value: ThemeBackgroundType.image, label: Text(context.l10n.themeTypePhoto)),
              ],
              selected: {bg.type},
              onSelectionChanged: (s) => _setDraft((d) => d.copyWith(background: _backgroundOf(d, s.first))),
            ),
          ),
          if (bg.type == ThemeBackgroundType.gradient) ..._gradientControls(bg),
          if (bg.type == ThemeBackgroundType.image) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
              child: hasPhoto
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.file(
                        File(photoPath),
                        height: 96,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => const SizedBox(height: 96),
                      ),
                    )
                  : Text(context.l10n.themeNoPhotoYet),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Wrap(
                spacing: 8,
                children: [
                  FilledButton.tonal(onPressed: _choosePhoto, child: Text(context.l10n.themeChoosePhoto)),
                  if (_photoBytes != null && hasPhoto)
                    OutlinedButton(
                      onPressed: () => unawaited(_openCrop(_photoBytes!, bg.blur)),
                      child: Text(context.l10n.themeEditCrop),
                    ),
                ],
              ),
            ),
            _SliderRow(
              label: context.l10n.themeDim,
              value: bg.dim,
              min: 0,
              max: 0.8,
              valueText: '${(bg.dim * 100).round()}%',
              onChanged: (v) => _setDraft((d) => d.copyWith(background: d.background.copyWith(dim: v))),
            ),
          ],
        ],
      ),
      SettingsGroup(
        title: context.l10n.themeSectionPopups,
        children: [
          SettingsSwitchTile(
            title: context.l10n.themeSolidPopups,
            subtitle: dynamicSource
                ? context.l10n.themeSolidPopupsBodyWallpaper
                : context.l10n.themeSolidPopupsBodyPrimary,
            value: draft.accents.popupFill != null,
            onChanged: dynamicSource
                ? null
                : (on) => _setDraft((d) => d.copyWith(accents: _solidPopups(d, on, scheme))),
          ),
          SettingsSwitchTile(
            title: context.l10n.themeSwipeTrail,
            value: _trailOn,
            onChanged: (v) => _edit(() => _trailOn = v),
          ),
          if (_trailOn) ...[
            _SliderRow(
              label: context.l10n.typingTrailWidth,
              value: _trailWidth,
              min: 2,
              max: 16,
              valueText: context.l10n.dpValue(_trailWidth.round()),
              onChanged: (v) => _edit(() => _trailWidth = v),
            ),
            _SliderRow(
              label: context.l10n.typingTrailFade,
              value: _trailFade.toDouble(),
              min: 0,
              max: 2000,
              divisions: 20,
              valueText: _trailFade == 0 ? context.l10n.themeTrailInstant : context.l10n.milliseconds(_trailFade),
              onChanged: (v) => _edit(() => _trailFade = v.round()),
            ),
          ],
          _ControlTile(
            title: context.l10n.themeTrailColours,
            child: Row(
              children: [
                _ColorChip(
                  label: context.l10n.themeTrailStart,
                  color: Color(draft.accents.trailStart ?? scheme.primary.toARGB32()),
                  onTap: () async {
                    final argb = await showColorPicker(
                      context,
                      initial: draft.accents.trailStart ?? scheme.primary.toARGB32(),
                      title: context.l10n.themeTrailStartTitle,
                    );
                    if (argb != null) {
                      _setDraft((d) => d.copyWith(accents: d.accents.copyWith(trailStart: argb)));
                    }
                  },
                ),
                const SizedBox(width: 12),
                _ColorChip(
                  label: context.l10n.themeTrailEnd,
                  color: Color(draft.accents.trailEnd ?? scheme.tertiary.toARGB32()),
                  onTap: () async {
                    final argb = await showColorPicker(
                      context,
                      initial: draft.accents.trailEnd ?? scheme.tertiary.toARGB32(),
                      title: context.l10n.themeTrailEndTitle,
                    );
                    if (argb != null) {
                      _setDraft((d) => d.copyWith(accents: d.accents.copyWith(trailEnd: argb)));
                    }
                  },
                ),
                const Spacer(),
                TextButton(
                  onPressed: () => _setDraft((d) => d.copyWith(accents: d.accents.copyWith(clearTrail: true))),
                  child: Text(context.l10n.voicePackAutomatic),
                ),
              ],
            ),
          ),
        ],
      ),
      SettingsGroup(
        title: context.l10n.themeSectionMotion,
        children: [
          _ControlTile(
            title: context.l10n.themeKeyPressAnimation,
            child: SegmentedButton<double>(
              segments: [
                for (final (label, value) in _motionChoices(context.l10n))
                  ButtonSegment(value: value, label: Text(label)),
              ],
              selected: {_nearestMotion(draft.motionIntensity)},
              onSelectionChanged: (s) => _setDraft((d) => d.copyWith(motionIntensity: s.first)),
            ),
          ),
          if (MediaQuery.disableAnimationsOf(context))
            Padding(padding: EdgeInsets.fromLTRB(16, 0, 16, 12), child: Text(context.l10n.themeReduceMotion)),
        ],
      ),
    ];
  }

  List<Widget> _gradientControls(ThemeBackgroundSpec bg) {
    final stops = bg.gradientColors.isEmpty ? const [0xFFFFE08C, 0xFFF5B700] : bg.gradientColors;
    void setStops(List<int> next) =>
        _setDraft((d) => d.copyWith(background: d.background.copyWith(gradientColors: next)));
    return [
      _ControlTile(
        title: context.l10n.themeSectionColours,
        child: Wrap(
          spacing: 12,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            for (var i = 0; i < stops.length; i++)
              _ColorChip(
                label: context.l10n.themeStopLabel('${i + 1}'),
                color: Color(stops[i]),
                onTap: () async {
                  final argb = await showColorPicker(
                    context,
                    initial: stops[i],
                    title: context.l10n.themePickStopTitle('${i + 1}'),
                  );
                  if (argb == null) return;
                  final next = [...stops]..[i] = argb;
                  setStops(next);
                },
              ),
            if (stops.length < 3)
              TextButton.icon(
                onPressed: () => setStops([...stops, stops.last]),
                icon: const Icon(Icons.add),
                label: Text(context.l10n.themeAddStop),
              ),
            if (stops.length > 2)
              TextButton.icon(
                onPressed: () => setStops(stops.sublist(0, stops.length - 1)),
                icon: const Icon(Icons.remove),
                label: Text(context.l10n.themeRemoveStop),
              ),
          ],
        ),
      ),
      _SliderRow(
        label: context.l10n.themeAngle,
        value: bg.gradientAngle,
        min: 0,
        max: 360,
        valueText: '${bg.gradientAngle.round()}°',
        onChanged: (v) => _setDraft((d) => d.copyWith(background: d.background.copyWith(gradientAngle: v))),
      ),
    ];
  }

  /// The background for a new [type], keeping what makes sense for it.
  ThemeBackgroundSpec _backgroundOf(ThemeSpec d, ThemeBackgroundType type) {
    final bg = d.background;
    return bg.copyWith(
      type: type,
      gradientColors: type == ThemeBackgroundType.gradient && bg.gradientColors.length < 2
          ? const [0xFFFFE08C, 0xFFF5B700]
          : bg.gradientColors,
    );
  }

  ThemeAccentOverrides _solidPopups(ThemeSpec d, bool on, ColorScheme s) => on
      ? d.accents.copyWith(
          popupFill: s.primary.toARGB32(),
          popupLabel: s.onPrimary.toARGB32(),
          popupSelectedFill: s.tertiary.toARGB32(),
          popupSelectedLabel: s.onTertiary.toARGB32(),
        )
      : d.accents.copyWith(clearPopup: true);

  void _setRole(String role, int? argb, {required bool dark}) => _setDraft((d) {
    final base = dark ? (d.customRolesDark ?? d.customRoles) : d.customRoles;
    final roles = Map<String, int>.of(base);
    if (argb == null) {
      roles.remove(role);
    } else {
      roles[role] = argb;
    }
    return dark ? d.copyWith(customRolesDark: roles) : d.copyWith(customRoles: roles);
  });

  double _nearestMotion(double v) {
    var best = _motionValues.first;
    for (final value in _motionValues) {
      if ((value - v).abs() < (best - v).abs()) best = value;
    }
    return best;
  }

  static String _shapeName(double keyRadius, AppLocalizations l10n) {
    if (keyRadius >= 0.42) return l10n.themeShapePill;
    if (keyRadius >= 0.16) return l10n.themeShapeRounded;
    return l10n.themeShapeSquare;
  }

  /// `surfaceContainerHighest` becomes "Surface container highest".
  static String _roleLabel(String role) {
    final words = role.replaceAllMapped(RegExp(r'([A-Z])'), (m) => ' ${m.group(1)!.toLowerCase()}');
    return words.isEmpty ? role : '${words[0].toUpperCase()}${words.substring(1)}';
  }
}

class _PreviewHeaderDelegate extends SliverPersistentHeaderDelegate {
  _PreviewHeaderDelegate({required this.extent, required this.child});

  final double extent;
  final Widget child;

  @override
  double get minExtent => extent;

  @override
  double get maxExtent => extent;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) => SizedBox.expand(child: child);

  @override
  bool shouldRebuild(covariant _PreviewHeaderDelegate oldDelegate) => true;
}

class _ControlTile extends StatelessWidget {
  const _ControlTile({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [Text(title), const SizedBox(height: 8), child],
    ),
  );
}

/// A slider that updates the draft while it moves (the preview follows the finger).
class _SliderRow extends StatelessWidget {
  const _SliderRow({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
    this.divisions,
    this.valueText,
    this.leftHint,
    this.rightHint,
  });

  final String label;
  final double value;
  final double min;
  final double max;
  final int? divisions;
  final String? valueText;
  final String? leftHint;
  final String? rightHint;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final shown = valueText ?? value.toStringAsFixed(2);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(child: Text(label)),
              Text(shown, style: text.labelLarge?.copyWith(color: scheme.primary)),
            ],
          ),
          Semantics(
            slider: true,
            label: label,
            value: shown,
            child: Slider(
              value: value.clamp(min, max),
              min: min,
              max: max,
              divisions: divisions,
              label: shown,
              onChanged: onChanged,
            ),
          ),
          if (leftHint != null || rightHint != null)
            Row(
              children: [
                Text(leftHint ?? '', style: text.bodySmall),
                const Spacer(),
                Text(rightHint ?? '', style: text.bodySmall),
              ],
            ),
        ],
      ),
    );
  }
}

class _SeedSwatches extends StatelessWidget {
  const _SeedSwatches({required this.selected, required this.onPick, required this.onCustom});

  final int selected;
  final ValueChanged<int> onPick;
  final VoidCallback onCustom;

  @override
  Widget build(BuildContext context) {
    final inList = kSeedSwatches.contains(selected);
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        for (final argb in kSeedSwatches)
          _Swatch(color: Color(argb), selected: argb == selected, label: '#${hexOf(argb)}', onTap: () => onPick(argb)),
        _Swatch(
          color: Color(selected),
          selected: !inList,
          label: inList ? context.l10n.themeCustomColour : context.l10n.themeCustomColourHex(hexOf(selected)),
          icon: Icons.colorize,
          onTap: onCustom,
        ),
      ],
    );
  }
}

class _Swatch extends StatelessWidget {
  const _Swatch({required this.color, required this.selected, required this.label, required this.onTap, this.icon});

  final Color color;
  final bool selected;
  final String label;
  final VoidCallback onTap;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: InkResponse(
        onTap: onTap,
        radius: 28,
        child: SizedBox.square(
          dimension: 48,
          child: Center(
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                border: Border.all(color: selected ? scheme.onSurface : scheme.outlineVariant, width: selected ? 3 : 1),
              ),
              child: icon == null
                  ? null
                  : Icon(
                      icon,
                      size: 18,
                      color: color.computeLuminance() > 0.5 ? const Color(0xFF000000) : const Color(0xFFFFFFFF),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ColorChip extends StatelessWidget {
  const _ColorChip({required this.label, required this.color, required this.onTap});

  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: context.l10n.themeSwatchLabel(label, hexOf(color.toARGB32())),
    child: ActionChip(
      avatar: CircleAvatar(backgroundColor: color, radius: 10),
      label: Text(label),
      onPressed: onTap,
    ),
  );
}

class _RoleTile extends StatelessWidget {
  const _RoleTile({
    required this.label,
    required this.color,
    required this.overridden,
    required this.onPick,
    required this.onReset,
  });

  final String label;
  final Color? color;
  final bool overridden;
  final VoidCallback onPick;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) => ListTile(
    dense: true,
    minVerticalPadding: 8,
    leading: CircleAvatar(backgroundColor: color ?? const Color(0xFF000000), radius: 12),
    title: Text(label),
    subtitle: Text(overridden ? context.l10n.themeOverridden : context.l10n.themeFromScheme),
    trailing: overridden
        ? IconButton(
            tooltip: context.l10n.themeUseSchemeColour(label),
            onPressed: onReset,
            icon: const Icon(Icons.restart_alt),
          )
        : null,
    onTap: onPick,
  );
}
