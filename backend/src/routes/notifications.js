/**
 * Notification Routes — TRD Section 6
 * GET  /notifications          — List user notifications
 * PUT  /notifications/:id/read — Mark notification as read
 * PUT  /notifications/read-all — Mark all as read
 */

const router = require('express').Router();
const { query } = require('../database/connection');
const { authenticate } = require('../middleware/auth');

// ─── GET /notifications — List user notifications ────
router.get('/', authenticate(), async (req, res, next) => {
    try {
        const { page = 1, limit = 20 } = req.query;
        const offset = (page - 1) * limit;

        const result = await query(
            `SELECT * FROM notifications
             WHERE user_id = $1
             ORDER BY created_at DESC
             LIMIT $2 OFFSET $3`,
            [req.user.userId, parseInt(limit), parseInt(offset)]
        );

        // Get unread count
        const unreadResult = await query(
            `SELECT COUNT(*) AS cnt FROM notifications
             WHERE user_id = $1 AND read = false`,
            [req.user.userId]
        );

        res.json({
            success: true,
            unread_count: parseInt(unreadResult.rows[0].cnt),
            notifications: result.rows.map(n => ({
                id: n.id,
                title: n.title,
                body: n.body,
                type: n.type,
                data: n.data,
                read: n.read,
                created_at: n.created_at,
            })),
        });
    } catch (err) { next(err); }
});

// ─── PUT /notifications/:id/read — Mark as read ────
router.put('/:id/read', authenticate(), async (req, res, next) => {
    try {
        await query(
            `UPDATE notifications SET read = true WHERE id = $1 AND user_id = $2`,
            [req.params.id, req.user.userId]
        );
        res.json({ success: true });
    } catch (err) { next(err); }
});

// ─── PUT /notifications/read-all — Mark all as read ────
router.put('/read-all', authenticate(), async (req, res, next) => {
    try {
        await query(
            `UPDATE notifications SET read = true WHERE user_id = $1 AND read = false`,
            [req.user.userId]
        );
        res.json({ success: true });
    } catch (err) { next(err); }
});

module.exports = router;
