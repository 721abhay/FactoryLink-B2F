// Quick API test script
const http = require('http');

function request(method, path, body = null, token = null) {
    return new Promise((resolve, reject) => {
        const options = {
            hostname: 'localhost', port: 3000,
            path: `/v1${path}`, method,
            headers: { 'Content-Type': 'application/json' },
        };
        if (token) options.headers['Authorization'] = `Bearer ${token}`;

        const req = http.request(options, (res) => {
            let data = '';
            res.on('data', (chunk) => data += chunk);
            res.on('end', () => resolve({ status: res.statusCode, body: JSON.parse(data) }));
        });
        req.on('error', reject);
        if (body) req.write(JSON.stringify(body));
        req.end();
    });
}

async function test() {
    console.log('🧪 Testing FactoryLink API...\n');

    // 1. Send OTP
    const otp = await request('POST', '/auth/otp/send', { phone: '9999900001' });
    console.log('1️⃣  Send OTP:', otp.body.success ? '✅' : '❌', otp.body.dev_otp || '');

    // 2. Verify OTP
    const auth = await request('POST', '/auth/otp/verify', {
        phone: '9999900001', otp: otp.body.dev_otp, user_type: 'customer'
    });
    console.log('2️⃣  Verify OTP:', auth.body.success ? '✅' : '❌', `User: ${auth.body.user?.name}`);
    const token = auth.body.jwt_token;

    // 3. Get Products
    const products = await request('GET', '/products', null, token);
    console.log('3️⃣  Products:', products.body.success ? '✅' : '❌', `${products.body.products?.length} products`);
    if (products.body.products?.[0]) {
        const p = products.body.products[0];
        console.log(`   📦 "${p.name}" — ₹${p.price} (${p.savings_percent}% off MRP)`);
        console.log(`   🏭 Factory: ${p.factory.name} (Score: ${p.factory.trust_score})`);
        if (p.pool) console.log(`   🏊 Pool: ${p.pool.progress}% filled (${p.pool.current_qty}/${p.pool.min_qty})`);
    }

    // 4. Get Orders
    const orders = await request('GET', '/orders', null, token);
    console.log('4️⃣  Orders:', orders.body.success ? '✅' : '❌', `${orders.body.orders?.length} orders`);

    // 5. Get Zones
    const zones = await request('GET', '/zones/nearby', null, token);
    console.log('5️⃣  Zones:', zones.body.success ? '✅' : '❌', `${zones.body.zones?.length} zones`);
    if (zones.body.zones?.[0]) {
        const z = zones.body.zones[0];
        console.log(`   📍 "${z.name}" — Health: ${z.health_score}, ${z.anchor_points?.length} anchors`);
    }

    console.log('\n🎉 All API tests completed!');
}

test().catch(err => console.error('❌ Test failed:', err.message));
