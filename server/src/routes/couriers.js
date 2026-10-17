const express = require('express');
const { parseIdParam } = require('../validate');
const { notFound } = require('../errors');
const { toDollars } = require('../serialize');
const { getUser } = require('./users');
const { ORDER_SELECT } = require('./orders');

function couriersRouter(db) {
  const router = express.Router();

  router.get('/:id/earnings', (req, res) => {
    const id = parseIdParam(req.params.id);
    const courier = getUser(db, id);
    if (!courier || courier.role !== 'courier') throw notFound(`Courier ${id} not found`);

    const rows = db
      .prepare(`${ORDER_SELECT} WHERE o.courier_id = ? AND o.status = 'delivered' ORDER BY o.delivered_at DESC, o.id DESC`)
      .all(id);

    res.json({
      courierId: id,
      earnings: toDollars(courier.earnings_cents),
      deliveryCount: rows.length,
      deliveries: rows.map((r) => ({
        orderId: r.id,
        pickupLocation: r.pickup_location_id,
        pickupLocationName: r.pickup_location_name,
        dropoffLocation: r.dropoff_location_id,
        dropoffLocationName: r.dropoff_location_name,
        deliveryFee: toDollars(r.delivery_fee_cents),
        tip: toDollars(r.tip_cents),
        totalPay: toDollars(r.total_pay_cents),
        deliveredAt: r.delivered_at,
      })),
    });
  });

  return router;
}

module.exports = { couriersRouter };
