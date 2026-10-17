const express = require('express');
const { Checker, parseIdParam } = require('../validate');
const { conflict, forbidden, notFound } = require('../errors');
const { orderToJson } = require('../serialize');
const { deliveryFeeCents, tipToCents } = require('../pricing');
const { getUser } = require('./users');
const { STATUSES, canTransition, ACTOR_FOR_STATUS } = require('../status');

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
    const body = req.body;
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

  // Filters: ?customerId=1, ?courierId=3, ?status=requested or status=accepted,picked_up.
  router.get('/', (req, res) => {
    const check = new Checker();
    const where = [];
    const params = [];

    for (const field of ['customerId', 'courierId']) {
      const raw = req.query[field];
      if (raw === undefined) continue;
      if (typeof raw !== 'string' || !/^\d+$/.test(raw) || Number(raw) < 1) {
        check.fail(field, 'must be a positive integer');
        continue;
      }
      where.push(field === 'customerId' ? 'o.customer_id = ?' : 'o.courier_id = ?');
      params.push(Number(raw));
    }

    if (req.query.status !== undefined) {
      const statuses = [req.query.status].flat().join(',').split(',').map((s) => s.trim());
      const bad = statuses.filter((s) => !STATUSES.includes(s));
      if (bad.length > 0) {
        check.fail('status', `must be one or more of: ${STATUSES.join(', ')}`);
      } else {
        where.push(`o.status IN (${statuses.map(() => '?').join(', ')})`);
        params.push(...statuses);
      }
    }
    check.done();

    const sql = `${ORDER_SELECT} ${where.length ? `WHERE ${where.join(' AND ')}` : ''} ORDER BY o.created_at DESC, o.id DESC`;
    res.json(db.prepare(sql).all(...params).map(orderToJson));
  });

  router.get('/:id', (req, res) => {
    const id = parseIdParam(req.params.id);
    const order = getOrder(db, id);
    if (!order) throw notFound(`Order ${id} not found`);
    res.json(orderToJson(order));
  });

  // Runs as one IMMEDIATE transaction (write lock taken up front), and the UPDATE
  // only matches while the order is still 'requested', so if two couriers race
  // exactly one of them gets the order.
  const acceptOrder = db.transaction((orderId, courierId) => {
    if (!getOrder(db, orderId)) throw notFound(`Order ${orderId} not found`);
    const courier = getUser(db, courierId);
    if (!courier || courier.role !== 'courier') throw notFound(`Courier ${courierId} not found`);

    const active = db
      .prepare("SELECT id FROM orders WHERE courier_id = ? AND status IN ('accepted', 'picked_up') LIMIT 1")
      .get(courierId);
    if (active) throw conflict('courier_busy', `Courier ${courierId} already has an active delivery (order ${active.id})`);

    const { changes } = db
      .prepare("UPDATE orders SET status = 'accepted', courier_id = ?, updated_at = ? WHERE id = ? AND status = 'requested'")
      .run(courierId, new Date().toISOString(), orderId);
    if (changes === 0) throw conflict('already_accepted', `Order ${orderId} is no longer available`);

    return getOrder(db, orderId);
  });

  router.patch('/:id/accept', (req, res) => {
    const orderId = parseIdParam(req.params.id);
    const check = new Checker();
    const courierId = check.id(req.body.courierId, 'courierId');
    check.done();
    res.json(orderToJson(acceptOrder.immediate(orderId, courierId)));
  });

  const updateStatus = db.transaction((orderId, status, actorRole, actorId) => {
    const order = getOrder(db, orderId);
    if (!order) throw notFound(`Order ${orderId} not found`);
    if (!canTransition(order.status, status)) {
      throw conflict('invalid_transition', `Cannot change order ${orderId} from ${order.status} to ${status}`);
    }
    const ownerId = actorRole === 'courier' ? order.courier_id : order.customer_id;
    if (ownerId !== actorId) {
      throw forbidden(`${actorRole === 'courier' ? 'Courier' : 'Customer'} ${actorId} is not on order ${orderId}`);
    }

    const now = new Date().toISOString();
    const { changes } = db
      .prepare('UPDATE orders SET status = ?, updated_at = ?, delivered_at = ? WHERE id = ? AND status = ?')
      .run(status, now, status === 'delivered' ? now : null, orderId, order.status);
    if (changes === 0) throw conflict('invalid_transition', `Order ${orderId} changed while updating; try again`);

    // Same transaction as the status change, so pay is credited exactly once.
    if (status === 'delivered') {
      db.prepare('UPDATE users SET earnings_cents = earnings_cents + ? WHERE id = ?')
        .run(order.total_pay_cents, order.courier_id);
    }

    return getOrder(db, orderId);
  });

  router.patch('/:id/status', (req, res) => {
    const orderId = parseIdParam(req.params.id);
    const body = req.body;
    const check = new Checker();
    if (body.status === 'accepted') check.fail('status', 'cannot be accepted here; use PATCH /orders/:id/accept');
    const status = body.status === 'accepted' ? null : check.oneOf(body.status, 'status', Object.keys(ACTOR_FOR_STATUS));
    const actorRole = ACTOR_FOR_STATUS[status];
    const actorField = actorRole === 'courier' ? 'courierId' : 'customerId';
    const actorId = status && check.id(body[actorField], actorField);
    check.done();
    res.json(orderToJson(updateStatus.immediate(orderId, status, actorRole, actorId)));
  });

  return router;
}

function getOrder(db, id) {
  return db.prepare(`${ORDER_SELECT} WHERE o.id = ?`).get(id);
}

module.exports = { ordersRouter, getOrder, ORDER_SELECT };
