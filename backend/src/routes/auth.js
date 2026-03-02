/**
 * Auth Routes — TRD Section 4: Authentication APIs
 * POST /auth/otp/send    — Send OTP to phone
 * POST /auth/otp/verify  — Verify OTP, return JWT
 * POST /auth/refresh     — Refresh expired JWT
 * POST /auth/logout      — Invalidate session
 */

const router = require('express').Router();
const jwt = require('jsonwebtoken');
const { v4: uuidv4 } = require('uuid');
const { query } = require('../database/connection');
const { setSession, deleteSession } = require('../cache/redis');
const { validate } = require('../middleware/validators');
const { authenticate } = require('../middleware/auth');

// ─── POST /auth/otp/send ─────────────────────────
router.post('/otp/send', validate('sendOtp'), async (req, res, next) => {
    try {
        const { phone } = req.body;

        // Generate 6-digit OTP
        const otp = Math.floor(100000 + Math.random() * 900000).toString();
        const expiresAt = new Date(Date.now() + 5 * 60 * 1000); // 5 min expiry

        // Store OTP in database
        await query(
            `INSERT INTO otps (phone, otp, expires_at) VALUES ($1, $2, $3)`,
            [phone, otp, expiresAt]
        );

        // TODO: Send OTP via Gupshup WhatsApp/SMS
        // In development, log the OTP
        console.log(`📱 OTP for ${phone}: ${otp}`);

        // In production, integrate Gupshup:
        // await gupshup.sendOtp(phone, otp);

        res.json({
            success: true,
            message: 'OTP sent successfully',
            message_id: uuidv4(),
            // Remove this in production:
            ...(process.env.NODE_ENV === 'development' && { dev_otp: otp }),
        });
    } catch (err) { next(err); }
});

// ─── POST /auth/otp/verify ───────────────────────
router.post('/otp/verify', validate('verifyOtp'), async (req, res, next) => {
    try {
        const { phone, otp, user_type } = req.body;

        // Check OTP
        const otpResult = await query(
            `SELECT * FROM otps 
       WHERE phone = $1 AND otp = $2 AND verified = false AND expires_at > NOW()
       ORDER BY created_at DESC LIMIT 1`,
            [phone, otp]
        );

        if (otpResult.rows.length === 0) {
            return res.status(400).json({
                error: 'Invalid OTP',
                message: 'The OTP is incorrect or has expired. Please try again.',
            });
        }

        // Mark OTP as verified
        await query('UPDATE otps SET verified = true WHERE id = $1', [otpResult.rows[0].id]);

        // Find or create user
        let userResult = await query('SELECT * FROM users WHERE phone = $1', [phone]);
        let isNewUser = false;

        if (userResult.rows.length === 0) {
            // New user — create account
            userResult = await query(
                `INSERT INTO users (phone, type) VALUES ($1, $2) RETURNING *`,
                [phone, user_type]
            );
            isNewUser = true;
        }

        const user = userResult.rows[0];

        // Generate JWT tokens
        const accessToken = jwt.sign(
            { userId: user.id, phone: user.phone, type: user.type },
            process.env.JWT_SECRET,
            { expiresIn: process.env.JWT_EXPIRY || '24h' }
        );

        const refreshToken = jwt.sign(
            { userId: user.id, type: 'refresh' },
            process.env.JWT_REFRESH_SECRET,
            { expiresIn: process.env.JWT_REFRESH_EXPIRY || '7d' }
        );

        // Store session in Redis (TTL 24h)
        await setSession(user.id, {
            userId: user.id,
            phone: user.phone,
            type: user.type,
            loginAt: new Date().toISOString(),
        });

        res.json({
            success: true,
            jwt_token: accessToken,
            refresh_token: refreshToken,
            user: {
                id: user.id,
                phone: user.phone,
                name: user.name,
                type: user.type,
                is_new: isNewUser,
                is_verified: user.is_verified,
            },
        });
    } catch (err) { next(err); }
});

// ─── POST /auth/refresh ──────────────────────────
router.post('/refresh', async (req, res, next) => {
    try {
        const { refresh_token } = req.body;
        if (!refresh_token) {
            return res.status(400).json({ error: 'Missing token', message: 'Refresh token is required.' });
        }

        const decoded = jwt.verify(refresh_token, process.env.JWT_REFRESH_SECRET);

        // Get user
        const userResult = await query('SELECT * FROM users WHERE id = $1', [decoded.userId]);
        if (userResult.rows.length === 0) {
            return res.status(401).json({ error: 'Invalid token', message: 'User not found.' });
        }

        const user = userResult.rows[0];

        // Issue new access token
        const newToken = jwt.sign(
            { userId: user.id, phone: user.phone, type: user.type },
            process.env.JWT_SECRET,
            { expiresIn: process.env.JWT_EXPIRY || '24h' }
        );

        // Refresh Redis session
        await setSession(user.id, {
            userId: user.id,
            phone: user.phone,
            type: user.type,
            loginAt: new Date().toISOString(),
        });

        res.json({ success: true, new_token: newToken });
    } catch (err) {
        return res.status(401).json({ error: 'Invalid refresh token', message: 'Please login again.' });
    }
});

// ─── POST /auth/logout ───────────────────────────
router.post('/logout', authenticate(), async (req, res, next) => {
    try {
        await deleteSession(req.user.userId);
        res.json({ success: true, message: 'Logged out successfully.' });
    } catch (err) { next(err); }
});

module.exports = router;
