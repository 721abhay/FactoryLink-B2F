/**
 * Redis Cache — TRD Section 3: Redis Keys
 * 
 * Key patterns from TRD:
 * - pool:{pool_id}:count    — Current order count (TTL 48h)
 * - pool:{pool_id}:status   — Pool status open/locked/cancelled (TTL 48h)
 * - zone:{zone_id}:health   — Zone health score (TTL 7d)
 * - factory:{factory_id}:available — Factory availability (TTL 7d)
 * - session:{user_id}       — JWT session metadata (TTL 24h)
 * - rate:{user_id}:{endpoint} — Rate limiting counter (TTL 1min)
 */

const { createClient } = require('redis');

let client;

async function connectRedis() {
    client = createClient({
        url: process.env.REDIS_URL || 'redis://localhost:6379',
        socket: { reconnectStrategy: (retries) => Math.min(retries * 100, 3000) }
    });

    client.on('error', (err) => console.error('Redis error:', err.message));
    client.on('reconnecting', () => console.log('🔄 Redis reconnecting...'));

    await client.connect();
    await client.ping();
    return client;
}

function getRedis() {
    if (!client || !client.isOpen) throw new Error('Redis not connected');
    return client;
}

// ─── Pool helpers ────────────────────────────────
const POOL_TTL = 48 * 60 * 60; // 48 hours

async function getPoolCount(poolId) {
    const count = await getRedis().get(`pool:${poolId}:count`);
    return parseInt(count) || 0;
}

async function incrementPoolCount(poolId) {
    const r = getRedis();
    const count = await r.incr(`pool:${poolId}:count`);
    await r.expire(`pool:${poolId}:count`, POOL_TTL);
    return count;
}

async function setPoolStatus(poolId, status) {
    await getRedis().set(`pool:${poolId}:status`, status, { EX: POOL_TTL });
}

async function getPoolStatus(poolId) {
    return await getRedis().get(`pool:${poolId}:status`);
}

// ─── Zone helpers ────────────────────────────────
const ZONE_TTL = 7 * 24 * 60 * 60; // 7 days

async function setZoneHealth(zoneId, score) {
    await getRedis().set(`zone:${zoneId}:health`, score.toString(), { EX: ZONE_TTL });
}

async function getZoneHealth(zoneId) {
    const score = await getRedis().get(`zone:${zoneId}:health`);
    return parseFloat(score) || 0;
}

// ─── Factory helpers ─────────────────────────────
async function setFactoryAvailability(factoryId, status) {
    await getRedis().set(`factory:${factoryId}:available`, status, { EX: ZONE_TTL });
}

async function getFactoryAvailability(factoryId) {
    return await getRedis().get(`factory:${factoryId}:available`) || 'full';
}

// ─── Session helpers ─────────────────────────────
const SESSION_TTL = 24 * 60 * 60; // 24 hours

async function setSession(userId, data) {
    await getRedis().set(`session:${userId}`, JSON.stringify(data), { EX: SESSION_TTL });
}

async function getSession(userId) {
    const data = await getRedis().get(`session:${userId}`);
    return data ? JSON.parse(data) : null;
}

async function deleteSession(userId) {
    await getRedis().del(`session:${userId}`);
}

module.exports = {
    connectRedis, getRedis,
    getPoolCount, incrementPoolCount, setPoolStatus, getPoolStatus,
    setZoneHealth, getZoneHealth,
    setFactoryAvailability, getFactoryAvailability,
    setSession, getSession, deleteSession,
};
