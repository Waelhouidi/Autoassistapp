/**
 * Auth Controller
 * Handles authentication-related endpoints
 */
const { UserModel } = require('../models');
const { successResponse, errorResponse } = require('../utils/apiResponse');
const { asyncHandler } = require('../middleware');
const logger = require('../config/logger');
const firebase = require('../config/firebase');
const axios = require('axios');

/**
 * Register a new user
 * POST /api/auth/register
 */
const register = asyncHandler(async (req, res) => {
    const { email, password, name } = req.body;

    if (!email || !password) {
        throw new Error('Email and password are required');
    }

    try {
        // Create user in Firebase Auth
        // displayName must be a valid string - use name, or fallback to email username
        const displayName = name || email.split('@')[0];
        const userRecord = await firebase.auth.createUser({
            email,
            password,
            displayName: displayName,
        });

        // Create user in Firestore
        // Note: middleware/auth.js usually creates the user in DB on first login
        // But here we do it explicitly to return the full user object
        const newUser = await UserModel.create({
            firebaseUid: userRecord.uid,  // Changed from 'uid'
            email: userRecord.email,
            displayName: userRecord.displayName || name,  // Changed from 'name'
            photoURL: userRecord.photoURL,  // Changed from 'photoUrl'
        });

        return successResponse(res, {
            user: newUser,
            message: 'User registered successfully. Please login to get a token.'
        }, 'User registered successfully', 201);
    } catch (error) {
        if (error.code === 'auth/email-already-exists') {
            return errorResponse(res, 'Email already in use', 400);
        }
        throw error;
    }
});

/**
 * Login user (Placeholder/Proxy)
 * POST /api/auth/login
 * Note: Real login should happen on client. This is a helper for testing if API Key is available.
 */
const login = asyncHandler(async (req, res) => {
    const { email, password } = req.body;

    if (!email || !password) {
        throw new Error('Email and password are required');
    }

    const apiKey = process.env.FIREBASE_API_KEY;
    if (!apiKey) {
        return errorResponse(res, 'FIREBASE_API_KEY not configured', 501);
    }

    try {
        // Exchange password for ID token
        const response = await axios.post(
            `https://identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key=${apiKey}`,
            {
                email,
                password,
                returnSecureToken: true
            }
        );

        const { idToken, localId, refreshToken, expiresIn } = response.data;

        // Ensure user exists in our Firestore
        // (In case they were created in Firebase Console directly)
        const userSnapshot = await UserModel.findById(localId);
        if (!userSnapshot) {
            const userRecord = await firebase.auth.getUser(localId);
            await UserModel.create({
                firebaseUid: localId,  // Changed from 'uid'
                email: userRecord.email,
                displayName: userRecord.displayName,  // Changed from 'name'
                photoURL: userRecord.photoURL,  // Changed from 'photoUrl'
            });
        }

        return successResponse(res, {
            token: idToken,
            refreshToken,
            expiresIn,
            user: {
                id: localId,
                email
            }
        }, 'Login successful');

    } catch (error) {
        if (error.response && error.response.data && error.response.data.error) {
            const output = error.response.data.error;
            return errorResponse(res, output.message || 'Login failed', 401);
        }
        throw new Error('Authentication failed: ' + error.message);
    }
});

/**
 * Get current user profile
 * GET /api/auth/me
 */
const getProfile = asyncHandler(async (req, res) => {
    const user = req.user;

    // Remove sensitive data
    const safeUser = {
        id: user.id,
        email: user.email,
        displayName: user.displayName,
        photoURL: user.photoURL,
        platforms: {
            linkedin: { connected: user.platforms?.linkedin?.connected || false },
            twitter: { connected: user.platforms?.twitter?.connected || false },
        },
        settings: user.settings,
        createdAt: user.createdAt,
    };

    return successResponse(res, safeUser, 'Profile retrieved successfully');
});

/**
 * Update user profile
 * PATCH /api/auth/me
 */
const updateProfile = asyncHandler(async (req, res) => {
    const { displayName, settings } = req.body;
    const userId = req.user.id;

    const updates = {};

    if (displayName) {
        updates.displayName = displayName;
    }

    if (settings) {
        updates.settings = {
            ...req.user.settings,
            ...settings,
        };
    }

    const updatedUser = await UserModel.update(userId, updates);

    logger.info('User profile updated', { userId });

    return successResponse(res, updatedUser, 'Profile updated successfully');
});

/**
 * Verify token (for client-side token validation)
 * GET /api/auth/verify
 */
const verifyTokenEndpoint = asyncHandler(async (req, res) => {
    return successResponse(res, {
        valid: true,
        user: {
            id: req.user.id,
            email: req.user.email,
        },
    }, 'Token is valid');
});

/**
 * Delete user account
 * DELETE /api/auth/me
 */
const deleteAccount = asyncHandler(async (req, res) => {
    const userId = req.user.id;

    await UserModel.delete(userId);

    logger.info('User account deleted', { userId });

    return successResponse(res, null, 'Account deleted successfully');
});

module.exports = {
    getProfile,
    updateProfile,
    verifyTokenEndpoint,
    deleteAccount,
    register,
    login,
};