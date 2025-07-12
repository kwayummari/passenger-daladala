import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

abstract class LocalStorage {
  Future<bool> saveString(String key, String value);
  Future<String?> getString(String key);
  Future<bool> saveBool(String key, bool value);
  Future<bool?> getBool(String key);
  Future<bool> saveInt(String key, int value);
  Future<int?> getInt(String key);
  Future<bool> saveDouble(String key, double value);
  Future<double?> getDouble(String key);
  Future<bool> saveStringList(String key, List<String> value);
  Future<List<String>?> getStringList(String key);
  Future<bool> saveObject(String key, Map<String, dynamic> value);
  Future<Map<String, dynamic>?> getObject(String key);
  Future<bool> saveObjectList(String key, List<Map<String, dynamic>> value);
  Future<List<Map<String, dynamic>>?> getObjectList(String key);
  Future<bool> hasKey(String key);
  Future<bool> removeKey(String key);
  Future<bool> clear();
}

class LocalStorageImpl implements LocalStorage {
  final SharedPreferences sharedPreferences;

  LocalStorageImpl({required this.sharedPreferences});

  @override
  Future<bool> saveString(String key, String value) async {
    return await sharedPreferences.setString(key, value);
  }

  @override
  Future<String?> getString(String key) async {
    return sharedPreferences.getString(key);
  }

  @override
  Future<bool> saveBool(String key, bool value) async {
    return await sharedPreferences.setBool(key, value);
  }

  @override
  Future<bool?> getBool(String key) async {
    return sharedPreferences.getBool(key);
  }

  @override
  Future<bool> saveInt(String key, int value) async {
    return await sharedPreferences.setInt(key, value);
  }

  @override
  Future<int?> getInt(String key) async {
    return sharedPreferences.getInt(key);
  }

  @override
  Future<bool> saveDouble(String key, double value) async {
    return await sharedPreferences.setDouble(key, value);
  }

  @override
  Future<double?> getDouble(String key) async {
    return sharedPreferences.getDouble(key);
  }

  @override
  Future<bool> saveStringList(String key, List<String> value) async {
    return await sharedPreferences.setStringList(key, value);
  }

  @override
  Future<List<String>?> getStringList(String key) async {
    return sharedPreferences.getStringList(key);
  }

  @override
  Future<bool> saveObject(String key, Map<String, dynamic> value) async {
    return await sharedPreferences.setString(key, jsonEncode(value));
  }

  @override
  Future<Map<String, dynamic>?> getObject(String key) async {
    final String? jsonString = sharedPreferences.getString(key);
    if (jsonString == null) {
      return null;
    }
    try {
      return jsonDecode(jsonString) as Map<String, dynamic>;
    } catch (e) {
      return null;
    }
  }

  @override
  Future<bool> saveObjectList(String key, List<Map<String, dynamic>> value) async {
    return await sharedPreferences.setString(key, jsonEncode(value));
  }

  @override
  Future<List<Map<String, dynamic>>?> getObjectList(String key) async {
    final String? jsonString = sharedPreferences.getString(key);
    if (jsonString == null) {
      return null;
    }
    try {
      final List<dynamic> decodedList = jsonDecode(jsonString) as List<dynamic>;
      return decodedList.map((item) => item as Map<String, dynamic>).toList();
    } catch (e) {
      return null;
    }
  }

  @override
  Future<bool> hasKey(String key) async {
    return sharedPreferences.containsKey(key);
  }

  @override
  Future<bool> removeKey(String key) async {
    return await sharedPreferences.remove(key);
  }

  @override
  Future<bool> clear() async {
    return await sharedPreferences.clear();
  }
}