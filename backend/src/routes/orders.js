/**
 * Order Routes — TRD Section 4: Customer Order APIs
 * POST /orders              — Place new order (joins pool or creates new)
 * GET  /orders              — List all customer orders
 * GET  /orders/:id          — Get order status/tracking
 * POST /orders/:id/pay-final — Customer pays remaining 70%
 * POST /orders/:id/collect  — Customer scans QR to confirm collection
 * POST /orders/:id/rate     — Submit quality rating
 */

const router = require('express').Router();
const { v4: uuidv4 } = require('uuid');
const { query, transaction } = require('../database/connection');
const { authenticate } = require('../middleware/auth');
const { validate } = require('../middleware/validators');
const { incrementPoolCount, setPoolStatus } = require('../cache/redis');
const { notifications } = require('../services/notifications');

// ─── POST /orders — Place new order ──────────────
// TRD: Place new order — joins existing pool or creates new one
router.post('/', authenticate('customer'), validate('placeOrder'), async (req, res, next) => {
    try {
        const { product_id, qty, anchor_point_id } = req.body;
        const userId = req.user.userId;

        const result = await transaction(async (client) => {
            // 1. Get product with pricing
            const productResult = await client.query(
                'SELECT * FROM products WHERE id = $1 AND is_active = true', [product_id]
            );
            if (productResult.rows.length === 0) {
                throw Object.assign(new Error('Product not found or unavailable.'), { statusCode: 404 });
            }
            const product = productResult.rows[0];

            // 2. Determine price tier based on qty
            let unitPrice = parseFloat(product.tier1_price);
            if (product.tier3_price && qty >= product.tier3_min_qty) {
                unitPrice = parseFloat(product.tier3_price);
            } else if (product.tier2_price && qty >= product.tier2_min_qty) {
                unitPrice = parseFloat(product.tier2_price);
            }

            const totalAmount = Math.round(unitPrice * qty * 100) / 100;
            const advanceAmount = Math.round(totalAmount * 0.30 * 100) / 100; // 30% advance — TRD C6
            const finalAmount = Math.round((totalAmount - advanceAmount) * 100) / 100; // 70% remaining

            // 3. Find or create pool for this product in user's zone
            // Get user's zone
            const userResult = await client.query('SELECT zone_id FROM users WHERE id = $1', [userId]);
            const zoneId = userResult.rows[0]?.zone_id;

            let poolId;
            if (zoneId) {
                // Look for existing open pool
                const poolResult = await client.query(
                    `SELECT id FROM pools WHERE product_id = $1 AND zone_id = $2 AND status = 'open'
           ORDER BY created_at DESC LIMIT 1`,
                    [product_id, zoneId]
                );

                if (poolResult.rows.length > 0) {
                    poolId = poolResult.rows[0].id;
                } else {
                    // Create new pool with 48h timer
                    const timerEnd = new Date(Date.now() + 48 * 60 * 60 * 1000);
                    const newPool = await client.query(
                        `INSERT INTO pools (product_id, zone_id, min_qty, target_qty, timer_end)
             VALUES ($1, $2, $3, $4, $5) RETURNING id`,
                        [product_id, zoneId, product.tier1_min_qty || 10, product.tier2_min_qty || 50, timerEnd]
                    );
                    poolId = newPool.rows[0].id;
                    await setPoolStatus(poolId, 'open');
                }

                // Update pool count
                await client.query(
                    'UPDATE pools SET current_qty = current_qty + $1 WHERE id = $2',
                    [qty, poolId]
                );
                await incrementPoolCount(poolId);

                // Check if pool should lock (reached min_qty)
                const updatedPool = await client.query('SELECT * FROM pools WHERE id = $1', [poolId]);
                if (updatedPool.rows[0].current_qty >= updatedPool.rows[0].min_qty && updatedPool.rows[0].status === 'open') {
                    await client.query(
                        `UPDATE pools SET status = 'locked', locked_at = NOW() WHERE id = $1`,
                        [poolId]
                    );
                    await setPoolStatus(poolId, 'locked');
                }
            }

            // 4. Create order
            const orderResult = await client.query(
                `INSERT INTO orders (user_id, pool_id, product_id, qty, unit_price, total_amount,
          advance_amount, final_amount, anchor_point_id, status)
         VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, 'pending')
         RETURNING *`,
                [userId, poolId, product_id, qty, unitPrice, totalAmount, advanceAmount, finalAmount, anchor_point_id]
            );

            return orderResult.rows[0];
        });

        // Send notification
        await notifications.orderPlaced(userId, result.id);

        // Emit to pool room via Socket.IO
        const io = req.app.get('io');
        if (io && result.pool_id) {
            io.to(`pool:${result.pool_id}`).emit('pool:updated', {
                poolId: result.pool_id,
                newOrder: true,
            });
        }

        res.status(201).json({
            success: true,
            order_id: result.id,
            order: {
                id: result.id,
                status: result.status,
                qty: result.qty,
                unit_price: parseFloat(result.unit_price),
                total_amount: parseFloat(result.total_amount),
                advance_amount: parseFloat(result.advance_amount),
                final_amount: parseFloat(result.final_amount),
                pool_id: result.pool_id,
            },
        });
    } catch (err) { next(err); }
});

// ─── GET /orders — List all customer orders ──────
router.get('/', authenticate('customer'), async (req, res, next) => {
    try {
        const { status, page = 1, limit = 20 } = req.query;
        const offset = (page - 1) * limit;

        let sql = `
      SELECT o.*, p.name AS product_name, p.image_urls, p.category,
             ap.name AS anchor_name
      FROM orders o
      JOIN products p ON o.product_id = p.id
      LEFT JOIN anchor_points ap ON o.anchor_point_id = ap.id
      WHERE o.user_id = $1
    `;
        const params = [req.user.userId];

        if (status) {
            sql += ` AND o.status = $2`;
            params.push(status);
        }

        sql += ` ORDER BY o.created_at DESC LIMIT $${params.length + 1} OFFSET $${params.length + 2}`;
        params.push(parseInt(limit), parseInt(offset));

        const result = await query(sql, params);

        res.json({
            success: true,
            orders: result.rows.map(o => ({
                id: o.id,
                product_name: o.product_name,
                category: o.category,
                image: o.image_urls?.[0],
                qty: o.qty,
                total_amount: parseFloat(o.total_amount),
                advance_paid: o.advance_paid,
                final_paid: o.final_paid,
                status: o.status,
                tracking_number: o.tracking_number,
                anchor_point: o.anchor_name,
                delivery_date: o.delivery_date,
                created_at: o.created_at,
            })),
        });
    } catch (err) { next(err); }
});

// ─── GET /orders/:id — Get order details ─────────
router.get('/:id', authenticate('customer'), async (req, res, next) => {
    try {
        const result = await query(
            `SELECT o.*, p.name AS product_name, p.image_urls, p.category,
              f.business_name AS factory_name, ap.name AS anchor_name, ap.address AS anchor_address
       FROM orders o
       JOIN products p ON o.product_id = p.id
       JOIN factories f ON p.factory_id = f.id
       LEFT JOIN anchor_points ap ON o.anchor_point_id = ap.id
       WHERE o.id = $1 AND o.user_id = $2`,
            [req.params.id, req.user.userId]
        );

        if (result.rows.length === 0) {
            return res.status(404).json({ error: 'Not Found', message: 'Order not found.' });
        }

        const o = result.rows[0];

        // Get payment history
        const payments = await query(
            'SELECT * FROM payments WHERE order_id = $1 ORDER BY created_at',
            [o.id]
        );

        res.json({
            success: true,
            order: {
                id: o.id,
                product: { name: o.product_name, category: o.category, images: o.image_urls },
                factory: o.factory_name,
                qty: o.qty,
                unit_price: parseFloat(o.unit_price),
                total_amount: parseFloat(o.total_amount),
                advance_amount: parseFloat(o.advance_amount),
                final_amount: parseFloat(o.final_amount),
                advance_paid: o.advance_paid,
                final_paid: o.final_paid,
                status: o.status,
                tracking_number: o.tracking_number,
                qr_code: o.qr_code,
                anchor_point: o.anchor_name ? { name: o.anchor_name, address: o.anchor_address } : null,
                delivery_date: o.delivery_date,
                collected_at: o.collected_at,
                created_at: o.created_at,
                payments: payments.rows.map(p => ({
                    id: p.id,
                    amount: parseFloat(p.amount),
                    type: p.type,
                    status: p.status,
                    created_at: p.created_at,
                })),
            },
        });
    } catch (err) { next(err); }
});

// ─── POST /orders/:id/pay-final — Pay 70% balance ────
// TRD: Customer pays remaining 70% before delivery
router.post('/:id/pay-final', authenticate('customer'), async (req, res, next) => {
    try {
        const orderResult = await query(
            `SELECT * FROM orders WHERE id = $1 AND user_id = $2 AND final_paid = false`,
            [req.params.id, req.user.userId]
        );

        if (orderResult.rows.length === 0) {
            return res.status(404).json({ error: 'Not Found', message: 'Order not found or already paid.' });
        }

        const order = orderResult.rows[0];

        // TODO: Integrate Razorpay — create payment order
        // const razorpayOrder = await razorpay.orders.create({
        //   amount: order.final_amount * 100,
        //   currency: 'INR',
        //   receipt: order.id,
        // });

        // Create payment record
        const paymentResult = await query(
            `INSERT INTO payments (order_id, user_id, amount, type, status)
       VALUES ($1, $2, $3, 'final', 'pending') RETURNING *`,
            [order.id, req.user.userId, order.final_amount]
        );

        res.json({
            success: true,
            payment_id: paymentResult.rows[0].id,
            amount: parseFloat(order.final_amount),
            // razorpay_order_id: razorpayOrder.id,
        });
    } catch (err) { next(err); }
});

// ─── POST /orders/:id/collect — QR scan collection ────
// TRD C9: Customer scans QR to confirm collection — triggers factory payment
router.post('/:id/collect', authenticate('customer'), async (req, res, next) => {
    try {
        const result = await transaction(async (client) => {
            const orderResult = await client.query(
                `SELECT * FROM orders WHERE id = $1 AND user_id = $2 AND status = 'delivered'`,
                [req.params.id, req.user.userId]
            );

            if (orderResult.rows.length === 0) {
                throw Object.assign(new Error('Order not ready for collection.'), { statusCode: 400 });
            }

            // Mark as collected
            await client.query(
                `UPDATE orders SET status = 'collected', collected_at = NOW() WHERE id = $1`,
                [req.params.id]
            );

            // TODO: Trigger factory payout via Razorpay Route
            // This releases the escrowed advance to the factory

            return { success: true };
        });

        res.json({ success: true, message: 'Order collected! Thank you.' });
    } catch (err) { next(err); }
});

// ─── POST /orders/:id/rate — Submit rating ───────
// TRD: Submit quality rating 1-5 stars with optional photo
router.post('/:id/rate', authenticate('customer'), validate('submitRating'), async (req, res, next) => {
    try {
        const { stars, review } = req.body;

        // Get order with factory
        const orderResult = await query(
            `SELECT o.id, p.factory_id FROM orders o
       JOIN products p ON o.product_id = p.id
       WHERE o.id = $1 AND o.user_id = $2`,
            [req.params.id, req.user.userId]
        );

        if (orderResult.rows.length === 0) {
            return res.status(404).json({ error: 'Not Found', message: 'Order not found.' });
        }

        const factoryId = orderResult.rows[0].factory_id;

        // Insert rating
        const ratingResult = await query(
            `INSERT INTO ratings (order_id, factory_id, user_id, stars, review)
       VALUES ($1, $2, $3, $4, $5) RETURNING id`,
            [req.params.id, factoryId, req.user.userId, stars, review]
        );

        // Update factory trust score (average of all ratings)
        await query(
            `UPDATE factories SET trust_score = (
        SELECT ROUND(AVG(stars) * 2, 1) FROM ratings WHERE factory_id = $1
      ) WHERE id = $1`,
            [factoryId]
        );

        res.json({ success: true, rating_id: ratingResult.rows[0].id });
    } catch (err) { next(err); }
});

module.exports = router;
