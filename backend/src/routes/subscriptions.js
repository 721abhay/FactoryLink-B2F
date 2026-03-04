/**
 * Subscription Routes — TRD Section 4 (Enhanced)
 * POST   /subscriptions           — Create grocery subscription
 * GET    /subscriptions           — List user subscriptions
 * GET    /subscriptions/:id       — Get subscription details
 * PUT    /subscriptions/:id/pause — Pause subscription
 * PUT    /subscriptions/:id/resume — Resume subscription
 * DELETE /subscriptions/:id       — Cancel subscription
 */

const router = require('express').Router();
const { query } = require('../database/connection');
const { authenticate } = require('../middleware/auth');
const { validate } = require('../middleware/validators');
const { createNotification } = require('../services/notifications');

// ─── POST /subscriptions — Create subscription ──────
// TRD: Create grocery subscription with item list and duration
router.post('/', authenticate('customer'), validate('createSubscription'), async (req, res, next) => {
    try {
        const { product_id, qty, frequency, duration_months, anchor_point_id } = req.body;

        // Verify product exists
        const product = await query('SELECT * FROM products WHERE id = $1 AND is_active = true', [product_id]);
        if (product.rows.length === 0) {
            return res.status(404).json({ error: 'Not Found', message: 'Product not found or inactive.' });
        }

        // Check for existing active subscription for same product
        const existing = await query(
            `SELECT id FROM subscriptions WHERE user_id = $1 AND product_id = $2 AND status = 'active'`,
            [req.user.userId, product_id]
        );
        if (existing.rows.length > 0) {
            return res.status(409).json({
                error: 'Duplicate',
                message: 'You already have an active subscription for this product.',
                existing_id: existing.rows[0].id,
            });
        }

        // Calculate next delivery date
        const nextDelivery = new Date();
        if (frequency === 'weekly') nextDelivery.setDate(nextDelivery.getDate() + 7);
        else if (frequency === 'biweekly') nextDelivery.setDate(nextDelivery.getDate() + 14);
        else nextDelivery.setMonth(nextDelivery.getMonth() + 1);

        const result = await query(
            `INSERT INTO subscriptions (user_id, product_id, qty, frequency, duration_months, next_delivery_date, anchor_point_id)
             VALUES ($1, $2, $3, $4, $5, $6, $7) RETURNING *`,
            [req.user.userId, product_id, qty, frequency, duration_months, nextDelivery, anchor_point_id]
        );

        const sub = result.rows[0];
        const unitPrice = parseFloat(product.rows[0].tier1_price);
        const monthlyEstimate = unitPrice * qty * (frequency === 'weekly' ? 4 : frequency === 'biweekly' ? 2 : 1);

        await createNotification(
            req.user.userId,
            '🔔 Subscription Created!',
            `${qty}x ${product.rows[0].name} (${frequency}). Estimated ₹${monthlyEstimate.toFixed(0)}/month. First delivery: ${nextDelivery.toLocaleDateString('en-IN')}.`,
            'subscription',
            { subscriptionId: sub.id }
        );

        res.status(201).json({
            success: true,
            sub_id: sub.id,
            subscription: {
                ...sub,
                product_name: product.rows[0].name,
                monthly_estimate: monthlyEstimate,
            },
        });
    } catch (err) { next(err); }
});

// ─── GET /subscriptions — List all subscriptions ────
router.get('/', authenticate('customer'), async (req, res, next) => {
    try {
        const { status } = req.query;

        let sql = `
            SELECT s.*, p.name AS product_name, p.tier1_price, p.image_urls,
                   ap.name AS anchor_name
            FROM subscriptions s
            JOIN products p ON s.product_id = p.id
            LEFT JOIN anchor_points ap ON s.anchor_point_id = ap.id
            WHERE s.user_id = $1
        `;
        const params = [req.user.userId];

        if (status) {
            sql += ` AND s.status = $2`;
            params.push(status);
        }

        sql += ` ORDER BY s.created_at DESC`;

        const result = await query(sql, params);

        res.json({
            success: true,
            subscriptions: result.rows.map(s => ({
                id: s.id,
                product: {
                    id: s.product_id,
                    name: s.product_name,
                    price: parseFloat(s.tier1_price),
                    image: s.image_urls?.[0],
                },
                qty: s.qty,
                frequency: s.frequency,
                duration_months: s.duration_months,
                status: s.status,
                next_delivery_date: s.next_delivery_date,
                anchor_point: s.anchor_name,
                created_at: s.created_at,
            })),
        });
    } catch (err) { next(err); }
});

// ─── GET /subscriptions/:id — Get subscription details ──
router.get('/:id', authenticate('customer'), async (req, res, next) => {
    try {
        const result = await query(
            `SELECT s.*, p.name AS product_name, p.tier1_price, p.image_urls,
                    ap.name AS anchor_name
             FROM subscriptions s
             JOIN products p ON s.product_id = p.id
             LEFT JOIN anchor_points ap ON s.anchor_point_id = ap.id
             WHERE s.id = $1 AND s.user_id = $2`,
            [req.params.id, req.user.userId]
        );

        if (result.rows.length === 0) {
            return res.status(404).json({ error: 'Not Found', message: 'Subscription not found.' });
        }

        const s = result.rows[0];

        // Get related orders
        const orders = await query(
            `SELECT o.id, o.qty, o.total_amount, o.status, o.created_at
             FROM orders o
             JOIN subscriptions sub ON sub.product_id = o.product_id AND sub.user_id = o.user_id
             WHERE sub.id = $1
             ORDER BY o.created_at DESC LIMIT 10`,
            [req.params.id]
        );

        res.json({
            success: true,
            subscription: {
                id: s.id,
                product: { name: s.product_name, price: parseFloat(s.tier1_price), image: s.image_urls?.[0] },
                qty: s.qty,
                frequency: s.frequency,
                duration_months: s.duration_months,
                status: s.status,
                next_delivery_date: s.next_delivery_date,
                anchor_point: s.anchor_name,
                created_at: s.created_at,
            },
            recent_orders: orders.rows,
        });
    } catch (err) { next(err); }
});

// ─── PUT /subscriptions/:id/pause — Pause ───────────
router.put('/:id/pause', authenticate('customer'), async (req, res, next) => {
    try {
        const result = await query(
            `UPDATE subscriptions SET status = 'paused', updated_at = NOW()
             WHERE id = $1 AND user_id = $2 AND status = 'active'
             RETURNING *`,
            [req.params.id, req.user.userId]
        );

        if (result.rows.length === 0) {
            return res.status(404).json({
                error: 'Not Found',
                message: 'Active subscription not found.',
            });
        }

        await createNotification(
            req.user.userId,
            '⏸️ Subscription Paused',
            `Your subscription has been paused. No orders will be created until you resume.`,
            'subscription',
            { subscriptionId: req.params.id }
        );

        res.json({ success: true, subscription: result.rows[0] });
    } catch (err) { next(err); }
});

// ─── PUT /subscriptions/:id/resume — Resume ─────────
router.put('/:id/resume', authenticate('customer'), async (req, res, next) => {
    try {
        // Calculate new next delivery date
        const sub = await query(
            'SELECT * FROM subscriptions WHERE id = $1 AND user_id = $2 AND status = $3',
            [req.params.id, req.user.userId, 'paused']
        );

        if (sub.rows.length === 0) {
            return res.status(404).json({
                error: 'Not Found',
                message: 'Paused subscription not found.',
            });
        }

        const nextDelivery = new Date();
        const freq = sub.rows[0].frequency;
        if (freq === 'weekly') nextDelivery.setDate(nextDelivery.getDate() + 7);
        else if (freq === 'biweekly') nextDelivery.setDate(nextDelivery.getDate() + 14);
        else nextDelivery.setMonth(nextDelivery.getMonth() + 1);

        const result = await query(
            `UPDATE subscriptions SET status = 'active', next_delivery_date = $1, updated_at = NOW()
             WHERE id = $2 RETURNING *`,
            [nextDelivery, req.params.id]
        );

        await createNotification(
            req.user.userId,
            '▶️ Subscription Resumed',
            `Your subscription is active again. Next delivery: ${nextDelivery.toLocaleDateString('en-IN')}.`,
            'subscription',
            { subscriptionId: req.params.id }
        );

        res.json({ success: true, subscription: result.rows[0] });
    } catch (err) { next(err); }
});

// ─── DELETE /subscriptions/:id — Cancel ─────────────
router.delete('/:id', authenticate('customer'), async (req, res, next) => {
    try {
        const result = await query(
            `UPDATE subscriptions SET status = 'cancelled', updated_at = NOW()
             WHERE id = $1 AND user_id = $2 AND status IN ('active', 'paused')
             RETURNING *`,
            [req.params.id, req.user.userId]
        );

        if (result.rows.length === 0) {
            return res.status(404).json({
                error: 'Not Found',
                message: 'Active or paused subscription not found.',
            });
        }

        await createNotification(
            req.user.userId,
            '🚫 Subscription Cancelled',
            `Your subscription has been cancelled. You can create a new one anytime.`,
            'subscription',
            { subscriptionId: req.params.id }
        );

        res.json({ success: true, message: 'Subscription cancelled.', subscription: result.rows[0] });
    } catch (err) { next(err); }
});

module.exports = router;
