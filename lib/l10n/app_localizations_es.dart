// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get appName => 'BooBoard';

  @override
  String get homeTagline => 'Escritura privada, en este teléfono';

  @override
  String get homeOfflinePromise =>
      'BooBoard funciona sin conexión y no envía *nada a ningún sitio.*';

  @override
  String get cancel => 'Cancelar';

  @override
  String get delete => 'Eliminar';

  @override
  String get save => 'Guardar';

  @override
  String get useAction => 'Usar';

  @override
  String get off => 'Desactivado';

  @override
  String get left => 'Izquierda';

  @override
  String get right => 'Derecha';

  @override
  String get settingsLanguages => 'Idiomas';

  @override
  String get settingsTyping => 'Escritura';

  @override
  String get settingsFeel => 'Sensación';

  @override
  String get settingsThemes => 'Temas';

  @override
  String get settingsPanels => 'Paneles';

  @override
  String get settingsVoice => 'Voz';

  @override
  String get settingsTranslation => 'Traducción';

  @override
  String get settingsPrivacy => 'Privacidad';

  @override
  String get settingsAbout => 'Acerca de';

  @override
  String get settingsModelPacks => 'Paquetes de modelos';

  @override
  String get homeSetupTurnOn =>
      'Activa BooBoard en la lista de teclados de Android.';

  @override
  String get homeSetupChoose =>
      'Elige BooBoard como el teclado con el que escribes.';

  @override
  String get homeFinishSetup => 'Termina de configurar BooBoard';

  @override
  String get homeTypingSubtitle =>
      'Correcciones, sugerencias, teclas y deslizar';

  @override
  String get homeFeelSubtitle =>
      'Vibración, sonidos, altura y modo de una mano';

  @override
  String get homePanelsSubtitle => 'Portapapeles y emoji';

  @override
  String get homeVoiceSubtitle => 'Habla para escribir, en este teléfono';

  @override
  String get homeTranslationSubtitle =>
      'Traduce mientras escribes, sin conexión';

  @override
  String get homePrivacySubtitle =>
      'Qué se guarda, incógnito, bloqueo de la app y copia de seguridad';

  @override
  String get homeAboutSubtitle => 'Versión, licencias y código fuente';

  @override
  String get homeImages => 'Imágenes';

  @override
  String get homeAboutBooBoard => 'Acerca de BooBoard';

  @override
  String get websiteOpenHint => 'Abre booboard.com en tu navegador';

  @override
  String get websiteNoBrowser => 'Ningún navegador puede abrir booboard.com.';

  @override
  String get imagesSoonTitle => 'Imágenes *muy pronto*';

  @override
  String get imagesSoonBody =>
      'Crea imágenes a partir de tus palabras, aquí en este teléfono. Como todo en BooBoard, funcionará sin conexión.';

  @override
  String get aboutWebsite => 'Sitio web';

  @override
  String get aboutTitle => 'Acerca de';

  @override
  String aboutVersion(String versionCode, String versionName) {
    return 'Versión $versionName ($versionCode)';
  }

  @override
  String aboutVersionDebug(String versionCode, String versionName) {
    return 'Versión $versionName ($versionCode) · compilación de depuración';
  }

  @override
  String get aboutReadingVersion => 'Leyendo la versión…';

  @override
  String get aboutPrivacy => 'Privacidad';

  @override
  String get aboutNoInternet => 'BooBoard no puede usar Internet';

  @override
  String get aboutNoInternetBody =>
      'Las versiones publicadas no tienen permiso de Internet, así que nada de lo que escribes sale de este teléfono.';

  @override
  String get aboutLicence => 'Licencia';

  @override
  String get aboutGplTitle => 'Licencia Pública General GNU v3 o posterior';

  @override
  String get aboutGplBody =>
      'BooBoard es software libre. Puedes estudiarlo, modificarlo y compartirlo bajo la GPL.';

  @override
  String get aboutSourceCode => 'Código fuente';

  @override
  String get aboutSourceBody =>
      'BooBoard es GPL-3.0-or-later. Su código fuente está disponible en la página del proyecto.';

  @override
  String get aboutLicences => 'Licencias';

  @override
  String get aboutOpenSource => 'Licencias de código abierto';

  @override
  String get aboutOpenSourceBody =>
      'Flutter, material_ui y cada paquete que usa BooBoard';

  @override
  String get aboutTextLoadFailed => 'No se pudo cargar este texto.';

  @override
  String get languagesEnabledHeader =>
      'Activados; el primero es el predeterminado';

  @override
  String get languagesActive => 'Idioma activo';

  @override
  String get languagesAdd => 'Añadir un idioma';

  @override
  String get languagesAllEnabled => 'Todos los idiomas están activados';

  @override
  String get languagesAllEnabledBody =>
      'Quita uno de arriba para dejar espacio.';

  @override
  String get languagesMultilingual => 'Escritura multilingüe';

  @override
  String get languagesMultilingualBody =>
      'Sugiere palabras de hasta tres idiomas activados que comparten la escritura del teclado. Una palabra que cualquiera de ellos conoce nunca se corrige automáticamente.';

  @override
  String get languagesNativeDigits => 'Dígitos nativos';

  @override
  String get languagesNativeDigitsBody =>
      'Escribe dígitos en la escritura del idioma activo cuando lo tenga (०१२, ٠١٢).';

  @override
  String get languagesOptions => 'Opciones de idioma';

  @override
  String get languagesZhSubtitle =>
      'Pinyin, caracteres tradicionales y paquetes de diccionario';

  @override
  String get languagesJaSubtitle =>
      'Entrada por deslizamiento, conversión y paquetes de diccionario';

  @override
  String languagesReorderLabel(String language) {
    return 'Arrastra para reordenar $language';
  }

  @override
  String languageDefaultLabel(String language) {
    return '$language, predeterminado';
  }

  @override
  String languageLayoutTooltip(String language) {
    return 'Distribución para $language';
  }

  @override
  String languageRemoveTooltip(String language) {
    return 'Quitar $language';
  }

  @override
  String get feelHaptics => 'Háptica';

  @override
  String get feelHapticFeedback => 'Respuesta háptica';

  @override
  String get feelHapticFeedbackBody =>
      'Una vibración corta en cada tecla, según el ajuste del sistema';

  @override
  String get feelHapticStrength => 'Intensidad háptica';

  @override
  String get feelSounds => 'Sonidos';

  @override
  String get feelKeySounds => 'Sonidos de tecla';

  @override
  String get feelKeySoundsBody => 'Clics para teclas, espacio, borrar e intro';

  @override
  String get feelUseSystemVolume => 'Usar el volumen del sistema';

  @override
  String get feelKeySoundVolume => 'Volumen de sonido de tecla';

  @override
  String get feelHeight => 'Altura';

  @override
  String get feelPortraitHeight => 'Altura en vertical';

  @override
  String get feelLandscapeHeight => 'Altura en horizontal';

  @override
  String get feelOneHandedFloating => 'Una mano y flotante';

  @override
  String get feelOneHandedSide => 'Lado del modo de una mano';

  @override
  String get feelFloatingKeyboard => 'Teclado flotante';

  @override
  String get feelFloatingBody => 'Arrástralo a cualquier parte de la pantalla';

  @override
  String get panelsClipboard => 'Portapapeles';

  @override
  String get panelsClipboardHistory => 'Historial del portapapeles';

  @override
  String get panelsClipboardHistoryBody =>
      'Guarda lo que copias, cifrado en este teléfono';

  @override
  String get panelsRecentChip => 'Chip de copia reciente';

  @override
  String get panelsRecentChipBody =>
      'Ofrece tu última copia en la barra de sugerencias durante un minuto';

  @override
  String get panelsKeepUnpinned => 'Guardar copias no fijadas durante';

  @override
  String get panelsClipsToKeep => 'Clips que conservar';

  @override
  String get panelsEmoji => 'Emoji';

  @override
  String get emojiSuggestions => 'Sugerencias de emoji';

  @override
  String get emojiSuggestionsPanelBody =>
      'Ofrece un emoji para algunas palabras en la barra de sugerencias';

  @override
  String get panelsPasswordsNeverSaved => 'Las contraseñas nunca se guardan';

  @override
  String get panelsSensitiveBody =>
      'Las copias que Android marca como sensibles nunca se guardan.';

  @override
  String get typingCorrections => 'Correcciones';

  @override
  String get typingAutocorrect => 'Autocorrección';

  @override
  String get typingAutocorrectBody =>
      'Corrige las erratas probables al terminar una palabra';

  @override
  String get typingAutoCapitalise => 'Mayúscula automática';

  @override
  String get typingAutoCapitaliseBody =>
      'Mayúsculas al inicio de las oraciones';

  @override
  String get typingDoubleSpace => 'Espacio doble para punto';

  @override
  String get typingDoubleSpaceBody =>
      'Dos toques en la barra espaciadora escriben \". \"';

  @override
  String get typingSmartPunctuation => 'Puntuación inteligente';

  @override
  String get typingSmartPunctuationBody =>
      'Ordena los espacios alrededor de los signos y usa comillas locales';

  @override
  String get typingSuggestions => 'Sugerencias';

  @override
  String get typingSuggestionsBody =>
      'Muestra palabras en la barra de sugerencias';

  @override
  String get typingNextWord => 'Predicción de la siguiente palabra';

  @override
  String get typingNextWordBody => 'Sugiere la palabra que suele seguir';

  @override
  String get typingEmojiBody => 'Ofrece un emoji para algunas palabras';

  @override
  String get typingHideOffensive => 'Ocultar palabras ofensivas';

  @override
  String get typingHideOffensiveBody =>
      'Nunca los sugiere, salvo que los escribas completos';

  @override
  String get typingKeys => 'Teclas';

  @override
  String get typingKeyPopups => 'Ventanas emergentes de tecla';

  @override
  String get typingKeyPopupsBody => 'Agranda una tecla mientras la pulsas';

  @override
  String get typingLongPressDelay => 'Retardo de pulsación larga';

  @override
  String get typingNumberRow => 'Fila de números';

  @override
  String get typingNumberRowBody => 'Muestra del 0 al 9 encima de las letras';

  @override
  String get typingHintLabels => 'Etiquetas de ayuda';

  @override
  String get typingHintLabelsBody =>
      'Símbolos pequeños en las teclas, como los acentos';

  @override
  String get typingLowercaseLabels => 'Etiquetas en minúscula';

  @override
  String get typingLowercaseLabelsBody =>
      'Mantiene las letras en minúscula con Mayús activado';

  @override
  String get typingSwipe => 'Deslizar';

  @override
  String get typingSwipeTyping => 'Escritura por deslizamiento';

  @override
  String get typingSwipeTypingBody =>
      'Desliza sobre las letras para escribir una palabra';

  @override
  String get typingShowTrail => 'Mostrar el rastro';

  @override
  String get typingTrailWidth => 'Ancho del rastro';

  @override
  String get typingTrailFade => 'Desvanecimiento del rastro';

  @override
  String get typingLivePreview => 'Vista previa en vivo';

  @override
  String get typingLivePreviewBody =>
      'Muestra la palabra probable mientras deslizas';

  @override
  String get typingSpaceMovesCursor => 'La barra espaciadora mueve el cursor';

  @override
  String get typingSpaceMovesCursorBody =>
      'Arrastra sobre la barra espaciadora para mover el cursor';

  @override
  String get typingSwipeBackspace =>
      'Deslizar en borrar para eliminar palabras';

  @override
  String get typingSwipeBackspaceBody =>
      'Desliza a la izquierda en borrar para seleccionar y eliminar palabras';

  @override
  String get voiceTyping => 'Escritura por voz';

  @override
  String get voiceTypingBody =>
      'Habla en inglés para escribir. El reconocimiento se hace en este teléfono.';

  @override
  String get voiceRecognition => 'Reconocimiento';

  @override
  String get voiceModelPacksBody =>
      'Instala o quita paquetes de voz y traducción';

  @override
  String get voiceAudioStays =>
      'El audio se queda en este teléfono y nunca se guarda.';

  @override
  String get voicePackAutomatic => 'Automático';

  @override
  String get voicePackAutomaticSelected => 'Automático (seleccionado)';

  @override
  String get voicePack => 'Paquete de voz';

  @override
  String get voiceNoPack =>
      'No hay ningún paquete de voz instalado. Instala uno en Paquetes de modelos.';

  @override
  String get voiceLooking => 'Buscando paquetes instalados';

  @override
  String voicePackItem(String name, String size) {
    return '$name · $size';
  }

  @override
  String voicePackItemSelected(String name, String size) {
    return '$name · $size (seleccionado)';
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
      'BooBoard no pudo abrir el selector de archivos.';

  @override
  String packsInstalled(String name) {
    return 'Se instaló $name.';
  }

  @override
  String packsDeleteTitle(String name) {
    return '¿Eliminar $name?';
  }

  @override
  String get packsDeleteBody =>
      'Sus archivos se borran de este teléfono. Puedes volver a importar el paquete más adelante desde su archivo.';

  @override
  String packsDeleted(String name) {
    return 'Se eliminó $name.';
  }

  @override
  String packsDeleteFailed(String name) {
    return 'BooBoard no pudo eliminar $name. Inténtalo de nuevo.';
  }

  @override
  String get packsIntro =>
      'Los paquetes se verifican antes de instalarse. Contienen solo datos, nunca código.';

  @override
  String get packsImport => 'Importar';

  @override
  String get packsImportTitle => 'Importar un archivo de paquete';

  @override
  String get packsChecking => 'Comprobando e instalando…';

  @override
  String get packsImportBody => 'Un archivo .boopack, por ejemplo de Descargas';

  @override
  String get packsNoVoice => 'No hay paquetes de voz instalados';

  @override
  String get packsNoVoiceBody =>
      'La escritura por voz necesita un paquete de voz.';

  @override
  String get packsNoTranslation => 'No hay paquetes de traducción instalados';

  @override
  String get packsNoTranslationBody =>
      'La traducción necesita un paquete por cada dirección.';

  @override
  String get packsDictionaries => 'Diccionarios';

  @override
  String get packsNoDictionary => 'No hay paquetes de diccionario instalados';

  @override
  String get packsNoDictionaryBody =>
      'La escritura en chino y japonés necesita un paquete de diccionario.';

  @override
  String get packsGetTitle => 'Obtener paquetes';

  @override
  String get packsExplainTitle => 'Los paquetes son archivos que añades tú.';

  @override
  String get packsExplainBody =>
      'Descárgalos desde la página de publicaciones del proyecto en otro dispositivo, cópialos a este teléfono y luego impórtalos.';

  @override
  String get packsCopyLink => 'Copiar el enlace de la página de publicaciones';

  @override
  String get packsPrivateTitle => 'Cómo las descargas siguen siendo privadas';

  @override
  String get packsPrivateBody =>
      'BooBoard no tiene permiso de internet y nunca se conecta. Descargar abre tu navegador, que obtiene el paquete de la publicación del proyecto en GitHub. Después, BooBoard comprueba la firma del paquete en este teléfono antes de instalar nada.';

  @override
  String get packsAvailableTitle => 'Paquetes que puedes añadir';

  @override
  String get packsDownload => 'Descargar';

  @override
  String packsDownloadMeta(String size) {
    return '$size · abre tu navegador';
  }

  @override
  String packsDownloadStarted(String name) {
    return 'Tu navegador está descargando $name. Cuando termine, toca Importar un archivo de paquete.';
  }

  @override
  String get packsNoBrowser =>
      'Ningún navegador puede abrir el enlace. Copia el enlace de la página de publicaciones.';

  @override
  String get packsImportCheckedBody =>
      'Elige el archivo .boopack descargado. Se comprueba en este teléfono y después se instala.';

  @override
  String get packsAllInstalled =>
      'Todos los paquetes publicados están instalados.';

  @override
  String get packsLinkCopied => 'Enlace copiado. Ábrelo en otro dispositivo.';

  @override
  String get packsPlayTitle => 'Obtener a través de Google Play';

  @override
  String get packsPlayNote =>
      'Google Play descarga estos paquetes, no BooBoard. BooBoard nunca usa la red.';

  @override
  String get packsGet => 'Obtener';

  @override
  String get packsStatusNotRequested => 'Aún no descargado';

  @override
  String get packsStatusWaiting => 'Esperando Wi-Fi o datos móviles';

  @override
  String get packsStatusDownloading => 'Descargando con Google Play';

  @override
  String get packsStatusInstalling => 'Comprobando e instalando';

  @override
  String get packsStatusFailed =>
      'Google Play no pudo entregarlo. Inténtalo de nuevo.';

  @override
  String packsOfferMeta(Object size, Object status) {
    return '$size · $status';
  }

  @override
  String get packsVerifyTitle => 'Verificar paquetes instalados';

  @override
  String get packsVerifyBody =>
      'Comprueba cada archivo de cada paquete instalado con su lista firmada. No se cambia nada.';

  @override
  String packsVerifyOk(Object count) {
    return 'Se han comprobado $count paquetes instalados. Todos los archivos coinciden.';
  }

  @override
  String packsVerifyDamaged(Object count) {
    return '$count paquetes instalados tienen archivos dañados o que faltan. Elimínalos e impórtalos de nuevo.';
  }

  @override
  String get packsVerifyUnavailable =>
      'La comprobación de paquetes no está disponible en esta versión de BooBoard.';

  @override
  String get packsVerifyFailed =>
      'BooBoard no pudo comprobar los paquetes. No se cambió nada.';

  @override
  String packsFreeSpace(Object size) {
    return '$size libres en este teléfono.';
  }

  @override
  String get packsNothingStored => 'Todavía no hay nada guardado.';

  @override
  String packsInstalledUse(String size) {
    return 'Los paquetes instalados usan $size en este teléfono.';
  }

  @override
  String get packErrorBadSignature =>
      'Este paquete no está firmado para BooBoard, así que no se instaló nada.';

  @override
  String get packErrorBadFormat =>
      'Este archivo no es un paquete de BooBoard. No se instaló nada.';

  @override
  String get packErrorTooLarge =>
      'Este paquete es demasiado grande para instalarlo en este teléfono.';

  @override
  String get packErrorVersion =>
      'Este paquete necesita una versión más nueva de BooBoard.';

  @override
  String get packErrorNoSpace =>
      'No hay suficiente espacio libre para instalar este paquete.';

  @override
  String get packErrorGeneric =>
      'No se pudo instalar el paquete. No se cambió nada.';

  @override
  String get translateDefaultPair => 'Par de idiomas predeterminado';

  @override
  String translatePairName(String from, String to) {
    return '$from → $to';
  }

  @override
  String get translateOffline => 'Traducción sin conexión';

  @override
  String get translateOfflineBody =>
      'Traduce mientras escribes en el teclado y el texto seleccionado en cualquier app.';

  @override
  String get translateDefaultPairTile => 'Par predeterminado';

  @override
  String get translatePackInstalled => 'Paquete instalado';

  @override
  String get translatePackNotInstalled =>
      'Paquete no instalado. Consíguelo en Paquetes de modelos.';

  @override
  String get translateInstalled => 'Direcciones instaladas';

  @override
  String get translateInstalledBody =>
      'Cada dirección es un paquete, por ejemplo inglés → español.';

  @override
  String translatePackMeta(String license, String size) {
    return '$size · $license';
  }

  @override
  String get translateModelPacksBody =>
      'Instala o elimina paquetes de traducción';

  @override
  String get translateRunsOnPhone =>
      'La traducción se hace en este teléfono. Nada de lo que traduces se guarda.';

  @override
  String get privacyUnlockReason =>
      'Desbloquea BooBoard para ver tus ajustes y datos';

  @override
  String get privacyLockUnavailable =>
      'El bloqueo del dispositivo no está disponible ahora. Inténtalo de nuevo en un momento.';

  @override
  String get privacyLockedTitle => 'BooBoard está bloqueado';

  @override
  String get privacyLockedBody =>
      'Desbloquea con tu huella o el PIN del dispositivo para continuar.';

  @override
  String get privacyUnlock => 'Desbloquear';

  @override
  String backupSaved(String size) {
    return 'Copia guardada ($size). Guarda bien tu frase de contraseña.';
  }

  @override
  String get backupUnlockRetrySaved =>
      'Desbloquea el teléfono y vuelve a intentarlo. No se guardó nada.';

  @override
  String get backupSaveFailed =>
      'No se pudo guardar la copia. No se cambió nada.';

  @override
  String get backupCheckFailed =>
      'No se pudo comprobar el archivo guardado; puede estar dañado. Vuelve a guardar la copia como un archivo nuevo.';

  @override
  String get backupWrongPassphrase =>
      'Frase de contraseña incorrecta o archivo dañado. No se cambió nada.';

  @override
  String get backupInvalidFile =>
      'Este archivo no es una copia de BooBoard válida. No se cambió nada.';

  @override
  String get backupTooLarge =>
      'Este archivo es demasiado grande para ser una copia de BooBoard.';

  @override
  String get backupNewerVersion =>
      'Esta copia la creó una versión más reciente de BooBoard. Actualiza BooBoard para restaurarla.';

  @override
  String get backupBusy =>
      'Cierra primero la otra ventana de archivos y vuelve a intentarlo.';

  @override
  String get backupOpenFailed =>
      'No se pudo abrir la copia. No se cambió nada.';

  @override
  String get backupEmpty => 'Esta copia no tiene nada.';

  @override
  String get backupRestoreTitle => 'Restaurar copia';

  @override
  String backupMadeBy(String date, String version) {
    return 'Creada el $date con BooBoard $version.';
  }

  @override
  String get backupMerge => 'Combinar';

  @override
  String get backupMergeBody =>
      'Conserva lo que hay en este teléfono y añade lo de la copia.';

  @override
  String get backupReplace => 'Reemplazar';

  @override
  String get backupReplaceBody =>
      'Haz que las secciones elegidas coincidan con la copia. Los datos actuales se borran antes.';

  @override
  String get commonContinue => 'Continuar';

  @override
  String get backupReplaceTitle => '¿Reemplazar los datos de este teléfono?';

  @override
  String get backupReplaceConfirm =>
      'Las secciones elegidas de este teléfono se borran y se reemplazan. No se puede deshacer.';

  @override
  String get backupPrivacyChangesTitle =>
      'Esta copia cambia tus ajustes de privacidad';

  @override
  String get backupPrivacyChangesBody =>
      'Al restaurar los ajustes, cambiarán estos ajustes de privacidad en este teléfono. Revísalos antes de continuar.';

  @override
  String backupPrivacyChangeLine(String setting, String from, String to) {
    return '$setting: $from → $to';
  }

  @override
  String get backupStateOn => 'Activado';

  @override
  String backupAppsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count apps',
      one: '1 app',
    );
    return '$_temp0';
  }

  @override
  String get backupRestoreAndChange => 'Restaurar y cambiar';

  @override
  String get backupUnlockRetryChanged =>
      'Desbloquea el teléfono y vuelve a intentarlo. No se cambió nada.';

  @override
  String get backupRestoreFailed =>
      'BooBoard no pudo terminar la restauración. Es posible que algunos datos no se escribieran.';

  @override
  String get restoreNothingNew => 'No se restauró nada nuevo.';

  @override
  String restoreSummary(String items) {
    return 'Se restauró: $items.';
  }

  @override
  String restoreSummarySkipped(String added, String skipped) {
    return '$added Omitido: $skipped.';
  }

  @override
  String restoreLearnedFor(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count idiomas',
      one: '1 idioma',
    );
    return 'palabras aprendidas en $_temp0';
  }

  @override
  String countFiles(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count archivos',
      one: '1 archivo',
    );
    return '$_temp0';
  }

  @override
  String countWords(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count palabras',
      one: '1 palabra',
    );
    return '$_temp0';
  }

  @override
  String countLanguages(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count idiomas',
      one: '1 idioma',
    );
    return '$_temp0';
  }

  @override
  String countShortcuts(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count atajos',
      one: '1 atajo',
    );
    return '$_temp0';
  }

  @override
  String countClipboardItems(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count elementos del portapapeles',
      one: '1 elemento del portapapeles',
    );
    return '$_temp0';
  }

  @override
  String countThemeFiles(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count archivos de tema',
      one: '1 archivo de tema',
    );
    return '$_temp0';
  }

  @override
  String countPinnedItems(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count elementos fijados',
      one: '1 elemento fijado',
    );
    return '$_temp0';
  }

  @override
  String countPacks(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count paquetes',
      one: '1 paquete',
    );
    return '$_temp0';
  }

  @override
  String countBlockedWords(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count palabras bloqueadas',
      one: '1 palabra bloqueada',
    );
    return '$_temp0';
  }

  @override
  String countTimes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count veces',
      one: '1 vez',
    );
    return '$_temp0';
  }

  @override
  String timeMinutesAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'hace $count minutos',
      one: 'hace 1 minuto',
    );
    return '$_temp0';
  }

  @override
  String timeHoursAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'hace $count horas',
      one: 'hace 1 hora',
    );
    return '$_temp0';
  }

  @override
  String timeDaysAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'hace $count días',
      one: 'hace 1 día',
    );
    return '$_temp0';
  }

  @override
  String get timeJustNow => 'justo ahora';

  @override
  String get languagePortuguese => 'Portugués';

  @override
  String packMeta(String languages, String license, String size) {
    return '$languages · $size · $license';
  }

  @override
  String privacyLearnedWordsTitle(String language) {
    return 'Palabras aprendidas ($language)';
  }

  @override
  String privacyClearLanguageTitle(String language) {
    return '¿Borrar las palabras de $language?';
  }

  @override
  String get privacyClearLanguageBody =>
      'Esto borra todas las palabras aprendidas en este idioma y las palabras bloqueadas. No se puede deshacer.';

  @override
  String get privacyClear => 'Borrar';

  @override
  String get privacySaveFailed =>
      'No se pudo guardar el cambio. Inténtalo de nuevo.';

  @override
  String get privacyCouldNotReadWords =>
      'BooBoard no pudo leer estas palabras.';

  @override
  String get privacyCannotReadWordsNow =>
      'BooBoard no puede leer estas palabras ahora. Desbloquea el teléfono y vuelve a intentarlo.';

  @override
  String get privacyNoWordsLanguage =>
      'Todavía no se han aprendido palabras en este idioma. BooBoard aprende una palabra después de escribirla varias veces.';

  @override
  String privacyBlockedWordsTooltip(num count) {
    return 'Palabras bloqueadas ($count)';
  }

  @override
  String get privacySortTooltip => 'Ordenar';

  @override
  String get privacySortMostUsed => 'Más usadas primero';

  @override
  String get privacySortAZ => 'De la A a la Z';

  @override
  String get privacyMoreTooltip => 'Más';

  @override
  String get privacyClearThisLanguage => 'Borrar este idioma';

  @override
  String get privacySearchWords => 'Buscar palabras';

  @override
  String privacyWordsSummary(String blocked, String words) {
    return '$words · $blocked';
  }

  @override
  String get privacyNoWordsYet => 'Todavía no hay palabras.';

  @override
  String privacyNoWordsMatch(String query) {
    return 'No hay palabras que coincidan con «$query».';
  }

  @override
  String get privacyNeverSuggested => 'Nunca sugeridas';

  @override
  String get privacyBlockedExplain =>
      'BooBoard no sugerirá ni corregirá a estas palabras.';

  @override
  String get privacyNoBlockedWords => 'No hay palabras bloqueadas.';

  @override
  String get privacyAllowAgain => 'Permitir de nuevo';

  @override
  String privacyWordLastUsed(int count, String when) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count veces',
      one: 'una vez',
    );
    return 'Escrita $_temp0 · última vez $when';
  }

  @override
  String privacyWordNotYetSuggested(String when) {
    return 'Escrita una vez hasta ahora, aún sin sugerir · última vez $when';
  }

  @override
  String get privacyToday => 'hoy';

  @override
  String get privacyYesterday => 'ayer';

  @override
  String privacyActionsFor(String word) {
    return 'Acciones para $word';
  }

  @override
  String get privacyForgetWord => 'Olvidar esta palabra';

  @override
  String get privacyNeverSuggestWord => 'No sugerir nunca esta palabra';

  @override
  String get privacyTryAgain => 'Intentar de nuevo';

  @override
  String get privacyCenterLoadFailed =>
      'BooBoard no pudo leer sus datos de privacidad. Inténtalo más tarde.';

  @override
  String get privacyDevBuildNetwork =>
      'Esta versión pide acceso a Internet. BooBoard nunca debería hacerlo. Por favor, repórtalo.';

  @override
  String get privacyNoInternetPermission =>
      'BooBoard no tiene permiso de Internet. No puede enviar nada.';

  @override
  String get privacyDevBuildNote =>
      'Esta es una versión de desarrollo. Su permiso de red es solo para herramientas de desarrollo.';

  @override
  String get privacyDevBuildShort =>
      'Versión de desarrollo. BooBoard sigue sin permiso de Internet.';

  @override
  String privacyStorageSize(String size, String when) {
    return '$size · cambiado $when';
  }

  @override
  String get privacyCustomThemes => 'Temas personalizados';

  @override
  String get privacyNoPacks =>
      'Ninguno instalado. Aquí aparecen los paquetes de voz y traducción.';

  @override
  String privacyPacksSize(int count, String size) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count paquetes',
      one: '1 paquete',
    );
    return '$_temp0 · $size';
  }

  @override
  String get privacyWhatBooBoardStores => 'Lo que guarda BooBoard';

  @override
  String get privacyShowsSizesOnly =>
      'BooBoard muestra aquí solo tamaños, nunca lo que hay dentro. Los tamaños incluyen la última copia guardada, que protege tus datos si un guardado se interrumpe.';

  @override
  String get privacyTypingPrivacy => 'Privacidad al escribir';

  @override
  String get privacyLearnNewWords => 'Aprender palabras nuevas';

  @override
  String get privacyLearnNewWordsBody =>
      'Aprende palabras y frases de lo que escribes. Nunca en campos de contraseña ni en incógnito.';

  @override
  String get privacyIncognito => 'Incógnito';

  @override
  String get privacyIncognitoBody =>
      'No aprende ni recuerda nada mientras está activo. Las pestañas de incógnito del navegador lo activan solas.';

  @override
  String get privacyHideScreenshots => 'Ocultar de las capturas';

  @override
  String get privacyHideScreenshotsBody =>
      'Impide las capturas y grabaciones de pantalla del teclado en todas las apps. Los campos de contraseña siempre están ocultos.';

  @override
  String get privacyAutoOffApps => 'Se desactiva automáticamente en estas apps';

  @override
  String get privacyAutoOffAppsBody =>
      'BooBoard guarda los nombres de las apps solo para llenar esta lista. Están cifrados, nunca se registran en incógnito, y puedes borrarlos abajo.';

  @override
  String get privacyNoAppsYet => 'Todavía no hay apps';

  @override
  String get privacyNoAppsYetBody => 'Las apps donde escribes aparecerán aquí.';

  @override
  String get privacyAlwaysIncognitoApps => 'Apps siempre en incógnito';

  @override
  String get privacyPersonalShortcuts => 'Atajos personales';

  @override
  String get privacyOfferShortcuts => 'Ofrecer atajos';

  @override
  String get privacyOfferShortcutsBody =>
      'Muestra tus formas abreviadas, como «omw», como primera sugerencia.';

  @override
  String get privacyEditShortcuts => 'Editar atajos';

  @override
  String get privacyNoShortcutsYet => 'Todavía ninguno';

  @override
  String get privacyLearnedAndClipboard => 'Palabras aprendidas y portapapeles';

  @override
  String get privacyNoWordsLearnedYet => 'Todavía no se han aprendido palabras';

  @override
  String get privacyWordsLearnedBody =>
      'Las palabras que escribes se aprenden aquí cuando BooBoard las ha visto algunas veces.';

  @override
  String privacyReviewWords(String when) {
    return 'Revisa, quita o bloquea palabras · $when';
  }

  @override
  String get privacyClipboardHistoryEmpty =>
      'El historial está vacío. Cambia los ajustes del portapapeles en Paneles.';

  @override
  String privacyClipboardInHistory(String size) {
    return '$size en el historial. Cambia los ajustes del portapapeles en Paneles.';
  }

  @override
  String get privacyAppLock => 'Bloqueo de la app';

  @override
  String get privacyLockBooBoard => 'Bloquear BooBoard';

  @override
  String get privacyLockBooBoardBody =>
      'Pide tu huella o el PIN del dispositivo al abrir la app o después de estar en segundo plano.';

  @override
  String get privacyLockAfter => 'Bloquear después de';

  @override
  String get privacySetScreenLockFirst =>
      'Primero configura un bloqueo de pantalla';

  @override
  String get privacySetScreenLockBody =>
      'El bloqueo de la app usa tu huella o el PIN del dispositivo. Configura un PIN, patrón o contraseña en los ajustes de seguridad de Android y vuelve.';

  @override
  String get privacyTurnOnAppLockReason =>
      'Activa el bloqueo de la app para BooBoard';

  @override
  String get privacyNotAvailable => 'No disponible ahora';

  @override
  String get privacyNotAvailableBody =>
      'No se pudo usar el bloqueo del dispositivo. El bloqueo de la app sigue desactivado.';

  @override
  String get privacyBackupTitle => 'Copia de seguridad';

  @override
  String get privacyBackupRestore => 'Copia y restauración';

  @override
  String get privacyBackupRestoreBody =>
      'Un archivo .boobackup cifrado que guardas. Tú eliges qué incluye.';

  @override
  String get privacyDeleteData => 'Eliminar datos';

  @override
  String get privacyEraseEverything => 'Borrar todo';

  @override
  String get privacyEraseEverythingBody =>
      'Todas las categorías de arriba, tus temas personalizados y la clave que los protege.';

  @override
  String privacyDeleteTitle(String category) {
    return '¿Eliminar $category?';
  }

  @override
  String get privacyEraseTitle => '¿Borrar todo?';

  @override
  String get privacyWillDelete => 'Esto borrará permanentemente:';

  @override
  String get privacyResetSettings =>
      'Restablecer también todos los ajustes a los predeterminados';

  @override
  String get privacyCannotBeUndone => 'Esto no se puede deshacer.';

  @override
  String get privacyDeleted => 'Eliminado.';

  @override
  String get privacyDeleteFailed =>
      'BooBoard no pudo eliminar todo. Inténtalo de nuevo.';

  @override
  String get privacyOk => 'OK';

  @override
  String get backupMakeTitle => 'Crear una copia';

  @override
  String get backupIncludeImages => 'Incluir imágenes de fondo';

  @override
  String get backupPhotosLarger =>
      'Las fotos hacen el archivo mucho más grande.';

  @override
  String get backupCreateButton => 'Crear copia cifrada';

  @override
  String get backupRestoreSection => 'Restaurar';

  @override
  String get backupRestoreFromFile => 'Restaurar desde un archivo de copia';

  @override
  String get backupRestoreFromFileBody =>
      'Abre un archivo .boobackup, revisa su contenido y luego combina o reemplaza.';

  @override
  String get backupChoosePassphrase => 'Elige una frase de contraseña';

  @override
  String get backupEnterPassphrase => 'Escribe la frase de contraseña';

  @override
  String get backupWriteItDown =>
      'Anótala en un lugar seguro. Una frase perdida no se puede recuperar.';

  @override
  String get backupPassphrase => 'Frase de contraseña';

  @override
  String get backupTypeAgain => 'Escríbela de nuevo';

  @override
  String get backupMismatch => 'Las frases de contraseña no coinciden';

  @override
  String backupStrength(String strength) {
    return 'Seguridad de la frase: $strength';
  }

  @override
  String get strengthTooShort => 'Usa al menos 8 caracteres';

  @override
  String get strengthWeak => 'Débil';

  @override
  String get strengthFair => 'Aceptable';

  @override
  String get strengthGood => 'Buena';

  @override
  String get strengthStrong => 'Fuerte';

  @override
  String get backupOpen => 'Abrir';

  @override
  String get backupNothingYet => 'Nada todavía';

  @override
  String get backupSettingsSummary =>
      'Tema, idiomas, escritura y opciones de privacidad';

  @override
  String backupLearnedSummary(String languages, String words) {
    return '$words en $languages';
  }

  @override
  String backupPinnedOff(String items) {
    return '$items. Desactivado salvo que lo actives.';
  }

  @override
  String backupAlreadyHere(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count atajos ya existen',
      one: '1 atajo ya existe',
    );
    return '$_temp0';
  }

  @override
  String backupThemesAlreadyHere(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count archivos de tema ya existen',
      one: '1 archivo de tema ya existe',
    );
    return '$_temp0';
  }

  @override
  String get backupClipboardKept =>
      'portapapeles sin cambios (diseño desconocido)';

  @override
  String get backupEmojiKept => 'emojis recientes conservados';

  @override
  String get backupSettingsApplied => 'ajustes';

  @override
  String backupLearnedAdded(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count idiomas',
      one: '1 idioma',
    );
    return 'palabras aprendidas en $_temp0';
  }

  @override
  String shortcutDeleteTitle(String trigger) {
    return '¿Eliminar «$trigger»?';
  }

  @override
  String get shortcutDeleteBody =>
      'Esto elimina el atajo. No se puede deshacer.';

  @override
  String get shortcutAdd => 'Añadir atajo';

  @override
  String get shortcutSearch => 'Buscar atajos';

  @override
  String get shortcutNoMatch => 'No hay atajos que coincidan con tu búsqueda.';

  @override
  String shortcutDeleteTooltip(String trigger) {
    return 'Eliminar $trigger';
  }

  @override
  String get shortcutNoneYet => 'Todavía no hay atajos';

  @override
  String get shortcutExplain =>
      'Un atajo convierte una forma abreviada en un texto más largo. Ejemplos:';

  @override
  String shortcutExamples(String first, String second) {
    return '$first\n$second';
  }

  @override
  String get shortcutEncrypted =>
      'Los atajos están cifrados en este teléfono, como tus palabras aprendidas.';

  @override
  String get shortcutNew => 'Nuevo atajo';

  @override
  String get shortcutEdit => 'Editar atajo';

  @override
  String get shortcutShortForm => 'Forma abreviada';

  @override
  String get shortcutExpandsTo => 'Se expande a';

  @override
  String get privacyMascotLabel => 'Mascota de privacidad de BooBoard';

  @override
  String get privacyStoredEmoji => 'Emoji recientes';

  @override
  String get privacyStoredApps => 'Lista de apps';

  @override
  String get privacyStoredOther => 'Otros datos guardados';

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
      'Escribe la forma abreviada que quieres expandir.';

  @override
  String shortcutProblemTriggerTooLong(num count) {
    return 'La forma abreviada puede tener como máximo $count caracteres.';
  }

  @override
  String get shortcutProblemTriggerCharacters =>
      'Usa solo letras, números y apóstrofos en la forma abreviada.';

  @override
  String get shortcutProblemEmptyExpansion =>
      'Escribe a qué debe expandirse la forma abreviada.';

  @override
  String shortcutProblemExpansionTooLong(num count) {
    return 'La expansión puede tener como máximo $count caracteres.';
  }

  @override
  String get shortcutProblemDuplicate =>
      'Ya tienes un atajo con esta forma abreviada.';

  @override
  String shortcutProblemTooMany(num count) {
    return 'Puedes tener como máximo $count atajos.';
  }

  @override
  String get onboardingWelcomeTitle => 'Hola, soy *Boo.*';

  @override
  String get onboardingWelcomeBody =>
      'Soy un teclado que nunca se conecta a internet. Lo que escribes se queda en este teléfono, bajo llave.';

  @override
  String get onboardingWelcomeStart => 'Empezar';

  @override
  String get onboardingMascotLabel => 'Boo, el fantasma de BooBoard';

  @override
  String get onboardingFactNoInternet => 'Sin permiso de internet';

  @override
  String get onboardingFactOpenSource => 'Código abierto';

  @override
  String get onboardingFactOpenSourceBody =>
      'Cualquiera puede leer el código y comprobarlo.';

  @override
  String get onboardingDemoKeyboards => 'Apps de teclado';

  @override
  String get onboardingDemoOtherKeyboard => 'Otro teclado';

  @override
  String get onboardingDemoAttention => 'Atención';

  @override
  String get onboardingDemoAttentionBody =>
      'Este teclado podría recopilar todo el texto que escribas…';

  @override
  String get onboardingDemoOk => 'Aceptar';

  @override
  String get onboardingDemoChooseInput => 'Elegir método de entrada';

  @override
  String get onboardingDemoSwitchOn => 'Activar';

  @override
  String get onboardingDemoTapOk => 'OK y OK';

  @override
  String get onboardingDemoComeBack => 'Vuelve';

  @override
  String get onboardingDemoPick => 'Elige BooBoard';

  @override
  String get onboardingDemoStartTyping => 'Empieza a escribir';

  @override
  String get onboardingDemoRebootNote =>
      'Nota: Después de reiniciar, esta app no puede iniciarse hasta que desbloquees el teléfono';

  @override
  String get onboardingDemoChatIn => '¿Nos vemos a las 7?';

  @override
  String get onboardingDemoChatOut => 'Voy para allá';

  @override
  String get onboardingDemoMessage => 'Mensaje';

  @override
  String get onboardingShh => 'shh';

  @override
  String get onboardingTryMe => 'Pruébame';

  @override
  String get onboardingTurnOnTitle => 'Activa *BooBoard*';

  @override
  String get onboardingTurnOnBody =>
      'Actívalo en la lista de teclados de Android y vuelve. Esta página lo detecta sola.';

  @override
  String get onboardingKeyboardOn => 'BooBoard está activado';

  @override
  String get onboardingKeyboardOff => 'Aún no está activado';

  @override
  String get onboardingOpenKeyboardSettings => 'Abrir ajustes del teclado';

  @override
  String get onboardingSwitchTitle => 'Hazlo *tuyo*';

  @override
  String get onboardingSwitchBody =>
      'Elige BooBoard en la lista corta de Android. Puedes volver a cambiar cuando quieras.';

  @override
  String get onboardingKeyboardIsYours => 'BooBoard es tu teclado';

  @override
  String get onboardingKeyboardNotYours => 'Aún no es tu teclado';

  @override
  String get onboardingTurnOnFirst => 'Actívalo primero';

  @override
  String get onboardingChooseKeyboard => 'Elegir teclado';

  @override
  String get onboardingCheckingPermissions =>
      'Comprobando los permisos de la app…';

  @override
  String get onboardingDebugInternet =>
      'Esta versión de depuración puede acceder a Internet. Tiene ese permiso solo para desarrollo.';

  @override
  String get onboardingReleaseInternet =>
      'Esta versión puede acceder a Internet.';

  @override
  String get onboardingNoInternet =>
      'BooBoard no tiene permiso de Internet, así que no puede enviar nada a ningún sitio.';

  @override
  String get onboardingWarningTitle => 'Sobre esa *advertencia*';

  @override
  String get onboardingWarningBody =>
      'Android la muestra con todos los teclados, porque un teclado podría enviar lo que escribes a internet. BooBoard no puede.';

  @override
  String get onboardingInternetAccess => 'Acceso a Internet';

  @override
  String get onboardingEverythingHere => 'Se queda en este teléfono';

  @override
  String get onboardingEverythingHereBody =>
      'Las palabras aprendidas, el portapapeles y los ajustes se cifran con una clave en Android Keystore.';

  @override
  String get onboardingLanguagesTitle => 'Tus *idiomas*';

  @override
  String get onboardingThemeTitle => 'Tema';

  @override
  String get onboardingTryTyping => 'Escribe una frase';

  @override
  String get onboardingTrySwipe => 'Desliza una palabra, letra a letra';

  @override
  String get onboardingTryAccents => 'Mantén una letra para ver acentos';

  @override
  String get onboardingTryTitle => '*Pruébalo*';

  @override
  String get onboardingTryField => 'Escribe algo aquí';

  @override
  String get onboardingAllSetTitle => '*Todo listo.*';

  @override
  String get onboardingAllSetBody =>
      'Idiomas, escritura, temas y más están en Ajustes cuando quieras.';

  @override
  String onboardingStepOf(String step, String total) {
    return 'Paso $step de $total';
  }

  @override
  String get onboardingBack => 'Atrás';

  @override
  String get onboardingNext => 'Siguiente';

  @override
  String get onboardingDone => 'Listo';

  @override
  String get onboardingSearchLanguages => 'Buscar idiomas';

  @override
  String onboardingSelected(String languages) {
    return 'Seleccionados: $languages';
  }

  @override
  String get onboardingNoLanguageMatch =>
      'Ningún idioma coincide con la búsqueda.';

  @override
  String get themeCreate => 'Crear tema';

  @override
  String themeSelectedLabel(String name) {
    return '$name, seleccionado';
  }

  @override
  String themeCardOptions(String name) {
    return 'Opciones de $name';
  }

  @override
  String get themeEdit => 'Editar';

  @override
  String get themeDuplicate => 'Duplicar';

  @override
  String get themeRename => 'Cambiar nombre';

  @override
  String get themeDeleteAction => 'Eliminar';

  @override
  String get themeTryTyping => 'Prueba a escribir';

  @override
  String get themeTryLabel => 'Escribe aquí para probar el tema';

  @override
  String get themeTryHelper =>
      'El teclado aparece aquí cuando BooBoard está seleccionado.';

  @override
  String get themeRenameTitle => 'Cambiar nombre del tema';

  @override
  String get themeNameField => 'Nombre';

  @override
  String get themeEditTitle => 'Editar tema';

  @override
  String get themeNewTitle => 'Tema nuevo';

  @override
  String get themeEditorTitle => 'Tema';

  @override
  String get themeOpenFailed => 'No se pudo abrir este tema.';

  @override
  String get themeSaveFailed => 'No se pudo guardar el tema.';

  @override
  String get themePhotoPickerFailed => 'No se pudo abrir el selector de fotos.';

  @override
  String get themeDiscardTitle => '¿Descartar los cambios?';

  @override
  String get themeDiscardBody =>
      'Se perderán los cambios que hiciste en este tema.';

  @override
  String get themeKeepEditing => 'Seguir editando';

  @override
  String get themeDiscard => 'Descartar';

  @override
  String get themeSave => 'Guardar';

  @override
  String get themeNameRequired => 'Se necesita un nombre';

  @override
  String get themeNameLabel => 'Nombre del tema';

  @override
  String get themeDefaultName => 'Mi tema';

  @override
  String get themeSectionName => 'Nombre';

  @override
  String get themeSectionLook => 'Aspecto';

  @override
  String get themeDarkMode => 'Modo oscuro';

  @override
  String get themeChoiceSystem => 'Sistema';

  @override
  String get themeChoiceLight => 'Claro';

  @override
  String get themeChoiceDark => 'Oscuro';

  @override
  String get themePureBlack => 'Negro puro';

  @override
  String get themePureBlackBody => 'Fondo negro';

  @override
  String get themePureBlackOnlyDark => 'Solo en modo oscuro';

  @override
  String get themeGalleryPureBlackDark => 'Fondo negro en modo oscuro';

  @override
  String get themeContrast => 'Contraste';

  @override
  String get themeChoiceStandard => 'Estándar';

  @override
  String get themeChoiceMedium => 'Medio';

  @override
  String get themeChoiceHigh => 'Alto';

  @override
  String get themeKeyboardHeight => 'Altura del teclado';

  @override
  String get themeSectionColours => 'Colores';

  @override
  String get themeSource => 'Origen';

  @override
  String get themeSourceWallpaper => 'Fondo de pantalla';

  @override
  String get themeSourceSeed => 'Color base';

  @override
  String get themeSourcePerRole => 'Por función';

  @override
  String get themeWallpaperNeedsAndroid12 =>
      'Los colores del fondo de pantalla necesitan Android 12 o una versión más reciente.';

  @override
  String get themeSeedColour => 'Color base';

  @override
  String get themeScheme => 'Esquema';

  @override
  String get themeColourRoles => 'Funciones de color';

  @override
  String themeEditingColours(String mode) {
    String _temp0 = intl.Intl.selectLogic(mode, {
      'dark': 'Editando los colores oscuros',
      'other': 'Editando los colores claros',
    });
    return '$_temp0';
  }

  @override
  String get themeResetRoles => 'Restablecer todas las funciones';

  @override
  String get themeKeys => 'Teclas';

  @override
  String get themeShape => 'Forma';

  @override
  String get themeShapePill => 'Píldora';

  @override
  String get themeShapeRounded => 'Redondeada';

  @override
  String get themeShapeSquare => 'Cuadrada';

  @override
  String get themeKeyBorders => 'Bordes de las teclas';

  @override
  String get themeBorderWidth => 'Ancho del borde';

  @override
  String get themeKeyGap => 'Espacio entre teclas';

  @override
  String get themeFontWeight => 'Grosor de la fuente';

  @override
  String get themeFontSize => 'Tamaño de la fuente';

  @override
  String get themeHintCharacters => 'Caracteres de sugerencia';

  @override
  String get themeHintCharactersBody =>
      'Caracteres pequeños al mantener pulsado';

  @override
  String get themeBackground => 'Fondo';

  @override
  String get themeBackgroundType => 'Tipo';

  @override
  String get themeTypeSolid => 'Sólido';

  @override
  String get themeTypeGradient => 'Degradado';

  @override
  String get themeTypePhoto => 'Foto';

  @override
  String get themeNoPhotoYet =>
      'Todavía no hay foto. Elige una para recortarla al teclado.';

  @override
  String get themeChoosePhoto => 'Elegir foto';

  @override
  String get themeEditCrop => 'Editar recorte y desenfoque';

  @override
  String get themeDim => 'Atenuar';

  @override
  String get themeSectionPopups => 'Ventanas emergentes y rastro';

  @override
  String get themeSolidPopups => 'Ventanas sólidas';

  @override
  String get themeSolidPopupsBodyWallpaper =>
      'No con colores del fondo de pantalla';

  @override
  String get themeSolidPopupsBodyPrimary =>
      'Ventanas emergentes en el color primario';

  @override
  String get themeSwipeTrail => 'Rastro de deslizamiento';

  @override
  String get themeTrailWidth => 'Ancho del rastro';

  @override
  String get themeTrailFade => 'Desvanecimiento del rastro';

  @override
  String get themeTrailInstant => 'Instantáneo';

  @override
  String get themeTrailColours => 'Colores del rastro';

  @override
  String get themeTrailStart => 'Inicio';

  @override
  String get themeTrailEnd => 'Fin';

  @override
  String get themeTrailStartTitle => 'Inicio del rastro';

  @override
  String get themeTrailEndTitle => 'Fin del rastro';

  @override
  String get themeAutomatic => 'Automático';

  @override
  String get themeSectionMotion => 'Movimiento';

  @override
  String get themeKeyPressAnimation => 'Animación al pulsar tecla';

  @override
  String get themeReduceMotion =>
      '«Quitar animaciones» está activado en los ajustes del sistema, así que las teclas no se animan.';

  @override
  String get themeMotionOff => 'Desactivado';

  @override
  String get themeMotionSubtle => 'Sutil';

  @override
  String get themeMotionStandard => 'Estándar';

  @override
  String get themeMotionBouncy => 'Rebotante';

  @override
  String get themeSchemeTonalSpot => 'Punto tonal';

  @override
  String get themeSchemeVibrant => 'Vibrante';

  @override
  String get themeSchemeExpressive => 'Expresivo';

  @override
  String get themeSchemeFidelity => 'Fidelidad';

  @override
  String get themeSchemeContent => 'Contenido';

  @override
  String get themeSchemeMonochrome => 'Monocromo';

  @override
  String get themeSchemeNeutral => 'Neutro';

  @override
  String get themeSchemeRainbow => 'Arcoíris';

  @override
  String get themeSchemeFruitSalad => 'Macedonia';

  @override
  String themeCustomColourHex(String hex) {
    return 'Color personalizado #$hex';
  }

  @override
  String get themeCustomColour => 'Color personalizado';

  @override
  String themeSwatchLabel(String hex, String label) {
    return 'Color $label, #$hex';
  }

  @override
  String themeUseSchemeColour(String label) {
    return 'Usar el color del esquema para $label';
  }

  @override
  String get themeFromScheme => 'Del esquema';

  @override
  String get themeOverridden => 'Definido';

  @override
  String themeStopLabel(String n) {
    return 'Punto $n';
  }

  @override
  String themePickStopTitle(String n) {
    return 'Punto $n';
  }

  @override
  String get themeAddStop => 'Añadir punto';

  @override
  String get themeRemoveStop => 'Quitar punto';

  @override
  String get themeAngle => 'Ángulo';

  @override
  String get themeUseSchemeTooltipLabel => 'Usar el color del esquema';

  @override
  String get themeCropTitle => 'Recortar foto';

  @override
  String get themeUsePhoto => 'Usar foto';

  @override
  String get themeCropSaveFailed => 'No se pudo guardar la foto.';

  @override
  String get themeCropSemantics =>
      'Recorte de foto. Arrastra para mover la foto y pellizca o usa el control de zoom para ampliar.';

  @override
  String get themeCropZoom => 'Zoom';

  @override
  String get themeCropBlur => 'Desenfoque';

  @override
  String get themeCropBlurOff => 'Desactivado';

  @override
  String get themeCropNote =>
      'El desenfoque se guarda en la imagen. El atenuado se ajusta en el editor y se aplica en vivo.';

  @override
  String get themeHexLabel => 'Hex';

  @override
  String get themeHexError => 'Usa seis dígitos hexadecimales, como F5B700';

  @override
  String get themeHue => 'Tono';

  @override
  String get themeSaturation => 'Saturación';

  @override
  String get themeBrightness => 'Brillo';

  @override
  String get themePickShadeHint => 'Elige un tono y toca Usar.';

  @override
  String get themePickColourUse => 'Usar';

  @override
  String get themeCopySuffix => 'copia';

  @override
  String themeCopyName(String name) {
    return 'Copia de $name';
  }

  @override
  String themeDeleteTitle(String name) {
    return '¿Eliminar «$name»?';
  }

  @override
  String get themeDeleteSelectedBody =>
      'Este tema está seleccionado. Se usará BooBoard Dynamic en su lugar. No se puede deshacer.';

  @override
  String get themeDeleteBody => 'Esto no se puede deshacer.';

  @override
  String get themeDeleteFailed => 'No se pudo eliminar el tema.';

  @override
  String get themeRenameFailed => 'No se pudo cambiar el nombre del tema.';

  @override
  String get themeDuplicateFailed => 'No se pudo copiar el tema.';

  @override
  String get themeSettingFailed => 'No se pudo guardar el ajuste.';

  @override
  String get themeSystemColoursUnavailable =>
      'Los colores del sistema no están disponibles.';

  @override
  String get themeBooBoardDynamicFollows =>
      'BooBoard Dynamic sigue tu fondo de pantalla';

  @override
  String get themeBooBoardDynamicBody =>
      'Sus colores se actualizan cuando cambia el fondo de pantalla';

  @override
  String get themeSectionPresets => 'Ajustes preestablecidos';

  @override
  String get themeSectionMyThemes => 'Mis temas';

  @override
  String get themeSectionTry => 'Prueba a escribir';

  @override
  String get themeAppearance => 'Apariencia';

  @override
  String get themesTitle => 'Temas';

  @override
  String privacyThemesSize(int count, String size) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count archivos de tema',
      one: '1 archivo de tema',
    );
    return '$_temp0 · $size';
  }

  @override
  String get backupUnlockToSeeCount =>
      'Desbloquea el teléfono para ver el recuento';

  @override
  String get shortcutHelp =>
      'Un atajo convierte una forma abreviada en un texto más largo. Ejemplos:\nomw → on my way\naddr → your address';

  @override
  String privacyStoredLearned(String language) {
    return 'Palabras aprendidas ($language)';
  }

  @override
  String get settingsComingLater => 'Disponible en una actualización posterior';

  @override
  String get backupExplainer =>
      'Una copia es un solo archivo, cifrado con una frase de contraseña que tú eliges. Solo esa frase lo abre. Si olvidas la frase, nadie puede recuperar la copia, ni siquiera BooBoard.';

  @override
  String privacyCategoryLine(String detail, String title) {
    return '$title: $detail';
  }

  @override
  String get shortcutShortFormHint => 'omw';

  @override
  String get shortcutExpansionHint => 'on my way';

  @override
  String get durationMinutes15 => '15 minutos';

  @override
  String get durationHour => '1 hora';

  @override
  String get durationDay => '1 día';

  @override
  String get durationWeek => '1 semana';

  @override
  String get onboardingCloseSetup => 'Cerrar configuración';

  @override
  String get packsCouldNotRead => 'BooBoard no pudo leer sus paquetes';

  @override
  String packsDeleteTooltip(String name) {
    return 'Eliminar $name';
  }

  @override
  String get privacyNothingStored => 'Todavía no hay nada guardado';

  @override
  String privacyRemoveAppTooltip(String app) {
    return 'Quitar $app de la lista';
  }

  @override
  String get chineseTitle => 'Chino';

  @override
  String get chineseTraditional => 'Caracteres tradicionales';

  @override
  String get chineseTraditionalBody =>
      'Muestra los candidatos en caracteres tradicionales (estándar de Taiwán).';

  @override
  String get chineseFuzzy => 'Pinyin aproximado';

  @override
  String get chineseFuzzyBody =>
      'Acepta también z y zh, c y ch, s y sh, n y l, an y ang, en y eng, in y ing.';

  @override
  String get cjkDictionary => 'Diccionario';

  @override
  String get chineseClearPhrases => 'Borrar frases aprendidas';

  @override
  String get chineseClearPhrasesBody =>
      'Olvida las palabras que elegiste. El diccionario se conserva.';

  @override
  String get chineseFooter =>
      'El chino se escribe en este teléfono. Las frases aprendidas están cifradas y nunca salen de él.';

  @override
  String get chineseClearTitle => '¿Borrar las frases aprendidas?';

  @override
  String get chineseClearBody =>
      'Se eliminan las palabras que elegiste para el chino. No se puede deshacer.';

  @override
  String get cjkClear => 'Borrar';

  @override
  String get chinesePhrasesCleared => 'Frases aprendidas borradas';

  @override
  String get chineseLooking => 'Buscando el diccionario';

  @override
  String get chineseDictName => 'Diccionario de chino';

  @override
  String get chinesePackMissing =>
      'No instalado. Escribir en chino lo necesita; instálalo en Paquetes de modelos.';

  @override
  String chinesePackInstalled(String license) {
    return 'Instalado. $license';
  }

  @override
  String get japaneseTitle => 'Japonés';

  @override
  String get japaneseLayout => 'Disposición';

  @override
  String get japaneseLayout12 => '12 teclas (deslizar)';

  @override
  String get japaneseLayoutRomaji => 'Romaji (QWERTY)';

  @override
  String get japaneseTyping => 'Escritura';

  @override
  String get japaneseFlickOnly => 'Solo deslizar';

  @override
  String get japaneseFlickOnlyBody =>
      'Sin pulsación múltiple: tocar あ dos veces escribe ああ, no い';

  @override
  String get japaneseHalfWidth => 'Espacio de ancho normal';

  @override
  String get japaneseHalfWidthBody =>
      'El espacio escribe un espacio normal cuando no se está componiendo. Desactivado escribe un espacio de ancho completo.';

  @override
  String get japaneseDictPack => 'Paquete de diccionario';

  @override
  String get japaneseChecking => 'Comprobando...';

  @override
  String japaneseInstalled(String name) {
    return '$name está instalado. La conversión a kanji está activada.';
  }

  @override
  String get japaneseNotInstalled =>
      'No instalado. El kana se escribe igualmente; los kanji necesitan el paquete.';

  @override
  String get japaneseClearWords => 'Borrar palabras aprendidas';

  @override
  String get japaneseClearWordsBody =>
      'Olvida las palabras japonesas que elegiste. Se guardan cifradas en este teléfono.';

  @override
  String get japaneseClearTitle => '¿Borrar las palabras japonesas aprendidas?';

  @override
  String get japaneseClearBody =>
      'Se elimina cada palabra japonesa que elegiste. No se puede deshacer.';

  @override
  String get privacyStoredChinesePhrases => 'Frases en chino';

  @override
  String get privacyStoredJapaneseWords => 'Palabras en japonés';
}
