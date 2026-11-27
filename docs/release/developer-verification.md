# Android developer verification

Checked: 23 November 2026, against the official Android developer pages linked below. Dates and rules change;
re-check before the F-Droid merge request and before the first GitHub release.

## What the rules say

- From **30 September 2026**, on certified Android devices running Android 8 (API 26) or higher, apps installed
  from participating stores must come from registered, verified developers. The first countries are **Brazil,
  Indonesia, Singapore and Thailand**. Global protection is planned for **2027**.
  Source: https://developer.android.com/developer-verification (the page also says the rollout details changed;
  the country list is therefore to be re-checked on the day).
- Verification is open to all developers, through the **Android Developer Console** (for apps distributed only
  outside Google Play) or the **Google Play Console** (for apps on Play, and for registering apps distributed
  outside Play). Source: https://developer.android.com/developer-verification
- An app is **registered** by its **package name** and the **SHA-256 fingerprint** of its signing key. Source:
  https://developer.android.com/developer-verification/guides/open-source-app-registration
- **Limited distribution accounts** for students, teachers and hobbyists: no government ID, no registration fee,
  sharing with **up to 20 devices**. Early access was June 2026; the global launch was planned for August 2026.
  Source: https://developer.android.com/developer-verification (the "Limited distribution accounts" note) and
  https://developer.android.com/developer-verification/guides/limited-distribution.md.txt (not fetched in full).
  Read the guide before choosing a path: a public release above 20 devices needs a standard account.
- **Advanced flow.** After the deadline, an unregistered app can still be installed by a user who turns on an
  advanced flow on the device. The flow is described in the Android developers blog ("Balancing openness and choice
  with safety", March 2026).
- **Developer Console fee.** One August 2025 press report gives a one-time $25 fee for the Android Developer
  Console. **Not confirmed** on the official page I checked; the FAQ
  (https://developer.android.com/developer-verification/guides/faq.md.txt) is the place to confirm it.

## What it means for BooBoard

| Channel | Effect |
|---|---|
| Google Play (`play` flavour) | Play registers eligible apps automatically once the Play Console verification is complete. The app's package name and key are then covered. Play App Signing is the normal path. |
| GitHub release APK (`foss`) | Signed with the release key. Users on certified phones in the first countries will need the registration of the package name and the release key fingerprint, or the advanced flow, to install a future update through that channel. |
| F-Droid (`foss`) | F-Droid signs the build with its own key unless the reproducible build lets the developer's signature be used. If F-Droid re-signs, the F-Droid signing key fingerprint must be registered too. The open-source registration guide describes both cases. |
| Developer's own F-Droid repository | Signed with the release key. Registration as for GitHub. |

The registration guide also says that an app repository which re-signs the APK needs the store-signed APK's
fingerprint added, and that the repository's snippet file (`adi-registration.properties`, in `assets/`) may need
to be published in a release. **That file is not in this repository.** Adding it means an app asset change, which
belongs to the orchestrator.

## Steps for the user

1. Decide the path: standard Android Developer Console account (for GitHub and an own F-Droid repository),
   Play Console (for Play), or a limited distribution account if the audience stays at 20 devices or fewer.
2. Create the account with an email address and the payment profile the Console asks for (if the fee applies).
   Choose the developer name carefully: it is public. The user does this, not the agents.
3. Once the release key exists (`make_release_keys.ps1`), read its SHA-256 fingerprint from the keystore
   (`keytool -list -v`, the line starting `SHA256:`) and register the package name and key in the Console.
4. Register the Play App Signing upload/app keys in Play Console when the app is created there.
5. After the F-Droid merge, if F-Droid re-signs, read the fingerprint from the F-Droid APK and register it too.
6. Re-check the country list and the advanced-flow text on 30 September 2026 and before the first release.

## Sources

- https://developer.android.com/developer-verification
- https://developer.android.com/developer-verification/guides/open-source-app-registration.md.txt
- https://developer.android.com/developer-verification/guides/limited-distribution.md.txt
- https://android-developers.googleblog.com/2026/03/android-developer-verification-rolling-out-to-all-developers.html
- https://android-developers.googleblog.com/2026/03/android-developer-verification.html

## Not confirmed

- The exact fee for the Android Developer Console (one press report says $25).
- The exact registration fields of the Console (the open-source guide refers to a Help Center page not read here).
- The current country list after the "select regions" update on the official page.
