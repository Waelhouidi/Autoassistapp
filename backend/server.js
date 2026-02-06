/**
 * Server Entry Point
 * Start the Express server
 */
const app = require('./src/app');
const env = require('./src/config/env');
const logger = require('./src/config/logger');

// Initialize Firebase (loads on import)
require('./src/config/firebase');

const PORT = env.PORT;

// Start server
// Start server
// On ajoute '0.0.0.0' pour écouter toutes les interfaces réseau
const server = app.listen(PORT, '0.0.0.0', () => {
    // On récupère l'IP locale pour le log
    const networkInterfaces = require('os').networkInterfaces();
    const ip = Object.values(networkInterfaces)
        .flat()
        .find(i => i.family === 'IPv4' && !i.internal)?.address;

    logger.info(`🚀 Serveur actif sur le port : ${PORT}`);
    logger.info(`🔗 Local : http://localhost:${PORT}`);
    logger.info(`🌐 Réseau : http://${ip || 'votre-ip'}:${PORT}`);
});

// Graceful shutdown
const gracefulShutdown = (signal) => {
    logger.info(`${signal} received. Shutting down gracefully...`);

    server.close((err) => {
        if (err) {
            logger.error('Error during shutdown:', err);
            process.exit(1);
        }

        logger.info('Server closed. Process terminated.');
        process.exit(0);
    });

    // Force close after 10 seconds
    setTimeout(() => {
        logger.error('Forcing shutdown after timeout');
        process.exit(1);
    }, 10000);
};

// Handle shutdown signals
process.on('SIGTERM', () => gracefulShutdown('SIGTERM'));
process.on('SIGINT', () => gracefulShutdown('SIGINT'));

// Handle unhandled promise rejections
process.on('unhandledRejection', (reason, promise) => {
    logger.error('Unhandled Rejection:', { reason, promise });
});

// Handle uncaught exceptions
process.on('uncaughtException', (error) => {
    logger.error('Uncaught Exception:', error);
    process.exit(1);
});

module.exports = server;
