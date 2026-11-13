
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AuthStorage {
  static const FlutterSecureStorage _secureStorage = FlutterSecureStorage();
  static const String _rememberedAccountKey = 'rememberedAccount';
  static const String _rememberedPasswordKey = 'rememberedPassword';
  static const String _userIdKey = 'userId';
  static const String _roleKey = 'userRole';
  static const String _tokenKey = 'accessToken';
  static const String _nameKey = 'userName';

  // Lưu thông tin sau khi đăng nhập thành công
  static Future<void> saveLogin({
    required String userId,
    required String role,
    required String accessToken,
    String? name,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString(_userIdKey, userId);
    await prefs.setString(_roleKey, role);
    await prefs.setString(_tokenKey, accessToken);
    await prefs.setString(_nameKey, name ?? '');
  }

  // Lấy ID người dùng
  static Future<String?> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userIdKey);
  }

  // Lấy vai trò
  static Future<String?> getRole() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_roleKey);
  }

  // Lấy JWT
  static Future<String?> getAccessToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  // Lấy tên người dùng
  static Future<String?> getUserName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_nameKey);
  }

  // Xóa thông tin khi đăng xuất
  static Future<void> clearLogin() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.remove(_userIdKey);
    await prefs.remove(_roleKey);
    await prefs.remove(_tokenKey);
    await prefs.remove(_nameKey);
  }

  static Future<Map<String, String>?> getRememberedCredentials() async {
    final account = await _secureStorage.read(key: _rememberedAccountKey);
    final password = await _secureStorage.read(key: _rememberedPasswordKey);
    if (account == null || password == null) return null;
    return {'account': account, 'password': password};
  }

  static Future<void> saveRememberedCredentials({
    required String account,
    required String password,
  }) async {
    await _secureStorage.write(key: _rememberedAccountKey, value: account);
    await _secureStorage.write(key: _rememberedPasswordKey, value: password);
  }

  static Future<void> clearRememberedCredentials() async {
    await _secureStorage.delete(key: _rememberedAccountKey);
    await _secureStorage.delete(key: _rememberedPasswordKey);
  }
}
