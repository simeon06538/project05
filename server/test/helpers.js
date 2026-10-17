const { openDb } = require('../src/db');
const { seed } = require('../src/seed');
const { createApp } = require('../src/app');

// Seeded ids (see src/seed-data.js): customers 1-3, couriers 4-5.
const CUSTOMER = 1;
const OTHER_CUSTOMER = 2;
const COURIER = 4;
const OTHER_COURIER = 5;

// Starts the app on a random port with a fresh in-memory database.
async function startServer() {
  const db = openDb(':memory:');
  seed(db);
  const server = createApp(db).listen(0);
  await new Promise((resolve) => server.once('listening', resolve));
  const base = `http://127.0.0.1:${server.address().port}`;

  async function request(method, path, body, { raw = false } = {}) {
    const init = { method, headers: {} };
    if (body !== undefined) {
      init.headers['content-type'] = 'application/json';
      init.body = raw ? body : JSON.stringify(body);
    }
    const res = await fetch(base + path, init);
    const text = await res.text();
    return { status: res.status, headers: res.headers, body: text ? JSON.parse(text) : null };
  }

  async function close() {
    await new Promise((resolve) => server.close(resolve));
    db.close();
  }

  return { db, request, close };
}

const validOrder = (overrides = {}) => ({
  customerId: CUSTOMER,
  pickupLocation: 'union',
  dropoffLocation: 'west-campus-apts',
  tip: 2,
  pawPointsOrderNumber: 'PP-1001',
  ...overrides,
});

module.exports = { startServer, validOrder, CUSTOMER, OTHER_CUSTOMER, COURIER, OTHER_COURIER };
