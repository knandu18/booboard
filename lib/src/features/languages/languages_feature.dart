// SPDX-License-Identifier: GPL-3.0-or-later
//
// OWNER: Wave 3-A. Language picker panel (space-bar long press: hooks.onLanguagePicker), per-language extras.
// keyboard_main.dart calls createLanguagesFeature(); keep that signature.
import 'dart:async';

import '../../keyboard/keyboard_session.dart';
import '../../keyboard/panels/keyboard_panel.dart';
import 'language_picker_panel.dart';

KeyboardFeature createLanguagesFeature() => _LanguagesFeature();

class _LanguagesFeature extends KeyboardFeature {
  @override
  KeyboardHooks attach(KeyboardSession session) => KeyboardHooks(onLanguagePicker: () => _onSpaceLongPress(session));
}

/// With two or more enabled languages the picker opens. With one there is nothing to pick from, so
/// the system keyboard picker opens instead (what a null hook would do).
void _onSpaceLongPress(KeyboardSession session) {
  if (!session.canSwitchLanguage) {
    unawaited(session.services.host.showInputMethodPicker());
    return;
  }
  session.openPanel(LanguagePickerPanel(session: session));
}
