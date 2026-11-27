# Data safety, permissions and content rating answers

For Google Play Console. Answers are for the `play` flavour. The `foss` build is the same code and the same
permissions. The form layout changes from time to time: answer each question with the meaning below, and check
the wording on the day you submit.

Basis: the code as of Wave 5 (`main` after the Wave 5 merge). Each claim is checked against the code in
`privacy-policy.md`. Anything not confirmed is listed in `checklist.md`.

## 1. Data safety form

**Does your app collect or share any of the required user data types?** No.

Reason: the app has no network code and no internet permission. Data that stays on the device and is never
sent to the developer or to any third party is not "collected" under Play's definition.

**Is all of the user data collected by your app encrypted in transit?** Not applicable. No data is transmitted.
(If the form forces a choice, pick "Yes" with the note that nothing is transmitted.)

**Do you provide a way for users to request that their data is deleted?** Yes. BooBoard has an in-app privacy
centre that wipes everything or one category at a time. Uninstalling removes all app data. Nothing is kept on
any server, so no request needs a server-side deletion.

**Data types the form lists** (answer "not collected" for each):

| Category | Types | Collected | Shared |
|---|---|---|---|
| Location | approximate, precise | No | No |
| Personal info | name, email, user IDs, address, phone, race, religion, political, health, sexual orientation, other | No | No |
| Financial info | payment, purchase history, credit score, other | No | No |
| Health and fitness | health, fitness | No | No |
| Messages | emails, SMS, other in-app messages | No | No |
| Photos and videos | photos, videos | No | No |
| Audio | voice or sound recordings, music, other | No | No |
| Files and docs | files and docs | No | No |
| Calendar | calendar events | No | No |
| Contacts | contacts | No | No |
| App activity | app interactions, in-app search history, installed apps, other user-generated content, other actions | No | No |
| Web browsing | web browsing history | No | No |
| App info and performance | crash logs, diagnostics, other app performance data | No | No |
| Device or other IDs | device or other IDs | No | No |

Note for the reviewer: the text the keyboard sees (what you type) is processed only on the device and is
never collected or sent, which is why "Messages" and "Other user-generated content" are answered No.

**Data handled only on the device (not collected under Play's definition):** learned words and shortcuts
(encrypted), clipboard text (encrypted, expires), the list of apps used (encrypted, names only), settings, themes,
and the voice audio held in memory during a voice session (never saved or sent).

## 2. Permissions declaration (Play Console, "Sensitive permissions and declarations")

| Permission | Declared use | Foreground only? | Answer |
|---|---|---|---|
| `RECORD_AUDIO` | Offline voice typing. Requested the first time the user taps the microphone key. Recording happens only during a voice session the user starts, and stops when the session ends. Audio is held in memory and never saved or sent. | Yes: the session is started by the user in the keyboard or the settings app and is visible in the UI | Justification text: "Offline voice typing. Audio is processed on the device during a session the user starts, is never saved and is never transmitted." |
| `USE_BIOMETRIC` / `USE_FINGERPRINT` | Optional app lock for the settings app and the privacy centre (via the system biometric prompt). | Not a sensitive permission; declare the use only | "Unlocks the optional app lock. Biometric data never leaves the system prompt." |
| `VIBRATE` | Key feedback | Not sensitive | No declaration needed |

There are **no** accessibility-service, contacts, location, storage, query-all-packages, notification,
foreground-service or background-location permissions. BooBoard's keyboard is an input method service (`BIND_INPUT_METHOD`),
not an accessibility service.

## 3. Keyboard (input method) policy

Play's policy for keyboard apps requires:

1. **Collection and transmission of typed text.** BooBoard does not collect or transmit the text the user types.
   Typed text is handled on the device only. The app has no internet permission (checked on every release by
   `tool/check_release_permissions.sh`).
2. **In-app disclosure before the keyboard is enabled.** Onboarding step 3 (`onboarding_steps.dart`,
   `PrivacyStep`) says: "Android warns that any keyboard may collect what you type. That warning is about
   keyboards that can reach the internet. BooBoard cannot." Play's wording expects the disclosure to state that a
   keyboard can collect all text you type. **The current sentence does not say that. It is a requested change**
   (see `checklist.md`): the text should say that a keyboard can collect everything you type, including
   passwords, and that BooBoard has no internet access and so cannot send anything.
3. **Sensitive fields.** Password fields get no suggestions, no learning, no key pop-ups, no swipe, no emoji and no
   voice input. No-suggestion fields get no suggestions, no learning, no key pop-ups and no voice input; swipe and
   emoji still work. Fields that only ask for no personalised learning (private browsing) get no learning and
   nothing else changes. (Learning is switched off in code through `allowsLearning`; `isSensitive` covers the
   rest; key pop-ups and voice in the sensitive fields are not yet verified, see `checklist.md`.)
4. **Declaration in the Play Console.** The Console asks for an input-method declaration. Answer it with the
   wording of point 1, and mention that the keyboard works with no network.

## 4. Store review notes (for the reviewer)

BooBoard is a keyboard. To test it, a reviewer must enable it:

1. Install the app and open BooBoard. Onboarding explains the keyboard and the privacy position.
2. Follow the onboarding steps to turn BooBoard on in the system keyboard settings, then select it as the current
   keyboard in any text field.
3. Type in any text app. Suggestions and the keyboard panels work with no internet connection.
4. Voice typing: the microphone key asks for the microphone permission the first time. Voice needs a voice model
   pack. Today the user imports it (a file, in the foss build); the play build will deliver it through Play once
   the asset packs ship (Wave 5-C). The rest of the keyboard does not need it, so the reviewer can skip voice.

The reviewer does not need an account, a login or a payment.

## 5. Content rating questionnaire (IARC)

Answer as follows. The result is expected to be the lowest age band (for example "Everyone"); the Console
generates the rating from the answers.

- Violence, blood, fear, gambling, sexual content, profanity, drugs, alcohol, tobacco: No.
- User-generated content or chat between users: No. (BooBoard has no other users.)
- Users can interact or exchange content with other users: No.
- Shares the user's location with others: No.
- Digital purchases (in-app purchases, paid features): No.
- Advertising: No.
- Targeted at children: No.

## 6. Other answers

- **Ads:** No ads.
- **Target audience:** not directed at children. If the Console asks for an audience, choose the option for
  users of all ages or adults, and do not declare children as an audience.
- **App access:** no login needed; the app works without an account.
- **Financial features:** none.
- **Government app:** No.
- **Health:** No.
