/**
 * Admin Routes — TRD Section 4: Admin APIs (Internal Only)
 * GET  /admin/factories/pending       — List factories awaiting verification
 * PUT  /admin/factories/:id/verify    — Approve or reject factory
 * GET  /admin/zones                   — Zone health map
 * GET  /admin/pools/live              — Active pools with fill status
 * POST /admin/orders/:id/refund       — Force refund
 * GET  /admin/analytics               — Platform metrics
 */

const router = require('express').Router();
const { query } = require('../database/connection');
const { authenticate } = require('../middleware/auth');

// ─── GET /admin/factories/pending ────────────────
router.get('/factories/pending', authenticate('admin'), async (req, res, next) => {
    try {
        const result = await query(
            `SELECT f.*, u.phone AS owner_phone, u.name AS owner_name
       FROM factories f
       JOIN users u ON f.owner_id = u.id
       WHERE f.verification_status = 'pending'
       ORDER BY f.created_at DESC`
        );

        res.json({ success: true, factories: result.rows });
    } catch (err) { next(err); }
});

// ─── PUT /admin/factories/:id/verify ─────────────
router.put('/factories/:id/verify', authenticate('admin'), async (req, res, next) => {
    try {
        const { status, reason } = req.body; // approved or rejected

        if (!['approved', 'rejected'].includes(status)) {
            return res.status(400).json({ error: 'Invalid status', message: 'Must be approved or rejected.' });
        }

        const result = await query(
            `UPDATE factories SET verification_status = $1 WHERE id = $2 RETURNING *`,
            [status, req.params.id]
        );

        if (result.rows.length === 0) {
            return res.status(404).json({ error: 'Not Found', message: 'Factory not found.' });
        }

        // If approved, update user verified status
        if (status === 'approved') {
            await query('UPDATE users SET is_verified = true WHERE id = $1', [result.rows[0].owner_id]);
        }

        res.json({ success: true, factory: result.rows[0] });
    } catch (err) { next(err); }
});

// ─── GET /admin/zones ────────────────────────────
router.get('/zones', authenticate('admin'), async (req, res, next) => {
    try {
        const result = await query(
            `SELECT z.*, 
        (SELECT COUNT(*) FROM anchor_points WHERE zone_id = z.id) AS anchor_count,
        (SELECT COUNT(*) FROM users WHERE zone_id = z.id) AS user_count
       FROM zones z ORDER BY z.health_score DESC`
        );

        res.json({ success: true, zones: result.rows });
    } catch (err) { next(err); }
});

// ─── GET /admin/pools/live ───────────────────────
router.get('/pools/live', authenticate('admin'), async (req, res, next) => {
    try {
        const result = await query(
            `SELECT po.*, p.name AS product_name, z.name AS zone_name,
              f.business_name AS factory_name
       FROM pools po
       JOIN products p ON po.product_id = p.id
       JOIN zones z ON po.zone_id = z.id
       LEFT JOIN factories f ON po.factory_id = f.id
       WHERE po.status IN ('open', 'locked', 'assigned', 'production')
       ORDER BY po.created_at DESC`
        );

        res.json({ success: true, pools: result.rows });
    } catch (err) { next(err); }
});

// ─── POST /admin/orders/:id/refund ───────────────
router.post('/orders/:id/refund', authenticate('admin'), async (req, res, next) => {
    try {
        const orderResult = await query('SELECT * FROM orders WHERE id = $1', [req.params.id]);
        if (orderResult.rows.length === 0) {
            return res.status(404).json({ error: 'Not Found', message: 'Order not found.' });
        }

        const order = orderResult.rows[0];

        // Create refund payment record
        const refundResult = await query(
            `INSERT INTO payments (order_id, user_id, amount, type, status)
       VALUES ($1, $2, $3, 'refund', 'pending') RETURNING id`,
            [order.id, order.user_id, order.total_amount]
        );

        // Update order status
        await query(`UPDATE orders SET status = 'refunded' WHERE id = $1`, [order.id]);

        // TODO: Initiate Razorpay refund

        res.json({ success: true, refund_id: refundResult.rows[0].id });
    } catch (err) { next(err); }
});

// ─── GET /admin/analytics ────────────────────────
// TRD: Platform GMV, order count, user growth metrics
router.get('/analytics', authenticate('admin'), async (req, res, next) => {
    try {
        const [gmvResult, ordersResult, usersResult, factoriesResult, zonesResult] = await Promise.all([
            query(`SELECT COALESCE(SUM(total_amount), 0) AS gmv FROM orders WHERE status NOT IN ('cancelled', 'refunded')`),
            query(`SELECT COUNT(*) AS total, status FROM orders GROUP BY status`),
            query(`SELECT COUNT(*) AS total, type FROM users GROUP BY type`),
            query(`SELECT COUNT(*) AS total, verification_status FROM factories GROUP BY verification_status`),
            query(`SELECT COUNT(*) AS total FROM zones WHERE status = 'active'`),
        ]);

        // Monthly growth
        const monthlyGrowth = await query(
            `SELECT DATE_TRUNC('month', created_at) AS month, COUNT(*) AS new_users
       FROM users
       WHERE created_at >= NOW() - INTERVAL '6 months'
       GROUP BY month ORDER BY month`
        );

        res.json({
            success: true,
            metrics: {
                gmv: parseFloat(gmvResult.rows[0].gmv),
                orders_by_status: ordersResult.rows,
                users_by_type: usersResult.rows,
                factories_by_status: factoriesResult.rows,
                active_zones: parseInt(zonesResult.rows[0].total),
                monthly_growth: monthlyGrowth.rows,
            },
        });
    } catch (err) { next(err); }
});

module.exports = router;
