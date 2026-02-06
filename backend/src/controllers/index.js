/**
 * Controllers Index
 * Export all controllers from a single entry point
 */
const authController = require('./authController');
const postController = require('./postController');
const platformController = require('./platformController');
const todoController = require('./todoController');

module.exports = {
    authController,
    postController,
    platformController,
    todoController,
};
