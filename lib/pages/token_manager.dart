// token_manager.dart
class TokenManager {
  static String? _accessToken;

  static String? get accessToken => _accessToken;

  static void setAccessToken(String token) {
    _accessToken = token;
  }

  static void clearToken() {
    _accessToken = null;
  }
}