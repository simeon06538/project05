const STATUSES = ['requested', 'accepted', 'picked_up', 'delivered', 'cancelled'];

// requested -> accepted -> picked_up -> delivered, and requested -> cancelled.
const TRANSITIONS = {
  requested: ['accepted', 'cancelled'],
  accepted: ['picked_up'],
  picked_up: ['delivered'],
  delivered: [],
  cancelled: [],
};

function canTransition(from, to) {
  return (TRANSITIONS[from] ?? []).includes(to);
}

// Which user is allowed to move an order into each status.
// 'accepted' is handled by PATCH /orders/:id/accept, not the status endpoint.
const ACTOR_FOR_STATUS = {
  picked_up: 'courier',
  delivered: 'courier',
  cancelled: 'customer',
};

module.exports = { STATUSES, TRANSITIONS, canTransition, ACTOR_FOR_STATUS };
