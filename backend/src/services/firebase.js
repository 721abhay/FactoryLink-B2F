/**
 * Firebase Admin SDK Initialization — TRD Section 6
 * Push Notifications via Firebase FCM
 */

const admin = require('firebase-admin');

function initFirebase() {
    try {
        const serviceAccountPath = process.env.FIREBASE_SERVICE_ACCOUNT;
        if (serviceAccountPath) {
            const serviceAccount = require(serviceAccountPath);
            admin.initializeApp({
                credential: admin.credential.cert(serviceAccount),
                projectId: process.env.FIREBASE_PROJECT_ID,
            });
        } else {
            // Use default credentials (for Cloud Run / GCP environments)
            admin.initializeApp({
                projectId: process.env.FIREBASE_PROJECT_ID,
            });
        }
        console.log('   🔔 FCM ready for push notifications');
    } catch (err) {
        console.warn('⚠️ Firebase init skipped:', err.message);
    }
}

/**
 * Send push notification to a single user
 * TRD: Store notification in DB. Show in-app on next open if push failed.
 */
async function sendPushNotification(fcmToken, title, body, data = {}) {
    if (!fcmToken) return { success: false, reason: 'no_token' };

    try {
        const message = {
            token: fcmToken,
            notification: { title, body },
            data: Object.fromEntries(Object.entries(data).map(([k, v]) => [k, String(v)])),
            android: {
                priority: 'high',
                notification: { channelId: 'factorylink_orders', sound: 'default' },
            },
            apns: {
                payload: { aps: { badge: 1, sound: 'default' } },
            },
        };

        const result = await admin.messaging().send(message);
        return { success: true, messageId: result };
    } catch (err) {
        console.error('Push failed:', err.message);
        return { success: false, reason: err.message };
    }
}

/**
 * Send to multiple users (multicast)
 */
async function sendMulticast(tokens, title, body, data = {}) {
    if (!tokens || tokens.length === 0) return;

    const message = {
        tokens,
        notification: { title, body },
        data: Object.fromEntries(Object.entries(data).map(([k, v]) => [k, String(v)])),
    };

    try {
        const result = await admin.messaging().sendEachForMulticast(message);
        console.log(`📨 Push sent: ${result.successCount} ok, ${result.failureCount} failed`);
        return result;
    } catch (err) {
        console.error('Multicast push failed:', err.message);
    }
}

module.exports = { initFirebase, sendPushNotification, sendMulticast };
