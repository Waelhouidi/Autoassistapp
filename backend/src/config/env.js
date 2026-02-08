/**
 * Environment Configuration
 * Centralized environment variable management
 */
require('dotenv').config();

const env = {
    // Server
    NODE_ENV: process.env.NODE_ENV || 'development',
    PORT: parseInt(process.env.PORT, 10) || 3000,

    // Firebase
    FIREBASE_PROJECT_ID: process.env.FIREBASE_PROJECT_ID || 'myquiz-2c0e7',

    // Gemini AI
    GEMINI_API_KEY: process.env.GEMINI_API_KEY,

    // LinkedIn OAuth
    LINKEDIN_CLIENT_ID: process.env.LINKEDIN_CLIENT_ID,
    LINKEDIN_CLIENT_SECRET: process.env.LINKEDIN_CLIENT_SECRET,
    LINKEDIN_REDIRECT_URI: process.env.LINKEDIN_REDIRECT_URI || 'http://192.168.0.196:3000/api/auth/linkedin/callback',

    // Twitter OAuth
    TWITTER_CLIENT_ID: process.env.TWITTER_CLIENT_ID,
    TWITTER_CLIENT_SECRET: process.env.TWITTER_CLIENT_SECRET,
    TWITTER_REDIRECT_URI: process.env.TWITTER_REDIRECT_URI || 'http://192.168.0.196:3000/api/auth/twitter/callback',

    // API URL (for OAuth callbacks)
    API_URL: process.env.API_URL || 'http://192.168.0.196:3000',

    // n8n Webhooks
    N8N_ENHANCE_WEBHOOK: process.env.N8N_ENHANCE_WEBHOOK || 'http://192.168.1.72:5678/webhook-test/flutter-linkedin-manager',
    N8N_PUBLISH_WEBHOOK: process.env.N8N_PUBLISH_WEBHOOK || 'http://192.168.1.72:5678/webhook-test/flutter-publish-approved',

    // Rate Limiting
    RATE_LIMIT_WINDOW_MS: parseInt(process.env.RATE_LIMIT_WINDOW_MS, 10) || 900000, // 15 minutes
    RATE_LIMIT_MAX_REQUESTS: parseInt(process.env.RATE_LIMIT_MAX_REQUESTS, 10) || 100,

    // CORS
    ALLOWED_ORIGINS: process.env.ALLOWED_ORIGINS?.split(',') || ['http://localhost:3000'],

    // Helpers
    isDevelopment: () => env.NODE_ENV === 'development',
    isProduction: () => env.NODE_ENV === 'production',
    isTest: () => env.NODE_ENV === 'test',
};

module.exports = env;
