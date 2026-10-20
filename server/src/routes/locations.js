const express = require('express');

function locationsRouter(db) {
  const router = express.Router();

  router.get('/', (req, res) => {
    const rows = db
      .prepare('SELECT * FROM locations ORDER BY distance_from_union_miles, name')
      .all();
    res.json(rows.map((r) => ({ id: r.id, name: r.name, distanceFromUnionMiles: r.distance_from_union_miles, demoXMiles: r.demo_x_miles, demoYMiles: r.demo_y_miles, category: r.category })));
  });

  return router;
}

module.exports = { locationsRouter };
