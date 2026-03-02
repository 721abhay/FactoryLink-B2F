/**
 * Rate Limiter — TRD Section 5 & 7
 * Max 100 requests per user per minute on standard endpoints
 * Stricter limits on payment endpoints
 */

const rateLimit = require('express-rate-limit');

const rateLimiter = rateLimit({
    windowMs: parseInt(process.env.RATE_LIMIT_WINDOW_MS) || 60000,
    max: parseInt(process.env.RATE_LIMIT_MAX_REQUESTS) || 100,
    standardHeaders: true,
    legacyHeaders: false,
    message: {
        error: 'Too Many Requests',
        message: 'You are sending too many requests. Please wait a moment and try again.',
    },
    keyGenerator: (req) => {
        // Use user ID if authenticated, otherwise IP
        return req.user?.userId || req.ip;
    },
});

// Stricter rate limit for payment endpoints
const paymentRateLimiter = rateLimit({
    windowMs: 60000,
    max: 10,
    message: {
        error: 'Too Many Payment Requests',
        message: 'Please wait before making another payment attempt.',
    },
});

module.exports = { rateLimiter, paymentRateLimiter };
