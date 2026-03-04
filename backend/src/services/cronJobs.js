/**
 * Cron Scheduler — Automated background jobs for FactoryLink
 * 
 * TRD Section 4: Zone Service — Cron job every hour
 * TRD Section 4: Matching Service — Bull Queue for async jobs
 * 
 * Jobs:
 * ┌─────────────────────────────────────────────────────────────────┐
 * │ Job                        │ Interval    │ Purpose              │
 * ├─────────────────────────────────────────────────────────────────┤
 * │ Pool Timer Expiry          │ Every 5 min │ Cancel expired pools │
 * │ Pool Factory Assignment    │ Every 5 min │ Assign locked pools  │
 * │ Factory Response Timeout   │ Every 15 min│ Reroute if no reply  │
 * │ Zone Health Update         │ Every 1 hr  │ Recalculate scores   │
 * │ Auto-Complete Stale Orders │ Every 6 hr  │ Complete old orders  │
 * │ Subscription Fulfillment   │ Every 12 hr │ Auto-create orders   │
 * │ Pool Stats Logging         │ Every 30 min│ Monitoring logs      │
 * └─────────────────────────────────────────────────────────────────┘
 */

const {
    processExpiredPools,
    processLockedPools,
    processFactoryTimeouts,
    updateZoneHealth,
    autoCompleteStaleOrders,
    getPoolStats,
} = require('./poolEngine');
const { processDueSubscriptions } = require('./subscriptionFulfillment');

// Track running state to prevent overlapping runs
const running = {
    expiredPools: false,
    lockedPools: false,
    factoryTimeouts: false,
    zoneHealth: false,
    autoComplete: false,
    subscriptions: false,
};

// Safe wrapper — prevents overlapping runs and logs errors
async function safeRun(name, fn) {
    if (running[name]) {
        console.log(`⏭️  [Cron] ${name} already running, skipping...`);
        return;
    }

    running[name] = true;
    const start = Date.now();

    try {
        await fn();
        const duration = Date.now() - start;
        console.log(`✅ [Cron] ${name} completed in ${duration}ms\n`);
    } catch (err) {
        console.error(`❌ [Cron] ${name} failed:`, err.message);
    } finally {
        running[name] = false;
    }
}

// ─── Interval handles (for cleanup) ─────────────
let intervals = [];

/**
 * Start all cron jobs
 * Called from server.js after DB and Redis are connected
 */
function startCronJobs() {
    console.log('\n⏰ [Cron] Starting background jobs...');
    console.log('   📦 Pool Timer Expiry     → every 5 min');
    console.log('   🔒 Pool Factory Assign   → every 5 min');
    console.log('   ⏳ Factory Response Check → every 15 min');
    console.log('   🗺️  Zone Health Update    → every 1 hour');
    console.log('   📋 Auto-Complete Orders  → every 6 hours');
    console.log('   🔔 Subscription Fulfill  → every 12 hours');
    console.log('   📊 Pool Stats Logging    → every 30 min\n');

    // Every 5 minutes — process expired pools
    intervals.push(setInterval(() => {
        safeRun('expiredPools', processExpiredPools);
    }, 5 * 60 * 1000));

    // Every 5 minutes (offset by 1 min) — assign locked pools to factories
    setTimeout(() => {
        intervals.push(setInterval(() => {
            safeRun('lockedPools', processLockedPools);
        }, 5 * 60 * 1000));
    }, 60 * 1000);

    // Every 15 minutes — check factory response timeouts
    intervals.push(setInterval(() => {
        safeRun('factoryTimeouts', processFactoryTimeouts);
    }, 15 * 60 * 1000));

    // Every 1 hour — update zone health
    intervals.push(setInterval(() => {
        safeRun('zoneHealth', updateZoneHealth);
    }, 60 * 60 * 1000));

    // Every 6 hours — auto-complete stale collected orders
    intervals.push(setInterval(() => {
        safeRun('autoComplete', autoCompleteStaleOrders);
    }, 6 * 60 * 60 * 1000));

    // Every 12 hours — process due subscriptions
    intervals.push(setInterval(() => {
        safeRun('subscriptions', processDueSubscriptions);
    }, 12 * 60 * 60 * 1000));

    // Every 30 minutes — log pool statistics
    intervals.push(setInterval(async () => {
        try {
            const stats = await getPoolStats();
            console.log(`📊 [Pool Stats] Open: ${stats.open_pools} | Locked: ${stats.locked_pools} | ` +
                `Assigned: ${stats.assigned_pools} | Production: ${stats.production_pools} | ` +
                `Cancelled: ${stats.cancelled_pools} | Completed: ${stats.completed_pools}`);
        } catch (err) {
            console.error('📊 [Pool Stats] Error:', err.message);
        }
    }, 30 * 60 * 1000));

    // Run initial jobs after a 10-second startup delay
    setTimeout(async () => {
        console.log('🚀 [Cron] Running initial job sweep...');
        await safeRun('expiredPools', processExpiredPools);
        await safeRun('lockedPools', processLockedPools);
        await safeRun('factoryTimeouts', processFactoryTimeouts);
        await safeRun('zoneHealth', updateZoneHealth);
        await safeRun('subscriptions', processDueSubscriptions);

        // Log initial stats
        try {
            const stats = await getPoolStats();
            console.log(`📊 [Pool Stats] Open: ${stats.open_pools} | Locked: ${stats.locked_pools} | ` +
                `Assigned: ${stats.assigned_pools} | Production: ${stats.production_pools}\n`);
        } catch (err) { /* ignore on startup */ }
    }, 10 * 1000);
}

/**
 * Stop all cron jobs
 * Called during graceful shutdown
 */
function stopCronJobs() {
    console.log('🛑 [Cron] Stopping all background jobs...');
    intervals.forEach(clearInterval);
    intervals = [];
}

module.exports = { startCronJobs, stopCronJobs };
