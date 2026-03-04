/**
 * Matching Service — TRD Section 4: Factory Matching & Dual Backup Routing
 * 
 * Complete Plan Feature #6: Dual Factory Backup
 * "Factory A declines → Factory B gets it within 30 minutes.
 *  Customer barely notices. No order ever fails because of one factory."
 * 
 * This service:
 * 1. Finds the best factory for a given product/pool
 * 2. Implements scoring algorithm (trust score + capacity + response time)
 * 3. Handles cascade to backup factory when primary declines
 * 4. Manages factory blacklist per pool (declined factories)
 * 5. Tracks assignment history for analytics
 */

const { query, transaction } = require('../database/connection');
const { setPoolStatus, getFactoryAvailability } = require('../cache/redis');
const { createNotification } = require('./notifications');

// ═══════════════════════════════════════════════════
// FACTORY SCORING ALGORITHM
// ═══════════════════════════════════════════════════
// TRD: Weighted scoring to find best factory match
// Weights: Trust Score 40%, Capacity 25%, Response Time 20%, Distance 15%

/**
 * Score a factory for a given order
 * @returns {number} 0-100 score
 */
function scoreFactory(factory, requiredQty, zoneCity) {
    let score = 0;

    // Trust Score (40%) — scale from 0-10 to 0-40
    score += (parseFloat(factory.trust_score) || 5) * 4;

    // Capacity match (25%) — how much spare capacity vs. required qty
    const capacityRatio = Math.min(factory.capacity_per_day / Math.max(requiredQty, 1), 3);
    score += Math.min(capacityRatio * 8.33, 25);

    // Response history (20%) — based on tier
    const tierScores = { gold: 20, silver: 14, bronze: 8, new: 5 };
    score += tierScores[factory.tier] || 5;

    // Location proximity (15%) — same city bonus
    if (factory.city && zoneCity && factory.city.toLowerCase() === zoneCity.toLowerCase()) {
        score += 15;
    } else {
        score += 5; // Cross-city still gets some points
    }

    return Math.round(score * 10) / 10;
}


// ═══════════════════════════════════════════════════
// FIND BEST FACTORY — Core matching function
// ═══════════════════════════════════════════════════
/**
 * Find the best available factory for a product/pool
 * @param {string} productId - The product to match
 * @param {number} requiredQty - Required quantity
 * @param {string} zoneId - Zone for location matching
 * @param {string[]} excludeFactoryIds - Factories to skip (already declined/timed out)
 * @returns {object|null} Best matching factory or null
 */
async function findBestFactory(productId, requiredQty, zoneId, excludeFactoryIds = []) {
    // 1. Get product info and its primary factory
    const productResult = await query(
        `SELECT p.*, f.id AS primary_factory_id, f.business_name AS primary_factory_name
         FROM products p
         JOIN factories f ON p.factory_id = f.id
         WHERE p.id = $1`, [productId]
    );

    if (productResult.rows.length === 0) return null;
    const product = productResult.rows[0];

    // 2. Get zone for city matching
    const zoneResult = await query('SELECT city FROM zones WHERE id = $1', [zoneId]);
    const zoneCity = zoneResult.rows[0]?.city || '';

    // 3. Build exclude list
    const excludeList = excludeFactoryIds.length > 0
        ? excludeFactoryIds
        : ['00000000-0000-0000-0000-000000000000']; // dummy UUID so SQL doesn't break

    // 4. Find all eligible factories
    const factories = await query(
        `SELECT f.* FROM factories f
         WHERE f.verification_status = 'approved'
           AND f.availability != 'none'
           AND f.capacity_per_day >= $1
           AND f.id != ALL($2::uuid[])
           AND ($3 = ANY(f.product_categories) OR f.id = $4)
         ORDER BY f.trust_score DESC`,
        [requiredQty, excludeList, product.category, product.primary_factory_id]
    );

    if (factories.rows.length === 0) return null;

    // 5. Score each factory and sort
    const scored = factories.rows.map(f => ({
        ...f,
        match_score: scoreFactory(f, requiredQty, zoneCity),
        is_primary: f.id === product.primary_factory_id,
    }));

    // Primary factory gets a 10-point bonus
    scored.forEach(f => { if (f.is_primary) f.match_score += 10; });

    scored.sort((a, b) => b.match_score - a.match_score);

    return scored[0];
}


// ═══════════════════════════════════════════════════
// ASSIGN POOL TO FACTORY — With cascade support
// ═══════════════════════════════════════════════════
/**
 * Assign a pool to the best factory, cascading if one declines
 * @returns {{ success: boolean, factory?: object, message?: string }}
 */
async function assignPoolToFactory(poolId, excludeFactoryIds = []) {
    return await transaction(async (client) => {
        // 1. Get pool details
        const poolResult = await client.query(
            `SELECT p.*, pr.name AS product_name, pr.category, z.city AS zone_city
             FROM pools p
             JOIN products pr ON p.product_id = pr.id
             JOIN zones z ON p.zone_id = z.id
             WHERE p.id = $1`, [poolId]
        );

        if (poolResult.rows.length === 0) {
            return { success: false, message: 'Pool not found' };
        }
        const pool = poolResult.rows[0];

        // 2. Find best factory
        const factory = await findBestFactory(
            pool.product_id,
            pool.current_qty,
            pool.zone_id,
            excludeFactoryIds
        );

        if (!factory) {
            return { success: false, message: 'No eligible factory found' };
        }

        // 3. Get factory owner user ID for notifications
        const ownerResult = await client.query(
            'SELECT id FROM users WHERE id = $1', [factory.owner_id]
        );
        const factoryOwnerId = ownerResult.rows[0]?.id;

        // 4. Assign factory to pool
        await client.query(
            `UPDATE pools SET factory_id = $1, status = 'assigned', updated_at = NOW() WHERE id = $2`,
            [factory.id, poolId]
        );
        await setPoolStatus(poolId, 'assigned');

        // 5. Update all orders in pool to 'assigned'
        await client.query(
            `UPDATE orders SET status = 'assigned', updated_at = NOW()
             WHERE pool_id = $1 AND status IN ('pending', 'pooled', 'locked')`,
            [poolId]
        );

        // 6. Record assignment in history
        await client.query(
            `INSERT INTO pool_assignments (pool_id, factory_id, match_score, is_primary)
             VALUES ($1, $2, $3, $4)
             ON CONFLICT DO NOTHING`,
            [poolId, factory.id, factory.match_score, factory.is_primary]
        );

        // 7. Notify factory owner
        if (factoryOwnerId) {
            await createNotification(
                factoryOwnerId,
                '📦 New Bulk Order!',
                `${pool.current_qty}x ${pool.product_name} awaits you. ` +
                `Score: ${factory.match_score}/110. Accept within 2 hours.`,
                'factory_order',
                { poolId, qty: pool.current_qty, product: pool.product_name, score: factory.match_score }
            );
        }

        // 8. Notify all customers
        const customers = await client.query(
            'SELECT DISTINCT user_id FROM orders WHERE pool_id = $1', [poolId]
        );
        for (const c of customers.rows) {
            await createNotification(
                c.user_id,
                '🏭 Factory Found!',
                `${factory.business_name} has been matched to produce your ${pool.product_name}. They'll respond within 2 hours.`,
                'order',
                { poolId, factoryName: factory.business_name }
            );
        }

        console.log(`   🏭 Pool ${poolId.slice(0, 8)}: assigned to "${factory.business_name}" (score: ${factory.match_score})`);

        return {
            success: true,
            factory: {
                id: factory.id,
                name: factory.business_name,
                score: factory.match_score,
                is_primary: factory.is_primary,
            },
        };
    });
}


// ═══════════════════════════════════════════════════
// HANDLE FACTORY DECLINE — Cascade to next factory
// ═══════════════════════════════════════════════════
/**
 * When a factory declines, penalize them and find the next best factory
 * TRD T04: "Factory declines → cascade to next factory"
 */
async function handleFactoryDecline(poolId, decliningFactoryId) {
    return await transaction(async (client) => {
        // 1. Get current pool
        const poolResult = await client.query(
            `SELECT p.*, pr.name AS product_name FROM pools p
             JOIN products pr ON p.product_id = pr.id
             WHERE p.id = $1`, [poolId]
        );
        if (poolResult.rows.length === 0) {
            return { success: false, message: 'Pool not found' };
        }
        const pool = poolResult.rows[0];

        // 2. Record the decline
        await client.query(
            `UPDATE pool_assignments SET status = 'declined', responded_at = NOW()
             WHERE pool_id = $1 AND factory_id = $2`,
            [poolId, decliningFactoryId]
        );

        // 3. Apply trust score penalty (0.3 per decline)
        await client.query(
            `UPDATE factories SET trust_score = GREATEST(trust_score - 0.3, 0)
             WHERE id = $1`,
            [decliningFactoryId]
        );

        // 4. Get all factories that have declined this pool
        const declinedResult = await client.query(
            `SELECT factory_id FROM pool_assignments
             WHERE pool_id = $1 AND status = 'declined'`,
            [poolId]
        );
        const excludeIds = declinedResult.rows.map(r => r.factory_id);

        // 5. Reset pool status to locked for reassignment
        await client.query(
            `UPDATE pools SET factory_id = NULL, status = 'locked', updated_at = NOW()
             WHERE id = $1`,
            [poolId]
        );
        await setPoolStatus(poolId, 'locked');

        // 6. Update orders back to locked
        await client.query(
            `UPDATE orders SET status = 'locked', updated_at = NOW()
             WHERE pool_id = $1 AND status = 'assigned'`,
            [poolId]
        );

        // 7. Try to find next factory
        // We call assignPoolToFactory which will exclude declined ones
        const result = await assignPoolToFactory(poolId, excludeIds);

        if (!result.success) {
            // No backup factory available — notify customers
            const customers = await client.query(
                'SELECT DISTINCT user_id FROM orders WHERE pool_id = $1', [poolId]
            );

            for (const c of customers.rows) {
                await createNotification(
                    c.user_id,
                    '🔄 Finding New Factory',
                    `The original factory for ${pool.product_name} couldn't fulfill your order. ` +
                    `We're searching for a replacement. You'll be notified when one is found.`,
                    'order',
                    { poolId, type: 'factory_declined' }
                );
            }
        }

        return {
            success: true,
            rerouted: result.success,
            new_factory: result.factory || null,
            message: result.success
                ? `Rerouted to ${result.factory.name}`
                : 'No backup factory available yet. Will retry in next cron cycle.',
        };
    });
}


module.exports = {
    scoreFactory,
    findBestFactory,
    assignPoolToFactory,
    handleFactoryDecline,
};
