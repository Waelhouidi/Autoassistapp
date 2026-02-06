/**
 * Rate Limiter Middleware
 * Protect API from abuse
 */
const rateLimit = require('express-rate-limit');
const env = require('../config/env');

/**
 * General API rate limiter
 */
const apiLimiter = rateLimit({
    windowMs: env.RATE_LIMIT_WINDOW_MS, // 15 minutes
    max: env.RATE_LIMIT_MAX_REQUESTS, // 100 requests per window
    message: {
        success: false,
        error: 'TooManyRequests',
        message: 'Too many requests, please try again later.',
    },
    standardHeaders: true,
    legacyHeaders: false,
    skip: (req) => {
        // Skip rate limiting in test environment
        return env.isTest();
    },
});

/**
 * Stricter rate limiter for auth endpoints
 */
const authLimiter = rateLimit({
    windowMs: 15 * 60 * 1000, // 15 minutes
    max: 10, // 10 requests per window
    message: {
        success: false,
        error: 'TooManyRequests',
        message: 'Too many authentication attempts, please try again later.',
    },
    standardHeaders: true,
    legacyHeaders: false,
    skip: (req) => env.isTest(),
});

/**
 * Rate limiter for AI enhancement (expensive operation)
 */
const enhanceLimiter = rateLimit({
    windowMs: 60 * 60 * 1000, // 1 hour
    max: 30, // 30 enhancements per hour
    message: {
        success: false,
        error: 'TooManyRequests',
        message: 'Enhancement limit reached. Please try again later.',
    },
    standardHeaders: true,
    legacyHeaders: false,
    skip: (req) => env.isTest(),
});

/**
 * Rate limiter for publishing
 */
const publishLimiter = rateLimit({
    windowMs: 60 * 60 * 1000, // 1 hour
    max: 20, // 20 publishes per hour
    message: {
        success: false,
        error: 'TooManyRequests',
        message: 'Publishing limit reached. Please try again later.',
    },
    standardHeaders: true,
    legacyHeaders: false,
    skip: (req) => env.isTest(),
});

module.exports = {
    apiLimiter,
    authLimiter,
    enhanceLimiter,
    publishLimiter,
};
