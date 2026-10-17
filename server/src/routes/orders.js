const express = require('express');
const { Checker, parseIdParam } = require('../validate');
const { notFound } = require('../errors');
const { orderToJson } = require('../serialize');
const { deliveryFeeCents, tipToCents } = require('../pricing');
const { getUser } = require('./users');

const ORDER_SELECT = `
  SELECT o.*, p.name AS pickup_location_name, d.name AS dropoff_location_name
  FROM orders o
  JOIN locations p ON p.id = o.pickup_location_id
  JOIN locations d ON d.id = o.dropoff_location_id
`;

function ordersRouter(db) {
  const router = express.Router();
  const getLocation = db.prepare('SELECT * FROM locations WHERE id = ?');

  router.post('/', (req, res) => {
    const body = req.body ?? {};
    const check = new Checker();
    const customerId = check.id(body.customerId, 'customerId');
    const pickupId = check.string(body.pickupLocation, 'pickupLocation', { max: 64 });
    const dropoffId = check.string(body.dropoffLocation, 'dropoffLocation', { max: 64 });
    const pawPointsOrderNumber = check.string(body.pawPointsOrderNumber, 'pawPointsOrderNumber', { max: 40 });

    const pickup = pickupId && getLocation.get(pickupId);
    const dropoff = dropoffId && getLocation.get(dropoffId);
    if (pickupId && !pickup) check.fail('pickupLocation', `is not a known location: ${pickupId}`);
    if (dropoffId && !dropoff) check.fail('dropoffLocation', `is not a known location: ${dropoffId}`);
    if (pickup && dropoff && pickup.id === dropoff.id) check.fail('dropoffLocation', 'must be different from pickupLocation');

    const tipCents = body.tip === undefined || body.tip === null ? 0 : tipToCents(body.tip);
    if (tipCents === null) check.fail('tip', 'must be a number from 0 to 50 with at most 2 decimals');
    check.done();

    const customer = getUser(db, customerId);
    if (!customer || customer.role !== 'customer') throw notFound(`Customer ${customerId} not found`);

    // Fee is always recalculated here; any fee/total the client sent is ignored.
    const distanceMiles = dropoff.distance_from_union_miles;
    const feeCents = deliveryFeeCents(distanceMiles);
    const now = new Date().toISOString();
    const { lastInsertRowid } = db
      .prepare(`
        INSERT INTO orders (customer_id, pickup_location_id, dropoff_location_id, distance_miles,
          delivery_fee_cents, tip_cents, total_pay_cents, status, paw_points_order_number, created_at, updated_at)
        VALUES (?, ?, ?, ?, ?, ?, ?, 'requested', ?, ?, ?)
      `)
      .run(customerId, pickup.id, dropoff.id, distanceMiles, feeCents, tipCents, feeCents + tipCents,
        pawPointsOrderNumber, now, now);

    res.status(201).json(orderToJson(getOrder(db, Number(lastInsertRowid))));
  });

  router.get('/:id', (req, res) => {
    const id = parseIdParam(req.params.id);
    const order = getOrder(db, id);
    if (!order) throw notFound(`Order ${id} not found`);
    res.json(orderToJson(order));
  });

  return router;
}

function getOrder(db, id) {
  return db.prepare(`${ORDER_SELECT} WHERE o.id = ?`).get(id);
}

module.exports = { ordersRouter, getOrder, ORDER_SELECT };
