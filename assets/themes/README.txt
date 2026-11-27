BooBoard themes data. See THIRD_PARTY_NOTICES.md for sources and licenses.

The built-in presets (BooBoard Dynamic, BooBoard Gold, Lavender, Ocean, Mint, Coral,
Rose, Graphite) are defined in Dart (lib/src/theme/presets.dart) so resolving a
theme is synchronous. Custom themes (theme editor, Wave 2) are stored as JSON
files in this format, one file per theme, and selected through
AppearanceSettings.themeId. The same model (ThemeSpec) reads and writes both.

JSON format, version 1 (lib/src/theme/theme_spec.dart)
-------------------------------------------------------
All keys are optional on read: a missing or invalid value falls back to the
default shown. Numbers are clamped to the stated range. Unknown keys are
ignored, and files from a newer version are read leniently.

{
  "version": 1,                  // format version, always written
  "id": "custom_1",              // unique id; presets use fixed ids
  "name": "My theme",
  "colorSource": "seed",         // "dynamic" | "seed" | "custom"
                                 //   dynamic: Material You wallpaper colours on
                                 //            Android 12+, seedColor otherwise
                                 //   seed:    generated from seedColor + variant
                                 //   custom:  generated, then roles replaced
  "seedColor": 4294948608,       // ARGB int (0xFFF5B700)
  "variant": "tonalSpot",        // tonalSpot | vibrant | expressive | fidelity |
                                 // content | monochrome | neutral | rainbow |
                                 // fruitSalad
  "customRoles": {               // colorSource "custom" only; role -> ARGB int
    "primary": 4294948608,       // roles: primary, onPrimary, primaryContainer,
    "onPrimary": 4282137383      // onPrimaryContainer, secondary..., tertiary...,
  },                             // error, onError, surface, onSurface,
                                 // onSurfaceVariant, surfaceDim, surfaceBright,
                                 // surfaceContainerLowest/Low/""/High/Highest,
                                 // outline, outlineVariant
  "customRolesDark": { },        // optional dark-mode roles; absent = customRoles
  "keyRadius": 0.5,              // 0 (square) .. 0.5 (pill), fraction of the
                                 // key's shorter side
  "borderWidth": 0,              // dp, 0..4
  "keyGap": 6,                   // dp, 0..16
  "fontFamily": "GoogleSansFlex",// bundled variable font; null = system font
  "labelWeight": 500,            // 100..900 (variable axis wght)
  "fontRoundness": 100,          // 0..100 (axis ROND); absent = keyRadius * 200
  "labelScale": 1.0,             // 0.7..1.5
  "showHints": true,             // long-press hint characters on keys
  "background": {
    "type": "solid",             // "solid" | "gradient" | "image"
    "gradientColors": [ ],       // two or more ARGB ints; empty = from scheme
    "gradientAngle": 90,         // degrees; 0 = left to right, 90 = top to bottom
    "imagePath": null,           // "images/<uuid>.png", relative to the themes folder
                                 // (see "Custom themes on disk" below)
    "blur": 0,                   // blur radius used when preparing the image
    "dim": 0.3                   // 0..1 dim painted over the image
  },
  "accents": {                   // optional colour overrides (ARGB ints)
    "popupFill": null, "popupLabel": null,
    "popupSelectedFill": null, "popupSelectedLabel": null,
    "trailStart": null, "trailEnd": null
  },
  "motionIntensity": 1.0         // 0 = no motion, 1 = normal, 2 = snappier and
                                 // deeper key press
}

Contrast
--------
Whatever the colours, the resolver adjusts label colours (and, if needed, key
fills) so every label/fill pair meets WCAG 4.5:1, or 7:1 when the user chose high
contrast. Dark mode, pure black and the contrast level are user settings
(AppearanceSettings), not part of a theme.

Migrations
----------
migrateThemeJson() upgrades older files step by step (version N to N+1) when
they are read; writing always uses the current version. To change the format,
add a step to the migration table in theme_spec.dart and bump
ThemeSpec.currentVersion; never edit an existing step.

  v0 (pre-release, no "version" key): flat keys radius, gap, border, font,
     weight, seed, scheme, motion, bgColors, bgImage, bgDim, bgBlur and a
     boolean "dynamic". Upgraded to v1 by renaming and grouping them.

Custom themes on disk (Wave 2-C)
--------------------------------
Custom themes live in <dataDirectory>/themes, which is plain app-private data (no
typed text, so not in SecureBlobStore):

  <dataDirectory>/themes/<uuid>.json        the ThemeSpec JSON above
  <dataDirectory>/themes/images/<uuid>.png  the photo background, cropped to the
                                            keyboard's size and blurred (the dim is
                                            not baked in; the keyboard paints it)

Theme id: "custom:<uuid>", stored in AppearanceSettings.themeId. The uuid is an RFC
4122 version 4 lower-case uuid; anything else is rejected, so an id can never name a
path outside the folder. The JSON "id" always equals the file's id. "imagePath" is
relative ("images/<uuid>.png") so a backup restored elsewhere still finds the photo;
the resolver makes it absolute, and a missing photo turns the background solid.

Writes are atomic (a .tmp file, then rename). A spec file is capped at 64 KB.
Saving or deleting a custom theme bumps AppearanceSettings.customThemeRevision, so
the keyboard re-reads a theme that is in use.
