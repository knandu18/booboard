// SPDX-License-Identifier: GPL-3.0-or-later
//
// OWNER: Wave 1-C (gesture typing).
import '../contracts.dart';
import 'isolate_gesture_decoder.dart';

/// Swipe decoder backed by one long-lived background isolate.
GestureDecoder createGestureDecoder({required LexiconSource lexicons}) => IsolateGestureDecoder(lexicons: lexicons);
