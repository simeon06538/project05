const seedData = require('./seed-data');

// Locations are upserted every time so edits to seed-data.js take effect.
// Demo users are only added to an empty users table, so real sign-ups are kept.
function seed(db) {
  const upsertLocation = db.prepare(`
    INSERT INTO locations (id, name, distance_from_union_miles, demo_x_miles, demo_y_miles, category)
    VALUES (@id, @name, @distanceFromUnionMiles, @demoXMiles, @demoYMiles, @category)
    ON CONFLICT (id) DO UPDATE SET
      name = excluded.name,
      distance_from_union_miles = excluded.distance_from_union_miles,
      demo_x_miles = excluded.demo_x_miles, demo_y_miles = excluded.demo_y_miles, category = excluded.category
  `);
  const insertUser = db.prepare(`
    INSERT INTO users (name, email, role, created_at)
    VALUES (@name, @email, @role, @createdAt)
  `);

  db.transaction(() => {
    for (const location of seedData.locations) upsertLocation.run(location);

    const { count } = db.prepare('SELECT COUNT(*) AS count FROM users').get();
    if (count === 0) {
      const createdAt = new Date().toISOString();
      for (const user of seedData.users) insertUser.run({ ...user, createdAt });
    }
  })();
}

module.exports = { seed };

if (require.main === module) {
  const config = require('./config');
  const { openDb } = require('./db');
  const db = openDb(config.dbPath);
  seed(db);
  const users = db.prepare('SELECT id, name, role FROM users ORDER BY id').all();
  console.log(`Seeded ${seedData.locations.length} locations. Users:`);
  console.table(users);
  db.close();
}
