const config = require('./config');
const { openDb } = require('./db');
const { seed } = require('./seed');
const { createApp } = require('./app');

const db = openDb(config.dbPath);
seed(db);
const app = createApp(db, { corsOrigin: config.corsOrigin });

app.listen(config.port, config.host, () => {
  console.log(`Server listening on http://localhost:${config.port} (bound to ${config.host})`);
  console.log(`Android emulator: http://10.0.2.2:${config.port}`);
});
