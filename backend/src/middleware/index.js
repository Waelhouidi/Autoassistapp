/**
 * Middleware Index
 * Export all middleware from a single entry point
 */
const { verifyToken, optionalAuth } = require('./auth');
const { ApiError, notFoundHandler, errorHandler, asyncHandler } = require('./errorHandler');
const { apiLimiter, authLimiter, enhanceLimiter, publishLimiter } = require('./rateLimiter');
const {
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
} = require('./validator');

module.exports = {
    // Auth
    verifyToken,
    optionalAuth,

    // Error handling
    ApiError,
    notFoundHandler,
    errorHandler,
    asyncHandler,

    // Rate limiting
    apiLimiter,
    authLimiter,
    enhanceLimiter,
    publishLimiter,

    // Validation
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

