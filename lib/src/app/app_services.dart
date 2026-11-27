// SPDX-License-Identifier: GPL-3.0-or-later
//
// CONTRACT (orchestrator-owned): everything the settings app's screens need,
// created once in main() and provided to the widget tree by [AppScope].
//
//   final services = AppScope.of(context);
//   await services.settings.update((s) => s.copyWith(...), sections: ['typing']);
//
// The keyboard engine is told about every settings change automatically
// (SettingsStore's notifyOther). After changing encrypted data, call
// [AppServices.notifyDataChanged] with a DataSections id.
import 'dart:async';

import 'package:flutter/widgets.dart';

import '../bridge/messages.g.dart';
import '../core/data_sections.dart';
import '../core/log.dart';
import '../core/secure_blob_store.dart';
import '../core/seen_apps.dart';
import '../settings/settings_store.dart';

class AppServices {
  AppServices({
    required this.settings,
    required this.secureStore,
    required this.platform,
    required this.app,
    SeenAppsStore? seenApps,
  }) : seenApps = seenApps ?? SeenAppsStore(secureStore);

  final SettingsStore settings;
  final SecureBlobStore secureStore;
  final PlatformHostApi platform;
  final AppHostApi app;

  /// Apps the keyboard was used in (incognito picker).
  final SeenAppsStore seenApps;

  final StreamController<String> _routes = StreamController.broadcast();
  final StreamController<List<String>> _dataChanges = StreamController.broadcast();

  /// Routes requested while the app is running (keyboard toolbar). The launch route is read once
  /// with `app.takeLaunchRoute()`.
  Stream<String> get routeRequests => _routes.stream;

  /// DataSections changed by the keyboard engine (for example new clipboard items or learned
  /// words); screens showing that data should reload it.
  Stream<List<String>> get dataChanges => _dataChanges.stream;

  static Future<AppServices> create() async {
    final platform = PlatformHostApi();
    final dir = await platform.getDataDirectory();
    final settings = await SettingsStore.open(directory: dir, notifyOther: platform.notifySettingsChanged);
    final services = AppServices(
      settings: settings,
      secureStore: PlatformSecureBlobStore(platform),
      platform: platform,
      app: AppHostApi(),
    );
    AppFlutterApi.setUp(_AppEvents(services));
    return services;
  }

  /// Lives as long as the app; tests call this.
  Future<void> dispose() async {
    await _routes.close();
    await _dataChanges.close();
  }

  /// Tell the keyboard engine that encrypted data changed ([DataSections] ids).
  Future<void> notifyDataChanged(List<String> sections) async {
    try {
      await platform.notifySettingsChanged(sections);
    } on Object catch (e) {
      BooBoardLog.w('App', 'data change notify failed', e.runtimeType);
    }
  }

  void _onSettingsChanged(List<String> sections) {
    final data = sections.where((s) => s.startsWith('data.')).toList();
    if (data.length != sections.length) unawaited(settings.reload());
    if (data.isNotEmpty) {
      if (DataSections.affects(data, DataSections.seenApps)) seenApps.invalidate();
      _dataChanges.add(data);
    }
  }
}

class _AppEvents implements AppFlutterApi {
  _AppEvents(this._services);

  final AppServices _services;

  @override
  Future<void> onSettingsChanged(List<String> sections) async => _services._onSettingsChanged(sections);

  @override
  Future<void> onOpenRoute(String route) async => _services._routes.add(route);
}

/// Provides [AppServices] to the settings app.
class AppScope extends InheritedWidget {
  const AppScope({super.key, required this.services, required super.child});

  final AppServices services;

  static AppServices of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AppScope>();
    assert(scope != null, 'AppScope missing above this context');
    return scope!.services;
  }

  @override
  bool updateShouldNotify(AppScope oldWidget) => !identical(services, oldWidget.services);
}
