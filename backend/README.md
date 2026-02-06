# AutoApp Assist Backend

A Node.js Express backend for the AI Social Publisher app with Firebase authentication.

## 🚀 Quick Start

```bash
# Install dependencies
npm install

# Start development server
npm run dev

# Start production server
npm start
```

## 📁 Project Structure

```
backend/
├── src/
│   ├── config/          # Configuration files
│   │   ├── env.js       # Environment variables
│   │   ├── firebase.js  # Firebase Admin SDK
│   │   └── logger.js    # Winston logger
│   ├── controllers/     # Route handlers
│   │   ├── authController.js
│   │   ├── postController.js
│   │   └── platformController.js
│   ├── middleware/      # Express middleware
│   │   ├── auth.js      # Firebase token verification
│   │   ├── errorHandler.js
│   │   ├── rateLimiter.js
│   │   └── validator.js
│   ├── models/          # Firestore models
│   │   ├── User.js
│   │   ├── Post.js
│   │   └── Platform.js
│   ├── routes/          # API routes
│   │   ├── auth.routes.js
│   │   ├── post.routes.js
│   │   └── platform.routes.js
│   ├── services/        # Business logic
│   │   ├── aiService.js
│   │   └── postService.js
│   └── app.js           # Express app
├── server.js            # Entry point
├── package.json
└── .env
```

## 🔌 API Endpoints

### Health Check
- `GET /api/health` - API status

### Authentication
- `GET /api/auth/verify` - Verify token
- `GET /api/auth/me` - Get profile
- `PATCH /api/auth/me` - Update profile

### Posts
- `POST /api/posts/enhance` - Enhance content with AI
- `POST /api/posts/publish` - Publish to platforms
- `GET /api/posts` - Get post history
- `GET /api/posts/stats` - Get statistics

### Platforms
- `GET /api/platforms/status` - Get connected platforms
- `POST /api/platforms/connect/:platform` - Connect platform
- `DELETE /api/platforms/disconnect/:platform` - Disconnect

## 🔐 Authentication

All protected routes require a Firebase ID token:

```
Authorization: Bearer <firebase_id_token>
```

## 🔧 Environment Variables

See `.env.example` for required variables.
