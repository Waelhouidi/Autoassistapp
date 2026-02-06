
// Mock config/env BEFORE requiring service
jest.mock('../../src/config/env', () => ({
    GEMINI_API_KEY: 'mock-api-key',
    N8N_ENHANCE_WEBHOOK: 'http://mock-n8n.com'
}));

// Mock logger to avoid console noise
jest.mock('../../src/config/logger', () => ({
    info: jest.fn(),
    warn: jest.fn(),
    error: jest.fn()
}));

const { GoogleGenerativeAI } = require('@google/generative-ai');
const aiService = require('../../src/services/aiService');

// Mock dependencies
jest.mock('@google/generative-ai');
jest.mock('axios');

describe('AI Service', () => {
    let mockGenerateContent;

    beforeEach(() => {
        // Reset mocks
        jest.clearAllMocks();

        // Setup Google AI mock
        mockGenerateContent = jest.fn();
        GoogleGenerativeAI.prototype.getGenerativeModel = jest.fn().mockReturnValue({
            generateContent: mockGenerateContent
        });

        // Re-initialize model because the singleton might have been created before mocks were fully set up
        // But since we mocked GoogleGenerativeAI from the start, the constructor logic in aiService should have picked up the mocked class
        // actually, aiService is a singleton created at module load time.
        // The constructor calls `new GoogleGenerativeAI(...)`.
    });

    test('enhanceContent should return enhanced result from Google AI', async () => {
        // Arrange
        const inputContent = 'Hello world';
        const expectedContent = 'Enhanced Hello world';

        // Check if model exists (was initialized)
        if (!aiService.model) {
            // Force re-init if needed, or rely on mock content
            const genAI = new GoogleGenerativeAI('test');
            aiService.model = genAI.getGenerativeModel({ model: 'gemini-pro' });
        }

        // Inject mock into the current model instance
        aiService.model.generateContent = mockGenerateContent;

        mockGenerateContent.mockResolvedValue({
            response: {
                text: () => expectedContent
            }
        });

        // Act
        const result = await aiService.enhanceContent(inputContent, ['Twitter']);

        // Assert
        expect(result.enhancedContent).toBe(expectedContent);
        expect(result.originalContent).toBe(inputContent);
        expect(mockGenerateContent).toHaveBeenCalled();
    });
});
