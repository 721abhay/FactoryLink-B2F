/**
 * Pool Engine — The Brain of FactoryLink Group Buying
 * 
 * TRD: Order joins pool, pool locks, timer expires
 * Complete Plan: Feature #1 Smart Zone Fill, Feature #6 Dual Factory Backup
 * 
 * This service handles:
 * 1. Pool timer expiry — auto-cancel expired pools, refund all customers
 * 2. Pool locking — when min_qty reached, lock pool and assign to factory
 * 3. Factory assignment — route locked pools to best available factory
 * 4. Dual factory backup — if Factory A declines/times out, route to Factory B
 * 5. Zone health recalculation — hourly cron job
 * 6. Factory response timeout — 2-hour window to accept/decline
 */

const { query, transaction } = require('../database/connection');
const { setPoolStatus, getPoolStatus, setZoneHealth } = require('../cache/redis');
const { notifications, createNotification } = require('./notifications');

// ═══════════════════════════════════════════════════
// 1. PROCESS EXPIRED POOLS — Runs every 5 minutes
// ═══════════════════════════════════════════════════
// TRD T03: Timer expires with only 10 of 25 orders in pool
// → All orders cancelled. Full advance refund within 2 hours.
async function processExpiredPools() {
    console.log('⏱️  [Pool Engine] Checking for expired pools...');

    try {
        // Find all open pools where timer has expired
        const expired = await query(`
            SELECT p.*, pr.name AS product_name, pr.factory_id
            FROM pools p
            JOIN products pr ON p.product_id = pr.id
            WHERE p.status = 'open' AND p.timer_end < NOW()
        `);

        if (expired.rows.length === 0) {
            console.log('   ✅ No expired pools found.');
            return { processed: 0 };
        }

        console.log(`   🔄 Found ${expired.rows.length} expired pool(s) to process.`);

        let cancelledCount = 0;
        let refundedOrders = 0;

        for (const pool of expired.rows) {
            try {
                const result = await cancelExpiredPool(pool);
                cancelledCount++;
                refundedOrders += result.refundedOrders;
            } catch (err) {
                console.error(`   ❌ Failed to cancel pool ${pool.id}:`, err.message);
            }
        }

        console.log(`   ✅ Cancelled ${cancelledCount} pools, refunded ${refundedOrders} orders.`);
        return { processed: cancelledCount, refunded: refundedOrders };
    } catch (err) {
        console.error('❌ [Pool Engine] processExpiredPools error:', err.message);
        throw err;
    }
}

// Cancel a single expired pool and refund all orders
async function cancelExpiredPool(pool) {
    return await transaction(async (client) => {
        // 1. Mark pool as cancelled
        await client.query(
            `UPDATE pools SET status = 'cancelled', updated_at = NOW() WHERE id = $1`,
            [pool.id]
        );
        await setPoolStatus(pool.id, 'cancelled');

        // 2. Get all orders in this pool
        const orders = await client.query(
            `SELECT o.id, o.user_id, o.advance_amount, o.advance_paid, o.total_amount
             FROM orders o WHERE o.pool_id = $1 AND o.status NOT IN ('cancelled', 'refunded')`,
            [pool.id]
        );

        let refundedOrders = 0;

        for (const order of orders.rows) {
            // 3. Cancel the order
            await client.query(
                `UPDATE orders SET status = 'cancelled', updated_at = NOW() WHERE id = $1`,
                [order.id]
            );

            // 4. Create refund record if advance was paid
            if (order.advance_paid) {
                await client.query(
                    `INSERT INTO payments (order_id, user_id, amount, type, status)
                     VALUES ($1, $2, $3, 'refund', 'pending')`,
                    [order.id, order.user_id, order.advance_amount]
                );

                // TODO: Trigger actual Razorpay refund
                // await razorpay.payments.refund(gatewayPaymentId, { amount: advance * 100 });
            }

            // 5. Notify customer
            await createNotification(
                order.user_id,
                '⏰ Group Order Expired',
                `The group order for ${pool.product_name} didn't reach the minimum quantity in time. ` +
                (order.advance_paid ? 'Your advance payment will be refunded within 2 hours.' : 'No payment was charged.'),
                'order',
                { orderId: order.id, poolId: pool.id, type: 'pool_expired' }
            );

            refundedOrders++;
        }

        console.log(`   📦 Pool ${pool.id.slice(0, 8)}: cancelled ${refundedOrders} orders for "${pool.product_name}"`);
        return { refundedOrders };
    });
}


// ═══════════════════════════════════════════════════
// 2. PROCESS LOCKED POOLS — Assign to factory
// ═══════════════════════════════════════════════════
// TRD: When pool reaches min_qty → lock → assign to factory
// Complete Plan Feature #6: Dual factory backup routing
async function processLockedPools() {
    console.log('🔒 [Pool Engine] Processing locked pools for factory assignment...');

    try {
        // Find locked pools that don't have a factory assigned yet
        const locked = await query(`
            SELECT p.*, pr.name AS product_name, pr.factory_id AS primary_factory_id,
                   pr.category, f.business_name AS factory_name, f.availability,
                   f.trust_score, f.capacity_per_day, f.min_order_qty
            FROM pools p
            JOIN products pr ON p.product_id = pr.id
            JOIN factories f ON pr.factory_id = f.id
            WHERE p.status = 'locked' AND p.factory_id IS NULL
        `);

        if (locked.rows.length === 0) {
            console.log('   ✅ No unassigned locked pools.');
            return { assigned: 0 };
        }

        console.log(`   🔄 Found ${locked.rows.length} locked pool(s) to assign.`);

        let assignedCount = 0;

        for (const pool of locked.rows) {
            try {
                await assignPoolToFactory(pool);
                assignedCount++;
            } catch (err) {
                console.error(`   ❌ Failed to assign pool ${pool.id}:`, err.message);
            }
        }

        console.log(`   ✅ Assigned ${assignedCount} pools to factories.`);
        return { assigned: assignedCount };
    } catch (err) {
        console.error('❌ [Pool Engine] processLockedPools error:', err.message);
        throw err;
    }
}

// Assign a locked pool to the best available factory
async function assignPoolToFactory(pool) {
    return await transaction(async (client) => {
        // 1. Try primary factory first (the one that owns the product)
        const primaryFactory = await client.query(
            `SELECT f.*, u.id AS owner_user_id FROM factories f
             JOIN users u ON f.owner_id = u.id
             WHERE f.id = $1 AND f.verification_status = 'approved'
               AND f.availability != 'none'
               AND f.capacity_per_day >= $2`,
            [pool.primary_factory_id, pool.current_qty]
        );

        let assignedFactory = null;

        if (primaryFactory.rows.length > 0) {
            assignedFactory = primaryFactory.rows[0];
        } else {
            // 2. Find backup factory — Dual Factory Routing (Complete Plan Feature #6)
            // Look for another factory with same product category, good trust score, available
            const backupFactory = await client.query(
                `SELECT f.*, u.id AS owner_user_id FROM factories f
                 JOIN users u ON f.owner_id = u.id
                 WHERE f.id != $1
                   AND f.verification_status = 'approved'
                   AND f.availability != 'none'
                   AND f.capacity_per_day >= $2
                   AND $3 = ANY(f.product_categories)
                 ORDER BY f.trust_score DESC, f.capacity_per_day DESC
                 LIMIT 1`,
                [pool.primary_factory_id, pool.current_qty, pool.category]
            );

            if (backupFactory.rows.length > 0) {
                assignedFactory = backupFactory.rows[0];
                console.log(`   🔄 Primary factory unavailable for pool ${pool.id.slice(0, 8)}, using backup: ${assignedFactory.business_name}`);
            }
        }

        if (!assignedFactory) {
            console.log(`   ⚠️ No factory available for pool ${pool.id.slice(0, 8)} (${pool.product_name})`);
            return;
        }

        // 3. Assign factory to pool
        await client.query(
            `UPDATE pools SET factory_id = $1, status = 'assigned', updated_at = NOW() WHERE id = $2`,
            [assignedFactory.id, pool.id]
        );
        await setPoolStatus(pool.id, 'assigned');

        // 4. Update all orders in pool to 'assigned' status
        await client.query(
            `UPDATE orders SET status = 'assigned', updated_at = NOW()
             WHERE pool_id = $1 AND status IN ('pending', 'pooled', 'locked')`,
            [pool.id]
        );

        // 5. Notify factory owner about the new bulk order
        await createNotification(
            assignedFactory.owner_user_id,
            '🆕 New Bulk Order!',
            `New order: ${pool.current_qty}x ${pool.product_name}. ` +
            `Total value waiting. Accept within 2 hours to begin production.`,
            'factory_order',
            { poolId: pool.id, qty: pool.current_qty, product: pool.product_name }
        );

        // 6. Record the assignment timestamp for the 2-hour response window
        await client.query(
            `UPDATE pools SET updated_at = NOW() WHERE id = $1`,
            [pool.id]
        );

        // 7. Notify all customers that their pool has been assigned
        const customerOrders = await client.query(
            `SELECT DISTINCT user_id FROM orders WHERE pool_id = $1`,
            [pool.id]
        );

        for (const row of customerOrders.rows) {
            await notifications.poolLocked(row.user_id, pool.id);
        }

        console.log(`   ✅ Pool ${pool.id.slice(0, 8)}: assigned to "${assignedFactory.business_name}" (${pool.current_qty} units)`);
    });
}


// ═══════════════════════════════════════════════════
// 3. HANDLE FACTORY RESPONSE TIMEOUT — 2-hour window
// ═══════════════════════════════════════════════════
// TRD T04: Factory assigned to order — does not respond in 2 hours
// → Order automatically routed to second-ranked factory. Penalty applied.
async function processFactoryTimeouts() {
    console.log('⏳ [Pool Engine] Checking for factory response timeouts...');

    try {
        // Find assigned pools where factory hasn't responded in 2 hours
        const timedOut = await query(`
            SELECT p.*, pr.name AS product_name, pr.category,
                   f.id AS factory_id, f.business_name, f.owner_id AS factory_owner_id
            FROM pools p
            JOIN products pr ON p.product_id = pr.id
            JOIN factories f ON p.factory_id = f.id
            WHERE p.status = 'assigned'
              AND p.updated_at < NOW() - INTERVAL '2 hours'
        `);

        if (timedOut.rows.length === 0) {
            console.log('   ✅ No factory timeouts.');
            return { rerouted: 0 };
        }

        console.log(`   🔄 Found ${timedOut.rows.length} timed-out assignment(s).`);

        let reroutedCount = 0;

        for (const pool of timedOut.rows) {
            try {
                await rerouteTimedOutPool(pool);
                reroutedCount++;
            } catch (err) {
                console.error(`   ❌ Failed to reroute pool ${pool.id}:`, err.message);
            }
        }

        console.log(`   ✅ Rerouted ${reroutedCount} pools.`);
        return { rerouted: reroutedCount };
    } catch (err) {
        console.error('❌ [Pool Engine] processFactoryTimeouts error:', err.message);
        throw err;
    }
}

async function rerouteTimedOutPool(pool) {
    return await transaction(async (client) => {
        // 1. Penalize the non-responsive factory (reduce trust score)
        await client.query(
            `UPDATE factories SET trust_score = GREATEST(trust_score - 0.5, 0)
             WHERE id = $1`,
            [pool.factory_id]
        );

        // Notify factory about the penalty
        await createNotification(
            pool.factory_owner_id,
            '⚠️ Response Timeout',
            `You didn't respond to the order for ${pool.product_name} within 2 hours. ` +
            `The order has been reassigned. Your trust score has been reduced by 0.5.`,
            'warning',
            { poolId: pool.id }
        );

        // 2. Find another factory (dual backup routing)
        const backupFactory = await client.query(
            `SELECT f.*, u.id AS owner_user_id FROM factories f
             JOIN users u ON f.owner_id = u.id
             WHERE f.id != $1
               AND f.verification_status = 'approved'
               AND f.availability != 'none'
               AND f.capacity_per_day >= $2
               AND $3 = ANY(f.product_categories)
             ORDER BY f.trust_score DESC
             LIMIT 1`,
            [pool.factory_id, pool.current_qty, pool.category]
        );

        if (backupFactory.rows.length > 0) {
            const backup = backupFactory.rows[0];

            // 3. Reassign pool to backup factory
            await client.query(
                `UPDATE pools SET factory_id = $1, status = 'assigned', updated_at = NOW() WHERE id = $2`,
                [backup.id, pool.id]
            );

            // 4. Notify backup factory
            await createNotification(
                backup.owner_user_id,
                '🆕 Reassigned Order!',
                `${pool.current_qty}x ${pool.product_name} needs a factory. Accept within 2 hours.`,
                'factory_order',
                { poolId: pool.id }
            );

            console.log(`   🔄 Pool ${pool.id.slice(0, 8)}: rerouted from "${pool.business_name}" to "${backup.business_name}"`);
        } else {
            // No backup available — cancel pool and refund
            console.log(`   ⚠️ No backup factory for pool ${pool.id.slice(0, 8)}, cancelling...`);

            await client.query(
                `UPDATE pools SET status = 'cancelled', updated_at = NOW() WHERE id = $1`,
                [pool.id]
            );
            await setPoolStatus(pool.id, 'cancelled');

            // Cancel all orders and refund
            const orders = await client.query(
                `SELECT id, user_id, advance_amount, advance_paid FROM orders
                 WHERE pool_id = $1 AND status NOT IN ('cancelled', 'refunded')`,
                [pool.id]
            );

            for (const order of orders.rows) {
                await client.query(
                    `UPDATE orders SET status = 'cancelled', updated_at = NOW() WHERE id = $1`,
                    [order.id]
                );

                if (order.advance_paid) {
                    await client.query(
                        `INSERT INTO payments (order_id, user_id, amount, type, status)
                         VALUES ($1, $2, $3, 'refund', 'pending')`,
                        [order.id, order.user_id, order.advance_amount]
                    );
                }

                await createNotification(
                    order.user_id,
                    '😔 Order Cancelled',
                    `Unfortunately, no factory could fulfill the order for ${pool.product_name}. ` +
                    (order.advance_paid ? 'Your advance will be refunded within 2 hours.' : ''),
                    'order',
                    { orderId: order.id, type: 'no_factory' }
                );
            }
        }
    });
}


// ═══════════════════════════════════════════════════
// 4. UPDATE ZONE HEALTH — Hourly cron
// ═══════════════════════════════════════════════════
// TRD: Zone Service — Cron job every hour
// Complete Plan Feature #5: Zone Health Dashboard
async function updateZoneHealth() {
    console.log('🗺️  [Pool Engine] Updating zone health scores...');

    try {
        const zones = await query(`SELECT id, city, name FROM zones WHERE status = 'active'`);

        for (const zone of zones.rows) {
            // Calculate health based on:
            // - Number of active orders in last 7 days
            // - Number of active users
            // - Pool fill rate (how often pools reach minimum)
            const stats = await query(`
                SELECT
                    COALESCE(COUNT(DISTINCT o.id), 0) AS order_count,
                    COALESCE(COUNT(DISTINCT o.user_id), 0) AS active_users,
                    COALESCE(AVG(CASE WHEN p.status IN ('locked', 'assigned', 'production', 'completed')
                        THEN p.current_qty::float / NULLIF(p.min_qty, 0) ELSE 0 END), 0) AS avg_fill_rate
                FROM zones z
                LEFT JOIN pools p ON p.zone_id = z.id AND p.created_at > NOW() - INTERVAL '7 days'
                LEFT JOIN orders o ON o.pool_id = p.id AND o.created_at > NOW() - INTERVAL '7 days'
                WHERE z.id = $1
            `, [zone.id]);

            const s = stats.rows[0];
            // Health formula: scale 0-10
            const orderScore = Math.min(s.order_count / 5, 1) * 3;    // 0-3 pts (orders)
            const userScore = Math.min(s.active_users / 3, 1) * 3;    // 0-3 pts (users)
            const fillScore = Math.min(s.avg_fill_rate, 1) * 4;       // 0-4 pts (fill rate)
            const health = Math.round((orderScore + userScore + fillScore) * 10) / 10;

            await query(
                `UPDATE zones SET health_score = $1, total_orders = $2, total_users = $3, updated_at = NOW()
                 WHERE id = $4`,
                [health, s.order_count, s.active_users, zone.id]
            );
            await setZoneHealth(zone.id, health);
        }

        // TRD T09: Zone health drops below 0.4 for 2 consecutive weeks → merge
        const weakZones = await query(`
            SELECT id, name, city FROM zones
            WHERE status = 'active' AND health_score < 4.0
              AND updated_at < NOW() - INTERVAL '14 days'
        `);

        if (weakZones.rows.length > 0) {
            console.log(`   ⚠️ ${weakZones.rows.length} zone(s) with low health — consider merging.`);
            // TODO: Auto-merge logic with customer notification
        }

        console.log(`   ✅ Updated health for ${zones.rows.length} zones.`);
        return { updated: zones.rows.length };
    } catch (err) {
        console.error('❌ [Pool Engine] updateZoneHealth error:', err.message);
        throw err;
    }
}


// ═══════════════════════════════════════════════════
// 5. AUTO-COMPLETE STALE ORDERS — Daily
// ═══════════════════════════════════════════════════
// TRD C10: If not rated in 24 hours order auto-completes with neutral score
async function autoCompleteStaleOrders() {
    console.log('📋 [Pool Engine] Auto-completing stale collected orders...');

    try {
        const stale = await query(`
            UPDATE orders SET status = 'completed', updated_at = NOW()
            WHERE status = 'collected'
              AND collected_at < NOW() - INTERVAL '24 hours'
            RETURNING id, user_id, product_id
        `);

        if (stale.rows.length > 0) {
            console.log(`   ✅ Auto-completed ${stale.rows.length} order(s).`);

            // Create neutral ratings for unrated orders
            for (const order of stale.rows) {
                const existing = await query(
                    'SELECT id FROM ratings WHERE order_id = $1', [order.id]
                );

                if (existing.rows.length === 0) {
                    // Get factory_id
                    const product = await query(
                        'SELECT factory_id FROM products WHERE id = $1', [order.product_id]
                    );

                    if (product.rows.length > 0) {
                        await query(
                            `INSERT INTO ratings (order_id, factory_id, user_id, stars, review)
                             VALUES ($1, $2, $3, 3, 'Auto-completed — no review submitted')`,
                            [order.id, product.rows[0].factory_id, order.user_id]
                        );
                    }
                }
            }
        } else {
            console.log('   ✅ No stale orders to process.');
        }

        return { completed: stale.rows.length };
    } catch (err) {
        console.error('❌ [Pool Engine] autoCompleteStaleOrders error:', err.message);
        throw err;
    }
}


// ═══════════════════════════════════════════════════
// 6. POOL STATISTICS — For monitoring
// ═══════════════════════════════════════════════════
async function getPoolStats() {
    const stats = await query(`
        SELECT
            COUNT(*) FILTER (WHERE status = 'open') AS open_pools,
            COUNT(*) FILTER (WHERE status = 'locked') AS locked_pools,
            COUNT(*) FILTER (WHERE status = 'assigned') AS assigned_pools,
            COUNT(*) FILTER (WHERE status = 'production') AS production_pools,
            COUNT(*) FILTER (WHERE status = 'cancelled') AS cancelled_pools,
            COUNT(*) FILTER (WHERE status = 'completed') AS completed_pools,
            COUNT(*) AS total_pools
        FROM pools
        WHERE created_at > NOW() - INTERVAL '7 days'
    `);

    return stats.rows[0];
}


module.exports = {
    processExpiredPools,
    processLockedPools,
    processFactoryTimeouts,
    updateZoneHealth,
    autoCompleteStaleOrders,
    getPoolStats,
};
