const fs = require('fs');
const path = require('path');
const Database = require('better-sqlite3');

function openDb(dbPath) {
  if (dbPath !== ':memory:') {
    fs.mkdirSync(path.dirname(dbPath), { recursive: true });
  }
  const db = new Database(dbPath);
  db.pragma('journal_mode = WAL');
  db.pragma('foreign_keys = ON');
  // Tables are created in B-03.
  return db;
}

module.exports = { openDb };
