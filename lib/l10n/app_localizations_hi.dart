// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Hindi (`hi`).
class AppLocalizationsHi extends AppLocalizations {
  AppLocalizationsHi([String locale = 'hi']) : super(locale);

  @override
  String get appName => 'BooBoard';

  @override
  String get homeTagline => 'निजी टाइपिंग, इसी फ़ोन पर';

  @override
  String get homeOfflinePromise =>
      'BooBoard ऑफ़लाइन काम करता है और *कहीं कुछ नहीं भेजता।*';

  @override
  String get cancel => 'रद्द करें';

  @override
  String get delete => 'हटाएं';

  @override
  String get save => 'सहेजें';

  @override
  String get useAction => 'उपयोग करें';

  @override
  String get off => 'बंद';

  @override
  String get left => 'बाएँ';

  @override
  String get right => 'दाएँ';

  @override
  String get settingsLanguages => 'भाषाएँ';

  @override
  String get settingsTyping => 'टाइपिंग';

  @override
  String get settingsFeel => 'अनुभव';

  @override
  String get settingsThemes => 'थीम';

  @override
  String get settingsPanels => 'पैनल';

  @override
  String get settingsVoice => 'वॉइस';

  @override
  String get settingsTranslation => 'अनुवाद';

  @override
  String get settingsPrivacy => 'गोपनीयता';

  @override
  String get settingsAbout => 'के बारे में';

  @override
  String get settingsModelPacks => 'मॉडल पैक';

  @override
  String get homeSetupTurnOn =>
      'Android के कीबोर्ड की सूची में BooBoard चालू करें।';

  @override
  String get homeSetupChoose =>
      'जिस कीबोर्ड से आप टाइप करते हैं, उसके रूप में BooBoard चुनें।';

  @override
  String get homeFinishSetup => 'BooBoard का सेटअप पूरा करें';

  @override
  String get homeTypingSubtitle => 'सुधार, सुझाव, कुंजियाँ और स्वाइप';

  @override
  String get homeFeelSubtitle => 'हैप्टिक्स, ध्वनि, ऊँचाई और एक-हाथ मोड';

  @override
  String get homePanelsSubtitle => 'क्लिपबोर्ड और इमोजी';

  @override
  String get homeVoiceSubtitle => 'बोलकर टाइप करें, इसी फ़ोन पर';

  @override
  String get homeTranslationSubtitle => 'टाइप करते समय अनुवाद करें, ऑफ़लाइन';

  @override
  String get homePrivacySubtitle =>
      'क्या सहेजा जाता है, इनकॉग्निटो, ऐप लॉक और बैकअप';

  @override
  String get homeAboutSubtitle => 'संस्करण, लाइसेंस और स्रोत कोड';

  @override
  String get homeImages => 'चित्र';

  @override
  String get homeAboutBooBoard => 'BooBoard के बारे में';

  @override
  String get websiteOpenHint => 'booboard.com को आपके ब्राउज़र में खोलता है';

  @override
  String get websiteNoBrowser => 'कोई ब्राउज़र booboard.com नहीं खोल सकता।';

  @override
  String get imagesSoonTitle => 'चित्र *जल्द आ रहे हैं*';

  @override
  String get imagesSoonBody =>
      'अपने शब्दों से चित्र बनाएँ, इसी फ़ोन पर। BooBoard की हर चीज़ की तरह, यह भी ऑफ़लाइन काम करेगा।';

  @override
  String get aboutWebsite => 'वेबसाइट';

  @override
  String get aboutTitle => 'के बारे में';

  @override
  String aboutVersion(String versionCode, String versionName) {
    return 'संस्करण $versionName ($versionCode)';
  }

  @override
  String aboutVersionDebug(String versionCode, String versionName) {
    return 'संस्करण $versionName ($versionCode) · डीबग बिल्ड';
  }

  @override
  String get aboutReadingVersion => 'संस्करण पढ़ा जा रहा है…';

  @override
  String get aboutPrivacy => 'गोपनीयता';

  @override
  String get aboutNoInternet => 'BooBoard इंटरनेट का उपयोग नहीं कर सकता';

  @override
  String get aboutNoInternetBody =>
      'रिलीज़ बिल्ड में इंटरनेट की अनुमति नहीं होती, इसलिए आप जो टाइप करते हैं वह इस फ़ोन से बाहर नहीं जाता।';

  @override
  String get aboutLicence => 'लाइसेंस';

  @override
  String get aboutGplTitle => 'GNU General Public License v3 या बाद का';

  @override
  String get aboutGplBody =>
      'BooBoard मुक्त सॉफ़्टवेयर है। आप इसे GPL के तहत पढ़, बदल और साझा कर सकते हैं।';

  @override
  String get aboutSourceCode => 'स्रोत कोड';

  @override
  String get aboutSourceBody =>
      'BooBoard GPL-3.0-or-later के तहत है। इसका स्रोत कोड प्रोजेक्ट पेज पर उपलब्ध है।';

  @override
  String get aboutLicences => 'लाइसेंस';

  @override
  String get aboutOpenSource => 'ओपन-सोर्स लाइसेंस';

  @override
  String get aboutOpenSourceBody =>
      'Flutter, material_ui और BooBoard द्वारा उपयोग किए गए हर पैकेज';

  @override
  String get aboutTextLoadFailed => 'यह पाठ लोड नहीं हो सका।';

  @override
  String get languagesEnabledHeader => 'सक्षम, पहली भाषा डिफ़ॉल्ट है';

  @override
  String get languagesActive => 'सक्रिय भाषा';

  @override
  String get languagesAdd => 'भाषा जोड़ें';

  @override
  String get languagesAllEnabled => 'सभी भाषाएँ सक्षम हैं';

  @override
  String get languagesAllEnabledBody => 'जगह बनाने के लिए ऊपर से कोई एक हटाएँ।';

  @override
  String get languagesMultilingual => 'बहुभाषी टाइपिंग';

  @override
  String get languagesMultilingualBody =>
      'सक्षम तीन भाषाओं तक से शब्द सुझाता है, जिनकी लिपि कीबोर्ड की लिपि से मिलती है। जिस शब्द को उनमें से कोई भी जानती है, उसे कभी अपने-आप नहीं सुधारा जाता।';

  @override
  String get languagesNativeDigits => 'स्थानीय अंक';

  @override
  String get languagesNativeDigitsBody =>
      'जहाँ सक्रिय भाषा की अपनी लिपि में अंक हों, वहाँ उसी लिपि में अंक टाइप करता है (०१२, ٠١٢)।';

  @override
  String get languagesOptions => 'भाषा विकल्प';

  @override
  String get languagesZhSubtitle => 'पिनयिन, परंपरागत अक्षर और शब्दकोश पैक';

  @override
  String get languagesJaSubtitle => 'फ़्लिक इनपुट, रूपांतरण और शब्दकोश पैक';

  @override
  String languagesReorderLabel(String language) {
    return '$language को क्रम बदलने के लिए खींचें';
  }

  @override
  String languageDefaultLabel(String language) {
    return '$language, डिफ़ॉल्ट';
  }

  @override
  String languageLayoutTooltip(String language) {
    return '$language का लेआउट';
  }

  @override
  String languageRemoveTooltip(String language) {
    return '$language हटाएँ';
  }

  @override
  String get feelHaptics => 'हैप्टिक्स';

  @override
  String get feelHapticFeedback => 'हैप्टिक फ़ीडबैक';

  @override
  String get feelHapticFeedbackBody =>
      'हर कुंजी पर एक छोटा कंपन, सिस्टम सेटिंग के अनुसार';

  @override
  String get feelHapticStrength => 'हैप्टिक तीव्रता';

  @override
  String get feelSounds => 'ध्वनियाँ';

  @override
  String get feelKeySounds => 'कुंजी ध्वनियाँ';

  @override
  String get feelKeySoundsBody => 'कुंजी, स्पेस, हटाने और एंटर के लिए क्लिक';

  @override
  String get feelUseSystemVolume => 'सिस्टम वॉल्यूम का उपयोग करें';

  @override
  String get feelKeySoundVolume => 'कुंजी ध्वनि का वॉल्यूम';

  @override
  String get feelHeight => 'ऊँचाई';

  @override
  String get feelPortraitHeight => 'पोर्ट्रेट ऊँचाई';

  @override
  String get feelLandscapeHeight => 'लैंडस्केप ऊँचाई';

  @override
  String get feelOneHandedFloating => 'एक-हाथ और फ़्लोटिंग';

  @override
  String get feelOneHandedSide => 'एक-हाथ मोड की ओर';

  @override
  String get feelFloatingKeyboard => 'फ़्लोटिंग कीबोर्ड';

  @override
  String get feelFloatingBody => 'स्क्रीन पर कहीं भी खींचें';

  @override
  String get panelsClipboard => 'क्लिपबोर्ड';

  @override
  String get panelsClipboardHistory => 'क्लिपबोर्ड इतिहास';

  @override
  String get panelsClipboardHistoryBody =>
      'आप जो कॉपी करते हैं, वह इसी फ़ोन पर एन्क्रिप्ट करके रखा जाता है';

  @override
  String get panelsRecentChip => 'हाल की कॉपी चिप';

  @override
  String get panelsRecentChipBody =>
      'आपकी आखिरी कॉपी एक मिनट तक सुझाव पट्टी में दिखती है';

  @override
  String get panelsKeepUnpinned => 'बिना पिन की कॉपी इतने समय तक रखें';

  @override
  String get panelsClipsToKeep => 'रखने वाली क्लिप';

  @override
  String get panelsEmoji => 'इमोजी';

  @override
  String get emojiSuggestions => 'इमोजी सुझाव';

  @override
  String get emojiSuggestionsPanelBody =>
      'कुछ शब्दों के लिए सुझाव पट्टी में इमोजी दिखाता है';

  @override
  String get panelsPasswordsNeverSaved => 'पासवर्ड कभी सहेजे नहीं जाते';

  @override
  String get panelsSensitiveBody =>
      'Android जिन कॉपी को संवेदनशील बताता है, उन्हें कभी नहीं रखा जाता।';

  @override
  String get typingCorrections => 'सुधार';

  @override
  String get typingAutocorrect => 'स्वतः सुधार';

  @override
  String get typingAutocorrectBody =>
      'शब्द पूरा होने पर संभावित टाइपो ठीक करता है';

  @override
  String get typingAutoCapitalise => 'स्वतः बड़े अक्षर';

  @override
  String get typingAutoCapitaliseBody => 'वाक्य की शुरुआत में बड़े अक्षर';

  @override
  String get typingDoubleSpace => 'डबल स्पेस से पूर्ण विराम';

  @override
  String get typingDoubleSpaceBody =>
      'स्पेस दो बार दबाने पर \". \" लिखा जाता है';

  @override
  String get typingSmartPunctuation => 'स्मार्ट विराम चिह्न';

  @override
  String get typingSmartPunctuationBody =>
      'विराम चिह्नों के आसपास की जगह ठीक करता है और स्थानीय उद्धरण चिह्न लगाता है';

  @override
  String get typingSuggestions => 'सुझाव';

  @override
  String get typingSuggestionsBody => 'सुझाव पट्टी में शब्द दिखाता है';

  @override
  String get typingNextWord => 'अगला शब्द अनुमान';

  @override
  String get typingNextWordBody => 'वह शब्द सुझाता है जो अक्सर आता है';

  @override
  String get typingEmojiBody => 'कुछ शब्दों के लिए इमोजी सुझाता है';

  @override
  String get typingHideOffensive => 'अपमानजनक शब्द छिपाएँ';

  @override
  String get typingHideOffensiveBody =>
      'पूरे रूप में टाइप करने पर ही सुझाए जाते हैं';

  @override
  String get typingKeys => 'कुंजियाँ';

  @override
  String get typingKeyPopups => 'कुंजी पॉपअप';

  @override
  String get typingKeyPopupsBody => 'दबाते समय कुंजी को बड़ा करता है';

  @override
  String get typingLongPressDelay => 'लंबे दबाव की देरी';

  @override
  String get typingNumberRow => 'अंक पंक्ति';

  @override
  String get typingNumberRowBody => 'अक्षरों के ऊपर 0 से 9 दिखाता है';

  @override
  String get typingHintLabels => 'संकेत लेबल';

  @override
  String get typingHintLabelsBody =>
      'कुंजियों पर छोटे चिह्न, जैसे मात्राएँ या स्वर चिह्न';

  @override
  String get typingLowercaseLabels => 'छोटे अक्षरों के लेबल';

  @override
  String get typingLowercaseLabelsBody =>
      'शिफ़्ट चालू होने पर भी कुंजी के अक्षर छोटे रखता है';

  @override
  String get typingSwipe => 'स्वाइप';

  @override
  String get typingSwipeTyping => 'स्वाइप टाइपिंग';

  @override
  String get typingSwipeTypingBody =>
      'कोई शब्द लिखने के लिए अक्षरों पर फिसलाएँ';

  @override
  String get typingShowTrail => 'पथ दिखाएँ';

  @override
  String get typingTrailWidth => 'पथ की चौड़ाई';

  @override
  String get typingTrailFade => 'पथ धुंधलापन';

  @override
  String get typingLivePreview => 'लाइव पूर्वावलोकन';

  @override
  String get typingLivePreviewBody => 'फिसलते समय संभावित शब्द दिखाता है';

  @override
  String get typingSpaceMovesCursor => 'स्पेस बार कर्सर को हिलाता है';

  @override
  String get typingSpaceMovesCursorBody =>
      'कर्सर हिलाने के लिए स्पेस बार पर खींचें';

  @override
  String get typingSwipeBackspace => 'हटाएँ कुंजी पर स्वाइप करके शब्द हटाएँ';

  @override
  String get typingSwipeBackspaceBody =>
      'शब्द चुनने और हटाने के लिए हटाएँ कुंजी को बाईं ओर स्वाइप करें';

  @override
  String get voiceTyping => 'वॉइस टाइपिंग';

  @override
  String get voiceTypingBody =>
      'अंग्रेज़ी में बोलकर टाइप करें। पहचान इसी फ़ोन पर होती है।';

  @override
  String get voiceRecognition => 'पहचान';

  @override
  String get voiceModelPacksBody => 'वॉइस और अनुवाद पैक इंस्टॉल या हटाएँ';

  @override
  String get voiceAudioStays =>
      'ऑडियो इसी फ़ोन पर रहता है और कभी सहेजा नहीं जाता।';

  @override
  String get voicePackAutomatic => 'स्वचालित';

  @override
  String get voicePackAutomaticSelected => 'स्वचालित (चुना गया)';

  @override
  String get voicePack => 'वॉइस पैक';

  @override
  String get voiceNoPack =>
      'कोई वॉइस पैक इंस्टॉल नहीं है। मॉडल पैक के अंतर्गत एक इंस्टॉल करें।';

  @override
  String get voiceLooking => 'इंस्टॉल किए गए पैक खोजे जा रहे हैं';

  @override
  String voicePackItem(String name, String size) {
    return '$name · $size';
  }

  @override
  String voicePackItemSelected(String name, String size) {
    return '$name · $size (चुना गया)';
  }

  @override
  String megabytes(num count) {
    return '$count MB';
  }

  @override
  String milliseconds(num count) {
    return '$count ms';
  }

  @override
  String dpValue(num count) {
    return '$count dp';
  }

  @override
  String get packsOpenFailed => 'BooBoard फ़ाइल चुनने वाला टूल नहीं खोल सका।';

  @override
  String packsInstalled(String name) {
    return '$name इंस्टॉल किया गया।';
  }

  @override
  String packsDeleteTitle(String name) {
    return '$name हटाएँ?';
  }

  @override
  String get packsDeleteBody =>
      'इसकी फ़ाइलें इस फ़ोन से हटा दी जाएँगी। बाद में इसकी फ़ाइल से पैक फिर से आयात किया जा सकता है।';

  @override
  String packsDeleted(String name) {
    return '$name हटाया गया।';
  }

  @override
  String packsDeleteFailed(String name) {
    return 'BooBoard $name हटा नहीं सका। फिर से कोशिश करें।';
  }

  @override
  String get packsIntro =>
      'पैक इंस्टॉल होने से पहले जाँचे जाते हैं। इनमें केवल डेटा होता है, कोड कभी नहीं।';

  @override
  String get packsImport => 'आयात करें';

  @override
  String get packsImportTitle => 'पैक फ़ाइल आयात करें';

  @override
  String get packsChecking => 'जाँच और इंस्टॉल हो रहा है…';

  @override
  String get packsImportBody => 'एक .boopack फ़ाइल, जैसे डाउनलोड से';

  @override
  String get packsNoVoice => 'कोई वॉइस पैक इंस्टॉल नहीं है';

  @override
  String get packsNoVoiceBody => 'वॉइस टाइपिंग के लिए वॉइस पैक चाहिए।';

  @override
  String get packsNoTranslation => 'कोई अनुवाद पैक इंस्टॉल नहीं है';

  @override
  String get packsNoTranslationBody => 'अनुवाद के लिए हर दिशा का एक पैक चाहिए।';

  @override
  String get packsDictionaries => 'शब्दकोश';

  @override
  String get packsNoDictionary => 'कोई शब्दकोश पैक इंस्टॉल नहीं है';

  @override
  String get packsNoDictionaryBody =>
      'चीनी और जापानी टाइपिंग के लिए शब्दकोश पैक चाहिए।';

  @override
  String get packsGetTitle => 'पैक प्राप्त करें';

  @override
  String get packsExplainTitle =>
      'पैक वे फ़ाइलें हैं जिन्हें आप खुद जोड़ते हैं।';

  @override
  String get packsExplainBody =>
      'इन्हें किसी दूसरे डिवाइस पर प्रोजेक्ट के रिलीज़ पेज से डाउनलोड करें, इस फ़ोन पर कॉपी करें, फिर आयात करें।';

  @override
  String get packsCopyLink => 'रिलीज़ पेज का लिंक कॉपी करें';

  @override
  String get packsPrivateTitle => 'डाउनलोड निजी कैसे रहते हैं';

  @override
  String get packsPrivateBody =>
      'BooBoard के पास इंटरनेट की अनुमति नहीं है और यह कभी कनेक्ट नहीं होता। डाउनलोड आपका ब्राउज़र खोलता है, जो पैक को प्रोजेक्ट की GitHub रिलीज़ से लाता है। फिर BooBoard कुछ भी इंस्टॉल करने से पहले इसी फ़ोन पर पैक का हस्ताक्षर जाँचता है।';

  @override
  String get packsAvailableTitle => 'पैक जो आप जोड़ सकते हैं';

  @override
  String get packsDownload => 'डाउनलोड करें';

  @override
  String packsDownloadMeta(String size) {
    return '$size · आपका ब्राउज़र खुलता है';
  }

  @override
  String packsDownloadStarted(String name) {
    return 'आपका ब्राउज़र $name डाउनलोड कर रहा है। पूरा होने पर पैक फ़ाइल इंपोर्ट करें पर टैप करें।';
  }

  @override
  String get packsNoBrowser =>
      'कोई ब्राउज़र यह लिंक नहीं खोल सकता। इसके बजाय रिलीज़ पेज का लिंक कॉपी करें।';

  @override
  String get packsImportCheckedBody =>
      'डाउनलोड की गई .boopack फ़ाइल चुनें। इसे इसी फ़ोन पर जाँचा जाता है, फिर इंस्टॉल किया जाता है।';

  @override
  String get packsAllInstalled => 'सभी प्रकाशित पैक इंस्टॉल हैं।';

  @override
  String get packsLinkCopied => 'लिंक कॉपी हो गया। इसे दूसरे डिवाइस पर खोलें।';

  @override
  String get packsPlayTitle => 'Google Play से प्राप्त करें';

  @override
  String get packsPlayNote =>
      'ये पैक Google Play डाउनलोड करता है, BooBoard नहीं। BooBoard खुद कभी नेटवर्क का इस्तेमाल नहीं करता।';

  @override
  String get packsGet => 'प्राप्त करें';

  @override
  String get packsStatusNotRequested => 'अभी डाउनलोड नहीं हुआ';

  @override
  String get packsStatusWaiting => 'Wi-Fi या मोबाइल डेटा का इंतज़ार';

  @override
  String get packsStatusDownloading => 'Google Play से डाउनलोड हो रहा है';

  @override
  String get packsStatusInstalling => 'जाँच और इंस्टॉल हो रहा है';

  @override
  String get packsStatusFailed =>
      'Google Play इसे पहुँचा नहीं सका। फिर से कोशिश करें।';

  @override
  String packsOfferMeta(Object size, Object status) {
    return '$size · $status';
  }

  @override
  String get packsVerifyTitle => 'इंस्टॉल किए गए पैक जाँचें';

  @override
  String get packsVerifyBody =>
      'हर इंस्टॉल किए गए पैक की हर फ़ाइल को उसकी हस्ताक्षरित सूची से मिलाता है। कुछ नहीं बदला जाता।';

  @override
  String packsVerifyOk(Object count) {
    return '$count इंस्टॉल किए गए पैक जाँचे गए। सभी फ़ाइलें मेल खाती हैं।';
  }

  @override
  String packsVerifyDamaged(Object count) {
    return '$count इंस्टॉल किए गए पैक की फ़ाइलें खराब या गायब हैं। उन्हें हटाकर फिर से आयात करें।';
  }

  @override
  String get packsVerifyUnavailable =>
      'BooBoard के इस संस्करण में इंस्टॉल किए गए पैक की जाँच उपलब्ध नहीं है।';

  @override
  String get packsVerifyFailed =>
      'BooBoard पैक की जाँच नहीं कर सका। कुछ नहीं बदला गया।';

  @override
  String packsFreeSpace(Object size) {
    return 'इस फ़ोन पर $size खाली है।';
  }

  @override
  String get packsNothingStored => 'अभी कुछ सहेजा नहीं गया है।';

  @override
  String packsInstalledUse(String size) {
    return 'इंस्टॉल पैक इस फ़ोन पर $size लेते हैं।';
  }

  @override
  String get packErrorBadSignature =>
      'यह पैक BooBoard के लिए हस्ताक्षरित नहीं है, इसलिए कुछ भी इंस्टॉल नहीं हुआ।';

  @override
  String get packErrorBadFormat =>
      'यह फ़ाइल BooBoard पैक नहीं है। कुछ भी इंस्टॉल नहीं हुआ।';

  @override
  String get packErrorTooLarge =>
      'यह पैक इस फ़ोन पर इंस्टॉल करने के लिए बहुत बड़ा है।';

  @override
  String get packErrorVersion => 'इस पैक के लिए BooBoard का नया संस्करण चाहिए।';

  @override
  String get packErrorNoSpace =>
      'इस पैक को इंस्टॉल करने के लिए पर्याप्त खाली जगह नहीं है।';

  @override
  String get packErrorGeneric =>
      'पैक इंस्टॉल नहीं हो सका। कुछ भी नहीं बदला गया।';

  @override
  String get translateDefaultPair => 'डिफ़ॉल्ट भाषा जोड़ी';

  @override
  String translatePairName(String from, String to) {
    return '$from → $to';
  }

  @override
  String get translateOffline => 'ऑफ़लाइन अनुवाद';

  @override
  String get translateOfflineBody =>
      'कीबोर्ड में टाइप करते समय और किसी भी ऐप में चुने गए टेक्स्ट का अनुवाद करता है।';

  @override
  String get translateDefaultPairTile => 'डिफ़ॉल्ट जोड़ी';

  @override
  String get translatePackInstalled => 'पैक इंस्टॉल है';

  @override
  String get translatePackNotInstalled =>
      'पैक इंस्टॉल नहीं है। इसे मॉडल पैक में पाएँ।';

  @override
  String get translateInstalled => 'इंस्टॉल की गई दिशाएँ';

  @override
  String get translateInstalledBody =>
      'हर दिशा एक पैक है, जैसे अंग्रेज़ी → स्पेनिश।';

  @override
  String translatePackMeta(String license, String size) {
    return '$size · $license';
  }

  @override
  String get translateModelPacksBody => 'अनुवाद पैक इंस्टॉल या हटाएँ';

  @override
  String get translateRunsOnPhone =>
      'अनुवाद इसी फ़ोन पर होता है। आप जो अनुवाद करते हैं, वह सहेजा नहीं जाता।';

  @override
  String get privacyUnlockReason =>
      'अपनी सेटिंग और डेटा देखने के लिए BooBoard अनलॉक करें';

  @override
  String get privacyLockUnavailable =>
      'डिवाइस लॉक अभी उपलब्ध नहीं है। थोड़ी देर बाद फिर कोशिश करें।';

  @override
  String get privacyLockedTitle => 'BooBoard लॉक है';

  @override
  String get privacyLockedBody =>
      'जारी रखने के लिए अपनी फ़िंगरप्रिंट या डिवाइस PIN से अनलॉक करें।';

  @override
  String get privacyUnlock => 'अनलॉक करें';

  @override
  String backupSaved(String size) {
    return 'बैकअप सहेजा गया ($size)। अपना पासफ़्रेज़ सुरक्षित रखें।';
  }

  @override
  String get backupUnlockRetrySaved =>
      'फ़ोन अनलॉक करके फिर कोशिश करें। कुछ सहेजा नहीं गया।';

  @override
  String get backupSaveFailed =>
      'बैकअप सहेजा नहीं जा सका। कुछ भी नहीं बदला गया।';

  @override
  String get backupCheckFailed =>
      'सहेजी गई फ़ाइल की जाँच नहीं हो सकी, वह खराब हो सकती है। बैकअप को नई फ़ाइल के रूप में फिर से सहेजें।';

  @override
  String get backupWrongPassphrase =>
      'पासफ़्रेज़ गलत है, या फ़ाइल खराब है। कुछ भी नहीं बदला गया।';

  @override
  String get backupInvalidFile =>
      'यह फ़ाइल वैध BooBoard बैकअप नहीं है। कुछ भी नहीं बदला गया।';

  @override
  String get backupTooLarge => 'यह फ़ाइल BooBoard बैकअप के लिए बहुत बड़ी है।';

  @override
  String get backupNewerVersion =>
      'यह बैकअप BooBoard के नए संस्करण से बना है। पुनर्स्थापित करने के लिए BooBoard अपडेट करें।';

  @override
  String get backupBusy => 'पहले दूसरी फ़ाइल विंडो बंद करें, फिर कोशिश करें।';

  @override
  String get backupOpenFailed => 'बैकअप नहीं खुल सका। कुछ भी नहीं बदला गया।';

  @override
  String get backupEmpty => 'इस बैकअप में कुछ नहीं है।';

  @override
  String get backupRestoreTitle => 'बैकअप पुनर्स्थापित करें';

  @override
  String backupMadeBy(String date, String version) {
    return '$date को BooBoard $version से बनाया गया।';
  }

  @override
  String get backupMerge => 'मिलाएँ';

  @override
  String get backupMergeBody =>
      'इस फ़ोन पर जो है उसे रखें और बैकअप में जो है उसे जोड़ें।';

  @override
  String get backupReplace => 'बदलें';

  @override
  String get backupReplaceBody =>
      'चुने गए भागों को बैकअप जैसा बनाएँ। यहाँ का डेटा पहले मिटा दिया जाता है।';

  @override
  String get commonContinue => 'जारी रखें';

  @override
  String get backupReplaceTitle => 'इस फ़ोन का डेटा बदलें?';

  @override
  String get backupReplaceConfirm =>
      'इस फ़ोन पर चुने गए भाग मिटाकर बदल दिए जाएँगे। इसे वापस नहीं लाया जा सकता।';

  @override
  String get backupPrivacyChangesTitle =>
      'यह बैकअप आपकी गोपनीयता सेटिंग बदलता है';

  @override
  String get backupPrivacyChangesBody =>
      'सेटिंग बहाल करने पर इस फ़ोन की ये गोपनीयता सेटिंग बदल जाएँगी। आगे बढ़ने से पहले इन्हें देख लें।';

  @override
  String backupPrivacyChangeLine(String setting, String from, String to) {
    return '$setting: $from → $to';
  }

  @override
  String get backupStateOn => 'चालू';

  @override
  String backupAppsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ऐप',
      one: '1 ऐप',
    );
    return '$_temp0';
  }

  @override
  String get backupRestoreAndChange => 'बहाल करें और बदलें';

  @override
  String get backupUnlockRetryChanged =>
      'फ़ोन अनलॉक करके फिर कोशिश करें। कुछ भी नहीं बदला गया।';

  @override
  String get backupRestoreFailed =>
      'BooBoard पुनर्स्थापना पूरी नहीं कर सका। कुछ डेटा शायद नहीं लिखा गया।';

  @override
  String get restoreNothingNew => 'कुछ नया पुनर्स्थापित नहीं हुआ।';

  @override
  String restoreSummary(String items) {
    return 'पुनर्स्थापित: $items।';
  }

  @override
  String restoreSummarySkipped(String added, String skipped) {
    return '$added छोड़ा गया: $skipped।';
  }

  @override
  String restoreLearnedFor(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count भाषाएँ',
      one: '1 भाषा',
    );
    return '$_temp0 के लिए सीखे गए शब्द';
  }

  @override
  String countFiles(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count फ़ाइलें',
      one: '1 फ़ाइल',
    );
    return '$_temp0';
  }

  @override
  String countWords(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count शब्द',
      one: '1 शब्द',
    );
    return '$_temp0';
  }

  @override
  String countLanguages(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count भाषाएँ',
      one: '1 भाषा',
    );
    return '$_temp0';
  }

  @override
  String countShortcuts(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count शॉर्टकट',
      one: '1 शॉर्टकट',
    );
    return '$_temp0';
  }

  @override
  String countClipboardItems(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count क्लिपबोर्ड आइटम',
      one: '1 क्लिपबोर्ड आइटम',
    );
    return '$_temp0';
  }

  @override
  String countThemeFiles(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count थीम फ़ाइलें',
      one: '1 थीम फ़ाइल',
    );
    return '$_temp0';
  }

  @override
  String countPinnedItems(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count पिन किए आइटम',
      one: '1 पिन किया आइटम',
    );
    return '$_temp0';
  }

  @override
  String countPacks(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count पैक',
      one: '1 पैक',
    );
    return '$_temp0';
  }

  @override
  String countBlockedWords(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count अवरुद्ध शब्द',
      one: '1 अवरुद्ध शब्द',
    );
    return '$_temp0';
  }

  @override
  String countTimes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count बार',
      one: '1 बार',
    );
    return '$_temp0';
  }

  @override
  String timeMinutesAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count मिनट पहले',
      one: '1 मिनट पहले',
    );
    return '$_temp0';
  }

  @override
  String timeHoursAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count घंटे पहले',
      one: '1 घंटे पहले',
    );
    return '$_temp0';
  }

  @override
  String timeDaysAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count दिन पहले',
      one: '1 दिन पहले',
    );
    return '$_temp0';
  }

  @override
  String get timeJustNow => 'अभी-अभी';

  @override
  String get languagePortuguese => 'पुर्तगाली';

  @override
  String packMeta(String languages, String license, String size) {
    return '$languages · $size · $license';
  }

  @override
  String privacyLearnedWordsTitle(String language) {
    return 'सीखे गए शब्द ($language)';
  }

  @override
  String privacyClearLanguageTitle(String language) {
    return '$language के शब्द मिटाएँ?';
  }

  @override
  String get privacyClearLanguageBody =>
      'इस भाषा में सीखे गए सभी शब्द और अवरुद्ध शब्द मिट जाएँगे। इसे वापस नहीं लाया जा सकता।';

  @override
  String get privacyClear => 'मिटाएँ';

  @override
  String get privacySaveFailed => 'बदलाव सहेजा नहीं जा सका। फिर से कोशिश करें।';

  @override
  String get privacyCouldNotReadWords => 'BooBoard ये शब्द नहीं पढ़ सका।';

  @override
  String get privacyCannotReadWordsNow =>
      'BooBoard अभी ये शब्द नहीं पढ़ सकता। फ़ोन अनलॉक करके फिर कोशिश करें।';

  @override
  String get privacyNoWordsLanguage =>
      'इस भाषा में अभी कोई शब्द नहीं सीखा गया। आपके कई बार टाइप करने के बाद BooBoard कोई शब्द सीखता है।';

  @override
  String privacyBlockedWordsTooltip(num count) {
    return 'अवरुद्ध शब्द ($count)';
  }

  @override
  String get privacySortTooltip => 'क्रमबद्ध करें';

  @override
  String get privacySortMostUsed => 'सबसे ज़्यादा इस्तेमाल किए गए पहले';

  @override
  String get privacySortAZ => 'A से Z';

  @override
  String get privacyMoreTooltip => 'और';

  @override
  String get privacyClearThisLanguage => 'यह भाषा मिटाएँ';

  @override
  String get privacySearchWords => 'शब्द खोजें';

  @override
  String privacyWordsSummary(String blocked, String words) {
    return '$words · $blocked';
  }

  @override
  String get privacyNoWordsYet => 'अभी कोई शब्द नहीं है।';

  @override
  String privacyNoWordsMatch(String query) {
    return '\"$query\" से मेल खाने वाला कोई शब्द नहीं है।';
  }

  @override
  String get privacyNeverSuggested => 'कभी सुझाए नहीं गए';

  @override
  String get privacyBlockedExplain =>
      'BooBoard इन शब्दों के सुझाव या सुधार नहीं करेगा।';

  @override
  String get privacyNoBlockedWords => 'कोई अवरुद्ध शब्द नहीं।';

  @override
  String get privacyAllowAgain => 'फिर से अनुमति दें';

  @override
  String privacyWordLastUsed(int count, String when) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count बार टाइप किया',
      one: 'एक बार टाइप किया',
    );
    return '$_temp0 · आखिरी बार $when';
  }

  @override
  String privacyWordNotYetSuggested(String when) {
    return 'अब तक एक बार टाइप किया, अभी सुझाया नहीं गया · आखिरी बार $when';
  }

  @override
  String get privacyToday => 'आज';

  @override
  String get privacyYesterday => 'कल';

  @override
  String privacyActionsFor(String word) {
    return '$word के लिए कार्रवाइयाँ';
  }

  @override
  String get privacyForgetWord => 'यह शब्द भूल जाएँ';

  @override
  String get privacyNeverSuggestWord => 'यह शब्द कभी न सुझाएँ';

  @override
  String get privacyTryAgain => 'फिर से कोशिश करें';

  @override
  String get privacyCenterLoadFailed =>
      'BooBoard अपना गोपनीयता डेटा नहीं पढ़ सका। बाद में फिर कोशिश करें।';

  @override
  String get privacyDevBuildNetwork =>
      'इस बिल्ड में इंटरनेट की अनुमति माँगी गई है। BooBoard को ऐसा कभी नहीं करना चाहिए। कृपया इसकी रिपोर्ट करें।';

  @override
  String get privacyNoInternetPermission =>
      'BooBoard के पास इंटरनेट की अनुमति नहीं है। यह कुछ भी नहीं भेज सकता।';

  @override
  String get privacyDevBuildNote =>
      'यह एक डेवलपमेंट बिल्ड है। इसकी नेटवर्क अनुमति केवल डेवलपमेंट टूल्स के लिए है।';

  @override
  String get privacyDevBuildShort =>
      'डेवलपमेंट बिल्ड। BooBoard के पास फिर भी इंटरनेट की अनुमति नहीं है।';

  @override
  String privacyStorageSize(String size, String when) {
    return '$size · $when बदला गया';
  }

  @override
  String get privacyCustomThemes => 'कस्टम थीम';

  @override
  String get privacyNoPacks =>
      'कोई इंस्टॉल नहीं। वॉइस और अनुवाद पैक यहाँ दिखते हैं।';

  @override
  String privacyPacksSize(int count, String size) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count पैक',
      one: '1 पैक',
    );
    return '$_temp0 · $size';
  }

  @override
  String get privacyWhatBooBoardStores => 'BooBoard क्या सहेजता है';

  @override
  String get privacyShowsSizesOnly =>
      'BooBoard यहाँ केवल आकार दिखाता है, अंदर की चीज़ें नहीं। आकार में पिछली सहेजी गई प्रति शामिल है, जो सहेजना रुकने पर आपके डेटा को सुरक्षित रखती है।';

  @override
  String get privacyTypingPrivacy => 'टाइपिंग गोपनीयता';

  @override
  String get privacyLearnNewWords => 'नए शब्द सीखें';

  @override
  String get privacyLearnNewWordsBody =>
      'आप जो टाइप करते हैं उससे शब्द और वाक्यांश सीखता है। पासवर्ड फ़ील्ड या इनकॉग्निटो में कभी नहीं।';

  @override
  String get privacyIncognito => 'इनकॉग्निटो';

  @override
  String get privacyIncognitoBody =>
      'चालू होने पर कुछ भी नहीं सीखता या याद रखता। ब्राउज़र की इनकॉग्निटो टैब इसे अपने-आप चालू कर देते हैं।';

  @override
  String get privacyHideScreenshots => 'स्क्रीनशॉट से छिपाएँ';

  @override
  String get privacyHideScreenshotsBody =>
      'हर ऐप में कीबोर्ड के स्क्रीनशॉट और स्क्रीन रिकॉर्डिंग रोकता है। पासवर्ड फ़ील्ड हमेशा छिपे रहते हैं।';

  @override
  String get privacyAutoOffApps => 'इन ऐप्स में अपने-आप बंद';

  @override
  String get privacyAutoOffAppsBody =>
      'BooBoard यह सूची भरने के लिए केवल ऐप के नाम रखता है। ये एन्क्रिप्टेड रहते हैं, इनकॉग्निटो में कभी दर्ज नहीं होते, और आप इन्हें नीचे मिटा सकते हैं।';

  @override
  String get privacyNoAppsYet => 'अभी कोई ऐप नहीं';

  @override
  String get privacyNoAppsYetBody =>
      'जिन ऐप्स में आप टाइप करेंगे, वे यहाँ दिखेंगे।';

  @override
  String get privacyAlwaysIncognitoApps => 'हमेशा इनकॉग्निटो वाले ऐप्स';

  @override
  String get privacyPersonalShortcuts => 'निजी शॉर्टकट';

  @override
  String get privacyOfferShortcuts => 'शॉर्टकट सुझाएँ';

  @override
  String get privacyOfferShortcutsBody =>
      'आपके छोटे रूप, जैसे \"omw\", पहले सुझाव के रूप में दिखाता है।';

  @override
  String get privacyEditShortcuts => 'शॉर्टकट संपादित करें';

  @override
  String get privacyNoShortcutsYet => 'अभी कोई नहीं';

  @override
  String get privacyLearnedAndClipboard => 'सीखे गए शब्द और क्लिपबोर्ड';

  @override
  String get privacyNoWordsLearnedYet => 'अभी कोई शब्द नहीं सीखा गया';

  @override
  String get privacyWordsLearnedBody =>
      'आप जो शब्द टाइप करते हैं, वे यहाँ तब सीखे जाते हैं जब BooBoard उन्हें कुछ बार देख लेता है।';

  @override
  String privacyReviewWords(String when) {
    return 'शब्द देखें, हटाएँ या अवरुद्ध करें · $when';
  }

  @override
  String get privacyClipboardHistoryEmpty =>
      'इतिहास खाली है। क्लिपबोर्ड की सेटिंग पैनल में बदलें।';

  @override
  String privacyClipboardInHistory(String size) {
    return 'इतिहास में $size। क्लिपबोर्ड की सेटिंग पैनल में बदलें।';
  }

  @override
  String get privacyAppLock => 'ऐप लॉक';

  @override
  String get privacyLockBooBoard => 'BooBoard लॉक करें';

  @override
  String get privacyLockBooBoardBody =>
      'ऐप खुलने पर, या पृष्ठभूमि में जाने के बाद, फ़िंगरप्रिंट या डिवाइस PIN माँगता है।';

  @override
  String get privacyLockAfter => 'इसके बाद लॉक करें';

  @override
  String get privacySetScreenLockFirst => 'पहले स्क्रीन लॉक सेट करें';

  @override
  String get privacySetScreenLockBody =>
      'ऐप लॉक आपके फ़िंगरप्रिंट या डिवाइस PIN का उपयोग करता है। Android की सुरक्षा सेटिंग में PIN, पैटर्न या पासवर्ड सेट करें, फिर लौटें।';

  @override
  String get privacyTurnOnAppLockReason => 'BooBoard के लिए ऐप लॉक चालू करें';

  @override
  String get privacyNotAvailable => 'अभी उपलब्ध नहीं';

  @override
  String get privacyNotAvailableBody =>
      'डिवाइस लॉक इस्तेमाल नहीं हो सका। ऐप लॉक बंद रहेगा।';

  @override
  String get privacyBackupTitle => 'बैकअप';

  @override
  String get privacyBackupRestore => 'बैकअप और पुनर्स्थापना';

  @override
  String get privacyBackupRestoreBody =>
      'एक एन्क्रिप्टेड .boobackup फ़ाइल जिसे आप रखते हैं। कौन सी चीज़ें इसमें हों, यह आप चुनते हैं।';

  @override
  String get privacyDeleteData => 'डेटा मिटाएँ';

  @override
  String get privacyEraseEverything => 'सब कुछ मिटाएँ';

  @override
  String get privacyEraseEverythingBody =>
      'ऊपर की सभी श्रेणियाँ, आपकी कस्टम थीम, और उन्हें सुरक्षित रखने वाली कुंजी।';

  @override
  String privacyDeleteTitle(String category) {
    return '$category मिटाएँ?';
  }

  @override
  String get privacyEraseTitle => 'सब कुछ मिटाएँ?';

  @override
  String get privacyWillDelete => 'यह स्थायी रूप से मिटा देगा:';

  @override
  String get privacyResetSettings => 'सभी सेटिंग्स भी डिफ़ॉल्ट पर रीसेट करें';

  @override
  String get privacyCannotBeUndone => 'इसे वापस नहीं लाया जा सकता।';

  @override
  String get privacyDeleted => 'मिटाया गया।';

  @override
  String get privacyDeleteFailed =>
      'BooBoard सब कुछ नहीं मिटा सका। फिर से कोशिश करें।';

  @override
  String get privacyOk => 'ठीक है';

  @override
  String get backupMakeTitle => 'बैकअप बनाएँ';

  @override
  String get backupIncludeImages => 'पृष्ठभूमि की छवियाँ शामिल करें';

  @override
  String get backupPhotosLarger => 'फ़ोटो से फ़ाइल काफ़ी बड़ी हो जाती है।';

  @override
  String get backupCreateButton => 'एन्क्रिप्टेड बैकअप बनाएँ';

  @override
  String get backupRestoreSection => 'पुनर्स्थापित करें';

  @override
  String get backupRestoreFromFile => 'बैकअप फ़ाइल से पुनर्स्थापित करें';

  @override
  String get backupRestoreFromFileBody =>
      'एक .boobackup फ़ाइल खोलें, उसमें क्या है देखें, फिर मिलाएँ या बदलें।';

  @override
  String get backupChoosePassphrase => 'पासफ़्रेज़ चुनें';

  @override
  String get backupEnterPassphrase => 'पासफ़्रेज़ दर्ज करें';

  @override
  String get backupWriteItDown =>
      'इसे किसी सुरक्षित जगह लिख लें। खोया हुआ पासफ़्रेज़ वापस नहीं मिल सकता।';

  @override
  String get backupPassphrase => 'पासफ़्रेज़';

  @override
  String get backupTypeAgain => 'फिर से लिखें';

  @override
  String get backupMismatch => 'पासफ़्रेज़ मेल नहीं खाते';

  @override
  String backupStrength(String strength) {
    return 'पासफ़्रेज़ की मज़बूती: $strength';
  }

  @override
  String get strengthTooShort => 'कम से कम 8 अक्षर इस्तेमाल करें';

  @override
  String get strengthWeak => 'कमज़ोर';

  @override
  String get strengthFair => 'ठीक-ठाक';

  @override
  String get strengthGood => 'अच्छी';

  @override
  String get strengthStrong => 'मज़बूत';

  @override
  String get backupOpen => 'खोलें';

  @override
  String get backupNothingYet => 'अभी कुछ नहीं';

  @override
  String get backupSettingsSummary =>
      'थीम, भाषाएँ, टाइपिंग और गोपनीयता की पसंद';

  @override
  String backupLearnedSummary(String languages, String words) {
    return '$languages में $words';
  }

  @override
  String backupPinnedOff(String items) {
    return '$items। इसे चालू करने तक बंद रहता है।';
  }

  @override
  String backupAlreadyHere(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count शॉर्टकट पहले से हैं',
      one: '1 शॉर्टकट पहले से है',
    );
    return '$_temp0';
  }

  @override
  String backupThemesAlreadyHere(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count थीम फ़ाइलें पहले से हैं',
      one: '1 थीम फ़ाइल पहले से है',
    );
    return '$_temp0';
  }

  @override
  String get backupClipboardKept => 'क्लिपबोर्ड छोड़ा गया (अज्ञात लेआउट)';

  @override
  String get backupEmojiKept => 'हाल के इमोजी रखे गए';

  @override
  String get backupSettingsApplied => 'सेटिंग्स';

  @override
  String backupLearnedAdded(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count भाषाएँ',
      one: '1 भाषा',
    );
    return '$_temp0 के लिए सीखे गए शब्द';
  }

  @override
  String shortcutDeleteTitle(String trigger) {
    return '\"$trigger\" हटाएँ?';
  }

  @override
  String get shortcutDeleteBody =>
      'इससे शॉर्टकट हट जाएगा। इसे वापस नहीं लाया जा सकता।';

  @override
  String get shortcutAdd => 'शॉर्टकट जोड़ें';

  @override
  String get shortcutSearch => 'शॉर्टकट खोजें';

  @override
  String get shortcutNoMatch => 'आपकी खोज से कोई शॉर्टकट मेल नहीं खाता।';

  @override
  String shortcutDeleteTooltip(String trigger) {
    return '$trigger हटाएँ';
  }

  @override
  String get shortcutNoneYet => 'अभी कोई शॉर्टकट नहीं';

  @override
  String get shortcutExplain =>
      'शॉर्टकट एक छोटे रूप को लंबे टेक्स्ट में बदलता है। उदाहरण:';

  @override
  String shortcutExamples(String first, String second) {
    return '$first\n$second';
  }

  @override
  String get shortcutEncrypted =>
      'शॉर्टकट इसी फ़ोन पर एन्क्रिप्टेड रहते हैं, आपके सीखे गए शब्दों की तरह।';

  @override
  String get shortcutNew => 'नया शॉर्टकट';

  @override
  String get shortcutEdit => 'शॉर्टकट संपादित करें';

  @override
  String get shortcutShortForm => 'छोटा रूप';

  @override
  String get shortcutExpandsTo => 'इसमें विस्तारित होता है';

  @override
  String get privacyMascotLabel => 'BooBoard गोपनीयता मैस्कॉट';

  @override
  String get privacyStoredEmoji => 'हाल के इमोजी';

  @override
  String get privacyStoredApps => 'ऐप्स की सूची';

  @override
  String get privacyStoredOther => 'अन्य सहेजा गया डेटा';

  @override
  String privacyUnitBytes(num count) {
    return '$count B';
  }

  @override
  String privacyUnitKilobytes(num count) {
    return '$count KB';
  }

  @override
  String privacyUnitMegabytes(num count) {
    return '$count MB';
  }

  @override
  String get shortcutProblemEmptyTrigger =>
      'वह छोटा रूप लिखें जिसे विस्तारित करना है।';

  @override
  String shortcutProblemTriggerTooLong(num count) {
    return 'छोटे रूप में अधिकतम $count अक्षर हो सकते हैं।';
  }

  @override
  String get shortcutProblemTriggerCharacters =>
      'छोटे रूप में केवल अक्षर, अंक और एपोस्ट्रॉफ़ इस्तेमाल करें।';

  @override
  String get shortcutProblemEmptyExpansion =>
      'बताएँ कि छोटा रूप किसमें विस्तारित हो।';

  @override
  String shortcutProblemExpansionTooLong(num count) {
    return 'विस्तार में अधिकतम $count अक्षर हो सकते हैं।';
  }

  @override
  String get shortcutProblemDuplicate => 'इस छोटे रूप वाला शॉर्टकट पहले से है।';

  @override
  String shortcutProblemTooMany(num count) {
    return 'आप अधिकतम $count शॉर्टकट रख सकते हैं।';
  }

  @override
  String get onboardingWelcomeTitle => 'नमस्ते, मैं *Boo* हूँ।';

  @override
  String get onboardingWelcomeBody =>
      'मैं एक कीबोर्ड हूँ जो कभी ऑनलाइन नहीं जाता। आप जो लिखते हैं, वह इसी फ़ोन पर ताले में रहता है।';

  @override
  String get onboardingWelcomeStart => 'सेट अप करें';

  @override
  String get onboardingMascotLabel => 'Boo, BooBoard का भूत';

  @override
  String get onboardingFactNoInternet => 'इंटरनेट की अनुमति नहीं';

  @override
  String get onboardingFactOpenSource => 'ओपन सोर्स';

  @override
  String get onboardingFactOpenSourceBody => 'कोई भी कोड पढ़कर जाँच सकता है।';

  @override
  String get onboardingDemoKeyboards => 'कीबोर्ड ऐप्लिकेशन';

  @override
  String get onboardingDemoOtherKeyboard => 'दूसरा कीबोर्ड';

  @override
  String get onboardingDemoAttention => 'ध्यान दें';

  @override
  String get onboardingDemoAttentionBody =>
      'यह कीबोर्ड आपका लिखा सारा टेक्स्ट इकट्ठा कर सकता है…';

  @override
  String get onboardingDemoOk => 'ठीक है';

  @override
  String get onboardingDemoChooseInput => 'इनपुट विधि चुनें';

  @override
  String get onboardingDemoSwitchOn => 'चालू करें';

  @override
  String get onboardingDemoTapOk => 'OK, फिर OK';

  @override
  String get onboardingDemoComeBack => 'वापस आएँ';

  @override
  String get onboardingDemoPick => 'BooBoard चुनें';

  @override
  String get onboardingDemoStartTyping => 'टाइप करना शुरू करें';

  @override
  String get onboardingDemoRebootNote =>
      'ध्यान दें: रीबूट के बाद, फ़ोन अनलॉक करने तक यह ऐप शुरू नहीं हो सकता';

  @override
  String get onboardingDemoChatIn => '7 बजे मिलें?';

  @override
  String get onboardingDemoChatOut => 'आ रहा हूँ';

  @override
  String get onboardingDemoMessage => 'मैसेज';

  @override
  String get onboardingShh => 'श्श';

  @override
  String get onboardingTryMe => 'मुझे आज़माओ';

  @override
  String get onboardingTurnOnTitle => '*BooBoard* चालू करें';

  @override
  String get onboardingTurnOnBody =>
      'Android की कीबोर्ड सूची में इसे चालू करें, फिर वापस आएँ। यह पेज अपने आप पहचान लेता है।';

  @override
  String get onboardingKeyboardOn => 'BooBoard चालू है';

  @override
  String get onboardingKeyboardOff => 'अभी चालू नहीं है';

  @override
  String get onboardingOpenKeyboardSettings => 'कीबोर्ड सेटिंग खोलें';

  @override
  String get onboardingSwitchTitle => 'इसे *अपना* बनाएँ';

  @override
  String get onboardingSwitchBody =>
      'Android की छोटी सूची से BooBoard चुनें। आप कभी भी वापस बदल सकते हैं।';

  @override
  String get onboardingKeyboardIsYours => 'BooBoard आपका कीबोर्ड है';

  @override
  String get onboardingKeyboardNotYours => 'अभी आपका कीबोर्ड नहीं है';

  @override
  String get onboardingTurnOnFirst => 'पहले इसे चालू करें';

  @override
  String get onboardingChooseKeyboard => 'कीबोर्ड चुनें';

  @override
  String get onboardingCheckingPermissions =>
      'ऐप की अनुमतियाँ जाँची जा रही हैं…';

  @override
  String get onboardingDebugInternet =>
      'इस डीबग बिल्ड की इंटरनेट तक पहुँच है। डीबग बिल्ड में यह अनुमति केवल डेवलपमेंट के लिए होती है।';

  @override
  String get onboardingReleaseInternet => 'इस बिल्ड की इंटरनेट तक पहुँच है।';

  @override
  String get onboardingNoInternet =>
      'BooBoard के पास इंटरनेट की अनुमति नहीं है, इसलिए यह कहीं कुछ नहीं भेज सकता।';

  @override
  String get onboardingWarningTitle => 'उस *चेतावनी* के बारे में';

  @override
  String get onboardingWarningBody =>
      'Android यह हर कीबोर्ड के लिए दिखाता है, क्योंकि कोई कीबोर्ड आपका लिखा ऑनलाइन भेज सकता है। BooBoard नहीं भेज सकता।';

  @override
  String get onboardingInternetAccess => 'इंटरनेट पहुँच';

  @override
  String get onboardingEverythingHere => 'इसी फ़ोन पर रहता है';

  @override
  String get onboardingEverythingHereBody =>
      'सीखे गए शब्द, क्लिपबोर्ड और सेटिंग Android Keystore की कुंजी से एन्क्रिप्ट हैं।';

  @override
  String get onboardingLanguagesTitle => 'आपकी *भाषाएँ*';

  @override
  String get onboardingThemeTitle => 'थीम';

  @override
  String get onboardingTryTyping => 'एक वाक्य टाइप करें';

  @override
  String get onboardingTrySwipe => 'एक शब्द स्वाइप करें, अक्षर से अक्षर';

  @override
  String get onboardingTryAccents => 'मात्राओं के लिए अक्षर दबाए रखें';

  @override
  String get onboardingTryTitle => 'इसे *आज़माएँ*';

  @override
  String get onboardingTryField => 'यहाँ कुछ लिखें';

  @override
  String get onboardingAllSetTitle => 'सब *तैयार है।*';

  @override
  String get onboardingAllSetBody =>
      'भाषाएँ, टाइपिंग, थीम और बहुत कुछ जब चाहें सेटिंग में मिलेंगे।';

  @override
  String onboardingStepOf(String step, String total) {
    return 'चरण $step / $total';
  }

  @override
  String get onboardingBack => 'वापस';

  @override
  String get onboardingNext => 'आगे';

  @override
  String get onboardingDone => 'पूर्ण';

  @override
  String get onboardingSearchLanguages => 'भाषाएँ खोजें';

  @override
  String onboardingSelected(String languages) {
    return 'चुनी गई: $languages';
  }

  @override
  String get onboardingNoLanguageMatch => 'इस खोज से कोई भाषा मेल नहीं खाती।';

  @override
  String get themeCreate => 'थीम बनाएँ';

  @override
  String themeSelectedLabel(String name) {
    return '$name, चुना गया';
  }

  @override
  String themeCardOptions(String name) {
    return '$name के विकल्प';
  }

  @override
  String get themeEdit => 'बदलें';

  @override
  String get themeDuplicate => 'डुप्लिकेट करें';

  @override
  String get themeRename => 'नाम बदलें';

  @override
  String get themeDeleteAction => 'हटाएँ';

  @override
  String get themeTryTyping => 'टाइप करके देखें';

  @override
  String get themeTryLabel => 'थीम आज़माने के लिए यहाँ टाइप करें';

  @override
  String get themeTryHelper =>
      'जब BooBoard चुना होता है, तब कीबोर्ड यहाँ दिखता है।';

  @override
  String get themeRenameTitle => 'थीम का नाम बदलें';

  @override
  String get themeNameField => 'नाम';

  @override
  String get themeEditTitle => 'थीम संपादित करें';

  @override
  String get themeNewTitle => 'नई थीम';

  @override
  String get themeEditorTitle => 'थीम';

  @override
  String get themeOpenFailed => 'यह थीम नहीं खुल सकी।';

  @override
  String get themeSaveFailed => 'थीम सहेजी नहीं जा सकी।';

  @override
  String get themePhotoPickerFailed => 'फ़ोटो चुनने वाला टूल नहीं खुल सका।';

  @override
  String get themeDiscardTitle => 'बदलाव छोड़ें?';

  @override
  String get themeDiscardBody => 'इस थीम में आपके बदलाव खो जाएँगे।';

  @override
  String get themeKeepEditing => 'संपादन जारी रखें';

  @override
  String get themeDiscard => 'छोड़ें';

  @override
  String get themeSave => 'सहेजें';

  @override
  String get themeNameRequired => 'नाम ज़रूरी है';

  @override
  String get themeNameLabel => 'थीम का नाम';

  @override
  String get themeDefaultName => 'मेरी थीम';

  @override
  String get themeSectionName => 'नाम';

  @override
  String get themeSectionLook => 'रूप';

  @override
  String get themeDarkMode => 'डार्क मोड';

  @override
  String get themeChoiceSystem => 'सिस्टम';

  @override
  String get themeChoiceLight => 'हल्का';

  @override
  String get themeChoiceDark => 'गहरा';

  @override
  String get themePureBlack => 'पूरा काला';

  @override
  String get themePureBlackBody => 'काली पृष्ठभूमि';

  @override
  String get themePureBlackOnlyDark => 'केवल डार्क मोड में';

  @override
  String get themeGalleryPureBlackDark => 'डार्क मोड में काली पृष्ठभूमि';

  @override
  String get themeContrast => 'कंट्रास्ट';

  @override
  String get themeChoiceStandard => 'मानक';

  @override
  String get themeChoiceMedium => 'मध्यम';

  @override
  String get themeChoiceHigh => 'उच्च';

  @override
  String get themeKeyboardHeight => 'कीबोर्ड की ऊँचाई';

  @override
  String get themeSectionColours => 'रंग';

  @override
  String get themeSource => 'स्रोत';

  @override
  String get themeSourceWallpaper => 'वॉलपेपर';

  @override
  String get themeSourceSeed => 'सीड रंग';

  @override
  String get themeSourcePerRole => 'भूमिका के अनुसार';

  @override
  String get themeWallpaperNeedsAndroid12 =>
      'वॉलपेपर रंगों के लिए Android 12 या नया संस्करण चाहिए।';

  @override
  String get themeSeedColour => 'सीड रंग';

  @override
  String get themeScheme => 'स्कीम';

  @override
  String get themeColourRoles => 'रंग भूमिकाएँ';

  @override
  String themeEditingColours(String mode) {
    String _temp0 = intl.Intl.selectLogic(mode, {
      'dark': 'गहरे रंग संपादित हो रहे हैं',
      'other': 'हल्के रंग संपादित हो रहे हैं',
    });
    return '$_temp0';
  }

  @override
  String get themeResetRoles => 'सभी भूमिकाएँ रीसेट करें';

  @override
  String get themeKeys => 'कुंजियाँ';

  @override
  String get themeShape => 'आकार';

  @override
  String get themeShapePill => 'पिल';

  @override
  String get themeShapeRounded => 'गोल';

  @override
  String get themeShapeSquare => 'वर्गाकार';

  @override
  String get themeKeyBorders => 'कुंजी की सीमाएँ';

  @override
  String get themeBorderWidth => 'सीमा की चौड़ाई';

  @override
  String get themeKeyGap => 'कुंजियों के बीच की जगह';

  @override
  String get themeFontWeight => 'फ़ॉन्ट वज़न';

  @override
  String get themeFontSize => 'फ़ॉन्ट आकार';

  @override
  String get themeHintCharacters => 'संकेत अक्षर';

  @override
  String get themeHintCharactersBody => 'दबाए रखने पर छोटे अक्षर';

  @override
  String get themeBackground => 'पृष्ठभूमि';

  @override
  String get themeBackgroundType => 'प्रकार';

  @override
  String get themeTypeSolid => 'ठोस';

  @override
  String get themeTypeGradient => 'ग्रेडिएंट';

  @override
  String get themeTypePhoto => 'फ़ोटो';

  @override
  String get themeNoPhotoYet =>
      'अभी कोई फ़ोटो नहीं है। कीबोर्ड के लिए उसे काटने हेतु एक चुनें।';

  @override
  String get themeChoosePhoto => 'फ़ोटो चुनें';

  @override
  String get themeEditCrop => 'क्रॉप और ब्लर संपादित करें';

  @override
  String get themeDim => 'धुंधलापन';

  @override
  String get themeSectionPopups => 'पॉपअप और पथ';

  @override
  String get themeSolidPopups => 'ठोस पॉपअप';

  @override
  String get themeSolidPopupsBodyWallpaper => 'वॉलपेपर रंगों के साथ नहीं';

  @override
  String get themeSolidPopupsBodyPrimary => 'मुख्य रंग में पॉपअप';

  @override
  String get themeSwipeTrail => 'स्वाइप पथ';

  @override
  String get themeTrailWidth => 'पथ की चौड़ाई';

  @override
  String get themeTrailFade => 'पथ धुंधलापन';

  @override
  String get themeTrailInstant => 'तुरंत';

  @override
  String get themeTrailColours => 'पथ के रंग';

  @override
  String get themeTrailStart => 'शुरू';

  @override
  String get themeTrailEnd => 'अंत';

  @override
  String get themeTrailStartTitle => 'पथ की शुरुआत';

  @override
  String get themeTrailEndTitle => 'पथ का अंत';

  @override
  String get themeAutomatic => 'स्वचालित';

  @override
  String get themeSectionMotion => 'गति';

  @override
  String get themeKeyPressAnimation => 'कुंजी दबाने की एनिमेशन';

  @override
  String get themeReduceMotion =>
      'सिस्टम सेटिंग्स में \"एनिमेशन हटाएँ\" चालू है, इसलिए कुंजियाँ एनिमेट नहीं होतीं।';

  @override
  String get themeMotionOff => 'बंद';

  @override
  String get themeMotionSubtle => 'हल्का';

  @override
  String get themeMotionStandard => 'मानक';

  @override
  String get themeMotionBouncy => 'उछलता हुआ';

  @override
  String get themeSchemeTonalSpot => 'टोनल स्पॉट';

  @override
  String get themeSchemeVibrant => 'जीवंत';

  @override
  String get themeSchemeExpressive => 'अभिव्यंजक';

  @override
  String get themeSchemeFidelity => 'निष्ठा';

  @override
  String get themeSchemeContent => 'सामग्री';

  @override
  String get themeSchemeMonochrome => 'एकवर्णी';

  @override
  String get themeSchemeNeutral => 'तटस्थ';

  @override
  String get themeSchemeRainbow => 'इंद्रधनुष';

  @override
  String get themeSchemeFruitSalad => 'फ़्रूट सलाद';

  @override
  String themeCustomColourHex(String hex) {
    return 'कस्टम रंग #$hex';
  }

  @override
  String get themeCustomColour => 'कस्टम रंग';

  @override
  String themeSwatchLabel(String hex, String label) {
    return '$label रंग, #$hex';
  }

  @override
  String themeUseSchemeColour(String label) {
    return '$label के लिए स्कीम का रंग इस्तेमाल करें';
  }

  @override
  String get themeFromScheme => 'स्कीम से';

  @override
  String get themeOverridden => 'सेट';

  @override
  String themeStopLabel(String n) {
    return 'चरण $n';
  }

  @override
  String themePickStopTitle(String n) {
    return 'चरण $n';
  }

  @override
  String get themeAddStop => 'चरण जोड़ें';

  @override
  String get themeRemoveStop => 'चरण हटाएँ';

  @override
  String get themeAngle => 'कोण';

  @override
  String get themeUseSchemeTooltipLabel => 'स्कीम का रंग इस्तेमाल करें';

  @override
  String get themeCropTitle => 'फ़ोटो क्रॉप करें';

  @override
  String get themeUsePhoto => 'फ़ोटो उपयोग करें';

  @override
  String get themeCropSaveFailed => 'फ़ोटो सहेजी नहीं जा सकी।';

  @override
  String get themeCropSemantics =>
      'फ़ोटो क्रॉप। फ़ोटो हिलाने के लिए खींचें, और ज़ूम के लिए पिंच करें या ज़ूम स्लाइडर इस्तेमाल करें।';

  @override
  String get themeCropZoom => 'ज़ूम';

  @override
  String get themeCropBlur => 'ब्लर';

  @override
  String get themeCropBlurOff => 'बंद';

  @override
  String get themeCropNote =>
      'ब्लर चित्र में सहेजा जाता है। धुंधलापन संपादक में तय होता है और तुरंत लागू होता है।';

  @override
  String get themeHexLabel => 'हेक्स';

  @override
  String get themeHexError => 'छह हेक्स अंक इस्तेमाल करें, जैसे F5B700';

  @override
  String get themeHue => 'रंगत';

  @override
  String get themeSaturation => 'संतृप्ति';

  @override
  String get themeBrightness => 'चमक';

  @override
  String get themePickShadeHint => 'कोई शेड चुनें, फिर उपयोग करें दबाएँ।';

  @override
  String get themePickColourUse => 'उपयोग करें';

  @override
  String get themeCopySuffix => 'प्रति';

  @override
  String themeCopyName(String name) {
    return '$name की प्रति';
  }

  @override
  String themeDeleteTitle(String name) {
    return '\"$name\" हटाएँ?';
  }

  @override
  String get themeDeleteSelectedBody =>
      'यह थीम चुनी हुई है। इसके बजाय BooBoard Dynamic इस्तेमाल होगा। इसे वापस नहीं लाया जा सकता।';

  @override
  String get themeDeleteBody => 'इसे वापस नहीं लाया जा सकता।';

  @override
  String get themeDeleteFailed => 'थीम हटाई नहीं जा सकी।';

  @override
  String get themeRenameFailed => 'थीम का नाम नहीं बदला जा सका।';

  @override
  String get themeDuplicateFailed => 'थीम की प्रति नहीं बनाई जा सकी।';

  @override
  String get themeSettingFailed => 'सेटिंग सहेजी नहीं जा सकी।';

  @override
  String get themeSystemColoursUnavailable => 'सिस्टम के रंग उपलब्ध नहीं हैं।';

  @override
  String get themeBooBoardDynamicFollows =>
      'BooBoard Dynamic आपके वॉलपेपर का अनुसरण करता है';

  @override
  String get themeBooBoardDynamicBody =>
      'वॉलपेपर बदलने पर इसके रंग अपडेट होते हैं';

  @override
  String get themeSectionPresets => 'प्रीसेट';

  @override
  String get themeSectionMyThemes => 'मेरी थीम';

  @override
  String get themeSectionTry => 'टाइप करके देखें';

  @override
  String get themeAppearance => 'रूप';

  @override
  String get themesTitle => 'थीम';

  @override
  String privacyThemesSize(int count, String size) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count थीम फ़ाइलें',
      one: '1 थीम फ़ाइल',
    );
    return '$_temp0 · $size';
  }

  @override
  String get backupUnlockToSeeCount => 'गिनती देखने के लिए फ़ोन अनलॉक करें';

  @override
  String get shortcutHelp =>
      'शॉर्टकट एक छोटे रूप को लंबे टेक्स्ट में बदलता है। उदाहरण:\nomw → on my way\naddr → your address';

  @override
  String privacyStoredLearned(String language) {
    return 'सीखे गए शब्द ($language)';
  }

  @override
  String get settingsComingLater => 'बाद के अपडेट में उपलब्ध होगा';

  @override
  String get backupExplainer =>
      'बैकअप एक ही फ़ाइल है, जो आपके चुने पासफ़्रेज़ से एन्क्रिप्ट होती है। केवल वही पासफ़्रेज़ इसे खोलता है। पासफ़्रेज़ भूल गए तो बैकअप कोई भी वापस नहीं ला सकता, BooBoard भी नहीं।';

  @override
  String privacyCategoryLine(String detail, String title) {
    return '$title: $detail';
  }

  @override
  String get shortcutShortFormHint => 'omw';

  @override
  String get shortcutExpansionHint => 'रास्ते में';

  @override
  String get durationMinutes15 => '15 मिनट';

  @override
  String get durationHour => '1 घंटा';

  @override
  String get durationDay => '1 दिन';

  @override
  String get durationWeek => '1 सप्ताह';

  @override
  String get onboardingCloseSetup => 'सेटअप बंद करें';

  @override
  String get packsCouldNotRead => 'BooBoard अपने पैक नहीं पढ़ सका';

  @override
  String packsDeleteTooltip(String name) {
    return '$name हटाएँ';
  }

  @override
  String get privacyNothingStored => 'अभी कुछ सहेजा नहीं गया';

  @override
  String privacyRemoveAppTooltip(String app) {
    return 'सूची से $app हटाएँ';
  }

  @override
  String get chineseTitle => 'चीनी';

  @override
  String get chineseTraditional => 'पारंपरिक अक्षर';

  @override
  String get chineseTraditionalBody =>
      'उम्मीदवार पारंपरिक अक्षरों में दिखाएँ (ताइवान मानक)।';

  @override
  String get chineseFuzzy => 'अनुमानित पिनयिन';

  @override
  String get chineseFuzzyBody =>
      'z और zh, c और ch, s और sh, n और l, an और ang, en और eng, in और ing भी स्वीकार करें।';

  @override
  String get cjkDictionary => 'शब्दकोश';

  @override
  String get chineseClearPhrases => 'सीखे गए वाक्यांश मिटाएँ';

  @override
  String get chineseClearPhrasesBody =>
      'आपके चुने शब्द भूल जाएगा। शब्दकोश बना रहेगा।';

  @override
  String get chineseFooter =>
      'चीनी इसी फ़ोन पर टाइप होती है। सीखे गए वाक्यांश एन्क्रिप्टेड हैं और फ़ोन से बाहर नहीं जाते।';

  @override
  String get chineseClearTitle => 'सीखे गए वाक्यांश मिटाएँ?';

  @override
  String get chineseClearBody =>
      'चीनी के लिए आपके चुने शब्द हटा दिए जाएँगे। इसे पूर्ववत नहीं किया जा सकता।';

  @override
  String get cjkClear => 'मिटाएँ';

  @override
  String get chinesePhrasesCleared => 'सीखे गए वाक्यांश मिटा दिए गए';

  @override
  String get chineseLooking => 'शब्दकोश खोजा जा रहा है';

  @override
  String get chineseDictName => 'चीनी शब्दकोश';

  @override
  String get chinesePackMissing =>
      'इंस्टॉल नहीं है। चीनी टाइपिंग को इसकी ज़रूरत है; इसे मॉडल पैक में इंस्टॉल करें।';

  @override
  String chinesePackInstalled(String license) {
    return 'इंस्टॉल है। $license';
  }

  @override
  String get japaneseTitle => 'जापानी';

  @override
  String get japaneseLayout => 'लेआउट';

  @override
  String get japaneseLayout12 => '12-कुंजी (फ़्लिक)';

  @override
  String get japaneseLayoutRomaji => 'रोमाजी (QWERTY)';

  @override
  String get japaneseTyping => 'टाइपिंग';

  @override
  String get japaneseFlickOnly => 'केवल फ़्लिक';

  @override
  String get japaneseFlickOnlyBody =>
      'मल्टी-टैप नहीं: あ को दो बार टैप करने पर ああ लिखा जाता है, い नहीं';

  @override
  String get japaneseHalfWidth => 'आधी चौड़ाई का स्पेस';

  @override
  String get japaneseHalfWidthBody =>
      'कुछ टाइप न हो रहा हो तो स्पेस सामान्य स्पेस लिखता है। बंद होने पर पूरी चौड़ाई का स्पेस लिखता है।';

  @override
  String get japaneseDictPack => 'शब्दकोश पैक';

  @override
  String get japaneseChecking => 'जाँच हो रही है...';

  @override
  String japaneseInstalled(String name) {
    return '$name इंस्टॉल है। कांजी रूपांतरण चालू है।';
  }

  @override
  String get japaneseNotInstalled =>
      'इंस्टॉल नहीं है। काना फिर भी टाइप होता है; कांजी के लिए पैक चाहिए।';

  @override
  String get japaneseClearWords => 'सीखे गए शब्द मिटाएँ';

  @override
  String get japaneseClearWordsBody =>
      'आपके चुने जापानी शब्द भूल जाएगा। इस फ़ोन पर एन्क्रिप्टेड रूप में संग्रहीत।';

  @override
  String get japaneseClearTitle => 'सीखे गए जापानी शब्द मिटाएँ?';

  @override
  String get japaneseClearBody =>
      'आपके चुने सभी जापानी शब्द मिटा दिए जाएँगे। इसे पूर्ववत नहीं किया जा सकता।';

  @override
  String get privacyStoredChinesePhrases => 'चीनी वाक्यांश';

  @override
  String get privacyStoredJapaneseWords => 'जापानी शब्द';
}
