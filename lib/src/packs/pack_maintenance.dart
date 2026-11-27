// SPDX-License-Identifier: GPL-3.0-or-later
//
// OWNER: Wave 5-C. What the Model packs screen needs beyond list, import and delete: checking installed
// packs, free storage, and (play flavour only) packs the store delivers. Dart stays flavour-agnostic: the
// screen asks [PackMaintenance] and shows what it gets back.
//
// [UnavailablePackMaintenance] is the fallback when the bridge cannot be reached, and the screen
// says those features are not in this build. Nothing here touches the network.
//
// [BridgePackMaintenance] is the real implementation over the settings-app Pigeon calls. The screen uses it
// unless a test passes its own [PackMaintenance].

import '../bridge/messages.g.dart';

/// The website where packs are published (the project's GitHub releases). The app has no INTERNET permission
/// and never downloads anything: it shows this link to copy, and "Download" hands a single pack's release
/// link to the browser (pack_catalog.dart, AppHostApi.openPackDownload).
const String kPackReleasePageUrl = 'https://github.com/knandu18/booboard/releases';

/// How packs reach this build: files the user imports, or packs the store delivers too (play flavour).
enum PackDelivery { importOnly, storeDelivery }

/// Where a store-delivered pack is in its download. Play reports these; the keyboard only shows them.
enum PackOfferStatus { notRequested, waitingForNetwork, downloading, installing, failed, ready }

/// A pack the store can deliver to this phone (only in builds with [PackDelivery.storeDelivery]).
class PackOffer {
  const PackOffer({required this.id, required this.name, required this.sizeBytes, required this.status});

  final String id;
  final String name;
  final int sizeBytes;
  final PackOfferStatus status;
}

/// Free space on the storage that holds packs.
class PackStorage {
  const PackStorage({required this.freeBytes});

  final int freeBytes;
}

/// Result of re-checking one installed pack against its signed manifest. Counts only, never paths.
class PackCheck {
  const PackCheck({required this.id, required this.manifestOk, required this.missingFiles, required this.damagedFiles});

  final String id;
  final bool manifestOk;
  final int missingFiles;
  final int damagedFiles;

  bool get ok => manifestOk && missingFiles == 0 && damagedFiles == 0;
}

/// Thrown when this build cannot do a maintenance action (the bridge call is not wired yet).
class PackMaintenanceUnavailable implements Exception {
  const PackMaintenanceUnavailable();

  @override
  String toString() => 'PackMaintenanceUnavailable';
}

abstract interface class PackMaintenance {
  /// Import-only builds (foss) return [PackDelivery.importOnly]; the play flavour may return
  /// [PackDelivery.storeDelivery].
  PackDelivery get delivery;

  /// Packs the store can deliver, with their state. Empty when [delivery] is importOnly.
  Future<List<PackOffer>> offers();

  /// Asks the store to deliver pack [id]. Only valid with [PackDelivery.storeDelivery].
  Future<void> request(String id);

  /// Free storage for packs, or null when this build cannot tell.
  Future<PackStorage?> storage();

  /// Re-checks every installed pack. Throws [PackMaintenanceUnavailable] when this build cannot.
  Future<List<PackCheck>> verifyInstalled();

  /// Verifies and installs the pack the store has delivered for [id], and returns its display name. Throws
  /// a PlatformException with code `not_delivered` when the store has not delivered it yet, or with the import codes.
  Future<String> installDelivered(String id);
}

/// The default until the bridge supports maintenance: import-only, nothing to check, storage unknown.
class UnavailablePackMaintenance implements PackMaintenance {
  const UnavailablePackMaintenance();

  @override
  PackDelivery get delivery => PackDelivery.importOnly;

  @override
  Future<List<PackOffer>> offers() async => const [];

  @override
  Future<void> request(String id) async => throw const PackMaintenanceUnavailable();

  @override
  Future<PackStorage?> storage() async => null;

  @override
  Future<List<PackCheck>> verifyInstalled() async => throw const PackMaintenanceUnavailable();

  @override
  Future<String> installDelivered(String id) async => throw const PackMaintenanceUnavailable();
}

/// The real thing: maintenance through the settings-app Pigeon calls. Create it with [load], which reads
/// how this build delivers packs (the answer never changes while the app runs).
class BridgePackMaintenance implements PackMaintenance {
  BridgePackMaintenance._(this._api, this.delivery);

  final AppHostApi _api;

  @override
  final PackDelivery delivery;

  /// Asks the platform how packs reach this build. Throws when the bridge is not available.
  static Future<BridgePackMaintenance> load(AppHostApi api) async {
    final kind = await api.packDelivery();
    return BridgePackMaintenance._(api, kind == 'store' ? PackDelivery.storeDelivery : PackDelivery.importOnly);
  }

  @override
  Future<List<PackOffer>> offers() async {
    if (delivery == PackDelivery.importOnly) return const [];
    final offers = await _api.packOffers();
    return [
      for (final o in offers) PackOffer(id: o.id, name: o.name, sizeBytes: o.sizeBytes, status: _status(o.status)),
    ];
  }

  @override
  Future<void> request(String id) => _api.requestPack(id);

  @override
  Future<PackStorage?> storage() async {
    final s = await _api.packStorage();
    return s == null ? null : PackStorage(freeBytes: s.freeBytes);
  }

  @override
  Future<List<PackCheck>> verifyInstalled() async {
    final checks = await _api.verifyPacks();
    return [
      for (final c in checks)
        PackCheck(id: c.id, manifestOk: c.manifestOk, missingFiles: c.missingFiles, damagedFiles: c.damagedFiles),
    ];
  }

  @override
  Future<String> installDelivered(String id) async => (await _api.installDeliveredPack(id)).name;

  static PackOfferStatus _status(PackOfferStatusMessage m) => switch (m) {
    PackOfferStatusMessage.notRequested => PackOfferStatus.notRequested,
    PackOfferStatusMessage.waitingForNetwork => PackOfferStatus.waitingForNetwork,
    PackOfferStatusMessage.downloading => PackOfferStatus.downloading,
    PackOfferStatusMessage.installing => PackOfferStatus.installing,
    PackOfferStatusMessage.failed => PackOfferStatus.failed,
    PackOfferStatusMessage.ready => PackOfferStatus.ready,
  };
}
