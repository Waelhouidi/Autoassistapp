/**
 * Todo Controller
 * Handles todo CRUD endpoints
 */
const todoService = require('../services/todoService');
const { successResponse, createdResponse } = require('../utils/apiResponse');
const { asyncHandler, ApiError } = require('../middleware');
const logger = require('../config/logger');

/**
 * Create a new todo
 * POST /api/todos
 */
const createTodo = asyncHandler(async (req, res) => {
    const { title, description, priority, dueDate } = req.body;
    const userId = req.user.id;

    logger.info('Create todo request', { userId, title });

    const todo = await todoService.createTodo(userId, {
        title,
        description,
        priority,
        dueDate,
    });

    return createdResponse(res, todo, 'Todo created successfully');
});

/**
 * Get all todos for the authenticated user
 * GET /api/todos
 */
const getTodos = asyncHandler(async (req, res) => {
    const { limit, status, priority, sortBy, sortOrder } = req.query;
    const userId = req.user.id;

    const todos = await todoService.getTodos(userId, {
        limit: parseInt(limit, 10) || 50,
        status,
        priority,
        sortBy,
        sortOrder,
    });

    return successResponse(res, todos, 'Todos retrieved successfully');
});

/**
 * Get a single todo
 * GET /api/todos/:id
 */
const getTodo = asyncHandler(async (req, res) => {
    const { id } = req.params;
    const userId = req.user.id;

    const todo = await todoService.getTodoById(id, userId);

    if (!todo) {
        throw ApiError.notFound('Todo not found');
    }

    return successResponse(res, todo, 'Todo retrieved successfully');
});

/**
 * Update a todo
 * PUT /api/todos/:id
 */
const updateTodo = asyncHandler(async (req, res) => {
    const { id } = req.params;
    const userId = req.user.id;
    const updates = req.body;

    const todo = await todoService.updateTodo(id, userId, updates);

    if (!todo) {
        throw ApiError.notFound('Todo not found');
    }

    return successResponse(res, todo, 'Todo updated successfully');
});

/**
 * Toggle todo status
 * PATCH /api/todos/:id/toggle
 */
const toggleTodoStatus = asyncHandler(async (req, res) => {
    const { id } = req.params;
    const userId = req.user.id;

    const todo = await todoService.toggleTodoStatus(id, userId);

    if (!todo) {
        throw ApiError.notFound('Todo not found');
    }

    return successResponse(res, todo, 'Todo status toggled successfully');
});

/**
 * Delete a todo
 * DELETE /api/todos/:id
 */
const deleteTodo = asyncHandler(async (req, res) => {
    const { id } = req.params;
    const userId = req.user.id;

    const deleted = await todoService.deleteTodo(id, userId);

    if (!deleted) {
        throw ApiError.notFound('Todo not found');
    }

    return successResponse(res, null, 'Todo deleted successfully');
});

/**
 * Get todo statistics
 * GET /api/todos/stats
 */
const getStats = asyncHandler(async (req, res) => {
    const userId = req.user.id;

    const stats = await todoService.getStats(userId);

    return successResponse(res, stats, 'Statistics retrieved successfully');
});

module.exports = {
    createTodo,
    getTodos,
    getTodo,
    updateTodo,
    toggleTodoStatus,
    deleteTodo,
    getStats,
};
