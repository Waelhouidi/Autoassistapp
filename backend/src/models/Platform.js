/**
 * Platform Model
 * Firestore schema for platform connections
 */
const { collections, admin } = require('../config/firebase');
const { v4: uuidv4 } = require('uuid');

/**
 * Platform Schema:
 * {
 *   id: string,
 *   userId: string,
 *   name: 'linkedin' | 'twitter',
 *   connected: boolean,
 *   credentials: {
 *     accessToken: string (encrypted),
 *     refreshToken: string (encrypted),
 *     expiresAt: timestamp
 *   },
 *   profile: {
 *     id: string,
 *     name: string,
 *     username: string,
 *     avatarUrl: string
 *   },
 *   createdAt: timestamp,
 *   updatedAt: timestamp
 * }
 */

class PlatformModel {
    static collection = collections.platforms;

    /**
     * Create or update platform connection
     */
    static async upsert(userId, platformName, connectionData) {
        // Check if platform connection exists
        const existing = await this.findByUserAndPlatform(userId, platformName);

        if (existing) {
            return this.update(existing.id, connectionData);
        }

        const id = uuidv4();
        const now = admin.firestore.FieldValue.serverTimestamp();

        const platform = {
            id,
            userId,
            name: platformName.toLowerCase(),
            connected: true,
            credentials: {
                accessToken: connectionData.accessToken || null,
                refreshToken: connectionData.refreshToken || null,
                expiresAt: connectionData.expiresAt || null,
                email: connectionData.email || null,
                password: connectionData.password || null, // In production, this should be encrypted
            },
            profile: {
                id: connectionData.profileId || null,
                name: connectionData.profileName || null,
                username: connectionData.username || connectionData.email || null,
                avatarUrl: connectionData.avatarUrl || null,
            },
            createdAt: now,
            updatedAt: now,
        };

        await this.collection.doc(id).set(platform);
        return { ...platform, createdAt: new Date(), updatedAt: new Date() };
    }

    /**
     * Find platform by ID
     */
    static async findById(id) {
        const doc = await this.collection.doc(id).get();
        if (!doc.exists) return null;
        return doc.data();
    }

    /**
     * Find platform by user ID and platform name
     */
    static async findByUserAndPlatform(userId, platformName) {
        const snapshot = await this.collection
            .where('userId', '==', userId)
            .where('name', '==', platformName.toLowerCase())
            .limit(1)
            .get();

        if (snapshot.empty) return null;
        return snapshot.docs[0].data();
    }

    /**
     * Find all platforms for a user
     */
    static async findByUserId(userId) {
        const snapshot = await this.collection
            .where('userId', '==', userId)
            .get();

        return snapshot.docs.map(doc => doc.data());
    }

    /**
     * Get connected platforms for a user
     */
    static async getConnectedPlatforms(userId) {
        const snapshot = await this.collection
            .where('userId', '==', userId)
            .where('connected', '==', true)
            .get();

        return snapshot.docs.map(doc => doc.data());
    }

    /**
     * Update platform
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
     * Disconnect platform
     */
    static async disconnect(userId, platformName) {
        const platform = await this.findByUserAndPlatform(userId, platformName);
        if (!platform) return null;

        await this.collection.doc(platform.id).update({
            connected: false,
            'credentials.accessToken': null,
            'credentials.refreshToken': null,
            updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        });

        return this.findById(platform.id);
    }

    /**
     * Delete platform connection
     */
    static async delete(id) {
        await this.collection.doc(id).delete();
        return true;
    }
}

module.exports = PlatformModel;
