/**
 * Authentication Middleware
 * Verify Firebase ID tokens for protected routes
 */
const { auth } = require('../config/firebase');
const { UserModel } = require('../models');
const logger = require('../config/logger');

/**
 * Verify Firebase ID Token
 * Attaches user to request object
 */
const verifyToken = async (req, res, next) => {
    try {
        const authHeader = req.headers.authorization;

        if (!authHeader || !authHeader.startsWith('Bearer ')) {
            return res.status(401).json({
                success: false,
                error: 'Unauthorized',
                message: 'No token provided. Please include Authorization header with Bearer token.',
            });
        }

        const idToken = authHeader.split('Bearer ')[1];

        // Verify the ID token
        const decodedToken = await auth.verifyIdToken(idToken);

        // Get or create user in Firestore
        let user = await UserModel.findByFirebaseUid(decodedToken.uid);

        if (!user) {
            // Create user on first login
            user = await UserModel.create({
                firebaseUid: decodedToken.uid,
                email: decodedToken.email,
                displayName: decodedToken.name || decodedToken.email?.split('@')[0],
                photoURL: decodedToken.picture || null,
            });
            logger.info(`New user created: ${user.email}`);
        }

        // Attach user and decoded token to request
        req.user = user;
        req.firebaseUser = decodedToken;

        next();
    } catch (error) {
        logger.error('Token verification failed:', error);

        if (error.code === 'auth/id-token-expired') {
            return res.status(401).json({
                success: false,
                error: 'TokenExpired',
                message: 'Token has expired. Please refresh your token.',
            });
        }

        if (error.code === 'auth/argument-error') {
            return res.status(401).json({
                success: false,
                error: 'InvalidToken',
                message: 'Invalid token format.',
            });
        }

        return res.status(401).json({
            success: false,
            error: 'Unauthorized',
            message: 'Invalid or expired token.',
        });
    }
};

/**
 * Optional authentication
 * Continues without user if token not provided
 */
const optionalAuth = async (req, res, next) => {
    const authHeader = req.headers.authorization;

    if (!authHeader || !authHeader.startsWith('Bearer ')) {
        req.user = null;
        return next();
    }

    return verifyToken(req, res, next);
};

module.exports = {
    verifyToken,
    optionalAuth,
};
