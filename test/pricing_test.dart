import 'package:campus_delivery/services/pricing.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('charges the base fee at the Union', () {
    expect(deliveryFeeCents(0), 200);
  });

  test('rounds each started quarter-mile up, matching the server examples', () {
    final cases = <double, int>{
      0.01: 250,
      0.1: 250,
      0.2: 250,
      0.25: 250,
      0.250001: 300,
      0.26: 300,
      0.3: 300,
      0.5: 300,
      0.500001: 350,
      0.7: 350,
      0.75: 350,
      1: 400,
      1.1: 450,
      1.75: 550,
      1.750001: 600,
    };
    for (final entry in cases.entries) {
      expect(
        deliveryFeeCents(entry.key),
        entry.value,
        reason: '${entry.key} miles',
      );
    }
  });

  test('does not charge an extra step for floating-point noise', () {
    expect(deliveryFeeCents(0.15 + 0.6), 350);
    expect(deliveryFeeCents(0.1 + 0.2 + 0.2), 300);
    expect(deliveryFeeCents(0.25 + 1e-12), 250);
  });

  test('caps delivery fees at six dollars, including very large distances', () {
    for (final miles in [2.0, 2.01, 3.0, 50.0, double.maxFinite]) {
      expect(deliveryFeeCents(miles), 600);
    }
  });

  test('rejects negative and non-finite distances', () {
    for (final miles in [
      -0.1,
      double.nan,
      double.infinity,
      double.negativeInfinity,
    ]) {
      expect(() => deliveryFeeCents(miles), throwsRangeError);
    }
  });
}
