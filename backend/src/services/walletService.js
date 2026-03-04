/**
 * Wallet Service — TRD Complete Plan Feature #12
 * 
 * Manages customer wallet for:
 * - Subscription prepayment (monthly grocery auto-debit)
 * - Refund credits (pool cancellation refunds go to wallet)
 * - Cashback rewards
 * - Order payment from wallet balance
 * 
 * TRD: "Wallet model for monthly subscription customers"
 */

const { query, transaction } = require('../database/connection');
const { createNotification } = require('./notifications');

// ═══════════════════════════════════════════════════
// GET OR CREATE WALLET
// ═══════════════════════════════════════════════════
async function getOrCreateWallet(userId) {
    // Try to get existing wallet
    let result = await query('SELECT * FROM wallets WHERE user_id = $1', [userId]);

    if (result.rows.length === 0) {
        // Create new wallet
        result = await query(
            `INSERT INTO wallets (user_id) VALUES ($1) RETURNING *`,
            [userId]
        );
    }

    return result.rows[0];
}

// ═══════════════════════════════════════════════════
// CREDIT WALLET (add money)
// ═══════════════════════════════════════════════════
/**
 * Add money to wallet
 * @param {string} userId
 * @param {number} amount — positive number
 * @param {string} source — 'refund' | 'topup' | 'cashback' | 'referral_bonus' | 'admin_adjustment'
 * @param {string} description
 * @param {string} referenceId — related order/payment ID
 */
async function creditWallet(userId, amount, source, description, referenceId = null) {
    if (amount <= 0) throw new Error('Credit amount must be positive');

    return await transaction(async (client) => {
        // Get wallet (with row lock)
        const walletResult = await client.query(
            'SELECT * FROM wallets WHERE user_id = $1 FOR UPDATE',
            [userId]
        );

        let wallet;
        if (walletResult.rows.length === 0) {
            const newWallet = await client.query(
                'INSERT INTO wallets (user_id) VALUES ($1) RETURNING *', [userId]
            );
            wallet = newWallet.rows[0];
        } else {
            wallet = walletResult.rows[0];
        }

        const newBalance = parseFloat(wallet.balance) + amount;

        // Update wallet
        await client.query(
            `UPDATE wallets SET balance = $1, total_credited = total_credited + $2, updated_at = NOW()
             WHERE id = $3`,
            [newBalance, amount, wallet.id]
        );

        // Record transaction
        const txResult = await client.query(
            `INSERT INTO wallet_transactions (wallet_id, user_id, amount, type, source, reference_id, description, balance_after)
             VALUES ($1, $2, $3, 'credit', $4, $5, $6, $7) RETURNING id`,
            [wallet.id, userId, amount, source, referenceId, description, newBalance]
        );

        // Notify user
        await createNotification(
            userId,
            '💰 Wallet Credited',
            `₹${amount.toFixed(2)} added to your wallet. Balance: ₹${newBalance.toFixed(2)}. ${description}`,
            'payment',
            { walletBalance: newBalance, amount, source, txId: txResult.rows[0].id }
        );

        return { balance: newBalance, transaction_id: txResult.rows[0].id };
    });
}


// ═══════════════════════════════════════════════════
// DEBIT WALLET (spend money)
// ═══════════════════════════════════════════════════
/**
 * Deduct money from wallet
 * @param {string} userId
 * @param {number} amount — positive number
 * @param {string} source — 'order_payment' | 'subscription_prepay'
 * @param {string} description
 * @param {string} referenceId
 */
async function debitWallet(userId, amount, source, description, referenceId = null) {
    if (amount <= 0) throw new Error('Debit amount must be positive');

    return await transaction(async (client) => {
        // Get wallet (with row lock)
        const walletResult = await client.query(
            'SELECT * FROM wallets WHERE user_id = $1 FOR UPDATE',
            [userId]
        );

        if (walletResult.rows.length === 0) {
            throw Object.assign(new Error('Wallet not found. Please add money first.'), { statusCode: 404 });
        }

        const wallet = walletResult.rows[0];
        const currentBalance = parseFloat(wallet.balance);

        if (currentBalance < amount) {
            throw Object.assign(
                new Error(`Insufficient wallet balance. Current: ₹${currentBalance.toFixed(2)}, Required: ₹${amount.toFixed(2)}`),
                { statusCode: 400 }
            );
        }

        const newBalance = currentBalance - amount;

        // Update wallet
        await client.query(
            `UPDATE wallets SET balance = $1, total_debited = total_debited + $2, updated_at = NOW()
             WHERE id = $3`,
            [newBalance, amount, wallet.id]
        );

        // Record transaction
        const txResult = await client.query(
            `INSERT INTO wallet_transactions (wallet_id, user_id, amount, type, source, reference_id, description, balance_after)
             VALUES ($1, $2, $3, 'debit', $4, $5, $6, $7) RETURNING id`,
            [wallet.id, userId, amount, source, referenceId, description, newBalance]
        );

        return { balance: newBalance, transaction_id: txResult.rows[0].id };
    });
}


// ═══════════════════════════════════════════════════
// PROCESS REFUND TO WALLET
// ═══════════════════════════════════════════════════
/**
 * Process a refund — credits the customer wallet instead of bank
 * This is faster than bank refund and encourages repeat usage
 */
async function processRefundToWallet(userId, amount, orderId) {
    return await creditWallet(
        userId,
        amount,
        'refund',
        `Refund for order #${orderId.slice(0, 8)}`,
        orderId
    );
}


module.exports = {
    getOrCreateWallet,
    creditWallet,
    debitWallet,
    processRefundToWallet,
};
