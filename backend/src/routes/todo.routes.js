/**
 * Todo Routes
 * Define todo API endpoints
 */
const express = require('express');
const router = express.Router();
const todoController = require('../controllers/todoController');
const {
    verifyToken,
    validate,
    createTodoRules,
    updateTodoRules,
    todoIdRules,
    getTodosRules,
} = require('../middleware');

// All todo routes require authentication
router.use(verifyToken);

/**
 * @route   GET /api/todos/stats
 * @desc    Get todo statistics
 * @access  Private
 */
router.get('/stats', todoController.getStats);

/**
 * @route   POST /api/todos
 * @desc    Create a new todo
 * @access  Private
 */
router.post('/', createTodoRules, validate, todoController.createTodo);

/**
 * @route   GET /api/todos
 * @desc    Get all todos for authenticated user
 * @access  Private
 */
router.get('/', getTodosRules, validate, todoController.getTodos);

/**
 * @route   GET /api/todos/:id
 * @desc    Get a single todo
 * @access  Private
 */
router.get('/:id', todoIdRules, validate, todoController.getTodo);

/**
 * @route   PUT /api/todos/:id
 * @desc    Update a todo
 * @access  Private
 */
router.put('/:id', todoIdRules, updateTodoRules, validate, todoController.updateTodo);

/**
 * @route   PATCH /api/todos/:id/toggle
 * @desc    Toggle todo status
 * @access  Private
 */
router.patch('/:id/toggle', todoIdRules, validate, todoController.toggleTodoStatus);

/**
 * @route   DELETE /api/todos/:id
 * @desc    Delete a todo
 * @access  Private
 */
router.delete('/:id', todoIdRules, validate, todoController.deleteTodo);

module.exports = router;
