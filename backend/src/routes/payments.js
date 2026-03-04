/**
 * Payment Routes — TRD T05: Razorpay Integration
 * POST /payments/create-order     — Create Razorpay order
 * POST /payments/verify-advance   — Verify & confirm advance payment
 * POST /payments/verify-final     — Verify & confirm final payment
 * POST /payments/webhook          — Razorpay webhook endpoint
 */

const router = require('express').Router();
const { query } = require('../database/connection');
const { authenticate } = require('../middleware/auth');
const {
    createRazorpayOrder,
    processAdvancePayment,
    processFinalPayment,
    processRefund,
    verifyWebhookSignature,
    handleWebhookEvent,
} = require('../services/paymentGateway');

// ─── POST /payments/create-order ────────────────
// Creates a Razorpay order for the customer to pay
router.post('/create-order', authenticate('customer'), async (req, res, next) => {
    try {
        const { order_id, payment_type } = req.body;

        if (!order_id || !['advance', 'final'].includes(payment_type)) {
            return res.status(400).json({
                error: 'Invalid request',
                message: 'order_id and payment_type (advance/final) are required.',
            });
        }

        // Get order
        const orderResult = await query('SELECT * FROM orders WHERE id = $1 AND user_id = $2', [order_id, req.user.userId]);
        if (orderResult.rows.length === 0) {
            return res.status(404).json({ error: 'Not Found', message: 'Order not found.' });
        }

        const order = orderResult.rows[0];
        const amount = payment_type === 'advance'
            ? parseFloat(order.advance_amount)
            : parseFloat(order.final_amount);

        if (payment_type === 'advance' && order.advance_paid) {
            return res.status(400).json({ error: 'Already paid', message: 'Advance already paid.' });
        }
        if (payment_type === 'final' && order.final_paid) {
            return res.status(400).json({ error: 'Already paid', message: 'Final payment already done.' });
        }

        const razorpayOrder = await createRazorpayOrder(
            amount,
            `${payment_type}_${order_id.slice(0, 20)}`,
            {
                order_id,
                type: payment_type,
                user_id: req.user.userId,
            }
        );

        // Store order_id mapping
        await query(
            `INSERT INTO payments (order_id, user_id, amount, type, gateway, gateway_order_id, status)
             VALUES ($1, $2, $3, $4, 'razorpay', $5, 'pending')`,
            [order_id, req.user.userId, amount, payment_type, razorpayOrder.id]
        );

        res.json({
            success: true,
            razorpay_order: {
                id: razorpayOrder.id,
                amount: razorpayOrder.amount,
                currency: razorpayOrder.currency || 'INR',
            },
            key_id: process.env.RAZORPAY_KEY_ID,
            order_details: {
                order_id,
                payment_type,
                amount,
            },
        });
    } catch (err) { next(err); }
});

// ─── POST /payments/verify-advance ──────────────
// Verify advance payment after Razorpay checkout
router.post('/verify-advance', authenticate('customer'), async (req, res, next) => {
    try {
        const { order_id, razorpay_order_id, razorpay_payment_id, razorpay_signature } = req.body;

        if (!order_id || !razorpay_payment_id) {
            return res.status(400).json({
                error: 'Missing fields',
                message: 'order_id, razorpay_payment_id required.',
            });
        }

        const result = await processAdvancePayment(
            order_id,
            razorpay_order_id,
            razorpay_payment_id,
            razorpay_signature
        );

        res.json(result);
    } catch (err) { next(err); }
});

// ─── POST /payments/verify-final ────────────────
// Verify final 70% payment
router.post('/verify-final', authenticate('customer'), async (req, res, next) => {
    try {
        const { order_id, razorpay_order_id, razorpay_payment_id, razorpay_signature } = req.body;

        if (!order_id || !razorpay_payment_id) {
            return res.status(400).json({
                error: 'Missing fields',
                message: 'order_id, razorpay_payment_id required.',
            });
        }

        const result = await processFinalPayment(
            order_id,
            razorpay_payment_id,
            razorpay_signature,
            razorpay_order_id
        );

        res.json(result);
    } catch (err) { next(err); }
});

// ─── POST /payments/create-topup — Wallet top-up order ────
router.post('/create-topup', authenticate('customer'), async (req, res, next) => {
    try {
        const { amount } = req.body;
        if (!amount || amount < 10 || amount > 50000) {
            return res.status(400).json({ error: 'Invalid amount', message: 'Amount must be ₹10 - ₹50,000.' });
        }

        const razorpayOrder = await createRazorpayOrder(
            parseFloat(amount),
            `topup_${req.user.userId.slice(0, 20)}`,
            { type: 'wallet_topup', user_id: req.user.userId }
        );

        res.json({
            success: true,
            razorpay_order: {
                id: razorpayOrder.id,
                amount: razorpayOrder.amount,
                currency: razorpayOrder.currency || 'INR',
            },
            key_id: process.env.RAZORPAY_KEY_ID,
        });
    } catch (err) { next(err); }
});

// ─── POST /payments/webhook — Razorpay webhooks ─
// No auth — uses webhook signature verification
router.post('/webhook', async (req, res, next) => {
    try {
        const signature = req.headers['x-razorpay-signature'];

        if (!verifyWebhookSignature(req.body, signature)) {
            return res.status(400).json({ error: 'Invalid webhook signature' });
        }

        const { event, payload } = req.body;
        await handleWebhookEvent(event, payload);

        res.json({ status: 'ok' });
    } catch (err) {
        console.error('Webhook error:', err.message);
        res.status(500).json({ error: 'Webhook processing failed' });
    }
});

module.exports = router;
