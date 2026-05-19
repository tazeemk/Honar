import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class TokenStorage {
  static const _accessTokenKey = 'access_token';
  static const _refreshTokenKey = 'refresh_token';
  static const _userIdKey = 'user_id';
  static const _userRoleKey = 'user_role';
  static const _userEmailKey = 'user_email';

  static const _storage = FlutterSecureStorage();

  /// Save tokens after login/register
  static Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
    required String userId,
    required String userRole,
    required String userEmail,
  }) async {
    await Future.wait([
      _storage.write(key: _accessTokenKey, value: accessToken),
      _storage.write(key: _refreshTokenKey, value: refreshToken),
      _storage.write(key: _userIdKey, value: userId),
      _storage.write(key: _userRoleKey, value: userRole),
      _storage.write(key: _userEmailKey, value: userEmail),
    ]);
  }

  /// Get access token
  static Future<String?> getAccessToken() async {
    return await _storage.read(key: _accessTokenKey);
  }

  /// Get refresh token
  static Future<String?> getRefreshToken() async {
    return await _storage.read(key: _refreshTokenKey);
  }

  /// Get user ID
  static Future<String?> getUserId() async {
    return await _storage.read(key: _userIdKey);
  }

  /// Get user role
  static Future<String?> getUserRole() async {
    return await _storage.read(key: _userRoleKey);
  }

  /// Get user email
  static Future<String?> getUserEmail() async {
    return await _storage.read(key: _userEmailKey);
  }

  /// Clear all tokens (logout)
  static Future<void> clearTokens() async {
    await Future.wait([
      _storage.delete(key: _accessTokenKey),
      _storage.delete(key: _refreshTokenKey),
      _storage.delete(key: _userIdKey),
      _storage.delete(key: _userRoleKey),
      _storage.delete(key: _userEmailKey),
    ]);
  }

  /// Check if user is logged in
  static Future<bool> isLoggedIn() async {
    final token = await getAccessToken();
    return token != null && token.isNotEmpty;
  }
}
