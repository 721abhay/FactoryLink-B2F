/**
 * Subscription Fulfillment Service — TRD Subscription Support
 * 
 * Complete Plan Feature #12: "Grocery subscription model"
 * - Monthly/weekly recurring orders auto-created from subscriptions
 * - Payment auto-debited from customer wallet
 * - Orders automatically join pools in the customer's zone
 * - Runs as a cron job daily to check for due subscriptions
 */

const { query, transaction } = require('../database/connection');
const { debitWallet, getOrCreateWallet } = require('./walletService');
const { createNotification } = require('./notifications');

// ═══════════════════════════════════════════════════
// PROCESS DUE SUBSCRIPTIONS — Daily Cron
// ═══════════════════════════════════════════════════
async function processDueSubscriptions() {
    console.log('📦 [Subscription] Checking for due deliveries...');

    try {
        // Find active subscriptions where next_delivery_date is today or past
        const due = await query(`
            SELECT s.*, p.name AS product_name, p.tier1_price, p.factory_id, p.category,
                   u.zone_id, u.name AS user_name
            FROM subscriptions s
            JOIN products p ON s.product_id = p.id
            JOIN users u ON s.user_id = u.id
            WHERE s.status = 'active'
              AND s.next_delivery_date <= CURRENT_DATE
        `);

        if (due.rows.length === 0) {
            console.log('   ✅ No subscriptions due today.');
            return { processed: 0 };
        }

        console.log(`   🔄 Found ${due.rows.length} subscription(s) due for fulfillment.`);

        let processedCount = 0;
        let failedCount = 0;

        for (const sub of due.rows) {
            try {
                await fulfillSubscription(sub);
                processedCount++;
            } catch (err) {
                console.error(`   ❌ Sub ${sub.id.slice(0, 8)} failed:`, err.message);
                failedCount++;
            }
        }

        console.log(`   ✅ Processed ${processedCount} subscriptions, ${failedCount} failed.`);
        return { processed: processedCount, failed: failedCount };
    } catch (err) {
        console.error('❌ [Subscription] processDueSubscriptions error:', err.message);
        throw err;
    }
}


async function fulfillSubscription(sub) {
    return await transaction(async (client) => {
        const unitPrice = parseFloat(sub.tier1_price);
        const totalAmount = unitPrice * sub.qty;
        const advanceAmount = totalAmount * 0.3; // 30% advance

        // 1. Check if customer has sufficient wallet balance
        const wallet = await getOrCreateWallet(sub.user_id);
        const walletBalance = parseFloat(wallet.balance);

        if (walletBalance < advanceAmount) {
            // Insufficient funds — notify customer, don't process
            await createNotification(
                sub.user_id,
                '💳 Subscription Payment Failed',
                `Your subscription for ${sub.product_name} couldn't be fulfilled. ` +
                `Required: ₹${advanceAmount.toFixed(2)}, Wallet: ₹${walletBalance.toFixed(2)}. ` +
                `Please top up your wallet.`,
                'payment',
                { subscriptionId: sub.id, shortfall: advanceAmount - walletBalance }
            );
            return;
        }

        // 2. Find or create an open pool for this product in the user's zone
        let poolResult = await client.query(
            `SELECT id FROM pools
             WHERE product_id = $1 AND zone_id = $2 AND status = 'open' AND timer_end > NOW()
             LIMIT 1`,
            [sub.product_id, sub.zone_id]
        );

        let poolId;
        if (poolResult.rows.length > 0) {
            poolId = poolResult.rows[0].id;
        } else {
            // Create a new pool
            const newPool = await client.query(
                `INSERT INTO pools (product_id, zone_id, current_qty, min_qty, timer_end)
                 VALUES ($1, $2, 0, 10, NOW() + INTERVAL '48 hours') RETURNING id`,
                [sub.product_id, sub.zone_id]
            );
            poolId = newPool.rows[0].id;
        }

        // 3. Create order
        const orderResult = await client.query(
            `INSERT INTO orders (user_id, pool_id, product_id, qty, unit_price, total_amount,
                                 advance_amount, final_amount, anchor_point_id, status)
             VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, 'pooled')
             RETURNING id`,
            [sub.user_id, poolId, sub.product_id, sub.qty, unitPrice, totalAmount,
                advanceAmount, totalAmount - advanceAmount, sub.anchor_point_id]
        );
        const orderId = orderResult.rows[0].id;

        // 4. Update pool quantity
        await client.query(
            `UPDATE pools SET current_qty = current_qty + $1, updated_at = NOW() WHERE id = $2`,
            [sub.qty, poolId]
        );

        // 5. Debit wallet for advance payment
        await debitWallet(
            sub.user_id,
            advanceAmount,
            'subscription_prepay',
            `Subscription: ${sub.qty}x ${sub.product_name}`,
            orderId
        );

        // 6. Mark advance as paid
        await client.query(
            `UPDATE orders SET advance_paid = true WHERE id = $1`,
            [orderId]
        );

        // 7. Record payment
        await client.query(
            `INSERT INTO payments (order_id, user_id, amount, type, status)
             VALUES ($1, $2, $3, 'advance', 'completed')`,
            [orderId, sub.user_id, advanceAmount]
        );

        // 8. Update subscription next delivery date
        let nextDate = new Date(sub.next_delivery_date);
        if (sub.frequency === 'weekly') nextDate.setDate(nextDate.getDate() + 7);
        else if (sub.frequency === 'biweekly') nextDate.setDate(nextDate.getDate() + 14);
        else nextDate.setMonth(nextDate.getMonth() + 1);

        // Check if subscription has expired
        const subAge = Math.floor((nextDate - new Date(sub.created_at)) / (30 * 24 * 60 * 60 * 1000));
        if (subAge >= sub.duration_months) {
            // Subscription completed
            await client.query(
                `UPDATE subscriptions SET status = 'completed', updated_at = NOW() WHERE id = $1`,
                [sub.id]
            );

            await createNotification(
                sub.user_id,
                '🎉 Subscription Completed',
                `Your ${sub.duration_months}-month subscription for ${sub.product_name} is complete! ` +
                `Renew anytime for continued savings.`,
                'subscription',
                { subscriptionId: sub.id }
            );
        } else {
            await client.query(
                `UPDATE subscriptions SET next_delivery_date = $1, updated_at = NOW() WHERE id = $2`,
                [nextDate, sub.id]
            );
        }

        // 9. Check if pool should lock
        const poolCheck = await client.query(
            'SELECT current_qty, min_qty FROM pools WHERE id = $1', [poolId]
        );
        if (poolCheck.rows.length > 0) {
            const pool = poolCheck.rows[0];
            if (pool.current_qty >= pool.min_qty) {
                await client.query(
                    `UPDATE pools SET status = 'locked', locked_at = NOW(), updated_at = NOW() WHERE id = $1`,
                    [poolId]
                );
            }
        }

        // 10. Notify customer
        await createNotification(
            sub.user_id,
            '📦 Subscription Order Placed',
            `Auto-order: ${sub.qty}x ${sub.product_name} placed. ₹${advanceAmount.toFixed(2)} debited from wallet.`,
            'order',
            { orderId, subscriptionId: sub.id, poolId }
        );

        console.log(`   📦 Sub ${sub.id.slice(0, 8)}: order created for "${sub.product_name}" (₹${advanceAmount} from wallet)`);
    });
}


module.exports = { processDueSubscriptions };
