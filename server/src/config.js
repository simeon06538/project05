const path = require('path');

module.exports = {
  port: Number(process.env.PORT) || 3000,
  // 0.0.0.0 so the Android emulator (10.0.2.2) and phones on the same Wi-Fi can connect.
  host: process.env.HOST || '0.0.0.0',
  // Allowed browser origin(s) for Flutter web, comma-separated. '*' allows any.
  corsOrigin: process.env.CORS_ORIGIN || '*',
  // Use ':memory:' for tests; defaults to a file in server/data/.
  dbPath: process.env.DB_PATH || path.join(__dirname, '..', 'data', 'delivery.db'),
};
