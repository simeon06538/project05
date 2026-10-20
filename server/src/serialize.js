// Converts database rows (snake_case, cents) into API JSON (camelCase, dollars).
const toDollars = (cents) => cents / 100;

function userToJson(row) {
  return {
    id: row.id,
    name: row.name,
    email: row.email,
    role: row.role,
    earnings: toDollars(row.earnings_cents),
  };
}

module.exports = { toDollars, userToJson };

// Expects a row from ORDER_SELECT in routes/orders.js (orders joined with location names).
function orderToJson(row) {
  return {
    id: row.id,
    customerId: row.customer_id,
    courierId: row.courier_id,
    pickupLocation: row.pickup_location_id,
    pickupLocationName: row.pickup_location_name,
    dropoffLocation: row.dropoff_location_id,
    dropoffLocationName: row.dropoff_location_name,
    distanceMiles: row.distance_miles,
    deliveryFee: toDollars(row.delivery_fee_cents),
    tip: toDollars(row.tip_cents),
    totalPay: toDollars(row.total_pay_cents),
    status: row.status,
    pawPointsOrderNumber: row.paw_points_order_number,
    orderName: row.order_name,
    pickupRestaurant: row.pickup_restaurant,
    createdAt: row.created_at,
    updatedAt: row.updated_at,
  };
}

module.exports.orderToJson = orderToJson;
