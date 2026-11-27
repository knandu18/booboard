// Pigeon contract between the Kotlin shell and Dart.
// Regenerate with:  dart run pigeon --input pigeons/messages.dart
//
// This file is a FROZEN CONTRACT for parallel work. Only the orchestrator edits it.
// Feature agents that need a new call describe it in their report instead.
import 'package:pigeon/pigeon.dart';

@ConfigurePigeon(
  PigeonOptions(
    dartOut: 'lib/src/bridge/messages.g.dart',
    dartOptions: DartOptions(),
    kotlinOut: 'android/app/src/main/kotlin/app/booboard/keyboard/bridge/Messages.g.kt',
    kotlinOptions: KotlinOptions(package: 'app.booboard.keyboard.bridge'),
    copyrightHeader: 'pigeons/copyright.txt',
    dartPackageName: 'booboard',
  ),
)
// ---------------------------------------------------------------------------
// Data
// ---------------------------------------------------------------------------
/// Snapshot of android.view.inputmethod.EditorInfo (raw values; decode in Dart
/// with InputFieldInfo).
class EditorInfoMessage {
  EditorInfoMessage({
    required this.inputType,
    required this.imeOptions,
    required this.actionId,
    required this.fieldId,
    required this.initialSelStart,
    required this.initialSelEnd,
    required this.initialCapsMode,
  });
  int inputType;
  int imeOptions;
  int actionId;
  String? actionLabel;
  String? packageName;
  String? hintText;
  int fieldId;
  int initialSelStart;
  int initialSelEnd;
  int initialCapsMode;
  String? privateImeOptions;
  List<String>? contentMimeTypes;
}

class SelectionMessage {
  SelectionMessage({
    required this.oldSelStart,
    required this.oldSelEnd,
    required this.newSelStart,
    required this.newSelEnd,
    required this.candidatesStart,
    required this.candidatesEnd,
  });
  int oldSelStart;
  int oldSelEnd;
  int newSelStart;
  int newSelEnd;

  /// Composing region reported by the editor, -1 when none.
  int candidatesStart;
  int candidatesEnd;
}

class SurroundingTextMessage {
  SurroundingTextMessage({
    required this.text,
    required this.selectionStart,
    required this.selectionEnd,
    required this.offset,
  });
  String text;

  /// Relative to [text].
  int selectionStart;
  int selectionEnd;

  /// Absolute editor offset of text[0], -1 when unknown.
  int offset;
}

class ClipMessage {
  ClipMessage({required this.text, required this.timestampMillis, required this.isSensitive});
  String text;
  int timestampMillis;

  /// ClipDescription.EXTRA_IS_SENSITIVE (Android 13+). Never store these.
  bool isSensitive;
}

class WindowMetricsMessage {
  WindowMetricsMessage({
    required this.screenWidthPx,
    required this.screenHeightPx,
    required this.density,
    required this.navigationBarInsetPx,
    required this.isLandscape,
    required this.smallestScreenWidthDp,
    required this.fontScale,
    required this.isNightMode,
  });
  int screenWidthPx;
  int screenHeightPx;
  double density;
  int navigationBarInsetPx;
  bool isLandscape;
  int smallestScreenWidthDp;
  double fontScale;
  bool isNightMode;
}

/// Material You palettes (Android 12+): 5 palettes x 13 tones (ARGB), in
/// order accent1, accent2, accent3, neutral1, neutral2 and tones
/// 0,10,50,100,200,300,400,500,600,700,800,900,1000.
class SystemColorsMessage {
  SystemColorsMessage({required this.palettes, required this.isNightMode});
  List<int> palettes;
  bool isNightMode;
}

class RectMessage {
  RectMessage({required this.left, required this.top, required this.width, required this.height});

  /// Logical pixels (dp), relative to the keyboard content area.
  double left;
  double top;
  double width;
  double height;
}

enum WindowMode { docked, floating }

class WindowLayoutMessage {
  WindowLayoutMessage({required this.mode, required this.heightDp});
  WindowMode mode;

  /// Total height of the keyboard view in dp, INCLUDING the bottom inset
  /// (Dart adds MediaQuery.viewPadding.bottom: the gesture bar / IME
  /// navigation buttons live there). Kotlin applies it verbatim.
  double heightDp;

  /// Floating mode only: the visible keyboard rect inside the IME window.
  RectMessage? floatingRect;
}

enum HapticKind { keyTap, keyLongPress, repeatTick, gestureStart, gestureCommit, toggle, error }

enum KeySoundKind { standard, space, delete, enter }

class FeedbackConfigMessage {
  FeedbackConfigMessage({
    required this.hapticsEnabled,
    required this.hapticStrength,
    required this.soundsEnabled,
    required this.soundVolume,
  });
  bool hapticsEnabled;

  /// 0..1
  double hapticStrength;
  bool soundsEnabled;

  /// 0..1, or -1 for the system default volume.
  double soundVolume;
}

enum ContextMenuAction {
  selectAll,
  cut,
  copy,
  paste,
  pasteAsPlainText,
  undo,
  redo,
  startSelectingText,
  stopSelectingText,
}

/// One blob in the encrypted store (for the privacy center's "what is stored" list).
class SecureBlobInfo {
  SecureBlobInfo({required this.name, required this.sizeBytes, required this.modifiedMillis});

  /// The name passed to secureWrite.
  String name;

  /// Encrypted size on disk, including the last-good backup copy.
  int sizeBytes;
  int modifiedMillis;
}

class AppInfoMessage {
  AppInfoMessage({
    required this.packageName,
    required this.versionName,
    required this.versionCode,
    required this.sdkInt,
    required this.isDebugBuild,
  });
  String packageName;
  String versionName;
  int versionCode;
  int sdkInt;
  bool isDebugBuild;
}

// ---------------------------------------------------------------------------
// Wave 3: model packs, voice typing, translation
// ---------------------------------------------------------------------------

/// Wave 4 adds `dictionary` (Chinese and Japanese conversion data, read from the pack folder).
/// Images adds `image` (the picture model, read by the `:images` helper process). New kinds are appended.
enum PackKind { voice, translation, dictionary, image }

/// An installed, verified model pack (see docs/waves/wave3/COMMON.md, "Pack format").
class PackInfoMessage {
  PackInfoMessage({
    required this.id,
    required this.kind,
    required this.name,
    required this.version,
    required this.languages,
    required this.sizeBytes,
    required this.engine,
    required this.license,
  });

  /// For example 'voice-parakeet-en' or 'translate-en-es'.
  String id;
  PackKind kind;

  /// Display name from the manifest.
  String name;
  int version;

  /// Voice: languages the model can recognise. Translation: exactly [from, to].
  List<String> languages;

  /// Installed size on disk.
  int sizeBytes;

  /// Engine id from the manifest, for example 'sherpa-onnx-nemo-transducer' or 'opus-mt-onnx'.
  String engine;
  String license;
}

/// Result of re-checking one installed pack against its signed manifest. Counts only, never paths.
class PackCheckMessage {
  PackCheckMessage({
    required this.id,
    required this.manifestOk,
    required this.missingFiles,
    required this.damagedFiles,
  });

  String id;
  bool manifestOk;
  int missingFiles;
  int damagedFiles;
}

/// Free space on the storage that holds packs.
class PackStorageMessage {
  PackStorageMessage({required this.freeBytes});

  int freeBytes;
}

/// Where a store delivery stands (play flavour). Mirrors `PackOfferStatus` in lib/src/packs/pack_maintenance.dart.
enum PackOfferStatusMessage { notRequested, waitingForNetwork, downloading, installing, failed, ready }

/// A pack the store can deliver to this phone. Empty list in import-only builds (foss).
class PackOfferMessage {
  PackOfferMessage({required this.id, required this.name, required this.sizeBytes, required this.status});

  String id;
  String name;
  int sizeBytes;
  PackOfferStatusMessage status;
}

enum VoiceStartStatus { started, noPermission, noModel, busy, failed }

class VoiceRequestMessage {
  VoiceRequestMessage({required this.packId});

  /// Keyboard language ('en', 'en-GB', ...). Voice typing works in English only: other languages get noModel.
  String? language;
  String packId;
}

enum VoiceEventKind {
  /// Input level changed ([VoiceEventMessage.level], about 20 per second).
  level,

  /// Interim text for the current utterance (replaces the previous partial).
  partial,

  /// Final text for one utterance (voice-activity detection closed it).
  finalText,

  /// Recording ended (after stopVoice, cancelVoice, silence timeout or an error). Last event.
  stopped,

  /// Something failed ([VoiceEventMessage.errorCode]); a `stopped` event follows.
  error,
}

class VoiceEventMessage {
  VoiceEventMessage({required this.kind, required this.level});
  VoiceEventKind kind;
  String? text;

  /// 0..1, only meaningful for [VoiceEventKind.level].
  double level;

  /// 'audio_busy', 'model_failed', 'permission_revoked', 'internal'.
  String? errorCode;
}

/// Result of [ImeHostApi.makeImage].
enum ImageStartStatus {
  /// The helper was asked to make the picture; progress and the result arrive via ImeFlutterApi.onImageEvent.
  started,

  /// No image pack is installed (or its model files are missing).
  noPack,

  /// This phone's CPU type has no image engine (only arm64-v8a and x86_64 do), or the helper cannot start.
  unsupported,

  /// A picture is already being made. One at a time.
  busy,
}

class ImageRequestMessage {
  ImageRequestMessage({required this.prompt});

  /// The words to turn into a picture. Never logged, on either side.
  String prompt;

  /// Null picks a random seed.
  int? seed;
}

enum ImageEventKind {
  /// The model is being loaded (first picture after a pause; takes a few seconds).
  loading,

  /// Sampling: [ImageEventMessage.step] of [ImageEventMessage.steps].
  step,

  /// The picture is being decoded.
  decoding,

  /// Finished: [ImageEventMessage.path] is a PNG in the keyboard's cache, [ImageEventMessage.millis] the time taken.
  /// Only the last few pictures are kept there.
  done,

  /// Stopped by stopImage. Last event.
  cancelled,

  /// Failed ([ImageEventMessage.error]). Last event.
  error,
}

class ImageEventMessage {
  ImageEventMessage({required this.kind, required this.step, required this.steps});

  ImageEventKind kind;

  /// 1-based sampling step, only meaningful for [ImageEventKind.step].
  int step;

  /// Total sampling steps (4 for now), only meaningful for [ImageEventKind.step].
  int steps;

  /// Only for [ImageEventKind.done].
  String? path;

  /// Only for [ImageEventKind.done]: loading plus making, in milliseconds.
  int? millis;

  /// Only for [ImageEventKind.error]: 'unsupported' (no engine on this phone), 'load_failed', 'failed',
  /// 'busy', 'helper_died' (the helper process was closed, most likely for memory). Never contains the prompt.
  String? error;
}

// ---------------------------------------------------------------------------
// Dart -> Kotlin
// ---------------------------------------------------------------------------

/// Registered only on the keyboard (IME) engine.
@HostApi()
abstract class ImeHostApi {
  // InputConnection ---------------------------------------------------------
  bool commitText(String text, int newCursorPosition);
  bool setComposingText(String text, int newCursorPosition);
  bool setComposingRegion(int start, int end);
  bool finishComposingText();
  bool deleteSurroundingText(int beforeLength, int afterLength);
  bool deleteSurroundingTextInCodePoints(int beforeLength, int afterLength);
  bool sendDownUpKeyEvent(int keyCode, int metaState);
  bool performEditorAction(int actionId);
  bool performContextMenuAction(ContextMenuAction action);
  bool setSelection(int start, int end);
  String? getTextBeforeCursor(int length);
  String? getTextAfterCursor(int length);
  String? getSelectedText();
  SurroundingTextMessage? getSurroundingText(int beforeLength, int afterLength);
  int getCursorCapsMode(int reqModes);
  bool beginBatchEdit();
  bool endBatchEdit();

  // Keyboard window ---------------------------------------------------------
  void setWindowLayout(WindowLayoutMessage layout);
  void setSecureWindow(bool secure);
  void hideKeyboard();
  bool switchToPreviousInputMethod();
  bool switchToNextInputMethod(bool onlyCurrentIme);
  void showInputMethodPicker();
  void openSettings(String? route);

  /// The keyboard's background colour (ARGB) where it meets the navigation bar, so Kotlin can pick
  /// dark or light navigation-bar icons (API 30+). Call when the theme changes.
  void setNavigationBarStyle(int backgroundArgb);

  /// The user-visible name of the app the keyboard is typing into. The IME can see the app it is
  /// bound to without QUERY_ALL_PACKAGES. Null when unknown.
  String? getAppLabel(String packageName);

  /// Where the suggestion strip is, so Kotlin can overlay Android inline
  /// autofill suggestions there. null hides them.
  void setInlineSuggestionsArea(RectMessage? area);

  // Feedback ----------------------------------------------------------------
  void setFeedbackConfig(FeedbackConfigMessage config);
  void performHaptic(HapticKind kind);
  void playKeySound(KeySoundKind kind);

  // Clipboard ---------------------------------------------------------------
  ClipMessage? getPrimaryClip();
  void setPrimaryClip(String text, bool sensitive);
  void clearPrimaryClip();

  // Voice typing (Wave 3-D) ------------------------------------------------

  bool hasMicPermission();

  /// Opens the transparent, non-exported permission activity. True if granted.
  @async
  bool requestMicPermission();

  /// Starts recording with an installed voice pack. Events arrive via ImeFlutterApi.onVoiceEvent.
  @async
  VoiceStartStatus startVoice(VoiceRequestMessage request);

  /// Stop listening, deliver the last finalText, then `stopped`.
  void stopVoice();

  /// Stop and discard: no more text events, then `stopped`.
  void cancelVoice();

  // Images (offline picture making in the `:images` helper process) ---------

  /// Asks the helper to make one picture with the installed image pack (512x512, 4 steps). Returns once the
  /// request was handed over; progress and the result arrive via ImeFlutterApi.onImageEvent. One at a time.
  @async
  ImageStartStatus makeImage(ImageRequestMessage request);

  /// Asks the helper to stop the picture being made: a `cancelled` event follows. Does nothing when idle.
  void stopImage();

  // Translation (Wave 3-T) --------------------------------------------------

  /// Translates on the device. Throws code `no_pack` when no installed pack covers [from] -> [to],
  /// `failed` otherwise. Never logs [text].
  @async
  String translate(String text, String from, String to);

  /// Frees the loaded translation model (panel closed, memory pressure).
  void releaseTranslator();

  // State sync (Dart may start after Kotlin already received callbacks) ------
  WindowMetricsMessage getWindowMetrics();
  EditorInfoMessage? getCurrentEditorInfo();
  bool isInputViewShown();
}

/// Registered on both engines.
@HostApi()
abstract class PlatformHostApi {
  SystemColorsMessage? getSystemColors();

  /// Encrypted (AES-256-GCM, Android Keystore key) blob storage in no-backup
  /// app storage. [name] must match [a-z0-9_.-]{1,64}.
  @TaskQueue(type: TaskQueueType.serialBackgroundThread)
  Uint8List? secureRead(String name);

  /// Like [secureRead], for the backup restore only (SEC-06): null when the blob is missing or damaged,
  /// and an error with code `secure_store_locked` while the key cannot be used (phone locked).
  @TaskQueue(type: TaskQueueType.serialBackgroundThread)
  Uint8List? secureReadStrict(String name);
  @TaskQueue(type: TaskQueueType.serialBackgroundThread)
  void secureWrite(String name, Uint8List data);
  @TaskQueue(type: TaskQueueType.serialBackgroundThread)
  void secureDelete(String name);
  @TaskQueue(type: TaskQueueType.serialBackgroundThread)
  void secureWipeAll();

  /// Every blob currently stored, with sizes. Never returns contents.
  @TaskQueue(type: TaskQueueType.serialBackgroundThread)
  List<SecureBlobInfo> secureList();

  /// True if the installed package requests android.permission.INTERNET
  /// (expected: false for release builds).
  bool hasInternetPermission();
  AppInfoMessage getAppInfo();

  /// Whether the device font can render each string (emoji filtering).
  List<bool> hasGlyphs(List<String> texts);

  /// Absolute path of app-private, no-backup storage for plain data files.
  String getDataDirectory();

  /// Tell the other engine that these settings sections changed on disk.
  void notifySettingsChanged(List<String> sections);

  /// Installed, verified model packs (Wave 3). Never returns file contents.
  @TaskQueue(type: TaskQueueType.serialBackgroundThread)
  List<PackInfoMessage> listPacks();

  /// Absolute path of an installed pack's folder, after re-verifying its signed manifest (Wave 4:
  /// dictionary packs are read directly by Dart), or null when [id] is not installed or invalid.
  /// Files sit at the paths the manifest lists.
  @TaskQueue(type: TaskQueueType.serialBackgroundThread)
  String? getPackDirectory(String id);
}

/// Registered only on the settings-app engine.
@HostApi()
abstract class AppHostApi {
  bool isBooBoardEnabled();
  bool isBooBoardSelected();
  void openInputMethodSettings();
  void showInputMethodPicker();

  /// FLAG_SECURE + no recents thumbnail for sensitive screens.
  void setSecureScreen(bool secure);

  /// The settings route the activity was started with (from the keyboard's toolbar or a
  /// notification), or null. Returns it once, then null. Later routes arrive via
  /// AppFlutterApi.onOpenRoute.
  String? takeLaunchRoute();

  // Backup files (Storage Access Framework, no storage permission) -- Wave 2-B ------

  /// ACTION_CREATE_DOCUMENT. Returns the content URI, or null if the user cancelled.
  @async
  String? createDocument(String suggestedName, String mimeType);

  /// ACTION_OPEN_DOCUMENT. Returns the content URI, or null if the user cancelled.
  @async
  String? openDocument(List<String> mimeTypes);

  @TaskQueue(type: TaskQueueType.serialBackgroundThread)
  void writeDocument(String uri, Uint8List data);

  /// Throws (code `too_large`) when the document is bigger than [maxBytes].
  @TaskQueue(type: TaskQueueType.serialBackgroundThread)
  Uint8List readDocument(String uri, int maxBytes);

  // Backup crypto (.boobackup): PBKDF2-HMAC-SHA256, 600k iterations, random salt,
  // AES-256-GCM -- Wave 2-B ------------------------------------------------------

  /// Encrypts [plain] into the complete .boobackup file bytes.
  @TaskQueue(type: TaskQueueType.serialBackgroundThread)
  Uint8List sealBackup(Uint8List plain, String passphrase);

  /// Decrypts a .boobackup file. Returns null for a wrong passphrase or a damaged file;
  /// throws (code `unsupported_version`) for a newer format.
  @TaskQueue(type: TaskQueueType.serialBackgroundThread)
  Uint8List? openBackup(Uint8List sealed, String passphrase);

  // Model packs (Wave 3) ------------------------------------------------------

  /// Verifies (signature, hashes) and installs a .boopack file from a SAF URI, replacing an
  /// installed pack with the same id. Throws code `bad_signature`, `bad_format`, `too_large`,
  /// `unsupported_version` or `no_space`.
  @TaskQueue(type: TaskQueueType.serialBackgroundThread)
  PackInfoMessage importPack(String uri);

  @TaskQueue(type: TaskQueueType.serialBackgroundThread)
  void deletePack(String id);

  // Pack maintenance (Wave 5-C, wired in the rename session) ----------------------------

  /// Re-checks every installed pack against its signed manifest and file hashes.
  @TaskQueue(type: TaskQueueType.serialBackgroundThread)
  List<PackCheckMessage> verifyPacks();

  /// Usable space on the storage that holds packs, or null when it cannot be read.
  @TaskQueue(type: TaskQueueType.serialBackgroundThread)
  PackStorageMessage? packStorage();

  /// 'import' (packs come from files the user imports: foss) or 'store' (the store delivers some: play).
  String packDelivery();

  /// Packs the store can deliver, with their state. Empty for 'import'.
  @TaskQueue(type: TaskQueueType.serialBackgroundThread)
  List<PackOfferMessage> packOffers();

  /// Asks the store to deliver pack [id]. Throws code `unsupported` in import-only builds.
  @TaskQueue(type: TaskQueueType.serialBackgroundThread)
  void requestPack(String id);

  /// Installs the store's copy of [id] with the same signature and hash checks as an imported file.
  /// Throws code `not_delivered` when the store has not delivered it yet, or the import codes
  /// (`bad_signature`, `bad_format`, `too_large`, `unsupported_version`, `no_space`).
  @TaskQueue(type: TaskQueueType.serialBackgroundThread)
  PackInfoMessage installDeliveredPack(String id);

  /// Opens the download of the published pack file [fileName] in the user's browser. BooBoard has no
  /// internet permission: the browser downloads the file, and the user imports it afterwards. Only the
  /// project's own release files are accepted (the URL is built on the platform side). Throws code
  /// `bad_link` for an unknown file name and `no_browser` when no app can open the link.
  void openPackDownload(String fileName);

  /// Opens BooBoard's website (https://booboard.com) in the user's browser. BooBoard has no internet
  /// permission: the browser loads the page. The address is fixed on the platform side. Throws code
  /// `no_browser` when no app can open the link.
  void openWebsite();
}

// ---------------------------------------------------------------------------
// Kotlin -> Dart
// ---------------------------------------------------------------------------

@FlutterApi()
abstract class ImeFlutterApi {
  @asyncCallback
  void onStartInput(EditorInfoMessage info, bool restarting);
  @asyncCallback
  void onStartInputView(EditorInfoMessage info, bool restarting);
  @asyncCallback
  void onFinishInputView(bool finishingInput);
  @asyncCallback
  void onFinishInput();
  @asyncCallback
  void onUpdateSelection(SelectionMessage selection);
  @asyncCallback
  void onWindowShown();
  @asyncCallback
  void onWindowHidden();
  @asyncCallback
  void onClipboardChanged(ClipMessage clip);
  @asyncCallback
  void onConfigurationChanged(WindowMetricsMessage metrics);
  @asyncCallback
  void onSystemColorsChanged();
  @asyncCallback
  void onTrimMemory(int level);
  @asyncCallback
  void onSettingsChanged(List<String> sections);
  @asyncCallback
  void onInlineSuggestionsChanged(int count);

  /// Voice typing events (Wave 3-D), in order, on the main thread.
  @asyncCallback
  void onVoiceEvent(VoiceEventMessage event);

  /// Picture making events (Images), in order, on the main thread. The last one is `done`, `cancelled` or `error`.
  @asyncCallback
  void onImageEvent(ImageEventMessage event);
}

@FlutterApi()
abstract class AppFlutterApi {
  @asyncCallback
  void onSettingsChanged(List<String> sections);

  /// The running settings activity was asked to show [route] (onNewIntent).
  @asyncCallback
  void onOpenRoute(String route);
}
