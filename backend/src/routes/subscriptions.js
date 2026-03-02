/**
 * Subscription Routes — TRD Section 4
 * POST /subscriptions      — Create grocery subscription
 * GET  /subscriptions/:id  — Get subscription details
 */

const router = require('express').Router();
const { query } = require('../database/connection');
const { authenticate } = require('../middleware/auth');
const { validate } = require('../middleware/validators');

// ─── POST /subscriptions ─────────────────────────
// TRD: Create grocery subscription with item list and duration
router.post('/', authenticate('customer'), validate('createSubscription'), async (req, res, next) => {
    try {
        const { product_id, qty, frequency, duration_months, anchor_point_id } = req.body;

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

        res.status(201).json({
            success: true,
            sub_id: result.rows[0].id,
            subscription: result.rows[0],
        });
    } catch (err) { next(err); }
});

// ─── GET /subscriptions/:id ──────────────────────
// TRD: Get subscription details and next delivery date
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
        });
    } catch (err) { next(err); }
});

module.exports = router;
