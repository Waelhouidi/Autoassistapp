import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_typography.dart';
import '../core/theme/app_spacing.dart';
import '../core/api/api_exceptions.dart';
import '../models/todo.dart';
import '../services/todo_service.dart';

import 'package:provider/provider.dart';
import '../providers/todo_provider.dart';
import '../widgets/skeleton_loader.dart';
import 'package:lottie/lottie.dart';

class TodoListScreen extends StatefulWidget {
  const TodoListScreen({super.key});

  @override
  State<TodoListScreen> createState() => _TodoListScreenState();
}

class _TodoListScreenState extends State<TodoListScreen>
    with TickerProviderStateMixin {
  late AnimationController _fabController;
  late Animation<double> _fabAnimation;

  @override
  void initState() {
    super.initState();
    _initAnimations();
    // Data is loaded in main.dart or via refresh
  }

  void _initAnimations() {
    _fabController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _fabAnimation = CurvedAnimation(
      parent: _fabController,
      curve: Curves.easeOut,
    );
    _fabController.forward();
  }

  Future<void> _toggleTodoStatus(Todo todo) async {
    try {
      HapticFeedback.lightImpact();
      final isCompleting = todo.status != TodoStatus.completed;
      await context.read<TodoProvider>().toggleTodoStatus(todo.id);

      if (isCompleting) {
        _showCelebration();
      } else {
        _showSuccessSnackBar('Status updated! ✨');
      }
    } catch (e) {
      // Error handled in provider
    }
  }

  void _showCelebration() {
    final overlay = Overlay.of(context);
    final entry = OverlayEntry(
      builder: (context) => Stack(
        children: [
          IgnorePointer(
            child: Center(
              child: Lottie.network(
                'https://assets10.lottiefiles.com/packages/lf20_vu93ey.json', // Alternative celebration
                width: 300,
                height: 300,
                repeat: false,
                onWarning: (warning) => debugPrint('Lottie Warning: $warning'),
                errorBuilder: (context, error, stackTrace) {
                  debugPrint('Lottie Celebration Error: $error');
                  return const SizedBox();
                },
                onLoaded: (composition) {
                  Future.delayed(composition.duration, () {
                    // entry.remove() later
                  });
                },
              ),
            ),
          ),
        ],
      ),
    );

    overlay.insert(entry);
    Future.delayed(const Duration(seconds: 2), () {
      if (entry.mounted) entry.remove();
    });
  }

  Future<void> _deleteTodo(Todo todo) async {
    try {
      await context.read<TodoProvider>().deleteTodo(todo.id);
      _showSuccessSnackBar('Todo deleted 🗑️');
    } catch (e) {
      _showErrorSnackBar('Failed to delete task');
    }
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
              ),
              child: const Icon(
                Icons.check_circle_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(
                message,
                style: AppTypography.bodyMedium.copyWith(color: Colors.white),
              ),
            ),
          ],
        ),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        ),
        margin: const EdgeInsets.all(AppSpacing.md),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
              ),
              child: const Icon(
                Icons.error_outline_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(
                message,
                style: AppTypography.bodyMedium.copyWith(color: Colors.white),
              ),
            ),
          ],
        ),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        ),
        margin: const EdgeInsets.all(AppSpacing.md),
        action: SnackBarAction(
          label: 'Retry',
          textColor: Colors.white,
          onPressed: () => context.read<TodoProvider>().loadData(),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _fabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Consumer<TodoProvider>(
        builder: (context, provider, child) {
          return RefreshIndicator(
            onRefresh: provider.loadData,
            color: AppColors.primary,
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                _buildAppBar(context, provider.todos.length),
                SliverToBoxAdapter(child: _buildFilterChips(provider)),
                if (provider.isLoading && provider.todos.isEmpty)
                  const SliverFillRemaining(child: _LoadingIndicator())
                else if (provider.error != null && provider.todos.isEmpty)
                  SliverFillRemaining(
                      child: _ErrorView(
                          error: provider.error!, onRetry: provider.loadData))
                else if (provider.todos.isEmpty)
                  const SliverFillRemaining(child: _EmptyView())
                else
                  _buildTodoList(provider.todos),
              ],
            ),
          );
        },
      ),
      floatingActionButton: ScaleTransition(
        scale: _fabAnimation,
        child: FloatingActionButton.extended(
          onPressed: () => _showAddTodoDialog(context),
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: AppSpacing.elevationMd,
          icon: const Icon(Icons.add_rounded),
          label: const Text('Add Task'),
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context, int count) {
    return SliverAppBar(
      expandedHeight: 140,
      floating: false,
      pinned: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            gradient: AppColors.primaryGradient,
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(AppSpacing.sm),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius:
                              BorderRadius.circular(AppSpacing.radiusMd),
                        ),
                        child: const Icon(
                          Icons.checklist_rounded,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Text(
                        'My Tasks',
                        style: AppTypography.h1.copyWith(color: Colors.white),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md,
                          vertical: AppSpacing.sm,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius:
                              BorderRadius.circular(AppSpacing.radiusFull),
                        ),
                        child: Text(
                          '$count',
                          style: AppTypography.h3.copyWith(color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChips(TodoProvider provider) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.md,
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _FilterChip(
              label: 'All',
              isSelected: provider.filterStatus == null,
              onTap: () => provider.setFilterStatus(null),
            ),
            const SizedBox(width: AppSpacing.sm),
            _FilterChip(
              label: 'Pending',
              isSelected: provider.filterStatus == TodoStatus.pending,
              color: AppColors.statusPending,
              onTap: () => provider.setFilterStatus(TodoStatus.pending),
            ),
            const SizedBox(width: AppSpacing.sm),
            _FilterChip(
              label: 'In Progress',
              isSelected: provider.filterStatus == TodoStatus.inProgress,
              color: AppColors.statusInProgress,
              onTap: () => provider.setFilterStatus(TodoStatus.inProgress),
            ),
            const SizedBox(width: AppSpacing.sm),
            _FilterChip(
              label: 'Completed',
              isSelected: provider.filterStatus == TodoStatus.completed,
              color: AppColors.statusCompleted,
              onTap: () => provider.setFilterStatus(TodoStatus.completed),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTodoList(List<Todo> todos) {
    return SliverPadding(
      padding: const EdgeInsets.only(
        left: AppSpacing.md,
        right: AppSpacing.md,
        bottom: 100,
      ),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final todo = todos[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.md),
              child: _TodoCard(
                todo: todo,
                onToggle: () => _toggleTodoStatus(todo),
                onEdit: () => _showEditTodoDialog(context, todo),
                onDelete: () => _confirmDeleteTodo(todo),
              ),
            );
          },
          childCount: todos.length,
        ),
      ),
    );
  }

  void _showAddTodoDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _TodoFormSheet(
        onSave: (title, description, priority, dueDate, status) async {
          try {
            await context.read<TodoProvider>().createTodo(
                  title: title,
                  description: description,
                  priority: priority,
                  dueDate: dueDate,
                );
            _showSuccessSnackBar('Task created! 🎉');
          } catch (e) {
            _showErrorSnackBar('Failed to create task');
          }
        },
      ),
    );
  }

  void _showEditTodoDialog(BuildContext context, Todo todo) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _TodoFormSheet(
        todo: todo,
        onSave: (title, description, priority, dueDate, status) async {
          try {
            await context.read<TodoProvider>().updateTodo(
                  todo.id,
                  title: title,
                  description: description,
                  priority: priority,
                  dueDate: dueDate,
                  status: status,
                );
            _showSuccessSnackBar('Task updated! ✨');
          } catch (e) {
            _showErrorSnackBar('Failed to update task');
          }
        },
      ),
    );
  }

  void _confirmDeleteTodo(Todo todo) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
              ),
              child: const Icon(Icons.delete_outline_rounded,
                  color: AppColors.error),
            ),
            const SizedBox(width: AppSpacing.md),
            const Text('Delete Task?'),
          ],
        ),
        content: Text(
          'Are you sure you want to delete "${todo.title}"? This action cannot be undone.',
          style: AppTypography.body,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteTodo(todo);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

// Filter Chip Widget
class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final Color? color;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: AppSpacing.animationFast,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? (color ?? AppColors.primary)
              : Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
          border: Border.all(
            color: isSelected ? (color ?? AppColors.primary) : AppColors.border,
            width: 1.5,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: (color ?? AppColors.primary).withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: AppTypography.captionMedium.copyWith(
            color: isSelected ? Colors.white : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}

// Todo Card Widget
class _TodoCard extends StatelessWidget {
  final Todo todo;
  final VoidCallback onToggle;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _TodoCard({
    required this.todo,
    required this.onToggle,
    required this.onEdit,
    required this.onDelete,
  });

  Color get _priorityColor {
    switch (todo.priority) {
      case TodoPriority.high:
        return AppColors.priorityHigh;
      case TodoPriority.medium:
        return AppColors.priorityMedium;
      case TodoPriority.low:
        return AppColors.priorityLow;
    }
  }

  Color get _statusColor {
    switch (todo.status) {
      case TodoStatus.pending:
        return AppColors.statusPending;
      case TodoStatus.inProgress:
        return AppColors.statusInProgress;
      case TodoStatus.completed:
        return AppColors.statusCompleted;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isCompleted = todo.status == TodoStatus.completed;

    return Dismissible(
      key: Key(todo.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onDelete(),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: AppSpacing.lg),
        decoration: BoxDecoration(
          color: AppColors.error,
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        ),
        child: const Icon(
          Icons.delete_rounded,
          color: Colors.white,
          size: 28,
        ),
      ),
      child: GestureDetector(
        onTap: onEdit,
        child: Container(
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
            border: Border.all(
              color: todo.isOverdue
                  ? AppColors.error.withValues(alpha: 0.3)
                  : AppColors.border,
              width: todo.isOverdue ? 2 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Priority indicator
              Container(
                height: 4,
                decoration: BoxDecoration(
                  color: _priorityColor,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(AppSpacing.radiusLg),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Checkbox
                    GestureDetector(
                      onTap: onToggle,
                      child: AnimatedContainer(
                        duration: AppSpacing.animationFast,
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color:
                              isCompleted ? _statusColor : Colors.transparent,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: _statusColor,
                            width: 2,
                          ),
                        ),
                        child: isCompleted
                            ? const Icon(
                                Icons.check_rounded,
                                color: Colors.white,
                                size: 18,
                              )
                            : null,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    // Content
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            todo.title,
                            style: AppTypography.bodyBold.copyWith(
                              decoration: isCompleted
                                  ? TextDecoration.lineThrough
                                  : null,
                              color: isCompleted
                                  ? AppColors.textTertiary
                                  : AppColors.textPrimary,
                            ),
                          ),
                          if (todo.description != null &&
                              todo.description!.isNotEmpty) ...[
                            const SizedBox(height: AppSpacing.xs),
                            Text(
                              todo.description!,
                              style: AppTypography.caption.copyWith(
                                color: isCompleted
                                    ? AppColors.textTertiary
                                    : AppColors.textSecondary,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                          const SizedBox(height: AppSpacing.sm),
                          Row(
                            children: [
                              _StatusBadge(status: todo.status),
                              const SizedBox(width: AppSpacing.sm),
                              _PriorityBadge(priority: todo.priority),
                              if (todo.dueDate != null) ...[
                                const Spacer(),
                                _DueDateBadge(
                                  dueDate: todo.dueDate!,
                                  isOverdue: todo.isOverdue,
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                    // Menu
                    PopupMenuButton<String>(
                      icon: const Icon(
                        Icons.more_vert_rounded,
                        color: AppColors.textSecondary,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(AppSpacing.radiusMd),
                      ),
                      onSelected: (value) {
                        if (value == 'edit') onEdit();
                        if (value == 'delete') onDelete();
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'edit',
                          child: Row(
                            children: [
                              Icon(Icons.edit_rounded, size: 20),
                              SizedBox(width: AppSpacing.sm),
                              Text('Edit'),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(Icons.delete_rounded,
                                  size: 20, color: AppColors.error),
                              SizedBox(width: AppSpacing.sm),
                              Text('Delete',
                                  style: TextStyle(color: AppColors.error)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Status Badge
class _StatusBadge extends StatelessWidget {
  final TodoStatus status;

  const _StatusBadge({required this.status});

  Color get _color {
    switch (status) {
      case TodoStatus.pending:
        return AppColors.statusPending;
      case TodoStatus.inProgress:
        return AppColors.statusInProgress;
      case TodoStatus.completed:
        return AppColors.statusCompleted;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: _color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
      ),
      child: Text(
        status.label,
        style: AppTypography.small.copyWith(
          color: _color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

// Priority Badge
class _PriorityBadge extends StatelessWidget {
  final TodoPriority priority;

  const _PriorityBadge({required this.priority});

  Color get _color {
    switch (priority) {
      case TodoPriority.high:
        return AppColors.priorityHigh;
      case TodoPriority.medium:
        return AppColors.priorityMedium;
      case TodoPriority.low:
        return AppColors.priorityLow;
    }
  }

  IconData get _icon {
    switch (priority) {
      case TodoPriority.high:
        return Icons.keyboard_double_arrow_up_rounded;
      case TodoPriority.medium:
        return Icons.remove_rounded;
      case TodoPriority.low:
        return Icons.keyboard_double_arrow_down_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: _color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_icon, size: 14, color: _color),
          const SizedBox(width: 2),
          Text(
            priority.label,
            style: AppTypography.small.copyWith(
              color: _color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// Due Date Badge
class _DueDateBadge extends StatelessWidget {
  final DateTime dueDate;
  final bool isOverdue;

  const _DueDateBadge({required this.dueDate, required this.isOverdue});

  String get _formattedDate {
    final now = DateTime.now();
    final difference = dueDate.difference(now).inDays;

    if (difference == 0) return 'Today';
    if (difference == 1) return 'Tomorrow';
    if (difference == -1) return 'Yesterday';
    if (difference < 0) return '${-difference}d overdue';
    if (difference < 7) return 'In ${difference}d';

    return '${dueDate.day}/${dueDate.month}';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: isOverdue
            ? AppColors.error.withValues(alpha: 0.1)
            : Theme.of(context).brightness == Brightness.dark
                ? AppColors.surfaceDark
                : AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.schedule_rounded,
            size: 12,
            color: isOverdue ? AppColors.error : AppColors.textSecondary,
          ),
          const SizedBox(width: 4),
          Text(
            _formattedDate,
            style: AppTypography.small.copyWith(
              color: isOverdue ? AppColors.error : AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// Loading Indicator
class _LoadingIndicator extends StatelessWidget {
  const _LoadingIndicator();

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(AppSpacing.md),
      itemCount: 6,
      itemBuilder: (context, index) => const SkeletonTodoCard(),
    );
  }
}

// Error View
class _ErrorView extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;

  const _ErrorView({required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.error_outline_rounded,
                size: 64,
                color: AppColors.error,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            const Text(
              'Error Occurred',
              style: AppTypography.h3,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              error,
              style:
                  AppTypography.body.copyWith(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xl),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }
}

// Empty View
class _EmptyView extends StatelessWidget {
  const _EmptyView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              height: 200,
              child: Lottie.network(
                'https://assets5.lottiefiles.com/packages/lf20_t9gkkhz4.json', // Alternative empty state
                fit: BoxFit.contain,
                onWarning: (warning) => debugPrint('Lottie Warning: $warning'),
                errorBuilder: (context, error, stackTrace) {
                  debugPrint('Lottie Error: $error');
                  return const Icon(
                    Icons.task_alt_rounded,
                    size: 80,
                    color: AppColors.primary,
                  );
                },
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            const Text(
              'No tasks yet!',
              style: AppTypography.h2,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Tap the + button to create your first task and start being productive! 🚀',
              style:
                  AppTypography.body.copyWith(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// Todo Form Sheet
class _TodoFormSheet extends StatefulWidget {
  final Todo? todo;
  final Future<void> Function(String title, String? description,
      TodoPriority priority, DateTime? dueDate, TodoStatus status) onSave;

  const _TodoFormSheet({this.todo, required this.onSave});

  @override
  State<_TodoFormSheet> createState() => _TodoFormSheetState();
}

class _TodoFormSheetState extends State<_TodoFormSheet> {
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late TodoPriority _priority;
  late TodoStatus _status;
  DateTime? _dueDate;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.todo?.title ?? '');
    _descriptionController =
        TextEditingController(text: widget.todo?.description ?? '');
    _priority = widget.todo?.priority ?? TodoPriority.medium;
    _status = widget.todo?.status ?? TodoStatus.pending;
    _dueDate = widget.todo?.dueDate;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please enter a title'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          ),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    await widget.onSave(
      _titleController.text.trim(),
      _descriptionController.text.trim().isEmpty
          ? null
          : _descriptionController.text.trim(),
      _priority,
      _dueDate,
      _status,
    );

    if (mounted) {
      Navigator.pop(context);
    }
  }

  Future<void> _pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
                  primary: AppColors.primary,
                ),
          ),
          child: child!,
        );
      },
    );

    if (date != null) {
      setState(() => _dueDate = date);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppSpacing.radiusXl),
        ),
        child: Container(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor.withValues(alpha: 0.8),
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(AppSpacing.radiusXl),
            ),
            border: Border.all(
              color: Theme.of(context).dividerColor.withValues(alpha: 0.1),
            ),
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Handle
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.border,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                // Title
                Text(
                  widget.todo == null ? 'New Task ✨' : 'Edit Task',
                  style: AppTypography.h2,
                ),
                const SizedBox(height: AppSpacing.lg),
                // Title Input
                TextField(
                  controller: _titleController,
                  decoration: const InputDecoration(
                    labelText: 'Title',
                    hintText: 'What do you need to do?',
                    prefixIcon: Icon(Icons.title_rounded),
                  ),
                  textCapitalization: TextCapitalization.sentences,
                  autofocus: widget.todo == null,
                ),
                const SizedBox(height: AppSpacing.md),
                // Description Input
                TextField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Description (optional)',
                    hintText: 'Add some details...',
                    prefixIcon: Icon(Icons.notes_rounded),
                  ),
                  textCapitalization: TextCapitalization.sentences,
                  maxLines: 3,
                ),
                const SizedBox(height: AppSpacing.lg),

                // Status Selector
                const Text('Status', style: AppTypography.label),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  children: TodoStatus.values.map((s) {
                    final isSelected = s == _status;
                    return Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(
                          right: s != TodoStatus.completed ? AppSpacing.sm : 0,
                        ),
                        child: GestureDetector(
                          onTap: () => setState(() => _status = s),
                          child: AnimatedContainer(
                            duration: AppSpacing.animationFast,
                            padding: const EdgeInsets.symmetric(
                              vertical: AppSpacing.md,
                            ),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? _getStatusColor(s).withValues(alpha: 0.1)
                                  : Theme.of(context).brightness ==
                                          Brightness.dark
                                      ? AppColors.surfaceDark
                                      : AppColors.surfaceVariant,
                              borderRadius:
                                  BorderRadius.circular(AppSpacing.radiusMd),
                              border: Border.all(
                                color: isSelected
                                    ? _getStatusColor(s)
                                    : Colors.transparent,
                                width: 2,
                              ),
                            ),
                            child: Column(
                              children: [
                                Icon(
                                  _getStatusIcon(s),
                                  color: isSelected
                                      ? _getStatusColor(s)
                                      : AppColors.textSecondary,
                                  size: 20,
                                ),
                                const SizedBox(height: AppSpacing.xs),
                                Text(
                                  s.label,
                                  style: AppTypography.captionMedium.copyWith(
                                    color: isSelected
                                        ? _getStatusColor(s)
                                        : AppColors.textSecondary,
                                    fontSize: 11,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: AppSpacing.lg),

                // Priority
                const Text('Priority', style: AppTypography.label),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  children: TodoPriority.values.map((p) {
                    final isSelected = p == _priority;
                    return Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(
                          right: p != TodoPriority.high ? AppSpacing.sm : 0,
                        ),
                        child: GestureDetector(
                          onTap: () => setState(() => _priority = p),
                          child: AnimatedContainer(
                            duration: AppSpacing.animationFast,
                            padding: const EdgeInsets.symmetric(
                              vertical: AppSpacing.md,
                            ),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? _getPriorityColor(p).withValues(alpha: 0.1)
                                  : Theme.of(context).brightness ==
                                          Brightness.dark
                                      ? AppColors.surfaceDark
                                      : AppColors.surfaceVariant,
                              borderRadius:
                                  BorderRadius.circular(AppSpacing.radiusMd),
                              border: Border.all(
                                color: isSelected
                                    ? _getPriorityColor(p)
                                    : Colors.transparent,
                                width: 2,
                              ),
                            ),
                            child: Column(
                              children: [
                                Icon(
                                  _getPriorityIcon(p),
                                  color: isSelected
                                      ? _getPriorityColor(p)
                                      : AppColors.textSecondary,
                                ),
                                const SizedBox(height: AppSpacing.xs),
                                Text(
                                  p.label,
                                  style: AppTypography.captionMedium.copyWith(
                                    color: isSelected
                                        ? _getPriorityColor(p)
                                        : AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: AppSpacing.lg),
                // Due Date
                GestureDetector(
                  onTap: _pickDate,
                  child: Container(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceVariant,
                      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today_rounded,
                            color: AppColors.textSecondary),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Text(
                            _dueDate != null
                                ? 'Due: ${_dueDate!.day}/${_dueDate!.month}/${_dueDate!.year}'
                                : 'Set due date (optional)',
                            style: AppTypography.body.copyWith(
                              color: _dueDate != null
                                  ? AppColors.textPrimary
                                  : AppColors.textSecondary,
                            ),
                          ),
                        ),
                        if (_dueDate != null)
                          GestureDetector(
                            onTap: () => setState(() => _dueDate = null),
                            child: const Icon(
                              Icons.close_rounded,
                              color: AppColors.textSecondary,
                              size: 20,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                // Save Button
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _save,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(AppSpacing.radiusLg),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 24,
                            width: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            widget.todo == null
                                ? 'Create Task'
                                : 'Save Changes',
                            style: AppTypography.bodyBold
                                .copyWith(color: Colors.white),
                          ),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _getPriorityColor(TodoPriority p) {
    switch (p) {
      case TodoPriority.high:
        return AppColors.priorityHigh;
      case TodoPriority.medium:
        return AppColors.priorityMedium;
      case TodoPriority.low:
        return AppColors.priorityLow;
    }
  }

  IconData _getPriorityIcon(TodoPriority p) {
    switch (p) {
      case TodoPriority.high:
        return Icons.keyboard_double_arrow_up_rounded;
      case TodoPriority.medium:
        return Icons.remove_rounded;
      case TodoPriority.low:
        return Icons.keyboard_double_arrow_down_rounded;
    }
  }

  Color _getStatusColor(TodoStatus s) {
    switch (s) {
      case TodoStatus.pending:
        return AppColors.statusPending;
      case TodoStatus.inProgress:
        return AppColors.statusInProgress;
      case TodoStatus.completed:
        return AppColors.statusCompleted;
    }
  }

  IconData _getStatusIcon(TodoStatus s) {
    switch (s) {
      case TodoStatus.pending:
        return Icons.radio_button_unchecked_rounded;
      case TodoStatus.inProgress:
        return Icons.timelapse_rounded;
      case TodoStatus.completed:
        return Icons.check_circle_rounded;
    }
  }
}
