const { test } = require('node:test');
const assert = require('node:assert/strict');
const { startServer, validOrder, CUSTOMER, OTHER_CUSTOMER, COURIER } = require('./helpers');
const catalog = require('../../assets/data/campus_locations.json');

test('catalog includes current halls and apartment communities; future halls excluded', async () => {
  const api = await startServer();
  try {
    const locations = (await api.request('GET', '/locations')).body;
    assert.equal(locations.length, catalog.length);
    assert.equal(locations.filter((item) => item.category === 'residence_hall').length, 23);
    for (const id of ['acadian-hall', 'lejeune-hall', 'west-laville-hall', 'east-campus-apts', 'nicholson-bayou']) {
      assert.ok(locations.some((item) => item.id === id));
    }
    assert.ok(!locations.some((item) => item.id === 'crane-hall' || item.id === 'pelican-hall'));
  } finally { await api.close(); }
});

test('food order metadata is saved and non-Union pickup determines distance and fee', async () => {
  const api = await startServer();
  try {
    const response = await api.request('POST', '/orders', validOrder({
      pickupLocation: 'the-5', dropoffLocation: 'spruce-hall',
      orderName: '  Taylor  ', pickupRestaurant: '  Popeyes  ', tip: 1,
      distanceMiles: 999, deliveryFee: 99,
    }));
    assert.equal(response.status, 201);
    assert.equal(response.body.orderName, 'Taylor');
    assert.equal(response.body.pickupRestaurant, 'Popeyes');
    assert.equal(response.body.distanceMiles, 0.104);
    assert.equal(response.body.deliveryFee, 2.5);
    assert.equal(response.body.totalPay, 3.5);
    const fetched = (await api.request('GET', `/orders/${response.body.id}`)).body;
    assert.equal(fetched.pickupRestaurant, 'Popeyes');
    const invalid = await api.request('POST', '/orders', validOrder({ orderName: ' ', pickupRestaurant: 'x'.repeat(101) }));
    assert.equal(invalid.status, 400);
  } finally { await api.close(); }
});

test('permanent deletion checks ownership and requested status; no history entry remains', async () => {
  const api = await startServer();
  try {
    const order = (await api.request('POST', '/orders', validOrder())).body;
    assert.equal((await api.request('DELETE', `/orders/${order.id}`, {customerId: OTHER_CUSTOMER})).status, 403);
    assert.equal((await api.request('DELETE', `/orders/${order.id}`, {customerId: CUSTOMER})).status, 204);
    assert.equal((await api.request('GET', `/orders/${order.id}`)).status, 404);
    assert.deepEqual((await api.request('GET', `/orders?customerId=${CUSTOMER}`)).body, []);
    const accepted = (await api.request('POST', '/orders', validOrder())).body;
    await api.request('PATCH', `/orders/${accepted.id}/accept`, {courierId: COURIER});
    assert.equal((await api.request('DELETE', `/orders/${accepted.id}`, {customerId: CUSTOMER})).status, 409);
    await api.request('PATCH', `/orders/${accepted.id}/status`, {courierId: COURIER, status: 'picked_up'});
    await api.request('PATCH', `/orders/${accepted.id}/status`, {courierId: COURIER, status: 'delivered'});
    assert.equal((await api.request('DELETE', `/orders/${accepted.id}`, {customerId: CUSTOMER})).status, 409);
    assert.equal((await api.request('GET', `/orders?customerId=${CUSTOMER}&status=delivered`)).body.length, 1);
    assert.match((await api.request('OPTIONS', '/orders')).headers.get('access-control-allow-methods'), /DELETE/);
  } finally { await api.close(); }
});
