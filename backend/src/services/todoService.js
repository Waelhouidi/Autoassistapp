/**
 * Todo Service
 * Business logic for todo operations
 */
const TodoModel = require('../models/Todo');
const logger = require('../config/logger');

/**
 * Create a new todo
 */
const createTodo = async (userId, todoData) => {
    logger.info('Creating new todo', { userId, title: todoData.title });

    const todo = await TodoModel.create({
        userId,
        title: todoData.title,
        description: todoData.description,
        priority: todoData.priority,
        dueDate: todoData.dueDate,
    });

    logger.info('Todo created successfully', { todoId: todo.id, userId });
    return todo;
};

/**
 * Get all todos for a user with optional filters
 */
const getTodos = async (userId, filters = {}) => {
    logger.info('Fetching todos', { userId, filters });

    const todos = await TodoModel.findByUserId(userId, {
        limit: filters.limit || 50,
        status: filters.status,
        priority: filters.priority,
        sortBy: filters.sortBy || 'createdAt',
        sortOrder: filters.sortOrder || 'desc',
    });

    logger.info('Todos fetched', { userId, count: todos.length });
    return todos;
};

/**
 * Get a single todo by ID
 */
const getTodoById = async (todoId, userId) => {
    logger.info('Fetching todo', { todoId, userId });

    const todo = await TodoModel.findById(todoId);

    if (!todo) {
        logger.warn('Todo not found', { todoId });
        return null;
    }

    // Verify ownership
    if (todo.userId !== userId) {
        logger.warn('Unauthorized todo access attempt', { todoId, userId });
        return null;
    }

    return todo;
};

/**
 * Update a todo
 */
const updateTodo = async (todoId, userId, updates) => {
    logger.info('Updating todo', { todoId, userId, updates: Object.keys(updates) });

    // Verify ownership first
    const existing = await getTodoById(todoId, userId);
    if (!existing) {
        return null;
    }

    const allowedUpdates = ['title', 'description', 'status', 'priority', 'dueDate'];
    const filteredUpdates = {};

    for (const key of allowedUpdates) {
        if (updates[key] !== undefined) {
            filteredUpdates[key] = updates[key];
        }
    }

    const updated = await TodoModel.update(todoId, filteredUpdates);
    logger.info('Todo updated successfully', { todoId });
    return updated;
};

/**
 * Toggle todo status
 */
const toggleTodoStatus = async (todoId, userId) => {
    logger.info('Toggling todo status', { todoId, userId });

    // Verify ownership first
    const existing = await getTodoById(todoId, userId);
    if (!existing) {
        return null;
    }

    const updated = await TodoModel.toggleStatus(todoId);
    logger.info('Todo status toggled', { todoId, newStatus: updated?.status });
    return updated;
};

/**
 * Delete a todo
 */
const deleteTodo = async (todoId, userId) => {
    logger.info('Deleting todo', { todoId, userId });

    // Verify ownership first
    const existing = await getTodoById(todoId, userId);
    if (!existing) {
        return false;
    }

    await TodoModel.delete(todoId);
    logger.info('Todo deleted successfully', { todoId });
    return true;
};

/**
 * Get todo statistics for a user
 */
const getStats = async (userId) => {
    logger.info('Fetching todo stats', { userId });
    return TodoModel.getStatsByUserId(userId);
};

module.exports = {
    createTodo,
    getTodos,
    getTodoById,
    updateTodo,
    toggleTodoStatus,
    deleteTodo,
    getStats,
};
