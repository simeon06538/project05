const { describe, test, beforeEach, afterEach } = require('node:test');
const assert = require('node:assert/strict');
const { startServer, validOrder, CUSTOMER, OTHER_CUSTOMER, COURIER, OTHER_COURIER } = require('./helpers');

let api;
beforeEach(async () => {
  api = await startServer();
});
afterEach(async () => {
  await api.close();
});

const request = (...args) => api.request(...args);

function assertError(res, status, code) {
  assert.equal(res.status, status, JSON.stringify(res.body));
  assert.equal(res.body.error.code, code);
  assert.equal(typeof res.body.error.message, 'string');
}

async function createOrder(overrides) {
  const res = await request('POST', '/orders', validOrder(overrides));
  assert.equal(res.status, 201, JSON.stringify(res.body));
  return res.body;
}

async function setStatus(orderId, status, courierId = COURIER) {
  const res = await request('PATCH', `/orders/${orderId}/status`, { status, courierId });
  assert.equal(res.status, 200, JSON.stringify(res.body));
  return res.body;
}

async function deliver(orderId, courierId = COURIER) {
  const res = await request('PATCH', `/orders/${orderId}/accept`, { courierId });
  assert.equal(res.status, 200, JSON.stringify(res.body));
  await setStatus(orderId, 'picked_up', courierId);
  return setStatus(orderId, 'delivered', courierId);
}

describe('general', () => {
  test('GET /health', async () => {
    const res = await request('GET', '/health');
    assert.equal(res.status, 200);
    assert.deepEqual(res.body, { status: 'ok' });
  });

  test('unknown route is a 404 in the standard error shape', async () => {
    assertError(await request('GET', '/nope'), 404, 'not_found');
  });

  test('malformed JSON is a 400', async () => {
    assertError(await request('POST', '/users', '{"name":', { raw: true }), 400, 'validation_error');
  });

  test('non-object JSON body is a 400', async () => {
    assertError(await request('POST', '/users', [1, 2]), 400, 'validation_error');
  });

  test('CORS headers are sent and preflight succeeds', async () => {
    const res = await request('OPTIONS', '/orders');
    assert.equal(res.status, 204);
    assert.equal(res.headers.get('access-control-allow-origin'), '*');
    assert.match(res.headers.get('access-control-allow-methods'), /PATCH/);
  });
});

describe('GET /locations', () => {
  test('lists seeded locations sorted by distance', async () => {
    const res = await request('GET', '/locations');
    assert.equal(res.status, 200);
    assert.ok(res.body.length >= 2);
    assert.deepEqual(res.body[0], { id: 'union', name: 'LSU Student Union', distanceFromUnionMiles: 0 });
    const distances = res.body.map((l) => l.distanceFromUnionMiles);
    assert.deepEqual(distances, [...distances].sort((a, b) => a - b));
  });
});

describe('users', () => {
  test('POST /users creates a user', async () => {
    const res = await request('POST', '/users', { name: '  Casey  ', role: 'courier', email: 'Casey@Example.edu' });
    assert.equal(res.status, 201);
    assert.deepEqual(res.body, { id: res.body.id, name: 'Casey', email: 'casey@example.edu', role: 'courier', earnings: 0 });

    const fetched = await request('GET', `/users/${res.body.id}`);
    assert.equal(fetched.status, 200);
    assert.deepEqual(fetched.body, res.body);
  });

  test('email is optional', async () => {
    const res = await request('POST', '/users', { name: 'No Email', role: 'customer' });
    assert.equal(res.status, 201);
    assert.equal(res.body.email, null);
  });

  test('POST /users reports every invalid field at once', async () => {
    const res = await request('POST', '/users', { name: '', role: 'admin', email: 'nope' });
    assertError(res, 400, 'validation_error');
    assert.deepEqual(res.body.error.details.map((d) => d.field).sort(), ['email', 'name', 'role']);
  });

  test('duplicate email is a 409', async () => {
    await request('POST', '/users', { name: 'A', role: 'customer', email: 'dup@example.edu' });
    assertError(await request('POST', '/users', { name: 'B', role: 'courier', email: 'DUP@example.edu' }), 409, 'email_taken');
  });

  test('GET /users/:id errors', async () => {
    assertError(await request('GET', '/users/999'), 404, 'not_found');
    assertError(await request('GET', '/users/abc'), 400, 'validation_error');
    assertError(await request('GET', '/users/0'), 400, 'validation_error');
  });
});

describe('POST /orders', () => {
  test('creates a requested order with server-calculated pricing', async () => {
    const order = await createOrder({ dropoffLocation: 'west-campus-apts', tip: 2 });
    assert.equal(order.status, 'requested');
    assert.equal(order.customerId, CUSTOMER);
    assert.equal(order.courierId, null);
    assert.equal(order.pickupLocationName, 'LSU Student Union');
    assert.equal(order.dropoffLocationName, 'West Campus Apartments');
    assert.equal(order.distanceMiles, 1);
    assert.equal(order.deliveryFee, 4);
    assert.equal(order.tip, 2);
    assert.equal(order.totalPay, 6);
    assert.equal(order.pawPointsOrderNumber, 'PP-1001');
    assert.ok(order.createdAt);
  });

  test('ignores fee, total and status sent by the client', async () => {
    const order = await createOrder({ deliveryFee: 0.01, totalPay: 0.01, distanceMiles: 0, status: 'delivered' });
    assert.equal(order.deliveryFee, 4);
    assert.equal(order.totalPay, 6);
    assert.equal(order.status, 'requested');
  });

  test('tip defaults to 0 and supports custom amounts', async () => {
    const noTip = validOrder();
    delete noTip.tip;
    const res = await request('POST', '/orders', noTip);
    assert.equal(res.body.tip, 0);
    assert.equal(res.body.totalPay, 4);
    assert.equal((await createOrder({ tip: 4.75 })).totalPay, 8.75);
  });

  test('validation errors', async () => {
    const cases = [
      [{ customerId: undefined }, 'customerId'],
      [{ customerId: 'one' }, 'customerId'],
      [{ pickupLocation: undefined }, 'pickupLocation'],
      [{ pickupLocation: 'mars' }, 'pickupLocation'],
      [{ dropoffLocation: 'union' }, 'dropoffLocation'],
      [{ tip: -1 }, 'tip'],
      [{ tip: 1.234 }, 'tip'],
      [{ tip: 51 }, 'tip'],
      [{ tip: '2' }, 'tip'],
      [{ pawPointsOrderNumber: '' }, 'pawPointsOrderNumber'],
      [{ pawPointsOrderNumber: 'x'.repeat(41) }, 'pawPointsOrderNumber'],
    ];
    for (const [overrides, field] of cases) {
      const res = await request('POST', '/orders', validOrder(overrides));
      assertError(res, 400, 'validation_error');
      assert.ok(res.body.error.details.some((d) => d.field === field), `${JSON.stringify(overrides)} should flag ${field}`);
    }
  });

  test('unknown customer, or a courier as the customer, is a 404', async () => {
    assertError(await request('POST', '/orders', validOrder({ customerId: 999 })), 404, 'not_found');
    assertError(await request('POST', '/orders', validOrder({ customerId: COURIER })), 404, 'not_found');
  });
});

describe('GET /orders', () => {
  test('filters by customer, courier and status', async () => {
    const a = await createOrder({ customerId: CUSTOMER });
    const b = await createOrder({ customerId: OTHER_CUSTOMER });
    const c = await createOrder({ customerId: CUSTOMER });
    await request('PATCH', `/orders/${b.id}/accept`, { courierId: COURIER });

    const ids = async (query) => (await request('GET', `/orders${query}`)).body.map((o) => o.id);
    assert.deepEqual(await ids(''), [c.id, b.id, a.id]);
    assert.deepEqual(await ids(`?customerId=${CUSTOMER}`), [c.id, a.id]);
    assert.deepEqual(await ids(`?courierId=${COURIER}`), [b.id]);
    assert.deepEqual(await ids('?status=requested'), [c.id, a.id]);
    assert.deepEqual(await ids(`?courierId=${COURIER}&status=accepted,picked_up`), [b.id]);
    assert.deepEqual(await ids(`?customerId=${CUSTOMER}&status=accepted`), []);
  });

  test('bad filters are a 400', async () => {
    assertError(await request('GET', '/orders?status=bogus'), 400, 'validation_error');
    assertError(await request('GET', '/orders?customerId=abc'), 400, 'validation_error');
    assertError(await request('GET', '/orders?courierId=-1'), 400, 'validation_error');
  });

  test('GET /orders/:id', async () => {
    const order = await createOrder();
    const res = await request('GET', `/orders/${order.id}`);
    assert.equal(res.status, 200);
    assert.deepEqual(res.body, order);
    assertError(await request('GET', '/orders/999'), 404, 'not_found');
  });
});

describe('PATCH /orders/:id/accept', () => {
  test('courier accepts a requested order', async () => {
    const order = await createOrder();
    const res = await request('PATCH', `/orders/${order.id}/accept`, { courierId: COURIER });
    assert.equal(res.status, 200);
    assert.equal(res.body.status, 'accepted');
    assert.equal(res.body.courierId, COURIER);
  });

  test('two couriers racing: exactly one wins', async () => {
    const order = await createOrder();
    const results = await Promise.all([
      request('PATCH', `/orders/${order.id}/accept`, { courierId: COURIER }),
      request('PATCH', `/orders/${order.id}/accept`, { courierId: OTHER_COURIER }),
    ]);
    assert.deepEqual(results.map((r) => r.status).sort(), [200, 409]);
    assertError(results.find((r) => r.status === 409), 409, 'already_accepted');
    const winner = results.find((r) => r.status === 200).body.courierId;
    assert.equal((await request('GET', `/orders/${order.id}`)).body.courierId, winner);
  });

  test('cannot accept a cancelled order', async () => {
    const order = await createOrder();
    await request('PATCH', `/orders/${order.id}/status`, { status: 'cancelled', customerId: CUSTOMER });
    assertError(await request('PATCH', `/orders/${order.id}/accept`, { courierId: COURIER }), 409, 'already_accepted');
  });

  test('courier with an active delivery cannot accept another', async () => {
    const first = await createOrder();
    const second = await createOrder();
    await request('PATCH', `/orders/${first.id}/accept`, { courierId: COURIER });
    assertError(await request('PATCH', `/orders/${second.id}/accept`, { courierId: COURIER }), 409, 'courier_busy');

    await setStatus(first.id, 'picked_up');
    assertError(await request('PATCH', `/orders/${second.id}/accept`, { courierId: COURIER }), 409, 'courier_busy');

    await setStatus(first.id, 'delivered');
    assert.equal((await request('PATCH', `/orders/${second.id}/accept`, { courierId: COURIER })).status, 200);
  });

  test('errors', async () => {
    const order = await createOrder();
    assertError(await request('PATCH', `/orders/${order.id}/accept`, {}), 400, 'validation_error');
    assertError(await request('PATCH', '/orders/999/accept', { courierId: COURIER }), 404, 'not_found');
    assertError(await request('PATCH', `/orders/${order.id}/accept`, { courierId: 999 }), 404, 'not_found');
    assertError(await request('PATCH', `/orders/${order.id}/accept`, { courierId: CUSTOMER }), 404, 'not_found');
  });
});

describe('PATCH /orders/:id/status', () => {
  test('full happy path', async () => {
    const order = await createOrder();
    await request('PATCH', `/orders/${order.id}/accept`, { courierId: COURIER });
    assert.equal((await setStatus(order.id, 'picked_up')).status, 'picked_up');
    assert.equal((await setStatus(order.id, 'delivered')).status, 'delivered');
  });

  test('cannot skip steps or go backwards', async () => {
    const order = await createOrder();
    const attempt = (status) => request('PATCH', `/orders/${order.id}/status`, { status, courierId: COURIER });
    assertError(await attempt('delivered'), 409, 'invalid_transition');
    await request('PATCH', `/orders/${order.id}/accept`, { courierId: COURIER });
    assertError(await attempt('delivered'), 409, 'invalid_transition');
    await setStatus(order.id, 'picked_up');
    assertError(await attempt('picked_up'), 409, 'invalid_transition');
    await setStatus(order.id, 'delivered');
    assertError(await attempt('picked_up'), 409, 'invalid_transition');
  });

  test('customer can cancel only while requested', async () => {
    const order = await createOrder();
    const res = await request('PATCH', `/orders/${order.id}/status`, { status: 'cancelled', customerId: CUSTOMER });
    assert.equal(res.status, 200);
    assert.equal(res.body.status, 'cancelled');

    const accepted = await createOrder();
    await request('PATCH', `/orders/${accepted.id}/accept`, { courierId: COURIER });
    assertError(await request('PATCH', `/orders/${accepted.id}/status`, { status: 'cancelled', customerId: CUSTOMER }), 409, 'invalid_transition');
  });

  test('only the order\'s own courier or customer may update it', async () => {
    const order = await createOrder();
    assertError(await request('PATCH', `/orders/${order.id}/status`, { status: 'cancelled', customerId: OTHER_CUSTOMER }), 403, 'forbidden');
    await request('PATCH', `/orders/${order.id}/accept`, { courierId: COURIER });
    assertError(await request('PATCH', `/orders/${order.id}/status`, { status: 'picked_up', courierId: OTHER_COURIER }), 403, 'forbidden');
  });

  test('validation errors', async () => {
    const order = await createOrder();
    const attempt = (body) => request('PATCH', `/orders/${order.id}/status`, body);
    assertError(await attempt({}), 400, 'validation_error');
    assertError(await attempt({ status: 'accepted', courierId: COURIER }), 400, 'validation_error');
    assertError(await attempt({ status: 'requested', customerId: CUSTOMER }), 400, 'validation_error');
    assertError(await attempt({ status: 'picked_up' }), 400, 'validation_error');
    assertError(await attempt({ status: 'cancelled', courierId: COURIER }), 400, 'validation_error');
    assertError(await request('PATCH', '/orders/999/status', { status: 'cancelled', customerId: CUSTOMER }), 404, 'not_found');
  });
});

describe('earnings', () => {
  test('delivering adds totalPay to the courier balance exactly once', async () => {
    const order = await createOrder({ tip: 1.25, dropoffLocation: 'pmac' }); // $3.00 fee + $1.25 tip
    await deliver(order.id);
    assert.equal((await request('GET', `/users/${COURIER}`)).body.earnings, 4.25);

    const again = await request('PATCH', `/orders/${order.id}/status`, { status: 'delivered', courierId: COURIER });
    assertError(again, 409, 'invalid_transition');
    assert.equal((await request('GET', `/users/${COURIER}`)).body.earnings, 4.25);
    assert.equal((await request('GET', `/users/${OTHER_COURIER}`)).body.earnings, 0);
  });

  test('GET /couriers/:id/earnings returns balance and history', async () => {
    const first = await createOrder({ tip: 0, dropoffLocation: 'middleton-library' }); // $2.50
    const second = await createOrder({ tip: 3, dropoffLocation: 'nicholson-gateway' }); // $4.50 + $3 tip
    await createOrder(); // still requested, so not in the history
    await deliver(first.id);
    await deliver(second.id);

    const res = await request('GET', `/couriers/${COURIER}/earnings`);
    assert.equal(res.status, 200);
    assert.equal(res.body.courierId, COURIER);
    assert.equal(res.body.earnings, 10);
    assert.equal(res.body.deliveryCount, 2);
    assert.deepEqual(res.body.deliveries.map((d) => d.totalPay).sort(), [2.5, 7.5]);
    const d = res.body.deliveries.find((x) => x.orderId === second.id);
    assert.equal(d.deliveryFee, 4.5);
    assert.equal(d.tip, 3);
    assert.equal(d.dropoffLocationName, 'Nicholson Gateway');
    assert.ok(d.deliveredAt);
  });

  test('earnings errors', async () => {
    assertError(await request('GET', '/couriers/999/earnings'), 404, 'not_found');
    assertError(await request('GET', `/couriers/${CUSTOMER}/earnings`), 404, 'not_found');
    assertError(await request('GET', '/couriers/x/earnings'), 400, 'validation_error');
  });
});
