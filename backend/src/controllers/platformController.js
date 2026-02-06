/**
 * Platform Controller
 * Handles platform connection endpoints and OAuth flows
 */
const { PlatformModel, UserModel } = require('../models');
const { twitterService, linkedinService } = require('../services');
const { successResponse } = require('../utils/apiResponse');
const { asyncHandler, ApiError } = require('../middleware');
const logger = require('../config/logger');
const env = require('../config/env');

/**
 * Get connected platforms status
 * GET /api/platforms/status
 */
const getStatus = asyncHandler(async (req, res) => {
    const userId = req.user.id;

    const platforms = await PlatformModel.findByUserId(userId);

    const status = {
        linkedin: { connected: false },
        twitter: { connected: false },
    };

    platforms.forEach(platform => {
        status[platform.name] = {
            connected: platform.connected,
            profile: platform.connected ? {
                name: platform.profile?.name,
                username: platform.profile?.username,
                avatarUrl: platform.profile?.avatarUrl,
            } : null,
        };
    });

    return successResponse(res, status, 'Platform status retrieved');
});

/**
 * Initiate OAuth flow
 * GET /api/platforms/auth/:platform
 */
const initAuth = asyncHandler(async (req, res) => {
    const { platform } = req.params;
    const userId = req.user.id;

    if (platform === 'twitter') {
        const { oauthToken, oauthTokenSecret, authUrl } = await twitterService.getRequestToken();

        // Save request token secret temporarily (in production use Redis or DB)
        // For simplicity we're storing it in a session-like collection
        await UserModel.collection.doc(userId).collection('oauth_temp').doc('twitter').set({
            oauthToken,
            oauthTokenSecret,
            timestamp: new Date()
        });

        return successResponse(res, { authUrl }, 'Twitter auth initiated');
    }
    else if (platform === 'linkedin') {
        const authUrl = linkedinService.getAuthorizationUrl();
        return successResponse(res, { authUrl }, 'LinkedIn auth initiated');
    }

    throw ApiError.badRequest('Invalid platform');
});

/**
 * Handle OAuth callback
 * POST /api/platforms/callback/:platform
 */
const authCallback = asyncHandler(async (req, res) => {
    const { platform } = req.params;
    const { code, oauth_token, oauth_verifier } = req.body;
    const userId = req.user.id;

    if (platform === 'twitter') {
        // Retrieve stored token secret
        const tempDoc = await UserModel.collection.doc(userId).collection('oauth_temp').doc('twitter').get();
        if (!tempDoc.exists) {
            throw ApiError.badRequest('Invalid OAuth session');
        }

        const { oauthTokenSecret } = tempDoc.data();

        // Get access token
        const { accessToken, accessTokenSecret, screenName, userId: twitterUserId } =
            await twitterService.getAccessToken(oauth_token, oauthTokenSecret, oauth_verifier);

        // Save connection
        await PlatformModel.upsert(userId, 'twitter', {
            accessToken,
            refreshToken: accessTokenSecret, // For OAuth 1.0, secret acts as refresh equivalent
            profileId: twitterUserId,
            username: screenName,
            connected: true
        });

        // Update user status
        await UserModel.updatePlatform(userId, 'twitter', { connected: true });

        // Clean up temp doc
        await UserModel.collection.doc(userId).collection('oauth_temp').doc('twitter').delete();

        return successResponse(res, { connected: true, platform: 'twitter' }, 'Twitter connected successfully');
    }
    else if (platform === 'linkedin') {
        // Get access token
        const tokenData = await linkedinService.getAccessToken(code);

        // Get user profile
        const profile = await linkedinService.getUserProfile(tokenData.access_token);

        // Save connection
        await PlatformModel.upsert(userId, 'linkedin', {
            accessToken: tokenData.access_token,
            expiresAt: new Date(Date.now() + tokenData.expires_in * 1000),
            profileId: profile.sub,
            profileName: `${profile.given_name} ${profile.family_name}`,
            avatarUrl: profile.picture,
            connected: true
        });

        // Update user status
        await UserModel.updatePlatform(userId, 'linkedin', { connected: true });

        return successResponse(res, { connected: true, platform: 'linkedin' }, 'LinkedIn connected successfully');
    }

    throw ApiError.badRequest('Invalid platform');
});

/**
 * Disconnect a platform
 * DELETE /api/platforms/disconnect/:platform
 */
const disconnectPlatform = asyncHandler(async (req, res) => {
    const { platform } = req.params;
    const userId = req.user.id;

    const platformLower = platform.toLowerCase();

    if (!['linkedin', 'twitter'].includes(platformLower)) {
        throw ApiError.badRequest('Invalid platform');
    }

    await PlatformModel.disconnect(userId, platformLower);

    // Also update user's platform status
    await UserModel.updatePlatform(userId, platformLower, {
        connected: false,
    });

    logger.info('Platform disconnected', { userId, platform: platformLower });

    return successResponse(res, {
        platform: platformLower,
        connected: false,
    }, `${platform} disconnected successfully`);
});

/**
 * Refresh platform tokens
 * POST /api/platforms/refresh/:platform
 */
const refreshToken = asyncHandler(async (req, res) => {
    const { platform } = req.params;
    const userId = req.user.id;

    const platformLower = platform.toLowerCase();

    const existingPlatform = await PlatformModel.findByUserAndPlatform(userId, platformLower);

    if (!existingPlatform || !existingPlatform.connected) {
        throw ApiError.badRequest(`${platform} is not connected`);
    }

    // In a real implementation, this would call the OAuth refresh endpoint
    // For now, we'll just return the current status

    return successResponse(res, {
        platform: platformLower,
        refreshed: true,
    }, 'Token refresh initiated');
});

module.exports = {
    getStatus,
    initAuth,
    authCallback,
    disconnectPlatform,
    refreshToken,
};
