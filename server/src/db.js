const fs = require('fs');
const path = require('path');
const Database = require('better-sqlite3');

// Money is stored as integer cents so totals never pick up float rounding errors.
const SCHEMA = `
CREATE TABLE IF NOT EXISTS users (
  id             INTEGER PRIMARY KEY AUTOINCREMENT,
  name           TEXT    NOT NULL,
  email          TEXT    UNIQUE,
  role           TEXT    NOT NULL CHECK (role IN ('customer', 'courier')),
  earnings_cents INTEGER NOT NULL DEFAULT 0 CHECK (earnings_cents >= 0),
  created_at     TEXT    NOT NULL
);

CREATE TABLE IF NOT EXISTS locations (
  id                        TEXT PRIMARY KEY,
  name                      TEXT NOT NULL,
  distance_from_union_miles REAL NOT NULL CHECK (distance_from_union_miles >= 0)
);

CREATE TABLE IF NOT EXISTS orders (
  id                      INTEGER PRIMARY KEY AUTOINCREMENT,
  customer_id             INTEGER NOT NULL REFERENCES users(id),
  courier_id              INTEGER REFERENCES users(id),
  pickup_location_id      TEXT    NOT NULL REFERENCES locations(id),
  dropoff_location_id     TEXT    NOT NULL REFERENCES locations(id),
  distance_miles          REAL    NOT NULL,
  delivery_fee_cents      INTEGER NOT NULL,
  tip_cents               INTEGER NOT NULL DEFAULT 0 CHECK (tip_cents >= 0),
  total_pay_cents         INTEGER NOT NULL,
  status                  TEXT    NOT NULL DEFAULT 'requested'
                          CHECK (status IN ('requested', 'accepted', 'picked_up', 'delivered', 'cancelled')),
  paw_points_order_number TEXT    NOT NULL,
  created_at              TEXT    NOT NULL,
  updated_at              TEXT    NOT NULL,
  delivered_at            TEXT
);

CREATE INDEX IF NOT EXISTS idx_orders_status   ON orders(status);
CREATE INDEX IF NOT EXISTS idx_orders_customer ON orders(customer_id);
CREATE INDEX IF NOT EXISTS idx_orders_courier  ON orders(courier_id);
`;

function openDb(dbPath) {
  if (dbPath !== ':memory:') {
    fs.mkdirSync(path.dirname(dbPath), { recursive: true });
  }
  const db = new Database(dbPath);
  db.pragma('journal_mode = WAL');
  db.pragma('foreign_keys = ON');
  db.exec(SCHEMA);
  // Additive migrations preserve existing demo data and old client requests.
  for (const [table, columns] of Object.entries({
    locations: { demo_x_miles: 'REAL NOT NULL DEFAULT 0', demo_y_miles: 'REAL NOT NULL DEFAULT 0', category: "TEXT NOT NULL DEFAULT 'campus'" },
    orders: { order_name: 'TEXT', pickup_restaurant: 'TEXT' },
  })) {
    const existing = new Set(db.prepare(`PRAGMA table_info(${table})`).all().map((column) => column.name));
    for (const [name, type] of Object.entries(columns)) {
      if (!existing.has(name)) db.exec(`ALTER TABLE ${table} ADD COLUMN ${name} ${type}`);
    }
  }
  return db;
}

module.exports = { openDb };
