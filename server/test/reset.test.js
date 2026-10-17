const test = require('node:test');
const assert = require('node:assert/strict');
const { startServer, validOrder, COURIER } = require('./helpers');
const { resetDemoData } = require('../src/reset');

test('reset clears orders, extra users and earnings, and restarts ids', async () => {
  const api = await startServer();
  try {
    await api.request('POST', '/users', { name: 'Test Signup', role: 'customer' });
    const order = (await api.request('POST', '/orders', validOrder())).body;
    await api.request('PATCH', `/orders/${order.id}/accept`, { courierId: COURIER });
    await api.request('PATCH', `/orders/${order.id}/status`, { status: 'picked_up', courierId: COURIER });
    await api.request('PATCH', `/orders/${order.id}/status`, { status: 'delivered', courierId: COURIER });

    resetDemoData(api.db);

    assert.deepEqual((await api.request('GET', '/orders')).body, []);
    assert.equal((await api.request('GET', `/users/${COURIER}`)).body.earnings, 0);
    assert.equal((await api.request('GET', '/users/6')).status, 404);
    const users = api.db.prepare('SELECT id FROM users ORDER BY id').all().map((u) => u.id);
    assert.deepEqual(users, [1, 2, 3, 4, 5]);
    assert.ok((await api.request('GET', '/locations')).body.length > 0);

    const next = (await api.request('POST', '/orders', validOrder())).body;
    assert.equal(next.id, 1);
  } finally {
    await api.close();
  }
});
