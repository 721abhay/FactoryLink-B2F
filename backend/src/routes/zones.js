/**
 * Zone Routes — TRD Section 4
 * GET /zones/nearby — Get nearest anchor points and zone health
 */

const router = require('express').Router();
const { query } = require('../database/connection');
const { authenticate } = require('../middleware/auth');
const { getZoneHealth } = require('../cache/redis');

// ─── GET /zones/nearby ───────────────────────────
// TRD: Get nearest anchor points and zone health for customer address
router.get('/nearby', authenticate('customer'), async (req, res, next) => {
    try {
        const { lat, lng, radius_km = 5 } = req.query;

        let zones;
        if (lat && lng) {
            // Haversine distance-based query
            zones = await query(
                `SELECT *, 
          (6371 * acos(cos(radians($1)) * cos(radians(lat)) * cos(radians(lng) - radians($2)) + sin(radians($1)) * sin(radians(lat)))) AS distance_km
         FROM zones
         WHERE status = 'active'
         HAVING distance_km <= $3
         ORDER BY distance_km
         LIMIT 20`,
                [parseFloat(lat), parseFloat(lng), parseFloat(radius_km)]
            );
        } else {
            zones = await query(
                `SELECT * FROM zones WHERE status = 'active' ORDER BY health_score DESC LIMIT 20`
            );
        }

        // Enrich with anchor points and Redis health
        const enrichedZones = await Promise.all(zones.rows.map(async (z) => {
            const anchors = await query(
                `SELECT id, name, type, lat, lng, address FROM anchor_points WHERE zone_id = $1 AND active = true`,
                [z.id]
            );

            const cachedHealth = await getZoneHealth(z.id);

            return {
                id: z.id,
                name: z.name,
                city: z.city,
                lat: parseFloat(z.lat),
                lng: parseFloat(z.lng),
                radius_km: parseFloat(z.radius_km),
                health_score: cachedHealth || parseFloat(z.health_score),
                total_orders: z.total_orders,
                total_users: z.total_users,
                distance_km: z.distance_km ? parseFloat(z.distance_km).toFixed(1) : null,
                anchor_points: anchors.rows.map(a => ({
                    id: a.id,
                    name: a.name,
                    type: a.type,
                    lat: parseFloat(a.lat),
                    lng: parseFloat(a.lng),
                    address: a.address,
                })),
            };
        }));

        res.json({ success: true, zones: enrichedZones });
    } catch (err) { next(err); }
});

module.exports = router;
