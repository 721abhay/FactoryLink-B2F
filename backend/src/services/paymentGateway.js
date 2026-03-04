/**
 * Payment Gateway Service — TRD T05: Razorpay Integration
 * 
 * TRD: "Payment splitting: 30% advance at order time, 70% upon delivery confirmation"
 * Complete Plan: "Razorpay handles ₹ flow. UPI preferred. Auto-split to factory."
 * 
 * Features:
 * 1. Create Razorpay order (for advance / final / topup)
 * 2. Verify payment signature
 * 3. Process refund
 * 4. Factory payout (after delivery confirmed)
 * 5. Webhook handler for async payment events
 */

const crypto = require('crypto');
const { query, transaction } = require('../database/connection');
const { createNotification } = require('./notifications');
const { creditWallet } = require('./walletService');

// ─── Razorpay SDK ────────────────────────────────
let Razorpay;
let razorpayInstance;

function initRazorpay() {
    try {
        Razorpay = require('razorpay');
        razorpayInstance = new Razorpay({
            key_id: process.env.RAZORPAY_KEY_ID,
            key_secret: process.env.RAZORPAY_KEY_SECRET,
        });
        console.log('✅ Razorpay SDK initialized');
        return true;
    } catch (err) {
        console.warn('⚠️  Razorpay SDK not available — using mock mode');
        return false;
    }
}

// ═══════════════════════════════════════════════════
// 1. CREATE RAZORPAY ORDER
// ═══════════════════════════════════════════════════
/**
 * Creates a Razorpay order for payment
 * @param {number} amount — Amount in INR (will be converted to paise)
 * @param {string} currency — Currency code, default 'INR'
 * @param {string} receipt — Internal receipt ID
 * @param {object} notes — Additional metadata
 * @returns {{ id, amount, currency, receipt }}
 */
async function createRazorpayOrder(amount, receipt, notes = {}) {
    const amountInPaise = Math.round(amount * 100);

    if (razorpayInstance) {
        // Real Razorpay
        const order = await razorpayInstance.orders.create({
            amount: amountInPaise,
            currency: 'INR',
            receipt: receipt.slice(0, 40),
            notes: {
                ...notes,
                platform: 'FactoryLink',
            },
        });
        return order;
    } else {
        // Mock mode for development
        return {
            id: `order_mock_${Date.now()}`,
            amount: amountInPaise,
            currency: 'INR',
            receipt,
            status: 'created',
            notes,
        };
    }
}


// ═══════════════════════════════════════════════════
// 2. VERIFY PAYMENT SIGNATURE
// ═══════════════════════════════════════════════════
/**
 * Verify Razorpay payment signature
 * TRD: "Verify signature on server before confirming payment"
 */
function verifyPaymentSignature(orderId, paymentId, signature) {
    if (!process.env.RAZORPAY_KEY_SECRET || process.env.RAZORPAY_KEY_SECRET === 'your_razorpay_secret') {
        // Mock mode — always valid
        return true;
    }

    const body = orderId + '|' + paymentId;
    const expectedSignature = crypto
        .createHmac('sha256', process.env.RAZORPAY_KEY_SECRET)
        .update(body)
        .digest('hex');

    return expectedSignature === signature;
}


// ═══════════════════════════════════════════════════
// 3. PROCESS ADVANCE PAYMENT — 30%
// ═══════════════════════════════════════════════════
/**
 * Process and confirm an advance payment for an order
 * TRD C4: "30% advance payment at order time"
 */
async function processAdvancePayment(orderId, razorpayOrderId, razorpayPaymentId, razorpaySignature) {
    // 1. Verify signature
    const isValid = verifyPaymentSignature(razorpayOrderId, razorpayPaymentId, razorpaySignature);
    if (!isValid) {
        throw Object.assign(new Error('Invalid payment signature'), { statusCode: 400 });
    }

    return await transaction(async (client) => {
        // 2. Get order
        const orderResult = await client.query(
            'SELECT * FROM orders WHERE id = $1', [orderId]
        );
        if (orderResult.rows.length === 0) {
            throw Object.assign(new Error('Order not found'), { statusCode: 404 });
        }
        const order = orderResult.rows[0];

        if (order.advance_paid) {
            throw Object.assign(new Error('Advance already paid'), { statusCode: 400 });
        }

        // 3. Record payment
        await client.query(
            `INSERT INTO payments (order_id, user_id, amount, type, gateway, gateway_order_id, gateway_payment_id, gateway_signature, status)
             VALUES ($1, $2, $3, 'advance', 'razorpay', $4, $5, $6, 'completed')`,
            [orderId, order.user_id, order.advance_amount, razorpayOrderId, razorpayPaymentId, razorpaySignature]
        );

        // 4. Mark advance as paid
        await client.query(
            `UPDATE orders SET advance_paid = true, updated_at = NOW() WHERE id = $1`,
            [orderId]
        );

        // 5. Notify customer
        await createNotification(
            order.user_id,
            '✅ Payment Received',
            `₹${parseFloat(order.advance_amount).toFixed(2)} advance payment confirmed for your order.`,
            'payment',
            { orderId, amount: order.advance_amount, type: 'advance' }
        );

        return { success: true, paid: parseFloat(order.advance_amount) };
    });
}


// ═══════════════════════════════════════════════════
// 4. PROCESS FINAL PAYMENT — 70%
// ═══════════════════════════════════════════════════
/**
 * Process final payment before delivery
 * TRD C6: "70% balance payment upon delivery notification"
 */
async function processFinalPayment(orderId, razorpayPaymentId, razorpaySignature, razorpayOrderId) {
    return await transaction(async (client) => {
        const orderResult = await client.query(
            'SELECT * FROM orders WHERE id = $1', [orderId]
        );
        if (orderResult.rows.length === 0) {
            throw Object.assign(new Error('Order not found'), { statusCode: 404 });
        }
        const order = orderResult.rows[0];

        if (!order.advance_paid) {
            throw Object.assign(new Error('Advance payment not completed'), { statusCode: 400 });
        }
        if (order.final_paid) {
            throw Object.assign(new Error('Final payment already paid'), { statusCode: 400 });
        }

        // Verify signature if provided
        if (razorpaySignature && razorpayOrderId) {
            const isValid = verifyPaymentSignature(razorpayOrderId, razorpayPaymentId, razorpaySignature);
            if (!isValid) {
                throw Object.assign(new Error('Invalid payment signature'), { statusCode: 400 });
            }
        }

        // Record payment
        await client.query(
            `INSERT INTO payments (order_id, user_id, amount, type, gateway, gateway_order_id, gateway_payment_id, status)
             VALUES ($1, $2, $3, 'final', 'razorpay', $4, $5, 'completed')`,
            [orderId, order.user_id, order.final_amount, razorpayOrderId || 'wallet', razorpayPaymentId || 'wallet']
        );

        // Mark final as paid
        await client.query(
            `UPDATE orders SET final_paid = true, updated_at = NOW() WHERE id = $1`,
            [orderId]
        );

        await createNotification(
            order.user_id,
            '✅ Full Payment Complete',
            `₹${parseFloat(order.final_amount).toFixed(2)} final payment received. Your order is ready for collection!`,
            'payment',
            { orderId, amount: order.final_amount, type: 'final' }
        );

        return { success: true, paid: parseFloat(order.final_amount) };
    });
}


// ═══════════════════════════════════════════════════
// 5. PROCESS REFUND
// ═══════════════════════════════════════════════════
/**
 * Initiate refund — to wallet (instant) or to bank (via Razorpay)
 * TRD T03: "Full advance refund within 2 hours"
 */
async function processRefund(orderId, toWallet = true) {
    return await transaction(async (client) => {
        const orderResult = await client.query(
            'SELECT * FROM orders WHERE id = $1', [orderId]
        );
        if (orderResult.rows.length === 0) {
            throw Object.assign(new Error('Order not found'), { statusCode: 404 });
        }
        const order = orderResult.rows[0];

        // Calculate refund amount (advance + any final paid)
        let refundAmount = 0;
        if (order.advance_paid) refundAmount += parseFloat(order.advance_amount);
        if (order.final_paid) refundAmount += parseFloat(order.final_amount);

        if (refundAmount <= 0) {
            return { success: true, refunded: 0, message: 'No payment to refund' };
        }

        if (toWallet) {
            // Instant refund to wallet
            await creditWallet(
                order.user_id, refundAmount, 'refund',
                `Refund for order #${orderId.slice(0, 8)}`, orderId
            );

            // Update payment record
            await client.query(
                `INSERT INTO payments (order_id, user_id, amount, type, status, metadata)
                 VALUES ($1, $2, $3, 'refund', 'completed', $4)`,
                [orderId, order.user_id, refundAmount, JSON.stringify({ method: 'wallet' })]
            );
        } else {
            // Refund via Razorpay
            const payment = await client.query(
                `SELECT gateway_payment_id FROM payments
                 WHERE order_id = $1 AND type = 'advance' AND status = 'completed'
                 LIMIT 1`, [orderId]
            );

            if (payment.rows.length > 0 && razorpayInstance) {
                try {
                    await razorpayInstance.payments.refund(payment.rows[0].gateway_payment_id, {
                        amount: Math.round(refundAmount * 100),
                    });
                } catch (err) {
                    console.error('Razorpay refund failed:', err.message);
                    // Fallback to wallet refund
                    await creditWallet(
                        order.user_id, refundAmount, 'refund',
                        `Refund for order #${orderId.slice(0, 8)} (bank refund failed)`, orderId
                    );
                }
            }

            await client.query(
                `INSERT INTO payments (order_id, user_id, amount, type, status, metadata)
                 VALUES ($1, $2, $3, 'refund', 'processing', $4)`,
                [orderId, order.user_id, refundAmount, JSON.stringify({ method: 'razorpay' })]
            );
        }

        // Update order status
        await client.query(
            `UPDATE orders SET status = 'refunded', updated_at = NOW() WHERE id = $1`,
            [orderId]
        );

        return { success: true, refunded: refundAmount, method: toWallet ? 'wallet' : 'razorpay' };
    });
}


// ═══════════════════════════════════════════════════
// 6. FACTORY PAYOUT — After collection
// ═══════════════════════════════════════════════════
/**
 * Trigger payout to factory after customer collects order
 * TRD C7: "Factory receives payment after QR scan"
 */
async function triggerFactoryPayout(orderId) {
    return await transaction(async (client) => {
        const orderResult = await client.query(
            `SELECT o.*, p.factory_id, f.bank_account, f.ifsc_code, f.business_name, f.owner_id
             FROM orders o
             JOIN products p ON o.product_id = p.id
             JOIN factories f ON p.factory_id = f.id
             WHERE o.id = $1 AND o.status IN ('collected', 'completed')`,
            [orderId]
        );

        if (orderResult.rows.length === 0) {
            throw Object.assign(new Error('Order not eligible for payout'), { statusCode: 400 });
        }

        const order = orderResult.rows[0];
        const totalPaid = parseFloat(order.total_amount);

        // Platform commission: 8% (TRD: "8% platform fee")
        const platformFee = totalPaid * 0.08;
        const payoutAmount = totalPaid - platformFee;

        // Check if payout already exists
        const existing = await client.query(
            `SELECT id FROM payments WHERE order_id = $1 AND type = 'factory_payout'`, [orderId]
        );
        if (existing.rows.length > 0) {
            return { success: false, message: 'Payout already processed' };
        }

        // Record factory payout
        await client.query(
            `INSERT INTO payments (order_id, user_id, amount, type, status, metadata)
             VALUES ($1, $2, $3, 'factory_payout', 'processing', $4)`,
            [orderId, order.owner_id, payoutAmount, JSON.stringify({
                factory_id: order.factory_id,
                total_order: totalPaid,
                platform_fee: platformFee,
                payout: payoutAmount,
                bank_account: order.bank_account,
                ifsc: order.ifsc_code,
            })]
        );

        // TODO: Initiate actual Razorpay Route payout
        // await razorpayInstance.payments.transfer({ ... });

        // Notify factory
        await createNotification(
            order.owner_id,
            '💰 Payment Credited!',
            `₹${payoutAmount.toFixed(2)} payout initiated for order #${orderId.slice(0, 8)}. ` +
            `(Order: ₹${totalPaid.toFixed(2)}, Platform fee: ₹${platformFee.toFixed(2)})`,
            'payment',
            { orderId, payout: payoutAmount, platformFee }
        );

        console.log(`   💰 Payout: ₹${payoutAmount.toFixed(2)} to "${order.business_name}" for order ${orderId.slice(0, 8)}`);

        return { success: true, payout: payoutAmount, platform_fee: platformFee };
    });
}


// ═══════════════════════════════════════════════════
// 7. WEBHOOK HANDLER
// ═══════════════════════════════════════════════════
/**
 * Verify and process Razorpay webhook events
 */
function verifyWebhookSignature(body, signature) {
    if (!process.env.RAZORPAY_WEBHOOK_SECRET || process.env.RAZORPAY_WEBHOOK_SECRET === 'your_webhook_secret') {
        return true; // Skip in dev
    }

    const expected = crypto
        .createHmac('sha256', process.env.RAZORPAY_WEBHOOK_SECRET)
        .update(JSON.stringify(body))
        .digest('hex');

    return expected === signature;
}

async function handleWebhookEvent(event, payload) {
    switch (event) {
        case 'payment.authorized':
            console.log(`💳 [Webhook] Payment authorized: ${payload.payment.entity.id}`);
            break;

        case 'payment.captured':
            console.log(`✅ [Webhook] Payment captured: ${payload.payment.entity.id}`);
            // Auto-confirm the payment in our system
            const notes = payload.payment.entity.notes;
            if (notes?.order_id && notes?.type === 'advance') {
                await processAdvancePayment(
                    notes.order_id,
                    payload.payment.entity.order_id,
                    payload.payment.entity.id,
                    '' // Webhook doesn't need signature verification
                );
            }
            break;

        case 'payment.failed':
            console.log(`❌ [Webhook] Payment failed: ${payload.payment.entity.id}`);
            break;

        case 'refund.processed':
            console.log(`💸 [Webhook] Refund processed: ${payload.refund.entity.id}`);
            break;

        default:
            console.log(`📩 [Webhook] Unhandled event: ${event}`);
    }
}


module.exports = {
    initRazorpay,
    createRazorpayOrder,
    verifyPaymentSignature,
    processAdvancePayment,
    processFinalPayment,
    processRefund,
    triggerFactoryPayout,
    verifyWebhookSignature,
    handleWebhookEvent,
};
