# OEM and device QA matrix

Owner: Wave 4-D. What to check by device family before a release. Each row is a manual check on
a device of that family (the orchestrator does device testing, never an agent). Tick the
results in the release notes, with the Android version and build.

Common checks for every device: keyboard shows and hides; first show after a cold start; key -> commit feels
immediate; no jank while typing; dark and light mode; font scale 1.3; TalkBack reads the keys
(see the Wave 4-C brief).

| Family | Insets and gesture navigation | Keystore when locked | Clipboard | Floating mode | TalkBack | Voice and translation packs |
|---|---|---|---|---|---|---|
| Samsung One UI (phone) | Bottom gesture bar and the 3-button bar; keyboard sits above the nav bar with no gap or overlap | Unlock, lock, re-unlock: Keystore-backed blobs still open | Copy from another app, paste from the clipboard panel | Keyboard floating and resized; back to docked | Keys announced; candidate strip announced | Voice loads after a cold start; translate EN -> ES |
| Xiaomi HyperOS | MIUI-style gesture pill; check the bottom inset in landscape | Lock with a PIN, then the Keystore unwrap on first show | Clipboard access permitted; check the clipboard panel after a reboot | Floating window may ignore insets; check the frame | Check the accessibility toggles also cover the IME | Pack storage permission prompts do not appear; packs load offline |
| Pixel (stock Android) | Gesture navigation; the IME inset follows the gesture bar | Keystore after reboot (before first unlock): nothing learned or read | Clipboard read needs the field focus; test paste into a password field is blocked | Floating mode via the system; no custom window | Full TalkBack pass | Voice and translation with airplane mode on (no network) |
| TECNO HiOS | Gesture bar with a custom cut-out; check the insets around the notch | Lock and unlock; check the Keystore blob survives | Clipboard permission after install | Floating mode: check the window size and the drag handle | TalkBack on the IME window | Packs load on a 4 GB device; memory stays within the budget |
| 2 GB RAM phone (low-end) | Gesture bar; no inset glitches | Keystore on first show after a reboot | Paste a long clip (1 MB), keyboard stays responsive | Floating mode: check memory after a resize | Keys still announced with low memory | Voice off by default; translate loads one pair at a time; RSS stays under the 2 GB budget |
| Foldable (inner and cover screen) | Fold and unfold with the keyboard shown: the layout reflows and insets update | Keystore after a fold does not re-lock | Clipboard across the screens | Floating mode on the cover screen | TalkBack on the cover screen | Voice and translation survive a fold |
| Tablet (landscape and split screen) | Split-screen: the keyboard follows the app's bounds; hardware keyboard detected | Lock and unlock in split screen | Paste between two apps in split screen | Floating mode on a tablet | Large keys announced at 200% font | Packs load; translate EN -> ES with the reduced runtime |

## Notes per check

- **Insets and gesture navigation:** the keyboard must never sit under the gesture bar or leave a gap.
  Rotate with the keyboard shown.
- **Keystore when locked:** learned data and the packs stay unreadable while the device is locked, and open
  after the first unlock. Nothing is learned in password fields or incognito.
- **Clipboard:** the clipboard panel reads only on user action. Check the password field.
- **Floating mode:** the window keeps its size and position across a rotate. No text is lost on resize.
- **TalkBack:** every key and candidate has a label; the strip and grid announce their state.
- **Voice and translation packs:** the packs are offline. Turn airplane mode on before every check. The app must
  not ask for the INTERNET permission (it has none; `check_aar.ps1` checks the AAR).
- **What the emulator covers:** voice (sherpa loads, a model loads), translation EN -> ES with the
  reduced runtime, and `tool/bench/device_bench.ps1`. Real families above need real devices.
