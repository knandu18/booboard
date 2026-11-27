// SPDX-License-Identifier: GPL-3.0-or-later
//
// Polite TalkBack announcements for keyboard events: page changes ("Symbols"), the language switch
// ("Deutsch"), caps lock, a swipe-typed word and panels opening or closing. The announcer only
// receives events and names. It has no access to typed text, candidates or the editor, so nothing
// the user types can reach TalkBack through it (privacy).
import 'dart:ui' show FlutterView, TextDirection;

import 'package:flutter/foundation.dart';
import 'package:flutter/semantics.dart';

import '../input/input_controller.dart';
import '../input/keyboard_page.dart';

/// Sends one polite announcement. Tests pass a fake; [KeyboardAnnouncer.forView] uses TalkBack.
typedef Announce = Future<void> Function(String message);

class KeyboardAnnouncer {
  KeyboardAnnouncer(this._send);

  /// Announcements through the view the keyboard is drawn in (the IME window).
  factory KeyboardAnnouncer.forView(FlutterView Function() view, {TextDirection direction = TextDirection.ltr}) =>
      KeyboardAnnouncer((message) => SemanticsService.sendAnnouncement(view(), message, direction));

  final Announce _send;
  final List<VoidCallback> _unbind = [];

  /// What the last notifier values were, so only real changes are announced.
  KeyboardPage? _page;
  ShiftState? _shift;
  String? _language;

  /// What TalkBack says for a page. Field pages (numbers, phone, date) are not announced: they
  /// come with the field, not with the user's choice.
  static String pageName(KeyboardPage page) => switch (page) {
    KeyboardPage.letters => 'Letters',
    KeyboardPage.symbols => 'Symbols',
    KeyboardPage.symbols2 => 'More symbols',
    KeyboardPage.numpad => 'Numbers',
    KeyboardPage.phone => 'Phone',
    KeyboardPage.datetime => 'Date and time',
  };

  /// Follows [page], [shift] and, when given, the language name. The current values are the
  /// baseline: binding announces nothing. Call [dispose] to stop listening.
  void bind({
    required ValueListenable<KeyboardPage> page,
    required ValueListenable<ShiftState> shift,
    ValueListenable<String?>? language,
  }) {
    _page = page.value;
    _shift = shift.value;
    _language = language?.value;
    void onPage() {
      final next = page.value;
      if (next == _page) return;
      _page = next;
      if (!next.isFieldPage) _say(pageName(next));
    }

    void onShift() {
      final next = shift.value;
      final was = _shift;
      _shift = next;
      if (was == next) return;
      if (next == ShiftState.caps) _say('Caps lock on');
      if (was == ShiftState.caps) _say('Caps lock off');
    }

    void onLanguage() {
      final next = language?.value;
      if (next == _language) return;
      _language = next;
      if (next != null && next.isNotEmpty) _say(next);
    }

    page.addListener(onPage);
    shift.addListener(onShift);
    _unbind.add(() => page.removeListener(onPage));
    _unbind.add(() => shift.removeListener(onShift));
    if (language != null) {
      language.addListener(onLanguage);
      _unbind.add(() => language.removeListener(onLanguage));
    }
  }

  /// The word was typed by swiping. The word itself is never announced.
  void swipeTyped() => _say('Swipe typed');

  /// A panel (emoji, clipboard, voice...) opened or closed; [name] is its title.
  void panelOpened(String name) => _say('$name open');
  void panelClosed(String name) => _say('$name closed');

  void dispose() {
    for (final undo in _unbind) {
      undo();
    }
    _unbind.clear();
  }

  void _say(String message) {
    // An announcement is best effort: a failed send must never break typing.
    _send(message).catchError((Object _) {});
  }
}
