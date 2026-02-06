/**
 * Firebase Configuration
 * Initialize Firebase Admin SDK with service account
 */
const admin = require('firebase-admin');
const path = require('path');
const env = require('./env');

// Path to service account key
const serviceAccountPath = path.join(__dirname, '../../firebase-service-account.json');

// Initialize Firebase Admin
let firebaseApp;

try {
    const serviceAccount = require(serviceAccountPath);

    firebaseApp = admin.initializeApp({
        credential: admin.credential.cert(serviceAccount),
        projectId: env.FIREBASE_PROJECT_ID,
    });

    console.log('✅ Firebase Admin SDK initialized successfully');
} catch (error) {
    console.error('❌ Failed to initialize Firebase Admin SDK:', error.message);
    process.exit(1);
}

// Get Firestore instance
const db = admin.firestore();

// Get Auth instance
const auth = admin.auth();

// Collection references
const collections = {
    users: db.collection('users'),
    posts: db.collection('posts'),
    platforms: db.collection('platforms'),
    sessions: db.collection('sessions'),
    todos: db.collection('todos'),
};

module.exports = {
    admin,
    firebaseApp,
    db,
    auth,
    collections,
};
