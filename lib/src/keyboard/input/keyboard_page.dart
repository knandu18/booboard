// SPDX-License-Identifier: GPL-3.0-or-later
import '../../core/input_field_info.dart';

/// Which layout page the keyboard shows.
enum KeyboardPage {
  letters,
  symbols,
  symbols2,
  numpad,
  phone,
  datetime;

  /// Pages that belong to symbols typing on top of the letters page.
  bool get isSymbols => this == symbols || this == symbols2;

  /// Pages chosen because of the field type (not switchable by the user).
  bool get isFieldPage => this == numpad || this == phone || this == datetime;

  static KeyboardPage forField(PreferredPage page) => switch (page) {
    PreferredPage.letters || PreferredPage.email || PreferredPage.url => KeyboardPage.letters,
    PreferredPage.number => KeyboardPage.numpad,
    PreferredPage.phone => KeyboardPage.phone,
    PreferredPage.datetime => KeyboardPage.datetime,
  };
}
