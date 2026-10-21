const { test } = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const os = require('node:os');
const path = require('node:path');
const { openDb } = require('../src/db');
const { seed } = require('../src/seed');

test('existing databases migrate and keep users and order rows', () => {
  const dir = fs.mkdtempSync(path.join(os.tmpdir(), 'delivery-migration-'));
  const file = path.join(dir, 'delivery.db');
  let db;
  try {
    db = openDb(file);
    seed(db);
    db.prepare(`INSERT INTO orders (customer_id,pickup_location_id,dropoff_location_id,distance_miles,
      delivery_fee_cents,tip_cents,total_pay_cents,paw_points_order_number,created_at,updated_at)
      VALUES (1,'union','middleton-library',0.2,250,0,250,'PP-LEGACY','2026-10-01','2026-10-01')`).run();
    for (const column of ['order_name','pickup_restaurant']) db.exec(`ALTER TABLE orders DROP COLUMN ${column}`);
    for (const column of ['demo_x_miles','demo_y_miles','category']) db.exec(`ALTER TABLE locations DROP COLUMN ${column}`);
    db.close();
    db = openDb(file);
    seed(db);
    assert.equal(db.prepare('SELECT count(*) AS n FROM orders').get().n, 1);
    const row = db.prepare('SELECT * FROM orders').get();
    assert.equal(row.paw_points_order_number, 'PP-LEGACY');
    assert.equal(row.order_name, null);
    assert.equal(db.prepare("SELECT demo_x_miles FROM locations WHERE id='the-5'").get().demo_x_miles, -0.3);
    assert.equal(db.prepare('SELECT count(*) AS n FROM users').get().n, 5);
  } finally {
    if (db?.open) db.close();
    fs.rmSync(dir, {recursive:true,force:true});
  }
});
