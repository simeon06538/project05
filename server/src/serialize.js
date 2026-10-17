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
