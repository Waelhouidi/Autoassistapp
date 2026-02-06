/// Todo Model
/// Data model for todo items
class Todo {
  final String id;
  final String userId;
  final String title;
  final String? description;
  final TodoStatus status;
  final TodoPriority priority;
  final DateTime? dueDate;
  final DateTime createdAt;
  final DateTime updatedAt;

  Todo({
    required this.id,
    required this.userId,
    required this.title,
    this.description,
    required this.status,
    required this.priority,
    this.dueDate,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Create from JSON
  factory Todo.fromJson(Map<String, dynamic> json) {
    return Todo(
      id: json['id'] ?? '',
      userId: json['userId'] ?? '',
      title: json['title'] ?? '',
      description: json['description'],
      status: TodoStatus.fromString(json['status'] ?? 'pending'),
      priority: TodoPriority.fromString(json['priority'] ?? 'medium'),
      dueDate: json['dueDate'] != null
          ? DateTime.tryParse(json['dueDate'].toString())
          : null,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'title': title,
      'description': description,
      'status': status.value,
      'priority': priority.value,
      'dueDate': dueDate?.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  /// Copy with updated values
  Todo copyWith({
    String? title,
    String? description,
    TodoStatus? status,
    TodoPriority? priority,
    DateTime? dueDate,
  }) {
    return Todo(
      id: id,
      userId: userId,
      title: title ?? this.title,
      description: description ?? this.description,
      status: status ?? this.status,
      priority: priority ?? this.priority,
      dueDate: dueDate ?? this.dueDate,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }

  /// Check if todo is overdue
  bool get isOverdue {
    if (dueDate == null || status == TodoStatus.completed) return false;
    return DateTime.now().isAfter(dueDate!);
  }
}

/// Todo Status enum
enum TodoStatus {
  pending('pending', 'Pending'),
  inProgress('in_progress', 'In Progress'),
  completed('completed', 'Completed');

  final String value;
  final String label;

  const TodoStatus(this.value, this.label);

  static TodoStatus fromString(String value) {
    return TodoStatus.values.firstWhere(
      (s) => s.value == value,
      orElse: () => TodoStatus.pending,
    );
  }
}

/// Todo Priority enum
enum TodoPriority {
  low('low', 'Low'),
  medium('medium', 'Medium'),
  high('high', 'High');

  final String value;
  final String label;

  const TodoPriority(this.value, this.label);

  static TodoPriority fromString(String value) {
    return TodoPriority.values.firstWhere(
      (p) => p.value == value,
      orElse: () => TodoPriority.medium,
    );
  }
}
