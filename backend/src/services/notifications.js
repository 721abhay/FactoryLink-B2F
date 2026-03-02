/**
 * Notification Service — TRD Section 6
 * Any event requiring customer or factory notification
 * Store notification in DB. Show in-app if push fails.
 */

const { query } = require('../database/connection');
const { sendPushNotification } = require('./firebase');

async function createNotification(userId, title, body, type = 'general', data = {}) {
    // 1. Save to database (always)
    const result = await query(
        `INSERT INTO notifications (user_id, title, body, type, data) 
     VALUES ($1, $2, $3, $4, $5) RETURNING id`,
        [userId, title, body, type, JSON.stringify(data)]
    );

    // 2. Try push notification
    const userResult = await query('SELECT fcm_token FROM users WHERE id = $1', [userId]);
    const fcmToken = userResult.rows[0]?.fcm_token;

    if (fcmToken) {
        const pushResult = await sendPushNotification(fcmToken, title, body, data);
        if (pushResult.success) {
            await query('UPDATE notifications SET pushed = true WHERE id = $1', [result.rows[0].id]);
        }
    }

    return result.rows[0].id;
}

// ─── Pre-built notification templates ────────────
const notifications = {
    orderPlaced: (userId, orderId) =>
        createNotification(userId, '🎉 Order Placed!', 'Your order has been added to the group pool. We\'ll notify you when it locks.', 'order', { orderId }),

    poolLocked: (userId, orderId) =>
        createNotification(userId, '🔒 Pool Locked!', 'Your group order has reached minimum quantity! Production will begin soon.', 'order', { orderId }),

    orderAccepted: (userId, factoryName) =>
        createNotification(userId, '✅ Order Accepted', `${factoryName} has accepted your order. Production starting soon!`, 'order'),

    orderDispatched: (userId, trackingNumber) =>
        createNotification(userId, '📦 Order Dispatched!', `Your order is on the way! Tracking: ${trackingNumber}`, 'delivery', { trackingNumber }),

    orderReady: (userId, anchorPoint) =>
        createNotification(userId, '📍 Ready for Pickup!', `Your order is ready at ${anchorPoint}. Show QR code to collect.`, 'delivery'),

    paymentReceived: (userId, amount) =>
        createNotification(userId, '💰 Payment Received', `₹${amount} payment confirmed. Thank you!`, 'payment'),

    // Factory notifications
    newOrderForFactory: (userId, productName, qty) =>
        createNotification(userId, '🆕 New Order!', `New order: ${qty}x ${productName}. Accept within 24 hours.`, 'factory_order'),

    factoryPayoutSent: (userId, amount) =>
        createNotification(userId, '💵 Payout Sent!', `₹${amount} has been transferred to your bank account.`, 'payment'),

    trustScoreUpdated: (userId, newScore) =>
        createNotification(userId, '⭐ Trust Score Updated', `Your trust score is now ${newScore}/10.`, 'trust'),
};

module.exports = { createNotification, notifications };
