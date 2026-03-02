/**
 * Error Handler Middleware — TRD Section 8
 * Every error must be handled gracefully.
 * No silent failures. No raw error messages to user.
 */

function errorHandler(err, req, res, next) {
    console.error(`❌ Error [${req.method} ${req.path}]:`, err.message);

    // Joi validation errors
    if (err.isJoi) {
        return res.status(400).json({
            error: 'Validation Error',
            message: 'Please check your details and try again.',
            details: err.details.map(d => ({ field: d.context.key, message: d.message })),
        });
    }

    // PostgreSQL unique constraint
    if (err.code === '23505') {
        return res.status(409).json({
            error: 'Duplicate Entry',
            message: 'This record already exists.',
        });
    }

    // PostgreSQL foreign key violation
    if (err.code === '23503') {
        return res.status(400).json({
            error: 'Invalid Reference',
            message: 'Referenced record does not exist.',
        });
    }

    // Default 500
    const statusCode = err.statusCode || 500;
    res.status(statusCode).json({
        error: statusCode === 500 ? 'Internal Server Error' : err.error || 'Error',
        message: statusCode === 500
            ? 'Something went wrong. Please try again later.'
            : err.message,
    });
}

module.exports = { errorHandler };
