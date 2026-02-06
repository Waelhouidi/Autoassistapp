/**
 * API Response Utilities
 * Standardized response format
 */

/**
 * Success response
 */
const successResponse = (res, data, message = 'Success', statusCode = 200) => {
    return res.status(statusCode).json({
        success: true,
        message,
        data,
    });
};

/**
 * Error response
 */
const errorResponse = (res, message = 'Error', statusCode = 500, errors = null) => {
    return res.status(statusCode).json({
        success: false,
        message,
        ...(errors && { errors }),
    });
};

/**
 * Created response (201)
 */
const createdResponse = (res, data, message = 'Created successfully') => {
    return successResponse(res, data, message, 201);
};

/**
 * No content response (204)
 */
const noContentResponse = (res) => {
    return res.status(204).send();
};

/**
 * Paginated response
 */
const paginatedResponse = (res, data, pagination, message = 'Success') => {
    return res.status(200).json({
        success: true,
        message,
        data,
        pagination: {
            total: pagination.total,
            limit: pagination.limit,
            offset: pagination.offset,
            hasMore: pagination.hasMore,
        },
    });
};

module.exports = {
    successResponse,
    errorResponse,  // ← ADD THIS
    createdResponse,
    noContentResponse,
    paginatedResponse,
};