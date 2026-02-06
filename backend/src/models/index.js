/**
 * Models Index
 * Export all models from a single entry point
 */
const UserModel = require('./User');
const PostModel = require('./Post');
const PlatformModel = require('./Platform');
const TodoModel = require('./Todo');

module.exports = {
    UserModel,
    PostModel,
    PlatformModel,
    TodoModel,
};
