/**
 * Express Application Setup
 * Main app configuration with middleware
 */
const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const morgan = require('morgan');

const env = require('./config/env');
const logger = require('./config/logger');
const routes = require('./routes');
const { apiLimiter, notFoundHandler, errorHandler } = require('./middleware');

// Create Express app
const app = express();

// =========================
// Security Middleware
// =========================

// Helmet for security headers
app.use(helmet({
    crossOriginResourcePolicy: { policy: 'cross-origin' },
}));

// CORS configuration
app.use(cors({
    origin: (origin, callback) => {
        // Allow requests with no origin (mobile apps, Postman, etc.)
        if (!origin) return callback(null, true);

        if (env.ALLOWED_ORIGINS.includes(origin) || env.isDevelopment()) {
            callback(null, true);
        } else {
            callback(new Error('Not allowed by CORS'));
        }
    },
    credentials: true,
    methods: ['GET', 'POST', 'PUT', 'PATCH', 'DELETE', 'OPTIONS'],
    allowedHeaders: ['Content-Type', 'Authorization'],
}));

// =========================
// Parsing Middleware
// =========================

// Parse JSON bodies
app.use(express.json({ limit: '10mb' }));

// Parse URL-encoded bodies
app.use(express.urlencoded({ extended: true, limit: '10mb' }));

// =========================
// Logging Middleware
// =========================

// HTTP request logging
if (env.isDevelopment()) {
    app.use(morgan('dev'));
} else {
    app.use(morgan('combined', {
        stream: {
            write: (message) => logger.info(message.trim()),
        },
    }));
}

// =========================
// Rate Limiting
// =========================

// Apply global rate limiter to API routes
app.use('/api', apiLimiter);

// =========================
// Routes
// =========================

// Mount API routes
app.use('/api', routes);

// Root endpoint
app.get('/', (req, res) => {
    res.json({
        success: true,
        message: 'AutoApp Assist API',
        version: '1.0.0',
        documentation: '/api/health',
    });
});

// =========================
// Error Handling
// =========================

// 404 handler
app.use(notFoundHandler);

// Global error handler
app.use(errorHandler);

module.exports = app;
