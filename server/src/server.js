const config = require('./config');
const { openDb } = require('./db');
const { createApp } = require('./app');

const db = openDb(config.dbPath);
const app = createApp(db);

app.listen(config.port, () => {
  console.log(`Server listening on http://localhost:${config.port}`);
});
