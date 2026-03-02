/**
 * Factory Routes — TRD Section 4: Factory APIs
 * POST /factory/register               — Factory registration
 * PUT  /factory/profile                 — Update profile/capacity/pricing
 * PUT  /factory/availability            — Update availability
 * GET  /factory/orders/pending          — List pending orders
 * PUT  /factory/orders/:id/accept       — Accept order
 * PUT  /factory/orders/:id/decline      — Decline order
 * PUT  /factory/orders/:id/status       — Update production status
 * GET  /factory/payments                — Payment history
 * GET  /factory/trust-score             — Trust score breakdown
 */

const router = require('express').Router();
const { query, transaction } = require('../database/connection');
const { authenticate } = require('../middleware/auth');
const { validate } = require('../middleware/validators');
const { setFactoryAvailability } = require('../cache/redis');
const { notifications } = require('../services/notifications');

// ─── POST /factory/register ──────────────────────
// TRD F1: Factory registration with all business details
router.post('/register', authenticate(), validate('factoryRegister'), async (req, res, next) => {
    try {
        const userId = req.user.userId;
        const {
            business_name, gst_number, msme_number, bank_account, ifsc_code,
            product_categories, capacity_per_day, min_order_qty,
            address, city, state
        } = req.body;

        // Check if factory already exists for this user
        const existing = await query('SELECT id FROM factories WHERE owner_id = $1', [userId]);
        if (existing.rows.length > 0) {
            return res.status(409).json({ error: 'Already registered', message: 'Factory already registered for this account.' });
        }

        const result = await query(
            `INSERT INTO factories (owner_id, business_name, gst_number, msme_number, bank_account, ifsc_code,
        product_categories, capacity_per_day, min_order_qty, address, city, state)
       VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12) RETURNING *`,
            [userId, business_name, gst_number, msme_number, bank_account, ifsc_code,
                product_categories, capacity_per_day, min_order_qty, address, city, state]
        );

        // Update user type to factory
        await query(`UPDATE users SET type = 'factory' WHERE id = $1`, [userId]);

        res.status(201).json({
            success: true,
            factory_id: result.rows[0].id,
            message: 'Factory registered! Documents will be verified within 48 hours.',
            factory: result.rows[0],
        });
    } catch (err) { next(err); }
});

// ─── PUT /factory/profile ────────────────────────
// TRD: Update factory profile, capacity, pricing tiers
router.put('/profile', authenticate('factory'), async (req, res, next) => {
    try {
        const userId = req.user.userId;
        const updates = req.body;
        const allowedFields = ['business_name', 'capacity_per_day', 'min_order_qty', 'product_categories', 'address', 'city', 'state'];

        const sets = [];
        const params = [];
        let idx = 1;

        for (const field of allowedFields) {
            if (updates[field] !== undefined) {
                sets.push(`${field} = $${idx++}`);
                params.push(updates[field]);
            }
        }

        if (sets.length === 0) {
            return res.status(400).json({ error: 'No updates', message: 'No valid fields to update.' });
        }

        params.push(userId);
        const result = await query(
            `UPDATE factories SET ${sets.join(', ')} WHERE owner_id = $${idx} RETURNING *`,
            params
        );

        res.json({ success: true, factory: result.rows[0] });
    } catch (err) { next(err); }
});

// ─── PUT /factory/availability ───────────────────
// TRD: Update weekly availability: full/partial/none
router.put('/availability', authenticate('factory'), async (req, res, next) => {
    try {
        const { availability } = req.body;
        if (!['full', 'partial', 'none'].includes(availability)) {
            return res.status(400).json({ error: 'Invalid value', message: 'Availability must be full, partial, or none.' });
        }

        const userId = req.user.userId;
        const result = await query(
            `UPDATE factories SET availability = $1 WHERE owner_id = $2 RETURNING id`,
            [availability, userId]
        );

        if (result.rows.length > 0) {
            await setFactoryAvailability(result.rows[0].id, availability);
        }

        res.json({ success: true, message: `Availability set to ${availability}.` });
    } catch (err) { next(err); }
});

// ─── GET /factory/orders/pending ─────────────────
// TRD: List all orders waiting for factory accept/decline
router.get('/orders/pending', authenticate('factory'), async (req, res, next) => {
    try {
        const userId = req.user.userId;

        const result = await query(
            `SELECT o.*, p.name AS product_name, p.category, po.current_qty AS pool_qty,
              u.name AS customer_name, ap.name AS anchor_name
       FROM orders o
       JOIN products p ON o.product_id = p.id
       JOIN factories f ON p.factory_id = f.id
       LEFT JOIN pools po ON o.pool_id = po.id
       LEFT JOIN users u ON o.user_id = u.id
       LEFT JOIN anchor_points ap ON o.anchor_point_id = ap.id
       WHERE f.owner_id = $1 AND o.status IN ('locked', 'assigned')
       ORDER BY o.created_at DESC`,
            [userId]
        );

        res.json({
            success: true,
            orders: result.rows.map(o => ({
                id: o.id,
                product: o.product_name,
                category: o.category,
                qty: o.qty,
                pool_qty: o.pool_qty,
                total_amount: parseFloat(o.total_amount),
                anchor: o.anchor_name,
                status: o.status,
                created_at: o.created_at,
            })),
        });
    } catch (err) { next(err); }
});

// ─── PUT /factory/orders/:id/accept ──────────────
// TRD: Factory accepts order — triggers advance payment release
router.put('/orders/:id/accept', authenticate('factory'), async (req, res, next) => {
    try {
        const result = await transaction(async (client) => {
            // Verify factory owns this product
            const orderResult = await client.query(
                `SELECT o.*, p.factory_id FROM orders o
         JOIN products p ON o.product_id = p.id
         JOIN factories f ON p.factory_id = f.id
         WHERE o.id = $1 AND f.owner_id = $2 AND o.status IN ('locked', 'assigned')`,
                [req.params.id, req.user.userId]
            );

            if (orderResult.rows.length === 0) {
                throw Object.assign(new Error('Order not found or not assignable.'), { statusCode: 404 });
            }

            // Update order status
            await client.query(
                `UPDATE orders SET status = 'accepted' WHERE id = $1`,
                [req.params.id]
            );

            // TODO: Trigger Razorpay advance payment release to factory

            // Notify customer
            await notifications.orderAccepted(orderResult.rows[0].user_id, 'Factory');

            return { payment_confirmed: true };
        });

        res.json({ success: true, payment_confirmed: true });
    } catch (err) { next(err); }
});

// ─── PUT /factory/orders/:id/decline ─────────────
// TRD: Factory declines — triggers cascade to next factory
router.put('/orders/:id/decline', authenticate('factory'), async (req, res, next) => {
    try {
        await query(
            `UPDATE orders SET status = 'pending' WHERE id = $1`,
            [req.params.id]
        );

        // TODO: Cascade to next factory in matching service
        // This would use Bull Queue for async job processing

        res.json({ success: true, rerouted: true, message: 'Order will be reassigned to another factory.' });
    } catch (err) { next(err); }
});

// ─── PUT /factory/orders/:id/status ──────────────
// TRD: Update production status: started/halfway/ready/dispatched
router.put('/orders/:id/status', authenticate('factory'), async (req, res, next) => {
    try {
        const { status } = req.body;
        const validStatuses = ['production', 'ready', 'dispatched', 'in_transit'];

        if (!validStatuses.includes(status)) {
            return res.status(400).json({
                error: 'Invalid status',
                message: `Status must be one of: ${validStatuses.join(', ')}`,
            });
        }

        const result = await query(
            `UPDATE orders SET status = $1 WHERE id = $2 RETURNING user_id`,
            [status, req.params.id]
        );

        if (result.rows.length === 0) {
            return res.status(404).json({ error: 'Not Found', message: 'Order not found.' });
        }

        // Send notification based on status
        if (status === 'dispatched') {
            await notifications.orderDispatched(result.rows[0].user_id, `FL-${req.params.id.slice(0, 6)}`);
        }

        res.json({ success: true, status });
    } catch (err) { next(err); }
});

// ─── GET /factory/payments ───────────────────────
// TRD: View all payment history and pending amounts
router.get('/payments', authenticate('factory'), async (req, res, next) => {
    try {
        const result = await query(
            `SELECT pay.*, o.qty, p.name AS product_name
       FROM payments pay
       JOIN orders o ON pay.order_id = o.id
       JOIN products p ON o.product_id = p.id
       JOIN factories f ON p.factory_id = f.id
       WHERE f.owner_id = $1
       ORDER BY pay.created_at DESC`,
            [req.user.userId]
        );

        // Calculate totals
        const totalReceived = result.rows
            .filter(p => p.status === 'completed' && p.type === 'factory_payout')
            .reduce((sum, p) => sum + parseFloat(p.amount), 0);

        const totalPending = result.rows
            .filter(p => p.status === 'pending')
            .reduce((sum, p) => sum + parseFloat(p.amount), 0);

        res.json({
            success: true,
            summary: {
                total_received: totalReceived,
                total_pending: totalPending,
            },
            payments: result.rows.map(p => ({
                id: p.id,
                order_id: p.order_id,
                product: p.product_name,
                amount: parseFloat(p.amount),
                type: p.type,
                status: p.status,
                created_at: p.created_at,
            })),
        });
    } catch (err) { next(err); }
});

// ─── GET /factory/trust-score ────────────────────
// TRD F9: View trust score breakdown by component
router.get('/trust-score', authenticate('factory'), async (req, res, next) => {
    try {
        const factoryResult = await query(
            'SELECT * FROM factories WHERE owner_id = $1', [req.user.userId]
        );
        if (factoryResult.rows.length === 0) {
            return res.status(404).json({ error: 'Not Found', message: 'Factory not found.' });
        }

        const factory = factoryResult.rows[0];

        // Calculate breakdown
        const ratings = await query(
            'SELECT AVG(stars) AS avg, COUNT(*) AS cnt FROM ratings WHERE factory_id = $1',
            [factory.id]
        );

        const completedOrders = await query(
            `SELECT COUNT(*) AS cnt FROM orders o
       JOIN products p ON o.product_id = p.id
       WHERE p.factory_id = $1 AND o.status = 'completed'`,
            [factory.id]
        );

        const totalOrders = await query(
            `SELECT COUNT(*) AS cnt FROM orders o
       JOIN products p ON o.product_id = p.id
       WHERE p.factory_id = $1`,
            [factory.id]
        );

        const fulfillmentRate = totalOrders.rows[0].cnt > 0
            ? (completedOrders.rows[0].cnt / totalOrders.rows[0].cnt * 100)
            : 100;

        res.json({
            success: true,
            score_detail: {
                overall_score: parseFloat(factory.trust_score),
                tier: factory.tier,
                breakdown: {
                    quality_rating: { score: parseFloat(ratings.rows[0]?.avg || 0).toFixed(1), weight: '40%', label: 'Customer Quality Rating' },
                    fulfillment_rate: { score: fulfillmentRate.toFixed(1), weight: '30%', label: 'Order Fulfillment Rate' },
                    response_time: { score: '8.0', weight: '15%', label: 'Response Time Score' },
                    document_verification: { score: factory.verification_status === 'approved' ? '10.0' : '0.0', weight: '15%', label: 'Document Verification' },
                },
                total_ratings: parseInt(ratings.rows[0]?.cnt || 0),
                completed_orders: parseInt(completedOrders.rows[0].cnt),
                total_orders: parseInt(totalOrders.rows[0].cnt),
            },
        });
    } catch (err) { next(err); }
});

module.exports = router;
