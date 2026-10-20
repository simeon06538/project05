/// Customer-side delivery estimate, matching server/src/pricing.js.
/// Returns integer cents; tips and the food purchase are separate.
/// The server remains responsible for the final price when submitting an order.
int deliveryFeeCents(double distanceMiles) {
  if (!distanceMiles.isFinite || distanceMiles < 0) {
    throw RangeError.value(
      distanceMiles,
      'distanceMiles',
      'must be a finite, non-negative distance from the Union',
    );
  }

  const baseFeeCents = 200;
  const stepFeeCents = 50;
  const stepMiles = 0.25;
  const maxFeeCents = 600;

  // Also avoids overflowing the step calculation for very large distances.
  if (distanceMiles >= 2) return maxFeeCents;

  // Match the server's nine-decimal rounding before rounding steps up.
  // This prevents floating-point noise from adding an extra quarter-mile.
  final steps = double.parse((distanceMiles / stepMiles).toStringAsFixed(9))
      .ceil();
  final fee = baseFeeCents + steps * stepFeeCents;
  return fee > maxFeeCents ? maxFeeCents : fee;
}
