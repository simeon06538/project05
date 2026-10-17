const test = require('node:test');
const assert = require('node:assert/strict');
const { deliveryFeeCents, tipToCents } = require('../src/pricing');

test('base fee only at the Union', () => {
  assert.equal(deliveryFeeCents(0), 200);
});

test('adds $0.50 per started 0.25 mi (rounds up)', () => {
  assert.equal(deliveryFeeCents(0.01), 250);
  assert.equal(deliveryFeeCents(0.1), 250);
  assert.equal(deliveryFeeCents(0.25), 250);
  assert.equal(deliveryFeeCents(0.26), 300);
  assert.equal(deliveryFeeCents(0.3), 300);
  assert.equal(deliveryFeeCents(0.5), 300);
  assert.equal(deliveryFeeCents(0.7), 350);
  assert.equal(deliveryFeeCents(0.75), 350);
  assert.equal(deliveryFeeCents(1.0), 400);
  assert.equal(deliveryFeeCents(1.1), 450);
});

test('exact multiples of 0.25 are not bumped by float error', () => {
  // 0.15 + 0.6 is 0.75000000000000001 in floating point.
  assert.equal(deliveryFeeCents(0.15 + 0.6), 350);
  assert.equal(deliveryFeeCents(0.1 + 0.2 + 0.2), 300);
});

test('caps at $6.00', () => {
  assert.equal(deliveryFeeCents(1.75), 550);
  assert.equal(deliveryFeeCents(2.0), 600);
  assert.equal(deliveryFeeCents(2.01), 600);
  assert.equal(deliveryFeeCents(50), 600);
});

test('rejects invalid distances', () => {
  for (const bad of [-0.1, NaN, Infinity, '1', null, undefined]) {
    assert.throws(() => deliveryFeeCents(bad), RangeError);
  }
});

test('tipToCents accepts the preset and custom tips', () => {
  assert.equal(tipToCents(0), 0);
  assert.equal(tipToCents(1), 100);
  assert.equal(tipToCents(3), 300);
  assert.equal(tipToCents(2.5), 250);
  assert.equal(tipToCents(0.1 + 0.2), 30);
  assert.equal(tipToCents(4.99), 499);
  assert.equal(tipToCents(50), 5000);
});

test('tipToCents rejects bad tips', () => {
  for (const bad of [-1, 1.234, 50.01, NaN, Infinity, '2', null, true]) {
    assert.equal(tipToCents(bad), null, `expected ${bad} to be rejected`);
  }
});
