const config = require('./config');
const { openDb } = require('./db');
const { seed } = require('./seed');
const { createApp } = require('./app');

const db = openDb(config.dbPath);
seed(db);
const app = createApp(db);

app.listen(config.port, () => {
  console.log(`Server listening on http://localhost:${config.port}`);
});
