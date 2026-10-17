const { seed } = require('./seed');

// Wipes all orders and users (including sign-ups made during testing), restarts
// ids at 1, and re-adds the demo data. Run before recording the demo.
function resetDemoData(db) {
  db.transaction(() => {
    db.exec(`
      DELETE FROM orders;
      DELETE FROM users;
      DELETE FROM locations;
      DELETE FROM sqlite_sequence WHERE name IN ('orders', 'users');
    `);
    seed(db);
  })();
}

module.exports = { resetDemoData };

if (require.main === module) {
  const config = require('./config');
  const { openDb } = require('./db');
  const db = openDb(config.dbPath);
  resetDemoData(db);
  const users = db.prepare('SELECT id, name, role FROM users ORDER BY id').all();
  console.log(`Demo data reset in ${config.dbPath}`);
  console.table(users);
  db.close();
}
