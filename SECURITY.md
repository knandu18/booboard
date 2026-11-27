# Security policy

BooBoard is a private, offline keyboard for Android. Its security goals are in `docs/security/threat-model.md`, and the audit of the current code is in `docs/security/audit.md`.

## Reporting a vulnerability

Please do not open a public issue for a security problem. Open a **private security advisory** on the project's GitHub repository (Security tab, "Report a vulnerability"). If that is not available, contact the maintainer through the repository profile and say that you have a security report, without the details.

Include:

- the app version (the version code in the APK name, or the About screen) and the Android version and device model;
- the steps to reproduce, with the smallest input that triggers the problem (a crafted pack, a backup file, a dictionary file, or a text field);
- what you expected and what you saw, and the impact you think it has.

Please do not send real personal data, real backups or real passphrases. Describe the file format problem, or send a file made with a throwaway passphrase.

## What we commit to

- We acknowledge a report within 7 days and say whether we can reproduce it.
- We keep you informed while we fix it, and credit you in the release notes if you wish.
- We fix issues that break the privacy promises first: anything that sends data off the device, stores typed text where it should not be, or weakens encryption of learned words, clipboard history or backups.

## Scope

In scope: the BooBoard app (keyboard, settings app, voice and translation packs, backup and restore, pack import), its build scripts, and the release pipeline in this repository.

Out of scope: Android itself, other keyboards and apps, and the signing keys held by the maintainer outside this repository.

## Privacy promises we test for

- The release build requests no network permission. The release gate (`tool/check_release_permissions.sh`) and the network audit (`tool/audit/network_audit.sh`) fail the build if one appears.
- Nothing typed is logged. Logging in release builds is off.
- Learned words, clipboard history and personal shortcuts are encrypted with a key held in the Android Keystore.
- Backups are encrypted with a passphrase you choose, and a lost passphrase cannot be recovered.

A report that shows any of these promises is false is always in scope, and high priority.

## Supported versions

Only the latest release is supported before 1.0. Fixes are not back-ported.
