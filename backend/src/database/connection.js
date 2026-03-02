/**
 * PostgreSQL Connection — TRD Section 3
 * Uses pg Pool for connection pooling (PgBouncer equivalent)
 */

const { Pool } = require('pg');

let pool;

async function connectDB() {
    pool = new Pool({
        connectionString: process.env.DATABASE_URL,
        ssl: process.env.DB_SSL === 'true' ? { rejectUnauthorized: false } : false,
        max: 20,               // Max connections in pool
        idleTimeoutMillis: 30000,
        connectionTimeoutMillis: 5000,
    });

    // Test connection
    const client = await pool.connect();
    const result = await client.query('SELECT NOW()');
    console.log(`   📅 DB Time: ${result.rows[0].now}`);
    client.release();
    return pool;
}

function getPool() {
    if (!pool) throw new Error('Database not initialized. Call connectDB() first.');
    return pool;
}

// Helper: run a query
async function query(text, params) {
    const start = Date.now();
    const result = await getPool().query(text, params);
    const duration = Date.now() - start;
    if (duration > 200) {
        console.warn(`⚠️ Slow query (${duration}ms):`, text.substring(0, 80));
    }
    return result;
}

// Helper: run inside transaction
async function transaction(callback) {
    const client = await getPool().connect();
    try {
        await client.query('BEGIN');
        const result = await callback(client);
        await client.query('COMMIT');
        return result;
    } catch (err) {
        await client.query('ROLLBACK');
        throw err;
    } finally {
        client.release();
    }
}

module.exports = { connectDB, getPool, query, transaction };
