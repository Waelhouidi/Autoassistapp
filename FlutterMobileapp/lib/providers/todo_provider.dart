import 'package:flutter/foundation.dart';
import '../models/todo.dart';
import '../services/todo_service.dart';
import '../core/api/api_exceptions.dart';

class TodoProvider extends ChangeNotifier {
  List<Todo> _todos = [];
  TodoStats? _stats;
  bool _isLoading = false;
  String? _error;

  // Getters
  List<Todo> get todos => _todos;
  TodoStats? get stats => _stats;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Filter state
  TodoStatus? _filterStatus;
  TodoPriority? _filterPriority;

  TodoStatus? get filterStatus => _filterStatus;
  TodoPriority? get filterPriority => _filterPriority;

  void setFilterStatus(TodoStatus? status) {
    _filterStatus = status;
    loadTodos();
  }

  void setFilterPriority(TodoPriority? priority) {
    _filterPriority = priority;
    loadTodos();
  }

  /// Load all data (Todos and Stats)
  Future<void> loadData() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Load both in parallel
      await Future.wait([
        loadTodos(setLoading: false), // Don't trigger loading twice
        loadStats(setLoading: false),
      ]);
    } catch (e) {
      _error = 'Failed to load data: $e';
      debugPrint(_error);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Load Todos specifically
  Future<void> loadTodos({bool setLoading = true}) async {
    if (setLoading) {
      _isLoading = true;
      _error = null;
      notifyListeners();
    }

    try {
      _todos = await TodoService.getTodos(
        status: _filterStatus,
        priority: _filterPriority,
      );
    } on ApiException catch (e) {
      _error = e.displayMessage;
      debugPrint('API Error loading todos: $e');
    } catch (e) {
      _error = 'Failed to load tasks. Please check your connection.';
      debugPrint('Error loading todos: $e');
    } finally {
      if (setLoading) {
        _isLoading = false;
        notifyListeners();
      }
    }
  }

  /// Load Stats specifically
  Future<void> loadStats({bool setLoading = true}) async {
    try {
      _stats = await TodoService.getStats();
      if (!setLoading)
        notifyListeners(); // Only notify if not controlled by parent
    } catch (e) {
      debugPrint('Error loading stats: $e');
    }
  }

  Future<void> createTodo({
    required String title,
    String? description,
    TodoPriority priority = TodoPriority.medium,
    DateTime? dueDate,
  }) async {
    try {
      await TodoService.createTodo(
        title: title,
        description: description,
        priority: priority,
        dueDate: dueDate,
      );
      // Refresh both list and stats to ensure consistency
      await loadData();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateTodo(
    String id, {
    String? title,
    String? description,
    TodoStatus? status,
    TodoPriority? priority,
    DateTime? dueDate,
  }) async {
    try {
      await TodoService.updateTodo(
        id,
        title: title,
        description: description,
        status: status,
        priority: priority,
        dueDate: dueDate,
      );
      await loadData();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> toggleTodoStatus(String id) async {
    try {
      // Optimistic update
      final index = _todos.indexWhere((t) => t.id == id);
      if (index != -1) {
        // We don't change the list locally yet as we don't know the exact logic
        // needed to create the new object without more code,
        // but we could mark it as loading if needed.
      }

      await TodoService.toggleTodoStatus(id);
      await loadData();
    } catch (e) {
      _error = 'Failed to update status';
      notifyListeners();
      rethrow;
    }
  }

  Future<void> deleteTodo(String id) async {
    try {
      await TodoService.deleteTodo(id);

      // Optimistic removal
      _todos.removeWhere((t) => t.id == id);
      notifyListeners();

      // Sync everything
      await loadData();
    } catch (e) {
      // Revert if needed (would need restore logic), for now just reload
      await loadTodos();
      rethrow;
    }
  }
}
