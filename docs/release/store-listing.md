# Store listing plan

Texts live in `fastlane/metadata/android/<locale>/` (F-Droid and the source of truth for copy). Play Console
takes the same title, short and full descriptions; paste them from those files. Lengths are checked by
`test/release/release_metadata_test.dart`.

## Texts

| Field | Limit | en-US | Other locales |
|---|---|---|---|
| Title | 30 characters | done | es-ES, fr-FR, de-DE, pt-BR, id, hi-IN (machine drafts) |
| Short description | 80 characters | done | same six locales |
| Full description | 4000 characters | en-US only | not yet |
| Changelog | 500 characters | `changelogs/1.txt` | none |

The full description states what has been tested, and no more: automated tests and an Android emulator check.
It says that Chinese and Japanese need a dictionary download (the user's own file in the foss build, Play in
the play build once Wave 5-C lands). It says that some translations are first drafts. Keep these statements
true when the texts change.

Translations of the title and the short description are machine drafts. A native speaker must review them
before the listing goes live (see `checklist.md`).

## Categories and tags

- **Play:** Tools (primary). Alternative: Productivity. Tags are not a Play field; use the keyword text in the
  description only.
- **F-Droid:** Writing (in `metadata/io.github.knandu18.booboard.yml`).
- **Content rating:** see `data-safety.md`, section 5. Expected lowest age band.
- **Contact details:** the public contact is the GitHub issues page (https://github.com/knandu18/booboard/issues,
  user's choice 2026-11-24), also in `privacy-policy.md`. Play still requires a developer email in the Console;
  the user enters it there. The website is optional (the repository URL can be given).

## Privacy policy URL

Play requires a public URL. `privacy-policy.md` is the text. Host it on GitHub Pages from the repository (the
user enables Pages and picks the folder or a `docs/privacy` copy). The URL is entered in Play Console. Not done
by the agents.

## Screenshot plan

Phone screenshots, portrait, at least two per locale (Play asks for 2 to 8). Take them on an emulator or
device, with the release build, and save them under `fastlane/metadata/android/<locale>/images/phoneScreenshots/`.
Use the `docs/brand/screenshot_frame.svg` frame if the design calls for it.

1. The keyboard in an ordinary text field, English, light theme.
2. The same keyboard in Spanish or Hindi with a suggestion strip (shows the languages).
3. The emoji panel with search.
4. Material You colours with a wallpaper-based theme (dark variant).
5. The privacy centre (learned words, clipboard, encrypted backups), showing "nothing leaves the phone".
6. Voice typing panel showing "on device" (only if a voice pack is installed in the test build).

Do not show a password field with text in it. Do not show real personal words in suggestions. Use a clean test
account of words.

Tablet screenshots are not planned for the first release.

## Play review notes

Paste the reviewer notes from `data-safety.md`, section 4. They say how to enable the keyboard, that no account is
needed, what the microphone is for, and that voice needs a pack.

## Feature graphic and icon

- Icon: 512 × 512, `docs/brand/play_icon_512.png` (copied into `fastlane/.../images/icon.png`).
- Feature graphic: 1024 × 500, `docs/brand/feature_graphic_1024x500.png`.
- Both are Wave 4 brand assets; not redrawn in Wave 5.

## Release notes

The changelog is short, factual and in the same locale as the listing. Each release adds
`changelogs/<build>.txt` for every locale that has a listing (en-US first).
