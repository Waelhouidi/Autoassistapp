/**
 * Auth Routes
 * Authentication and profile management endpoints
 */
const express = require('express');
const router = express.Router();
const { authController } = require('../controllers');
const { verifyToken, authLimiter } = require('../middleware');

// Apply auth rate limiter to all auth routes
router.use(authLimiter);

/**
 * @route   POST /api/auth/register
 * @desc    Register new user
 * @access  Public
 */
router.post('/register', authController.register);

/**
 * @route   POST /api/auth/login
 * @desc    Login user
 * @access  Public
 */
router.post('/login', authController.login);

/**
 * @route   GET /api/auth/verify
 * @desc    Verify token validity
 * @access  Private
 */
router.get('/verify', verifyToken, authController.verifyTokenEndpoint);

/**
 * @route   GET /api/auth/me
 * @desc    Get current user profile
 * @access  Private
 */
router.get('/me', verifyToken, authController.getProfile);

/**
 * @route   PATCH /api/auth/me
 * @desc    Update user profile
 * @access  Private
 */
router.patch('/me', verifyToken, authController.updateProfile);

/**
 * @route   DELETE /api/auth/me
 * @desc    Delete user account
 * @access  Private
 */
router.delete('/me', verifyToken, authController.deleteAccount);

module.exports = router;
