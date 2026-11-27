// SPDX-License-Identifier: GPL-3.0-or-later
//
// App lock: the device's strong biometric or its PIN, pattern or password (local_auth 3.x,
// BiometricPrompt on Android). Also the lock timeout rule and the FLAG_SECURE guard for sensitive
// screens. Tests use [AppAuthenticator] fakes.
import 'dart:async';

import 'package:local_auth/local_auth.dart';
import 'package:meta/meta.dart';

import '../bridge/messages.g.dart';
import '../core/log.dart';

enum AuthOutcome {
  /// The user passed the check.
  success,

  /// The user dismissed the prompt or tried again. Nothing is wrong.
  cancelled,

  /// No lock screen, no enrolled biometrics, or the sensor is locked out.
  unavailable,
}

abstract interface class AppAuthenticator {
  /// True when the device has a lock screen (PIN, pattern or password) or enrolled biometrics.
  Future<bool> isDeviceSecure();

  /// Shows the system prompt. Biometric or device credential, so a PIN also works.
  Future<AuthOutcome> authenticate(String reason);
}

class LocalAuthAuthenticator implements AppAuthenticator {
  LocalAuthAuthenticator([LocalAuthentication? auth]) : _auth = auth ?? LocalAuthentication();

  final LocalAuthentication _auth;

  @override
  Future<bool> isDeviceSecure() async {
    try {
      return await _auth.isDeviceSupported();
    } on Object catch (e) {
      BooBoardLog.w('AppLock', 'device support check failed', e.runtimeType);
      return false;
    }
  }

  @override
  Future<AuthOutcome> authenticate(String reason) async {
    try {
      // biometricOnly false: the device PIN, pattern or password is an accepted fallback.
      // persistAcrossBackgrounding keeps the prompt alive if the system backgrounds the app.
      final ok = await _auth.authenticate(
        localizedReason: reason,
        biometricOnly: false,
        persistAcrossBackgrounding: true,
      );
      return ok ? AuthOutcome.success : AuthOutcome.cancelled;
    } on LocalAuthException catch (e) {
      BooBoardLog.w('AppLock', 'authentication ended', e.code.name);
      return switch (e.code) {
        LocalAuthExceptionCode.userCanceled ||
        LocalAuthExceptionCode.systemCanceled ||
        LocalAuthExceptionCode.timeout => AuthOutcome.cancelled,
        _ => AuthOutcome.unavailable,
      };
    } on Object catch (e) {
      BooBoardLog.w('AppLock', 'authentication failed', e.runtimeType);
      return AuthOutcome.unavailable;
    }
  }
}

/// When the settings app must ask again after it went to the background.
abstract final class AppLockPolicy {
  /// The timeouts offered in the privacy center, in seconds. 0 means immediately.
  static const List<int> timeoutChoices = [0, 30, 60, 300];

  static bool shouldLock({
    required bool enabled,
    required int timeoutSeconds,
    required DateTime? backgroundedAt,
    required DateTime now,
  }) {
    if (!enabled || backgroundedAt == null) return false;
    return now.difference(backgroundedAt) >= Duration(seconds: timeoutSeconds);
  }

  static String timeoutLabel(int seconds) => switch (seconds) {
    0 => 'Immediately',
    30 => 'After 30 seconds',
    60 => 'After 1 minute',
    300 => 'After 5 minutes',
    _ => 'After $seconds seconds',
  };
}

/// Counts the screens that must not be captured (learned words, backup, the lock screen). The
/// window is FLAG_SECURE while any holder is active, so a leaving screen cannot unlock the others.
class SecureScreenGuard {
  SecureScreenGuard(this._api);

  static SecureScreenGuard? _override;

  /// The shared guard, backed by the settings app's host API.
  static SecureScreenGuard get instance => _override ??= SecureScreenGuard(AppHostApi());

  /// Tests replace the shared guard. Null restores the default.
  @visibleForTesting
  static set instance(SecureScreenGuard? guard) => _override = guard;

  final AppHostApi _api;
  int _holders = 0;

  bool get isSecure => _holders > 0;

  void acquire() {
    _holders++;
    _apply();
  }

  void release() {
    if (_holders > 0) _holders--;
    _apply();
  }

  void _apply() {
    try {
      unawaited(
        _api
            .setSecureScreen(_holders > 0)
            .catchError((Object e) => BooBoardLog.w('Secure', 'set failed', e.runtimeType)),
      );
    } on Object catch (e) {
      BooBoardLog.w('Secure', 'set failed', e.runtimeType);
    }
  }
}
