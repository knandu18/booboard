// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get appName => 'BooBoard';

  @override
  String get homeTagline => 'Saisie privée, sur ce téléphone';

  @override
  String get homeOfflinePromise =>
      'BooBoard fonctionne hors ligne et n\'envoie *rien nulle part.*';

  @override
  String get cancel => 'Annuler';

  @override
  String get delete => 'Supprimer';

  @override
  String get save => 'Enregistrer';

  @override
  String get useAction => 'Utiliser';

  @override
  String get off => 'Désactivé';

  @override
  String get left => 'Gauche';

  @override
  String get right => 'Droite';

  @override
  String get settingsLanguages => 'Langues';

  @override
  String get settingsTyping => 'Saisie';

  @override
  String get settingsFeel => 'Ressenti';

  @override
  String get settingsThemes => 'Thèmes';

  @override
  String get settingsPanels => 'Panneaux';

  @override
  String get settingsVoice => 'Voix';

  @override
  String get settingsTranslation => 'Traduction';

  @override
  String get settingsPrivacy => 'Confidentialité';

  @override
  String get settingsAbout => 'À propos';

  @override
  String get settingsModelPacks => 'Packs de modèles';

  @override
  String get homeSetupTurnOn =>
      'Activez BooBoard dans la liste des claviers d\'Android.';

  @override
  String get homeSetupChoose => 'Choisissez BooBoard comme clavier de saisie.';

  @override
  String get homeFinishSetup => 'Terminer la configuration de BooBoard';

  @override
  String get homeTypingSubtitle =>
      'Corrections, suggestions, touches et glissement';

  @override
  String get homeFeelSubtitle => 'Vibrations, sons, hauteur et mode une main';

  @override
  String get homePanelsSubtitle => 'Presse-papiers et emoji';

  @override
  String get homeVoiceSubtitle => 'Parlez pour écrire, sur ce téléphone';

  @override
  String get homeTranslationSubtitle => 'Traduit pendant la frappe, hors ligne';

  @override
  String get homePrivacySubtitle =>
      'Ce qui est stocké, incognito, verrouillage et sauvegarde';

  @override
  String get homeAboutSubtitle => 'Version, licences et code source';

  @override
  String get homeImages => 'Images';

  @override
  String get homeAboutBooBoard => 'À propos de BooBoard';

  @override
  String get websiteOpenHint => 'Ouvre booboard.com dans votre navigateur';

  @override
  String get websiteNoBrowser =>
      'Aucun navigateur ne peut ouvrir booboard.com.';

  @override
  String get imagesSoonTitle => 'Les images *arrivent*';

  @override
  String get imagesSoonBody =>
      'Créez des images à partir de vos mots, directement sur ce téléphone. Comme tout dans BooBoard, cela fonctionnera hors ligne.';

  @override
  String get aboutWebsite => 'Site web';

  @override
  String get aboutTitle => 'À propos';

  @override
  String aboutVersion(String versionCode, String versionName) {
    return 'Version $versionName ($versionCode)';
  }

  @override
  String aboutVersionDebug(String versionCode, String versionName) {
    return 'Version $versionName ($versionCode) · version de débogage';
  }

  @override
  String get aboutReadingVersion => 'Lecture de la version…';

  @override
  String get aboutPrivacy => 'Confidentialité';

  @override
  String get aboutNoInternet => 'BooBoard ne peut pas utiliser Internet';

  @override
  String get aboutNoInternetBody =>
      'Les versions publiées n\'ont pas l\'autorisation Internet : rien de ce que vous saisissez ne quitte ce téléphone.';

  @override
  String get aboutLicence => 'Licence';

  @override
  String get aboutGplTitle => 'Licence publique générale GNU v3 ou ultérieure';

  @override
  String get aboutGplBody =>
      'BooBoard est un logiciel libre. Vous pouvez l\'étudier, le modifier et le partager selon la GPL.';

  @override
  String get aboutSourceCode => 'Code source';

  @override
  String get aboutSourceBody =>
      'BooBoard est sous GPL-3.0-or-later. Son code source est disponible sur la page du projet.';

  @override
  String get aboutLicences => 'Licences';

  @override
  String get aboutOpenSource => 'Licences open source';

  @override
  String get aboutOpenSourceBody =>
      'Flutter, material_ui et chaque paquet utilisé par BooBoard';

  @override
  String get aboutTextLoadFailed => 'Ce texte n\'a pas pu être chargé.';

  @override
  String get languagesEnabledHeader =>
      'Activées ; la première est celle par défaut';

  @override
  String get languagesActive => 'Langue active';

  @override
  String get languagesAdd => 'Ajouter une langue';

  @override
  String get languagesAllEnabled => 'Toutes les langues sont activées';

  @override
  String get languagesAllEnabledBody =>
      'Retirez-en une ci-dessus pour faire de la place.';

  @override
  String get languagesMultilingual => 'Saisie multilingue';

  @override
  String get languagesMultilingualBody =>
      'Suggère des mots issus d\'au plus trois langues activées qui partagent l\'écriture du clavier. Un mot connu de l\'une d\'elles n\'est jamais corrigé automatiquement.';

  @override
  String get languagesNativeDigits => 'Chiffres natifs';

  @override
  String get languagesNativeDigitsBody =>
      'Saisit les chiffres dans l\'écriture de la langue active lorsqu\'elle en a (०१२, ٠١٢).';

  @override
  String get languagesOptions => 'Options de langue';

  @override
  String get languagesZhSubtitle =>
      'Pinyin, caractères traditionnels et paquets de dictionnaires';

  @override
  String get languagesJaSubtitle =>
      'Saisie par glissement, conversion et paquets de dictionnaires';

  @override
  String languagesReorderLabel(String language) {
    return 'Faites glisser pour réordonner $language';
  }

  @override
  String languageDefaultLabel(String language) {
    return '$language, par défaut';
  }

  @override
  String languageLayoutTooltip(String language) {
    return 'Disposition pour $language';
  }

  @override
  String languageRemoveTooltip(String language) {
    return 'Retirer $language';
  }

  @override
  String get feelHaptics => 'Haptique';

  @override
  String get feelHapticFeedback => 'Retour haptique';

  @override
  String get feelHapticFeedbackBody =>
      'Une courte vibration à chaque touche, selon le réglage du système';

  @override
  String get feelHapticStrength => 'Intensité haptique';

  @override
  String get feelSounds => 'Sons';

  @override
  String get feelKeySounds => 'Sons des touches';

  @override
  String get feelKeySoundsBody =>
      'Clics pour les touches, espace, effacer et entrée';

  @override
  String get feelUseSystemVolume => 'Utiliser le volume du système';

  @override
  String get feelKeySoundVolume => 'Volume des sons de touche';

  @override
  String get feelHeight => 'Hauteur';

  @override
  String get feelPortraitHeight => 'Hauteur en portrait';

  @override
  String get feelLandscapeHeight => 'Hauteur en paysage';

  @override
  String get feelOneHandedFloating => 'Une main et flottant';

  @override
  String get feelOneHandedSide => 'Côté du mode une main';

  @override
  String get feelFloatingKeyboard => 'Clavier flottant';

  @override
  String get feelFloatingBody => 'Faites-le glisser n\'importe où sur l\'écran';

  @override
  String get panelsClipboard => 'Presse-papiers';

  @override
  String get panelsClipboardHistory => 'Historique du presse-papiers';

  @override
  String get panelsClipboardHistoryBody =>
      'Garde ce que vous copiez, chiffré sur ce téléphone';

  @override
  String get panelsRecentChip => 'Pastille de copie récente';

  @override
  String get panelsRecentChipBody =>
      'Propose votre dernière copie dans la barre de suggestions pendant une minute';

  @override
  String get panelsKeepUnpinned => 'Garder les copies non épinglées pendant';

  @override
  String get panelsClipsToKeep => 'Clips à conserver';

  @override
  String get panelsEmoji => 'Emoji';

  @override
  String get emojiSuggestions => 'Suggestions d\'emoji';

  @override
  String get emojiSuggestionsPanelBody =>
      'Propose un emoji pour certains mots dans la barre de suggestions';

  @override
  String get panelsPasswordsNeverSaved =>
      'Les mots de passe ne sont jamais enregistrés';

  @override
  String get panelsSensitiveBody =>
      'Les copies qu\'Android marque comme sensibles ne sont jamais conservées.';

  @override
  String get typingCorrections => 'Corrections';

  @override
  String get typingAutocorrect => 'Correction automatique';

  @override
  String get typingAutocorrectBody =>
      'Corrige les fautes probables à la fin d\'un mot';

  @override
  String get typingAutoCapitalise => 'Majuscules automatiques';

  @override
  String get typingAutoCapitaliseBody => 'Majuscules au début des phrases';

  @override
  String get typingDoubleSpace => 'Double espace pour le point';

  @override
  String get typingDoubleSpaceBody => 'Deux appuis sur espace écrivent « . »';

  @override
  String get typingSmartPunctuation => 'Ponctuation intelligente';

  @override
  String get typingSmartPunctuationBody =>
      'Ajuste les espaces autour de la ponctuation et utilise les guillemets locaux';

  @override
  String get typingSuggestions => 'Suggestions';

  @override
  String get typingSuggestionsBody =>
      'Affiche des mots dans la barre de suggestions';

  @override
  String get typingNextWord => 'Prédiction du mot suivant';

  @override
  String get typingNextWordBody => 'Suggère le mot qui suit souvent';

  @override
  String get typingEmojiBody => 'Propose un emoji pour certains mots';

  @override
  String get typingHideOffensive => 'Masquer les mots offensants';

  @override
  String get typingHideOffensiveBody =>
      'Ne jamais les suggérer, sauf si vous les tapez en entier';

  @override
  String get typingKeys => 'Touches';

  @override
  String get typingKeyPopups => 'Bulles des touches';

  @override
  String get typingKeyPopupsBody => 'Agrandit une touche pendant l\'appui';

  @override
  String get typingLongPressDelay => 'Délai d\'appui long';

  @override
  String get typingNumberRow => 'Rangée de chiffres';

  @override
  String get typingNumberRowBody => 'Affiche de 0 à 9 au-dessus des lettres';

  @override
  String get typingHintLabels => 'Indications sur les touches';

  @override
  String get typingHintLabelsBody =>
      'Petits symboles sur les touches, comme les accents';

  @override
  String get typingLowercaseLabels => 'Étiquettes en minuscules';

  @override
  String get typingLowercaseLabelsBody =>
      'Garde les lettres en minuscules quand Maj est activé';

  @override
  String get typingSwipe => 'Glissement';

  @override
  String get typingSwipeTyping => 'Saisie par glissement';

  @override
  String get typingSwipeTypingBody =>
      'Glissez sur les lettres pour écrire un mot';

  @override
  String get typingShowTrail => 'Afficher la trace';

  @override
  String get typingTrailWidth => 'Largeur de la trace';

  @override
  String get typingTrailFade => 'Estompage de la trace';

  @override
  String get typingLivePreview => 'Aperçu en direct';

  @override
  String get typingLivePreviewBody =>
      'Affiche le mot probable pendant le glissement';

  @override
  String get typingSpaceMovesCursor => 'La barre d\'espace déplace le curseur';

  @override
  String get typingSpaceMovesCursorBody =>
      'Faites glisser sur la barre d\'espace pour déplacer le curseur';

  @override
  String get typingSwipeBackspace =>
      'Glisser sur effacer pour supprimer des mots';

  @override
  String get typingSwipeBackspaceBody =>
      'Glissez vers la gauche sur effacer pour sélectionner et supprimer des mots';

  @override
  String get voiceTyping => 'Saisie vocale';

  @override
  String get voiceTypingBody =>
      'Parlez en anglais pour écrire. La reconnaissance se fait sur ce téléphone.';

  @override
  String get voiceRecognition => 'Reconnaissance';

  @override
  String get voiceModelPacksBody =>
      'Installer ou supprimer les packs de voix et de traduction';

  @override
  String get voiceAudioStays =>
      'L\'audio reste sur ce téléphone et n\'est jamais enregistré.';

  @override
  String get voicePackAutomatic => 'Automatique';

  @override
  String get voicePackAutomaticSelected => 'Automatique (sélectionné)';

  @override
  String get voicePack => 'Pack de voix';

  @override
  String get voiceNoPack =>
      'Aucun pack de voix installé. Installez-en un dans Packs de modèles.';

  @override
  String get voiceLooking => 'Recherche des packs installés';

  @override
  String voicePackItem(String name, String size) {
    return '$name · $size';
  }

  @override
  String voicePackItemSelected(String name, String size) {
    return '$name · $size (sélectionné)';
  }

  @override
  String megabytes(num count) {
    return '$count Mo';
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
      'BooBoard n\'a pas pu ouvrir le sélecteur de fichiers.';

  @override
  String packsInstalled(String name) {
    return '$name installé.';
  }

  @override
  String packsDeleteTitle(String name) {
    return 'Supprimer $name ?';
  }

  @override
  String get packsDeleteBody =>
      'Ses fichiers sont supprimés de ce téléphone. Vous pourrez réimporter le paquet plus tard à partir de son fichier.';

  @override
  String packsDeleted(String name) {
    return '$name supprimé.';
  }

  @override
  String packsDeleteFailed(String name) {
    return 'BooBoard n\'a pas pu supprimer $name. Réessayez.';
  }

  @override
  String get packsIntro =>
      'Les packs sont vérifiés avant d\'être installés. Ils ne contiennent que des données, jamais du code.';

  @override
  String get packsImport => 'Importer';

  @override
  String get packsImportTitle => 'Importer un fichier de pack';

  @override
  String get packsChecking => 'Vérification et installation…';

  @override
  String get packsImportBody =>
      'Un fichier .boopack, par exemple depuis Téléchargements';

  @override
  String get packsNoVoice => 'Aucun pack de voix installé';

  @override
  String get packsNoVoiceBody => 'La saisie vocale nécessite un pack de voix.';

  @override
  String get packsNoTranslation => 'Aucun pack de traduction installé';

  @override
  String get packsNoTranslationBody =>
      'La traduction nécessite un pack par sens.';

  @override
  String get packsDictionaries => 'Dictionnaires';

  @override
  String get packsNoDictionary => 'Aucun pack de dictionnaire installé';

  @override
  String get packsNoDictionaryBody =>
      'La saisie en chinois et en japonais nécessite un pack de dictionnaire.';

  @override
  String get packsGetTitle => 'Obtenir des paquets';

  @override
  String get packsExplainTitle =>
      'Les paquets sont des fichiers que vous ajoutez vous-même.';

  @override
  String get packsExplainBody =>
      'Téléchargez-les depuis la page de publication du projet sur un autre appareil, copiez-les sur ce téléphone, puis importez-les.';

  @override
  String get packsCopyLink => 'Copier le lien de la page de publication';

  @override
  String get packsPrivateTitle => 'Des téléchargements qui restent privés';

  @override
  String get packsPrivateBody =>
      'BooBoard n\'a pas l\'autorisation d\'accès à internet et ne se connecte jamais. Télécharger ouvre votre navigateur, qui récupère le pack depuis la publication GitHub du projet. BooBoard vérifie ensuite la signature du pack sur ce téléphone avant d\'installer quoi que ce soit.';

  @override
  String get packsAvailableTitle => 'Packs que vous pouvez ajouter';

  @override
  String get packsDownload => 'Télécharger';

  @override
  String packsDownloadMeta(String size) {
    return '$size · ouvre votre navigateur';
  }

  @override
  String packsDownloadStarted(String name) {
    return 'Votre navigateur télécharge $name. Une fois terminé, touchez Importer un fichier de pack.';
  }

  @override
  String get packsNoBrowser =>
      'Aucun navigateur ne peut ouvrir le lien. Copiez plutôt le lien de la page des publications.';

  @override
  String get packsImportCheckedBody =>
      'Choisissez le fichier .boopack téléchargé. Il est vérifié sur ce téléphone, puis installé.';

  @override
  String get packsAllInstalled => 'Tous les packs publiés sont installés.';

  @override
  String get packsLinkCopied => 'Lien copié. Ouvrez-le sur un autre appareil.';

  @override
  String get packsPlayTitle => 'Obtenir via Google Play';

  @override
  String get packsPlayNote =>
      'Google Play télécharge ces paquets, pas BooBoard. BooBoard n\'utilise jamais le réseau.';

  @override
  String get packsGet => 'Obtenir';

  @override
  String get packsStatusNotRequested => 'Pas encore téléchargé';

  @override
  String get packsStatusWaiting => 'En attente de Wi-Fi ou de données mobiles';

  @override
  String get packsStatusDownloading => 'Téléchargement via Google Play';

  @override
  String get packsStatusInstalling => 'Vérification et installation';

  @override
  String get packsStatusFailed =>
      'Google Play n\'a pas pu le fournir. Réessayez.';

  @override
  String packsOfferMeta(Object size, Object status) {
    return '$size · $status';
  }

  @override
  String get packsVerifyTitle => 'Vérifier les paquets installés';

  @override
  String get packsVerifyBody =>
      'Vérifie chaque fichier de chaque paquet installé par rapport à sa liste signée. Rien n\'est modifié.';

  @override
  String packsVerifyOk(Object count) {
    return '$count paquets installés vérifiés. Tous les fichiers correspondent.';
  }

  @override
  String packsVerifyDamaged(Object count) {
    return '$count paquets installés ont des fichiers endommagés ou manquants. Supprimez-les et importez-les à nouveau.';
  }

  @override
  String get packsVerifyUnavailable =>
      'La vérification des paquets n\'est pas disponible dans cette version de BooBoard.';

  @override
  String get packsVerifyFailed =>
      'BooBoard n\'a pas pu vérifier les paquets. Rien n\'a été modifié.';

  @override
  String packsFreeSpace(Object size) {
    return '$size libres sur ce téléphone.';
  }

  @override
  String get packsNothingStored => 'Rien n\'est encore stocké.';

  @override
  String packsInstalledUse(String size) {
    return 'Les packs installés occupent $size sur ce téléphone.';
  }

  @override
  String get packErrorBadSignature =>
      'Ce pack n\'est pas signé pour BooBoard : rien n\'a été installé.';

  @override
  String get packErrorBadFormat =>
      'Ce fichier n\'est pas un pack BooBoard. Rien n\'a été installé.';

  @override
  String get packErrorTooLarge =>
      'Ce pack est trop volumineux pour ce téléphone.';

  @override
  String get packErrorVersion =>
      'Ce pack nécessite une version plus récente de BooBoard.';

  @override
  String get packErrorNoSpace =>
      'Il n\'y a pas assez d\'espace libre pour installer ce pack.';

  @override
  String get packErrorGeneric =>
      'Le pack n\'a pas pu être installé. Rien n\'a été modifié.';

  @override
  String get translateDefaultPair => 'Paire de langues par défaut';

  @override
  String translatePairName(String from, String to) {
    return '$from → $to';
  }

  @override
  String get translateOffline => 'Traduction hors ligne';

  @override
  String get translateOfflineBody =>
      'Traduit pendant la frappe au clavier, et le texte sélectionné dans toute appli.';

  @override
  String get translateDefaultPairTile => 'Paire par défaut';

  @override
  String get translatePackInstalled => 'Pack installé';

  @override
  String get translatePackNotInstalled =>
      'Pack non installé. Obtenez-le dans Packs de modèles.';

  @override
  String get translateInstalled => 'Sens installés';

  @override
  String get translateInstalledBody =>
      'Chaque sens est un pack, par exemple anglais → espagnol.';

  @override
  String translatePackMeta(String license, String size) {
    return '$size · $license';
  }

  @override
  String get translateModelPacksBody =>
      'Installer ou supprimer les packs de traduction';

  @override
  String get translateRunsOnPhone =>
      'La traduction se fait sur ce téléphone. Rien de ce que vous traduisez n\'est enregistré.';

  @override
  String get privacyUnlockReason =>
      'Déverrouillez BooBoard pour voir vos réglages et données';

  @override
  String get privacyLockUnavailable =>
      'Le verrouillage de l\'appareil n\'est pas disponible pour le moment. Réessayez dans un instant.';

  @override
  String get privacyLockedTitle => 'BooBoard est verrouillé';

  @override
  String get privacyLockedBody =>
      'Déverrouillez avec votre empreinte ou le code de votre appareil pour continuer.';

  @override
  String get privacyUnlock => 'Déverrouiller';

  @override
  String backupSaved(String size) {
    return 'Sauvegarde enregistrée ($size). Gardez votre phrase de passe en lieu sûr.';
  }

  @override
  String get backupUnlockRetrySaved =>
      'Déverrouillez le téléphone, puis réessayez. Rien n\'a été enregistré.';

  @override
  String get backupSaveFailed =>
      'La sauvegarde n\'a pas pu être enregistrée. Rien n\'a été modifié.';

  @override
  String get backupCheckFailed =>
      'Le fichier enregistré n\'a pas pu être vérifié et est peut-être endommagé. Enregistrez à nouveau la sauvegarde dans un nouveau fichier.';

  @override
  String get backupWrongPassphrase =>
      'Phrase de passe incorrecte ou fichier endommagé. Rien n\'a été modifié.';

  @override
  String get backupInvalidFile =>
      'Ce fichier n\'est pas une sauvegarde BooBoard valide. Rien n\'a été modifié.';

  @override
  String get backupTooLarge =>
      'Ce fichier est trop volumineux pour être une sauvegarde BooBoard.';

  @override
  String get backupNewerVersion =>
      'Cette sauvegarde a été faite par une version plus récente de BooBoard. Mettez BooBoard à jour pour la restaurer.';

  @override
  String get backupBusy =>
      'Fermez d\'abord l\'autre fenêtre de fichiers, puis réessayez.';

  @override
  String get backupOpenFailed =>
      'La sauvegarde n\'a pas pu être ouverte. Rien n\'a été modifié.';

  @override
  String get backupEmpty => 'Cette sauvegarde est vide.';

  @override
  String get backupRestoreTitle => 'Restaurer la sauvegarde';

  @override
  String backupMadeBy(String date, String version) {
    return 'Créée le $date avec BooBoard $version.';
  }

  @override
  String get backupMerge => 'Fusionner';

  @override
  String get backupMergeBody =>
      'Garde ce qui est sur ce téléphone et ajoute ce qui est dans la sauvegarde.';

  @override
  String get backupReplace => 'Remplacer';

  @override
  String get backupReplaceBody =>
      'Fait correspondre les sections choisies à la sauvegarde. Les données actuelles sont d\'abord supprimées.';

  @override
  String get commonContinue => 'Continuer';

  @override
  String get backupReplaceTitle => 'Remplacer les données de ce téléphone ?';

  @override
  String get backupReplaceConfirm =>
      'Les sections choisies sur ce téléphone sont supprimées et remplacées. Action irréversible.';

  @override
  String get backupPrivacyChangesTitle =>
      'Cette sauvegarde modifie vos réglages de confidentialité';

  @override
  String get backupPrivacyChangesBody =>
      'La restauration des réglages modifiera ces réglages de confidentialité sur ce téléphone. Vérifiez-les avant de continuer.';

  @override
  String backupPrivacyChangeLine(String setting, String from, String to) {
    return '$setting : $from → $to';
  }

  @override
  String get backupStateOn => 'Activé';

  @override
  String backupAppsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count applis',
      one: '1 appli',
    );
    return '$_temp0';
  }

  @override
  String get backupRestoreAndChange => 'Restaurer et modifier';

  @override
  String get backupUnlockRetryChanged =>
      'Déverrouillez le téléphone, puis réessayez. Rien n\'a été modifié.';

  @override
  String get backupRestoreFailed =>
      'BooBoard n\'a pas pu terminer la restauration. Certaines données n\'ont peut-être pas été écrites.';

  @override
  String get restoreNothingNew => 'Rien de nouveau n\'a été restauré.';

  @override
  String restoreSummary(String items) {
    return 'Restauré : $items.';
  }

  @override
  String restoreSummarySkipped(String added, String skipped) {
    return '$added Ignoré : $skipped.';
  }

  @override
  String restoreLearnedFor(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count langues',
      one: '1 langue',
    );
    return 'mots appris pour $_temp0';
  }

  @override
  String countFiles(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count fichiers',
      one: '1 fichier',
    );
    return '$_temp0';
  }

  @override
  String countWords(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count mots',
      one: '1 mot',
    );
    return '$_temp0';
  }

  @override
  String countLanguages(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count langues',
      one: '1 langue',
    );
    return '$_temp0';
  }

  @override
  String countShortcuts(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count raccourcis',
      one: '1 raccourci',
    );
    return '$_temp0';
  }

  @override
  String countClipboardItems(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count éléments du presse-papiers',
      one: '1 élément du presse-papiers',
    );
    return '$_temp0';
  }

  @override
  String countThemeFiles(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count fichiers de thème',
      one: '1 fichier de thème',
    );
    return '$_temp0';
  }

  @override
  String countPinnedItems(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count éléments épinglés',
      one: '1 élément épinglé',
    );
    return '$_temp0';
  }

  @override
  String countPacks(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count packs',
      one: '1 pack',
    );
    return '$_temp0';
  }

  @override
  String countBlockedWords(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count mots bloqués',
      one: '1 mot bloqué',
    );
    return '$_temp0';
  }

  @override
  String countTimes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count fois',
      one: '1 fois',
    );
    return '$_temp0';
  }

  @override
  String timeMinutesAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'il y a $count minutes',
      one: 'il y a 1 minute',
    );
    return '$_temp0';
  }

  @override
  String timeHoursAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'il y a $count heures',
      one: 'il y a 1 heure',
    );
    return '$_temp0';
  }

  @override
  String timeDaysAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'il y a $count jours',
      one: 'il y a 1 jour',
    );
    return '$_temp0';
  }

  @override
  String get timeJustNow => 'à l\'instant';

  @override
  String get languagePortuguese => 'Portugais';

  @override
  String packMeta(String languages, String license, String size) {
    return '$languages · $size · $license';
  }

  @override
  String privacyLearnedWordsTitle(String language) {
    return 'Mots appris ($language)';
  }

  @override
  String privacyClearLanguageTitle(String language) {
    return 'Effacer les mots de $language ?';
  }

  @override
  String get privacyClearLanguageBody =>
      'Cela supprime tous les mots appris dans cette langue, ainsi que les mots bloqués. Action irréversible.';

  @override
  String get privacyClear => 'Effacer';

  @override
  String get privacySaveFailed =>
      'Impossible d\'enregistrer la modification. Réessayez.';

  @override
  String get privacyCouldNotReadWords => 'BooBoard n\'a pas pu lire ces mots.';

  @override
  String get privacyCannotReadWordsNow =>
      'BooBoard ne peut pas lire ces mots pour le moment. Déverrouillez le téléphone, puis réessayez.';

  @override
  String get privacyNoWordsLanguage =>
      'Aucun mot appris dans cette langue pour l\'instant. BooBoard apprend un mot après l\'avoir tapé plusieurs fois.';

  @override
  String privacyBlockedWordsTooltip(num count) {
    return 'Mots bloqués ($count)';
  }

  @override
  String get privacySortTooltip => 'Trier';

  @override
  String get privacySortMostUsed => 'Les plus utilisés d\'abord';

  @override
  String get privacySortAZ => 'De A à Z';

  @override
  String get privacyMoreTooltip => 'Plus';

  @override
  String get privacyClearThisLanguage => 'Effacer cette langue';

  @override
  String get privacySearchWords => 'Rechercher des mots';

  @override
  String privacyWordsSummary(String blocked, String words) {
    return '$words · $blocked';
  }

  @override
  String get privacyNoWordsYet => 'Aucun mot pour l\'instant.';

  @override
  String privacyNoWordsMatch(String query) {
    return 'Aucun mot ne correspond à « $query ».';
  }

  @override
  String get privacyNeverSuggested => 'Jamais suggérés';

  @override
  String get privacyBlockedExplain =>
      'BooBoard ne suggérera ni ne corrigera ces mots.';

  @override
  String get privacyNoBlockedWords => 'Aucun mot bloqué.';

  @override
  String get privacyAllowAgain => 'Autoriser à nouveau';

  @override
  String privacyWordLastUsed(int count, String when) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count fois',
      one: 'une fois',
    );
    return 'Tapé $_temp0 · dernière fois $when';
  }

  @override
  String privacyWordNotYetSuggested(String when) {
    return 'Tapé une fois jusqu\'ici, pas encore suggéré · dernière fois $when';
  }

  @override
  String get privacyToday => 'aujourd\'hui';

  @override
  String get privacyYesterday => 'hier';

  @override
  String privacyActionsFor(String word) {
    return 'Actions pour $word';
  }

  @override
  String get privacyForgetWord => 'Oublier ce mot';

  @override
  String get privacyNeverSuggestWord => 'Ne jamais suggérer ce mot';

  @override
  String get privacyTryAgain => 'Réessayer';

  @override
  String get privacyCenterLoadFailed =>
      'BooBoard n\'a pas pu lire ses données de confidentialité. Réessayez plus tard.';

  @override
  String get privacyDevBuildNetwork =>
      'Cette version demande l\'accès à Internet. BooBoard ne devrait jamais le faire. Merci de le signaler.';

  @override
  String get privacyNoInternetPermission =>
      'BooBoard n\'a pas l\'autorisation Internet. Il ne peut rien envoyer.';

  @override
  String get privacyDevBuildNote =>
      'Ceci est une version de développement. Son autorisation réseau sert uniquement aux outils de développement.';

  @override
  String get privacyDevBuildShort =>
      'Version de développement. BooBoard n\'a toujours pas l\'autorisation Internet.';

  @override
  String privacyStorageSize(String size, String when) {
    return '$size · modifié $when';
  }

  @override
  String get privacyCustomThemes => 'Thèmes personnalisés';

  @override
  String get privacyNoPacks =>
      'Aucun installé. Les packs de voix et de traduction apparaissent ici.';

  @override
  String privacyPacksSize(int count, String size) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count packs',
      one: '1 pack',
    );
    return '$_temp0 · $size';
  }

  @override
  String get privacyWhatBooBoardStores => 'Ce que BooBoard stocke';

  @override
  String get privacyShowsSizesOnly =>
      'BooBoard n\'affiche ici que des tailles, jamais le contenu. Les tailles incluent la dernière copie enregistrée, qui protège vos données si une sauvegarde est interrompue.';

  @override
  String get privacyTypingPrivacy => 'Confidentialité de la saisie';

  @override
  String get privacyLearnNewWords => 'Apprendre de nouveaux mots';

  @override
  String get privacyLearnNewWordsBody =>
      'Apprend les mots et expressions de votre saisie. Jamais dans les champs de mot de passe ni en mode incognito.';

  @override
  String get privacyIncognito => 'Incognito';

  @override
  String get privacyIncognitoBody =>
      'N\'apprend ni ne retient rien quand il est activé. Les onglets incognito du navigateur l\'activent d\'eux-mêmes.';

  @override
  String get privacyHideScreenshots => 'Masquer des captures d\'écran';

  @override
  String get privacyHideScreenshotsBody =>
      'Empêche les captures et enregistrements d\'écran du clavier dans toutes les applis. Les champs de mot de passe sont toujours masqués.';

  @override
  String get privacyAutoOffApps => 'Désactivé automatiquement dans ces applis';

  @override
  String get privacyAutoOffAppsBody =>
      'BooBoard ne garde les noms d\'applis que pour remplir cette liste. Ils sont chiffrés, jamais enregistrés en incognito, et vous pouvez les effacer ci-dessous.';

  @override
  String get privacyNoAppsYet => 'Aucune appli pour l\'instant';

  @override
  String get privacyNoAppsYetBody =>
      'Les applis dans lesquelles vous écrivez apparaîtront ici.';

  @override
  String get privacyAlwaysIncognitoApps => 'Applis toujours en incognito';

  @override
  String get privacyPersonalShortcuts => 'Raccourcis personnels';

  @override
  String get privacyOfferShortcuts => 'Proposer les raccourcis';

  @override
  String get privacyOfferShortcutsBody =>
      'Affiche vos abréviations, comme « omw », en première suggestion.';

  @override
  String get privacyEditShortcuts => 'Modifier les raccourcis';

  @override
  String get privacyNoShortcutsYet => 'Aucun pour l\'instant';

  @override
  String get privacyLearnedAndClipboard => 'Mots appris et presse-papiers';

  @override
  String get privacyNoWordsLearnedYet => 'Aucun mot appris pour l\'instant';

  @override
  String get privacyWordsLearnedBody =>
      'Les mots que vous tapez sont appris ici après que BooBoard les a vus plusieurs fois.';

  @override
  String privacyReviewWords(String when) {
    return 'Revoir, retirer ou bloquer des mots · $when';
  }

  @override
  String get privacyClipboardHistoryEmpty =>
      'L\'historique est vide. Modifiez les réglages du presse-papiers dans Panneaux.';

  @override
  String privacyClipboardInHistory(String size) {
    return '$size dans l\'historique. Modifiez les réglages du presse-papiers dans Panneaux.';
  }

  @override
  String get privacyAppLock => 'Verrouillage de l\'app';

  @override
  String get privacyLockBooBoard => 'Verrouiller BooBoard';

  @override
  String get privacyLockBooBoardBody =>
      'Demande votre empreinte ou le code de l\'appareil à l\'ouverture de l\'app, ou après un passage en arrière-plan.';

  @override
  String get privacyLockAfter => 'Verrouiller après';

  @override
  String get privacySetScreenLockFirst =>
      'Définissez d\'abord un verrouillage d\'écran';

  @override
  String get privacySetScreenLockBody =>
      'El bloqueo de la app usa su huella o el PIN del dispositivo. Defina un PIN, patrón o contraseña en los ajustes de seguridad de Android y vuelva.';

  @override
  String get privacyTurnOnAppLockReason =>
      'Activer le verrouillage de l\'app pour BooBoard';

  @override
  String get privacyNotAvailable => 'Pas disponible pour le moment';

  @override
  String get privacyNotAvailableBody =>
      'Le verrouillage de l\'appareil n\'a pas pu être utilisé. Le verrouillage de l\'app reste désactivé.';

  @override
  String get privacyBackupTitle => 'Sauvegarde';

  @override
  String get privacyBackupRestore => 'Sauvegarde et restauration';

  @override
  String get privacyBackupRestoreBody =>
      'Un fichier .boobackup chiffré que vous conservez. Vous choisissez ce qu\'il contient.';

  @override
  String get privacyDeleteData => 'Supprimer les données';

  @override
  String get privacyEraseEverything => 'Tout effacer';

  @override
  String get privacyEraseEverythingBody =>
      'Toutes les catégories ci-dessus, vos thèmes personnalisés et la clé qui les protège.';

  @override
  String privacyDeleteTitle(String category) {
    return 'Supprimer $category ?';
  }

  @override
  String get privacyEraseTitle => 'Tout effacer ?';

  @override
  String get privacyWillDelete => 'Cela supprimera définitivement :';

  @override
  String get privacyResetSettings =>
      'Réinitialiser aussi tous les réglages par défaut';

  @override
  String get privacyCannotBeUndone => 'Action irréversible.';

  @override
  String get privacyDeleted => 'Supprimé.';

  @override
  String get privacyDeleteFailed =>
      'BooBoard n\'a pas pu tout supprimer. Réessayez.';

  @override
  String get privacyOk => 'OK';

  @override
  String get backupMakeTitle => 'Faire une sauvegarde';

  @override
  String get backupIncludeImages => 'Inclure les images de fond';

  @override
  String get backupPhotosLarger =>
      'Les photos rendent le fichier beaucoup plus lourd.';

  @override
  String get backupCreateButton => 'Créer une sauvegarde chiffrée';

  @override
  String get backupRestoreSection => 'Restaurer';

  @override
  String get backupRestoreFromFile =>
      'Restaurer depuis un fichier de sauvegarde';

  @override
  String get backupRestoreFromFileBody =>
      'Ouvrez un fichier .boobackup, vérifiez son contenu, puis fusionnez ou remplacez.';

  @override
  String get backupChoosePassphrase => 'Choisissez une phrase de passe';

  @override
  String get backupEnterPassphrase => 'Saisissez la phrase de passe';

  @override
  String get backupWriteItDown =>
      'Notez-la dans un endroit sûr. Une phrase de passe perdue ne peut pas être récupérée.';

  @override
  String get backupPassphrase => 'Phrase de passe';

  @override
  String get backupTypeAgain => 'Retapez-la';

  @override
  String get backupMismatch => 'Les phrases de passe ne correspondent pas';

  @override
  String backupStrength(String strength) {
    return 'Solidité de la phrase : $strength';
  }

  @override
  String get strengthTooShort => 'Utilisez au moins 8 caractères';

  @override
  String get strengthWeak => 'Faible';

  @override
  String get strengthFair => 'Correcte';

  @override
  String get strengthGood => 'Bonne';

  @override
  String get strengthStrong => 'Forte';

  @override
  String get backupOpen => 'Ouvrir';

  @override
  String get backupNothingYet => 'Rien pour l\'instant';

  @override
  String get backupSettingsSummary =>
      'Thème, langues, saisie et choix de confidentialité';

  @override
  String backupLearnedSummary(String languages, String words) {
    return '$words dans $languages';
  }

  @override
  String backupPinnedOff(String items) {
    return '$items. Désactivé sauf si vous l\'activez.';
  }

  @override
  String backupAlreadyHere(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count raccourcis déjà présents',
      one: '1 raccourci déjà présent',
    );
    return '$_temp0';
  }

  @override
  String backupThemesAlreadyHere(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count fichiers de thème déjà présents',
      one: '1 fichier de thème déjà présent',
    );
    return '$_temp0';
  }

  @override
  String get backupClipboardKept =>
      'presse-papiers laissé intact (disposition inconnue)';

  @override
  String get backupEmojiKept => 'emojis récents conservés';

  @override
  String get backupSettingsApplied => 'réglages';

  @override
  String backupLearnedAdded(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count langues',
      one: '1 langue',
    );
    return 'mots appris pour $_temp0';
  }

  @override
  String shortcutDeleteTitle(String trigger) {
    return 'Supprimer « $trigger » ?';
  }

  @override
  String get shortcutDeleteBody =>
      'Cela supprime le raccourci. Action irréversible.';

  @override
  String get shortcutAdd => 'Ajouter un raccourci';

  @override
  String get shortcutSearch => 'Rechercher des raccourcis';

  @override
  String get shortcutNoMatch =>
      'Aucun raccourci ne correspond à votre recherche.';

  @override
  String shortcutDeleteTooltip(String trigger) {
    return 'Supprimer $trigger';
  }

  @override
  String get shortcutNoneYet => 'Aucun raccourci pour l\'instant';

  @override
  String get shortcutExplain =>
      'Un raccourci transforme une abréviation en texte plus long. Exemples :';

  @override
  String shortcutExamples(String first, String second) {
    return '$first\n$second';
  }

  @override
  String get shortcutEncrypted =>
      'Les raccourcis sont chiffrés sur ce téléphone, comme vos mots appris.';

  @override
  String get shortcutNew => 'Nouveau raccourci';

  @override
  String get shortcutEdit => 'Modifier le raccourci';

  @override
  String get shortcutShortForm => 'Abréviation';

  @override
  String get shortcutExpandsTo => 'Se développe en';

  @override
  String get privacyMascotLabel => 'Mascotte de confidentialité de BooBoard';

  @override
  String get privacyStoredEmoji => 'Emoji récents';

  @override
  String get privacyStoredApps => 'Liste des applis';

  @override
  String get privacyStoredOther => 'Autres données stockées';

  @override
  String privacyUnitBytes(num count) {
    return '$count o';
  }

  @override
  String privacyUnitKilobytes(num count) {
    return '$count Ko';
  }

  @override
  String privacyUnitMegabytes(num count) {
    return '$count Mo';
  }

  @override
  String get shortcutProblemEmptyTrigger =>
      'Saisissez l\'abréviation à développer.';

  @override
  String shortcutProblemTriggerTooLong(num count) {
    return 'L\'abréviation peut comporter au plus $count caractères.';
  }

  @override
  String get shortcutProblemTriggerCharacters =>
      'Utilisez uniquement des lettres, des chiffres et des apostrophes dans l\'abréviation.';

  @override
  String get shortcutProblemEmptyExpansion =>
      'Saisissez ce que l\'abréviation doit développer.';

  @override
  String shortcutProblemExpansionTooLong(num count) {
    return 'Le développement peut comporter au plus $count caractères.';
  }

  @override
  String get shortcutProblemDuplicate =>
      'Vous avez déjà un raccourci avec cette abréviation.';

  @override
  String shortcutProblemTooMany(num count) {
    return 'Vous pouvez garder au plus $count raccourcis.';
  }

  @override
  String get onboardingWelcomeTitle => 'Salut, moi c’est *Boo.*';

  @override
  String get onboardingWelcomeBody =>
      'Je suis un clavier qui ne va jamais en ligne. Ce que vous tapez reste sur ce téléphone, sous clé.';

  @override
  String get onboardingWelcomeStart => 'C’est parti';

  @override
  String get onboardingMascotLabel => 'Boo, le fantôme de BooBoard';

  @override
  String get onboardingFactNoInternet => 'Aucune permission Internet';

  @override
  String get onboardingFactOpenSource => 'Open source';

  @override
  String get onboardingFactOpenSourceBody =>
      'Tout le monde peut lire le code et vérifier.';

  @override
  String get onboardingDemoKeyboards => 'Applications de clavier';

  @override
  String get onboardingDemoOtherKeyboard => 'Autre clavier';

  @override
  String get onboardingDemoAttention => 'Attention';

  @override
  String get onboardingDemoAttentionBody =>
      'Ce clavier pourrait recueillir tout le texte que vous saisissez…';

  @override
  String get onboardingDemoOk => 'OK';

  @override
  String get onboardingDemoChooseInput => 'Choisir le mode de saisie';

  @override
  String get onboardingDemoSwitchOn => 'Activer';

  @override
  String get onboardingDemoTapOk => 'OK, puis OK';

  @override
  String get onboardingDemoComeBack => 'Revenez';

  @override
  String get onboardingDemoPick => 'Choisissez BooBoard';

  @override
  String get onboardingDemoStartTyping => 'Commencez à taper';

  @override
  String get onboardingDemoRebootNote =>
      'Remarque : Après un redémarrage, cette appli ne peut pas démarrer tant que vous n\'avez pas déverrouillé votre téléphone';

  @override
  String get onboardingDemoChatIn => 'On se voit à 19 h ?';

  @override
  String get onboardingDemoChatOut => 'J\'arrive';

  @override
  String get onboardingDemoMessage => 'Message';

  @override
  String get onboardingShh => 'chut';

  @override
  String get onboardingTryMe => 'Essaie-moi';

  @override
  String get onboardingTurnOnTitle => 'Activez *BooBoard*';

  @override
  String get onboardingTurnOnBody =>
      'Activez-le dans la liste des claviers d’Android, puis revenez. Cette page le remarque toute seule.';

  @override
  String get onboardingKeyboardOn => 'BooBoard est activé';

  @override
  String get onboardingKeyboardOff => 'Pas encore activé';

  @override
  String get onboardingOpenKeyboardSettings => 'Ouvrir les réglages du clavier';

  @override
  String get onboardingSwitchTitle => 'Faites-en *le vôtre*';

  @override
  String get onboardingSwitchBody =>
      'Choisissez BooBoard dans la courte liste d’Android. Vous pouvez revenir en arrière à tout moment.';

  @override
  String get onboardingKeyboardIsYours => 'BooBoard est votre clavier';

  @override
  String get onboardingKeyboardNotYours => 'Pas encore votre clavier';

  @override
  String get onboardingTurnOnFirst => 'Activez-le d’abord';

  @override
  String get onboardingChooseKeyboard => 'Choisir le clavier';

  @override
  String get onboardingCheckingPermissions =>
      'Vérification des autorisations de l\'app…';

  @override
  String get onboardingDebugInternet =>
      'Cette version de débogage peut accéder à Internet. Elle n\'a cette autorisation que pour le développement.';

  @override
  String get onboardingReleaseInternet =>
      'Cette version peut accéder à Internet.';

  @override
  String get onboardingNoInternet =>
      'BooBoard n\'a pas l\'autorisation Internet : il ne peut rien envoyer nulle part.';

  @override
  String get onboardingWarningTitle => 'À propos de cet *avertissement*';

  @override
  String get onboardingWarningBody =>
      'Android l’affiche pour tous les claviers, car un clavier pourrait envoyer ce que vous tapez en ligne. BooBoard ne le peut pas.';

  @override
  String get onboardingInternetAccess => 'Accès à Internet';

  @override
  String get onboardingEverythingHere => 'Reste sur ce téléphone';

  @override
  String get onboardingEverythingHereBody =>
      'Les mots appris, le presse-papiers et les réglages sont chiffrés avec une clé dans Android Keystore.';

  @override
  String get onboardingLanguagesTitle => 'Vos *langues*';

  @override
  String get onboardingThemeTitle => 'Thème';

  @override
  String get onboardingTryTyping => 'Tapez une phrase';

  @override
  String get onboardingTrySwipe => 'Glissez un mot, lettre à lettre';

  @override
  String get onboardingTryAccents => 'Appui long sur une lettre : accents';

  @override
  String get onboardingTryTitle => '*Essayez-le*';

  @override
  String get onboardingTryField => 'Tapez quelque chose ici';

  @override
  String get onboardingAllSetTitle => 'Tout est *prêt.*';

  @override
  String get onboardingAllSetBody =>
      'Langues, saisie, thèmes et plus encore sont dans les Réglages, quand vous voulez.';

  @override
  String onboardingStepOf(String step, String total) {
    return 'Étape $step sur $total';
  }

  @override
  String get onboardingBack => 'Retour';

  @override
  String get onboardingNext => 'Suivant';

  @override
  String get onboardingDone => 'Terminé';

  @override
  String get onboardingSearchLanguages => 'Rechercher des langues';

  @override
  String onboardingSelected(String languages) {
    return 'Sélectionnées : $languages';
  }

  @override
  String get onboardingNoLanguageMatch =>
      'Aucune langue ne correspond à cette recherche.';

  @override
  String get themeCreate => 'Créer un thème';

  @override
  String themeSelectedLabel(String name) {
    return '$name, sélectionné';
  }

  @override
  String themeCardOptions(String name) {
    return 'Options pour $name';
  }

  @override
  String get themeEdit => 'Modifier';

  @override
  String get themeDuplicate => 'Dupliquer';

  @override
  String get themeRename => 'Renommer';

  @override
  String get themeDeleteAction => 'Supprimer';

  @override
  String get themeTryTyping => 'Essayer de taper';

  @override
  String get themeTryLabel => 'Tapez ici pour essayer le thème';

  @override
  String get themeTryHelper =>
      'Le clavier apparaît ici lorsque BooBoard est sélectionné.';

  @override
  String get themeRenameTitle => 'Renommer le thème';

  @override
  String get themeNameField => 'Nom';

  @override
  String get themeEditTitle => 'Modifier le thème';

  @override
  String get themeNewTitle => 'Nouveau thème';

  @override
  String get themeEditorTitle => 'Thème';

  @override
  String get themeOpenFailed => 'Ce thème n\'a pas pu être ouvert.';

  @override
  String get themeSaveFailed => 'Impossible d\'enregistrer le thème.';

  @override
  String get themePhotoPickerFailed =>
      'Le sélecteur de photos n\'a pas pu s\'ouvrir.';

  @override
  String get themeDiscardTitle => 'Abandonner les modifications ?';

  @override
  String get themeDiscardBody =>
      'Vos modifications de ce thème seront perdues.';

  @override
  String get themeKeepEditing => 'Continuer les modifications';

  @override
  String get themeDiscard => 'Abandonner';

  @override
  String get themeSave => 'Enregistrer';

  @override
  String get themeNameRequired => 'Un nom est requis';

  @override
  String get themeNameLabel => 'Nom du thème';

  @override
  String get themeDefaultName => 'Mon thème';

  @override
  String get themeSectionName => 'Nom';

  @override
  String get themeSectionLook => 'Apparence';

  @override
  String get themeDarkMode => 'Mode sombre';

  @override
  String get themeChoiceSystem => 'Système';

  @override
  String get themeChoiceLight => 'Clair';

  @override
  String get themeChoiceDark => 'Sombre';

  @override
  String get themePureBlack => 'Noir pur';

  @override
  String get themePureBlackBody => 'Fond noir';

  @override
  String get themePureBlackOnlyDark => 'Seulement en mode sombre';

  @override
  String get themeGalleryPureBlackDark => 'Fond noir en mode sombre';

  @override
  String get themeContrast => 'Contraste';

  @override
  String get themeChoiceStandard => 'Standard';

  @override
  String get themeChoiceMedium => 'Moyen';

  @override
  String get themeChoiceHigh => 'Élevé';

  @override
  String get themeKeyboardHeight => 'Hauteur du clavier';

  @override
  String get themeSectionColours => 'Couleurs';

  @override
  String get themeSource => 'Source';

  @override
  String get themeSourceWallpaper => 'Fond d\'écran';

  @override
  String get themeSourceSeed => 'Couleur de base';

  @override
  String get themeSourcePerRole => 'Par rôle';

  @override
  String get themeWallpaperNeedsAndroid12 =>
      'Les couleurs du fond d\'écran nécessitent Android 12 ou une version plus récente.';

  @override
  String get themeSeedColour => 'Couleur de base';

  @override
  String get themeScheme => 'Schéma';

  @override
  String get themeColourRoles => 'Rôles de couleur';

  @override
  String themeEditingColours(String mode) {
    String _temp0 = intl.Intl.selectLogic(mode, {
      'dark': 'Modification des couleurs sombres',
      'other': 'Modification des couleurs claires',
    });
    return '$_temp0';
  }

  @override
  String get themeResetRoles => 'Réinitialiser tous les rôles';

  @override
  String get themeKeys => 'Touches';

  @override
  String get themeShape => 'Forme';

  @override
  String get themeShapePill => 'Pilule';

  @override
  String get themeShapeRounded => 'Arrondie';

  @override
  String get themeShapeSquare => 'Carrée';

  @override
  String get themeKeyBorders => 'Bordures des touches';

  @override
  String get themeBorderWidth => 'Épaisseur de bordure';

  @override
  String get themeKeyGap => 'Espacement des touches';

  @override
  String get themeFontWeight => 'Graisse de police';

  @override
  String get themeFontSize => 'Taille de police';

  @override
  String get themeHintCharacters => 'Caractères d\'indication';

  @override
  String get themeHintCharactersBody => 'Petits caractères à l\'appui long';

  @override
  String get themeBackground => 'Arrière-plan';

  @override
  String get themeBackgroundType => 'Type';

  @override
  String get themeTypeSolid => 'Uni';

  @override
  String get themeTypeGradient => 'Dégradé';

  @override
  String get themeTypePhoto => 'Photo';

  @override
  String get themeNoPhotoYet =>
      'Aucune photo pour l\'instant. Choisissez-en une pour la recadrer au clavier.';

  @override
  String get themeChoosePhoto => 'Choisir une photo';

  @override
  String get themeEditCrop => 'Modifier le recadrage et le flou';

  @override
  String get themeDim => 'Assombrir';

  @override
  String get themeSectionPopups => 'Bulles et trace';

  @override
  String get themeSolidPopups => 'Bulles unies';

  @override
  String get themeSolidPopupsBodyWallpaper =>
      'No avec les couleurs du fond d\'écran';

  @override
  String get themeSolidPopupsBodyPrimary => 'Bulles dans la couleur principale';

  @override
  String get themeSwipeTrail => 'Trace du glissement';

  @override
  String get themeTrailWidth => 'Largeur de la trace';

  @override
  String get themeTrailFade => 'Estompage de la trace';

  @override
  String get themeTrailInstant => 'Instantané';

  @override
  String get themeTrailColours => 'Couleurs de la trace';

  @override
  String get themeTrailStart => 'Début';

  @override
  String get themeTrailEnd => 'Fin';

  @override
  String get themeTrailStartTitle => 'Début de la trace';

  @override
  String get themeTrailEndTitle => 'Fin de la trace';

  @override
  String get themeAutomatic => 'Automatique';

  @override
  String get themeSectionMotion => 'Mouvement';

  @override
  String get themeKeyPressAnimation => 'Animation à l\'appui des touches';

  @override
  String get themeReduceMotion =>
      '« Supprimer les animations » est activé dans les réglages système, donc les touches ne s\'animent pas.';

  @override
  String get themeMotionOff => 'Désactivé';

  @override
  String get themeMotionSubtle => 'Discret';

  @override
  String get themeMotionStandard => 'Standard';

  @override
  String get themeMotionBouncy => 'Rebondissant';

  @override
  String get themeSchemeTonalSpot => 'Point tonal';

  @override
  String get themeSchemeVibrant => 'Vibrant';

  @override
  String get themeSchemeExpressive => 'Expressif';

  @override
  String get themeSchemeFidelity => 'Fidélité';

  @override
  String get themeSchemeContent => 'Contenu';

  @override
  String get themeSchemeMonochrome => 'Monochrome';

  @override
  String get themeSchemeNeutral => 'Neutre';

  @override
  String get themeSchemeRainbow => 'Arc-en-ciel';

  @override
  String get themeSchemeFruitSalad => 'Salade de fruits';

  @override
  String themeCustomColourHex(String hex) {
    return 'Couleur personnalisée #$hex';
  }

  @override
  String get themeCustomColour => 'Couleur personnalisée';

  @override
  String themeSwatchLabel(String hex, String label) {
    return 'Couleur $label, #$hex';
  }

  @override
  String themeUseSchemeColour(String label) {
    return 'Utiliser la couleur du schéma pour $label';
  }

  @override
  String get themeFromScheme => 'Depuis le schéma';

  @override
  String get themeOverridden => 'Défini';

  @override
  String themeStopLabel(String n) {
    return 'Arrêt $n';
  }

  @override
  String themePickStopTitle(String n) {
    return 'Arrêt $n';
  }

  @override
  String get themeAddStop => 'Ajouter un arrêt';

  @override
  String get themeRemoveStop => 'Retirer un arrêt';

  @override
  String get themeAngle => 'Angle';

  @override
  String get themeUseSchemeTooltipLabel => 'Utiliser la couleur du schéma';

  @override
  String get themeCropTitle => 'Recadrer la photo';

  @override
  String get themeUsePhoto => 'Utiliser la photo';

  @override
  String get themeCropSaveFailed => 'La photo n\'a pas pu être enregistrée.';

  @override
  String get themeCropSemantics =>
      'Recadrage de photo. Faites glisser pour déplacer la photo et pincez ou utilisez le curseur de zoom pour zoomer.';

  @override
  String get themeCropZoom => 'Zoom';

  @override
  String get themeCropBlur => 'Flou';

  @override
  String get themeCropBlurOff => 'Désactivé';

  @override
  String get themeCropNote =>
      'Le flou est enregistré dans l\'image. L\'assombrissement se règle dans l\'éditeur et s\'applique en direct.';

  @override
  String get themeHexLabel => 'Hex';

  @override
  String get themeHexError =>
      'Utilisez six chiffres hexadécimaux, comme F5B700';

  @override
  String get themeHue => 'Teinte';

  @override
  String get themeSaturation => 'Saturation';

  @override
  String get themeBrightness => 'Luminosité';

  @override
  String get themePickShadeHint =>
      'Choisissez une nuance, puis touchez Utiliser.';

  @override
  String get themePickColourUse => 'Utiliser';

  @override
  String get themeCopySuffix => 'copie';

  @override
  String themeCopyName(String name) {
    return 'Copie de $name';
  }

  @override
  String themeDeleteTitle(String name) {
    return 'Supprimer « $name » ?';
  }

  @override
  String get themeDeleteSelectedBody =>
      'Ce thème est sélectionné. BooBoard Dynamic sera utilisé à la place. Action irréversible.';

  @override
  String get themeDeleteBody => 'Action irréversible.';

  @override
  String get themeDeleteFailed => 'Impossible de supprimer le thème.';

  @override
  String get themeRenameFailed => 'Impossible de renommer le thème.';

  @override
  String get themeDuplicateFailed => 'Impossible de copier le thème.';

  @override
  String get themeSettingFailed => 'Impossible d\'enregistrer le réglage.';

  @override
  String get themeSystemColoursUnavailable =>
      'Les couleurs du système ne sont pas disponibles.';

  @override
  String get themeBooBoardDynamicFollows =>
      'BooBoard Dynamic suit votre fond d\'écran';

  @override
  String get themeBooBoardDynamicBody =>
      'Ses couleurs se mettent à jour quand le fond d\'écran change';

  @override
  String get themeSectionPresets => 'Préréglages';

  @override
  String get themeSectionMyThemes => 'Mes thèmes';

  @override
  String get themeSectionTry => 'Essayer de taper';

  @override
  String get themeAppearance => 'Apparence';

  @override
  String get themesTitle => 'Thèmes';

  @override
  String privacyThemesSize(int count, String size) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count fichiers de thème',
      one: '1 fichier de thème',
    );
    return '$_temp0 · $size';
  }

  @override
  String get backupUnlockToSeeCount =>
      'Déverrouillez le téléphone pour voir le nombre';

  @override
  String get shortcutHelp =>
      'Un raccourci transforme une abréviation en texte plus long. Exemples :\nomw → on my way\naddr → your address';

  @override
  String privacyStoredLearned(String language) {
    return 'Mots appris ($language)';
  }

  @override
  String get settingsComingLater =>
      'Disponible dans une mise à jour ultérieure';

  @override
  String get backupExplainer =>
      'Une sauvegarde est un seul fichier, chiffré avec une phrase de passe que vous choisissez. Seule cette phrase l\'ouvre. Si vous oubliez la phrase, personne ne peut récupérer la sauvegarde, pas même BooBoard.';

  @override
  String privacyCategoryLine(String detail, String title) {
    return '$title : $detail';
  }

  @override
  String get shortcutShortFormHint => 'omw';

  @override
  String get shortcutExpansionHint => 'en route';

  @override
  String get durationMinutes15 => '15 minutes';

  @override
  String get durationHour => '1 heure';

  @override
  String get durationDay => '1 jour';

  @override
  String get durationWeek => '1 semaine';

  @override
  String get onboardingCloseSetup => 'Fermer la configuration';

  @override
  String get packsCouldNotRead => 'BooBoard n\'a pas pu lire ses packs';

  @override
  String packsDeleteTooltip(String name) {
    return 'Supprimer $name';
  }

  @override
  String get privacyNothingStored => 'Rien n\'est encore stocké';

  @override
  String privacyRemoveAppTooltip(String app) {
    return 'Retirer $app de la liste';
  }

  @override
  String get chineseTitle => 'Chinois';

  @override
  String get chineseTraditional => 'Caractères traditionnels';

  @override
  String get chineseTraditionalBody =>
      'Affiche les candidats en caractères traditionnels (norme de Taïwan).';

  @override
  String get chineseFuzzy => 'Pinyin approximatif';

  @override
  String get chineseFuzzyBody =>
      'Accepte aussi z et zh, c et ch, s et sh, n et l, an et ang, en et eng, in et ing.';

  @override
  String get cjkDictionary => 'Dictionnaire';

  @override
  String get chineseClearPhrases => 'Effacer les phrases apprises';

  @override
  String get chineseClearPhrasesBody =>
      'Oublie les mots que vous avez choisis. Le dictionnaire reste.';

  @override
  String get chineseFooter =>
      'Le chinois est saisi sur ce téléphone. Les phrases apprises sont chiffrées et ne le quittent jamais.';

  @override
  String get chineseClearTitle => 'Effacer les phrases apprises ?';

  @override
  String get chineseClearBody =>
      'Les mots choisis pour le chinois sont supprimés. Action irréversible.';

  @override
  String get cjkClear => 'Effacer';

  @override
  String get chinesePhrasesCleared => 'Phrases apprises effacées';

  @override
  String get chineseLooking => 'Recherche du dictionnaire';

  @override
  String get chineseDictName => 'Dictionnaire chinois';

  @override
  String get chinesePackMissing =>
      'Non installé. La saisie en chinois en a besoin ; installez-le dans Packs de modèles.';

  @override
  String chinesePackInstalled(String license) {
    return 'Installé. $license';
  }

  @override
  String get japaneseTitle => 'Japonais';

  @override
  String get japaneseLayout => 'Disposition';

  @override
  String get japaneseLayout12 => '12 touches (glisser)';

  @override
  String get japaneseLayoutRomaji => 'Romaji (QWERTY)';

  @override
  String get japaneseTyping => 'Saisie';

  @override
  String get japaneseFlickOnly => 'Glisser uniquement';

  @override
  String get japaneseFlickOnlyBody =>
      'Pas de pressions multiples : toucher あ deux fois saisit ああ, pas い';

  @override
  String get japaneseHalfWidth => 'Espace demi-chasse';

  @override
  String get japaneseHalfWidthBody =>
      'L\'espace saisit une espace normale quand rien n\'est en cours de saisie. Désactivé, il saisit une espace pleine chasse.';

  @override
  String get japaneseDictPack => 'Pack de dictionnaire';

  @override
  String get japaneseChecking => 'Vérification...';

  @override
  String japaneseInstalled(String name) {
    return '$name est installé. La conversion en kanji est activée.';
  }

  @override
  String get japaneseNotInstalled =>
      'Non installé. Les kana se saisissent quand même ; les kanji nécessitent le pack.';

  @override
  String get japaneseClearWords => 'Effacer les mots appris';

  @override
  String get japaneseClearWordsBody =>
      'Oublie les mots japonais que vous avez choisis. Stockés chiffrés sur ce téléphone.';

  @override
  String get japaneseClearTitle => 'Effacer les mots japonais appris ?';

  @override
  String get japaneseClearBody =>
      'Tous les mots japonais choisis sont supprimés. Action irréversible.';

  @override
  String get privacyStoredChinesePhrases => 'Phrases en chinois';

  @override
  String get privacyStoredJapaneseWords => 'Mots en japonais';
}
