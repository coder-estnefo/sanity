import 'package:shared_preferences/shared_preferences.dart';

/// Tiny abstraction over local storage so data sources are easy to test.
abstract class KeyValueStore {
  String? read(String key);
  Future<void> write(String key, String value);
}

class PrefsKeyValueStore implements KeyValueStore {
  PrefsKeyValueStore(this._prefs);
  final SharedPreferences _prefs;

  @override
  String? read(String key) => _prefs.getString(key);

  @override
  Future<void> write(String key, String value) =>
      _prefs.setString(key, value);
}

class MemoryKeyValueStore implements KeyValueStore {
  final Map<String, String> data = {};

  @override
  String? read(String key) => data[key];

  @override
  Future<void> write(String key, String value) async => data[key] = value;
}

