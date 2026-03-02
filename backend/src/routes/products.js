/**
 * Product Routes — TRD Section 4: Customer APIs
 * GET  /products       — List products with zone progress
 * GET  /products/:id   — Single product detail with price breakdown
 */

const router = require('express').Router();
const { query } = require('../database/connection');
const { authenticate } = require('../middleware/auth');
const { getPoolCount, getPoolStatus } = require('../cache/redis');

// ─── GET /products ───────────────────────────────
// TRD: List products with zone progress and timer for customer zone
router.get('/', authenticate('customer'), async (req, res, next) => {
    try {
        const { category, search, page = 1, limit = 20 } = req.query;
        const offset = (page - 1) * limit;

        let sql = `
      SELECT p.*, f.business_name AS factory_name, f.trust_score, f.tier AS factory_tier,
             f.city AS factory_city
      FROM products p
      JOIN factories f ON p.factory_id = f.id
      WHERE p.is_active = true AND f.verification_status = 'approved'
    `;
        const params = [];
        let paramIdx = 1;

        if (category) {
            sql += ` AND p.category = $${paramIdx++}`;
            params.push(category);
        }
        if (search) {
            sql += ` AND (p.name ILIKE $${paramIdx} OR p.description ILIKE $${paramIdx})`;
            params.push(`%${search}%`);
            paramIdx++;
        }

        sql += ` ORDER BY f.trust_score DESC, p.created_at DESC LIMIT $${paramIdx++} OFFSET $${paramIdx}`;
        params.push(parseInt(limit), parseInt(offset));

        const result = await query(sql, params);

        // Enrich with pool data from Redis
        const products = await Promise.all(result.rows.map(async (p) => {
            // Find active pool for this product in user's zone
            const poolResult = await query(
                `SELECT id, current_qty, min_qty, target_qty, timer_end, status
         FROM pools WHERE product_id = $1 AND status = 'open'
         ORDER BY created_at DESC LIMIT 1`,
                [p.id]
            );

            let poolInfo = null;
            if (poolResult.rows.length > 0) {
                const pool = poolResult.rows[0];
                const redisCount = await getPoolCount(pool.id);
                poolInfo = {
                    pool_id: pool.id,
                    current_qty: redisCount || pool.current_qty,
                    min_qty: pool.min_qty,
                    target_qty: pool.target_qty,
                    progress: Math.min(100, Math.round(((redisCount || pool.current_qty) / pool.min_qty) * 100)),
                    timer_end: pool.timer_end,
                    status: await getPoolStatus(pool.id) || pool.status,
                };
            }

            // Calculate savings
            const savings = p.mrp ? Math.round(((p.mrp - p.tier1_price) / p.mrp) * 100) : null;

            return {
                id: p.id,
                name: p.name,
                category: p.category,
                description: p.description,
                image_urls: p.image_urls,
                price: parseFloat(p.tier1_price),
                mrp: p.mrp ? parseFloat(p.mrp) : null,
                savings_percent: savings,
                gst_rate: parseFloat(p.gst_rate),
                unit: p.unit,
                factory: {
                    name: p.factory_name,
                    city: p.factory_city,
                    trust_score: parseFloat(p.trust_score),
                    tier: p.factory_tier,
                },
                pool: poolInfo,
            };
        }));

        res.json({ success: true, products, page: parseInt(page), limit: parseInt(limit) });
    } catch (err) { next(err); }
});

// ─── GET /products/:id ───────────────────────────
// TRD: Single product detail with full price breakdown and factory info
router.get('/:id', authenticate('customer'), async (req, res, next) => {
    try {
        const result = await query(
            `SELECT p.*, f.business_name, f.trust_score, f.tier, f.city AS factory_city,
              f.capacity_per_day AS factory_capacity, f.id AS fid
       FROM products p
       JOIN factories f ON p.factory_id = f.id
       WHERE p.id = $1`,
            [req.params.id]
        );

        if (result.rows.length === 0) {
            return res.status(404).json({ error: 'Not Found', message: 'Product not found.' });
        }

        const p = result.rows[0];

        // Get active pool
        const poolResult = await query(
            `SELECT * FROM pools WHERE product_id = $1 AND status IN ('open', 'locked')
       ORDER BY created_at DESC LIMIT 1`,
            [p.id]
        );

        // Get ratings
        const ratingResult = await query(
            `SELECT AVG(stars) AS avg_rating, COUNT(*) AS total_ratings
       FROM ratings WHERE factory_id = $1`,
            [p.fid]
        );

        // Full price breakdown — TRD C13
        const basePrice = parseFloat(p.tier1_price);
        const gstAmount = basePrice * (parseFloat(p.gst_rate) / 100);
        const platformFee = Math.round(basePrice * 0.05 * 100) / 100; // 5% platform fee
        const totalPerUnit = basePrice + gstAmount + platformFee;

        res.json({
            success: true,
            product: {
                id: p.id,
                name: p.name,
                category: p.category,
                description: p.description,
                image_urls: p.image_urls,
                unit: p.unit,
                lead_time_days: p.lead_time_days,
                pricing: {
                    tier1: { price: parseFloat(p.tier1_price), min_qty: p.tier1_min_qty, label: 'Standard' },
                    tier2: p.tier2_price ? { price: parseFloat(p.tier2_price), min_qty: p.tier2_min_qty, label: 'Bulk' } : null,
                    tier3: p.tier3_price ? { price: parseFloat(p.tier3_price), min_qty: p.tier3_min_qty, label: 'Wholesale' } : null,
                    mrp: p.mrp ? parseFloat(p.mrp) : null,
                    savings_percent: p.mrp ? Math.round(((parseFloat(p.mrp) - basePrice) / parseFloat(p.mrp)) * 100) : null,
                },
                price_breakdown: {
                    base_price: basePrice,
                    gst: { rate: parseFloat(p.gst_rate), amount: Math.round(gstAmount * 100) / 100 },
                    platform_fee: platformFee,
                    total_per_unit: Math.round(totalPerUnit * 100) / 100,
                },
                factory: {
                    name: p.business_name,
                    city: p.factory_city,
                    trust_score: parseFloat(p.trust_score),
                    tier: p.tier,
                    capacity_per_day: p.factory_capacity,
                    avg_rating: ratingResult.rows[0]?.avg_rating ? parseFloat(ratingResult.rows[0].avg_rating).toFixed(1) : null,
                    total_ratings: parseInt(ratingResult.rows[0]?.total_ratings) || 0,
                },
                pool: poolResult.rows.length > 0 ? {
                    pool_id: poolResult.rows[0].id,
                    current_qty: poolResult.rows[0].current_qty,
                    min_qty: poolResult.rows[0].min_qty,
                    target_qty: poolResult.rows[0].target_qty,
                    status: poolResult.rows[0].status,
                    timer_end: poolResult.rows[0].timer_end,
                } : null,
            },
        });
    } catch (err) { next(err); }
});

module.exports = router;
