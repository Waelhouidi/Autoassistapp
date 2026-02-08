/**
 * Post Controller
 * Handles post enhancement, scheduling, and publishing endpoints
 */
const { postService } = require('../services');
const schedulerService = require('../services/schedulerService');
const { successResponse, createdResponse } = require('../utils/apiResponse');
const { asyncHandler, ApiError } = require('../middleware');
const logger = require('../config/logger');

/**
 * Enhance content with AI
 * POST /api/posts/enhance
 */
const enhanceContent = asyncHandler(async (req, res) => {
    const { content, platforms, scheduledAt } = req.body;
    const userId = req.user.id;

    logger.info('Enhance request received', {
        userId,
        platforms,
        contentLength: content.length,
        scheduledAt: scheduledAt || 'immediate',
    });

    const result = await postService.enhancePost(userId, content, platforms, { scheduledAt });

    return createdResponse(res, {
        postId: result.id,
        originalContent: result.originalContent,
        improvedContent: result.enhancedContent, // Keep compatibility with Flutter app
        enhanced_content: result.enhancedContent,
        platforms: result.platforms,
        status: result.status,
        scheduledAt: result.scheduledAt,
        metadata: result.metadata,
    }, 'Content enhanced successfully');
});

/**
 * Publish content to platforms
 * POST /api/posts/publish
 * Supports both immediate and scheduled publishing
 */
const publishContent = asyncHandler(async (req, res) => {
    const { postId, content, platforms, scheduledAt, publishNow = true } = req.body;
    const userId = req.user.id;

    // Determine content to publish
    let contentToPublish = content;

    if (postId && !content) {
        // Fetch content from existing post
        const post = await postService.getPost(postId, userId);
        if (!post) {
            throw ApiError.notFound('Post not found');
        }
        contentToPublish = post.enhancedContent || post.originalContent;
    }

    if (!contentToPublish) {
        throw ApiError.badRequest('No content provided for publishing');
    }

    // Handle scheduled publishing
    if (scheduledAt && !publishNow) {
        logger.info('Scheduling post for later', {
            userId,
            postId,
            scheduledAt,
            platforms,
        });

        const scheduledPost = await schedulerService.schedulePost(
            userId,
            postId,
            scheduledAt,
            platforms
        );

        return successResponse(res, {
            message: 'Post scheduled successfully',
            postId: scheduledPost.id,
            scheduledAt: scheduledAt,
            platforms: platforms,
        }, 'Content scheduled for publishing');
    }

    // Immediate publishing
    const result = await postService.publishPost(
        userId,
        postId,
        contentToPublish,
        platforms
    );

    return successResponse(res, {
        message: result.message,
        results: result.results,
        postId,
    }, 'Content published successfully');
});

/**
 * Schedule a post for later
 * POST /api/posts/schedule
 */
const schedulePost = asyncHandler(async (req, res) => {
    const { postId, scheduledAt, platforms } = req.body;
    const userId = req.user.id;

    if (!postId) {
        throw ApiError.badRequest('Post ID is required');
    }

    if (!scheduledAt) {
        throw ApiError.badRequest('Scheduled date/time is required');
    }

    // Validate scheduled date is in the future
    const scheduledDate = new Date(scheduledAt);
    if (scheduledDate <= new Date()) {
        throw ApiError.badRequest('Scheduled date must be in the future');
    }

    const result = await schedulerService.schedulePost(
        userId,
        postId,
        scheduledAt,
        platforms || []
    );

    return successResponse(res, {
        postId: result.id,
        scheduledAt: scheduledAt,
        status: 'scheduled',
    }, 'Post scheduled successfully');
});

/**
 * Get user's scheduled posts
 * GET /api/posts/scheduled
 */
const getScheduledPosts = asyncHandler(async (req, res) => {
    const userId = req.user.id;

    const posts = await schedulerService.getScheduledPosts(userId);

    return successResponse(res, posts, 'Scheduled posts retrieved successfully');
});

/**
 * Cancel a scheduled post
 * DELETE /api/posts/schedule/:id
 */
const cancelScheduledPost = asyncHandler(async (req, res) => {
    const { id } = req.params;
    const userId = req.user.id;

    await schedulerService.cancelScheduledPost(userId, id);

    return successResponse(res, null, 'Schedule cancelled successfully');
});

/**
 * Get post history
 * GET /api/posts
 */
const getPosts = asyncHandler(async (req, res) => {
    const { limit, status } = req.query;
    const userId = req.user.id;

    const posts = await postService.getPostHistory(userId, {
        limit: parseInt(limit, 10) || 20,
        status,
    });

    return successResponse(res, posts, 'Posts retrieved successfully');
});

/**
 * Get single post
 * GET /api/posts/:id
 */
const getPost = asyncHandler(async (req, res) => {
    const { id } = req.params;
    const userId = req.user.id;

    const post = await postService.getPost(id, userId);

    if (!post) {
        throw ApiError.notFound('Post not found');
    }

    return successResponse(res, post, 'Post retrieved successfully');
});

/**
 * Delete post
 * DELETE /api/posts/:id
 */
const deletePost = asyncHandler(async (req, res) => {
    const { id } = req.params;
    const userId = req.user.id;

    const deleted = await postService.deletePost(id, userId);

    if (!deleted) {
        throw ApiError.notFound('Post not found');
    }

    return successResponse(res, null, 'Post deleted successfully');
});

/**
 * Get post statistics
 * GET /api/posts/stats
 */
const getStats = asyncHandler(async (req, res) => {
    const userId = req.user.id;

    const stats = await postService.getStats(userId);

    return successResponse(res, stats, 'Statistics retrieved successfully');
});

module.exports = {
    enhanceContent,
    publishContent,
    schedulePost,
    getScheduledPosts,
    cancelScheduledPost,
    getPosts,
    getPost,
    deletePost,
    getStats,
};
