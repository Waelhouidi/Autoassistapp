import '../core/api/api_client.dart';
import '../core/api/api_config.dart';
import '../models/todo.dart';

/// Todo Service
/// Handles all todo-related API operations
class TodoService {
  /// Get all todos with optional filters
  static Future<List<Todo>> getTodos({
    TodoStatus? status,
    TodoPriority? priority,
    int? limit,
  }) async {
    String endpoint = ApiConfig.todos;

    final params = <String, String>{};
    if (status != null) params['status'] = status.value;
    if (priority != null) params['priority'] = priority.value;
    if (limit != null) params['limit'] = limit.toString();

    if (params.isNotEmpty) {
      endpoint +=
          '?${params.entries.map((e) => '${e.key}=${e.value}').join('&')}';
    }

    final response = await ApiClient.get(endpoint);

    if (response.data is List) {
      return (response.data as List)
          .map((json) => Todo.fromJson(json))
          .toList();
    }

    return [];
  }

  /// Get a single todo by ID
  static Future<Todo?> getTodoById(String id) async {
    final response = await ApiClient.get('${ApiConfig.todos}/$id');

    if (response.data != null) {
      return Todo.fromJson(response.data);
    }

    return null;
  }

  /// Create a new todo
  static Future<Todo> createTodo({
    required String title,
    String? description,
    TodoPriority priority = TodoPriority.medium,
    DateTime? dueDate,
  }) async {
    final response = await ApiClient.post(
      ApiConfig.todos,
      body: {
        'title': title,
        if (description != null && description.isNotEmpty)
          'description': description,
        'priority': priority.value,
        if (dueDate != null) 'dueDate': dueDate.toIso8601String(),
      },
    );

    return Todo.fromJson(response.data);
  }

  /// Update a todo
  static Future<Todo> updateTodo(
    String id, {
    String? title,
    String? description,
    TodoStatus? status,
    TodoPriority? priority,
    DateTime? dueDate,
  }) async {
    final body = <String, dynamic>{};
    if (title != null) body['title'] = title;
    if (description != null) body['description'] = description;
    if (status != null) body['status'] = status.value;
    if (priority != null) body['priority'] = priority.value;
    if (dueDate != null) body['dueDate'] = dueDate.toIso8601String();

    final response = await ApiClient.put('${ApiConfig.todos}/$id', body: body);

    return Todo.fromJson(response.data);
  }

  /// Toggle todo status
  static Future<Todo> toggleTodoStatus(String id) async {
    final response = await ApiClient.patch('${ApiConfig.todos}/$id/toggle');

    return Todo.fromJson(response.data);
  }

  /// Delete a todo
  static Future<bool> deleteTodo(String id) async {
    await ApiClient.delete('${ApiConfig.todos}/$id');
    return true;
  }

  /// Get todo statistics
  static Future<TodoStats> getStats() async {
    final response = await ApiClient.get(ApiConfig.todoStats);

    return TodoStats.fromJson(response.data);
  }
}

/// Todo statistics
class TodoStats {
  final int total;
  final int pending;
  final int inProgress;
  final int completed;
  final int highPriority;

  TodoStats({
    required this.total,
    required this.pending,
    required this.inProgress,
    required this.completed,
    required this.highPriority,
  });

  factory TodoStats.fromJson(Map<String, dynamic> json) {
    return TodoStats(
      total: json['total'] ?? 0,
      pending: json['pending'] ?? 0,
      inProgress: json['in_progress'] ?? 0,
      completed: json['completed'] ?? 0,
      highPriority: json['high_priority'] ?? 0,
    );
  }
}
