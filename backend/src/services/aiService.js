/**
 * AI Service
 * Integration with Gemini AI via Google Generative AI SDK or n8n fallback
 */
const { GoogleGenerativeAI } = require('@google/generative-ai');
const axios = require('axios');
const env = require('../config/env');
const logger = require('../config/logger');

class AIService {
    constructor() {
        this.enhanceWebhook = env.N8N_ENHANCE_WEBHOOK;
        this.timeout = 60000; // 60 seconds

        // Initialize Gemini SDK if API key is present
        if (env.GEMINI_API_KEY) {
            const genAI = new GoogleGenerativeAI(env.GEMINI_API_KEY);
this.model = genAI.getGenerativeModel({ model: 'gemini-1.5-flash' });            logger.info('Gemini AI SDK initialized');
        } else {
            logger.warn('GEMINI_API_KEY not found, falling back to n8n only');
        }
    }

    /**
     * Enhance content using Gemini AI (Direct SDK with n8n fallback)
     */
    async enhanceContent(content, platforms, userId) {
        // Try Direct SDK first if available
        if (this.model) {
            try {
                logger.info('Enhancing content via Gemini SDK', { userId });
                return await this._enhanceWithSDK(content, platforms);
            } catch (error) {
                logger.error('Gemini SDK enhancement failed, falling back to n8n', { error: error.message });
                // Fallback to n8n below
            }
        }

        // Fallback to n8n
        return await this._enhanceWithN8n(content, platforms, userId);
    }

    /**
     * Private: Enhance using Gemini SDK
     */
    async _enhanceWithSDK(content, platforms) {
        const startTime = Date.now();

        const prompt = `
      You are an expert social media manager. 
      Please enhance the following content for ${platforms.join(' and ')}.
      
      Original Content: "${content}"
      
      Requirements:
      - Professional yet engaging tone
      - Optimized for visibility on specified platforms
      - Include relevant hashtags
      - Check for grammar and clarity
      
      Return ONLY the enhanced content text, no conversational filler.
    `;

        const result = await this.model.generateContent(prompt);
        const response = await result.response;
        const enhancedContent = response.text().trim();

        const enhancementTime = Date.now() - startTime;

        return {
            originalContent: content,
            enhancedContent,
            platforms,
            metadata: {
                enhancementTime,
                model: 'gemini-pro-sdk',
                tokensUsed: null // SDK doesn't always return this easily in simple call
            }
        };
    }

    /**
     * Private: Enhance using n8n Webhook
     */
    async _enhanceWithN8n(content, platforms, userId) {
        const startTime = Date.now();
        try {
            logger.info('Sending content for enhancement via n8n', { userId });

            const response = await axios.post(
                this.enhanceWebhook,
                {
                    content: content.trim(),
                    platforms: platforms.map(p => p.toLowerCase()),
                    user_id: userId,
                    timestamp: new Date().toISOString(),
                },
                {
                    headers: { 'Content-Type': 'application/json' },
                    timeout: this.timeout,
                }
            );

            const enhancementTime = Date.now() - startTime;

            return {
                originalContent: content,
                enhancedContent: response.data.improved_content || response.data.enhanced_content,
                platforms,
                metadata: {
                    enhancementTime,
                    model: response.data.model || 'gemini-n8n',
                    tokensUsed: response.data.tokens_used || null,
                },
                raw: response.data,
            };
        } catch (error) {
            throw new Error(`n8n Enhancement failed: ${error.message}`);
        }
    }

    /**
     * Generate variations
     */
    async generateVariations(content, platforms, count = 3) {
        // If SDK is available, we can efficiently generate variations
        if (this.model) {
            const variations = [];
            for (let i = 0; i < count; i++) {
                try {
                    const result = await this._enhanceWithSDK(content + ` (Rewrite option ${i + 1})`, platforms);
                    variations.push(result.enhancedContent);
                } catch (e) {
                    logger.warn(`Variation ${i + 1} failed`);
                }
            }
            return variations;
        }

        // Fallback logic could go here or reuse enhanceContent
        return [];
    }
}

module.exports = new AIService();
