/**
 * Post Routes
 * Content enhancement, scheduling, and publishing endpoints
 */
const express = require('express');
const router = express.Router();
const { postController } = require('../controllers');
const {
    verifyToken,
    enhanceLimiter,
    publishLimiter,
    validate,
    enhanceContentRules,
    publishContentRules,
    getPostsRules,
    postIdRules,
} = require('../middleware');

/**
 * @route   POST /api/posts/enhance
 * @desc    Enhance content with AI
 * @access  Private
 */
router.post(
    '/enhance',
    verifyToken,
    enhanceLimiter,
    enhanceContentRules,
    validate,
    postController.enhanceContent
);

/**
 * @route   POST /api/posts/publish
 * @desc    Publish content to platforms (immediate or scheduled)
 * @access  Private
 */
router.post(
    '/publish',
    verifyToken,
    publishLimiter,
    publishContentRules,
    validate,
    postController.publishContent
);

/**
 * @route   POST /api/posts/schedule
 * @desc    Schedule a post for later publishing
 * @access  Private
 */
router.post(
    '/schedule',
    verifyToken,
    postController.schedulePost
);

/**
 * @route   GET /api/posts/scheduled
 * @desc    Get all scheduled posts for the user
 * @access  Private
 */
router.get(
    '/scheduled',
    verifyToken,
    postController.getScheduledPosts
);

/**
 * @route   DELETE /api/posts/schedule/:id
 * @desc    Cancel a scheduled post
 * @access  Private
 */
router.delete(
    '/schedule/:id',
    verifyToken,
    postController.cancelScheduledPost
);

/**
 * @route   GET /api/posts/stats
 * @desc    Get post statistics
 * @access  Private
 */
router.get('/stats', verifyToken, postController.getStats);

/**
 * @route   GET /api/posts
 * @desc    Get post history
 * @access  Private
 */
router.get(
    '/',
    verifyToken,
    getPostsRules,
    validate,
    postController.getPosts
);

/**
 * @route   GET /api/posts/:id
 * @desc    Get single post
 * @access  Private
 */
router.get(
    '/:id',
    verifyToken,
    postIdRules,
    validate,
    postController.getPost
);

/**
 * @route   DELETE /api/posts/:id
 * @desc    Delete a post
 * @access  Private
 */
router.delete(
    '/:id',
    verifyToken,
    postIdRules,
    validate,
    postController.deletePost
);

module.exports = router;
