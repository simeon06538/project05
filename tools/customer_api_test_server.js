// Ephemeral server for the opt-in Flutter-to-Node smoke test; never touches delivery.db.
const { openDb } = require('../server/src/db');
const { seed } = require('../server/src/seed');
const { createApp } = require('../server/src/app');
const db = openDb(':memory:');
seed(db);
const server = createApp(db).listen(0, '127.0.0.1', () => {
  console.log(`http://127.0.0.1:${server.address().port}`);
});
process.on('SIGTERM', () => {
  server.closeAllConnections();
  server.close(() => { db.close(); process.exit(0); });
});
