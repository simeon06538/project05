const express = require('express');
const { locationsRouter } = require('./routes/locations');
const { usersRouter } = require('./routes/users');
const { ordersRouter } = require('./routes/orders');
const { couriersRouter } = require('./routes/couriers');
const { cors } = require('./cors');
const { errorHandler, notFound, validationError } = require('./errors');

// Builds the Express app around a database handle so tests can pass an
// in-memory DB.
function createApp(db, { corsOrigin = '*' } = {}) {
  const app = express();
  app.use(cors(corsOrigin));
  app.use(express.json({ limit: '10kb' }));

  // Routes can always read req.body as a plain object.
  app.use((req, res, next) => {
    if (req.body === undefined) req.body = {};
    if (typeof req.body !== 'object' || req.body === null || Array.isArray(req.body)) {
      throw validationError('Request body must be a JSON object');
    }
    next();
  });

  app.get('/health', (req, res) => {
    db.prepare('SELECT 1').get();
    res.json({ status: 'ok' });
  });

  app.use('/locations', locationsRouter(db));
  app.use('/users', usersRouter(db));
  app.use('/orders', ordersRouter(db));
  app.use('/couriers', couriersRouter(db));

  app.use((req, res) => {
    throw notFound(`No route for ${req.method} ${req.path}`);
  });
  app.use(errorHandler);

  return app;
}

module.exports = { createApp };
