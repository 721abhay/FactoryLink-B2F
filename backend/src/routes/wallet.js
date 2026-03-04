/**
 * Wallet Routes — Complete Plan Feature #12
 * GET  /wallet              — Get wallet balance
 * POST /wallet/topup        — Add money to wallet
 * GET  /wallet/transactions — Transaction history
 */

const router = require('express').Router();
const { query } = require('../database/connection');
const { authenticate } = require('../middleware/auth');
const { getOrCreateWallet, creditWallet, debitWallet } = require('../services/walletService');

// ─── GET /wallet — Get balance and summary ───────
router.get('/', authenticate('customer'), async (req, res, next) => {
    try {
        const wallet = await getOrCreateWallet(req.user.userId);

        // Get last 5 transactions
        const recent = await query(
            `SELECT * FROM wallet_transactions
             WHERE user_id = $1
             ORDER BY created_at DESC LIMIT 5`,
            [req.user.userId]
        );

        res.json({
            success: true,
            wallet: {
                balance: parseFloat(wallet.balance),
                total_credited: parseFloat(wallet.total_credited),
                total_debited: parseFloat(wallet.total_debited),
                created_at: wallet.created_at,
            },
            recent_transactions: recent.rows.map(t => ({
                id: t.id,
                amount: parseFloat(t.amount),
                type: t.type,
                source: t.source,
                description: t.description,
                balance_after: parseFloat(t.balance_after),
                created_at: t.created_at,
            })),
        });
    } catch (err) { next(err); }
});

// ─── POST /wallet/topup — Add money ─────────────
router.post('/topup', authenticate('customer'), async (req, res, next) => {
    try {
        const { amount } = req.body;

        if (!amount || amount < 10) {
            return res.status(400).json({
                error: 'Invalid amount',
                message: 'Minimum top-up is ₹10.',
            });
        }

        if (amount > 50000) {
            return res.status(400).json({
                error: 'Invalid amount',
                message: 'Maximum top-up is ₹50,000.',
            });
        }

        // TODO: Integrate Razorpay for actual payment processing
        // For now, we credit directly (simulating successful payment)

        const result = await creditWallet(
            req.user.userId,
            parseFloat(amount),
            'topup',
            `Wallet top-up of ₹${amount}`
        );

        res.json({
            success: true,
            new_balance: result.balance,
            transaction_id: result.transaction_id,
            message: `₹${amount} added to wallet.`,
        });
    } catch (err) { next(err); }
});

// ─── GET /wallet/transactions — Full history ─────
router.get('/transactions', authenticate('customer'), async (req, res, next) => {
    try {
        const { page = 1, limit = 20, type } = req.query;
        const offset = (page - 1) * limit;

        let sql = `SELECT * FROM wallet_transactions WHERE user_id = $1`;
        const params = [req.user.userId];

        if (type && ['credit', 'debit'].includes(type)) {
            sql += ` AND type = $2`;
            params.push(type);
        }

        sql += ` ORDER BY created_at DESC LIMIT $${params.length + 1} OFFSET $${params.length + 2}`;
        params.push(parseInt(limit), parseInt(offset));

        const result = await query(sql, params);

        res.json({
            success: true,
            transactions: result.rows.map(t => ({
                id: t.id,
                amount: parseFloat(t.amount),
                type: t.type,
                source: t.source,
                description: t.description,
                balance_after: parseFloat(t.balance_after),
                reference_id: t.reference_id,
                created_at: t.created_at,
            })),
        });
    } catch (err) { next(err); }
});

module.exports = router;
