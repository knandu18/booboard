// SPDX-License-Identifier: GPL-3.0-or-later
//
// OWNER: Wave 2-B. Wraps the settings app. When app lock is on, the app asks for the device's
// biometric or PIN on start and again after it has been in the background longer than the
// timeout. The locked screen shows no content and keeps the window FLAG_SECURE.
//
// Put it inside MaterialApp (the locked screen uses Scaffold).
import 'dart:async';

import 'package:material_ui/material_ui.dart';

import '../../security/app_auth.dart';
import '../app_services.dart';
import 'privacy_widgets.dart';

import 'package:booboard/src/app/l10n.dart';

class AppLockGate extends StatefulWidget {
  const AppLockGate({super.key, required this.child, this.authenticator, this.clock});

  final Widget child;

  /// Defaults to the device's biometric or PIN. Tests pass a fake.
  final AppAuthenticator? authenticator;

  /// Defaults to DateTime.now. Tests pass a fake clock.
  final DateTime Function()? clock;

  @override
  State<AppLockGate> createState() => _AppLockGateState();
}

class _AppLockGateState extends State<AppLockGate> {
  AppServices? _services;
  late final AppAuthenticator _auth = widget.authenticator ?? LocalAuthAuthenticator();
  late final AppLifecycleListener _lifecycle;
  DateTime? _backgroundedAt;
  bool _locked = false;
  bool _prompting = false;
  String? _message;

  DateTime _now() => (widget.clock ?? DateTime.now)();

  @override
  void initState() {
    super.initState();
    _lifecycle = AppLifecycleListener(onHide: _onHide, onShow: _onShow);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_services != null) return;
    final services = _services = AppScope.of(context);
    services.settings.addListener(_onSettingsChanged);
    if (services.settings.value.privacy.appLock) _lock(prompt: true);
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    _services?.settings.removeListener(_onSettingsChanged);
    if (_locked) SecureScreenGuard.instance.release();
    super.dispose();
  }

  void _onSettingsChanged() {
    final enabled = _services?.settings.value.privacy.appLock ?? false;
    if (!enabled && _locked) _unlockState();
  }

  void _onHide() {
    if (_prompting) return;
    _backgroundedAt = _now();
  }

  void _onShow() {
    if (_prompting || _locked) return;
    final privacy = _services?.settings.value.privacy;
    if (privacy == null) return;
    final due = AppLockPolicy.shouldLock(
      enabled: privacy.appLock,
      timeoutSeconds: privacy.appLockTimeoutSeconds,
      backgroundedAt: _backgroundedAt,
      now: _now(),
    );
    _backgroundedAt = null;
    if (due) _lock(prompt: true);
  }

  void _lock({required bool prompt}) {
    if (!_locked) {
      _locked = true;
      SecureScreenGuard.instance.acquire();
      if (mounted) setState(() => _message = null);
    }
    if (prompt) unawaited(_unlock());
  }

  void _unlockState() {
    if (_locked) {
      _locked = false;
      SecureScreenGuard.instance.release();
    }
    if (mounted) setState(() => _message = null);
  }

  Future<void> _unlock() async {
    if (_prompting) return;
    _prompting = true;
    try {
      final outcome = await _auth.authenticate(context.l10n.privacyUnlockReason);
      if (!mounted) return;
      if (outcome == AuthOutcome.success) {
        _unlockState();
      } else {
        setState(() {
          _message = outcome == AuthOutcome.unavailable ? context.l10n.privacyLockUnavailable : null;
        });
      }
    } finally {
      _prompting = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_locked) return widget.child;
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const PrivacyMascotSlot(size: 96),
                const SizedBox(height: 24),
                Text(context.l10n.privacyLockedTitle, style: text.headlineSmall, textAlign: TextAlign.center),
                const SizedBox(height: 8),
                Text(
                  context.l10n.privacyLockedBody,
                  style: text.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
                  textAlign: TextAlign.center,
                ),
                if (_message != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    _message!,
                    style: text.bodySmall?.copyWith(color: scheme.error),
                    textAlign: TextAlign.center,
                  ),
                ],
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: _prompting ? null : () => unawaited(_unlock()),
                  icon: const Icon(Icons.lock_open),
                  label: Text(context.l10n.privacyUnlock),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
