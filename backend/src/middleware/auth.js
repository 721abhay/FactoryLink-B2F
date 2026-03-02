/**
 * JWT Authentication Middleware — TRD Section 5
 * Verifies JWT tokens and attaches user to request
 */

const jwt = require('jsonwebtoken');
const { getSession } = require('../cache/redis');

function authenticate(requiredRole = null) {
    return async (req, res, next) => {
        try {
            const authHeader = req.headers.authorization;
            if (!authHeader || !authHeader.startsWith('Bearer ')) {
                return res.status(401).json({ error: 'Unauthorized', message: 'Please login to continue.' });
            }

            const token = authHeader.split(' ')[1];
            const decoded = jwt.verify(token, process.env.JWT_SECRET);

            // Check session in Redis
            const session = await getSession(decoded.userId);
            if (!session) {
                return res.status(401).json({ error: 'Session expired', message: 'Please login again.' });
            }

            // Role-based access control (RBAC) — TRD Security
            if (requiredRole && decoded.type !== requiredRole) {
                return res.status(403).json({ error: 'Forbidden', message: 'You do not have access to this resource.' });
            }

            req.user = {
                userId: decoded.userId,
                phone: decoded.phone,
                type: decoded.type,
            };

            next();
        } catch (err) {
            if (err.name === 'TokenExpiredError') {
                return res.status(401).json({ error: 'Token expired', message: 'Your session has expired. Please login again.' });
            }
            return res.status(401).json({ error: 'Invalid token', message: 'Please login again.' });
        }
    };
}

module.exports = { authenticate };
