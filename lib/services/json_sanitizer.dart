import 'package:cloud_firestore/cloud_firestore.dart';

/// Sanitize any Firestore-derived map into plain JSON-safe types for
/// Firebase Callable Functions.
/// - Converts Timestamp/DateTime to ISO8601 strings
/// - Converts GeoPoint to a simple map {latitude, longitude}
/// - Converts DocumentReference to its path
/// - Recursively processes lists and maps
/// - Leaves primitives (num, String, bool, null) untouched
dynamic sanitizeForCallable(dynamic value) {
  if (value == null) return null;

  if (value is num || value is String || value is bool) {
    // Force ints to double to avoid protobuf Int64 wrappers in Callable payloads
    if (value is int) return value.toDouble();
    return value;
  }

  if (value is DateTime) return value.toIso8601String();

  if (value is Timestamp) return value.toDate().toIso8601String();

  if (value is GeoPoint) {
    return {'latitude': value.latitude, 'longitude': value.longitude};
  }

  if (value is DocumentReference) return value.path;

  if (value is List) {
    return value.map((e) => sanitizeForCallable(e)).toList();
  }

  if (value is Map) {
    final out = <String, dynamic>{};
    value.forEach((key, v) {
      final skey = key?.toString() ?? '';
      out[skey] = sanitizeForCallable(v);
    });
    return out;
  }

  // Fallback to string for unknown types
  return value.toString();
}
