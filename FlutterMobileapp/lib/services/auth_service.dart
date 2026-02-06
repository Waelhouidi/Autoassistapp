import '../core/api/api_client.dart';
import '../core/api/api_config.dart';
import '../providers/user_provider.dart';

/// Auth Service
/// Handles authentication related API operations
class AuthService {
  /// Login with email and password
  static Future<Map<String, dynamic>> login(String email, String password,
      {UserProvider? userProvider}) async {
    final response = await ApiClient.post(
      ApiConfig.login,
      body: {
        'email': email,
        'password': password,
      },
    );

    if (response.success && response.data != null) {
      // Store token
      final token = response.data['token'];
      ApiClient.setToken(token);

      // Update UserProvider if user info is returned
      if (userProvider != null) {
        final userData = response.data['user'] ?? {};
        await userProvider.setUser(
          userData['username'] ?? 'User',
          userData['email'] ?? email,
          profilePhoto: userData['profilePhoto'],
        );
      }
      return response.data;
    }

    throw Exception(response.message ?? 'Login failed');
  }

  /// Register new user
  static Future<Map<String, dynamic>> register(
      String name, String email, String password,
      {UserProvider? userProvider}) async {
    final response = await ApiClient.post(
      ApiConfig.register,
      body: {
        'username': name,
        'email': email,
        'password': password,
      },
    );

    if (response.success && response.data != null) {
      // Store token (if returned on register) or just return success
      if (response.data['token'] != null) {
        ApiClient.setToken(response.data['token']);
      }

      // Update UserProvider
      if (userProvider != null) {
        final userData = response.data['user'] ?? {};
        await userProvider.setUser(
          userData['username'] ?? name,
          userData['email'] ?? email,
          profilePhoto: userData['profilePhoto'],
        );
      }
      return response.data;
    }

    throw Exception(response.message ?? 'Registration failed');
  }

  /// Logout
  static Future<void> logout({UserProvider? userProvider}) async {
    try {
      await ApiClient.post(ApiConfig.logout);
    } catch (_) {
      // Ignore logout errors
    } finally {
      ApiClient.clearToken();
      if (userProvider != null) {
        await userProvider.clearUser();
      }
    }
  }

  /// Update user profile
  static Future<ApiResponse> updateProfile(String name, String email) async {
    return await ApiClient.patch(
      ApiConfig.me,
      body: {
        'displayName': name,
        'email': email,
      },
    );
  }

  /// Change password
  static Future<ApiResponse> changePassword(
      String oldPassword, String newPassword) async {
    return await ApiClient.post(
      ApiConfig.changePassword,
      body: {
        'oldPassword': oldPassword,
        'newPassword': newPassword,
      },
    );
  }

  /// Update user settings
  static Future<ApiResponse> updateSettings(
      Map<String, dynamic> settings) async {
    return await ApiClient.patch(
      ApiConfig.me,
      body: {
        'settings': settings,
      },
    );
  }
}
