# BooBoard privacy policy

Last updated: <date of publication>. Applies to BooBoard for Android, the keyboard and its settings app.

BooBoard is a keyboard. A keyboard sees what you type, so this policy says plainly what happens to that. In short:
**BooBoard does not send anything you type, say or copy off your phone, because it cannot connect to the internet.**

## 1. Who we are

BooBoard is free software, licensed under the GNU General Public License v3.0 or later. It is developed by
the BooBoard contributors. Contact: open an issue at https://github.com/knandu18/booboard/issues (public; do not post
anything private there).

## 2. No network access

- BooBoard does not request the internet permission, and the app contains no network code. The release
  builds are checked for this before every release.
- BooBoard does not use analytics, advertising, crash reporting, or any service that collects data.
- BooBoard has no accounts. There is nothing to sign up for or log in to.
- Because the app cannot connect to the internet, nothing you type, say, copy or store in BooBoard is sent
  anywhere.

## 3. Permissions

| Permission | Why | When |
|---|---|---|
| Vibrate | Key feedback | Always, if you turn on haptics |
| Microphone (`RECORD_AUDIO`) | Offline voice typing | Asked the first time you tap the microphone key. Used only during a voice session you start |
| Biometrics (`USE_BIOMETRIC`, `USE_FINGERPRINT`) | Optional app lock | Only when you turn on app lock |

BooBoard does not ask for contacts, location, photos or files as permissions. Photos you choose for a theme
background come through Android's photo picker, which hands BooBoard only the picked image.

## 4. What is stored on your phone

All of it stays on the device, in the app's private storage that other apps cannot read.

- **Learned words, word combinations, personal shortcuts and the clipboard history** are encrypted with
  AES-256-GCM. The key lives in the Android Keystore, in secure hardware when the phone has it. The key can
  only be used while the device is unlocked, so these can be read only then. Writes are atomic.
- **The list of apps BooBoard was used in** (package names and app names, never text) is encrypted in the same way.
  It is used to offer apps for the "always incognito" list.
- **Settings** (layout, themes, toggles, the incognito app list) are stored in a plain file in the app's private
  storage. They contain no typed text.
- **Themes and background photos** you create are stored in the app's private storage.
- **Model packs** you import (dictionaries, voice and translation models) are stored in the app's private
  storage. Each pack is checked against its signature before it is used.

BooBoard keeps only what the features need. The clipboard history keeps text only, at most 30 items, and removes
items after an hour by default (you can change the time). Pinned items stay until you remove them. Copies that
Android marks as sensitive, such as passwords from password managers, are never stored.

## 5. Voice typing

When you start a voice session, BooBoard records audio from the microphone and processes it on the phone with a
model you installed. The audio is held in memory during the session and is discarded afterwards. It is never
saved to a file, never uploaded, and never shared. A session ends when you stop it, cancel it, or after a
period of silence.

## 6. Sensitive fields

In password fields BooBoard does not show suggestions, does not learn from what you type, does not show key
pop-ups, does not offer swipe typing or emoji, and does not offer voice input. In fields where the app asks for
no suggestions, BooBoard does not show suggestions, does not learn from what you type, does not show key
pop-ups, and does not offer voice input; swipe typing and emoji still work. In fields where the app asks for no
personalised learning (for example a private browsing window), BooBoard only stops learning from what you
type; the other keyboard features keep working. Screenshots of the keyboard in password and no-suggestion fields
are blocked by the system.

## 7. Incognito

You can turn on incognito with a switch, and you can keep it on for chosen apps (for example banking apps).
While incognito is on, BooBoard does not learn new words and does not record the app in its list. BooBoard does not
detect private browser tabs by itself; use the switch or the app list for those.

## 8. Backups

BooBoard does not back up to the cloud or to another device. The system's cloud backup and device transfer are
turned off for BooBoard's data.

You can make a backup yourself, from the privacy centre. The backup is saved to a place you choose with
Android's file picker. It is encrypted with AES-256-GCM. The key is derived from a passphrase you choose
with PBKDF2-HMAC-SHA256 (600,000 iterations and a random salt). If you lose the passphrase, the backup cannot
be opened by anyone, including us.

## 9. Logs

Release builds do not write debug or information logs. BooBoard logs events, sizes and timings, never what you
type, the words it knows, the names of the apps you use, or file paths. Logs stay on the phone and are never
sent anywhere.

## 10. Deleting your data

- In the privacy centre you can wipe everything, or one category at a time (learned words, clipboard history,
  recent emoji, shortcuts, the app list and imported packs). Wiping everything also destroys the encryption
  key, so no encrypted leftovers can be read afterwards.
- Uninstalling BooBoard removes all of its data from the phone.
- BooBoard holds no copy of your data anywhere else, so there is nothing for us to delete on request.

## 11. Children

BooBoard is not directed at children and does not knowingly collect any information from anyone, children included.

## 12. Changes

If this policy changes, the new version is published with the release notes, and the date above changes.
Because BooBoard does not connect to the internet, we cannot notify you on the phone; the release notes are the
notice.

## 13. Your choices

You can use BooBoard without learning, without the clipboard history, without voice, without the app lock and
without backups. Each of these is a switch in the settings app.
