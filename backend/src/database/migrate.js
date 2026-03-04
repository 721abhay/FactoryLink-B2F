/**
 * Database Migration — TRD Section 3: Database Schema
 * Creates all core tables as defined in the TRD
 * 
 * Tables: users, factories, products, zones, anchor_points, pools, orders, payments, ratings
 */

require('dotenv').config({ path: require('path').join(__dirname, '../../.env') });
const { connectDB, getPool } = require('./connection');

const MIGRATION_SQL = `
-- ═══════════════════════════════════════════════════
-- FACTORYLINK DATABASE SCHEMA — TRD v1.0
-- ═══════════════════════════════════════════════════

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- ─── USERS TABLE ─────────────────────────────────
-- TRD: id (UUID), phone, name, address, zone_id, type (customer/factory), created_at
CREATE TABLE IF NOT EXISTS users (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  phone VARCHAR(15) NOT NULL UNIQUE,
  name VARCHAR(100),
  address TEXT,
  pin_code VARCHAR(10),
  zone_id UUID,
  type VARCHAR(20) NOT NULL CHECK (type IN ('customer', 'factory', 'admin')),
  anchor_point_id UUID,
  fcm_token TEXT,
  is_verified BOOLEAN DEFAULT false,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS idx_users_phone ON users(phone);
CREATE INDEX IF NOT EXISTS idx_users_zone ON users(zone_id);
CREATE INDEX IF NOT EXISTS idx_users_type ON users(type);

-- ─── FACTORIES TABLE ────────────────────────────
-- TRD: owner_id (FK users), capacity_per_day, min_order_qty, trust_score, tier, slow_months[]
CREATE TABLE IF NOT EXISTS factories (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  owner_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  business_name VARCHAR(200) NOT NULL,
  gst_number VARCHAR(20),
  msme_number VARCHAR(30),
  bank_account VARCHAR(30),
  ifsc_code VARCHAR(15),
  product_categories TEXT[],
  capacity_per_day INTEGER DEFAULT 0,
  min_order_qty INTEGER DEFAULT 10,
  trust_score DECIMAL(3,1) DEFAULT 5.0,
  tier VARCHAR(10) DEFAULT 'bronze' CHECK (tier IN ('bronze', 'silver', 'gold', 'platinum')),
  slow_months INTEGER[],
  address TEXT,
  city VARCHAR(100),
  state VARCHAR(100),
  lat DECIMAL(10,7),
  lng DECIMAL(10,7),
  gst_doc_url TEXT,
  msme_doc_url TEXT,
  cheque_doc_url TEXT,
  verification_status VARCHAR(20) DEFAULT 'pending' CHECK (verification_status IN ('pending', 'approved', 'rejected')),
  availability VARCHAR(20) DEFAULT 'full' CHECK (availability IN ('full', 'partial', 'none')),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS idx_factories_trust ON factories(trust_score);
CREATE INDEX IF NOT EXISTS idx_factories_tier ON factories(tier);
CREATE INDEX IF NOT EXISTS idx_factories_city ON factories(city);
CREATE INDEX IF NOT EXISTS idx_factories_verification ON factories(verification_status);

-- ─── ZONES TABLE ─────────────────────────────────
-- TRD: city, lat, lng, radius_km, health_score, anchor_point_ids[], status
CREATE TABLE IF NOT EXISTS zones (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  city VARCHAR(100) NOT NULL,
  name VARCHAR(200),
  lat DECIMAL(10,7) NOT NULL,
  lng DECIMAL(10,7) NOT NULL,
  radius_km DECIMAL(5,2) DEFAULT 3.0,
  health_score DECIMAL(3,1) DEFAULT 5.0,
  status VARCHAR(20) DEFAULT 'active' CHECK (status IN ('active', 'inactive', 'merged')),
  total_orders INTEGER DEFAULT 0,
  total_users INTEGER DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS idx_zones_city ON zones(city);
CREATE INDEX IF NOT EXISTS idx_zones_health ON zones(health_score);
CREATE INDEX IF NOT EXISTS idx_zones_status ON zones(status);

-- ─── ANCHOR POINTS TABLE ────────────────────────
-- TRD: zone_id (FK), name, type (college/office/market), lat, lng, manager_phone, active
CREATE TABLE IF NOT EXISTS anchor_points (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  zone_id UUID NOT NULL REFERENCES zones(id) ON DELETE CASCADE,
  name VARCHAR(200) NOT NULL,
  type VARCHAR(30) NOT NULL CHECK (type IN ('college', 'office', 'market', 'residential', 'other')),
  lat DECIMAL(10,7) NOT NULL,
  lng DECIMAL(10,7) NOT NULL,
  address TEXT,
  manager_name VARCHAR(100),
  manager_phone VARCHAR(15),
  active BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS idx_anchors_zone ON anchor_points(zone_id);
CREATE INDEX IF NOT EXISTS idx_anchors_type ON anchor_points(type);
CREATE INDEX IF NOT EXISTS idx_anchors_active ON anchor_points(active);

-- ─── PRODUCTS TABLE ──────────────────────────────
-- TRD: factory_id (FK), category, name, tier1_price, tier2_price, tier3_price, gst_rate
CREATE TABLE IF NOT EXISTS products (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  factory_id UUID NOT NULL REFERENCES factories(id) ON DELETE CASCADE,
  category VARCHAR(100) NOT NULL,
  name VARCHAR(200) NOT NULL,
  description TEXT,
  image_urls TEXT[],
  tier1_price DECIMAL(10,2) NOT NULL,
  tier1_min_qty INTEGER DEFAULT 10,
  tier2_price DECIMAL(10,2),
  tier2_min_qty INTEGER DEFAULT 50,
  tier3_price DECIMAL(10,2),
  tier3_min_qty INTEGER DEFAULT 200,
  mrp DECIMAL(10,2),
  gst_rate DECIMAL(4,2) DEFAULT 18.00,
  unit VARCHAR(20) DEFAULT 'piece',
  lead_time_days INTEGER DEFAULT 7,
  capacity_per_day INTEGER DEFAULT 100,
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS idx_products_factory ON products(factory_id);
CREATE INDEX IF NOT EXISTS idx_products_category ON products(category);
CREATE INDEX IF NOT EXISTS idx_products_active ON products(is_active);

-- ─── POOLS TABLE ─────────────────────────────────
-- TRD: product_id (FK), zone_id (FK), factory_id (FK), current_qty, min_qty, status, timer_end
CREATE TABLE IF NOT EXISTS pools (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  product_id UUID NOT NULL REFERENCES products(id),
  zone_id UUID NOT NULL REFERENCES zones(id),
  factory_id UUID REFERENCES factories(id),
  current_qty INTEGER DEFAULT 0,
  min_qty INTEGER DEFAULT 10,
  target_qty INTEGER DEFAULT 50,
  status VARCHAR(20) DEFAULT 'open' CHECK (status IN ('open', 'locked', 'assigned', 'production', 'dispatched', 'completed', 'cancelled')),
  timer_end TIMESTAMPTZ,
  locked_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS idx_pools_zone ON pools(zone_id);
CREATE INDEX IF NOT EXISTS idx_pools_status ON pools(status);
CREATE INDEX IF NOT EXISTS idx_pools_timer ON pools(timer_end);
CREATE INDEX IF NOT EXISTS idx_pools_product ON pools(product_id);

-- ─── ORDERS TABLE ────────────────────────────────
-- TRD: user_id (FK), pool_id (FK), product_id (FK), qty, status, advance_paid, final_paid
CREATE TABLE IF NOT EXISTS orders (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES users(id),
  pool_id UUID REFERENCES pools(id),
  product_id UUID NOT NULL REFERENCES products(id),
  qty INTEGER NOT NULL DEFAULT 1,
  unit_price DECIMAL(10,2) NOT NULL,
  total_amount DECIMAL(10,2) NOT NULL,
  advance_amount DECIMAL(10,2) DEFAULT 0,
  final_amount DECIMAL(10,2) DEFAULT 0,
  advance_paid BOOLEAN DEFAULT false,
  final_paid BOOLEAN DEFAULT false,
  status VARCHAR(30) DEFAULT 'pending' CHECK (status IN (
    'pending', 'pooled', 'locked', 'assigned', 'accepted',
    'production', 'ready', 'dispatched', 'in_transit',
    'delivered', 'collected', 'completed', 'cancelled', 'refunded'
  )),
  qr_code TEXT,
  tracking_number VARCHAR(50),
  anchor_point_id UUID REFERENCES anchor_points(id),
  delivery_date TIMESTAMPTZ,
  collected_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS idx_orders_user ON orders(user_id);
CREATE INDEX IF NOT EXISTS idx_orders_pool ON orders(pool_id);
CREATE INDEX IF NOT EXISTS idx_orders_status ON orders(status);

-- ─── PAYMENTS TABLE ──────────────────────────────
-- TRD: order_id (FK), amount, type (advance/final/refund), gateway_ref, status, timestamp
CREATE TABLE IF NOT EXISTS payments (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  order_id UUID NOT NULL REFERENCES orders(id),
  user_id UUID NOT NULL REFERENCES users(id),
  amount DECIMAL(10,2) NOT NULL,
  type VARCHAR(20) NOT NULL CHECK (type IN ('advance', 'final', 'refund', 'factory_payout')),
  gateway VARCHAR(20) DEFAULT 'razorpay',
  gateway_order_id VARCHAR(100),
  gateway_payment_id VARCHAR(100),
  gateway_signature VARCHAR(200),
  status VARCHAR(20) DEFAULT 'pending' CHECK (status IN ('pending', 'processing', 'completed', 'failed', 'refunded')),
  metadata JSONB,
  created_at TIMESTAMPTZ DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS idx_payments_order ON payments(order_id);
CREATE INDEX IF NOT EXISTS idx_payments_status ON payments(status);
CREATE INDEX IF NOT EXISTS idx_payments_timestamp ON payments(created_at);

-- ─── RATINGS TABLE ───────────────────────────────
-- TRD: order_id (FK), factory_id (FK), user_id (FK), stars, photo_url, created_at
CREATE TABLE IF NOT EXISTS ratings (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  order_id UUID NOT NULL REFERENCES orders(id),
  factory_id UUID NOT NULL REFERENCES factories(id),
  user_id UUID NOT NULL REFERENCES users(id),
  stars INTEGER NOT NULL CHECK (stars >= 1 AND stars <= 5),
  review TEXT,
  photo_url TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS idx_ratings_factory ON ratings(factory_id);
CREATE INDEX IF NOT EXISTS idx_ratings_stars ON ratings(stars);
CREATE INDEX IF NOT EXISTS idx_ratings_created ON ratings(created_at);

-- ─── SUBSCRIPTIONS TABLE ────────────────────────
-- TRD: Grocery subscription support
CREATE TABLE IF NOT EXISTS subscriptions (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES users(id),
  product_id UUID NOT NULL REFERENCES products(id),
  qty INTEGER NOT NULL DEFAULT 1,
  frequency VARCHAR(20) DEFAULT 'monthly' CHECK (frequency IN ('weekly', 'biweekly', 'monthly')),
  duration_months INTEGER DEFAULT 3,
  status VARCHAR(20) DEFAULT 'active' CHECK (status IN ('active', 'paused', 'cancelled', 'completed')),
  next_delivery_date DATE,
  anchor_point_id UUID REFERENCES anchor_points(id),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS idx_subs_user ON subscriptions(user_id);
CREATE INDEX IF NOT EXISTS idx_subs_status ON subscriptions(status);

-- ─── NOTIFICATIONS TABLE ────────────────────────
CREATE TABLE IF NOT EXISTS notifications (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES users(id),
  title VARCHAR(200) NOT NULL,
  body TEXT NOT NULL,
  type VARCHAR(30) DEFAULT 'general',
  data JSONB,
  read BOOLEAN DEFAULT false,
  pushed BOOLEAN DEFAULT false,
  created_at TIMESTAMPTZ DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS idx_notif_user ON notifications(user_id);
CREATE INDEX IF NOT EXISTS idx_notif_read ON notifications(read);

-- ─── OTP TABLE ───────────────────────────────────
CREATE TABLE IF NOT EXISTS otps (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  phone VARCHAR(15) NOT NULL,
  otp VARCHAR(6) NOT NULL,
  verified BOOLEAN DEFAULT false,
  expires_at TIMESTAMPTZ NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS idx_otps_phone ON otps(phone);

-- ─── POOL ASSIGNMENTS TABLE ─────────────────────
-- Tracks which factories were assigned/declined per pool (Dual Factory Routing)
CREATE TABLE IF NOT EXISTS pool_assignments (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  pool_id UUID NOT NULL REFERENCES pools(id),
  factory_id UUID NOT NULL REFERENCES factories(id),
  match_score DECIMAL(5,1),
  is_primary BOOLEAN DEFAULT false,
  status VARCHAR(20) DEFAULT 'assigned' CHECK (status IN ('assigned', 'accepted', 'declined', 'timeout')),
  assigned_at TIMESTAMPTZ DEFAULT NOW(),
  responded_at TIMESTAMPTZ,
  UNIQUE(pool_id, factory_id)
);
CREATE INDEX IF NOT EXISTS idx_pool_assign_pool ON pool_assignments(pool_id);
CREATE INDEX IF NOT EXISTS idx_pool_assign_factory ON pool_assignments(factory_id);
CREATE INDEX IF NOT EXISTS idx_pool_assign_status ON pool_assignments(status);

-- ─── WALLETS TABLE ──────────────────────────────
-- TRD: Customer wallet for subscription prepay and refunds
CREATE TABLE IF NOT EXISTS wallets (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES users(id) UNIQUE,
  balance DECIMAL(10,2) DEFAULT 0.00,
  total_credited DECIMAL(10,2) DEFAULT 0.00,
  total_debited DECIMAL(10,2) DEFAULT 0.00,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS idx_wallets_user ON wallets(user_id);

-- ─── WALLET TRANSACTIONS TABLE ──────────────────
-- Tracks all wallet credits and debits
CREATE TABLE IF NOT EXISTS wallet_transactions (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  wallet_id UUID NOT NULL REFERENCES wallets(id),
  user_id UUID NOT NULL REFERENCES users(id),
  amount DECIMAL(10,2) NOT NULL,
  type VARCHAR(20) NOT NULL CHECK (type IN ('credit', 'debit')),
  source VARCHAR(30) NOT NULL CHECK (source IN (
    'refund', 'topup', 'subscription_prepay', 'order_payment',
    'cashback', 'referral_bonus', 'admin_adjustment'
  )),
  reference_id UUID,
  description TEXT,
  balance_after DECIMAL(10,2) NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS idx_wallet_tx_wallet ON wallet_transactions(wallet_id);
CREATE INDEX IF NOT EXISTS idx_wallet_tx_user ON wallet_transactions(user_id);
CREATE INDEX IF NOT EXISTS idx_wallet_tx_type ON wallet_transactions(type);

-- ─── Updated_at trigger function ─────────────────
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ language 'plpgsql';

-- Apply trigger to all tables with updated_at
DO $$
DECLARE
  t TEXT;
BEGIN
  FOR t IN SELECT unnest(ARRAY['users', 'factories', 'products', 'zones', 'pools', 'orders', 'subscriptions', 'wallets'])
  LOOP
    EXECUTE format('
      DROP TRIGGER IF EXISTS update_%s_updated_at ON %s;
      CREATE TRIGGER update_%s_updated_at
        BEFORE UPDATE ON %s
        FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
    ', t, t, t, t);
  END LOOP;
END $$;

SELECT 'Migration completed successfully!' AS result;
`;

async function migrate() {
  console.log('🔄 Running FactoryLink database migration...\n');
  try {
    await connectDB();
    const pool = getPool();
    await pool.query(MIGRATION_SQL);
    console.log('✅ All tables created successfully!');
    console.log('   Tables: users, factories, products, zones, anchor_points,');
    console.log('           pools, orders, payments, ratings, subscriptions,');
    console.log('           notifications, otps, pool_assignments,');
    console.log('           wallets, wallet_transactions');
    process.exit(0);
  } catch (err) {
    console.error('❌ Migration failed:', err.message);
    process.exit(1);
  }
}

migrate();
