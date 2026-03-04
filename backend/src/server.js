/**
 * FactoryLink Backend — Main Server
 * TRD v1.0 — Node.js + Express
 * 
 * Architecture: Microservices backend. REST API. Event-driven notifications.
 * Base URL: https://api.factorylink.in/v1
 */

require('dotenv').config();
const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const morgan = require('morgan');
const http = require('http');
const { Server: SocketServer } = require('socket.io');

const { connectDB } = require('./database/connection');
const { connectRedis } = require('./cache/redis');
const { initFirebase } = require('./services/firebase');
const { startCronJobs, stopCronJobs } = require('./services/cronJobs');
const { initRazorpay } = require('./services/paymentGateway');

// Route imports
const authRoutes = require('./routes/auth');
const productRoutes = require('./routes/products');
const orderRoutes = require('./routes/orders');
const factoryRoutes = require('./routes/factory');
const zoneRoutes = require('./routes/zones');
const subscriptionRoutes = require('./routes/subscriptions');
const adminRoutes = require('./routes/admin');
const uploadRoutes = require('./routes/uploads');
const notificationRoutes = require('./routes/notifications');
const walletRoutes = require('./routes/wallet');
const paymentRoutes = require('./routes/payments');

// Middleware imports
const { errorHandler } = require('./middleware/errorHandler');
const { rateLimiter } = require('./middleware/rateLimiter');

const app = express();
const server = http.createServer(app);
const io = new SocketServer(server, {
  cors: { origin: '*', methods: ['GET', 'POST'] }
});

// ─── GLOBAL MIDDLEWARE ───────────────────────────────
app.use(helmet());
app.use(cors());
app.use(morgan('combined'));
app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true }));
app.use(rateLimiter);

// ─── HEALTH CHECK ────────────────────────────────────
app.get('/health', (req, res) => {
  res.json({ status: 'ok', service: 'factorylink-api', version: '1.0.0', timestamp: new Date().toISOString() });
});

// ─── API ROUTES (v1) ────────────────────────────────
app.use('/v1/auth', authRoutes);
app.use('/v1/products', productRoutes);
app.use('/v1/orders', orderRoutes);
app.use('/v1/factory', factoryRoutes);
app.use('/v1/zones', zoneRoutes);
app.use('/v1/subscriptions', subscriptionRoutes);
app.use('/v1/admin', adminRoutes);
app.use('/v1/uploads', uploadRoutes);
app.use('/v1/notifications', notificationRoutes);
app.use('/v1/wallet', walletRoutes);
app.use('/v1/payments', paymentRoutes);

// ─── 404 HANDLER ─────────────────────────────────────
app.use((req, res) => {
  res.status(404).json({ error: 'Endpoint not found', message: `${req.method} ${req.path} does not exist` });
});

// ─── ERROR HANDLER ───────────────────────────────────
app.use(errorHandler);

// ─── SOCKET.IO for real-time pool updates ────────────
io.on('connection', (socket) => {
  console.log(`🔌 Client connected: ${socket.id}`);

  socket.on('join:pool', (poolId) => {
    socket.join(`pool:${poolId}`);
    console.log(`📦 ${socket.id} joined pool:${poolId}`);
  });

  socket.on('join:zone', (zoneId) => {
    socket.join(`zone:${zoneId}`);
  });

  socket.on('disconnect', () => {
    console.log(`❌ Client disconnected: ${socket.id}`);
  });
});

// Make io accessible to routes
app.set('io', io);

// ─── STARTUP ─────────────────────────────────────────
const PORT = process.env.PORT || 3000;

async function startServer() {
  try {
    // Connect to PostgreSQL
    await connectDB();
    console.log('✅ PostgreSQL connected');

    // Connect to Redis
    await connectRedis();
    console.log('✅ Redis connected');

    // Initialize Firebase Admin SDK
    initFirebase();
    console.log('✅ Firebase initialized');

    // Initialize Razorpay
    initRazorpay();
    console.log('✅ Razorpay initialized');

    // Start server
    server.listen(PORT, () => {
      console.log(`\n🚀 FactoryLink API running on port ${PORT}`);
      console.log(`📍 Base URL: http://localhost:${PORT}/v1`);
      console.log(`🔌 WebSocket ready on port ${PORT}`);
      console.log(`📊 Environment: ${process.env.NODE_ENV || 'development'}\n`);

      // Start background cron jobs (pool engine)
      startCronJobs();
    });
  } catch (err) {
    console.error('❌ Failed to start server:', err.message);
    process.exit(1);
  }
}

startServer();

// ─── GRACEFUL SHUTDOWN ──────────────────────────────
process.on('SIGTERM', () => {
  console.log('\n🛑 SIGTERM received. Shutting down gracefully...');
  stopCronJobs();
  server.close(() => {
    console.log('✅ Server closed.');
    process.exit(0);
  });
});

process.on('SIGINT', () => {
  console.log('\n🛑 SIGINT received. Shutting down...');
  stopCronJobs();
  server.close(() => process.exit(0));
});

module.exports = { app, io };
