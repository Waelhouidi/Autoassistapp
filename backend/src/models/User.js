/**
 * User Model
 * Firestore schema for user documents
 */
const { collections, admin } = require('../config/firebase');
const { v4: uuidv4 } = require('uuid');

/**
 * User Schema:
 * {
 *   id: string,
 *   email: string,
 *   displayName: string,
 *   photoURL: string | null,
 *   firebaseUid: string,
 *   platforms: {
 *     linkedin: { connected: boolean, accessToken?: string, refreshToken?: string },
 *     twitter: { connected: boolean, accessToken?: string, refreshToken?: string }
 *   },
 *   settings: {
 *     defaultPlatforms: string[],
 *     language: string
 *   },
 *   createdAt: timestamp,
 *   updatedAt: timestamp
 * }
 */

class UserModel {
    static collection = collections.users;

    /**
     * Create a new user
     */
    static async create(userData) {
        const id = uuidv4();
        const now = admin.firestore.FieldValue.serverTimestamp();

        const user = {
            id,
            email: userData.email,
            displayName: userData.displayName || userData.email.split('@')[0],
            photoURL: userData.photoURL || null,
            firebaseUid: userData.firebaseUid,
            platforms: {
                linkedin: { connected: false },
                twitter: { connected: false },
            },
            settings: {
                defaultPlatforms: ['linkedin'],
                language: 'en',
            },
            createdAt: now,
            updatedAt: now,
        };

        await this.collection.doc(id).set(user);
        return { ...user, createdAt: new Date(), updatedAt: new Date() };
    }

    /**
     * Find user by Firebase UID
     */
    static async findByFirebaseUid(firebaseUid) {
        const snapshot = await this.collection
            .where('firebaseUid', '==', firebaseUid)
            .limit(1)
            .get();

        if (snapshot.empty) return null;
        return snapshot.docs[0].data();
    }

    /**
     * Find user by ID
     */
    static async findById(id) {
        const doc = await this.collection.doc(id).get();
        if (!doc.exists) return null;
        return doc.data();
    }

    /**
     * Find user by email
     */
    static async findByEmail(email) {
        const snapshot = await this.collection
            .where('email', '==', email)
            .limit(1)
            .get();

        if (snapshot.empty) return null;
        return snapshot.docs[0].data();
    }

    /**
     * Update user
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
     * Update platform connection
     */
    static async updatePlatform(userId, platform, connectionData) {
        const updateData = {
            [`platforms.${platform}`]: connectionData,
            updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        };

        await this.collection.doc(userId).update(updateData);
        return this.findById(userId);
    }

    /**
     * Delete user
     */
    static async delete(id) {
        await this.collection.doc(id).delete();
        return true;
    }
}

module.exports = UserModel;
