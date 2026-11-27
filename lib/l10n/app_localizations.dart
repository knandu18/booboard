import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_de.dart';
import 'app_localizations_en.dart';
import 'app_localizations_es.dart';
import 'app_localizations_fr.dart';
import 'app_localizations_hi.dart';
import 'app_localizations_id.dart';
import 'app_localizations_pt.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('de'),
    Locale('en'),
    Locale('es'),
    Locale('fr'),
    Locale('hi'),
    Locale('id'),
    Locale('pt'),
  ];

  /// The app's name. Never translated; keep it as it is in every language
  ///
  /// In en, this message translates to:
  /// **'BooBoard'**
  String get appName;

  /// Home screen header, under the app name. Max 40 characters
  ///
  /// In en, this message translates to:
  /// **'Private typing, on this phone'**
  String get homeTagline;

  /// Home screen header: the privacy promise, in the serif headline font. Text between asterisks is set in italic. Three lines at most
  ///
  /// In en, this message translates to:
  /// **'BooBoard works offline and sends *nothing anywhere.*'**
  String get homeOfflinePromise;

  /// Dialog and sheet cancel button
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// Delete button and menu item
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// Save button
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// Confirms a picked colour or photo, button. Max 12 characters
  ///
  /// In en, this message translates to:
  /// **'Use'**
  String get useAction;

  /// Setting is off, short value label. Max 10 characters
  ///
  /// In en, this message translates to:
  /// **'Off'**
  String get off;

  /// Side choice for one-handed mode. Max 10 characters
  ///
  /// In en, this message translates to:
  /// **'Left'**
  String get left;

  /// Side choice for one-handed mode. Max 10 characters
  ///
  /// In en, this message translates to:
  /// **'Right'**
  String get right;

  /// Home row and section title for languages
  ///
  /// In en, this message translates to:
  /// **'Languages'**
  String get settingsLanguages;

  /// Home row and section title for typing
  ///
  /// In en, this message translates to:
  /// **'Typing'**
  String get settingsTyping;

  /// Home row and title for the feel screen. Max 16 characters
  ///
  /// In en, this message translates to:
  /// **'Feel'**
  String get settingsFeel;

  /// Home row and title for themes. Max 16 characters
  ///
  /// In en, this message translates to:
  /// **'Themes'**
  String get settingsThemes;

  /// Home row and title for panels. Max 16 characters
  ///
  /// In en, this message translates to:
  /// **'Panels'**
  String get settingsPanels;

  /// Home row and title for voice. Max 16 characters
  ///
  /// In en, this message translates to:
  /// **'Voice'**
  String get settingsVoice;

  /// Home row and title for translation. Max 24 characters
  ///
  /// In en, this message translates to:
  /// **'Translation'**
  String get settingsTranslation;

  /// Home row and title for privacy. Max 16 characters
  ///
  /// In en, this message translates to:
  /// **'Privacy'**
  String get settingsPrivacy;

  /// Home row and title for About. Max 16 characters
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get settingsAbout;

  /// Title of the packs screen, and a row that opens it. Max 24 characters
  ///
  /// In en, this message translates to:
  /// **'Model packs'**
  String get settingsModelPacks;

  /// Home hint while BooBoard is off. Two lines at most
  ///
  /// In en, this message translates to:
  /// **'Turn BooBoard on in Android\'s keyboard list.'**
  String get homeSetupTurnOn;

  /// Home hint when BooBoard is on but not chosen. Two lines at most
  ///
  /// In en, this message translates to:
  /// **'Choose BooBoard as the keyboard you type with.'**
  String get homeSetupChoose;

  /// Home card title while setup is unfinished. Max 40 characters
  ///
  /// In en, this message translates to:
  /// **'Finish setting up BooBoard'**
  String get homeFinishSetup;

  /// Home row subtitle for typing. Max 60 characters
  ///
  /// In en, this message translates to:
  /// **'Corrections, suggestions, keys and swipe'**
  String get homeTypingSubtitle;

  /// Home row subtitle for feel. Max 60 characters
  ///
  /// In en, this message translates to:
  /// **'Haptics, sounds, height and one-handed mode'**
  String get homeFeelSubtitle;

  /// Home row subtitle for panels. Max 60 characters
  ///
  /// In en, this message translates to:
  /// **'Clipboard and emoji'**
  String get homePanelsSubtitle;

  /// Home row subtitle for voice. Max 60 characters
  ///
  /// In en, this message translates to:
  /// **'Speak to type, on this phone'**
  String get homeVoiceSubtitle;

  /// Home row subtitle for translation. Max 60 characters
  ///
  /// In en, this message translates to:
  /// **'Translate as you type, offline'**
  String get homeTranslationSubtitle;

  /// Home row subtitle for privacy. Max 60 characters
  ///
  /// In en, this message translates to:
  /// **'What is stored, incognito, app lock and backup'**
  String get homePrivacySubtitle;

  /// Home row subtitle for About. Max 60 characters
  ///
  /// In en, this message translates to:
  /// **'Version, licences and source code'**
  String get homeAboutSubtitle;

  /// Home card for making pictures with the offline image model. Max 14 characters
  ///
  /// In en, this message translates to:
  /// **'Images'**
  String get homeImages;

  /// Home footer link to the About page. Max 24 characters
  ///
  /// In en, this message translates to:
  /// **'About BooBoard'**
  String get homeAboutBooBoard;

  /// Screen-reader hint on the booboard.com link (Home and About). Keep "booboard.com" as is
  ///
  /// In en, this message translates to:
  /// **'Opens booboard.com in your browser'**
  String get websiteOpenHint;

  /// Shown when no browser app is installed. Keep "booboard.com" as is
  ///
  /// In en, this message translates to:
  /// **'No browser can open booboard.com.'**
  String get websiteNoBrowser;

  /// Title of the Images page before the image model ships. Text between asterisks is set in italic. Max 28 characters
  ///
  /// In en, this message translates to:
  /// **'Images are *coming*'**
  String get imagesSoonTitle;

  /// Body of the Images page before the image model ships
  ///
  /// In en, this message translates to:
  /// **'Make pictures from your words, right on this phone. Like everything in BooBoard, it will work offline.'**
  String get imagesSoonBody;

  /// About page: row title for booboard.com. Max 24 characters
  ///
  /// In en, this message translates to:
  /// **'Website'**
  String get aboutWebsite;

  /// Title of the About screen. Max 24 characters
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get aboutTitle;

  /// About screen: app version under the name. Max 40 characters
  ///
  /// In en, this message translates to:
  /// **'Version {versionName} ({versionCode})'**
  String aboutVersion(String versionCode, String versionName);

  /// About screen: version line in a debug build. Max 60 characters
  ///
  /// In en, this message translates to:
  /// **'Version {versionName} ({versionCode}) · debug build'**
  String aboutVersionDebug(String versionCode, String versionName);

  /// About screen: shown while the version loads
  ///
  /// In en, this message translates to:
  /// **'Reading version…'**
  String get aboutReadingVersion;

  /// About section title
  ///
  /// In en, this message translates to:
  /// **'Privacy'**
  String get aboutPrivacy;

  /// About privacy tile title. Max 50 characters
  ///
  /// In en, this message translates to:
  /// **'BooBoard cannot use the internet'**
  String get aboutNoInternet;

  /// About privacy tile. Two lines at most
  ///
  /// In en, this message translates to:
  /// **'Release builds have no internet permission, so nothing you type leaves this phone.'**
  String get aboutNoInternetBody;

  /// About section title. British spelling, as in the app
  ///
  /// In en, this message translates to:
  /// **'Licence'**
  String get aboutLicence;

  /// About licence tile title. Keep the licence name
  ///
  /// In en, this message translates to:
  /// **'GNU General Public Licence v3 or later'**
  String get aboutGplTitle;

  /// About licence tile. Two lines at most
  ///
  /// In en, this message translates to:
  /// **'BooBoard is free software. You may study, change and share it under the GPL.'**
  String get aboutGplBody;

  /// About section title
  ///
  /// In en, this message translates to:
  /// **'Source code'**
  String get aboutSourceCode;

  /// About source tile. Two lines at most
  ///
  /// In en, this message translates to:
  /// **'BooBoard is GPL-3.0-or-later. Its source code is available from the project page.'**
  String get aboutSourceBody;

  /// About section title, for the open-source list
  ///
  /// In en, this message translates to:
  /// **'Licences'**
  String get aboutLicences;

  /// About tile title. Max 40 characters
  ///
  /// In en, this message translates to:
  /// **'Open-source licences'**
  String get aboutOpenSource;

  /// About tile subtitle. Lists the libraries. Two lines at most
  ///
  /// In en, this message translates to:
  /// **'Flutter, material_ui and every package BooBoard uses'**
  String get aboutOpenSourceBody;

  /// About screen: a licence text failed to load
  ///
  /// In en, this message translates to:
  /// **'This text could not be loaded.'**
  String get aboutTextLoadFailed;

  /// Languages: list heading. The first language is the default. Max 40 characters
  ///
  /// In en, this message translates to:
  /// **'Enabled, first is the default'**
  String get languagesEnabledHeader;

  /// Languages: the language the keyboard is using now. Max 30 characters
  ///
  /// In en, this message translates to:
  /// **'Active language'**
  String get languagesActive;

  /// Languages: adds a language to the list. Max 30 characters
  ///
  /// In en, this message translates to:
  /// **'Add a language'**
  String get languagesAdd;

  /// Languages: shown when all are on. Max 40 characters
  ///
  /// In en, this message translates to:
  /// **'Every language is enabled'**
  String get languagesAllEnabled;

  /// Languages: hint under the message above. Max 50 characters
  ///
  /// In en, this message translates to:
  /// **'Remove one above to make room.'**
  String get languagesAllEnabledBody;

  /// Languages: title of the multilingual section. Max 40 characters
  ///
  /// In en, this message translates to:
  /// **'Multilingual typing'**
  String get languagesMultilingual;

  /// Languages: explains multilingual typing. Three lines at most
  ///
  /// In en, this message translates to:
  /// **'Suggest words from up to three enabled languages that share the layout\'s script. A word that any of them knows is never auto-corrected.'**
  String get languagesMultilingualBody;

  /// Languages: title of the digits setting. Max 30 characters
  ///
  /// In en, this message translates to:
  /// **'Native digits'**
  String get languagesNativeDigits;

  /// Languages: explains native digits. Two lines at most
  ///
  /// In en, this message translates to:
  /// **'Type digits in the script of the active language where it has them (०१२, ٠١٢).'**
  String get languagesNativeDigitsBody;

  /// Languages: section for Chinese and Japanese options. Max 30 characters
  ///
  /// In en, this message translates to:
  /// **'Language options'**
  String get languagesOptions;

  /// Languages: Chinese row subtitle. Two lines at most
  ///
  /// In en, this message translates to:
  /// **'Pinyin, Traditional characters and dictionary packs'**
  String get languagesZhSubtitle;

  /// Languages: Japanese row subtitle. Two lines at most
  ///
  /// In en, this message translates to:
  /// **'Flick input, conversion and dictionary packs'**
  String get languagesJaSubtitle;

  /// Languages: accessibility label of the drag handle. {language} is a language name
  ///
  /// In en, this message translates to:
  /// **'Drag to reorder {language}'**
  String languagesReorderLabel(String language);

  /// Languages: label for the first language. {language} is a language name
  ///
  /// In en, this message translates to:
  /// **'{language}, default'**
  String languageDefaultLabel(String language);

  /// Languages: tooltip on the layout button. {language} is a language name. Max 40 characters
  ///
  /// In en, this message translates to:
  /// **'Layout for {language}'**
  String languageLayoutTooltip(String language);

  /// Languages: tooltip on the remove button. {language} is a language name. Max 30 characters
  ///
  /// In en, this message translates to:
  /// **'Remove {language}'**
  String languageRemoveTooltip(String language);

  /// Feel: section title
  ///
  /// In en, this message translates to:
  /// **'Haptics'**
  String get feelHaptics;

  /// Feel: switch title. Max 30 characters
  ///
  /// In en, this message translates to:
  /// **'Haptic feedback'**
  String get feelHapticFeedback;

  /// Feel: switch subtitle. Two lines at most
  ///
  /// In en, this message translates to:
  /// **'A short vibration on each key, following the system setting'**
  String get feelHapticFeedbackBody;

  /// Feel: slider title. Max 30 characters
  ///
  /// In en, this message translates to:
  /// **'Haptic strength'**
  String get feelHapticStrength;

  /// Feel: section title
  ///
  /// In en, this message translates to:
  /// **'Sounds'**
  String get feelSounds;

  /// Feel: switch title. Max 30 characters
  ///
  /// In en, this message translates to:
  /// **'Key sounds'**
  String get feelKeySounds;

  /// Feel: switch subtitle. Two lines at most
  ///
  /// In en, this message translates to:
  /// **'Clicks for keys, space, delete and enter'**
  String get feelKeySoundsBody;

  /// Feel: switch title. Max 30 characters
  ///
  /// In en, this message translates to:
  /// **'Use system volume'**
  String get feelUseSystemVolume;

  /// Feel: slider title. Max 30 characters
  ///
  /// In en, this message translates to:
  /// **'Key sound volume'**
  String get feelKeySoundVolume;

  /// Feel: section title
  ///
  /// In en, this message translates to:
  /// **'Height'**
  String get feelHeight;

  /// Feel: slider title. Max 30 characters
  ///
  /// In en, this message translates to:
  /// **'Portrait height'**
  String get feelPortraitHeight;

  /// Feel: slider title. Max 30 characters
  ///
  /// In en, this message translates to:
  /// **'Landscape height'**
  String get feelLandscapeHeight;

  /// Feel: section title. Max 30 characters
  ///
  /// In en, this message translates to:
  /// **'One-handed and floating'**
  String get feelOneHandedFloating;

  /// Feel: label above the side choice. Max 30 characters
  ///
  /// In en, this message translates to:
  /// **'One-handed side'**
  String get feelOneHandedSide;

  /// Feel: switch title. Max 30 characters
  ///
  /// In en, this message translates to:
  /// **'Floating keyboard'**
  String get feelFloatingKeyboard;

  /// Feel: switch subtitle. Two lines at most
  ///
  /// In en, this message translates to:
  /// **'Drag it anywhere on the screen'**
  String get feelFloatingBody;

  /// Panels: section title
  ///
  /// In en, this message translates to:
  /// **'Clipboard'**
  String get panelsClipboard;

  /// Panels: switch title. Max 30 characters
  ///
  /// In en, this message translates to:
  /// **'Clipboard history'**
  String get panelsClipboardHistory;

  /// Panels: switch subtitle. Two lines at most
  ///
  /// In en, this message translates to:
  /// **'Keep what you copy, encrypted on this phone'**
  String get panelsClipboardHistoryBody;

  /// Panels: switch title for the last-copy chip. Max 30 characters
  ///
  /// In en, this message translates to:
  /// **'Recent-copy chip'**
  String get panelsRecentChip;

  /// Panels: switch subtitle. Two lines at most
  ///
  /// In en, this message translates to:
  /// **'Offer your last copy in the suggestion bar for a minute'**
  String get panelsRecentChipBody;

  /// Panels: label above the duration choice. Max 40 characters
  ///
  /// In en, this message translates to:
  /// **'Keep unpinned copies for'**
  String get panelsKeepUnpinned;

  /// Panels: slider title. Max 30 characters
  ///
  /// In en, this message translates to:
  /// **'Clips to keep'**
  String get panelsClipsToKeep;

  /// Panels: section title
  ///
  /// In en, this message translates to:
  /// **'Emoji'**
  String get panelsEmoji;

  /// Emoji suggestions switch title, in Panels and Typing. Max 30 characters
  ///
  /// In en, this message translates to:
  /// **'Emoji suggestions'**
  String get emojiSuggestions;

  /// Panels: switch subtitle. Two lines at most
  ///
  /// In en, this message translates to:
  /// **'Offer an emoji for some words in the suggestion bar'**
  String get emojiSuggestionsPanelBody;

  /// Panels: switch title. Max 40 characters
  ///
  /// In en, this message translates to:
  /// **'Passwords are never saved'**
  String get panelsPasswordsNeverSaved;

  /// Panels: switch subtitle. Two lines at most
  ///
  /// In en, this message translates to:
  /// **'Copies that Android marks as sensitive are never kept.'**
  String get panelsSensitiveBody;

  /// Typing: section title
  ///
  /// In en, this message translates to:
  /// **'Corrections'**
  String get typingCorrections;

  /// Typing: switch title. Max 30 characters
  ///
  /// In en, this message translates to:
  /// **'Autocorrect'**
  String get typingAutocorrect;

  /// Typing: switch subtitle. Two lines at most
  ///
  /// In en, this message translates to:
  /// **'Fix likely typos as you finish a word'**
  String get typingAutocorrectBody;

  /// Typing: switch title. Max 30 characters
  ///
  /// In en, this message translates to:
  /// **'Auto-capitalise'**
  String get typingAutoCapitalise;

  /// Typing: switch subtitle. Two lines at most
  ///
  /// In en, this message translates to:
  /// **'Capital letters at the start of sentences'**
  String get typingAutoCapitaliseBody;

  /// Typing: switch title. Max 30 characters
  ///
  /// In en, this message translates to:
  /// **'Double-space full stop'**
  String get typingDoubleSpace;

  /// Typing: switch subtitle. Two lines at most
  ///
  /// In en, this message translates to:
  /// **'Two taps of space write \". \"'**
  String get typingDoubleSpaceBody;

  /// Typing: switch title. Max 30 characters
  ///
  /// In en, this message translates to:
  /// **'Smart punctuation'**
  String get typingSmartPunctuation;

  /// Typing: switch subtitle. Two lines at most
  ///
  /// In en, this message translates to:
  /// **'Tidy spaces around punctuation and use local quotes'**
  String get typingSmartPunctuationBody;

  /// Typing: section and switch title. Max 30 characters
  ///
  /// In en, this message translates to:
  /// **'Suggestions'**
  String get typingSuggestions;

  /// Typing: switch subtitle. Two lines at most
  ///
  /// In en, this message translates to:
  /// **'Show words in the suggestion bar'**
  String get typingSuggestionsBody;

  /// Typing: switch title. Max 30 characters
  ///
  /// In en, this message translates to:
  /// **'Next-word prediction'**
  String get typingNextWord;

  /// Typing: switch subtitle. Two lines at most
  ///
  /// In en, this message translates to:
  /// **'Suggest the word that often follows'**
  String get typingNextWordBody;

  /// Typing: emoji switch subtitle. Two lines at most
  ///
  /// In en, this message translates to:
  /// **'Offer an emoji for some words'**
  String get typingEmojiBody;

  /// Typing: switch title. Max 30 characters
  ///
  /// In en, this message translates to:
  /// **'Hide offensive words'**
  String get typingHideOffensive;

  /// Typing: switch subtitle. Two lines at most
  ///
  /// In en, this message translates to:
  /// **'Never suggest them unless you type them in full'**
  String get typingHideOffensiveBody;

  /// Typing: section title
  ///
  /// In en, this message translates to:
  /// **'Keys'**
  String get typingKeys;

  /// Typing: switch title. Max 30 characters
  ///
  /// In en, this message translates to:
  /// **'Key popups'**
  String get typingKeyPopups;

  /// Typing: switch subtitle. Two lines at most
  ///
  /// In en, this message translates to:
  /// **'Enlarge a key while you press it'**
  String get typingKeyPopupsBody;

  /// Typing: slider title. Max 30 characters
  ///
  /// In en, this message translates to:
  /// **'Long-press delay'**
  String get typingLongPressDelay;

  /// Typing: switch title. Max 30 characters
  ///
  /// In en, this message translates to:
  /// **'Number row'**
  String get typingNumberRow;

  /// Typing: switch subtitle. Two lines at most
  ///
  /// In en, this message translates to:
  /// **'Show 0 to 9 above the letters'**
  String get typingNumberRowBody;

  /// Typing: switch title. Max 30 characters
  ///
  /// In en, this message translates to:
  /// **'Hint labels'**
  String get typingHintLabels;

  /// Typing: switch subtitle. Two lines at most
  ///
  /// In en, this message translates to:
  /// **'Small symbols on keys, such as accents'**
  String get typingHintLabelsBody;

  /// Typing: switch title. Max 30 characters
  ///
  /// In en, this message translates to:
  /// **'Lowercase labels'**
  String get typingLowercaseLabels;

  /// Typing: switch subtitle. Two lines at most
  ///
  /// In en, this message translates to:
  /// **'Keep key letters lowercase when shift is on'**
  String get typingLowercaseLabelsBody;

  /// Typing: section title
  ///
  /// In en, this message translates to:
  /// **'Swipe'**
  String get typingSwipe;

  /// Typing: switch title. Max 30 characters
  ///
  /// In en, this message translates to:
  /// **'Swipe typing'**
  String get typingSwipeTyping;

  /// Typing: switch subtitle. Two lines at most
  ///
  /// In en, this message translates to:
  /// **'Glide across letters to write a word'**
  String get typingSwipeTypingBody;

  /// Typing: switch title. Max 30 characters
  ///
  /// In en, this message translates to:
  /// **'Show trail'**
  String get typingShowTrail;

  /// Typing: slider title. Max 30 characters
  ///
  /// In en, this message translates to:
  /// **'Trail width'**
  String get typingTrailWidth;

  /// Typing: slider title. Max 30 characters
  ///
  /// In en, this message translates to:
  /// **'Trail fade'**
  String get typingTrailFade;

  /// Typing: switch title. Max 30 characters
  ///
  /// In en, this message translates to:
  /// **'Live preview'**
  String get typingLivePreview;

  /// Typing: switch subtitle. Two lines at most
  ///
  /// In en, this message translates to:
  /// **'Show the likely word while you glide'**
  String get typingLivePreviewBody;

  /// Typing: switch title. Max 40 characters
  ///
  /// In en, this message translates to:
  /// **'Space bar moves the cursor'**
  String get typingSpaceMovesCursor;

  /// Typing: switch subtitle. Two lines at most
  ///
  /// In en, this message translates to:
  /// **'Drag on the space bar to move the cursor'**
  String get typingSpaceMovesCursorBody;

  /// Typing: switch title. Max 40 characters
  ///
  /// In en, this message translates to:
  /// **'Swipe backspace to delete words'**
  String get typingSwipeBackspace;

  /// Typing: switch subtitle. Two lines at most
  ///
  /// In en, this message translates to:
  /// **'Slide left on backspace to select and delete words'**
  String get typingSwipeBackspaceBody;

  /// Voice: switch title. Max 30 characters
  ///
  /// In en, this message translates to:
  /// **'Voice typing'**
  String get voiceTyping;

  /// Voice: switch subtitle. Two lines at most. Voice typing works in English only
  ///
  /// In en, this message translates to:
  /// **'Speak to type in English. Recognition runs on this phone.'**
  String get voiceTypingBody;

  /// Voice: section title. Max 30 characters
  ///
  /// In en, this message translates to:
  /// **'Recognition'**
  String get voiceRecognition;

  /// Voice and Translation: row subtitle for model packs. Two lines at most
  ///
  /// In en, this message translates to:
  /// **'Install or remove voice and translation packs'**
  String get voiceModelPacksBody;

  /// Voice: footnote under the mic. Two lines at most
  ///
  /// In en, this message translates to:
  /// **'Audio stays on this phone and is never saved.'**
  String get voiceAudioStays;

  /// Voice pack choice: the best installed pack. Max 20 characters
  ///
  /// In en, this message translates to:
  /// **'Automatic'**
  String get voicePackAutomatic;

  /// Voice pack choice when Automatic is in use. Max 30 characters
  ///
  /// In en, this message translates to:
  /// **'Automatic (selected)'**
  String get voicePackAutomaticSelected;

  /// Voice pack picker title. Max 30 characters
  ///
  /// In en, this message translates to:
  /// **'Voice pack'**
  String get voicePack;

  /// Voice pack picker: shown when none is installed. Two lines at most
  ///
  /// In en, this message translates to:
  /// **'No voice pack is installed. Install one under Model packs.'**
  String get voiceNoPack;

  /// Voice pack picker: shown while the packs load. Max 40 characters
  ///
  /// In en, this message translates to:
  /// **'Looking for installed packs'**
  String get voiceLooking;

  /// Voice pack picker: a pack with its size. {name} is the pack name, {size} is a size such as 120 MB
  ///
  /// In en, this message translates to:
  /// **'{name} · {size}'**
  String voicePackItem(String name, String size);

  /// Voice pack picker: the chosen pack with its size. {name} is the pack name, {size} a size
  ///
  /// In en, this message translates to:
  /// **'{name} · {size} (selected)'**
  String voicePackItemSelected(String name, String size);

  /// A size in megabytes, such as 120 MB. {count} is a number
  ///
  /// In en, this message translates to:
  /// **'{count} MB'**
  String megabytes(num count);

  /// A duration in milliseconds. {count} is a number. Max 12 characters
  ///
  /// In en, this message translates to:
  /// **'{count} ms'**
  String milliseconds(num count);

  /// A size in density-independent pixels. {count} is a number. Max 12 characters
  ///
  /// In en, this message translates to:
  /// **'{count} dp'**
  String dpValue(num count);

  /// Packs: shown when the file picker fails
  ///
  /// In en, this message translates to:
  /// **'BooBoard could not open the file picker.'**
  String get packsOpenFailed;

  /// Packs: snackbar after a pack installs. {name} is the pack name
  ///
  /// In en, this message translates to:
  /// **'Installed {name}.'**
  String packsInstalled(String name);

  /// Packs: dialog title before a pack is deleted. {name} is the pack name
  ///
  /// In en, this message translates to:
  /// **'Delete {name}?'**
  String packsDeleteTitle(String name);

  /// Packs: body text of the delete confirmation dialog, under the title. Max 120 characters
  ///
  /// In en, this message translates to:
  /// **'Its files are removed from this phone. You can import the pack again later from its file.'**
  String get packsDeleteBody;

  /// Packs: snackbar after a pack is deleted. {name} is the pack name
  ///
  /// In en, this message translates to:
  /// **'Deleted {name}.'**
  String packsDeleted(String name);

  /// Packs: shown when a delete fails. {name} is the pack name
  ///
  /// In en, this message translates to:
  /// **'BooBoard could not delete {name}. Try again.'**
  String packsDeleteFailed(String name);

  /// Packs: explains packs. Two lines at most
  ///
  /// In en, this message translates to:
  /// **'Packs are checked before they are installed. They contain data only, never code.'**
  String get packsIntro;

  /// Packs: section title
  ///
  /// In en, this message translates to:
  /// **'Import'**
  String get packsImport;

  /// Packs: row title for importing. Max 30 characters
  ///
  /// In en, this message translates to:
  /// **'Import a pack file'**
  String get packsImportTitle;

  /// Packs: row subtitle while an import runs
  ///
  /// In en, this message translates to:
  /// **'Checking and installing…'**
  String get packsChecking;

  /// Packs: row subtitle. Two lines at most. .boopack is a file extension
  ///
  /// In en, this message translates to:
  /// **'A .boopack file, for example from Downloads'**
  String get packsImportBody;

  /// Packs: empty state in Voice. Max 40 characters
  ///
  /// In en, this message translates to:
  /// **'No voice packs installed'**
  String get packsNoVoice;

  /// Packs: empty state detail. Max 60 characters
  ///
  /// In en, this message translates to:
  /// **'Voice typing needs a voice pack.'**
  String get packsNoVoiceBody;

  /// Packs: empty state in Translation. Max 40 characters
  ///
  /// In en, this message translates to:
  /// **'No translation packs installed'**
  String get packsNoTranslation;

  /// Packs: empty state detail. Max 60 characters
  ///
  /// In en, this message translates to:
  /// **'Translation needs one pack for each direction.'**
  String get packsNoTranslationBody;

  /// Packs: section title
  ///
  /// In en, this message translates to:
  /// **'Dictionaries'**
  String get packsDictionaries;

  /// Packs: empty state in Dictionaries. Max 40 characters
  ///
  /// In en, this message translates to:
  /// **'No dictionary packs installed'**
  String get packsNoDictionary;

  /// Packs: empty state detail. Max 60 characters
  ///
  /// In en, this message translates to:
  /// **'Chinese and Japanese typing need a dictionary pack.'**
  String get packsNoDictionaryBody;

  /// Packs: heading of the section that explains how to get packs
  ///
  /// In en, this message translates to:
  /// **'Get packs'**
  String get packsGetTitle;

  /// Packs: first line of the explanation, in a foss build with no store delivery
  ///
  /// In en, this message translates to:
  /// **'Packs are files you add yourself.'**
  String get packsExplainTitle;

  /// Packs: how to get a pack without the internet on the phone
  ///
  /// In en, this message translates to:
  /// **'Download them from the project\'s release page on another device, copy them to this phone, then import.'**
  String get packsExplainBody;

  /// Packs: button that copies the release page link to the clipboard
  ///
  /// In en, this message translates to:
  /// **'Copy the release page link'**
  String get packsCopyLink;

  /// Title of the tile that explains that the browser, not BooBoard, downloads packs.
  ///
  /// In en, this message translates to:
  /// **'How downloads stay private'**
  String get packsPrivateTitle;

  /// Body of the tile that explains private pack downloads.
  ///
  /// In en, this message translates to:
  /// **'BooBoard has no internet permission and never connects. Download opens your browser, which fetches the pack from the project\'s GitHub release. BooBoard then checks the pack\'s signature on this phone before it installs anything.'**
  String get packsPrivateBody;

  /// Group title for the published packs that are not installed.
  ///
  /// In en, this message translates to:
  /// **'Packs you can add'**
  String get packsAvailableTitle;

  /// Button that opens a pack download in the browser.
  ///
  /// In en, this message translates to:
  /// **'Download'**
  String get packsDownload;

  /// Subtitle of a downloadable pack.
  ///
  /// In en, this message translates to:
  /// **'{size} · opens your browser'**
  String packsDownloadMeta(String size);

  /// Snackbar after the browser was asked to download a pack.
  ///
  /// In en, this message translates to:
  /// **'Your browser is downloading {name}. When it is done, tap Import a pack file.'**
  String packsDownloadStarted(String name);

  /// Snackbar when no browser app is installed.
  ///
  /// In en, this message translates to:
  /// **'No browser can open the link. Copy the release page link instead.'**
  String get packsNoBrowser;

  /// Subtitle of the import tile.
  ///
  /// In en, this message translates to:
  /// **'Pick the downloaded .boopack file. It is checked on this phone, then installed.'**
  String get packsImportCheckedBody;

  /// Shown when nothing is left to download.
  ///
  /// In en, this message translates to:
  /// **'Every published pack is installed.'**
  String get packsAllInstalled;

  /// Packs: shown after the link is copied
  ///
  /// In en, this message translates to:
  /// **'Link copied. Open it on another device.'**
  String get packsLinkCopied;

  /// Packs: heading of the section for packs the Play store delivers
  ///
  /// In en, this message translates to:
  /// **'Get through Google Play'**
  String get packsPlayTitle;

  /// Packs: note that Google Play downloads the packs and BooBoard does not use the network
  ///
  /// In en, this message translates to:
  /// **'Google Play downloads these packs, not BooBoard. BooBoard itself never uses the network.'**
  String get packsPlayNote;

  /// Packs: button that asks Google Play for a pack
  ///
  /// In en, this message translates to:
  /// **'Get'**
  String get packsGet;

  /// Packs: status of a pack that has not been downloaded
  ///
  /// In en, this message translates to:
  /// **'Not downloaded yet'**
  String get packsStatusNotRequested;

  /// Packs: status while Play waits for Wi-Fi or mobile data
  ///
  /// In en, this message translates to:
  /// **'Waiting for Wi-Fi or mobile data'**
  String get packsStatusWaiting;

  /// Packs: status while Play downloads a pack
  ///
  /// In en, this message translates to:
  /// **'Downloading through Google Play'**
  String get packsStatusDownloading;

  /// Packs: status while BooBoard verifies and installs a pack from Play
  ///
  /// In en, this message translates to:
  /// **'Checking and installing'**
  String get packsStatusInstalling;

  /// Packs: status when Play could not deliver a pack
  ///
  /// In en, this message translates to:
  /// **'Google Play could not deliver it. Try again.'**
  String get packsStatusFailed;

  /// Packs: size and status of a pack the store can deliver. Max 60 characters
  ///
  /// In en, this message translates to:
  /// **'{size} · {status}'**
  String packsOfferMeta(Object size, Object status);

  /// Packs: title of the tile that checks installed packs
  ///
  /// In en, this message translates to:
  /// **'Verify installed packs'**
  String get packsVerifyTitle;

  /// Packs: what the verify action does
  ///
  /// In en, this message translates to:
  /// **'Checks every file of each installed pack against its signed list. Nothing is changed.'**
  String get packsVerifyBody;

  /// Packs: result of verifying, all packs intact. Max 90 characters
  ///
  /// In en, this message translates to:
  /// **'{count} installed packs checked. All files match.'**
  String packsVerifyOk(Object count);

  /// Packs: result of verifying, some packs damaged. Max 120 characters
  ///
  /// In en, this message translates to:
  /// **'{count} installed packs have damaged or missing files. Delete them and import again.'**
  String packsVerifyDamaged(Object count);

  /// Packs: shown when this build cannot verify packs yet
  ///
  /// In en, this message translates to:
  /// **'Checking installed packs is not available in this version of BooBoard.'**
  String get packsVerifyUnavailable;

  /// Packs: shown when the verify action itself failed
  ///
  /// In en, this message translates to:
  /// **'BooBoard could not check the packs. Nothing was changed.'**
  String get packsVerifyFailed;

  /// Packs: free storage for packs. Max 60 characters
  ///
  /// In en, this message translates to:
  /// **'{size} free on this phone.'**
  String packsFreeSpace(Object size);

  /// Packs: footer when no pack is installed
  ///
  /// In en, this message translates to:
  /// **'Nothing stored yet.'**
  String get packsNothingStored;

  /// Packs: footer with the total size. {size} is a size such as 300 MB
  ///
  /// In en, this message translates to:
  /// **'Installed packs use {size} on this phone.'**
  String packsInstalledUse(String size);

  /// Pack install error: the signature is wrong. Two lines at most
  ///
  /// In en, this message translates to:
  /// **'This pack is not signed for BooBoard, so nothing was installed.'**
  String get packErrorBadSignature;

  /// Pack install error: wrong file. Two lines at most
  ///
  /// In en, this message translates to:
  /// **'This file is not a BooBoard pack. Nothing was installed.'**
  String get packErrorBadFormat;

  /// Pack install error: too big. Two lines at most
  ///
  /// In en, this message translates to:
  /// **'This pack is too large to install on this phone.'**
  String get packErrorTooLarge;

  /// Pack install error: version too old. Two lines at most
  ///
  /// In en, this message translates to:
  /// **'This pack needs a newer version of BooBoard.'**
  String get packErrorVersion;

  /// Pack install error: no storage. Two lines at most
  ///
  /// In en, this message translates to:
  /// **'There is not enough free space to install this pack.'**
  String get packErrorNoSpace;

  /// Pack install error: any other failure. Two lines at most
  ///
  /// In en, this message translates to:
  /// **'The pack could not be installed. Nothing was changed.'**
  String get packErrorGeneric;

  /// Translation: section title for the default pair. Max 30 characters
  ///
  /// In en, this message translates to:
  /// **'Default language pair'**
  String get translateDefaultPair;

  /// Translation: a language pair. {from} and {to} are language names
  ///
  /// In en, this message translates to:
  /// **'{from} → {to}'**
  String translatePairName(String from, String to);

  /// Translation: switch title. Max 30 characters
  ///
  /// In en, this message translates to:
  /// **'Offline translation'**
  String get translateOffline;

  /// Translation: switch subtitle. Two lines at most
  ///
  /// In en, this message translates to:
  /// **'Translate as you type in the keyboard, and selected text in any app.'**
  String get translateOfflineBody;

  /// Translation: row title for the default pair. Max 30 characters
  ///
  /// In en, this message translates to:
  /// **'Default pair'**
  String get translateDefaultPairTile;

  /// Translation: status of a pair with its pack. Max 30 characters
  ///
  /// In en, this message translates to:
  /// **'Pack installed'**
  String get translatePackInstalled;

  /// Translation: status of a pair without its pack. Two lines at most
  ///
  /// In en, this message translates to:
  /// **'Pack not installed. Get it in Model packs.'**
  String get translatePackNotInstalled;

  /// Translation: section title for installed packs. Max 30 characters
  ///
  /// In en, this message translates to:
  /// **'Installed directions'**
  String get translateInstalled;

  /// Translation: explains installed directions. Two lines at most
  ///
  /// In en, this message translates to:
  /// **'Each direction is one pack, for example English → Spanish.'**
  String get translateInstalledBody;

  /// Translation: a pack's size and licence. {size} is a size, {license} a licence name
  ///
  /// In en, this message translates to:
  /// **'{size} · {license}'**
  String translatePackMeta(String license, String size);

  /// Translation: row subtitle for model packs. Two lines at most
  ///
  /// In en, this message translates to:
  /// **'Install or delete translation packs'**
  String get translateModelPacksBody;

  /// Translation: footnote. Two lines at most
  ///
  /// In en, this message translates to:
  /// **'Translation runs on this phone. Nothing you translate is saved.'**
  String get translateRunsOnPhone;

  /// Shown by the system fingerprint prompt. Max 60 characters
  ///
  /// In en, this message translates to:
  /// **'Unlock BooBoard to see your settings and data'**
  String get privacyUnlockReason;

  /// App lock: the device lock cannot be used now. Two lines at most
  ///
  /// In en, this message translates to:
  /// **'Your device lock is not available right now. Try again in a moment.'**
  String get privacyLockUnavailable;

  /// App lock screen title. Max 30 characters
  ///
  /// In en, this message translates to:
  /// **'BooBoard is locked'**
  String get privacyLockedTitle;

  /// App lock screen: explains how to unlock. Two lines at most
  ///
  /// In en, this message translates to:
  /// **'Unlock with your fingerprint or your device PIN to continue.'**
  String get privacyLockedBody;

  /// App lock screen: unlock button. Max 20 characters
  ///
  /// In en, this message translates to:
  /// **'Unlock'**
  String get privacyUnlock;

  /// Backup: snackbar after saving. {size} is a file size such as 2.4 MB
  ///
  /// In en, this message translates to:
  /// **'Backup saved ({size}). Keep your passphrase safe.'**
  String backupSaved(String size);

  /// Backup: saving needs the phone unlocked. Two lines at most
  ///
  /// In en, this message translates to:
  /// **'Unlock your phone, then try again. Nothing was saved.'**
  String get backupUnlockRetrySaved;

  /// Backup: saving failed. Two lines at most
  ///
  /// In en, this message translates to:
  /// **'The backup could not be saved. Nothing was changed.'**
  String get backupSaveFailed;

  /// Backup: the file was written but reading it back did not match. Two lines at most
  ///
  /// In en, this message translates to:
  /// **'The saved file could not be checked, so it may be damaged. Save the backup again as a new file.'**
  String get backupCheckFailed;

  /// Restore: wrong passphrase or broken file. Two lines at most
  ///
  /// In en, this message translates to:
  /// **'Wrong passphrase, or the file is damaged. Nothing was changed.'**
  String get backupWrongPassphrase;

  /// Restore: wrong file type. Two lines at most
  ///
  /// In en, this message translates to:
  /// **'This file is not a valid BooBoard backup. Nothing was changed.'**
  String get backupInvalidFile;

  /// Restore: file too big. Two lines at most
  ///
  /// In en, this message translates to:
  /// **'This file is too large to be a BooBoard backup.'**
  String get backupTooLarge;

  /// Restore: backup from a newer app. Two lines at most
  ///
  /// In en, this message translates to:
  /// **'This backup was made by a newer version of BooBoard. Update BooBoard to restore it.'**
  String get backupNewerVersion;

  /// Restore: another file window is open. Two lines at most
  ///
  /// In en, this message translates to:
  /// **'Finish the other file window first, then try again.'**
  String get backupBusy;

  /// Restore: any other open failure. Two lines at most
  ///
  /// In en, this message translates to:
  /// **'The backup could not be opened. Nothing was changed.'**
  String get backupOpenFailed;

  /// Restore: the backup is empty. Max 50 characters
  ///
  /// In en, this message translates to:
  /// **'This backup has nothing in it.'**
  String get backupEmpty;

  /// Restore: dialog title. Max 30 characters
  ///
  /// In en, this message translates to:
  /// **'Restore backup'**
  String get backupRestoreTitle;

  /// Restore: when and with which version the backup was made. {date} and {version} are text
  ///
  /// In en, this message translates to:
  /// **'Made {date} by BooBoard {version}.'**
  String backupMadeBy(String date, String version);

  /// Restore: choice to add to existing data. Max 20 characters
  ///
  /// In en, this message translates to:
  /// **'Merge'**
  String get backupMerge;

  /// Restore: merge choice explanation. Two lines at most
  ///
  /// In en, this message translates to:
  /// **'Keep what is on this phone and add what is in the backup.'**
  String get backupMergeBody;

  /// Restore: choice to overwrite existing data. Max 20 characters
  ///
  /// In en, this message translates to:
  /// **'Replace'**
  String get backupReplace;

  /// Restore: replace choice explanation. Two lines at most
  ///
  /// In en, this message translates to:
  /// **'Make the chosen sections match the backup. Data here is deleted first.'**
  String get backupReplaceBody;

  /// Continue button in dialogs and onboarding. Max 20 characters
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get commonContinue;

  /// Restore: confirmation title. Max 50 characters
  ///
  /// In en, this message translates to:
  /// **'Replace data on this phone?'**
  String get backupReplaceTitle;

  /// Restore: replace confirmation. Three lines at most
  ///
  /// In en, this message translates to:
  /// **'The chosen sections on this phone are deleted and replaced. This cannot be undone.'**
  String get backupReplaceConfirm;

  /// Restore: title of the confirmation that lists privacy settings the backup would change
  ///
  /// In en, this message translates to:
  /// **'This backup changes your privacy settings'**
  String get backupPrivacyChangesTitle;

  /// Restore: explains the list of privacy settings below it
  ///
  /// In en, this message translates to:
  /// **'Restoring the settings will change these privacy settings on this phone. Check them before you continue.'**
  String get backupPrivacyChangesBody;

  /// Restore: one changed privacy setting. {setting} is the setting's name, {from} and {to} are the old and new value (On, Off, or a number of apps)
  ///
  /// In en, this message translates to:
  /// **'{setting}: {from} → {to}'**
  String backupPrivacyChangeLine(String setting, String from, String to);

  /// A privacy setting's value: on (the off value is the existing 'off' string)
  ///
  /// In en, this message translates to:
  /// **'On'**
  String get backupStateOn;

  /// Restore: number of apps in the always-incognito list
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one {1 app} other {{count} apps}}'**
  String backupAppsCount(int count);

  /// Restore: button that restores and changes the listed privacy settings
  ///
  /// In en, this message translates to:
  /// **'Restore and change'**
  String get backupRestoreAndChange;

  /// Restore: needs the phone unlocked. Two lines at most
  ///
  /// In en, this message translates to:
  /// **'Unlock your phone, then try again. Nothing was changed.'**
  String get backupUnlockRetryChanged;

  /// Restore: failed partway. Two lines at most
  ///
  /// In en, this message translates to:
  /// **'BooBoard could not finish the restore. Some data may not have been written.'**
  String get backupRestoreFailed;

  /// Restore summary when nothing was added. Max 40 characters
  ///
  /// In en, this message translates to:
  /// **'Restored nothing new.'**
  String get restoreNothingNew;

  /// Restore summary: {items} is a list of added things, already written, such as "3 shortcuts, settings"
  ///
  /// In en, this message translates to:
  /// **'Restored {items}.'**
  String restoreSummary(String items);

  /// Restore summary with things that were already here. {added} is the summary above, {skipped} a list
  ///
  /// In en, this message translates to:
  /// **'{added} Skipped: {skipped}.'**
  String restoreSummarySkipped(String added, String skipped);

  /// Restore summary part: learned words in some languages. Lowercase, it follows "Restored"
  ///
  /// In en, this message translates to:
  /// **'learned words for {count, plural, one {1 language} other {{count} languages}}'**
  String restoreLearnedFor(int count);

  /// Count of files. Max 30 characters
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one {1 file} other {{count} files}}'**
  String countFiles(int count);

  /// Count of learned words. Max 30 characters
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one {1 word} other {{count} words}}'**
  String countWords(int count);

  /// Count of languages. Max 30 characters
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one {1 language} other {{count} languages}}'**
  String countLanguages(int count);

  /// Count of personal shortcuts. Max 30 characters
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one {1 shortcut} other {{count} shortcuts}}'**
  String countShortcuts(int count);

  /// Count of clipboard items. Max 30 characters
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one {1 clipboard item} other {{count} clipboard items}}'**
  String countClipboardItems(int count);

  /// Count of theme files. Max 30 characters
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one {1 theme file} other {{count} theme files}}'**
  String countThemeFiles(int count);

  /// Count of pinned clipboard items. Max 30 characters
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one {1 pinned item} other {{count} pinned items}}'**
  String countPinnedItems(int count);

  /// Count of model packs. Max 30 characters
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one {1 pack} other {{count} packs}}'**
  String countPacks(int count);

  /// Count of blocked words. Max 30 characters
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one {1 blocked word} other {{count} blocked words}}'**
  String countBlockedWords(int count);

  /// Count of how often a word was typed. Max 30 characters
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one {1 time} other {{count} times}}'**
  String countTimes(int count);

  /// Time since something happened, in minutes. Max 30 characters
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one {1 minute ago} other {{count} minutes ago}}'**
  String timeMinutesAgo(int count);

  /// Time since something happened, in hours. Max 30 characters
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one {1 hour ago} other {{count} hours ago}}'**
  String timeHoursAgo(int count);

  /// Time since something happened, in days. Max 30 characters
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one {1 day ago} other {{count} days ago}}'**
  String timeDaysAgo(int count);

  /// Time since something happened: under a minute. Max 20 characters
  ///
  /// In en, this message translates to:
  /// **'just now'**
  String get timeJustNow;

  /// Language name in English, used in pack and privacy lists. Max 30 characters
  ///
  /// In en, this message translates to:
  /// **'Portuguese'**
  String get languagePortuguese;

  /// Pack line: languages, size and licence, joined with middle dots. Max 80 characters
  ///
  /// In en, this message translates to:
  /// **'{languages} · {size} · {license}'**
  String packMeta(String languages, String license, String size);

  /// Privacy: title of learned words for one language. {language} is a language name
  ///
  /// In en, this message translates to:
  /// **'Learned words ({language})'**
  String privacyLearnedWordsTitle(String language);

  /// Privacy: confirmation title. {language} is a language name. Max 40 characters
  ///
  /// In en, this message translates to:
  /// **'Clear {language} words?'**
  String privacyClearLanguageTitle(String language);

  /// Privacy: confirmation text. Three lines at most
  ///
  /// In en, this message translates to:
  /// **'This deletes every word learned in this language, and the words you blocked. It cannot be undone.'**
  String get privacyClearLanguageBody;

  /// Privacy: confirm button that clears data. Max 20 characters
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get privacyClear;

  /// Privacy: a change failed to save. Two lines at most
  ///
  /// In en, this message translates to:
  /// **'Could not save the change. Try again.'**
  String get privacySaveFailed;

  /// Learned words: failed to load. Two lines at most
  ///
  /// In en, this message translates to:
  /// **'BooBoard could not read these words.'**
  String get privacyCouldNotReadWords;

  /// Learned words: locked data. Two lines at most
  ///
  /// In en, this message translates to:
  /// **'BooBoard cannot read these words right now. Unlock your phone, then try again.'**
  String get privacyCannotReadWordsNow;

  /// Learned words: empty list. Two lines at most
  ///
  /// In en, this message translates to:
  /// **'No words learned in this language yet. BooBoard learns a word after you type it a few times.'**
  String get privacyNoWordsLanguage;

  /// Learned words: button tooltip with the blocked count. Max 30 characters
  ///
  /// In en, this message translates to:
  /// **'Blocked words ({count})'**
  String privacyBlockedWordsTooltip(num count);

  /// Learned words: sort button tooltip. Max 20 characters
  ///
  /// In en, this message translates to:
  /// **'Sort'**
  String get privacySortTooltip;

  /// Learned words: sort option. Max 30 characters
  ///
  /// In en, this message translates to:
  /// **'Most used first'**
  String get privacySortMostUsed;

  /// Learned words: sort option. Max 20 characters
  ///
  /// In en, this message translates to:
  /// **'A to Z'**
  String get privacySortAZ;

  /// Learned words and others: more-actions button tooltip. Max 20 characters
  ///
  /// In en, this message translates to:
  /// **'More'**
  String get privacyMoreTooltip;

  /// Learned words: menu item. Max 30 characters
  ///
  /// In en, this message translates to:
  /// **'Clear this language'**
  String get privacyClearThisLanguage;

  /// Learned words: search field label. Max 30 characters
  ///
  /// In en, this message translates to:
  /// **'Search words'**
  String get privacySearchWords;

  /// Learned words: summary line. {words} and {blocked} are counts such as "3 words"
  ///
  /// In en, this message translates to:
  /// **'{words} · {blocked}'**
  String privacyWordsSummary(String blocked, String words);

  /// Learned words: empty search list. Max 40 characters
  ///
  /// In en, this message translates to:
  /// **'No words yet.'**
  String get privacyNoWordsYet;

  /// Learned words: search with no result. {query} is what the user searched for
  ///
  /// In en, this message translates to:
  /// **'No words match \"{query}\".'**
  String privacyNoWordsMatch(String query);

  /// Learned words: section title for blocked words. Max 30 characters
  ///
  /// In en, this message translates to:
  /// **'Never suggested'**
  String get privacyNeverSuggested;

  /// Learned words: explains blocked words. Two lines at most
  ///
  /// In en, this message translates to:
  /// **'BooBoard will not suggest or correct to these words.'**
  String get privacyBlockedExplain;

  /// Learned words: empty blocked list. Max 40 characters
  ///
  /// In en, this message translates to:
  /// **'No blocked words.'**
  String get privacyNoBlockedWords;

  /// Learned words: unblock a word. Max 30 characters
  ///
  /// In en, this message translates to:
  /// **'Allow again'**
  String get privacyAllowAgain;

  /// Learned word detail: how often, and when it was last typed. {when} is a time phrase such as "today"
  ///
  /// In en, this message translates to:
  /// **'Typed {count, plural, one {1 time} other {{count} times}} · last {when}'**
  String privacyWordLastUsed(int count, String when);

  /// Learned word detail: typed once, not suggested yet. {when} is a time phrase
  ///
  /// In en, this message translates to:
  /// **'Typed once so far, not suggested yet · last {when}'**
  String privacyWordNotYetSuggested(String when);

  /// Time phrase used in word details. Max 20 characters
  ///
  /// In en, this message translates to:
  /// **'today'**
  String get privacyToday;

  /// Time phrase used in word details. Max 20 characters
  ///
  /// In en, this message translates to:
  /// **'yesterday'**
  String get privacyYesterday;

  /// Learned word: tooltip of the word's menu. {word} is a learned word
  ///
  /// In en, this message translates to:
  /// **'Actions for {word}'**
  String privacyActionsFor(String word);

  /// Learned word menu item. Max 30 characters
  ///
  /// In en, this message translates to:
  /// **'Forget this word'**
  String get privacyForgetWord;

  /// Learned word menu item. Max 40 characters
  ///
  /// In en, this message translates to:
  /// **'Never suggest this word'**
  String get privacyNeverSuggestWord;

  /// Error state button. Max 20 characters
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get privacyTryAgain;

  /// Privacy center: failed to load. Two lines at most
  ///
  /// In en, this message translates to:
  /// **'BooBoard could not read its privacy data. Try again later.'**
  String get privacyCenterLoadFailed;

  /// Privacy center: a release build asks for internet. Two lines at most
  ///
  /// In en, this message translates to:
  /// **'This build requests internet access. BooBoard should never do that. Please report it.'**
  String get privacyDevBuildNetwork;

  /// Privacy center: release build status. Two lines at most
  ///
  /// In en, this message translates to:
  /// **'BooBoard has no internet permission. It cannot send anything.'**
  String get privacyNoInternetPermission;

  /// Privacy center: debug build status. Two lines at most
  ///
  /// In en, this message translates to:
  /// **'This is a development build. Its network permission is for development tools only.'**
  String get privacyDevBuildNote;

  /// Privacy center: short debug build status. Two lines at most
  ///
  /// In en, this message translates to:
  /// **'Development build. BooBoard still has no internet permission.'**
  String get privacyDevBuildShort;

  /// Privacy center: stored data size and when it changed. {size} is a size, {when} a time phrase
  ///
  /// In en, this message translates to:
  /// **'{size} · changed {when}'**
  String privacyStorageSize(String size, String when);

  /// Privacy center: stored data row. Max 30 characters
  ///
  /// In en, this message translates to:
  /// **'Custom themes'**
  String get privacyCustomThemes;

  /// Privacy center: no packs installed. Two lines at most
  ///
  /// In en, this message translates to:
  /// **'None installed. Voice and translation packs appear here.'**
  String get privacyNoPacks;

  /// Privacy center: packs count and size. {size} is a size
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one {1 pack} other {{count} packs}} · {size}'**
  String privacyPacksSize(int count, String size);

  /// Privacy center: group title. Max 30 characters
  ///
  /// In en, this message translates to:
  /// **'What BooBoard stores'**
  String get privacyWhatBooBoardStores;

  /// Privacy center: explains sizes. Three lines at most
  ///
  /// In en, this message translates to:
  /// **'BooBoard shows only sizes here, never what is inside. Sizes include the last saved copy, which keeps your data safe if a save is interrupted.'**
  String get privacyShowsSizesOnly;

  /// Privacy center: section title. Max 30 characters
  ///
  /// In en, this message translates to:
  /// **'Typing privacy'**
  String get privacyTypingPrivacy;

  /// Privacy center: switch title. Max 30 characters
  ///
  /// In en, this message translates to:
  /// **'Learn new words'**
  String get privacyLearnNewWords;

  /// Privacy center: switch subtitle. Two lines at most
  ///
  /// In en, this message translates to:
  /// **'Learn words and phrases from what you type. Never in password fields or incognito.'**
  String get privacyLearnNewWordsBody;

  /// Privacy center: switch title. Max 20 characters
  ///
  /// In en, this message translates to:
  /// **'Incognito'**
  String get privacyIncognito;

  /// Privacy center: switch subtitle. Two lines at most
  ///
  /// In en, this message translates to:
  /// **'Learn and remember nothing while on. Browser incognito tabs turn this on by themselves.'**
  String get privacyIncognitoBody;

  /// Privacy center: switch title. Max 30 characters
  ///
  /// In en, this message translates to:
  /// **'Hide from screenshots'**
  String get privacyHideScreenshots;

  /// Privacy center: switch subtitle. Two lines at most
  ///
  /// In en, this message translates to:
  /// **'Stop screenshots and screen recordings of the keyboard in every app. Password fields are always hidden.'**
  String get privacyHideScreenshotsBody;

  /// Privacy center: section title for apps where BooBoard turns off. Max 50 characters
  ///
  /// In en, this message translates to:
  /// **'Turned off automatically in these apps'**
  String get privacyAutoOffApps;

  /// Privacy center: explains the app list. Three lines at most
  ///
  /// In en, this message translates to:
  /// **'BooBoard keeps app names only to fill this list. They are encrypted, never recorded while incognito, and you can clear them below.'**
  String get privacyAutoOffAppsBody;

  /// Privacy center: empty app list. Max 30 characters
  ///
  /// In en, this message translates to:
  /// **'No apps yet'**
  String get privacyNoAppsYet;

  /// Privacy center: empty app list detail. Two lines at most
  ///
  /// In en, this message translates to:
  /// **'Apps you type in will appear here.'**
  String get privacyNoAppsYetBody;

  /// Privacy center: group title. Max 40 characters
  ///
  /// In en, this message translates to:
  /// **'Always incognito apps'**
  String get privacyAlwaysIncognitoApps;

  /// Privacy center and shortcuts screen title. Max 30 characters
  ///
  /// In en, this message translates to:
  /// **'Personal shortcuts'**
  String get privacyPersonalShortcuts;

  /// Privacy center: switch title. Max 30 characters
  ///
  /// In en, this message translates to:
  /// **'Offer shortcuts'**
  String get privacyOfferShortcuts;

  /// Privacy center: switch subtitle. Two lines at most
  ///
  /// In en, this message translates to:
  /// **'Show your short forms, such as \"omw\", as the first suggestion.'**
  String get privacyOfferShortcutsBody;

  /// Privacy center: row title. Max 30 characters
  ///
  /// In en, this message translates to:
  /// **'Edit shortcuts'**
  String get privacyEditShortcuts;

  /// Privacy center: no shortcuts yet. Max 30 characters
  ///
  /// In en, this message translates to:
  /// **'None yet'**
  String get privacyNoShortcutsYet;

  /// Privacy center: section title. Max 40 characters
  ///
  /// In en, this message translates to:
  /// **'Learned words and clipboard'**
  String get privacyLearnedAndClipboard;

  /// Privacy center: empty learned words. Max 40 characters
  ///
  /// In en, this message translates to:
  /// **'No words learned yet'**
  String get privacyNoWordsLearnedYet;

  /// Privacy center: explains learned words. Two lines at most
  ///
  /// In en, this message translates to:
  /// **'Words you type are learned here once BooBoard has seen them a few times.'**
  String get privacyWordsLearnedBody;

  /// Privacy center: row subtitle for learned words. {when} is a time phrase
  ///
  /// In en, this message translates to:
  /// **'Review, remove or block words · {when}'**
  String privacyReviewWords(String when);

  /// Privacy center: clipboard history empty. Two lines at most
  ///
  /// In en, this message translates to:
  /// **'History is empty. Change clipboard settings in Panels.'**
  String get privacyClipboardHistoryEmpty;

  /// Privacy center: clipboard history size. {size} is a size
  ///
  /// In en, this message translates to:
  /// **'{size} in history. Change clipboard settings in Panels.'**
  String privacyClipboardInHistory(String size);

  /// Privacy center: section title. Max 30 characters
  ///
  /// In en, this message translates to:
  /// **'App lock'**
  String get privacyAppLock;

  /// Privacy center: switch title. Max 30 characters
  ///
  /// In en, this message translates to:
  /// **'Lock BooBoard'**
  String get privacyLockBooBoard;

  /// Privacy center: switch subtitle. Three lines at most
  ///
  /// In en, this message translates to:
  /// **'Ask for your fingerprint or device PIN when the app opens, or after it was in the background.'**
  String get privacyLockBooBoardBody;

  /// Privacy center: slider and dialog title. Max 30 characters
  ///
  /// In en, this message translates to:
  /// **'Lock after'**
  String get privacyLockAfter;

  /// Privacy center: dialog title when the device has no lock. Max 40 characters
  ///
  /// In en, this message translates to:
  /// **'Set a screen lock first'**
  String get privacySetScreenLockFirst;

  /// Privacy center: dialog text. Three lines at most
  ///
  /// In en, this message translates to:
  /// **'App lock uses your fingerprint or device PIN. Set a PIN, pattern or password in Android\'s security settings, then come back.'**
  String get privacySetScreenLockBody;

  /// Shown by the system fingerprint prompt when turning on app lock. Max 60 characters
  ///
  /// In en, this message translates to:
  /// **'Turn on app lock for BooBoard'**
  String get privacyTurnOnAppLockReason;

  /// Privacy center: dialog title when the device lock cannot be used. Max 40 characters
  ///
  /// In en, this message translates to:
  /// **'Not available right now'**
  String get privacyNotAvailable;

  /// Privacy center: dialog text. Two lines at most
  ///
  /// In en, this message translates to:
  /// **'Your device lock could not be used. App lock stays off.'**
  String get privacyNotAvailableBody;

  /// Privacy center: section title. Max 20 characters
  ///
  /// In en, this message translates to:
  /// **'Backup'**
  String get privacyBackupTitle;

  /// Privacy center row title. Max 30 characters
  ///
  /// In en, this message translates to:
  /// **'Backup and restore'**
  String get privacyBackupRestore;

  /// Privacy center row subtitle. Two lines at most. .boobackup is a file extension
  ///
  /// In en, this message translates to:
  /// **'An encrypted .boobackup file you keep. You choose what goes in it.'**
  String get privacyBackupRestoreBody;

  /// Privacy center: section title. Max 30 characters
  ///
  /// In en, this message translates to:
  /// **'Delete data'**
  String get privacyDeleteData;

  /// Privacy center row title. Max 30 characters
  ///
  /// In en, this message translates to:
  /// **'Erase everything'**
  String get privacyEraseEverything;

  /// Privacy center row subtitle. Two lines at most
  ///
  /// In en, this message translates to:
  /// **'Every category above, your custom themes, and the key that protects them.'**
  String get privacyEraseEverythingBody;

  /// Privacy center: confirmation title. {category} is a category name in lower case
  ///
  /// In en, this message translates to:
  /// **'Delete {category}?'**
  String privacyDeleteTitle(String category);

  /// Privacy center: confirmation title for erasing all. Max 40 characters
  ///
  /// In en, this message translates to:
  /// **'Erase everything?'**
  String get privacyEraseTitle;

  /// Privacy center: confirmation list heading. Max 60 characters
  ///
  /// In en, this message translates to:
  /// **'This will permanently delete:'**
  String get privacyWillDelete;

  /// Privacy center: switch in the erase dialog. Max 60 characters
  ///
  /// In en, this message translates to:
  /// **'Also reset all settings to their defaults'**
  String get privacyResetSettings;

  /// Confirmation dialog: warning text. Max 60 characters
  ///
  /// In en, this message translates to:
  /// **'This cannot be undone.'**
  String get privacyCannotBeUndone;

  /// Privacy center: snackbar after deleting. Max 30 characters
  ///
  /// In en, this message translates to:
  /// **'Deleted.'**
  String get privacyDeleted;

  /// Privacy center: deletion failed. Two lines at most
  ///
  /// In en, this message translates to:
  /// **'BooBoard could not delete everything. Try again.'**
  String get privacyDeleteFailed;

  /// Dialog confirm button for information dialogs. Max 10 characters
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get privacyOk;

  /// Backup screen: section title. Max 30 characters
  ///
  /// In en, this message translates to:
  /// **'Make a backup'**
  String get backupMakeTitle;

  /// Backup: switch title. Max 40 characters
  ///
  /// In en, this message translates to:
  /// **'Include background images'**
  String get backupIncludeImages;

  /// Backup: switch subtitle. Max 60 characters
  ///
  /// In en, this message translates to:
  /// **'Photos make the file much larger.'**
  String get backupPhotosLarger;

  /// Backup: button. Max 30 characters
  ///
  /// In en, this message translates to:
  /// **'Create encrypted backup'**
  String get backupCreateButton;

  /// Backup screen: section title. Max 20 characters
  ///
  /// In en, this message translates to:
  /// **'Restore'**
  String get backupRestoreSection;

  /// Backup: row title. Max 40 characters
  ///
  /// In en, this message translates to:
  /// **'Restore from a backup file'**
  String get backupRestoreFromFile;

  /// Backup: row subtitle. Two lines at most
  ///
  /// In en, this message translates to:
  /// **'Open a .boobackup file, check what is in it, then merge or replace.'**
  String get backupRestoreFromFileBody;

  /// Backup: passphrase dialog title when creating. Max 40 characters
  ///
  /// In en, this message translates to:
  /// **'Choose a passphrase'**
  String get backupChoosePassphrase;

  /// Backup: passphrase dialog title when opening. Max 40 characters
  ///
  /// In en, this message translates to:
  /// **'Enter the passphrase'**
  String get backupEnterPassphrase;

  /// Backup: warning when creating. Two lines at most
  ///
  /// In en, this message translates to:
  /// **'Write it down somewhere safe. A lost passphrase cannot be recovered.'**
  String get backupWriteItDown;

  /// Backup: passphrase field label. Max 20 characters
  ///
  /// In en, this message translates to:
  /// **'Passphrase'**
  String get backupPassphrase;

  /// Backup: confirm passphrase field label. Max 30 characters
  ///
  /// In en, this message translates to:
  /// **'Type it again'**
  String get backupTypeAgain;

  /// Backup: error under the confirm field. Max 50 characters
  ///
  /// In en, this message translates to:
  /// **'The passphrases do not match'**
  String get backupMismatch;

  /// Backup: strength meter label. {strength} is Too short, Weak, Fair, Good or Strong
  ///
  /// In en, this message translates to:
  /// **'Passphrase strength: {strength}'**
  String backupStrength(String strength);

  /// Passphrase strength label: too short. Max 40 characters
  ///
  /// In en, this message translates to:
  /// **'Use at least 8 characters'**
  String get strengthTooShort;

  /// Passphrase strength: weak. Max 20 characters
  ///
  /// In en, this message translates to:
  /// **'Weak'**
  String get strengthWeak;

  /// Passphrase strength: fair. Max 20 characters
  ///
  /// In en, this message translates to:
  /// **'Fair'**
  String get strengthFair;

  /// Passphrase strength: good. Max 20 characters
  ///
  /// In en, this message translates to:
  /// **'Good'**
  String get strengthGood;

  /// Passphrase strength: strong. Max 20 characters
  ///
  /// In en, this message translates to:
  /// **'Strong'**
  String get strengthStrong;

  /// Backup: button to open a file. Max 20 characters
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get backupOpen;

  /// Backup: section size when the store is empty. Max 20 characters
  ///
  /// In en, this message translates to:
  /// **'Nothing yet'**
  String get backupNothingYet;

  /// Backup: what the settings section holds. Two lines at most
  ///
  /// In en, this message translates to:
  /// **'Theme, languages, typing and privacy choices'**
  String get backupSettingsSummary;

  /// Backup: learned words summary. {words} and {languages} are counts such as "3 words in 2 languages"
  ///
  /// In en, this message translates to:
  /// **'{words} in {languages}'**
  String backupLearnedSummary(String languages, String words);

  /// Backup: clipboard section summary when it is off. {items} is a count such as "2 pinned items"
  ///
  /// In en, this message translates to:
  /// **'{items}. Off unless you turn it on.'**
  String backupPinnedOff(String items);

  /// Restore summary: shortcuts skipped because they exist. Max 60 characters
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one {1 shortcut already here} other {{count} shortcuts already here}}'**
  String backupAlreadyHere(int count);

  /// Restore summary: theme files skipped because they exist. Max 60 characters
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one {1 theme file already here} other {{count} theme files already here}}'**
  String backupThemesAlreadyHere(int count);

  /// Restore summary part: clipboard not restored. Lowercase, follows "Restored"
  ///
  /// In en, this message translates to:
  /// **'clipboard left alone (unknown layout)'**
  String get backupClipboardKept;

  /// Restore summary part: recent emoji kept. Lowercase
  ///
  /// In en, this message translates to:
  /// **'emoji recents kept'**
  String get backupEmojiKept;

  /// Restore summary part: settings were applied. Lowercase
  ///
  /// In en, this message translates to:
  /// **'settings'**
  String get backupSettingsApplied;

  /// Restore summary part: learned words added. Lowercase. Same wording as restoreLearnedFor
  ///
  /// In en, this message translates to:
  /// **'learned words for {count, plural, one {1 language} other {{count} languages}}'**
  String backupLearnedAdded(int count);

  /// Shortcuts: dialog title. {trigger} is the short form. Max 40 characters
  ///
  /// In en, this message translates to:
  /// **'Delete \"{trigger}\"?'**
  String shortcutDeleteTitle(String trigger);

  /// Shortcuts: dialog text. Two lines at most
  ///
  /// In en, this message translates to:
  /// **'This removes the shortcut. It cannot be undone.'**
  String get shortcutDeleteBody;

  /// Shortcuts: button. Max 30 characters
  ///
  /// In en, this message translates to:
  /// **'Add shortcut'**
  String get shortcutAdd;

  /// Shortcuts: search field label. Max 30 characters
  ///
  /// In en, this message translates to:
  /// **'Search shortcuts'**
  String get shortcutSearch;

  /// Shortcuts: empty search result. Max 50 characters
  ///
  /// In en, this message translates to:
  /// **'No shortcuts match your search.'**
  String get shortcutNoMatch;

  /// Shortcuts: delete button tooltip. {trigger} is the short form. Max 30 characters
  ///
  /// In en, this message translates to:
  /// **'Delete {trigger}'**
  String shortcutDeleteTooltip(String trigger);

  /// Shortcuts: empty list title. Max 30 characters
  ///
  /// In en, this message translates to:
  /// **'No shortcuts yet'**
  String get shortcutNoneYet;

  /// Shortcuts: explains what a shortcut is. Two lines at most
  ///
  /// In en, this message translates to:
  /// **'A shortcut turns a short form into longer text. Examples:'**
  String get shortcutExplain;

  /// Shortcuts: two example lines, each "short form → expansion". {first} and {second} are the example lines
  ///
  /// In en, this message translates to:
  /// **'{first}\n{second}'**
  String shortcutExamples(String first, String second);

  /// Shortcuts: privacy note. Two lines at most
  ///
  /// In en, this message translates to:
  /// **'Shortcuts are encrypted on this phone, like your learned words.'**
  String get shortcutEncrypted;

  /// Shortcuts: dialog title for a new shortcut. Max 30 characters
  ///
  /// In en, this message translates to:
  /// **'New shortcut'**
  String get shortcutNew;

  /// Shortcuts: dialog title for editing. Max 30 characters
  ///
  /// In en, this message translates to:
  /// **'Edit shortcut'**
  String get shortcutEdit;

  /// Shortcuts: field label. Max 20 characters
  ///
  /// In en, this message translates to:
  /// **'Short form'**
  String get shortcutShortForm;

  /// Shortcuts: field label. Max 20 characters
  ///
  /// In en, this message translates to:
  /// **'Expands to'**
  String get shortcutExpandsTo;

  /// Accessibility label of the privacy mascot picture. Max 40 characters
  ///
  /// In en, this message translates to:
  /// **'BooBoard privacy mascot'**
  String get privacyMascotLabel;

  /// Privacy: stored data name. Max 30 characters
  ///
  /// In en, this message translates to:
  /// **'Emoji recents'**
  String get privacyStoredEmoji;

  /// Privacy: stored data name for the app list. Max 30 characters
  ///
  /// In en, this message translates to:
  /// **'Apps list'**
  String get privacyStoredApps;

  /// Privacy: stored data name for anything else. Max 30 characters
  ///
  /// In en, this message translates to:
  /// **'Other stored data'**
  String get privacyStoredOther;

  /// A size in bytes. {count} is a number
  ///
  /// In en, this message translates to:
  /// **'{count} B'**
  String privacyUnitBytes(num count);

  /// A size in kilobytes. {count} is a number
  ///
  /// In en, this message translates to:
  /// **'{count} KB'**
  String privacyUnitKilobytes(num count);

  /// A size in megabytes. {count} is a number
  ///
  /// In en, this message translates to:
  /// **'{count} MB'**
  String privacyUnitMegabytes(num count);

  /// Shortcut error: empty short form. Two lines at most
  ///
  /// In en, this message translates to:
  /// **'Type the short form you want to expand.'**
  String get shortcutProblemEmptyTrigger;

  /// Shortcut error: too long. {count} is a number
  ///
  /// In en, this message translates to:
  /// **'The short form can be at most {count} characters.'**
  String shortcutProblemTriggerTooLong(num count);

  /// Shortcut error: bad characters. Two lines at most
  ///
  /// In en, this message translates to:
  /// **'Use only letters, digits and apostrophes in the short form.'**
  String get shortcutProblemTriggerCharacters;

  /// Shortcut error: empty expansion. Two lines at most
  ///
  /// In en, this message translates to:
  /// **'Type what the short form should expand to.'**
  String get shortcutProblemEmptyExpansion;

  /// Shortcut error: expansion too long. {count} is a number
  ///
  /// In en, this message translates to:
  /// **'The expansion can be at most {count} characters.'**
  String shortcutProblemExpansionTooLong(num count);

  /// Shortcut error: duplicate. Two lines at most
  ///
  /// In en, this message translates to:
  /// **'You already have a shortcut with this short form.'**
  String get shortcutProblemDuplicate;

  /// Shortcut error: too many. {count} is a number
  ///
  /// In en, this message translates to:
  /// **'You can keep at most {count} shortcuts.'**
  String shortcutProblemTooMany(num count);

  /// Onboarding welcome page headline, spoken by Boo the ghost mascot. Text between asterisks is set in italic; keep the asterisks. Max 20 characters
  ///
  /// In en, this message translates to:
  /// **'Hi, I\'m *Boo.*'**
  String get onboardingWelcomeTitle;

  /// Onboarding welcome page: Boo introduces the keyboard, in the first person. Two short sentences
  ///
  /// In en, this message translates to:
  /// **'I\'m a keyboard that never goes online. What you type stays on this phone, locked away.'**
  String get onboardingWelcomeBody;

  /// Onboarding welcome page button that starts setup. Max 20 characters
  ///
  /// In en, this message translates to:
  /// **'Let\'s set up'**
  String get onboardingWelcomeStart;

  /// Screen reader label for the floating ghost mascot on the welcome page
  ///
  /// In en, this message translates to:
  /// **'Boo, the BooBoard ghost'**
  String get onboardingMascotLabel;

  /// Onboarding privacy step: row title. Max 30 characters
  ///
  /// In en, this message translates to:
  /// **'No internet permission'**
  String get onboardingFactNoInternet;

  /// Onboarding privacy step: row title. Max 30 characters
  ///
  /// In en, this message translates to:
  /// **'Open source'**
  String get onboardingFactOpenSource;

  /// Onboarding privacy step: row text under "Open source"
  ///
  /// In en, this message translates to:
  /// **'Anyone can read the code and check.'**
  String get onboardingFactOpenSourceBody;

  /// Onboarding demo animation: title of Android's keyboard list (as Android shows it)
  ///
  /// In en, this message translates to:
  /// **'Keyboard apps'**
  String get onboardingDemoKeyboards;

  /// Onboarding demo animation: a placeholder name for the phone's other keyboard
  ///
  /// In en, this message translates to:
  /// **'Other keyboard'**
  String get onboardingDemoOtherKeyboard;

  /// Onboarding demo animation: title of Android's warning dialog
  ///
  /// In en, this message translates to:
  /// **'Attention'**
  String get onboardingDemoAttention;

  /// Onboarding demo animation: Android's warning text, shortened
  ///
  /// In en, this message translates to:
  /// **'This input method may be able to collect all the text you type… Use this input method?'**
  String get onboardingDemoAttentionBody;

  /// Onboarding demo animation: the OK button in Android's dialog
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get onboardingDemoOk;

  /// Onboarding demo animation: title of Android's keyboard picker
  ///
  /// In en, this message translates to:
  /// **'Choose input method'**
  String get onboardingDemoChooseInput;

  /// Onboarding demo caption, step 1 of 3. Max 14 characters
  ///
  /// In en, this message translates to:
  /// **'Switch on'**
  String get onboardingDemoSwitchOn;

  /// Onboarding demo caption, step 2 of 3. Max 14 characters
  ///
  /// In en, this message translates to:
  /// **'OK, then OK'**
  String get onboardingDemoTapOk;

  /// Onboarding demo caption, step 3 of 3. Max 14 characters
  ///
  /// In en, this message translates to:
  /// **'Come back'**
  String get onboardingDemoComeBack;

  /// Onboarding demo caption, step 1 of 2. Max 16 characters
  ///
  /// In en, this message translates to:
  /// **'Pick BooBoard'**
  String get onboardingDemoPick;

  /// Onboarding demo caption, step 2 of 2. Max 16 characters
  ///
  /// In en, this message translates to:
  /// **'Start typing'**
  String get onboardingDemoStartTyping;

  /// Onboarding demo animation: Android's second notice after switching a keyboard on (as Android shows it)
  ///
  /// In en, this message translates to:
  /// **'Note: After a reboot, this app can\'t start until you unlock your phone'**
  String get onboardingDemoRebootNote;

  /// Onboarding demo animation: a short incoming chat message. Keep it short
  ///
  /// In en, this message translates to:
  /// **'See you at 7?'**
  String get onboardingDemoChatIn;

  /// Onboarding demo animation: a short outgoing chat reply. Keep it short
  ///
  /// In en, this message translates to:
  /// **'On my way'**
  String get onboardingDemoChatOut;

  /// Onboarding demo animation: placeholder of a chat app's message field
  ///
  /// In en, this message translates to:
  /// **'Message'**
  String get onboardingDemoMessage;

  /// Onboarding, privacy step: Boo's whisper in a speech bubble (a sound for 'quiet'). Max 6 characters
  ///
  /// In en, this message translates to:
  /// **'shh'**
  String get onboardingShh;

  /// Onboarding, try step: Boo's speech bubble. Max 12 characters
  ///
  /// In en, this message translates to:
  /// **'Try me'**
  String get onboardingTryMe;

  /// Onboarding: serif headline. Text between asterisks is set in italic; keep the asterisks around one word or short phrase. Max 30 characters
  ///
  /// In en, this message translates to:
  /// **'Turn on *BooBoard*'**
  String get onboardingTurnOnTitle;

  /// Onboarding: step explanation. Three lines at most
  ///
  /// In en, this message translates to:
  /// **'Switch it on in Android\'s keyboard list, then come back. This page notices by itself.'**
  String get onboardingTurnOnBody;

  /// Onboarding: status when BooBoard is on. Max 40 characters
  ///
  /// In en, this message translates to:
  /// **'BooBoard is on'**
  String get onboardingKeyboardOn;

  /// Onboarding: status when BooBoard is off. Max 40 characters
  ///
  /// In en, this message translates to:
  /// **'Not on yet'**
  String get onboardingKeyboardOff;

  /// Onboarding: button. Max 30 characters
  ///
  /// In en, this message translates to:
  /// **'Open keyboard settings'**
  String get onboardingOpenKeyboardSettings;

  /// Onboarding: serif headline. Text between asterisks is set in italic; keep the asterisks around one word or short phrase. Max 30 characters
  ///
  /// In en, this message translates to:
  /// **'Make it *yours*'**
  String get onboardingSwitchTitle;

  /// Onboarding: step explanation. Three lines at most
  ///
  /// In en, this message translates to:
  /// **'Pick BooBoard from Android\'s short list. You can switch back any time.'**
  String get onboardingSwitchBody;

  /// Onboarding: status when BooBoard is chosen. Max 40 characters
  ///
  /// In en, this message translates to:
  /// **'BooBoard is your keyboard'**
  String get onboardingKeyboardIsYours;

  /// Onboarding: status when BooBoard is on but not chosen. Max 40 characters
  ///
  /// In en, this message translates to:
  /// **'Not your keyboard yet'**
  String get onboardingKeyboardNotYours;

  /// Onboarding: status when the previous step is not done. Two lines at most
  ///
  /// In en, this message translates to:
  /// **'Turn it on first'**
  String get onboardingTurnOnFirst;

  /// Onboarding: button. Max 30 characters
  ///
  /// In en, this message translates to:
  /// **'Choose keyboard'**
  String get onboardingChooseKeyboard;

  /// Onboarding: privacy step while permissions are read. Max 60 characters
  ///
  /// In en, this message translates to:
  /// **'Checking the app permissions…'**
  String get onboardingCheckingPermissions;

  /// Onboarding: debug build privacy note. Three lines at most
  ///
  /// In en, this message translates to:
  /// **'This debug build can reach the internet. Debug builds have that permission for development only.'**
  String get onboardingDebugInternet;

  /// Onboarding: privacy note for a build that can reach the internet. Two lines at most
  ///
  /// In en, this message translates to:
  /// **'This build can reach the internet.'**
  String get onboardingReleaseInternet;

  /// Onboarding: privacy note. Two lines at most
  ///
  /// In en, this message translates to:
  /// **'BooBoard has no internet permission, so it cannot send anything anywhere.'**
  String get onboardingNoInternet;

  /// Onboarding: serif headline. Text between asterisks is set in italic; keep the asterisks around one word or short phrase. Max 30 characters
  ///
  /// In en, this message translates to:
  /// **'About that *warning*'**
  String get onboardingWarningTitle;

  /// Onboarding: explanation. Four lines at most
  ///
  /// In en, this message translates to:
  /// **'Android shows it for every keyboard, because a keyboard could send what you type online. BooBoard can\'t.'**
  String get onboardingWarningBody;

  /// Onboarding: privacy row title. Max 30 characters
  ///
  /// In en, this message translates to:
  /// **'Internet access'**
  String get onboardingInternetAccess;

  /// Onboarding: privacy row title. Max 40 characters
  ///
  /// In en, this message translates to:
  /// **'Kept on this phone'**
  String get onboardingEverythingHere;

  /// Onboarding: privacy row subtitle. Two lines at most. Android Keystore is the name of the Android key store
  ///
  /// In en, this message translates to:
  /// **'Learned words, clipboard and settings are encrypted with a key in Android Keystore.'**
  String get onboardingEverythingHereBody;

  /// Onboarding: serif headline. Text between asterisks is set in italic; keep the asterisks around one word or short phrase. Max 30 characters
  ///
  /// In en, this message translates to:
  /// **'Your *languages*'**
  String get onboardingLanguagesTitle;

  /// Onboarding: theme card title. Max 20 characters
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get onboardingThemeTitle;

  /// Onboarding: try-it checklist item. Max 40 characters
  ///
  /// In en, this message translates to:
  /// **'Type a sentence'**
  String get onboardingTryTyping;

  /// Onboarding: try-it checklist item. Two lines at most
  ///
  /// In en, this message translates to:
  /// **'Swipe a word, letter to letter'**
  String get onboardingTrySwipe;

  /// Onboarding: try-it checklist item. Two lines at most
  ///
  /// In en, this message translates to:
  /// **'Long-press a letter for accents'**
  String get onboardingTryAccents;

  /// Onboarding: serif headline. Text between asterisks is set in italic; keep the asterisks around one word or short phrase. Max 30 characters
  ///
  /// In en, this message translates to:
  /// **'Give it a *try*'**
  String get onboardingTryTitle;

  /// Onboarding: text field label. Max 30 characters
  ///
  /// In en, this message translates to:
  /// **'Type something here'**
  String get onboardingTryField;

  /// Onboarding: serif headline. Text between asterisks is set in italic; keep the asterisks around one word or short phrase. Max 30 characters
  ///
  /// In en, this message translates to:
  /// **'You\'re *all set.*'**
  String get onboardingAllSetTitle;

  /// Onboarding: last step explanation. Three lines at most
  ///
  /// In en, this message translates to:
  /// **'Languages, typing, themes and more are in Settings whenever you want them.'**
  String get onboardingAllSetBody;

  /// Onboarding: progress label for screen readers. {step} and {total} are numbers
  ///
  /// In en, this message translates to:
  /// **'Step {step} of {total}'**
  String onboardingStepOf(String step, String total);

  /// Onboarding: back button. Max 20 characters
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get onboardingBack;

  /// Onboarding: next button. Max 20 characters
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get onboardingNext;

  /// Onboarding and dialogs: finish button. Max 20 characters
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get onboardingDone;

  /// Onboarding: search field hint. Max 30 characters
  ///
  /// In en, this message translates to:
  /// **'Search languages'**
  String get onboardingSearchLanguages;

  /// Onboarding: summary of the selected languages. {languages} is a list of names
  ///
  /// In en, this message translates to:
  /// **'Selected: {languages}'**
  String onboardingSelected(String languages);

  /// Onboarding: empty search result. Max 50 characters
  ///
  /// In en, this message translates to:
  /// **'No language matches that search.'**
  String get onboardingNoLanguageMatch;

  /// Themes: button and label to create a theme. Max 30 characters
  ///
  /// In en, this message translates to:
  /// **'Create theme'**
  String get themeCreate;

  /// Themes: card label when selected. {name} is the theme name
  ///
  /// In en, this message translates to:
  /// **'{name}, selected'**
  String themeSelectedLabel(String name);

  /// Themes: tooltip of a theme card's menu. {name} is the theme name
  ///
  /// In en, this message translates to:
  /// **'Options for {name}'**
  String themeCardOptions(String name);

  /// Themes: menu item. Max 20 characters
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get themeEdit;

  /// Themes: menu item. Max 20 characters
  ///
  /// In en, this message translates to:
  /// **'Duplicate'**
  String get themeDuplicate;

  /// Themes: menu item. Max 20 characters
  ///
  /// In en, this message translates to:
  /// **'Rename'**
  String get themeRename;

  /// Themes: menu item to delete a theme. Max 20 characters
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get themeDeleteAction;

  /// Themes: section title for the try-it field. Max 30 characters
  ///
  /// In en, this message translates to:
  /// **'Try typing'**
  String get themeTryTyping;

  /// Themes: label of the try-it field. Max 40 characters
  ///
  /// In en, this message translates to:
  /// **'Type here to try the theme'**
  String get themeTryLabel;

  /// Themes: helper under the try-it field. Two lines at most
  ///
  /// In en, this message translates to:
  /// **'The keyboard appears here when BooBoard is selected.'**
  String get themeTryHelper;

  /// Themes: rename dialog title. Max 30 characters
  ///
  /// In en, this message translates to:
  /// **'Rename theme'**
  String get themeRenameTitle;

  /// Theme editor and rename dialog: field label. Max 20 characters
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get themeNameField;

  /// Theme editor: app bar title when editing. Max 30 characters
  ///
  /// In en, this message translates to:
  /// **'Edit theme'**
  String get themeEditTitle;

  /// Theme editor: app bar title when creating. Max 30 characters
  ///
  /// In en, this message translates to:
  /// **'New theme'**
  String get themeNewTitle;

  /// Theme editor: app bar title while loading. Max 20 characters
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get themeEditorTitle;

  /// Theme editor: loading failed. Two lines at most
  ///
  /// In en, this message translates to:
  /// **'This theme could not be opened.'**
  String get themeOpenFailed;

  /// Theme editor: save failed. Max 50 characters
  ///
  /// In en, this message translates to:
  /// **'Could not save the theme.'**
  String get themeSaveFailed;

  /// Theme editor: photo picker failed. Max 50 characters
  ///
  /// In en, this message translates to:
  /// **'The photo picker could not open.'**
  String get themePhotoPickerFailed;

  /// Theme editor: confirmation title. Max 40 characters
  ///
  /// In en, this message translates to:
  /// **'Discard changes?'**
  String get themeDiscardTitle;

  /// Theme editor: confirmation text. Two lines at most
  ///
  /// In en, this message translates to:
  /// **'Your changes to this theme will be lost.'**
  String get themeDiscardBody;

  /// Theme editor: button to stay. Max 30 characters
  ///
  /// In en, this message translates to:
  /// **'Keep editing'**
  String get themeKeepEditing;

  /// Theme editor: button to discard. Max 20 characters
  ///
  /// In en, this message translates to:
  /// **'Discard'**
  String get themeDiscard;

  /// Theme editor: save button. Max 20 characters
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get themeSave;

  /// Theme editor: error under the name field. Max 40 characters
  ///
  /// In en, this message translates to:
  /// **'A name is required'**
  String get themeNameRequired;

  /// Theme editor: name field label. Max 30 characters
  ///
  /// In en, this message translates to:
  /// **'Theme name'**
  String get themeNameLabel;

  /// Default name for a new theme. Max 30 characters
  ///
  /// In en, this message translates to:
  /// **'My theme'**
  String get themeDefaultName;

  /// Theme editor: section title. Max 20 characters
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get themeSectionName;

  /// Theme editor: section title. Max 20 characters
  ///
  /// In en, this message translates to:
  /// **'Look'**
  String get themeSectionLook;

  /// Theme editor: setting title. Max 30 characters
  ///
  /// In en, this message translates to:
  /// **'Dark mode'**
  String get themeDarkMode;

  /// Theme editor: segmented choice. Max 20 characters
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get themeChoiceSystem;

  /// Theme editor: segmented choice. Max 20 characters
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get themeChoiceLight;

  /// Theme editor: segmented choice. Max 20 characters
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get themeChoiceDark;

  /// Theme editor: switch title. Max 30 characters
  ///
  /// In en, this message translates to:
  /// **'Pure black'**
  String get themePureBlack;

  /// Theme editor: switch subtitle when dark. Max 40 characters
  ///
  /// In en, this message translates to:
  /// **'Black background'**
  String get themePureBlackBody;

  /// Theme editor: switch subtitle when not dark. Max 40 characters
  ///
  /// In en, this message translates to:
  /// **'Only in dark mode'**
  String get themePureBlackOnlyDark;

  /// Themes gallery: switch subtitle when dark. Max 50 characters
  ///
  /// In en, this message translates to:
  /// **'Black background in dark mode'**
  String get themeGalleryPureBlackDark;

  /// Theme editor: setting title. Max 30 characters
  ///
  /// In en, this message translates to:
  /// **'Contrast'**
  String get themeContrast;

  /// Theme editor: segmented choice. Max 20 characters
  ///
  /// In en, this message translates to:
  /// **'Standard'**
  String get themeChoiceStandard;

  /// Theme editor: segmented choice. Max 20 characters
  ///
  /// In en, this message translates to:
  /// **'Medium'**
  String get themeChoiceMedium;

  /// Theme editor: segmented choice. Max 20 characters
  ///
  /// In en, this message translates to:
  /// **'High'**
  String get themeChoiceHigh;

  /// Theme editor: slider title. Max 30 characters
  ///
  /// In en, this message translates to:
  /// **'Keyboard height'**
  String get themeKeyboardHeight;

  /// Theme editor: section title. Max 20 characters
  ///
  /// In en, this message translates to:
  /// **'Colours'**
  String get themeSectionColours;

  /// Theme editor: colour source title. Max 20 characters
  ///
  /// In en, this message translates to:
  /// **'Source'**
  String get themeSource;

  /// Theme editor: colour source choice. Max 20 characters
  ///
  /// In en, this message translates to:
  /// **'Wallpaper'**
  String get themeSourceWallpaper;

  /// Theme editor: colour source choice. Max 20 characters
  ///
  /// In en, this message translates to:
  /// **'Seed'**
  String get themeSourceSeed;

  /// Theme editor: colour source choice. Max 20 characters
  ///
  /// In en, this message translates to:
  /// **'Per role'**
  String get themeSourcePerRole;

  /// Theme editor: note when the wallpaper source is not available. Two lines at most
  ///
  /// In en, this message translates to:
  /// **'Wallpaper colours need Android 12 or newer.'**
  String get themeWallpaperNeedsAndroid12;

  /// Theme editor: colour setting title. Max 30 characters
  ///
  /// In en, this message translates to:
  /// **'Seed colour'**
  String get themeSeedColour;

  /// Theme editor: colour scheme title. Max 20 characters
  ///
  /// In en, this message translates to:
  /// **'Scheme'**
  String get themeScheme;

  /// Theme editor: row title for each colour role. Max 30 characters
  ///
  /// In en, this message translates to:
  /// **'Colour roles'**
  String get themeColourRoles;

  /// Theme editor: subtitle of colour roles. {mode} is dark or light
  ///
  /// In en, this message translates to:
  /// **'{mode, select, dark {Editing the dark colours} other {Editing the light colours}}'**
  String themeEditingColours(String mode);

  /// Theme editor: button to reset every colour role. Max 30 characters
  ///
  /// In en, this message translates to:
  /// **'Reset all roles'**
  String get themeResetRoles;

  /// Theme editor: section title. Max 20 characters
  ///
  /// In en, this message translates to:
  /// **'Keys'**
  String get themeKeys;

  /// Theme editor: key shape slider title. Max 20 characters
  ///
  /// In en, this message translates to:
  /// **'Shape'**
  String get themeShape;

  /// Theme editor: key shape named Pill. Max 20 characters
  ///
  /// In en, this message translates to:
  /// **'Pill'**
  String get themeShapePill;

  /// Theme editor: key shape named Rounded. Max 20 characters
  ///
  /// In en, this message translates to:
  /// **'Rounded'**
  String get themeShapeRounded;

  /// Theme editor: key shape named Square. Max 20 characters
  ///
  /// In en, this message translates to:
  /// **'Square'**
  String get themeShapeSquare;

  /// Theme editor: switch title. Max 30 characters
  ///
  /// In en, this message translates to:
  /// **'Key borders'**
  String get themeKeyBorders;

  /// Theme editor: slider title. Max 30 characters
  ///
  /// In en, this message translates to:
  /// **'Border width'**
  String get themeBorderWidth;

  /// Theme editor: slider title. Max 20 characters
  ///
  /// In en, this message translates to:
  /// **'Key gap'**
  String get themeKeyGap;

  /// Theme editor: slider title. Max 20 characters
  ///
  /// In en, this message translates to:
  /// **'Font weight'**
  String get themeFontWeight;

  /// Theme editor: slider title. Max 20 characters
  ///
  /// In en, this message translates to:
  /// **'Font size'**
  String get themeFontSize;

  /// Theme editor: switch title. Max 30 characters
  ///
  /// In en, this message translates to:
  /// **'Hint characters'**
  String get themeHintCharacters;

  /// Theme editor: switch subtitle. Max 40 characters
  ///
  /// In en, this message translates to:
  /// **'Small characters on long press'**
  String get themeHintCharactersBody;

  /// Theme editor: section title. Max 20 characters
  ///
  /// In en, this message translates to:
  /// **'Background'**
  String get themeBackground;

  /// Theme editor: background type title. Max 20 characters
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get themeBackgroundType;

  /// Theme editor: background type choice. Max 20 characters
  ///
  /// In en, this message translates to:
  /// **'Solid'**
  String get themeTypeSolid;

  /// Theme editor: background type choice. Max 20 characters
  ///
  /// In en, this message translates to:
  /// **'Gradient'**
  String get themeTypeGradient;

  /// Theme editor: background type choice. Max 20 characters
  ///
  /// In en, this message translates to:
  /// **'Photo'**
  String get themeTypePhoto;

  /// Theme editor: empty photo background. Two lines at most
  ///
  /// In en, this message translates to:
  /// **'No photo yet. Choose one to crop it to the keyboard.'**
  String get themeNoPhotoYet;

  /// Theme editor: button. Max 20 characters
  ///
  /// In en, this message translates to:
  /// **'Choose photo'**
  String get themeChoosePhoto;

  /// Theme editor: button for the photo crop screen. Max 30 characters
  ///
  /// In en, this message translates to:
  /// **'Edit crop and blur'**
  String get themeEditCrop;

  /// Theme editor: slider title. Max 20 characters
  ///
  /// In en, this message translates to:
  /// **'Dim'**
  String get themeDim;

  /// Theme editor: section title. Max 30 characters
  ///
  /// In en, this message translates to:
  /// **'Popups and trail'**
  String get themeSectionPopups;

  /// Theme editor: switch title. Max 30 characters
  ///
  /// In en, this message translates to:
  /// **'Solid popups'**
  String get themeSolidPopups;

  /// Theme editor: switch subtitle with wallpaper colours. Max 40 characters
  ///
  /// In en, this message translates to:
  /// **'Not with wallpaper colours'**
  String get themeSolidPopupsBodyWallpaper;

  /// Theme editor: switch subtitle. Max 40 characters
  ///
  /// In en, this message translates to:
  /// **'Popups in the primary colour'**
  String get themeSolidPopupsBodyPrimary;

  /// Theme editor: switch title. Max 30 characters
  ///
  /// In en, this message translates to:
  /// **'Swipe trail'**
  String get themeSwipeTrail;

  /// Theme editor: slider title. Max 30 characters
  ///
  /// In en, this message translates to:
  /// **'Trail width'**
  String get themeTrailWidth;

  /// Theme editor: slider title. Max 30 characters
  ///
  /// In en, this message translates to:
  /// **'Trail fade'**
  String get themeTrailFade;

  /// Theme editor: trail fade value when zero. Max 20 characters
  ///
  /// In en, this message translates to:
  /// **'Instant'**
  String get themeTrailInstant;

  /// Theme editor: section title. Max 30 characters
  ///
  /// In en, this message translates to:
  /// **'Trail colours'**
  String get themeTrailColours;

  /// Theme editor: trail colour label. Max 20 characters
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get themeTrailStart;

  /// Theme editor: trail colour label. Max 20 characters
  ///
  /// In en, this message translates to:
  /// **'End'**
  String get themeTrailEnd;

  /// Theme editor: colour picker title. Max 30 characters
  ///
  /// In en, this message translates to:
  /// **'Trail start'**
  String get themeTrailStartTitle;

  /// Theme editor: colour picker title. Max 30 characters
  ///
  /// In en, this message translates to:
  /// **'Trail end'**
  String get themeTrailEndTitle;

  /// Theme editor: trail colour choice. Max 20 characters
  ///
  /// In en, this message translates to:
  /// **'Automatic'**
  String get themeAutomatic;

  /// Theme editor: section title. Max 20 characters
  ///
  /// In en, this message translates to:
  /// **'Motion'**
  String get themeSectionMotion;

  /// Theme editor: switch title. Max 30 characters
  ///
  /// In en, this message translates to:
  /// **'Key press animation'**
  String get themeKeyPressAnimation;

  /// Theme editor: note when the system reduces motion. Two lines at most
  ///
  /// In en, this message translates to:
  /// **'Remove animations is on in system settings, so keys do not animate.'**
  String get themeReduceMotion;

  /// Theme editor: motion choice: none. Max 20 characters
  ///
  /// In en, this message translates to:
  /// **'Off'**
  String get themeMotionOff;

  /// Theme editor: motion choice. Max 20 characters
  ///
  /// In en, this message translates to:
  /// **'Subtle'**
  String get themeMotionSubtle;

  /// Theme editor: motion choice. Max 20 characters
  ///
  /// In en, this message translates to:
  /// **'Standard'**
  String get themeMotionStandard;

  /// Theme editor: motion choice. Max 20 characters
  ///
  /// In en, this message translates to:
  /// **'Bouncy'**
  String get themeMotionBouncy;

  /// Theme editor: Material colour scheme name. Max 30 characters
  ///
  /// In en, this message translates to:
  /// **'Tonal spot'**
  String get themeSchemeTonalSpot;

  /// Theme editor: Material colour scheme name. Max 20 characters
  ///
  /// In en, this message translates to:
  /// **'Vibrant'**
  String get themeSchemeVibrant;

  /// Theme editor: Material colour scheme name. Max 20 characters
  ///
  /// In en, this message translates to:
  /// **'Expressive'**
  String get themeSchemeExpressive;

  /// Theme editor: Material colour scheme name. Max 20 characters
  ///
  /// In en, this message translates to:
  /// **'Fidelity'**
  String get themeSchemeFidelity;

  /// Theme editor: Material colour scheme name. Max 20 characters
  ///
  /// In en, this message translates to:
  /// **'Content'**
  String get themeSchemeContent;

  /// Theme editor: Material colour scheme name. Max 20 characters
  ///
  /// In en, this message translates to:
  /// **'Monochrome'**
  String get themeSchemeMonochrome;

  /// Theme editor: Material colour scheme name. Max 20 characters
  ///
  /// In en, this message translates to:
  /// **'Neutral'**
  String get themeSchemeNeutral;

  /// Theme editor: Material colour scheme name. Max 20 characters
  ///
  /// In en, this message translates to:
  /// **'Rainbow'**
  String get themeSchemeRainbow;

  /// Theme editor: Material colour scheme name. Max 20 characters
  ///
  /// In en, this message translates to:
  /// **'Fruit salad'**
  String get themeSchemeFruitSalad;

  /// Theme editor: a custom colour with its hex code. {hex} is six hex digits
  ///
  /// In en, this message translates to:
  /// **'Custom colour #{hex}'**
  String themeCustomColourHex(String hex);

  /// Theme editor: colour swatch label. Max 30 characters
  ///
  /// In en, this message translates to:
  /// **'Custom colour'**
  String get themeCustomColour;

  /// Theme editor: colour swatch label. {label} is a role name, {hex} six hex digits
  ///
  /// In en, this message translates to:
  /// **'{label} colour, #{hex}'**
  String themeSwatchLabel(String hex, String label);

  /// Theme editor: tooltip to reset one colour. {label} is a role name
  ///
  /// In en, this message translates to:
  /// **'Use the scheme colour for {label}'**
  String themeUseSchemeColour(String label);

  /// Theme editor: colour role subtitle when not overridden. Max 40 characters
  ///
  /// In en, this message translates to:
  /// **'From the scheme'**
  String get themeFromScheme;

  /// Theme editor: colour role subtitle when overridden. Max 20 characters
  ///
  /// In en, this message translates to:
  /// **'Set'**
  String get themeOverridden;

  /// Theme editor: gradient colour stop name. {n} is a number
  ///
  /// In en, this message translates to:
  /// **'Stop {n}'**
  String themeStopLabel(String n);

  /// Theme editor: colour picker title for a gradient stop. {n} is a number
  ///
  /// In en, this message translates to:
  /// **'Stop {n}'**
  String themePickStopTitle(String n);

  /// Theme editor: button. Max 20 characters
  ///
  /// In en, this message translates to:
  /// **'Add stop'**
  String get themeAddStop;

  /// Theme editor: button. Max 20 characters
  ///
  /// In en, this message translates to:
  /// **'Remove stop'**
  String get themeRemoveStop;

  /// Theme editor: gradient angle slider title. Max 20 characters
  ///
  /// In en, this message translates to:
  /// **'Angle'**
  String get themeAngle;

  /// Theme editor: tooltip. Max 40 characters
  ///
  /// In en, this message translates to:
  /// **'Use the scheme colour'**
  String get themeUseSchemeTooltipLabel;

  /// Photo crop screen: title. Max 30 characters
  ///
  /// In en, this message translates to:
  /// **'Crop photo'**
  String get themeCropTitle;

  /// Photo crop screen: confirm button. Max 20 characters
  ///
  /// In en, this message translates to:
  /// **'Use photo'**
  String get themeUsePhoto;

  /// Photo crop: save failed. Max 50 characters
  ///
  /// In en, this message translates to:
  /// **'The photo could not be saved.'**
  String get themeCropSaveFailed;

  /// Photo crop: accessibility label of the crop area. Two lines at most
  ///
  /// In en, this message translates to:
  /// **'Photo crop. Drag to move the photo and pinch or use the zoom slider to zoom.'**
  String get themeCropSemantics;

  /// Photo crop: slider title. Max 20 characters
  ///
  /// In en, this message translates to:
  /// **'Zoom'**
  String get themeCropZoom;

  /// Photo crop: slider title. Max 20 characters
  ///
  /// In en, this message translates to:
  /// **'Blur'**
  String get themeCropBlur;

  /// Photo crop: blur value when zero. Max 20 characters
  ///
  /// In en, this message translates to:
  /// **'Off'**
  String get themeCropBlurOff;

  /// Photo crop: note. Two lines at most
  ///
  /// In en, this message translates to:
  /// **'The blur is saved into the picture. The dim is set in the editor and applied live.'**
  String get themeCropNote;

  /// Colour picker: hex field label. Max 20 characters
  ///
  /// In en, this message translates to:
  /// **'Hex'**
  String get themeHexLabel;

  /// Colour picker: error for a bad hex code. Max 50 characters
  ///
  /// In en, this message translates to:
  /// **'Use six hex digits, such as F5B700'**
  String get themeHexError;

  /// Colour picker: slider. Max 20 characters
  ///
  /// In en, this message translates to:
  /// **'Hue'**
  String get themeHue;

  /// Colour picker: slider. Max 20 characters
  ///
  /// In en, this message translates to:
  /// **'Saturation'**
  String get themeSaturation;

  /// Colour picker: slider. Max 20 characters
  ///
  /// In en, this message translates to:
  /// **'Brightness'**
  String get themeBrightness;

  /// Colour picker: instruction. Two lines at most
  ///
  /// In en, this message translates to:
  /// **'Pick a shade, then tap Use.'**
  String get themePickShadeHint;

  /// Colour picker: confirm button. Max 12 characters
  ///
  /// In en, this message translates to:
  /// **'Use'**
  String get themePickColourUse;

  /// Suffix added to a duplicated theme name. Starts with a space
  ///
  /// In en, this message translates to:
  /// **' copy'**
  String get themeCopySuffix;

  /// Name of a duplicated theme. {name} is the original name
  ///
  /// In en, this message translates to:
  /// **'{name} copy'**
  String themeCopyName(String name);

  /// Themes gallery: delete dialog title. {name} is the theme name. Max 40 characters
  ///
  /// In en, this message translates to:
  /// **'Delete \"{name}\"?'**
  String themeDeleteTitle(String name);

  /// Themes gallery: delete dialog text for the selected theme. Three lines at most
  ///
  /// In en, this message translates to:
  /// **'This theme is selected. BooBoard Dynamic will be used instead. This cannot be undone.'**
  String get themeDeleteSelectedBody;

  /// Themes gallery: delete dialog text. Max 60 characters
  ///
  /// In en, this message translates to:
  /// **'This cannot be undone.'**
  String get themeDeleteBody;

  /// Themes gallery: delete failed. Max 50 characters
  ///
  /// In en, this message translates to:
  /// **'Could not delete the theme.'**
  String get themeDeleteFailed;

  /// Themes gallery: rename failed. Max 50 characters
  ///
  /// In en, this message translates to:
  /// **'Could not rename the theme.'**
  String get themeRenameFailed;

  /// Themes gallery: duplicate failed. Max 50 characters
  ///
  /// In en, this message translates to:
  /// **'Could not copy the theme.'**
  String get themeDuplicateFailed;

  /// Themes gallery: setting write failed. Max 50 characters
  ///
  /// In en, this message translates to:
  /// **'Could not save the setting.'**
  String get themeSettingFailed;

  /// Themes: snackbar when the system colours cannot be read. Max 60 characters
  ///
  /// In en, this message translates to:
  /// **'System colours are unavailable.'**
  String get themeSystemColoursUnavailable;

  /// Themes gallery: switch title. Max 50 characters
  ///
  /// In en, this message translates to:
  /// **'BooBoard Dynamic follows your wallpaper'**
  String get themeBooBoardDynamicFollows;

  /// Themes gallery: switch subtitle. Two lines at most
  ///
  /// In en, this message translates to:
  /// **'Its colours update when the wallpaper changes'**
  String get themeBooBoardDynamicBody;

  /// Themes gallery: section title. Max 20 characters
  ///
  /// In en, this message translates to:
  /// **'Presets'**
  String get themeSectionPresets;

  /// Themes gallery: section title. Max 20 characters
  ///
  /// In en, this message translates to:
  /// **'My themes'**
  String get themeSectionMyThemes;

  /// Themes gallery: section title. Max 20 characters
  ///
  /// In en, this message translates to:
  /// **'Try typing'**
  String get themeSectionTry;

  /// Themes gallery: section title. Max 20 characters
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get themeAppearance;

  /// Themes gallery: title. Max 20 characters
  ///
  /// In en, this message translates to:
  /// **'Themes'**
  String get themesTitle;

  /// Privacy center and backup: custom themes count and size. {size} is a size such as 14 KB
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one {1 theme file} other {{count} theme files}} · {size}'**
  String privacyThemesSize(int count, String size);

  /// Backup: a section count is locked until the phone is unlocked. Max 60 characters
  ///
  /// In en, this message translates to:
  /// **'Unlock your phone to see the count'**
  String get backupUnlockToSeeCount;

  /// Shortcuts screen: explains shortcuts with two examples. Three lines. Keep the arrows and the line breaks
  ///
  /// In en, this message translates to:
  /// **'A shortcut turns a short form into longer text. Examples:\nomw → on my way\naddr → your address'**
  String get shortcutHelp;

  /// Privacy: stored data name for learned words of one language. {language} is a language name
  ///
  /// In en, this message translates to:
  /// **'Learned words ({language})'**
  String privacyStoredLearned(String language);

  /// Settings: tooltip on an option that is not available yet. Max 40 characters
  ///
  /// In en, this message translates to:
  /// **'Coming in a later update'**
  String get settingsComingLater;

  /// Backup screen: explains how backups are protected. Three lines at most
  ///
  /// In en, this message translates to:
  /// **'A backup is one file, encrypted with a passphrase you choose. Only that passphrase opens it. If you forget the passphrase, nobody can recover the backup, including BooBoard.'**
  String get backupExplainer;

  /// Privacy center: one line of a deletion list, a category name and what it holds. {title} and {detail} are text. Max 80 characters
  ///
  /// In en, this message translates to:
  /// **'{title}: {detail}'**
  String privacyCategoryLine(String detail, String title);

  /// Shortcuts: example short form shown as a hint. Replace with a short example that fits the language
  ///
  /// In en, this message translates to:
  /// **'omw'**
  String get shortcutShortFormHint;

  /// Shortcuts: example expansion shown as a hint. Replace with a short example that fits the language
  ///
  /// In en, this message translates to:
  /// **'on my way'**
  String get shortcutExpansionHint;

  /// Panels: clipboard duration option. Max 20 characters
  ///
  /// In en, this message translates to:
  /// **'15 minutes'**
  String get durationMinutes15;

  /// Panels: clipboard duration option. Max 20 characters
  ///
  /// In en, this message translates to:
  /// **'1 hour'**
  String get durationHour;

  /// Panels: clipboard duration option. Max 20 characters
  ///
  /// In en, this message translates to:
  /// **'1 day'**
  String get durationDay;

  /// Panels: clipboard duration option. Max 20 characters
  ///
  /// In en, this message translates to:
  /// **'1 week'**
  String get durationWeek;

  /// Onboarding: close button tooltip. Max 30 characters
  ///
  /// In en, this message translates to:
  /// **'Close setup'**
  String get onboardingCloseSetup;

  /// Packs: list failed to load. Two lines at most
  ///
  /// In en, this message translates to:
  /// **'BooBoard could not read its packs'**
  String get packsCouldNotRead;

  /// Packs: delete button tooltip. {name} is the pack name. Max 40 characters
  ///
  /// In en, this message translates to:
  /// **'Delete {name}'**
  String packsDeleteTooltip(String name);

  /// Privacy center: no stored data. Max 30 characters
  ///
  /// In en, this message translates to:
  /// **'Nothing stored yet'**
  String get privacyNothingStored;

  /// Privacy center: button to remove an app from the list. {app} is an app name. Max 60 characters
  ///
  /// In en, this message translates to:
  /// **'Remove {app} from the list'**
  String privacyRemoveAppTooltip(String app);

  /// Chinese/Japanese options screen text
  ///
  /// In en, this message translates to:
  /// **'Chinese'**
  String get chineseTitle;

  /// Chinese/Japanese options screen text
  ///
  /// In en, this message translates to:
  /// **'Traditional characters'**
  String get chineseTraditional;

  /// Chinese/Japanese options screen text
  ///
  /// In en, this message translates to:
  /// **'Show candidates in Traditional characters (Taiwan standard).'**
  String get chineseTraditionalBody;

  /// Chinese/Japanese options screen text
  ///
  /// In en, this message translates to:
  /// **'Fuzzy pinyin'**
  String get chineseFuzzy;

  /// Chinese/Japanese options screen text
  ///
  /// In en, this message translates to:
  /// **'Also accept z and zh, c and ch, s and sh, n and l, an and ang, en and eng, in and ing.'**
  String get chineseFuzzyBody;

  /// Chinese/Japanese options screen text
  ///
  /// In en, this message translates to:
  /// **'Dictionary'**
  String get cjkDictionary;

  /// Chinese/Japanese options screen text
  ///
  /// In en, this message translates to:
  /// **'Clear learned phrases'**
  String get chineseClearPhrases;

  /// Chinese/Japanese options screen text
  ///
  /// In en, this message translates to:
  /// **'Forget the words you picked. The dictionary stays.'**
  String get chineseClearPhrasesBody;

  /// Chinese/Japanese options screen text
  ///
  /// In en, this message translates to:
  /// **'Chinese is typed on this phone. Learned phrases are encrypted and never leave it.'**
  String get chineseFooter;

  /// Chinese/Japanese options screen text
  ///
  /// In en, this message translates to:
  /// **'Clear learned phrases?'**
  String get chineseClearTitle;

  /// Chinese/Japanese options screen text
  ///
  /// In en, this message translates to:
  /// **'The words you picked for Chinese are removed. This cannot be undone.'**
  String get chineseClearBody;

  /// Chinese/Japanese options screen text
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get cjkClear;

  /// Chinese/Japanese options screen text
  ///
  /// In en, this message translates to:
  /// **'Learned phrases cleared'**
  String get chinesePhrasesCleared;

  /// Chinese/Japanese options screen text
  ///
  /// In en, this message translates to:
  /// **'Looking for the dictionary'**
  String get chineseLooking;

  /// Chinese/Japanese options screen text
  ///
  /// In en, this message translates to:
  /// **'Chinese dictionary'**
  String get chineseDictName;

  /// Chinese/Japanese options screen text
  ///
  /// In en, this message translates to:
  /// **'Not installed. Chinese typing needs it; install it under Model packs.'**
  String get chinesePackMissing;

  /// Chinese/Japanese options screen text
  ///
  /// In en, this message translates to:
  /// **'Installed. {license}'**
  String chinesePackInstalled(String license);

  /// Chinese/Japanese options screen text
  ///
  /// In en, this message translates to:
  /// **'Japanese'**
  String get japaneseTitle;

  /// Chinese/Japanese options screen text
  ///
  /// In en, this message translates to:
  /// **'Layout'**
  String get japaneseLayout;

  /// Chinese/Japanese options screen text
  ///
  /// In en, this message translates to:
  /// **'12-key (flick)'**
  String get japaneseLayout12;

  /// Chinese/Japanese options screen text
  ///
  /// In en, this message translates to:
  /// **'Romaji (QWERTY)'**
  String get japaneseLayoutRomaji;

  /// Chinese/Japanese options screen text
  ///
  /// In en, this message translates to:
  /// **'Typing'**
  String get japaneseTyping;

  /// Chinese/Japanese options screen text
  ///
  /// In en, this message translates to:
  /// **'Flick only'**
  String get japaneseFlickOnly;

  /// Chinese/Japanese options screen text
  ///
  /// In en, this message translates to:
  /// **'No multi-tap: tapping あ twice types ああ, not い'**
  String get japaneseFlickOnlyBody;

  /// Chinese/Japanese options screen text
  ///
  /// In en, this message translates to:
  /// **'Half-width space'**
  String get japaneseHalfWidth;

  /// Chinese/Japanese options screen text
  ///
  /// In en, this message translates to:
  /// **'Space types a normal space when nothing is being typed. Off types a full-width space.'**
  String get japaneseHalfWidthBody;

  /// Chinese/Japanese options screen text
  ///
  /// In en, this message translates to:
  /// **'Dictionary pack'**
  String get japaneseDictPack;

  /// Chinese/Japanese options screen text
  ///
  /// In en, this message translates to:
  /// **'Checking...'**
  String get japaneseChecking;

  /// Chinese/Japanese options screen text
  ///
  /// In en, this message translates to:
  /// **'{name} is installed. Kanji conversion is on.'**
  String japaneseInstalled(String name);

  /// Chinese/Japanese options screen text
  ///
  /// In en, this message translates to:
  /// **'Not installed. Kana still types; kanji need the pack.'**
  String get japaneseNotInstalled;

  /// Chinese/Japanese options screen text
  ///
  /// In en, this message translates to:
  /// **'Clear learned words'**
  String get japaneseClearWords;

  /// Chinese/Japanese options screen text
  ///
  /// In en, this message translates to:
  /// **'Forgets the Japanese words you picked. Stored encrypted on this phone.'**
  String get japaneseClearWordsBody;

  /// Chinese/Japanese options screen text
  ///
  /// In en, this message translates to:
  /// **'Clear learned Japanese words?'**
  String get japaneseClearTitle;

  /// Chinese/Japanese options screen text
  ///
  /// In en, this message translates to:
  /// **'This deletes every Japanese word you picked. It cannot be undone.'**
  String get japaneseClearBody;

  /// Chinese/Japanese options screen text
  ///
  /// In en, this message translates to:
  /// **'Chinese phrases'**
  String get privacyStoredChinesePhrases;

  /// Chinese/Japanese options screen text
  ///
  /// In en, this message translates to:
  /// **'Japanese words'**
  String get privacyStoredJapaneseWords;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>[
    'de',
    'en',
    'es',
    'fr',
    'hi',
    'id',
    'pt',
  ].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'de':
      return AppLocalizationsDe();
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
    case 'fr':
      return AppLocalizationsFr();
    case 'hi':
      return AppLocalizationsHi();
    case 'id':
      return AppLocalizationsId();
    case 'pt':
      return AppLocalizationsPt();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
