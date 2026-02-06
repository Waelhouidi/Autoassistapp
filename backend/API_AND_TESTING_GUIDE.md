# 📘 AutoAssist API & Testing Guide

This document provides a comprehensive guide for testing the AutoAssist backend, understanding the data models, and executing use cases via Postman or cURL.

## 🛠️ Commands

### Backend
| Command | Description |
| :--- | :--- |
| `npm install` | Install all dependencies. |
| `npm run dev` | Start the development server (with hot-reload). |
| `npm start` | Start the production server. |
| `npm test` | Run unit tests (Jest). |
| `npm run test:watch` | Run tests in watch mode. |

### Frontend (Flutter)
| Command | Description |
| :--- | :--- |
| `flutter pub get` | Get dependencies. |
| `flutter run` | Run the app on a connected device/emulator. |
| `flutter build apk` | Build Android APK. |
| `flutter test` | Run widget/unit tests. |

---

## 🗄️ Data Models (Firestore)

### 1. User (`users` collection)
Represents a registered user.
```json
{
  "uid": "firebase_auth_uid",
  "email": "user@example.com",
  "name": "John Doe",
  "photoUrl": "https://...",
  "createdAt": "2024-02-02T12:00:00Z",
  "platforms": {
    "linkedin": { "connected": true, "accessToken": "..." },
    "twitter": { "connected": false }
  }
}
```

### 2. Post (`posts` collection)
Represents a social media post (draft or published).
```json
{
  "id": "uuid_v4",
  "userId": "firebase_auth_uid",
  "originalContent": "Raw idea text",
  "enhancedContent": "AI improved text...",
  "platforms": ["twitter", "linkedin"],
  "status": "draft" | "enhanced" | "published" | "failed",
  "createdAt": "2024-02-02T12:00:00Z",
  "metadata": {
    "aiModel": "gemini-pro",
    "enhancementTime": 1200
  }
}
```

### 3. Platform (`platforms` sub-collection usually, or part of User)
*Note: In this architecture, platform connection details are stored within the User document for simplicity, securely handled by the backend.*

---

## 🧪 Postman / API Testing Steps

**Base URL**: `http://localhost:3000/api`

### 🏗️ Step 1: Authentication (Get Token)
You must authenticate to access protected routes.

#### A. Register
*   **Endpoint**: `POST /auth/register`
*   **Body** (JSON):
    ```json
    {
      "email": "test@example.com",
      "password": "Password123!",
      "name": "Test User"
    }
    ```
*   **Response**: Returns `{ token: "jwt_token...", user: { ... } }`

#### B. Login
*   **Endpoint**: `POST /auth/login`
*   **Body** (JSON):
    ```json
    {
      "email": "test@example.com",
      "password": "Password123!"
    }
    ```
*   **Response**: Copy the `token` from the response. You will need this for all subsequent requests.

### 🔐 Authorization Header
For all steps below, add this header to your request:
- **Key**: `Authorization`
- **Value**: `Bearer YOUR_COPIED_TOKEN`

---

### 🚀 Step 2: Auto Post Use Cases

#### A. Enhance Content (AI)
Enhance a raw text draft using Gemini.
*   **Endpoint**: `POST /posts/enhance`
*   **Body** (JSON):
    ```json
    {
      "content": "I want to launch a new product next week. It is a coffee machine.",
      "platforms": ["Linkedin", "Twitter"]
    }
    ```
*   **Response**:
    ```json
    {
      "success": true,
      "data": {
        "enhancedContent": "🚀 Excited to announce our new product launch! ... #Coffee #Innovation",
        "originalContent": "...",
        "metadata": { ... }
      }
    }
    ```

#### B. Publish Post
Publish the content to selected platforms.
*   **Endpoint**: `POST /posts/publish`
*   **Body** (JSON):
    ```json
    {
      "content": "🚀 The waiting is over! Meet our new Coffee Machine 3000.",
      "platforms": ["Twitter"] 
    }
    ```
    *(Note: Verification might fail if actual Twitter keys aren't set in .env, but backend will process the request)*

#### C. Get Post History
View your previous actions.
*   **Endpoint**: `GET /posts`
*   **Response**: List of post objects.

#### D. Platform Status
Check connected accounts.
*   **Endpoint**: `GET /platforms/status`
*   **Response**:
    ```json
    {
      "linkedin": false,
      "twitter": false
    }
    ```

---

## 🔄 End-to-End Workflow (Manual Test)

1.  Start Backend: `npm run dev` inside `backend/`.
2.  Open Postman.
3.  **Register** a new user.
4.  Copy the `token`.
5.  Create a **New Request**: `POST http://localhost:3000/api/posts/enhance`.
6.  Set **Auth Type** to Bearer Token and paste the token.
7.  Set **Body** to JSON: `{"content": "Hello world", "platforms": ["Twitter"]}`.
8.  Send Request. Verify AI response.
9.  Open Flutter App (`flutter run`).
10. Login with the same credentials.
11. Go to "History" (top right icon). You should see your recent API activity if persisted, or create new posts from the App UI.
