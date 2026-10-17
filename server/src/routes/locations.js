const express = require('express');

function locationsRouter(db) {
  const router = express.Router();

  router.get('/', (req, res) => {
    const rows = db
      .prepare('SELECT id, name, distance_from_union_miles FROM locations ORDER BY distance_from_union_miles, name')
      .all();
    res.json(rows.map((r) => ({ id: r.id, name: r.name, distanceFromUnionMiles: r.distance_from_union_miles })));
  });

  return router;
}

module.exports = { locationsRouter };
