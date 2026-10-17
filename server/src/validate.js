const { validationError } = require('./errors');

// Collects field errors so the client gets all of them in one response.
class Checker {
  constructor() {
    this.details = [];
  }

  fail(field, message) {
    this.details.push({ field, message });
  }

  // Throws a 400 listing every failed field, if any.
  done() {
    if (this.details.length === 0) return;
    const message = this.details.map((d) => `${d.field} ${d.message}`).join('; ');
    throw validationError(message, this.details);
  }

  string(value, field, { min = 1, max = 100, optional = false } = {}) {
    if (value === undefined || value === null) {
      if (!optional) this.fail(field, 'is required');
      return null;
    }
    if (typeof value !== 'string') {
      this.fail(field, 'must be a string');
      return null;
    }
    const trimmed = value.trim();
    if (trimmed.length < min || trimmed.length > max) {
      this.fail(field, min === 1 ? `must be 1-${max} characters` : `must be ${min}-${max} characters`);
      return null;
    }
    return trimmed;
  }

  oneOf(value, field, allowed) {
    if (!allowed.includes(value)) {
      this.fail(field, `must be one of: ${allowed.join(', ')}`);
      return null;
    }
    return value;
  }

  id(value, field) {
    if (!isPositiveInt(value)) {
      this.fail(field, value === undefined ? 'is required' : 'must be a positive integer');
      return null;
    }
    return value;
  }
}

function isPositiveInt(value) {
  return Number.isSafeInteger(value) && value > 0;
}

// Parses an id from the URL path (e.g. /users/:id).
function parseIdParam(raw, name = 'id') {
  const value = /^\d+$/.test(raw) ? Number(raw) : NaN;
  if (!isPositiveInt(value)) {
    throw validationError(`${name} must be a positive integer`, [{ field: name, message: 'must be a positive integer' }]);
  }
  return value;
}

module.exports = { Checker, parseIdParam };
