import '../core/api/api_client.dart';
import '../core/api/api_config.dart';

/// Scheduled Post model
class ScheduledPost {
  final String id;
  final String content;
  final List<String> platforms;
  final DateTime scheduledAt;
  final String status;

  ScheduledPost({
    required this.id,
    required this.content,
    required this.platforms,
    required this.scheduledAt,
    required this.status,
  });

  factory ScheduledPost.fromJson(Map<String, dynamic> json) {
    return ScheduledPost(
      id: json['id'] ?? '',
      content: json['enhancedContent'] ?? json['originalContent'] ?? '',
      platforms: List<String>.from(json['platforms'] ?? []),
      scheduledAt: json['scheduledAt'] != null
          ? DateTime.parse(json['scheduledAt']['_seconds'] != null
              ? DateTime.fromMillisecondsSinceEpoch(
                      json['scheduledAt']['_seconds'] * 1000)
                  .toIso8601String()
              : json['scheduledAt'].toString())
          : DateTime.now(),
      status: json['status'] ?? 'scheduled',
    );
  }
}

/// Post Service
/// Handles AI enhancement, publishing, and scheduling of posts
class PostService {
  /// Enhance content using AI
  /// @param scheduledAt - Optional ISO date string for scheduling
  static Future<Map<String, dynamic>> enhanceContent(
    String content,
    List<String> platforms, {
    String? scheduledAt,
  }) async {
    final body = {
      'content': content,
      'platforms': platforms,
    };

    if (scheduledAt != null) {
      body['scheduledAt'] = scheduledAt;
    }

    final response = await ApiClient.post(
      ApiConfig.enhance,
      body: body,
    );

    return response.data as Map<String, dynamic>;
  }

  /// Publish content to selected platforms
  /// @param scheduledAt - Optional ISO date string for scheduling
  /// @param publishNow - If false and scheduledAt is set, schedules the post
  static Future<Map<String, dynamic>> publishContent(
    String content,
    List<String> platforms, {
    String? postId,
    String? scheduledAt,
    bool publishNow = true,
  }) async {
    final body = <String, dynamic>{
      'content': content,
      'platforms': platforms,
      'publishNow': publishNow,
    };

    if (postId != null) {
      body['postId'] = postId;
    }

    if (scheduledAt != null) {
      body['scheduledAt'] = scheduledAt;
    }

    final response = await ApiClient.post(
      ApiConfig.publish,
      body: body,
    );

    return {
      'success': response.success,
      'data': response.data,
      'message': response.message,
    };
  }

  /// Schedule a post for later publishing
  static Future<Map<String, dynamic>> schedulePost({
    required String postId,
    required String scheduledAt,
    required List<String> platforms,
  }) async {
    final response = await ApiClient.post(
      ApiConfig.schedule,
      body: {
        'postId': postId,
        'scheduledAt': scheduledAt,
        'platforms': platforms,
      },
    );

    return {
      'success': response.success,
      'data': response.data,
      'message': response.message,
    };
  }

  /// Get all scheduled posts
  static Future<List<ScheduledPost>> getScheduledPosts() async {
    final response = await ApiClient.get(ApiConfig.scheduled);

    if (response.success && response.data != null) {
      final List<dynamic> data = response.data as List<dynamic>;
      return data.map((json) => ScheduledPost.fromJson(json)).toList();
    }

    return [];
  }

  /// Cancel a scheduled post
  static Future<bool> cancelScheduledPost(String postId) async {
    final response = await ApiClient.delete('${ApiConfig.schedule}/$postId');
    return response.success;
  }

  /// Get post history
  static Future<List<Map<String, dynamic>>> getPostHistory({
    int limit = 20,
    String? status,
  }) async {
    String endpoint = '${ApiConfig.posts}?limit=$limit';
    if (status != null) {
      endpoint += '&status=$status';
    }

    final response = await ApiClient.get(endpoint);

    if (response.success && response.data != null) {
      return List<Map<String, dynamic>>.from(response.data);
    }

    return [];
  }

  /// Get post statistics
  static Future<Map<String, dynamic>> getStats() async {
    final response = await ApiClient.get(ApiConfig.postStats);

    if (response.success && response.data != null) {
      return response.data as Map<String, dynamic>;
    }

    return {};
  }
}
