/**
 * Post Model
 * Firestore schema for post documents
 */
const { collections, admin } = require('../config/firebase');
const { v4: uuidv4 } = require('uuid');

/**
 * Post Schema:
 * {
 *   id: string,
 *   userId: string,
 *   originalContent: string,
 *   enhancedContent: string,
 *   platforms: string[],
 *   status: 'draft' | 'enhanced' | 'scheduled' | 'published' | 'failed',
 *   scheduledAt: timestamp | null,      // NEW: When to publish
 *   publishNow: boolean,                 // NEW: Immediate vs scheduled
 *   publishResults: {
 *     linkedin?: { success: boolean, postId?: string, error?: string },
 *     twitter?: { success: boolean, tweetId?: string, error?: string }
 *   },
 *   metadata: {
 *     characterCount: number,
 *     enhancementTime: number,
 *     model: string
 *   },
 *   createdAt: timestamp,
 *   updatedAt: timestamp,
 *   publishedAt: timestamp | null
 * }
 */

class PostModel {
    static collection = collections.posts;

    /**
     * Create a new post
     */
    static async create(postData) {
        const id = uuidv4();
        const now = admin.firestore.FieldValue.serverTimestamp();

        // Handle scheduled date
        let scheduledAt = null;
        if (postData.scheduledAt) {
            scheduledAt = admin.firestore.Timestamp.fromDate(new Date(postData.scheduledAt));
        }

        const post = {
            id,
            userId: postData.userId,
            originalContent: postData.originalContent,
            enhancedContent: postData.enhancedContent || null,
            platforms: postData.platforms || [],
            status: 'draft',
            scheduledAt: scheduledAt,
            publishNow: postData.publishNow !== false, // Default to true (immediate)
            publishResults: {},
            metadata: {
                characterCount: postData.originalContent?.length || 0,
                enhancementTime: null,
                model: null,
            },
            createdAt: now,
            updatedAt: now,
            publishedAt: null,
        };

        await this.collection.doc(id).set(post);
        return { ...post, createdAt: new Date(), updatedAt: new Date() };
    }

    /**
     * Find post by ID
     */
    static async findById(id) {
        const doc = await this.collection.doc(id).get();
        if (!doc.exists) return null;
        return doc.data();
    }

    /**
     * Find posts by user ID
     */
    static async findByUserId(userId, limit = 20, startAfter = null) {
        let query = this.collection
            .where('userId', '==', userId)
            .orderBy('createdAt', 'desc')
            .limit(limit);

        if (startAfter) {
            query = query.startAfter(startAfter);
        }

        const snapshot = await query.get();
        return snapshot.docs.map(doc => doc.data());
    }

    /**
     * Find scheduled posts ready to publish
     * Returns posts where scheduledAt <= now and status is 'scheduled'
     */
    static async findScheduledReadyToPublish() {
        const now = admin.firestore.Timestamp.now();

        const snapshot = await this.collection
            .where('status', '==', 'scheduled')
            .where('scheduledAt', '<=', now)
            .get();

        return snapshot.docs.map(doc => doc.data());
    }

    /**
     * Find user's scheduled posts
     */
    static async findScheduledByUserId(userId) {
        const snapshot = await this.collection
            .where('userId', '==', userId)
            .where('status', '==', 'scheduled')
            .orderBy('scheduledAt', 'asc')
            .get();

        return snapshot.docs.map(doc => doc.data());
    }

    /**
     * Update post with enhanced content
     */
    static async updateEnhanced(id, enhancedContent, metadata = {}) {
        const updateData = {
            enhancedContent,
            status: 'enhanced',
            'metadata.enhancementTime': metadata.enhancementTime || null,
            'metadata.model': metadata.model || 'gemini',
            updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        };

        await this.collection.doc(id).update(updateData);
        return this.findById(id);
    }

    /**
     * Update post to scheduled status
     */
    static async updateScheduled(id, scheduledAt) {
        const updateData = {
            status: 'scheduled',
            scheduledAt: admin.firestore.Timestamp.fromDate(new Date(scheduledAt)),
            publishNow: false,
            updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        };

        await this.collection.doc(id).update(updateData);
        return this.findById(id);
    }

    /**
     * Update post status to published
     */
    static async updatePublished(id, publishResults) {
        const allSuccessful = Object.values(publishResults).every(r => r.success);

        const updateData = {
            status: allSuccessful ? 'published' : 'failed',
            publishResults,
            publishedAt: admin.firestore.FieldValue.serverTimestamp(),
            updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        };

        await this.collection.doc(id).update(updateData);
        return this.findById(id);
    }

    /**
     * Update post
     */
    static async update(id, updates) {
        const updateData = {
            ...updates,
            updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        };

        await this.collection.doc(id).update(updateData);
        return this.findById(id);
    }

    /**
     * Delete post
     */
    static async delete(id) {
        await this.collection.doc(id).delete();
        return true;
    }

    /**
     * Get user's post statistics
     */
    static async getStatsByUserId(userId) {
        const snapshot = await this.collection
            .where('userId', '==', userId)
            .get();

        const stats = {
            total: 0,
            draft: 0,
            enhanced: 0,
            scheduled: 0,
            published: 0,
            failed: 0,
        };

        snapshot.docs.forEach(doc => {
            const post = doc.data();
            stats.total++;
            stats[post.status] = (stats[post.status] || 0) + 1;
        });

        return stats;
    }
}

module.exports = PostModel;
