/**
 * Database Seed — Sample Data for FactoryLink
 * Creates zones, anchor points, sample factories, products, and users
 */

require('dotenv').config({ path: require('path').join(__dirname, '../../.env') });
const { connectDB, query } = require('./connection');

async function seed() {
    console.log('🌱 Seeding FactoryLink database...\n');

    try {
        await connectDB();

        // ─── 1. ZONES ────────────────────────────────
        console.log('📍 Creating zones...');
        const zones = await query(`
      INSERT INTO zones (city, name, lat, lng, radius_km, health_score, status) VALUES
        ('Pilani', 'BITS Pilani Zone', 28.3670, 75.5870, 3.0, 8.5, 'active'),
        ('Pilani', 'Pilani Market Zone', 28.3750, 75.6020, 2.5, 7.2, 'active'),
        ('Jaipur', 'Jaipur Central Zone', 26.9124, 75.7873, 5.0, 9.0, 'active'),
        ('Jaipur', 'Mansarovar Zone', 26.8684, 75.7586, 3.0, 6.8, 'active'),
        ('Delhi', 'South Delhi Zone', 28.5355, 77.2100, 4.0, 8.0, 'active'),
        ('Mumbai', 'Andheri Zone', 19.1136, 72.8697, 3.5, 7.5, 'active')
      ON CONFLICT DO NOTHING
      RETURNING id, name, city
    `);
        console.log('   ✅ Created', zones.rows.length, 'zones');

        const zoneIds = zones.rows;

        // ─── 2. ANCHOR POINTS ────────────────────────
        console.log('📌 Creating anchor points...');
        if (zoneIds.length > 0) {
            await query(`
        INSERT INTO anchor_points (zone_id, name, type, lat, lng, address, manager_name, manager_phone) VALUES
          ($1, 'BITS Pilani Main Gate', 'college', 28.3634, 75.5855, 'Vidya Vihar, Pilani, Rajasthan', 'Rahul Kumar', '9876543210'),
          ($1, 'BITS Library Square', 'college', 28.3650, 75.5880, 'Near Library, BITS Campus', 'Amit Singh', '9876543211'),
          ($2, 'Pilani Central Market', 'market', 28.3762, 75.6030, 'Main Bazaar, Pilani', 'Suresh Ji', '9876543212'),
          ($3, 'Jaipur Railway Station', 'market', 26.9196, 75.7879, 'Station Road, Jaipur', 'Priya Sharma', '9876543213'),
          ($3, 'MI Road Square', 'market', 26.9157, 75.8005, 'MI Road, Jaipur', 'Vikram Meena', '9876543214'),
          ($4, 'Mansarovar Metro Hub', 'office', 26.8702, 75.7610, 'Near Metro Station, Mansarovar', 'Deepak Jain', '9876543215'),
          ($5, 'Saket Metro Station', 'office', 28.5211, 77.2167, 'Saket, New Delhi', 'Neha Gupta', '9876543216'),
          ($6, 'Andheri Station West', 'market', 19.1197, 72.8464, 'Andheri West, Mumbai', 'Ravi Patel', '9876543217')
        ON CONFLICT DO NOTHING
      `, [zoneIds[0]?.id, zoneIds[1]?.id, zoneIds[2]?.id, zoneIds[3]?.id, zoneIds[4]?.id, zoneIds[5]?.id]);
            console.log('   ✅ Created 8 anchor points');
        }

        // ─── 3. USERS (sample) ───────────────────────
        console.log('👤 Creating sample users...');
        const users = await query(`
      INSERT INTO users (phone, name, type, address, pin_code, zone_id, is_verified) VALUES
        ('9999900001', 'Abhay Customer', 'customer', 'BITS Pilani Campus', '333031', $1, true),
        ('9999900002', 'Priya Sharma', 'customer', 'Jaipur Central', '302001', $2, true),
        ('9999900003', 'Rajesh Factory Owner', 'factory', 'Industrial Area, Jaipur', '302013', $2, true),
        ('9999900004', 'Meena Textiles Owner', 'factory', 'Sanganer Road, Jaipur', '302029', $2, true),
        ('9999900005', 'Admin User', 'admin', 'FactoryLink HQ', '110001', $3, true)
      ON CONFLICT (phone) DO NOTHING
      RETURNING id, name, type
    `, [zoneIds[0]?.id, zoneIds[2]?.id, zoneIds[4]?.id]);
        console.log('   ✅ Created', users.rows.length, 'users');

        // ─── 4. FACTORIES ────────────────────────────
        console.log('🏭 Creating sample factories...');
        const factoryOwners = users.rows.filter(u => u.type === 'factory');

        if (factoryOwners.length >= 2) {
            const factories = await query(`
        INSERT INTO factories (owner_id, business_name, gst_number, product_categories, capacity_per_day,
          min_order_qty, trust_score, tier, address, city, state, verification_status, availability) VALUES
          ($1, 'Rajesh Organic Products', '08AABCT1332L1ZT', ARRAY['food','organic','spices'], 200,
            10, 8.5, 'gold', 'Plot 45, RIICO Industrial Area', 'Jaipur', 'Rajasthan', 'approved', 'full'),
          ($2, 'Meena Handloom Textiles', '08BBDFT4521M1ZP', ARRAY['textiles','clothing','handloom'], 150,
            15, 7.2, 'silver', 'Sanganer Textile Park', 'Jaipur', 'Rajasthan', 'approved', 'full')
        ON CONFLICT DO NOTHING
        RETURNING id, business_name
      `, [factoryOwners[0].id, factoryOwners[1].id]);
            console.log('   ✅ Created', factories.rows.length, 'factories');

            // ─── 5. PRODUCTS ────────────────────────────
            console.log('📦 Creating sample products...');
            if (factories.rows.length >= 2) {
                const products = await query(`
          INSERT INTO products (factory_id, category, name, description, tier1_price, tier1_min_qty,
            tier2_price, tier2_min_qty, tier3_price, tier3_min_qty, mrp, gst_rate, unit, lead_time_days, capacity_per_day) VALUES
            ($1, 'food', 'Organic Cold-Pressed Mustard Oil (1L)', 'Pure organic mustard oil, cold-pressed from Rajasthan farms. No chemicals.',
              180, 10, 165, 50, 150, 200, 350, 5, 'bottle', 5, 100),
            ($1, 'food', 'Rajasthani Mixed Pickle (500g)', 'Traditional aam ka achar made with authentic spices.',
              120, 10, 105, 50, 95, 200, 220, 12, 'jar', 7, 150),
            ($1, 'spices', 'Premium Haldi Powder (500g)', 'Farm-fresh turmeric, sun-dried and ground. High curcumin.',
              95, 10, 80, 50, 70, 200, 180, 5, 'pack', 3, 200),
            ($1, 'organic', 'Natural Handmade Soap Pack (6 bars)', 'Chemical-free soap with neem, tulsi, aloe.',
              250, 10, 220, 50, 195, 200, 480, 18, 'pack', 7, 80),
            ($2, 'textiles', 'Pure Cotton Bedsheet (Double Bed)', 'Handloom cotton bedsheet with 2 pillow covers. Block print.',
              850, 5, 720, 25, 650, 100, 1600, 5, 'set', 10, 50),
            ($2, 'clothing', 'Men Cotton T-Shirt (Pack of 3)', 'Premium cotton round-neck tees. Sizes M/L/XL.',
              450, 10, 380, 50, 340, 200, 900, 5, 'pack', 7, 100),
            ($2, 'handloom', 'Handloom Cotton Tote Bag', 'Eco-friendly handwoven bag. Reusable, stylish.',
              180, 10, 150, 50, 130, 200, 350, 18, 'piece', 5, 120),
            ($2, 'textiles', 'Cotton Face Towel Set (6 pcs)', 'Soft absorbent face towels. Multiple colors.',
              320, 10, 275, 50, 245, 200, 600, 5, 'set', 5, 150)
          ON CONFLICT DO NOTHING
          RETURNING id, name
        `, [factories.rows[0].id, factories.rows[1].id]);
                console.log('   ✅ Created', products.rows.length, 'products');

                // ─── 6. SAMPLE POOLS ──────────────────────
                console.log('🏊 Creating sample pools...');
                if (products.rows.length > 0 && zoneIds.length > 0) {
                    const timerEnd = new Date(Date.now() + 36 * 60 * 60 * 1000); // 36h from now
                    await query(`
            INSERT INTO pools (product_id, zone_id, factory_id, current_qty, min_qty, target_qty, status, timer_end) VALUES
              ($1, $5, $7, 7, 10, 50, 'open', $9),
              ($2, $5, $7, 12, 10, 50, 'locked', $9),
              ($3, $6, $7, 3, 10, 50, 'open', $9),
              ($4, $5, $8, 8, 10, 50, 'open', $9)
            ON CONFLICT DO NOTHING
          `, [
                        products.rows[0]?.id, products.rows[1]?.id, products.rows[2]?.id, products.rows[4]?.id,
                        zoneIds[0]?.id, zoneIds[2]?.id,
                        factories.rows[0]?.id, factories.rows[1]?.id,
                        timerEnd
                    ]);
                    console.log('   ✅ Created 4 sample pools');
                }
            }
        }

        console.log('\n🎉 Seed completed successfully!');
        console.log('   You can now test the API at http://localhost:3000/v1\n');
        process.exit(0);
    } catch (err) {
        console.error('❌ Seed failed:', err.message);
        process.exit(1);
    }
}

seed();
