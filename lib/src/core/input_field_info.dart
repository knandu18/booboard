// SPDX-License-Identifier: GPL-3.0-or-later
//
// CONTRACT (Wave 0). Decodes Android EditorInfo into Dart-friendly facts.
import 'package:meta/meta.dart';

import '../bridge/messages.g.dart';

/// android.text.InputType constants.
abstract final class AndroidInputType {
  static const int maskClass = 0x0000000f;
  static const int maskVariation = 0x00000ff0;
  static const int maskFlags = 0x00fff000;

  static const int classNull = 0x0;
  static const int classText = 0x1;
  static const int classNumber = 0x2;
  static const int classPhone = 0x3;
  static const int classDatetime = 0x4;

  static const int textVariationNormal = 0x00;
  static const int textVariationUri = 0x10;
  static const int textVariationEmailAddress = 0x20;
  static const int textVariationEmailSubject = 0x30;
  static const int textVariationShortMessage = 0x40;
  static const int textVariationLongMessage = 0x50;
  static const int textVariationPersonName = 0x60;
  static const int textVariationPostalAddress = 0x70;
  static const int textVariationPassword = 0x80;
  static const int textVariationVisiblePassword = 0x90;
  static const int textVariationWebEditText = 0xa0;
  static const int textVariationFilter = 0xb0;
  static const int textVariationPhonetic = 0xc0;
  static const int textVariationWebEmailAddress = 0xd0;
  static const int textVariationWebPassword = 0xe0;

  static const int numberVariationPassword = 0x10;
  static const int datetimeVariationDate = 0x10;
  static const int datetimeVariationTime = 0x20;

  static const int textFlagCapCharacters = 0x1000;
  static const int textFlagCapWords = 0x2000;
  static const int textFlagCapSentences = 0x4000;
  static const int textFlagAutoCorrect = 0x8000;
  static const int textFlagAutoComplete = 0x10000;
  static const int textFlagMultiLine = 0x20000;
  static const int textFlagImeMultiLine = 0x40000;
  static const int textFlagNoSuggestions = 0x80000;

  static const int numberFlagSigned = 0x1000;
  static const int numberFlagDecimal = 0x2000;
}

/// android.view.inputmethod.EditorInfo imeOptions constants.
abstract final class AndroidImeOptions {
  static const int maskAction = 0xff;
  static const int actionUnspecified = 0;
  static const int actionNone = 1;
  static const int actionGo = 2;
  static const int actionSearch = 3;
  static const int actionSend = 4;
  static const int actionNext = 5;
  static const int actionDone = 6;
  static const int actionPrevious = 7;

  static const int flagNoPersonalizedLearning = 0x1000000;
  static const int flagNoFullscreen = 0x2000000;
  static const int flagNavigatePrevious = 0x4000000;
  static const int flagNavigateNext = 0x8000000;
  static const int flagNoExtractUi = 0x10000000;
  static const int flagNoAccessoryAction = 0x20000000;
  static const int flagNoEnterAction = 0x40000000;
  static const int flagForceAscii = 0x80000000;
}

/// android.text.TextUtils cap-mode flags (for getCursorCapsMode).
abstract final class AndroidCapsMode {
  static const int characters = 0x1000;
  static const int words = 0x2000;
  static const int sentences = 0x4000;
  static const int all = characters | words | sentences;
}

/// android.view.KeyEvent key codes used by BooBoard.
abstract final class AndroidKeyCode {
  static const int dpadUp = 19;
  static const int dpadDown = 20;
  static const int dpadLeft = 21;
  static const int dpadRight = 22;
  static const int a = 29;
  static const int c = 31;
  static const int v = 50;
  static const int x = 52;
  static const int y = 53;
  static const int z = 54;
  static const int tab = 61;
  static const int space = 62;
  static const int enter = 66;
  static const int del = 67;
  static const int pageUp = 92;
  static const int pageDown = 93;
  static const int escape = 111;
  static const int forwardDel = 112;
  static const int moveHome = 122;
  static const int moveEnd = 123;
}

/// android.view.KeyEvent meta-state flags.
abstract final class AndroidMetaState {
  static const int shiftOn = 0x1;
  static const int altOn = 0x2;
  static const int shiftLeftOn = 0x40;
  static const int ctrlOn = 0x1000;
  static const int ctrlLeftOn = 0x2000;
}

enum FieldKind { none, text, number, phone, datetime }

enum TextVariation {
  normal,
  uri,
  email,
  emailSubject,
  shortMessage,
  longMessage,
  personName,
  postalAddress,
  password,
  visiblePassword,
  webEditText,
  filter,
  phonetic,
  webEmail,
  webPassword,
  numberPassword,
  date,
  time,
  other,
}

enum ImeAction { unspecified, none, go, search, send, next, done, previous }

/// Which keyboard page suits the field when it gains focus.
enum PreferredPage { letters, email, url, number, phone, datetime }

/// Decoded facts about the focused text field.
@immutable
class InputFieldInfo {
  const InputFieldInfo({
    required this.inputType,
    required this.imeOptions,
    this.actionId = 0,
    this.actionLabel,
    this.packageName,
    this.hintText,
    this.fieldId = 0,
    this.initialSelStart = -1,
    this.initialSelEnd = -1,
    this.initialCapsMode = 0,
    this.contentMimeTypes = const [],
  });

  factory InputFieldInfo.fromMessage(EditorInfoMessage m) => InputFieldInfo(
    inputType: m.inputType,
    imeOptions: m.imeOptions,
    actionId: m.actionId,
    actionLabel: m.actionLabel,
    packageName: m.packageName,
    hintText: m.hintText,
    fieldId: m.fieldId,
    initialSelStart: m.initialSelStart,
    initialSelEnd: m.initialSelEnd,
    initialCapsMode: m.initialCapsMode,
    contentMimeTypes: m.contentMimeTypes ?? const [],
  );

  /// Plain multi-purpose text field (used before any field is focused).
  static const InputFieldInfo plainText = InputFieldInfo(
    inputType: AndroidInputType.classText | AndroidInputType.textFlagCapSentences,
    imeOptions: AndroidImeOptions.actionUnspecified,
  );

  final int inputType;
  final int imeOptions;
  final int actionId;
  final String? actionLabel;

  /// Package of the app that owns the field (used for per-app incognito rules).
  final String? packageName;
  final String? hintText;
  final int fieldId;
  final int initialSelStart;
  final int initialSelEnd;
  final int initialCapsMode;
  final List<String> contentMimeTypes;

  int get _class => inputType & AndroidInputType.maskClass;
  int get _variation => inputType & AndroidInputType.maskVariation;
  bool _flag(int f) => inputType & f != 0;
  bool _ime(int f) => imeOptions & f != 0;

  FieldKind get kind => switch (_class) {
    AndroidInputType.classText => FieldKind.text,
    AndroidInputType.classNumber => FieldKind.number,
    AndroidInputType.classPhone => FieldKind.phone,
    AndroidInputType.classDatetime => FieldKind.datetime,
    _ => FieldKind.none,
  };

  TextVariation get variation {
    switch (kind) {
      case FieldKind.text:
        return switch (_variation) {
          AndroidInputType.textVariationNormal => TextVariation.normal,
          AndroidInputType.textVariationUri => TextVariation.uri,
          AndroidInputType.textVariationEmailAddress => TextVariation.email,
          AndroidInputType.textVariationEmailSubject => TextVariation.emailSubject,
          AndroidInputType.textVariationShortMessage => TextVariation.shortMessage,
          AndroidInputType.textVariationLongMessage => TextVariation.longMessage,
          AndroidInputType.textVariationPersonName => TextVariation.personName,
          AndroidInputType.textVariationPostalAddress => TextVariation.postalAddress,
          AndroidInputType.textVariationPassword => TextVariation.password,
          AndroidInputType.textVariationVisiblePassword => TextVariation.visiblePassword,
          AndroidInputType.textVariationWebEditText => TextVariation.webEditText,
          AndroidInputType.textVariationFilter => TextVariation.filter,
          AndroidInputType.textVariationPhonetic => TextVariation.phonetic,
          AndroidInputType.textVariationWebEmailAddress => TextVariation.webEmail,
          AndroidInputType.textVariationWebPassword => TextVariation.webPassword,
          _ => TextVariation.other,
        };
      case FieldKind.number:
        return _variation == AndroidInputType.numberVariationPassword
            ? TextVariation.numberPassword
            : TextVariation.normal;
      case FieldKind.datetime:
        return switch (_variation) {
          AndroidInputType.datetimeVariationDate => TextVariation.date,
          AndroidInputType.datetimeVariationTime => TextVariation.time,
          _ => TextVariation.normal,
        };
      case FieldKind.phone:
      case FieldKind.none:
        return TextVariation.normal;
    }
  }

  bool get isPassword => switch (variation) {
    TextVariation.password ||
    TextVariation.visiblePassword ||
    TextVariation.webPassword ||
    TextVariation.numberPassword => true,
    _ => false,
  };

  bool get isMultiLine =>
      kind == FieldKind.text && _flag(AndroidInputType.textFlagMultiLine | AndroidInputType.textFlagImeMultiLine);
  bool get noSuggestionsFlag => kind == FieldKind.text && _flag(AndroidInputType.textFlagNoSuggestions);
  bool get hasAutoCorrectFlag => kind == FieldKind.text && _flag(AndroidInputType.textFlagAutoCorrect);
  bool get capCharacters => kind == FieldKind.text && _flag(AndroidInputType.textFlagCapCharacters);
  bool get capWords => kind == FieldKind.text && _flag(AndroidInputType.textFlagCapWords);
  bool get capSentences => kind == FieldKind.text && _flag(AndroidInputType.textFlagCapSentences);
  bool get noPersonalizedLearning => _ime(AndroidImeOptions.flagNoPersonalizedLearning);
  bool get noEnterAction => _ime(AndroidImeOptions.flagNoEnterAction);
  bool get forceAscii => _ime(AndroidImeOptions.flagForceAscii);

  ImeAction get action => switch (imeOptions & AndroidImeOptions.maskAction) {
    AndroidImeOptions.actionNone => ImeAction.none,
    AndroidImeOptions.actionGo => ImeAction.go,
    AndroidImeOptions.actionSearch => ImeAction.search,
    AndroidImeOptions.actionSend => ImeAction.send,
    AndroidImeOptions.actionNext => ImeAction.next,
    AndroidImeOptions.actionDone => ImeAction.done,
    AndroidImeOptions.actionPrevious => ImeAction.previous,
    _ => ImeAction.unspecified,
  };

  /// The raw action id to pass to performEditorAction (custom id wins).
  int get editorActionId => actionId != 0 ? actionId : imeOptions & AndroidImeOptions.maskAction;

  /// Enter inserts a newline (multi-line field, or the app asked for no enter action).
  bool get enterInsertsNewline =>
      noEnterAction || (isMultiLine && (action == ImeAction.unspecified || action == ImeAction.none));

  /// TYPE_NULL fields (terminals, some games) do not support composing text:
  /// send raw key events instead.
  bool get isRawKeyMode => kind == FieldKind.none;

  /// Sensitive = a password, or a field that asks for no suggestions: no popups, no suggestions, no learning,
  /// no voice, no translation, FLAG_SECURE. Swipe typing and the emoji panel still work in a no-suggestions field
  /// (`allowsSwipe`, `KeyboardPanel.allowedInNoSuggestionFields`). A field that only asks for no personalised
  /// learning (private browsing) is not sensitive: it keeps every feature, and only learning is off
  /// (`allowsLearning`, `InputController.learningAllowed`, and `shouldSecureWindow` still blocks screenshots).
  bool get isSensitive => isPassword || noSuggestionsFlag;

  /// Swipe typing works everywhere except password fields (decision 2026-11-25: no-suggestions fields keep swipe).
  bool get allowsSwipe => !isPassword;

  bool get allowsSuggestions => kind == FieldKind.text && !isPassword && !noSuggestionsFlag;

  bool get allowsAutoCorrect =>
      allowsSuggestions &&
      switch (variation) {
        TextVariation.uri ||
        TextVariation.email ||
        TextVariation.webEmail ||
        TextVariation.filter ||
        TextVariation.visiblePassword => false,
        _ => true,
      };

  /// The app permits learning (incognito settings are applied on top of this).
  bool get allowsLearning => !isPassword && !noPersonalizedLearning && !noSuggestionsFlag;

  bool get acceptsImages => contentMimeTypes.any((m) => m.startsWith('image/'));

  PreferredPage get preferredPage => switch (kind) {
    FieldKind.number => PreferredPage.number,
    FieldKind.phone => PreferredPage.phone,
    FieldKind.datetime => PreferredPage.datetime,
    FieldKind.text => switch (variation) {
      TextVariation.email || TextVariation.webEmail => PreferredPage.email,
      TextVariation.uri => PreferredPage.url,
      _ => PreferredPage.letters,
    },
    FieldKind.none => PreferredPage.letters,
  };

  @override
  bool operator ==(Object other) =>
      other is InputFieldInfo &&
      other.inputType == inputType &&
      other.imeOptions == imeOptions &&
      other.actionId == actionId &&
      other.packageName == packageName &&
      other.fieldId == fieldId;

  @override
  int get hashCode => Object.hash(inputType, imeOptions, actionId, packageName, fieldId);
}
