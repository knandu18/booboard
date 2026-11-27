// SPDX-License-Identifier: GPL-3.0-or-later
//
// Tolerant JSON readers: settings files written by older or newer versions
// must never crash the keyboard; unknown/invalid values fall back to defaults.
typedef Json = Map<String, Object?>;

bool jBool(Json j, String key, bool fallback) => j[key] is bool ? j[key]! as bool : fallback;

int jInt(Json j, String key, int fallback) => j[key] is num ? (j[key]! as num).toInt() : fallback;

double jDouble(Json j, String key, double fallback) => j[key] is num ? (j[key]! as num).toDouble() : fallback;

String jString(Json j, String key, String fallback) => j[key] is String ? j[key]! as String : fallback;

String? jStringOrNull(Json j, String key) => j[key] is String ? j[key]! as String : null;

List<String> jStrings(Json j, String key, List<String> fallback) =>
    j[key] is List ? (j[key]! as List).whereType<String>().toList() : fallback;

Map<String, String> jStringMap(Json j, String key, Map<String, String> fallback) => j[key] is Map
    ? {
        for (final e in (j[key]! as Map).entries)
          if (e.key is String && e.value is String) e.key as String: e.value as String,
      }
    : fallback;

T jEnum<T extends Enum>(Json j, String key, List<T> values, T fallback) {
  final name = j[key];
  for (final v in values) {
    if (v.name == name) return v;
  }
  return fallback;
}

Json jObject(Json j, String key) => j[key] is Map ? (j[key]! as Map).cast<String, Object?>() : const {};
