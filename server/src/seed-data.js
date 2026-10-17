// Campus locations with an approximate straight-line distance from the LSU
// Student Union. Placeholder until the team agrees on the shared list (S-03);
// keep the Flutter constants file in sync with this one.
const locations = [
  { id: 'union', name: 'LSU Student Union', distanceFromUnionMiles: 0 },
  { id: 'middleton-library', name: 'Middleton Library', distanceFromUnionMiles: 0.2 },
  { id: 'the-5', name: 'The 5 Dining Hall', distanceFromUnionMiles: 0.3 },
  { id: 'pentagon', name: 'Pentagon Community', distanceFromUnionMiles: 0.35 },
  { id: 'patrick-taylor-hall', name: 'Patrick F. Taylor Hall', distanceFromUnionMiles: 0.4 },
  { id: 'tiger-stadium', name: 'Tiger Stadium', distanceFromUnionMiles: 0.45 },
  { id: 'pmac', name: 'Pete Maravich Assembly Center', distanceFromUnionMiles: 0.5 },
  { id: '459-commons', name: '459 Commons', distanceFromUnionMiles: 0.6 },
  { id: 'east-campus-apts', name: 'East Campus Apartments', distanceFromUnionMiles: 0.7 },
  { id: 'urec', name: 'UREC Student Recreation Center', distanceFromUnionMiles: 0.9 },
  { id: 'west-campus-apts', name: 'West Campus Apartments', distanceFromUnionMiles: 1.0 },
  { id: 'nicholson-gateway', name: 'Nicholson Gateway', distanceFromUnionMiles: 1.1 },
];

const users = [
  { name: 'Alex Customer', email: 'alex.customer@example.edu', role: 'customer' },
  { name: 'Jordan Customer', email: 'jordan.customer@example.edu', role: 'customer' },
  { name: 'Sam Customer', email: 'sam.customer@example.edu', role: 'customer' },
  { name: 'Taylor Courier', email: 'taylor.courier@example.edu', role: 'courier' },
  { name: 'Riley Courier', email: 'riley.courier@example.edu', role: 'courier' },
];

module.exports = { locations, users };
