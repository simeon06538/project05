// Delivery fee: $2.00 base + $0.50 per started 0.25 mi of estimated delivery distance, capped at $6.00.
// Everything is in integer cents. Must match the client's lib/services/pricing.dart.
const BASE_FEE_CENTS = 200;
const STEP_FEE_CENTS = 50;
const STEP_MILES = 0.25;
const MAX_FEE_CENTS = 600;
const MAX_TIP_CENTS = 5000;

function deliveryFeeCents(distanceMiles) {
  if (typeof distanceMiles !== 'number' || !Number.isFinite(distanceMiles) || distanceMiles < 0) {
    throw new RangeError('distanceMiles must be a non-negative number');
  }
  // toFixed drops float noise so e.g. 0.75 / 0.25 is exactly 3 steps, not 3.0000000001.
  const steps = Math.ceil(Number((distanceMiles / STEP_MILES).toFixed(9)));
  return Math.min(BASE_FEE_CENTS + steps * STEP_FEE_CENTS, MAX_FEE_CENTS);
}

// Converts a dollar tip to cents, or returns null if it isn't a valid tip
// (0 to $50 with at most 2 decimal places).
function tipToCents(tip) {
  if (typeof tip !== 'number' || !Number.isFinite(tip) || tip < 0) return null;
  const cents = Math.round(tip * 100);
  if (Math.abs(tip * 100 - cents) > 1e-6 || cents > MAX_TIP_CENTS) return null;
  return cents;
}

module.exports = { deliveryFeeCents, tipToCents, MAX_TIP_CENTS };

// Coarse straight-line demo estimate, rounded identically by the Dart client.
function routeDistanceMiles(pickup, dropoff) {
  if (pickup.id === 'union') return dropoff.distance_from_union_miles;
  if (dropoff.id === 'union') return pickup.distance_from_union_miles;
  return Number(Math.hypot(dropoff.demo_x_miles - pickup.demo_x_miles,
    dropoff.demo_y_miles - pickup.demo_y_miles).toFixed(3));
}
module.exports.routeDistanceMiles = routeDistanceMiles;
