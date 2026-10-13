const path = require('path');

module.exports = {
  port: Number(process.env.PORT) || 3000,
  // Use ':memory:' for tests; defaults to a file in server/data/.
  dbPath: process.env.DB_PATH || path.join(__dirname, '..', 'data', 'delivery.db'),
};
