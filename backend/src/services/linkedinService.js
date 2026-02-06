/**
 * LinkedIn Service (OAuth 2.0)
 * Handles LinkedIn authentication and API interactions
 */
const axios = require('axios');
const env = require('../config/env');
const logger = require('../config/logger');

class LinkedInService {
    constructor() {
        this.clientId = process.env.LINKEDIN_CLIENT_ID;
        this.clientSecret = process.env.LINKEDIN_CLIENT_SECRET;
        this.callbackUrl = `${env.API_URL || 'http://localhost:3000'}/api/auth/linkedin/callback`;
        this.scope = 'openid profile w_member_social email';
    }

    /**
     * Get authorization URL
     */
    getAuthorizationUrl() {
        const params = new URLSearchParams({
            response_type: 'code',
            client_id: this.clientId,
            redirect_uri: this.callbackUrl,
            scope: this.scope,
            state: 'linkedin_auth_state', // Should be random in production
        });

        return `https://www.linkedin.com/oauth/v2/authorization?${params.toString()}`;
    }

    /**
     * Get access token from code
     */
    async getAccessToken(code) {
        try {
            const params = new URLSearchParams({
                grant_type: 'authorization_code',
                code: code,
                redirect_uri: this.callbackUrl,
                client_id: this.clientId,
                client_secret: this.clientSecret,
            });

            const response = await axios.post(
                'https://www.linkedin.com/oauth/v2/accessToken',
                params,
                {
                    headers: { 'Content-Type': 'application/x-www-form-urlencoded' }
                }
            );

            return response.data; // { access_token, expires_in, ... }
        } catch (error) {
            logger.error('Error getting LinkedIn access token:', error.response?.data || error.message);
            throw error;
        }
    }

    /**
     * Get current user profile (using OpenID)
     */
    async getUserProfile(accessToken) {
        try {
            const response = await axios.get('https://api.linkedin.com/v2/userinfo', {
                headers: { 'Authorization': `Bearer ${accessToken}` }
            });

            return response.data;
        } catch (error) {
            logger.error('Error getting LinkedIn profile:', error.response?.data || error.message);
            throw error;
        }
    }

    /**
     * Create a text share
     */
    async createShare(accessToken, personUrn, text) {
        try {
            const response = await axios.post(
                'https://api.linkedin.com/v2/ugcPosts',
                {
                    author: `urn:li:person:${personUrn}`,
                    lifecycleState: 'PUBLISHED',
                    specificContent: {
                        'com.linkedin.ugc.ShareContent': {
                            shareCommentary: {
                                text: text
                            },
                            shareMediaCategory: 'NONE'
                        }
                    },
                    visibility: {
                        'com.linkedin.ugc.MemberNetworkVisibility': 'PUBLIC'
                    }
                },
                {
                    headers: {
                        'Authorization': `Bearer ${accessToken}`,
                        'X-Restli-Protocol-Version': '2.0.0'
                    }
                }
            );

            return response.data;
        } catch (error) {
            logger.error('Error creating LinkedIn share:', error.response?.data || error.message);
            throw error;
        }
    }
}

module.exports = new LinkedInService();
