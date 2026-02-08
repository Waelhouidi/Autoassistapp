const express = require('express');
const router = express.Router();

/**
 * HTML Template for Callback Page
 */
const getCallbackHtml = (platform, code, verifier) => `
<!DOCTYPE html>
<html>
<head>
    <title>${platform} Connection Successful</title>
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <style>
        body { font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif; display: flex; justify-content: center; align-items: center; height: 100vh; margin: 0; background-color: #f0f2f5; }
        .card { background: white; padding: 2rem; border-radius: 1rem; box-shadow: 0 4px 6px rgba(0,0,0,0.1); max-width: 400px; width: 90%; text-align: center; }
        h1 { color: #1a73e8; margin-bottom: 1rem; }
        p { color: #5f6368; margin-bottom: 1.5rem; }
        .code-box { background: #f8f9fa; padding: 1rem; border-radius: 0.5rem; border: 1px solid #dadce0; font-family: monospace; font-size: 1.2rem; margin-bottom: 1.5rem; word-break: break-all; }
        .btn { background: #1a73e8; color: white; border: none; padding: 0.75rem 1.5rem; border-radius: 0.5rem; font-size: 1rem; cursor: pointer; transition: background 0.2s; }
        .btn:hover { background: #1557b0; }
        .success { color: #188038; font-weight: bold; margin-top: 1rem; display: none; }
    </style>
</head>
<body>
    <div class="card">
        <h1>${platform} Connected!</h1>
        <p>Copy the code below and paste it back in the app to complete the connection.</p>
        <div class="code-box" id="auth-code">${code || verifier}</div>
        <button class="btn" onclick="copyCode()">Copy Code</button>
        <div id="success-msg" class="success">Copied to clipboard!</div>
    </div>
    <script>
        function copyCode() {
            const code = document.getElementById('auth-code').innerText;
            navigator.clipboard.writeText(code).then(() => {
                const msg = document.getElementById('success-msg');
                msg.style.display = 'block';
                setTimeout(() => msg.style.display = 'none', 2000);
            });
        }
    </script>
</body>
</html>
`;

const { linkedinService } = require('../services');
const { PlatformModel, UserModel } = require('../models');

/**
 * LinkedIn Callback
 * GET /auth/linkedin/callback
 */
router.get('/linkedin/callback', async (req, res) => {
    const { code, state, error, error_description } = req.query;

    if (error) {
        return res.status(400).send(`<h1>Error: ${error}</h1><p>${error_description}</p>`);
    }

    if (!code) {
        return res.status(400).send('<h1>Error: No code received</h1>');
    }

    try {
        // Exchange code if state (userId) is present
        if (state && state !== 'linkedin_auth_state') {
            const userId = state;

            // Get access token
            const tokenData = await linkedinService.getAccessToken(code);

            // Get user profile
            const profile = await linkedinService.getUserProfile(tokenData.access_token);

            // Save connection
            await PlatformModel.upsert(userId, 'linkedin', {
                accessToken: tokenData.access_token,
                expiresAt: new Date(Date.now() + tokenData.expires_in * 1000),
                profileId: profile.sub,
                profileName: `${profile.given_name} ${profile.family_name}`,
                avatarUrl: profile.picture,
                connected: true
            });

            // Update user status
            await UserModel.updatePlatform(userId, 'linkedin', { connected: true });

            return res.send(`
                <!DOCTYPE html>
                <html>
                <head>
                    <title>Connected</title>
                    <meta name="viewport" content="width=device-width, initial-scale=1">
                    <style>
                        body { font-family: sans-serif; display: flex; flex-direction: column; justify-content: center; align-items: center; height: 100vh; margin: 0; background: #f0f2f5; text-align: center; }
                        .success { color: #188038; font-size: 2rem; margin-bottom: 1rem; }
                        p { color: #5f6368; }
                    </style>
                </head>
                <body>
                    <div class="success">✅ Connected!</div>
                    <h1>LinkedIn is now linked to your account.</h1>
                    <p>You can close this window and return to the app.</p>
                </body>
                </html>
            `);
        } else {
            // Fallback to manual code display if no userId in state
            res.send(getCallbackHtml('LinkedIn', code));
        }
    } catch (e) {
        console.error('LinkedIn Callback Error:', e);
        res.status(500).send(`<h1>Connection Failed</h1><p>${e.message}</p>`);
    }
});

/**
 * Twitter Callback
 * GET /auth/twitter/callback
 */
router.get('/twitter/callback', (req, res) => {
    const { oauth_token, oauth_verifier, denied } = req.query;

    if (denied) {
        return res.status(400).send('<h1>Error: Authorization denied</h1>');
    }

    if (!oauth_verifier) {
        return res.status(400).send('<h1>Error: No verifier received</h1>');
    }

    res.send(getCallbackHtml('Twitter', null, oauth_verifier));
});

module.exports = router;
