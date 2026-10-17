const test = require('node:test');
const assert = require('node:assert/strict');
const { STATUSES, canTransition } = require('../src/status');

const ALLOWED = [
  ['requested', 'accepted'],
  ['requested', 'cancelled'],
  ['accepted', 'picked_up'],
  ['picked_up', 'delivered'],
];

test('allows the happy path and cancelling a requested order', () => {
  for (const [from, to] of ALLOWED) {
    assert.ok(canTransition(from, to), `${from} -> ${to} should be allowed`);
  }
});

test('rejects every other transition', () => {
  for (const from of STATUSES) {
    for (const to of STATUSES) {
      if (ALLOWED.some(([f, t]) => f === from && t === to)) continue;
      assert.equal(canTransition(from, to), false, `${from} -> ${to} should be rejected`);
    }
  }
});

test('delivered and cancelled are final', () => {
  for (const to of STATUSES) {
    assert.equal(canTransition('delivered', to), false);
    assert.equal(canTransition('cancelled', to), false);
  }
});

test('unknown statuses are rejected', () => {
  assert.equal(canTransition('bogus', 'accepted'), false);
  assert.equal(canTransition('requested', 'bogus'), false);
});
