import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

abstract class SecureStorage {
  Future<void> saveAuthToken(String token);
  Future<String?> getAuthToken();
  Future<void> deleteAuthToken();
  Future<void> saveUserData(Map<String, dynamic> userData);
  Future<Map<String, dynamic>?> getUserData();
  Future<void> deleteUserData();
  Future<void> deleteAll();
}

class SecureStorageImpl implements SecureStorage {
  final FlutterSecureStorage secureStorage;
  
  // Key constants
  static const String authTokenKey = 'auth_token';
  static const String userDataKey = 'user_data';
  
  const SecureStorageImpl({required this.secureStorage});
  
  @override
  Future<void> saveAuthToken(String token) async {
    await secureStorage.write(key: authTokenKey, value: token);
  }
  
  @override
  Future<String?> getAuthToken() async {
    return await secureStorage.read(key: authTokenKey);
  }
  
  @override
  Future<void> deleteAuthToken() async {
    await secureStorage.delete(key: authTokenKey);
  }
  
  @override
  Future<void> saveUserData(Map<String, dynamic> userData) async {
    await secureStorage.write(
      key: userDataKey,
      value: jsonEncode(userData),
    );
  }
  
  @override
  Future<Map<String, dynamic>?> getUserData() async {
    final String? jsonString = await secureStorage.read(key: userDataKey);
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
  Future<void> deleteUserData() async {
    await secureStorage.delete(key: userDataKey);
  }
  
  @override
  Future<void> deleteAll() async {
    await secureStorage.deleteAll();
  }
}