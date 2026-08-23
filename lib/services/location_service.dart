import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/delivery_location.dart';

/// Selected delivery location + saved addresses.
///
/// Sab kuch device par `SharedPreferences` mein rehta hai — na GPS permission
/// chahiye, na koi external geocoding service. Isliye web, Windows aur Android
/// teeno par bilkul same chalta hai.
class LocationService extends ChangeNotifier {
  LocationService._(this._prefs)
      : _current = _readCurrent(_prefs),
        _saved = _readSaved(_prefs);

  static const _kCurrent = 'delivery_location_current';
  static const _kSaved = 'delivery_location_saved';

  final SharedPreferences _prefs;

  DeliveryLocation? _current;
  List<DeliveryLocation> _saved;

  static Future<LocationService> load() async {
    final prefs = await SharedPreferences.getInstance();
    return LocationService._(prefs);
  }

  /// Abhi chuni hui location. `null` matlab user ne abhi tak nahi chuni.
  DeliveryLocation? get current => _current;

  List<DeliveryLocation> get saved => List.unmodifiable(_saved);

  bool get hasLocation => _current != null;

  /// Location select karta hai aur (agar nayi ho to) saved list mein daal deta hai.
  Future<void> select(DeliveryLocation location) async {
    _current = location;
    if (!_saved.any((l) => l.sameAs(location))) {
      _saved = [location, ..._saved];
      // Bahut lambi list na ho jaaye.
      if (_saved.length > 8) _saved = _saved.sublist(0, 8);
      await _prefs.setString(
        _kSaved,
        jsonEncode(_saved.map((l) => l.toJson()).toList()),
      );
    }
    await _prefs.setString(_kCurrent, jsonEncode(location.toJson()));
    notifyListeners();
  }

  Future<void> remove(DeliveryLocation location) async {
    _saved = _saved.where((l) => !l.sameAs(location)).toList();
    await _prefs.setString(
      _kSaved,
      jsonEncode(_saved.map((l) => l.toJson()).toList()),
    );
    if (_current != null && _current!.sameAs(location)) {
      _current = null;
      await _prefs.remove(_kCurrent);
    }
    notifyListeners();
  }

  /// Sirf saved locations mein search — states/districts/pincodes ki asli list
  /// Supabase se aati hai (dekhein `SupabaseService.fetchStates()` waghairah).
  List<DeliveryLocation> searchSaved(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return const [];
    return _saved.where((l) => l.searchable.contains(q)).toList();
  }

  static DeliveryLocation? _readCurrent(SharedPreferences prefs) {
    final raw = prefs.getString(_kCurrent);
    if (raw == null || raw.isEmpty) return null;
    try {
      return DeliveryLocation.fromJson(
          jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      // Purana ya corrupt data — chup-chaap ignore, user dobara chun lega.
      return null;
    }
  }

  static List<DeliveryLocation> _readSaved(SharedPreferences prefs) {
    final raw = prefs.getString(_kSaved);
    if (raw == null || raw.isEmpty) return [];
    try {
      final list = jsonDecode(raw) as List;
      return list
          .map((e) => DeliveryLocation.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }
}

extension LocationContext on BuildContext {
  LocationService get location => watch<LocationService>();
}
