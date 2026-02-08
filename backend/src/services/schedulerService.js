/**
 * Scheduler Service
 * Handles scheduled post publishing via n8n automation
 */
const axios = require('axios');
const env = require('../config/env');
const logger = require('../config/logger');
const { PostModel, PlatformModel } = require('../models');

class SchedulerService {
    constructor() {
        this.publishWebhook = env.N8N_PUBLISH_WEBHOOK;
        this.enhanceWebhook = env.N8N_ENHANCE_WEBHOOK;
    }

    /**
     * Schedule a post for later publishing
     * @param {string} userId - User ID
     * @param {string} postId - Post ID
     * @param {string} scheduledAt - ISO date string for when to publish
     * @param {string[]} platforms - Platforms to publish to
     */
    async schedulePost(userId, postId, scheduledAt, platforms) {
        logger.info('Scheduling post', { userId, postId, scheduledAt, platforms });

        // Update post with scheduled status
        const post = await PostModel.updateScheduled(postId, scheduledAt);

        // Optionally notify n8n about the scheduled post (for cron-based polling)
        try {
            await axios.post(this.publishWebhook, {
                action: 'schedule',
                post_id: postId,
                user_id: userId,
                scheduled_at: scheduledAt,
                platforms: platforms,
                timestamp: new Date().toISOString(),
            }, {
                headers: { 'Content-Type': 'application/json' },
                timeout: 10000,
            });
        } catch (error) {
            // Non-critical: n8n will poll for scheduled posts
            logger.warn('Could not notify n8n about scheduled post', { error: error.message });
        }

        return post;
    }

    /**
     * Get user's scheduled posts
     */
    async getScheduledPosts(userId) {
        return PostModel.findScheduledByUserId(userId);
    }

    /**
     * Cancel a scheduled post
     */
    async cancelScheduledPost(userId, postId) {
        const post = await PostModel.findById(postId);

        if (!post || post.userId !== userId) {
            throw new Error('Post not found');
        }

        if (post.status !== 'scheduled') {
            throw new Error('Post is not scheduled');
        }

        await PostModel.update(postId, {
            status: 'draft',
            scheduledAt: null,
            publishNow: true,
        });

        return { success: true, message: 'Schedule cancelled' };
    }

    /**
     * Process scheduled posts that are due (called by n8n or cron)
     * This endpoint will be called by n8n to check for posts ready to publish
     */
    async processScheduledPosts() {
        const posts = await PostModel.findScheduledReadyToPublish();

        logger.info(`Found ${posts.length} scheduled posts ready to publish`);

        const results = [];

        for (const post of posts) {
            try {
                // Get user's platform connections
                const platforms = await PlatformModel.getConnectedPlatforms(post.userId);
                const connectedPlatformNames = platforms.map(p => p.name);

                // Filter to only platforms user has connected
                const targetPlatforms = post.platforms.filter(p =>
                    connectedPlatformNames.includes(p.toLowerCase())
                );

                if (targetPlatforms.length === 0) {
                    logger.warn('No connected platforms for scheduled post', { postId: post.id });
                    await PostModel.update(post.id, {
                        status: 'failed',
                        publishResults: { error: 'No connected platforms' }
                    });
                    continue;
                }

                // Trigger publish via n8n webhook
                const publishResult = await this.triggerN8nPublish(
                    post.userId,
                    post.id,
                    post.enhancedContent || post.originalContent,
                    targetPlatforms,
                    platforms // Pass platform credentials
                );

                results.push({
                    postId: post.id,
                    success: true,
                    result: publishResult,
                });
            } catch (error) {
                logger.error('Failed to process scheduled post', {
                    postId: post.id,
                    error: error.message
                });

                await PostModel.update(post.id, {
                    status: 'failed',
                    publishResults: { error: error.message }
                });

                results.push({
                    postId: post.id,
                    success: false,
                    error: error.message,
                });
            }
        }

        return results;
    }

    /**
     * Trigger n8n workflow to publish content
     * Sends user's platform credentials to n8n for publishing
     */
    async triggerN8nPublish(userId, postId, content, platforms, platformCredentials) {
        // Build credentials object for n8n
        const credentials = {};

        for (const platform of platformCredentials) {
            credentials[platform.name] = {
                accessToken: platform.credentials?.accessToken,
                refreshToken: platform.credentials?.refreshToken,
                profileId: platform.profile?.id,
                profileName: platform.profile?.name,
            };
        }

        const payload = {
            action: 'publish',
            post_id: postId,
            user_id: userId,
            content: content,
            platforms: platforms.map(p => p.toLowerCase()),
            credentials: credentials,
            timestamp: new Date().toISOString(),
        };

        logger.info('Triggering n8n publish workflow', {
            userId,
            postId,
            platforms,
        });

        const response = await axios.post(this.publishWebhook, payload, {
            headers: { 'Content-Type': 'application/json' },
            timeout: 60000, // 60 seconds for publishing
        });

        // Update post status based on n8n response
        if (response.data && response.data.success) {
            await PostModel.updatePublished(postId, response.data.results || {});
        }

        return response.data;
    }

    /**
     * Reschedule a post
     */
    async reschedulePost(userId, postId, newScheduledAt) {
        const post = await PostModel.findById(postId);

        if (!post || post.userId !== userId) {
            throw new Error('Post not found');
        }

        return this.schedulePost(userId, postId, newScheduledAt, post.platforms);
    }
}

module.exports = new SchedulerService();
