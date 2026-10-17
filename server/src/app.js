const express = require('express');
const { locationsRouter } = require('./routes/locations');
const { usersRouter } = require('./routes/users');
const { ordersRouter } = require('./routes/orders');
const { errorHandler } = require('./errors');

// Builds the Express app around a database handle so tests can pass an
// in-memory DB. Route modules (B-05 to B-11) get mounted here.
function createApp(db) {
  const app = express();
  app.use(express.json());

  app.get('/health', (req, res) => {
    db.prepare('SELECT 1').get();
    res.json({ status: 'ok' });
  });

  app.use('/locations', locationsRouter(db));
  app.use('/users', usersRouter(db));
  app.use('/orders', ordersRouter(db));

  app.use((req, res) => {
    res.status(404).json({ error: 'Not found' });
  });
  app.use(errorHandler);

  return app;
}

module.exports = { createApp };
