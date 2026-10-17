const express = require('express');
const { Checker, parseIdParam } = require('../validate');
const { conflict, notFound } = require('../errors');
const { userToJson } = require('../serialize');

const EMAIL_RE = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;

function usersRouter(db) {
  const router = express.Router();

  router.post('/', (req, res) => {
    const body = req.body;
    const check = new Checker();
    const name = check.string(body.name, 'name');
    const role = check.oneOf(body.role, 'role', ['customer', 'courier']);
    let email = check.string(body.email, 'email', { max: 254, optional: true });
    if (email !== null) {
      email = email.toLowerCase();
      if (!EMAIL_RE.test(email)) check.fail('email', 'must be a valid email address');
    }
    check.done();

    let id;
    try {
      ({ lastInsertRowid: id } = db
        .prepare('INSERT INTO users (name, email, role, created_at) VALUES (?, ?, ?, ?)')
        .run(name, email, role, new Date().toISOString()));
    } catch (err) {
      if (err.code === 'SQLITE_CONSTRAINT_UNIQUE') throw conflict('email_taken', 'A user with that email already exists');
      throw err;
    }
    res.status(201).json(userToJson(getUser(db, Number(id))));
  });

  router.get('/:id', (req, res) => {
    const id = parseIdParam(req.params.id);
    const user = getUser(db, id);
    if (!user) throw notFound(`User ${id} not found`);
    res.json(userToJson(user));
  });

  return router;
}

function getUser(db, id) {
  return db.prepare('SELECT * FROM users WHERE id = ?').get(id);
}

module.exports = { usersRouter, getUser };
