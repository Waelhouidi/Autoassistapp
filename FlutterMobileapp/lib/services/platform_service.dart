import '../core/api/api_client.dart';
import '../core/api/api_config.dart';

/// Platform model representing a connected social platform
class PlatformConnection {
  final String name;
  final bool connected;
  final PlatformProfile? profile;

  PlatformConnection({
    required this.name,
    required this.connected,
    this.profile,
  });

  factory PlatformConnection.fromJson(Map<String, dynamic> json) {
    return PlatformConnection(
      name: json['name'] ?? '',
      connected: json['connected'] ?? false,
      profile: json['profile'] != null
          ? PlatformProfile.fromJson(json['profile'])
          : null,
    );
  }
}

/// Platform profile info
class PlatformProfile {
  final String? name;
  final String? username;
  final String? avatarUrl;

  PlatformProfile({
    this.name,
    this.username,
    this.avatarUrl,
  });

  factory PlatformProfile.fromJson(Map<String, dynamic> json) {
    return PlatformProfile(
      name: json['name'],
      username: json['username'],
      avatarUrl: json['avatarUrl'],
    );
  }
}

/// Platform Service
/// Handles OAuth connections to social media platforms
class PlatformService {
  /// Get status of all platform connections for current user
  static Future<Map<String, PlatformConnection>> getPlatformStatus() async {
    final response = await ApiClient.get(ApiConfig.platformStatus);

    if (response.success && response.data != null) {
      final Map<String, dynamic> data = response.data as Map<String, dynamic>;
      final Map<String, PlatformConnection> platforms = {};

      data.forEach((key, value) {
        platforms[key] = PlatformConnection(
          name: key,
          connected: value['connected'] ?? false,
          profile: value['profile'] != null
              ? PlatformProfile.fromJson(value['profile'])
              : null,
        );
      });

      return platforms;
    }

    return {};
  }

  /// Initiate OAuth flow for a platform
  /// Returns the authorization URL to open in browser
  static Future<String?> initiateAuth(String platform) async {
    final response =
        await ApiClient.get(ApiConfig.platformAuth(platform.toLowerCase()));

    if (response.success && response.data != null) {
      return response.data['authUrl'] as String?;
    }

    return null;
  }

  /// Complete OAuth callback after user authorizes
  static Future<bool> completeAuth({
    required String platform,
    String? code, // For OAuth 2.0 (LinkedIn)
    String? oauthToken, // For OAuth 1.0a (Twitter)
    String? oauthVerifier, // For OAuth 1.0a (Twitter)
  }) async {
    final body = <String, dynamic>{};

    if (code != null) {
      body['code'] = code;
    }
    if (oauthToken != null) {
      body['oauth_token'] = oauthToken;
    }
    if (oauthVerifier != null) {
      body['oauth_verifier'] = oauthVerifier;
    }

    final response = await ApiClient.post(
      ApiConfig.platformCallback(platform.toLowerCase()),
      body: body,
    );

    return response.success;
  }

  /// Connect using email and password credentials
  static Future<bool> connectWithCredentials({
    required String platform,
    required String email,
    required String password,
  }) async {
    final response = await ApiClient.post(
      ApiConfig.platformConnectCredentials(platform.toLowerCase()),
      body: {
        'email': email,
        'password': password,
      },
    );

    return response.success;
  }

  /// Disconnect a platform
  static Future<bool> disconnect(String platform) async {
    final response = await ApiClient.delete(
        ApiConfig.platformDisconnect(platform.toLowerCase()));

    return response.success;
  }

  /// Refresh platform tokens
  static Future<bool> refreshToken(String platform) async {
    final response = await ApiClient.post(
      ApiConfig.platformRefresh(platform.toLowerCase()),
    );

    return response.success;
  }

  /// Check if a specific platform is connected
  static Future<bool> isConnected(String platform) async {
    final status = await getPlatformStatus();
    return status[platform.toLowerCase()]?.connected ?? false;
  }

  /// Get list of connected platform names
  static Future<List<String>> getConnectedPlatforms() async {
    final status = await getPlatformStatus();
    return status.entries
        .where((entry) => entry.value.connected)
        .map((entry) => entry.key)
        .toList();
  }
}
