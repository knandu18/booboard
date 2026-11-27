// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class AppLocalizationsDe extends AppLocalizations {
  AppLocalizationsDe([String locale = 'de']) : super(locale);

  @override
  String get appName => 'BooBoard';

  @override
  String get homeTagline => 'Private Eingabe, auf diesem Gerät';

  @override
  String get homeOfflinePromise =>
      'BooBoard funktioniert offline und sendet *nichts irgendwohin.*';

  @override
  String get cancel => 'Abbrechen';

  @override
  String get delete => 'Löschen';

  @override
  String get save => 'Speichern';

  @override
  String get useAction => 'Verwenden';

  @override
  String get off => 'Aus';

  @override
  String get left => 'Links';

  @override
  String get right => 'Rechts';

  @override
  String get settingsLanguages => 'Sprachen';

  @override
  String get settingsTyping => 'Tippen';

  @override
  String get settingsFeel => 'Gefühl';

  @override
  String get settingsThemes => 'Designs';

  @override
  String get settingsPanels => 'Bereiche';

  @override
  String get settingsVoice => 'Sprache';

  @override
  String get settingsTranslation => 'Übersetzung';

  @override
  String get settingsPrivacy => 'Datenschutz';

  @override
  String get settingsAbout => 'Info';

  @override
  String get settingsModelPacks => 'Modellpakete';

  @override
  String get homeSetupTurnOn =>
      'Aktiviere BooBoard in der Tastaturliste von Android.';

  @override
  String get homeSetupChoose =>
      'Wähle BooBoard als Tastatur zum Schreiben aus.';

  @override
  String get homeFinishSetup => 'BooBoard einrichten abschließen';

  @override
  String get homeTypingSubtitle =>
      'Korrekturen, Vorschläge, Tasten und Wischen';

  @override
  String get homeFeelSubtitle => 'Haptik, Töne, Höhe und Einhandmodus';

  @override
  String get homePanelsSubtitle => 'Zwischenablage und Emoji';

  @override
  String get homeVoiceSubtitle => 'Sprich zum Schreiben, auf diesem Gerät';

  @override
  String get homeTranslationSubtitle => 'Übersetzt beim Tippen, offline';

  @override
  String get homePrivacySubtitle =>
      'Was gespeichert wird, Inkognito, App-Sperre und Sicherung';

  @override
  String get homeAboutSubtitle => 'Version, Lizenzen und Quellcode';

  @override
  String get homeImages => 'Bilder';

  @override
  String get homeAboutBooBoard => 'Über BooBoard';

  @override
  String get websiteOpenHint => 'Öffnet booboard.com in deinem Browser';

  @override
  String get websiteNoBrowser => 'Kein Browser kann booboard.com öffnen.';

  @override
  String get imagesSoonTitle => 'Bilder *kommen bald*';

  @override
  String get imagesSoonBody =>
      'Erstelle Bilder aus deinen Worten, direkt auf diesem Handy. Wie alles in BooBoard funktioniert es offline.';

  @override
  String get aboutWebsite => 'Website';

  @override
  String get aboutTitle => 'Info';

  @override
  String aboutVersion(String versionCode, String versionName) {
    return 'Version $versionName ($versionCode)';
  }

  @override
  String aboutVersionDebug(String versionCode, String versionName) {
    return 'Version $versionName ($versionCode) · Debug-Build';
  }

  @override
  String get aboutReadingVersion => 'Version wird gelesen…';

  @override
  String get aboutPrivacy => 'Datenschutz';

  @override
  String get aboutNoInternet => 'BooBoard kann das Internet nicht nutzen';

  @override
  String get aboutNoInternetBody =>
      'Veröffentlichte Versionen haben keine Internetberechtigung, daher verlässt nichts, was du tippst, dieses Gerät.';

  @override
  String get aboutLicence => 'Lizenz';

  @override
  String get aboutGplTitle => 'GNU General Public License v3 oder neuer';

  @override
  String get aboutGplBody =>
      'BooBoard ist freie Software. Du darfst sie unter der GPL untersuchen, ändern und weitergeben.';

  @override
  String get aboutSourceCode => 'Quellcode';

  @override
  String get aboutSourceBody =>
      'BooBoard steht unter GPL-3.0-or-later. Der Quellcode ist auf der Projektseite verfügbar.';

  @override
  String get aboutLicences => 'Lizenzen';

  @override
  String get aboutOpenSource => 'Open-Source-Lizenzen';

  @override
  String get aboutOpenSourceBody =>
      'Flutter, material_ui und jedes Paket, das BooBoard verwendet';

  @override
  String get aboutTextLoadFailed => 'Dieser Text konnte nicht geladen werden.';

  @override
  String get languagesEnabledHeader =>
      'Aktiviert, die erste ist die Standardsprache';

  @override
  String get languagesActive => 'Aktive Sprache';

  @override
  String get languagesAdd => 'Sprache hinzufügen';

  @override
  String get languagesAllEnabled => 'Alle Sprachen sind aktiviert';

  @override
  String get languagesAllEnabledBody =>
      'Entferne eine oben, um Platz zu schaffen.';

  @override
  String get languagesMultilingual => 'Mehrsprachiges Tippen';

  @override
  String get languagesMultilingualBody =>
      'Schlägt Wörter aus bis zu drei aktivierten Sprachen mit derselben Schrift vor. Ein Wort, das eine davon kennt, wird nie automatisch korrigiert.';

  @override
  String get languagesNativeDigits => 'Einheimische Ziffern';

  @override
  String get languagesNativeDigitsBody =>
      'Schreibt Ziffern in der Schrift der aktiven Sprache, sofern sie welche hat (०१२, ٠١٢).';

  @override
  String get languagesOptions => 'Sprachoptionen';

  @override
  String get languagesZhSubtitle =>
      'Pinyin, traditionelle Schriftzeichen und Wörterbuchpakete';

  @override
  String get languagesJaSubtitle =>
      'Fächer-Eingabe, Umwandlung und Wörterbuchpakete';

  @override
  String languagesReorderLabel(String language) {
    return 'Zum Umsortieren von $language ziehen';
  }

  @override
  String languageDefaultLabel(String language) {
    return '$language, Standard';
  }

  @override
  String languageLayoutTooltip(String language) {
    return 'Layout für $language';
  }

  @override
  String languageRemoveTooltip(String language) {
    return '$language entfernen';
  }

  @override
  String get feelHaptics => 'Haptik';

  @override
  String get feelHapticFeedback => 'Haptisches Feedback';

  @override
  String get feelHapticFeedbackBody =>
      'Eine kurze Vibration bei jeder Taste, abhängig von der Systemeinstellung';

  @override
  String get feelHapticStrength => 'Haptik-Stärke';

  @override
  String get feelSounds => 'Töne';

  @override
  String get feelKeySounds => 'Tastentöne';

  @override
  String get feelKeySoundsBody =>
      'Klicks für Tasten, Leerzeichen, Löschen und Eingabe';

  @override
  String get feelUseSystemVolume => 'Systemlautstärke verwenden';

  @override
  String get feelKeySoundVolume => 'Lautstärke der Tastentöne';

  @override
  String get feelHeight => 'Höhe';

  @override
  String get feelPortraitHeight => 'Höhe im Hochformat';

  @override
  String get feelLandscapeHeight => 'Höhe im Querformat';

  @override
  String get feelOneHandedFloating => 'Einhand und schwebend';

  @override
  String get feelOneHandedSide => 'Seite für Einhandmodus';

  @override
  String get feelFloatingKeyboard => 'Schwebende Tastatur';

  @override
  String get feelFloatingBody => 'Auf dem Bildschirm beliebig verschiebbar';

  @override
  String get panelsClipboard => 'Zwischenablage';

  @override
  String get panelsClipboardHistory => 'Zwischenablage-Verlauf';

  @override
  String get panelsClipboardHistoryBody =>
      'Speichert, was du kopierst, verschlüsselt auf diesem Gerät';

  @override
  String get panelsRecentChip => 'Chip für letzte Kopie';

  @override
  String get panelsRecentChipBody =>
      'Bietet deine letzte Kopie eine Minute lang in der Vorschlagsleiste an';

  @override
  String get panelsKeepUnpinned => 'Nicht angeheftete Kopien behalten für';

  @override
  String get panelsClipsToKeep => 'Zu behaltende Clips';

  @override
  String get panelsEmoji => 'Emoji';

  @override
  String get emojiSuggestions => 'Emoji-Vorschläge';

  @override
  String get emojiSuggestionsPanelBody =>
      'Bietet bei manchen Wörtern ein Emoji in der Vorschlagsleiste an';

  @override
  String get panelsPasswordsNeverSaved => 'Passwörter werden nie gespeichert';

  @override
  String get panelsSensitiveBody =>
      'Kopien, die Android als vertraulich markiert, werden nie behalten.';

  @override
  String get typingCorrections => 'Korrekturen';

  @override
  String get typingAutocorrect => 'Automatische Korrektur';

  @override
  String get typingAutocorrectBody =>
      'Korrigiert wahrscheinliche Tippfehler, wenn du ein Wort beendest';

  @override
  String get typingAutoCapitalise => 'Automatische Großschreibung';

  @override
  String get typingAutoCapitaliseBody => 'Großbuchstaben am Satzanfang';

  @override
  String get typingDoubleSpace => 'Doppelleerzeichen für Punkt';

  @override
  String get typingDoubleSpaceBody => 'Zweimal Leertaste schreibt „. “';

  @override
  String get typingSmartPunctuation => 'Intelligente Interpunktion';

  @override
  String get typingSmartPunctuationBody =>
      'Leerzeichen um Satzzeichen bereinigen und lokale Anführungszeichen verwenden';

  @override
  String get typingSuggestions => 'Vorschläge';

  @override
  String get typingSuggestionsBody => 'Zeigt Wörter in der Vorschlagsleiste an';

  @override
  String get typingNextWord => 'Nächstes-Wort-Vorhersage';

  @override
  String get typingNextWordBody => 'Schlägt das Wort vor, das oft folgt';

  @override
  String get typingEmojiBody => 'Bietet bei manchen Wörtern ein Emoji an';

  @override
  String get typingHideOffensive => 'Anstößige Wörter ausblenden';

  @override
  String get typingHideOffensiveBody =>
      'Nie vorschlagen, außer du tippst sie vollständig';

  @override
  String get typingKeys => 'Tasten';

  @override
  String get typingKeyPopups => 'Tastenpopups';

  @override
  String get typingKeyPopupsBody =>
      'Vergrößert eine Taste, während du sie drückst';

  @override
  String get typingLongPressDelay => 'Verzögerung für langes Drücken';

  @override
  String get typingNumberRow => 'Zahlenreihe';

  @override
  String get typingNumberRowBody => 'Zeigt 0 bis 9 über den Buchstaben';

  @override
  String get typingHintLabels => 'Hinweisbeschriftungen';

  @override
  String get typingHintLabelsBody =>
      'Kleine Zeichen auf den Tasten, zum Beispiel Akzente';

  @override
  String get typingLowercaseLabels => 'Kleinbuchstaben-Beschriftung';

  @override
  String get typingLowercaseLabelsBody =>
      'Tastenbuchstaben bleiben klein, wenn Umschalt aktiv ist';

  @override
  String get typingSwipe => 'Wischen';

  @override
  String get typingSwipeTyping => 'Wischeingabe';

  @override
  String get typingSwipeTypingBody =>
      'Über Buchstaben gleiten, um ein Wort zu schreiben';

  @override
  String get typingShowTrail => 'Spur anzeigen';

  @override
  String get typingTrailWidth => 'Spurbreite';

  @override
  String get typingTrailFade => 'Spur-Ausblendung';

  @override
  String get typingLivePreview => 'Live-Vorschau';

  @override
  String get typingLivePreviewBody =>
      'Zeigt das wahrscheinliche Wort beim Gleiten an';

  @override
  String get typingSpaceMovesCursor => 'Leertaste bewegt den Cursor';

  @override
  String get typingSpaceMovesCursorBody =>
      'Auf der Leertaste ziehen, um den Cursor zu bewegen';

  @override
  String get typingSwipeBackspace =>
      'Auf Löschen wischen, um Wörter zu löschen';

  @override
  String get typingSwipeBackspaceBody =>
      'Auf Löschen nach links wischen, um Wörter auszuwählen und zu löschen';

  @override
  String get voiceTyping => 'Spracheingabe';

  @override
  String get voiceTypingBody =>
      'Sprich zum Schreiben, auf Englisch. Die Erkennung läuft auf diesem Gerät.';

  @override
  String get voiceRecognition => 'Erkennung';

  @override
  String get voiceModelPacksBody =>
      'Sprach- und Übersetzungspakete installieren oder entfernen';

  @override
  String get voiceAudioStays =>
      'Audio bleibt auf diesem Gerät und wird nie gespeichert.';

  @override
  String get voicePackAutomatic => 'Automatisch';

  @override
  String get voicePackAutomaticSelected => 'Automatisch (ausgewählt)';

  @override
  String get voicePack => 'Sprachpaket';

  @override
  String get voiceNoPack =>
      'Kein Sprachpaket installiert. Installiere eines unter Modellpakete.';

  @override
  String get voiceLooking => 'Installierte Pakete werden gesucht';

  @override
  String voicePackItem(String name, String size) {
    return '$name · $size';
  }

  @override
  String voicePackItemSelected(String name, String size) {
    return '$name · $size (ausgewählt)';
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
  String get packsOpenFailed =>
      'BooBoard konnte die Dateiauswahl nicht öffnen.';

  @override
  String packsInstalled(String name) {
    return '$name installiert.';
  }

  @override
  String packsDeleteTitle(String name) {
    return '$name löschen?';
  }

  @override
  String get packsDeleteBody =>
      'Die Dateien werden von diesem Telefon entfernt. Du kannst das Paket später aus seiner Datei wieder importieren.';

  @override
  String packsDeleted(String name) {
    return '$name gelöscht.';
  }

  @override
  String packsDeleteFailed(String name) {
    return 'BooBoard konnte $name nicht löschen. Versuche es erneut.';
  }

  @override
  String get packsIntro =>
      'Pakete werden vor der Installation geprüft. Sie enthalten nur Daten, niemals Code.';

  @override
  String get packsImport => 'Importieren';

  @override
  String get packsImportTitle => 'Paketdatei importieren';

  @override
  String get packsChecking => 'Wird geprüft und installiert…';

  @override
  String get packsImportBody =>
      'Eine .boopack-Datei, zum Beispiel aus Downloads';

  @override
  String get packsNoVoice => 'Keine Sprachpakete installiert';

  @override
  String get packsNoVoiceBody => 'Spracheingabe benötigt ein Sprachpaket.';

  @override
  String get packsNoTranslation => 'Keine Übersetzungspakete installiert';

  @override
  String get packsNoTranslationBody =>
      'Übersetzung benötigt ein Paket pro Richtung.';

  @override
  String get packsDictionaries => 'Wörterbücher';

  @override
  String get packsNoDictionary => 'Keine Wörterbuchpakete installiert';

  @override
  String get packsNoDictionaryBody =>
      'Chinesisches und japanisches Tippen benötigt ein Wörterbuchpaket.';

  @override
  String get packsGetTitle => 'Pakete beschaffen';

  @override
  String get packsExplainTitle =>
      'Pakete sind Dateien, die Sie selbst hinzufügen.';

  @override
  String get packsExplainBody =>
      'Laden Sie sie auf einem anderen Gerät von der Veröffentlichungsseite des Projekts herunter, kopieren Sie sie auf dieses Telefon und importieren Sie sie dann.';

  @override
  String get packsCopyLink => 'Link zur Veröffentlichungsseite kopieren';

  @override
  String get packsPrivateTitle => 'So bleiben Downloads privat';

  @override
  String get packsPrivateBody =>
      'BooBoard hat keine Internetberechtigung und verbindet sich nie. „Herunterladen“ öffnet deinen Browser, der das Paket aus der GitHub-Veröffentlichung des Projekts lädt. BooBoard prüft danach die Signatur des Pakets auf diesem Telefon, bevor etwas installiert wird.';

  @override
  String get packsAvailableTitle => 'Pakete, die du hinzufügen kannst';

  @override
  String get packsDownload => 'Herunterladen';

  @override
  String packsDownloadMeta(String size) {
    return '$size · öffnet deinen Browser';
  }

  @override
  String packsDownloadStarted(String name) {
    return 'Dein Browser lädt $name herunter. Wenn er fertig ist, tippe auf „Paketdatei importieren“.';
  }

  @override
  String get packsNoBrowser =>
      'Kein Browser kann den Link öffnen. Kopiere stattdessen den Link zur Veröffentlichungsseite.';

  @override
  String get packsImportCheckedBody =>
      'Wähle die heruntergeladene .boopack-Datei. Sie wird auf diesem Telefon geprüft und dann installiert.';

  @override
  String get packsAllInstalled =>
      'Alle veröffentlichten Pakete sind installiert.';

  @override
  String get packsLinkCopied =>
      'Link kopiert. Öffnen Sie ihn auf einem anderen Gerät.';

  @override
  String get packsPlayTitle => 'Über Google Play beziehen';

  @override
  String get packsPlayNote =>
      'Google Play lädt diese Pakete herunter, nicht BooBoard. BooBoard selbst nutzt nie das Netzwerk.';

  @override
  String get packsGet => 'Laden';

  @override
  String get packsStatusNotRequested => 'Noch nicht heruntergeladen';

  @override
  String get packsStatusWaiting => 'Warten auf WLAN oder mobile Daten';

  @override
  String get packsStatusDownloading => 'Wird über Google Play heruntergeladen';

  @override
  String get packsStatusInstalling => 'Wird geprüft und installiert';

  @override
  String get packsStatusFailed =>
      'Google Play konnte es nicht bereitstellen. Versuchen Sie es erneut.';

  @override
  String packsOfferMeta(Object size, Object status) {
    return '$size · $status';
  }

  @override
  String get packsVerifyTitle => 'Installierte Pakete prüfen';

  @override
  String get packsVerifyBody =>
      'Prüft jede Datei jedes installierten Pakets anhand der signierten Liste. Es wird nichts geändert.';

  @override
  String packsVerifyOk(Object count) {
    return '$count installierte Pakete geprüft. Alle Dateien stimmen überein.';
  }

  @override
  String packsVerifyDamaged(Object count) {
    return '$count installierte Pakete haben beschädigte oder fehlende Dateien. Löschen Sie sie und importieren Sie sie erneut.';
  }

  @override
  String get packsVerifyUnavailable =>
      'Die Prüfung installierter Pakete ist in dieser Version von BooBoard nicht verfügbar.';

  @override
  String get packsVerifyFailed =>
      'BooBoard konnte die Pakete nicht prüfen. Es wurde nichts geändert.';

  @override
  String packsFreeSpace(Object size) {
    return '$size frei auf diesem Telefon.';
  }

  @override
  String get packsNothingStored => 'Noch nichts gespeichert.';

  @override
  String packsInstalledUse(String size) {
    return 'Installierte Pakete belegen $size auf diesem Gerät.';
  }

  @override
  String get packErrorBadSignature =>
      'Dieses Paket ist nicht für BooBoard signiert, daher wurde nichts installiert.';

  @override
  String get packErrorBadFormat =>
      'Diese Datei ist kein BooBoard-Paket. Es wurde nichts installiert.';

  @override
  String get packErrorTooLarge => 'Dieses Paket ist zu groß für dieses Gerät.';

  @override
  String get packErrorVersion =>
      'Dieses Paket benötigt eine neuere Version von BooBoard.';

  @override
  String get packErrorNoSpace =>
      'Es ist nicht genug freier Speicher für dieses Paket vorhanden.';

  @override
  String get packErrorGeneric =>
      'Das Paket konnte nicht installiert werden. Es wurde nichts geändert.';

  @override
  String get translateDefaultPair => 'Standard-Sprachpaar';

  @override
  String translatePairName(String from, String to) {
    return '$from → $to';
  }

  @override
  String get translateOffline => 'Offline-Übersetzung';

  @override
  String get translateOfflineBody =>
      'Übersetzt beim Tippen auf der Tastatur und markierten Text in jeder App.';

  @override
  String get translateDefaultPairTile => 'Standardpaar';

  @override
  String get translatePackInstalled => 'Paket installiert';

  @override
  String get translatePackNotInstalled =>
      'Paket nicht installiert. Hole es unter Modellpakete.';

  @override
  String get translateInstalled => 'Installierte Richtungen';

  @override
  String get translateInstalledBody =>
      'Jede Richtung ist ein Paket, zum Beispiel Englisch → Spanisch.';

  @override
  String translatePackMeta(String license, String size) {
    return '$size · $license';
  }

  @override
  String get translateModelPacksBody =>
      'Übersetzungspakete installieren oder löschen';

  @override
  String get translateRunsOnPhone =>
      'Die Übersetzung läuft auf diesem Gerät. Nichts, was du übersetzt, wird gespeichert.';

  @override
  String get privacyUnlockReason =>
      'Entsperre BooBoard, um deine Einstellungen und Daten zu sehen';

  @override
  String get privacyLockUnavailable =>
      'Die Gerätesperre ist gerade nicht verfügbar. Versuche es gleich noch einmal.';

  @override
  String get privacyLockedTitle => 'BooBoard ist gesperrt';

  @override
  String get privacyLockedBody =>
      'Entsperre mit deinem Fingerabdruck oder der Geräte-PIN, um fortzufahren.';

  @override
  String get privacyUnlock => 'Entsperren';

  @override
  String backupSaved(String size) {
    return 'Backup gespeichert ($size). Bewahre deine Passphrase gut auf.';
  }

  @override
  String get backupUnlockRetrySaved =>
      'Entsperre das Gerät und versuche es erneut. Es wurde nichts gespeichert.';

  @override
  String get backupSaveFailed =>
      'Das Backup konnte nicht gespeichert werden. Es wurde nichts geändert.';

  @override
  String get backupCheckFailed =>
      'Die gespeicherte Datei ließ sich nicht prüfen und ist eventuell beschädigt. Speichere das Backup erneut als neue Datei.';

  @override
  String get backupWrongPassphrase =>
      'Falsche Passphrase oder beschädigte Datei. Es wurde nichts geändert.';

  @override
  String get backupInvalidFile =>
      'Diese Datei ist kein gültiges BooBoard-Backup. Es wurde nichts geändert.';

  @override
  String get backupTooLarge =>
      'Diese Datei ist zu groß für ein BooBoard-Backup.';

  @override
  String get backupNewerVersion =>
      'Dieses Backup wurde mit einer neueren BooBoard-Version erstellt. Aktualisiere BooBoard, um es wiederherzustellen.';

  @override
  String get backupBusy =>
      'Schließe zuerst das andere Dateifenster und versuche es erneut.';

  @override
  String get backupOpenFailed =>
      'Das Backup konnte nicht geöffnet werden. Es wurde nichts geändert.';

  @override
  String get backupEmpty => 'Dieses Backup ist leer.';

  @override
  String get backupRestoreTitle => 'Backup wiederherstellen';

  @override
  String backupMadeBy(String date, String version) {
    return 'Erstellt am $date mit BooBoard $version.';
  }

  @override
  String get backupMerge => 'Zusammenführen';

  @override
  String get backupMergeBody =>
      'Behält, was auf diesem Gerät ist, und fügt hinzu, was im Backup ist.';

  @override
  String get backupReplace => 'Ersetzen';

  @override
  String get backupReplaceBody =>
      'Macht die gewählten Bereiche wie im Backup. Vorhandene Daten werden vorher gelöscht.';

  @override
  String get commonContinue => 'Weiter';

  @override
  String get backupReplaceTitle => 'Daten auf diesem Gerät ersetzen?';

  @override
  String get backupReplaceConfirm =>
      'Die gewählten Bereiche auf diesem Gerät werden gelöscht und ersetzt. Das kann nicht rückgängig gemacht werden.';

  @override
  String get backupPrivacyChangesTitle =>
      'Dieses Backup ändert deine Datenschutz-Einstellungen';

  @override
  String get backupPrivacyChangesBody =>
      'Beim Wiederherstellen der Einstellungen werden diese Datenschutz-Einstellungen auf diesem Telefon geändert. Prüfe sie, bevor du fortfährst.';

  @override
  String backupPrivacyChangeLine(String setting, String from, String to) {
    return '$setting: $from → $to';
  }

  @override
  String get backupStateOn => 'An';

  @override
  String backupAppsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Apps',
      one: '1 App',
    );
    return '$_temp0';
  }

  @override
  String get backupRestoreAndChange => 'Wiederherstellen und ändern';

  @override
  String get backupUnlockRetryChanged =>
      'Entsperre das Gerät und versuche es erneut. Es wurde nichts geändert.';

  @override
  String get backupRestoreFailed =>
      'BooBoard konnte die Wiederherstellung nicht abschließen. Einige Daten wurden möglicherweise nicht geschrieben.';

  @override
  String get restoreNothingNew => 'Nichts Neues wiederhergestellt.';

  @override
  String restoreSummary(String items) {
    return 'Wiederhergestellt: $items.';
  }

  @override
  String restoreSummarySkipped(String added, String skipped) {
    return '$added Übersprungen: $skipped.';
  }

  @override
  String restoreLearnedFor(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Sprachen',
      one: '1 Sprache',
    );
    return 'gelernte Wörter für $_temp0';
  }

  @override
  String countFiles(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Dateien',
      one: '1 Datei',
    );
    return '$_temp0';
  }

  @override
  String countWords(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Wörter',
      one: '1 Wort',
    );
    return '$_temp0';
  }

  @override
  String countLanguages(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Sprachen',
      one: '1 Sprache',
    );
    return '$_temp0';
  }

  @override
  String countShortcuts(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Kürzel',
      one: '1 Kürzel',
    );
    return '$_temp0';
  }

  @override
  String countClipboardItems(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Zwischenablage-Einträge',
      one: '1 Zwischenablage-Eintrag',
    );
    return '$_temp0';
  }

  @override
  String countThemeFiles(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Designdateien',
      one: '1 Designdatei',
    );
    return '$_temp0';
  }

  @override
  String countPinnedItems(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count angeheftete Elemente',
      one: '1 angeheftetes Element',
    );
    return '$_temp0';
  }

  @override
  String countPacks(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Pakete',
      one: '1 Paket',
    );
    return '$_temp0';
  }

  @override
  String countBlockedWords(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count gesperrte Wörter',
      one: '1 gesperrtes Wort',
    );
    return '$_temp0';
  }

  @override
  String countTimes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Mal',
      one: '1 Mal',
    );
    return '$_temp0';
  }

  @override
  String timeMinutesAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'vor $count Minuten',
      one: 'vor 1 Minute',
    );
    return '$_temp0';
  }

  @override
  String timeHoursAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'vor $count Stunden',
      one: 'vor 1 Stunde',
    );
    return '$_temp0';
  }

  @override
  String timeDaysAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'vor $count Tagen',
      one: 'vor 1 Tag',
    );
    return '$_temp0';
  }

  @override
  String get timeJustNow => 'gerade eben';

  @override
  String get languagePortuguese => 'Portugiesisch';

  @override
  String packMeta(String languages, String license, String size) {
    return '$languages · $size · $license';
  }

  @override
  String privacyLearnedWordsTitle(String language) {
    return 'Gelernte Wörter ($language)';
  }

  @override
  String privacyClearLanguageTitle(String language) {
    return '$language-Wörter löschen?';
  }

  @override
  String get privacyClearLanguageBody =>
      'Dadurch werden alle in dieser Sprache gelernten Wörter und die gesperrten Wörter gelöscht. Das kann nicht rückgängig gemacht werden.';

  @override
  String get privacyClear => 'Leeren';

  @override
  String get privacySaveFailed =>
      'Die Änderung konnte nicht gespeichert werden. Versuche es erneut.';

  @override
  String get privacyCouldNotReadWords =>
      'BooBoard konnte diese Wörter nicht lesen.';

  @override
  String get privacyCannotReadWordsNow =>
      'BooBoard kann diese Wörter gerade nicht lesen. Entsperre das Gerät und versuche es erneut.';

  @override
  String get privacyNoWordsLanguage =>
      'In dieser Sprache wurden noch keine Wörter gelernt. BooBoard lernt ein Wort, nachdem du es ein paar Mal getippt hast.';

  @override
  String privacyBlockedWordsTooltip(num count) {
    return 'Gesperrte Wörter ($count)';
  }

  @override
  String get privacySortTooltip => 'Sortieren';

  @override
  String get privacySortMostUsed => 'Am häufigsten zuerst';

  @override
  String get privacySortAZ => 'A bis Z';

  @override
  String get privacyMoreTooltip => 'Mehr';

  @override
  String get privacyClearThisLanguage => 'Diese Sprache leeren';

  @override
  String get privacySearchWords => 'Wörter suchen';

  @override
  String privacyWordsSummary(String blocked, String words) {
    return '$words · $blocked';
  }

  @override
  String get privacyNoWordsYet => 'Noch keine Wörter.';

  @override
  String privacyNoWordsMatch(String query) {
    return 'Keine Wörter passen zu „$query“.';
  }

  @override
  String get privacyNeverSuggested => 'Nie vorgeschlagen';

  @override
  String get privacyBlockedExplain =>
      'BooBoard schlägt diese Wörter nicht vor und korrigiert nicht zu ihnen.';

  @override
  String get privacyNoBlockedWords => 'Keine gesperrten Wörter.';

  @override
  String get privacyAllowAgain => 'Wieder erlauben';

  @override
  String privacyWordLastUsed(int count, String when) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Mal getippt',
      one: 'Einmal getippt',
    );
    return '$_temp0 · zuletzt $when';
  }

  @override
  String privacyWordNotYetSuggested(String when) {
    return 'Bisher einmal getippt, noch nicht vorgeschlagen · zuletzt $when';
  }

  @override
  String get privacyToday => 'heute';

  @override
  String get privacyYesterday => 'gestern';

  @override
  String privacyActionsFor(String word) {
    return 'Aktionen für $word';
  }

  @override
  String get privacyForgetWord => 'Dieses Wort vergessen';

  @override
  String get privacyNeverSuggestWord => 'Dieses Wort nie vorschlagen';

  @override
  String get privacyTryAgain => 'Erneut versuchen';

  @override
  String get privacyCenterLoadFailed =>
      'BooBoard konnte seine Datenschutzdaten nicht lesen. Versuche es später erneut.';

  @override
  String get privacyDevBuildNetwork =>
      'Dieser Build fordert Internetzugriff an. BooBoard sollte das nie tun. Bitte melde es.';

  @override
  String get privacyNoInternetPermission =>
      'BooBoard hat keine Internetberechtigung. Es kann nichts senden.';

  @override
  String get privacyDevBuildNote =>
      'Dies ist ein Entwicklungs-Build. Seine Netzwerkberechtigung gilt nur für Entwicklungswerkzeuge.';

  @override
  String get privacyDevBuildShort =>
      'Entwicklungs-Build. BooBoard hat weiterhin keine Internetberechtigung.';

  @override
  String privacyStorageSize(String size, String when) {
    return '$size · geändert $when';
  }

  @override
  String get privacyCustomThemes => 'Eigene Designs';

  @override
  String get privacyNoPacks =>
      'Keine installiert. Sprach- und Übersetzungspakete erscheinen hier.';

  @override
  String privacyPacksSize(int count, String size) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Pakete',
      one: '1 Paket',
    );
    return '$_temp0 · $size';
  }

  @override
  String get privacyWhatBooBoardStores => 'Was BooBoard speichert';

  @override
  String get privacyShowsSizesOnly =>
      'BooBoard zeigt hier nur Größen, nie den Inhalt. Die Größen enthalten die letzte gespeicherte Kopie, die deine Daten schützt, wenn ein Speichern unterbrochen wird.';

  @override
  String get privacyTypingPrivacy => 'Datenschutz beim Tippen';

  @override
  String get privacyLearnNewWords => 'Neue Wörter lernen';

  @override
  String get privacyLearnNewWordsBody =>
      'Lernt Wörter und Wendungen aus deinen Eingaben. Nie in Passwortfeldern oder im Inkognito-Modus.';

  @override
  String get privacyIncognito => 'Inkognito';

  @override
  String get privacyIncognitoBody =>
      'Lernt und merkt sich nichts, solange es an ist. Inkognito-Tabs im Browser schalten es selbst ein.';

  @override
  String get privacyHideScreenshots => 'Vor Screenshots verbergen';

  @override
  String get privacyHideScreenshotsBody =>
      'Verhindert Screenshots und Bildschirmaufnahmen der Tastatur in jeder App. Passwortfelder sind immer verborgen.';

  @override
  String get privacyAutoOffApps => 'In diesen Apps automatisch ausgeschaltet';

  @override
  String get privacyAutoOffAppsBody =>
      'BooBoard speichert App-Namen nur, um diese Liste zu füllen. Sie sind verschlüsselt, werden im Inkognito-Modus nie gespeichert, und du kannst sie unten löschen.';

  @override
  String get privacyNoAppsYet => 'Noch keine Apps';

  @override
  String get privacyNoAppsYetBody =>
      'Apps, in denen du tippst, erscheinen hier.';

  @override
  String get privacyAlwaysIncognitoApps => 'Apps immer im Inkognito-Modus';

  @override
  String get privacyPersonalShortcuts => 'Persönliche Kürzel';

  @override
  String get privacyOfferShortcuts => 'Kürzel anbieten';

  @override
  String get privacyOfferShortcutsBody =>
      'Zeigt deine Kurzformen, wie „omw“, als ersten Vorschlag an.';

  @override
  String get privacyEditShortcuts => 'Kürzel bearbeiten';

  @override
  String get privacyNoShortcutsYet => 'Noch keine';

  @override
  String get privacyLearnedAndClipboard => 'Gelernte Wörter und Zwischenablage';

  @override
  String get privacyNoWordsLearnedYet => 'Noch keine Wörter gelernt';

  @override
  String get privacyWordsLearnedBody =>
      'Wörter, die du tippst, werden hier gelernt, sobald BooBoard sie ein paar Mal gesehen hat.';

  @override
  String privacyReviewWords(String when) {
    return 'Wörter prüfen, entfernen oder sperren · $when';
  }

  @override
  String get privacyClipboardHistoryEmpty =>
      'Der Verlauf ist leer. Ändere die Zwischenablage-Einstellungen unter Bereiche.';

  @override
  String privacyClipboardInHistory(String size) {
    return '$size im Verlauf. Ändere die Zwischenablage-Einstellungen unter Bereiche.';
  }

  @override
  String get privacyAppLock => 'App-Sperre';

  @override
  String get privacyLockBooBoard => 'BooBoard sperren';

  @override
  String get privacyLockBooBoardBody =>
      'Fragt beim Öffnen der App oder nach dem Hintergrundbetrieb nach Fingerabdruck oder Geräte-PIN.';

  @override
  String get privacyLockAfter => 'Sperren nach';

  @override
  String get privacySetScreenLockFirst => 'Lege zuerst eine Displaysperre fest';

  @override
  String get privacySetScreenLockBody =>
      'Die App-Sperre nutzt deinen Fingerabdruck oder die Geräte-PIN. Lege in den Sicherheitseinstellungen von Android eine PIN, ein Muster oder ein Passwort fest und komm dann zurück.';

  @override
  String get privacyTurnOnAppLockReason =>
      'App-Sperre für BooBoard einschalten';

  @override
  String get privacyNotAvailable => 'Gerade nicht verfügbar';

  @override
  String get privacyNotAvailableBody =>
      'Die Gerätesperre konnte nicht verwendet werden. Die App-Sperre bleibt aus.';

  @override
  String get privacyBackupTitle => 'Backup';

  @override
  String get privacyBackupRestore => 'Backup und Wiederherstellung';

  @override
  String get privacyBackupRestoreBody =>
      'Eine verschlüsselte .boobackup-Datei, die du aufbewahrst. Du wählst, was darin enthalten ist.';

  @override
  String get privacyDeleteData => 'Daten löschen';

  @override
  String get privacyEraseEverything => 'Alles löschen';

  @override
  String get privacyEraseEverythingBody =>
      'Alle oben genannten Kategorien, deine eigenen Designs und der Schlüssel, der sie schützt.';

  @override
  String privacyDeleteTitle(String category) {
    return '$category löschen?';
  }

  @override
  String get privacyEraseTitle => 'Alles löschen?';

  @override
  String get privacyWillDelete => 'Dies löscht dauerhaft:';

  @override
  String get privacyResetSettings =>
      'Alle Einstellungen außerdem auf die Standardwerte zurücksetzen';

  @override
  String get privacyCannotBeUndone =>
      'Das kann nicht rückgängig gemacht werden.';

  @override
  String get privacyDeleted => 'Gelöscht.';

  @override
  String get privacyDeleteFailed =>
      'BooBoard konnte nicht alles löschen. Versuche es erneut.';

  @override
  String get privacyOk => 'OK';

  @override
  String get backupMakeTitle => 'Backup erstellen';

  @override
  String get backupIncludeImages => 'Hintergrundbilder einschließen';

  @override
  String get backupPhotosLarger => 'Fotos machen die Datei deutlich größer.';

  @override
  String get backupCreateButton => 'Verschlüsseltes Backup erstellen';

  @override
  String get backupRestoreSection => 'Wiederherstellen';

  @override
  String get backupRestoreFromFile => 'Aus einer Backup-Datei wiederherstellen';

  @override
  String get backupRestoreFromFileBody =>
      'Öffne eine .boobackup-Datei, prüfe den Inhalt und führe dann zusammen oder ersetze.';

  @override
  String get backupChoosePassphrase => 'Passphrase wählen';

  @override
  String get backupEnterPassphrase => 'Passphrase eingeben';

  @override
  String get backupWriteItDown =>
      'Schreib sie an einen sicheren Ort. Eine verlorene Passphrase kann nicht wiederhergestellt werden.';

  @override
  String get backupPassphrase => 'Passphrase';

  @override
  String get backupTypeAgain => 'Noch einmal eingeben';

  @override
  String get backupMismatch => 'Die Passphrasen stimmen nicht überein';

  @override
  String backupStrength(String strength) {
    return 'Passphrase-Stärke: $strength';
  }

  @override
  String get strengthTooShort => 'Mindestens 8 Zeichen verwenden';

  @override
  String get strengthWeak => 'Schwach';

  @override
  String get strengthFair => 'Ausreichend';

  @override
  String get strengthGood => 'Gut';

  @override
  String get strengthStrong => 'Stark';

  @override
  String get backupOpen => 'Öffnen';

  @override
  String get backupNothingYet => 'Noch nichts';

  @override
  String get backupSettingsSummary =>
      'Design, Sprachen, Tippen und Datenschutzeinstellungen';

  @override
  String backupLearnedSummary(String languages, String words) {
    return '$words in $languages';
  }

  @override
  String backupPinnedOff(String items) {
    return '$items. Aus, außer du schaltest es ein.';
  }

  @override
  String backupAlreadyHere(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Kürzel schon vorhanden',
      one: '1 Kürzel schon vorhanden',
    );
    return '$_temp0';
  }

  @override
  String backupThemesAlreadyHere(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Designdateien schon vorhanden',
      one: '1 Designdatei schon vorhanden',
    );
    return '$_temp0';
  }

  @override
  String get backupClipboardKept =>
      'Zwischenablage unverändert (unbekanntes Layout)';

  @override
  String get backupEmojiKept => 'zuletzt genutzte Emoji behalten';

  @override
  String get backupSettingsApplied => 'Einstellungen';

  @override
  String backupLearnedAdded(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Sprachen',
      one: '1 Sprache',
    );
    return 'gelernte Wörter für $_temp0';
  }

  @override
  String shortcutDeleteTitle(String trigger) {
    return '„$trigger“ löschen?';
  }

  @override
  String get shortcutDeleteBody =>
      'Dadurch wird das Kürzel entfernt. Das kann nicht rückgängig gemacht werden.';

  @override
  String get shortcutAdd => 'Kürzel hinzufügen';

  @override
  String get shortcutSearch => 'Kürzel suchen';

  @override
  String get shortcutNoMatch => 'Keine Kürzel passen zu deiner Suche.';

  @override
  String shortcutDeleteTooltip(String trigger) {
    return '$trigger löschen';
  }

  @override
  String get shortcutNoneYet => 'Noch keine Kürzel';

  @override
  String get shortcutExplain =>
      'Ein Kürzel macht aus einer Kurzform einen längeren Text. Beispiele:';

  @override
  String shortcutExamples(String first, String second) {
    return '$first\n$second';
  }

  @override
  String get shortcutEncrypted =>
      'Kürzel sind auf diesem Gerät verschlüsselt, wie deine gelernten Wörter.';

  @override
  String get shortcutNew => 'Neues Kürzel';

  @override
  String get shortcutEdit => 'Kürzel bearbeiten';

  @override
  String get shortcutShortForm => 'Kurzform';

  @override
  String get shortcutExpandsTo => 'Wird erweitert zu';

  @override
  String get privacyMascotLabel => 'BooBoard-Datenschutzmaskottchen';

  @override
  String get privacyStoredEmoji => 'Zuletzt verwendete Emoji';

  @override
  String get privacyStoredApps => 'App-Liste';

  @override
  String get privacyStoredOther => 'Andere gespeicherte Daten';

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
      'Gib die Kurzform ein, die erweitert werden soll.';

  @override
  String shortcutProblemTriggerTooLong(num count) {
    return 'Die Kurzform darf höchstens $count Zeichen haben.';
  }

  @override
  String get shortcutProblemTriggerCharacters =>
      'Verwende in der Kurzform nur Buchstaben, Ziffern und Apostrophe.';

  @override
  String get shortcutProblemEmptyExpansion =>
      'Gib ein, wofür die Kurzform stehen soll.';

  @override
  String shortcutProblemExpansionTooLong(num count) {
    return 'Die Erweiterung darf höchstens $count Zeichen haben.';
  }

  @override
  String get shortcutProblemDuplicate =>
      'Du hast bereits ein Kürzel mit dieser Kurzform.';

  @override
  String shortcutProblemTooMany(num count) {
    return 'Du kannst höchstens $count Kürzel behalten.';
  }

  @override
  String get onboardingWelcomeTitle => 'Hallo, ich bin *Boo.*';

  @override
  String get onboardingWelcomeBody =>
      'Ich bin eine Tastatur, die nie online geht. Was du tippst, bleibt sicher verschlossen auf diesem Telefon.';

  @override
  String get onboardingWelcomeStart => 'Los geht’s';

  @override
  String get onboardingMascotLabel => 'Boo, der BooBoard-Geist';

  @override
  String get onboardingFactNoInternet => 'Keine Internetberechtigung';

  @override
  String get onboardingFactOpenSource => 'Open Source';

  @override
  String get onboardingFactOpenSourceBody =>
      'Jeder kann den Code lesen und prüfen.';

  @override
  String get onboardingDemoKeyboards => 'Tastatur-Apps';

  @override
  String get onboardingDemoOtherKeyboard => 'Andere Tastatur';

  @override
  String get onboardingDemoAttention => 'Achtung';

  @override
  String get onboardingDemoAttentionBody =>
      'Diese Tastatur kann möglicherweise alle eingegebenen Texte erfassen…';

  @override
  String get onboardingDemoOk => 'OK';

  @override
  String get onboardingDemoChooseInput => 'Eingabemethode wählen';

  @override
  String get onboardingDemoSwitchOn => 'Einschalten';

  @override
  String get onboardingDemoTapOk => '2× OK';

  @override
  String get onboardingDemoComeBack => 'Zurückkommen';

  @override
  String get onboardingDemoPick => 'BooBoard wählen';

  @override
  String get onboardingDemoStartTyping => 'Lostippen';

  @override
  String get onboardingDemoRebootNote =>
      'Hinweis: Nach einem Neustart kann diese App erst starten, wenn du dein Smartphone entsperrst';

  @override
  String get onboardingDemoChatIn => 'Bis um 7?';

  @override
  String get onboardingDemoChatOut => 'Bin unterwegs';

  @override
  String get onboardingDemoMessage => 'Nachricht';

  @override
  String get onboardingShh => 'psst';

  @override
  String get onboardingTryMe => 'Probier mich';

  @override
  String get onboardingTurnOnTitle => '*BooBoard* einschalten';

  @override
  String get onboardingTurnOnBody =>
      'Schalte es in der Tastaturliste von Android ein und komm dann zurück. Diese Seite merkt es von selbst.';

  @override
  String get onboardingKeyboardOn => 'BooBoard ist an';

  @override
  String get onboardingKeyboardOff => 'Noch nicht an';

  @override
  String get onboardingOpenKeyboardSettings => 'Tastatureinstellungen öffnen';

  @override
  String get onboardingSwitchTitle => 'Mach es zu *deinem*';

  @override
  String get onboardingSwitchBody =>
      'Wähle BooBoard in der kurzen Liste von Android. Du kannst jederzeit zurückwechseln.';

  @override
  String get onboardingKeyboardIsYours => 'BooBoard ist deine Tastatur';

  @override
  String get onboardingKeyboardNotYours => 'Noch nicht deine Tastatur';

  @override
  String get onboardingTurnOnFirst => 'Erst einschalten';

  @override
  String get onboardingChooseKeyboard => 'Tastatur wählen';

  @override
  String get onboardingCheckingPermissions =>
      'App-Berechtigungen werden geprüft…';

  @override
  String get onboardingDebugInternet =>
      'Dieser Debug-Build kann das Internet erreichen. Debug-Builds haben diese Berechtigung nur für die Entwicklung.';

  @override
  String get onboardingReleaseInternet =>
      'Dieser Build kann das Internet erreichen.';

  @override
  String get onboardingNoInternet =>
      'BooBoard hat keine Internetberechtigung und kann deshalb nichts irgendwohin senden.';

  @override
  String get onboardingWarningTitle => 'Zu dieser *Warnung*';

  @override
  String get onboardingWarningBody =>
      'Android zeigt sie bei jeder Tastatur, weil eine Tastatur das Getippte ins Internet senden könnte. BooBoard kann das nicht.';

  @override
  String get onboardingInternetAccess => 'Internetzugriff';

  @override
  String get onboardingEverythingHere => 'Bleibt auf diesem Telefon';

  @override
  String get onboardingEverythingHereBody =>
      'Gelernte Wörter, Zwischenablage und Einstellungen sind mit einem Schlüssel im Android Keystore verschlüsselt.';

  @override
  String get onboardingLanguagesTitle => 'Deine *Sprachen*';

  @override
  String get onboardingThemeTitle => 'Design';

  @override
  String get onboardingTryTyping => 'Schreibe einen Satz';

  @override
  String get onboardingTrySwipe => 'Wische ein Wort, Buchstabe für Buchstabe';

  @override
  String get onboardingTryAccents => 'Halte einen Buchstaben für Akzente';

  @override
  String get onboardingTryTitle => 'Probier es *aus*';

  @override
  String get onboardingTryField => 'Tippe hier etwas';

  @override
  String get onboardingAllSetTitle => 'Alles *bereit.*';

  @override
  String get onboardingAllSetBody =>
      'Sprachen, Tippen, Designs und mehr findest du jederzeit in den Einstellungen.';

  @override
  String onboardingStepOf(String step, String total) {
    return 'Schritt $step von $total';
  }

  @override
  String get onboardingBack => 'Zurück';

  @override
  String get onboardingNext => 'Weiter';

  @override
  String get onboardingDone => 'Fertig';

  @override
  String get onboardingSearchLanguages => 'Sprachen suchen';

  @override
  String onboardingSelected(String languages) {
    return 'Ausgewählt: $languages';
  }

  @override
  String get onboardingNoLanguageMatch =>
      'Keine Sprache passt zu dieser Suche.';

  @override
  String get themeCreate => 'Design erstellen';

  @override
  String themeSelectedLabel(String name) {
    return '$name, ausgewählt';
  }

  @override
  String themeCardOptions(String name) {
    return 'Optionen für $name';
  }

  @override
  String get themeEdit => 'Bearbeiten';

  @override
  String get themeDuplicate => 'Duplizieren';

  @override
  String get themeRename => 'Umbenennen';

  @override
  String get themeDeleteAction => 'Löschen';

  @override
  String get themeTryTyping => 'Ausprobieren';

  @override
  String get themeTryLabel => 'Hier tippen, um das Design zu testen';

  @override
  String get themeTryHelper =>
      'Die Tastatur erscheint hier, wenn BooBoard ausgewählt ist.';

  @override
  String get themeRenameTitle => 'Design umbenennen';

  @override
  String get themeNameField => 'Name';

  @override
  String get themeEditTitle => 'Design bearbeiten';

  @override
  String get themeNewTitle => 'Neues Design';

  @override
  String get themeEditorTitle => 'Design';

  @override
  String get themeOpenFailed => 'Dieses Design konnte nicht geöffnet werden.';

  @override
  String get themeSaveFailed => 'Das Design konnte nicht gespeichert werden.';

  @override
  String get themePhotoPickerFailed =>
      'Die Fotoauswahl konnte nicht geöffnet werden.';

  @override
  String get themeDiscardTitle => 'Änderungen verwerfen?';

  @override
  String get themeDiscardBody =>
      'Deine Änderungen an diesem Design gehen verloren.';

  @override
  String get themeKeepEditing => 'Weiter bearbeiten';

  @override
  String get themeDiscard => 'Verwerfen';

  @override
  String get themeSave => 'Speichern';

  @override
  String get themeNameRequired => 'Ein Name ist erforderlich';

  @override
  String get themeNameLabel => 'Designname';

  @override
  String get themeDefaultName => 'Mein Design';

  @override
  String get themeSectionName => 'Name';

  @override
  String get themeSectionLook => 'Aussehen';

  @override
  String get themeDarkMode => 'Dunkelmodus';

  @override
  String get themeChoiceSystem => 'System';

  @override
  String get themeChoiceLight => 'Hell';

  @override
  String get themeChoiceDark => 'Dunkel';

  @override
  String get themePureBlack => 'Reines Schwarz';

  @override
  String get themePureBlackBody => 'Schwarzer Hintergrund';

  @override
  String get themePureBlackOnlyDark => 'Nur im Dunkelmodus';

  @override
  String get themeGalleryPureBlackDark =>
      'Schwarzer Hintergrund im Dunkelmodus';

  @override
  String get themeContrast => 'Kontrast';

  @override
  String get themeChoiceStandard => 'Standard';

  @override
  String get themeChoiceMedium => 'Mittel';

  @override
  String get themeChoiceHigh => 'Hoch';

  @override
  String get themeKeyboardHeight => 'Tastaturhöhe';

  @override
  String get themeSectionColours => 'Farben';

  @override
  String get themeSource => 'Quelle';

  @override
  String get themeSourceWallpaper => 'Hintergrundbild';

  @override
  String get themeSourceSeed => 'Basisfarbe';

  @override
  String get themeSourcePerRole => 'Pro Rolle';

  @override
  String get themeWallpaperNeedsAndroid12 =>
      'Wallpaper-Farben benötigen Android 12 oder neuer.';

  @override
  String get themeSeedColour => 'Basisfarbe';

  @override
  String get themeScheme => 'Schema';

  @override
  String get themeColourRoles => 'Farbrollen';

  @override
  String themeEditingColours(String mode) {
    String _temp0 = intl.Intl.selectLogic(mode, {
      'dark': 'Dunkle Farben werden bearbeitet',
      'other': 'Helle Farben werden bearbeitet',
    });
    return '$_temp0';
  }

  @override
  String get themeResetRoles => 'Alle Rollen zurücksetzen';

  @override
  String get themeKeys => 'Tasten';

  @override
  String get themeShape => 'Form';

  @override
  String get themeShapePill => 'Kapsel';

  @override
  String get themeShapeRounded => 'Abgerundet';

  @override
  String get themeShapeSquare => 'Eckig';

  @override
  String get themeKeyBorders => 'Tastenränder';

  @override
  String get themeBorderWidth => 'Randbreite';

  @override
  String get themeKeyGap => 'Tastenabstand';

  @override
  String get themeFontWeight => 'Schriftstärke';

  @override
  String get themeFontSize => 'Schriftgröße';

  @override
  String get themeHintCharacters => 'Hinweiszeichen';

  @override
  String get themeHintCharactersBody => 'Kleine Zeichen beim langen Drücken';

  @override
  String get themeBackground => 'Hintergrund';

  @override
  String get themeBackgroundType => 'Typ';

  @override
  String get themeTypeSolid => 'Einfarbig';

  @override
  String get themeTypeGradient => 'Verlauf';

  @override
  String get themeTypePhoto => 'Foto';

  @override
  String get themeNoPhotoYet =>
      'Noch kein Foto. Wähle eines aus, um es auf die Tastatur zuzuschneiden.';

  @override
  String get themeChoosePhoto => 'Foto wählen';

  @override
  String get themeEditCrop => 'Zuschnitt und Unschärfe bearbeiten';

  @override
  String get themeDim => 'Abdunkeln';

  @override
  String get themeSectionPopups => 'Pop-ups und Spur';

  @override
  String get themeSolidPopups => 'Einfarbige Pop-ups';

  @override
  String get themeSolidPopupsBodyWallpaper => 'Nicht mit Wallpaper-Farben';

  @override
  String get themeSolidPopupsBodyPrimary => 'Pop-ups in der Hauptfarbe';

  @override
  String get themeSwipeTrail => 'Wischspur';

  @override
  String get themeTrailWidth => 'Spurbreite';

  @override
  String get themeTrailFade => 'Spur-Ausblendung';

  @override
  String get themeTrailInstant => 'Sofort';

  @override
  String get themeTrailColours => 'Spurfarben';

  @override
  String get themeTrailStart => 'Anfang';

  @override
  String get themeTrailEnd => 'Ende';

  @override
  String get themeTrailStartTitle => 'Spuranfang';

  @override
  String get themeTrailEndTitle => 'Spurende';

  @override
  String get themeAutomatic => 'Automatisch';

  @override
  String get themeSectionMotion => 'Bewegung';

  @override
  String get themeKeyPressAnimation => 'Animation beim Tastendruck';

  @override
  String get themeReduceMotion =>
      '„Animationen entfernen“ ist in den Systemeinstellungen aktiv, daher werden Tasten nicht animiert.';

  @override
  String get themeMotionOff => 'Aus';

  @override
  String get themeMotionSubtle => 'Dezent';

  @override
  String get themeMotionStandard => 'Standard';

  @override
  String get themeMotionBouncy => 'Federnd';

  @override
  String get themeSchemeTonalSpot => 'Tonal-Spot';

  @override
  String get themeSchemeVibrant => 'Lebendig';

  @override
  String get themeSchemeExpressive => 'Ausdrucksstark';

  @override
  String get themeSchemeFidelity => 'Treue';

  @override
  String get themeSchemeContent => 'Inhalt';

  @override
  String get themeSchemeMonochrome => 'Monochrom';

  @override
  String get themeSchemeNeutral => 'Neutral';

  @override
  String get themeSchemeRainbow => 'Regenbogen';

  @override
  String get themeSchemeFruitSalad => 'Obstsalat';

  @override
  String themeCustomColourHex(String hex) {
    return 'Eigene Farbe #$hex';
  }

  @override
  String get themeCustomColour => 'Eigene Farbe';

  @override
  String themeSwatchLabel(String hex, String label) {
    return '$label-Farbe, #$hex';
  }

  @override
  String themeUseSchemeColour(String label) {
    return 'Die Schemafarbe für $label verwenden';
  }

  @override
  String get themeFromScheme => 'Aus dem Schema';

  @override
  String get themeOverridden => 'Festgelegt';

  @override
  String themeStopLabel(String n) {
    return 'Stopp $n';
  }

  @override
  String themePickStopTitle(String n) {
    return 'Stopp $n';
  }

  @override
  String get themeAddStop => 'Stopp hinzufügen';

  @override
  String get themeRemoveStop => 'Stopp entfernen';

  @override
  String get themeAngle => 'Winkel';

  @override
  String get themeUseSchemeTooltipLabel => 'Schemafarbe verwenden';

  @override
  String get themeCropTitle => 'Foto zuschneiden';

  @override
  String get themeUsePhoto => 'Foto verwenden';

  @override
  String get themeCropSaveFailed => 'Das Foto konnte nicht gespeichert werden.';

  @override
  String get themeCropSemantics =>
      'Fotozuschnitt. Ziehen, um das Foto zu verschieben, und mit zwei Fingern oder dem Zoomregler vergrößern.';

  @override
  String get themeCropZoom => 'Zoom';

  @override
  String get themeCropBlur => 'Unschärfe';

  @override
  String get themeCropBlurOff => 'Aus';

  @override
  String get themeCropNote =>
      'Die Unschärfe wird im Bild gespeichert. Die Abdunklung wird im Editor eingestellt und sofort angewendet.';

  @override
  String get themeHexLabel => 'Hex';

  @override
  String get themeHexError => 'Verwende sechs Hex-Ziffern, zum Beispiel F5B700';

  @override
  String get themeHue => 'Farbton';

  @override
  String get themeSaturation => 'Sättigung';

  @override
  String get themeBrightness => 'Helligkeit';

  @override
  String get themePickShadeHint =>
      'Wähle einen Farbton und tippe dann auf Verwenden.';

  @override
  String get themePickColourUse => 'Verwenden';

  @override
  String get themeCopySuffix => 'Kopie';

  @override
  String themeCopyName(String name) {
    return 'Kopie von $name';
  }

  @override
  String themeDeleteTitle(String name) {
    return '„$name“ löschen?';
  }

  @override
  String get themeDeleteSelectedBody =>
      'Dieses Design ist ausgewählt. Stattdessen wird BooBoard Dynamic verwendet. Das kann nicht rückgängig gemacht werden.';

  @override
  String get themeDeleteBody => 'Das kann nicht rückgängig gemacht werden.';

  @override
  String get themeDeleteFailed => 'Das Design konnte nicht gelöscht werden.';

  @override
  String get themeRenameFailed => 'Das Design konnte nicht umbenannt werden.';

  @override
  String get themeDuplicateFailed => 'Das Design konnte nicht kopiert werden.';

  @override
  String get themeSettingFailed =>
      'Die Einstellung konnte nicht gespeichert werden.';

  @override
  String get themeSystemColoursUnavailable =>
      'Systemfarben sind nicht verfügbar.';

  @override
  String get themeBooBoardDynamicFollows =>
      'BooBoard Dynamic folgt deinem Hintergrundbild';

  @override
  String get themeBooBoardDynamicBody =>
      'Seine Farben aktualisieren sich, wenn sich das Hintergrundbild ändert';

  @override
  String get themeSectionPresets => 'Voreinstellungen';

  @override
  String get themeSectionMyThemes => 'Meine Designs';

  @override
  String get themeSectionTry => 'Ausprobieren';

  @override
  String get themeAppearance => 'Erscheinungsbild';

  @override
  String get themesTitle => 'Designs';

  @override
  String privacyThemesSize(int count, String size) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Designdateien',
      one: '1 Designdatei',
    );
    return '$_temp0 · $size';
  }

  @override
  String get backupUnlockToSeeCount =>
      'Entsperre dein Gerät, um die Anzahl zu sehen';

  @override
  String get shortcutHelp =>
      'Ein Kürzel macht aus einer Kurzform einen längeren Text. Beispiele:\nomw → on my way\naddr → your address';

  @override
  String privacyStoredLearned(String language) {
    return 'Gelernte Wörter ($language)';
  }

  @override
  String get settingsComingLater => 'Kommt in einem späteren Update';

  @override
  String get backupExplainer =>
      'Ein Backup ist eine einzelne Datei, verschlüsselt mit einer Passphrase deiner Wahl. Nur diese Passphrase öffnet sie. Wenn du die Passphrase vergisst, kann niemand das Backup wiederherstellen, auch BooBoard nicht.';

  @override
  String privacyCategoryLine(String detail, String title) {
    return '$title: $detail';
  }

  @override
  String get shortcutShortFormHint => 'omw';

  @override
  String get shortcutExpansionHint => 'unterwegs';

  @override
  String get durationMinutes15 => '15 Minuten';

  @override
  String get durationHour => '1 Stunde';

  @override
  String get durationDay => '1 Tag';

  @override
  String get durationWeek => '1 Woche';

  @override
  String get onboardingCloseSetup => 'Einrichtung schließen';

  @override
  String get packsCouldNotRead => 'BooBoard konnte seine Pakete nicht lesen';

  @override
  String packsDeleteTooltip(String name) {
    return '$name löschen';
  }

  @override
  String get privacyNothingStored => 'Noch nichts gespeichert';

  @override
  String privacyRemoveAppTooltip(String app) {
    return '$app aus der Liste entfernen';
  }

  @override
  String get chineseTitle => 'Chinesisch';

  @override
  String get chineseTraditional => 'Traditionelle Schriftzeichen';

  @override
  String get chineseTraditionalBody =>
      'Kandidaten in traditionellen Schriftzeichen anzeigen (Taiwan-Standard).';

  @override
  String get chineseFuzzy => 'Unscharfes Pinyin';

  @override
  String get chineseFuzzyBody =>
      'Akzeptiert auch z und zh, c und ch, s und sh, n und l, an und ang, en und eng, in und ing.';

  @override
  String get cjkDictionary => 'Wörterbuch';

  @override
  String get chineseClearPhrases => 'Gelernte Wendungen löschen';

  @override
  String get chineseClearPhrasesBody =>
      'Vergisst die gewählten Wörter. Das Wörterbuch bleibt.';

  @override
  String get chineseFooter =>
      'Chinesisch wird auf diesem Telefon eingegeben. Gelernte Wendungen sind verschlüsselt und verlassen es nie.';

  @override
  String get chineseClearTitle => 'Gelernte Wendungen löschen?';

  @override
  String get chineseClearBody =>
      'Die für Chinesisch gewählten Wörter werden entfernt. Das lässt sich nicht rückgängig machen.';

  @override
  String get cjkClear => 'Löschen';

  @override
  String get chinesePhrasesCleared => 'Gelernte Wendungen gelöscht';

  @override
  String get chineseLooking => 'Wörterbuch wird gesucht';

  @override
  String get chineseDictName => 'Chinesisches Wörterbuch';

  @override
  String get chinesePackMissing =>
      'Nicht installiert. Die chinesische Eingabe braucht es; installiere es unter Modellpakete.';

  @override
  String chinesePackInstalled(String license) {
    return 'Installiert. $license';
  }

  @override
  String get japaneseTitle => 'Japanisch';

  @override
  String get japaneseLayout => 'Layout';

  @override
  String get japaneseLayout12 => '12 Tasten (Wischen)';

  @override
  String get japaneseLayoutRomaji => 'Romaji (QWERTY)';

  @override
  String get japaneseTyping => 'Eingabe';

  @override
  String get japaneseFlickOnly => 'Nur Wischen';

  @override
  String get japaneseFlickOnlyBody =>
      'Kein Mehrfachtippen: zweimal あ tippen ergibt ああ, nicht い';

  @override
  String get japaneseHalfWidth => 'Halbbreites Leerzeichen';

  @override
  String get japaneseHalfWidthBody =>
      'Die Leertaste gibt ein normales Leerzeichen, wenn nichts eingegeben wird. Aus gibt ein vollbreites Leerzeichen.';

  @override
  String get japaneseDictPack => 'Wörterbuchpaket';

  @override
  String get japaneseChecking => 'Wird geprüft...';

  @override
  String japaneseInstalled(String name) {
    return '$name ist installiert. Kanji-Umwandlung ist aktiv.';
  }

  @override
  String get japaneseNotInstalled =>
      'Nicht installiert. Kana lassen sich weiter tippen; Kanji brauchen das Paket.';

  @override
  String get japaneseClearWords => 'Gelernte Wörter löschen';

  @override
  String get japaneseClearWordsBody =>
      'Vergisst die gewählten japanischen Wörter. Verschlüsselt auf diesem Telefon gespeichert.';

  @override
  String get japaneseClearTitle => 'Gelernte japanische Wörter löschen?';

  @override
  String get japaneseClearBody =>
      'Alle gewählten japanischen Wörter werden gelöscht. Das lässt sich nicht rückgängig machen.';

  @override
  String get privacyStoredChinesePhrases => 'Chinesische Wendungen';

  @override
  String get privacyStoredJapaneseWords => 'Japanische Wörter';
}
