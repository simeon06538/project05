// Shared campus catalog. See docs/locations.md for sources and estimate limitations.
const locations = require('../../assets/data/campus_locations.json');

const users = [
  { name: 'Alex Customer', email: 'alex.customer@example.edu', role: 'customer' },
  { name: 'Jordan Customer', email: 'jordan.customer@example.edu', role: 'customer' },
  { name: 'Sam Customer', email: 'sam.customer@example.edu', role: 'customer' },
  { name: 'Taylor Courier', email: 'taylor.courier@example.edu', role: 'courier' },
  { name: 'Riley Courier', email: 'riley.courier@example.edu', role: 'courier' },
];

module.exports = { locations, users };
