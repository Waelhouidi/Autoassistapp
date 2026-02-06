/**
 * Request Validator Middleware
 * Validate and sanitize incoming requests
 */
const { body, param, query, validationResult } = require('express-validator');
const { ApiError } = require('./errorHandler');

/**
 * Process validation results
 */
const validate = (req, res, next) => {
    const errors = validationResult(req);

    if (!errors.isEmpty()) {
        const formattedErrors = errors.array().map(err => ({
            field: err.path,
            message: err.msg,
            value: err.value,
        }));

        throw ApiError.badRequest('Validation failed', formattedErrors);
    }

    next();
};

/**
 * Validation rules for post enhancement
 */
const enhanceContentRules = [
    body('content')
        .trim()
        .notEmpty()
        .withMessage('Content is required')
        .isLength({ min: 10, max: 5000 })
        .withMessage('Content must be between 10 and 5000 characters'),

    body('platforms')
        .isArray({ min: 1 })
        .withMessage('At least one platform must be selected'),

    body('platforms.*')
        .isIn(['linkedin', 'twitter', 'LinkedIn', 'Twitter'])
        .withMessage('Invalid platform. Supported: linkedin, twitter'),
];

/**
 * Validation rules for publishing
 */
const publishContentRules = [
    body('postId')
        .optional()
        .isUUID()
        .withMessage('Invalid post ID format'),

    body('content')
        .trim()
        .notEmpty()
        .withMessage('Content is required')
        .isLength({ min: 1, max: 5000 })
        .withMessage('Content must be between 1 and 5000 characters'),

    body('platforms')
        .isArray({ min: 1 })
        .withMessage('At least one platform must be selected'),

    body('platforms.*')
        .isIn(['linkedin', 'twitter', 'LinkedIn', 'Twitter'])
        .withMessage('Invalid platform'),
];

/**
 * Validation rules for platform connection
 */
const connectPlatformRules = [
    param('platform')
        .isIn(['linkedin', 'twitter'])
        .withMessage('Invalid platform. Supported: linkedin, twitter'),

    body('accessToken')
        .notEmpty()
        .withMessage('Access token is required'),

    body('refreshToken')
        .optional()
        .isString(),
];

/**
 * Validation rules for getting post history
 */
const getPostsRules = [
    query('limit')
        .optional()
        .isInt({ min: 1, max: 100 })
        .withMessage('Limit must be between 1 and 100'),

    query('status')
        .optional()
        .isIn(['draft', 'enhanced', 'published', 'failed'])
        .withMessage('Invalid status'),
];

/**
 * Validation rules for post ID parameter
 */
const postIdRules = [
    param('id')
        .isUUID()
        .withMessage('Invalid post ID format'),
];

/**
 * Validation rules for creating a todo
 */
const createTodoRules = [
    body('title')
        .trim()
        .notEmpty()
        .withMessage('Title is required')
        .isLength({ min: 1, max: 200 })
        .withMessage('Title must be between 1 and 200 characters'),

    body('description')
        .optional()
        .trim()
        .isLength({ max: 1000 })
        .withMessage('Description must be at most 1000 characters'),

    body('priority')
        .optional()
        .isIn(['low', 'medium', 'high'])
        .withMessage('Priority must be low, medium, or high'),

    body('dueDate')
        .optional()
        .isISO8601()
        .withMessage('Due date must be a valid ISO 8601 date'),
];

/**
 * Validation rules for updating a todo
 */
const updateTodoRules = [
    body('title')
        .optional()
        .trim()
        .isLength({ min: 1, max: 200 })
        .withMessage('Title must be between 1 and 200 characters'),

    body('description')
        .optional()
        .trim()
        .isLength({ max: 1000 })
        .withMessage('Description must be at most 1000 characters'),

    body('status')
        .optional()
        .isIn(['pending', 'in_progress', 'completed'])
        .withMessage('Status must be pending, in_progress, or completed'),

    body('priority')
        .optional()
        .isIn(['low', 'medium', 'high'])
        .withMessage('Priority must be low, medium, or high'),

    body('dueDate')
        .optional()
        .isISO8601()
        .withMessage('Due date must be a valid ISO 8601 date'),
];

/**
 * Validation rules for todo ID parameter
 */
const todoIdRules = [
    param('id')
        .isUUID()
        .withMessage('Invalid todo ID format'),
];

/**
 * Validation rules for getting todos with filters
 */
const getTodosRules = [
    query('limit')
        .optional()
        .isInt({ min: 1, max: 100 })
        .withMessage('Limit must be between 1 and 100'),

    query('status')
        .optional()
        .isIn(['pending', 'in_progress', 'completed'])
        .withMessage('Invalid status'),

    query('priority')
        .optional()
        .isIn(['low', 'medium', 'high'])
        .withMessage('Invalid priority'),

    query('sortBy')
        .optional()
        .isIn(['createdAt', 'updatedAt', 'dueDate', 'priority'])
        .withMessage('Invalid sort field'),

    query('sortOrder')
        .optional()
        .isIn(['asc', 'desc'])
        .withMessage('Sort order must be asc or desc'),
];

module.exports = {
    validate,
    enhanceContentRules,
    publishContentRules,
    connectPlatformRules,
    getPostsRules,
    postIdRules,
    createTodoRules,
    updateTodoRules,
    todoIdRules,
    getTodosRules,
};
