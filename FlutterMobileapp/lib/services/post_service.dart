import '../core/api/api_client.dart';
import '../core/api/api_config.dart';

/// Post Service
/// Handles AI enhancement and publishing of posts
class PostService {
  /// Enhance content using AI
  static Future<Map<String, dynamic>> enhanceContent(
    String content,
    List<String> platforms,
  ) async {
    final response = await ApiClient.post(
      ApiConfig.enhance,
      body: {
        'content': content,
        'platforms': platforms,
      },
    );

    return response.data as Map<String, dynamic>;
  }

  /// Publish content to selected platforms
  static Future<bool> publishContent(
    String content,
    List<String> platforms,
  ) async {
    final response = await ApiClient.post(
      ApiConfig.publish,
      body: {
        'content': content,
        'platforms': platforms,
      },
    );

    return response.success;
  }
}
