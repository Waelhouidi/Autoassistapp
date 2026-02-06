/**
 * Routes Index
 * Aggregate and export all route modules
 */
const express = require('express');
const router = express.Router();

// Import route modules
const authRoutes = require('./auth.routes');
const postRoutes = require('./post.routes');
const platformRoutes = require('./platform.routes');
const todoRoutes = require('./todo.routes');

// Health check endpoint (no auth required)
router.get('/health', (req, res) => {
    res.status(200).json({
        success: true,
        message: 'API is running',
        timestamp: new Date().toISOString(),
        version: '1.0.0',
    });
});

// Mount routes
router.use('/auth', authRoutes);
router.use('/posts', postRoutes);
router.use('/platforms', platformRoutes);
router.use('/todos', todoRoutes);

module.exports = router;

