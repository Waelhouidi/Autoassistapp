/**
 * Twitter Service (OAuth 1.0a)
 * Handles Twitter authentication and API interactions
 */
const { OAuth } = require('oauth');
const env = require('../config/env');
const logger = require('../config/logger');

class TwitterService {
    constructor() {
        this.consumerKey = env.TWITTER_CLIENT_ID;
        this.consumerSecret = env.TWITTER_CLIENT_SECRET;
        this.callbackUrl = env.TWITTER_REDIRECT_URI;

        // Initialize OAuth 1.0a client
        this.oauth = new OAuth(
            'https://api.twitter.com/oauth/request_token',
            'https://api.twitter.com/oauth/access_token',
            this.consumerKey,
            this.consumerSecret,
            '1.0A',
            this.callbackUrl,
            'HMAC-SHA1'
        );
    }

    /**
     * Get request token for OAuth flow
     */
    async getRequestToken() {
        return new Promise((resolve, reject) => {
            this.oauth.getOAuthRequestToken((error, oauthToken, oauthTokenSecret, results) => {
                if (error) {
                    logger.error('Error getting Twitter request token:', error);
                    reject(error);
                } else {
                    resolve({
                        oauthToken,
                        oauthTokenSecret,
                        results,
                        authUrl: `https://api.twitter.com/oauth/authenticate?oauth_token=${oauthToken}`
                    });
                }
            });
        });
    }

    /**
     * Get access token using verifier
     */
    async getAccessToken(oauthToken, oauthTokenSecret, oauthVerifier) {
        return new Promise((resolve, reject) => {
            this.oauth.getOAuthAccessToken(
                oauthToken,
                oauthTokenSecret,
                oauthVerifier,
                (error, accessToken, accessTokenSecret, results) => {
                    if (error) {
                        logger.error('Error getting Twitter access token:', error);
                        reject(error);
                    } else {
                        resolve({
                            accessToken,
                            accessTokenSecret,
                            userId: results.user_id,
                            screenName: results.screen_name,
                            results
                        });
                    }
                }
            );
        });
    }

    /**
     * Verify credentials (get current user)
     */
    async verifyCredentials(accessToken, accessTokenSecret) {
        return new Promise((resolve, reject) => {
            this.oauth.get(
                'https://api.twitter.com/1.1/account/verify_credentials.json?include_email=true',
                accessToken,
                accessTokenSecret,
                (error, data, response) => {
                    if (error) {
                        logger.error('Error verifying Twitter credentials:', error);
                        reject(error);
                    } else {
                        try {
                            const user = JSON.parse(data);
                            resolve(user);
                        } catch (parseError) {
                            reject(parseError);
                        }
                    }
                }
            );
        });
    }

    /**
     * Post a tweet (v2 API via v1.0a auth or using v2 library if preferred, 
     * but v1.1 endpoint is often easier for simple text if access level allows. 
     * For v2, we usually need different signing. 
     * Keeping it simple with 1.1 or v2 standard endpoint assuming OAuth 1.0a context).
     * 
     * Note: Twitter API v2 write access often requires OAuth 1.0a User Context.
     */
    async postTweet(accessToken, accessTokenSecret, content) {
        return new Promise((resolve, reject) => {
            this.oauth.post(
                'https://api.twitter.com/2/tweets',
                accessToken,
                accessTokenSecret,
                { "text": content },
                'application/json',
                (error, data, response) => {
                    if (error) {
                        logger.error('Error posting tweet:', error);
                        reject(error);
                    } else {
                        try {
                            const result = JSON.parse(data);
                            resolve(result);
                        } catch (parseError) {
                            reject(parseError);
                        }
                    }
                }
            );
        });
    }
}

module.exports = new TwitterService();
