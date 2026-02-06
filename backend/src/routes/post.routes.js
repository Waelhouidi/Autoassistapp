/**
 * Post Routes
 * Content enhancement and publishing endpoints
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
 * @desc    Publish content to platforms
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
