/**
 * Post Controller
 * Handles post enhancement and publishing endpoints
 */
const { postService } = require('../services');
const { successResponse, createdResponse } = require('../utils/apiResponse');
const { asyncHandler, ApiError } = require('../middleware');
const logger = require('../config/logger');

/**
 * Enhance content with AI
 * POST /api/posts/enhance
 */
const enhanceContent = asyncHandler(async (req, res) => {
    const { content, platforms } = req.body;
    const userId = req.user.id;

    logger.info('Enhance request received', {
        userId,
        platforms,
        contentLength: content.length,
    });

    const result = await postService.enhancePost(userId, content, platforms);

    return createdResponse(res, {
        postId: result.id,
        originalContent: result.originalContent,
        improvedContent: result.enhancedContent, // Keep compatibility with Flutter app
        enhanced_content: result.enhancedContent,
        platforms: result.platforms,
        status: result.status,
        metadata: result.metadata,
    }, 'Content enhanced successfully');
});

/**
 * Publish content to platforms
 * POST /api/posts/publish
 */
const publishContent = asyncHandler(async (req, res) => {
    const { postId, content, platforms } = req.body;
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
    getPosts,
    getPost,
    deletePost,
    getStats,
};
