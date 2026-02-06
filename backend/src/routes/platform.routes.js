/**
 * Platform Routes
 * Social media platform connection endpoints
 */
const express = require('express');
const router = express.Router();
const { platformController } = require('../controllers');
const { verifyToken, validate, connectPlatformRules } = require('../middleware');

/**
 * @route   GET /api/platforms/status
 * @desc    Get connected platforms status
 * @access  Private
 */
router.get('/status', verifyToken, platformController.getStatus);

/**
 * @route   GET /api/platforms/auth/:platform
 * @desc    Initiate OAuth authentication
 * @access  Private
 */
router.get('/auth/:platform', verifyToken, platformController.initAuth);

/**
 * @route   POST /api/platforms/callback/:platform
 * @desc    Handle OAuth callback
 * @access  Private
 */
router.post('/callback/:platform', verifyToken, platformController.authCallback);


/**
 * @route   DELETE /api/platforms/disconnect/:platform
 * @desc    Disconnect a platform
 * @access  Private
 */
router.delete(
    '/disconnect/:platform',
    verifyToken,
    platformController.disconnectPlatform
);

/**
 * @route   POST /api/platforms/refresh/:platform
 * @desc    Refresh platform tokens
 * @access  Private
 */
router.post(
    '/refresh/:platform',
    verifyToken,
    platformController.refreshToken
);

module.exports = router;
