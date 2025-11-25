import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class StorageService {
  // Configuração de storage que funciona em todas as plataformas (web, Android, iOS)
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
    // iOSOptions vazio para compatibilidade cross-platform
    // Em web, flutter_secure_storage usa localStorage
  );

  // Token storage
  static Future<void> saveToken(String token) async {
    await _storage.write(key: 'auth_token', value: token);
  }

  static Future<String?> getToken() async {
    return await _storage.read(key: 'auth_token');
  }

  static Future<void> deleteToken() async {
    await _storage.delete(key: 'auth_token');
  }

  // Organization ID storage
  static Future<void> saveOrganizationId(String organizationId) async {
    await _storage.write(key: 'organization_id', value: organizationId);
  }

  static Future<String?> getOrganizationId() async {
    return await _storage.read(key: 'organization_id');
  }

  static Future<void> deleteOrganizationId() async {
    return await _storage.delete(key: 'organization_id');
  }

  // User data storage
  static Future<void> saveUserId(String userId) async {
    await _storage.write(key: 'user_id', value: userId);
  }

  static Future<String?> getUserId() async {
    return await _storage.read(key: 'user_id');
  }

  // Role storage
  static Future<void> saveRole(String role) async {
    await _storage.write(key: 'user_role', value: role);
  }

  static Future<String?> getRole() async {
    return await _storage.read(key: 'user_role');
  }

  // Email storage
  static Future<void> saveEmail(String email) async {
    await _storage.write(key: 'user_email', value: email);
  }

  static Future<String?> getEmail() async {
    return await _storage.read(key: 'user_email');
  }

  // Name storage
  static Future<void> saveName(String name) async {
    await _storage.write(key: 'user_name', value: name);
  }

  static Future<String?> getName() async {
    return await _storage.read(key: 'user_name');
  }

  // Organization name storage
  static Future<void> saveOrganizationName(String organizationName) async {
    await _storage.write(key: 'organization_name', value: organizationName);
  }

  static Future<String?> getOrganizationName() async {
    return await _storage.read(key: 'organization_name');
  }

  // Clear all storage
  static Future<void> clearAll() async {
    await _storage.deleteAll();
  }
}

