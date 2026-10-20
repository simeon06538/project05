/// Existing demo destinations from server/src/seed-data.js.
/// Keep IDs and distances aligned with the server; additions belong to S-03.
class CampusLocation {
  const CampusLocation(this.id, this.name, this.distanceFromUnionMiles);
  final String id;
  final String name;
  final double distanceFromUnionMiles;
}

const campusLocations = <CampusLocation>[
  CampusLocation('union', 'LSU Student Union', 0),
  CampusLocation('middleton-library', 'Middleton Library', 0.2),
  CampusLocation('the-5', 'The 5 Dining Hall', 0.3),
  CampusLocation('pentagon', 'Pentagon Community', 0.35),
  CampusLocation('patrick-taylor-hall', 'Patrick F. Taylor Hall', 0.4),
  CampusLocation('tiger-stadium', 'Tiger Stadium', 0.45),
  CampusLocation('pmac', 'Pete Maravich Assembly Center', 0.5),
  CampusLocation('459-commons', '459 Commons', 0.6),
  CampusLocation('east-campus-apts', 'East Campus Apartments', 0.7),
  CampusLocation('urec', 'UREC Student Recreation Center', 0.9),
  CampusLocation('west-campus-apts', 'West Campus Apartments', 1.0),
  CampusLocation('nicholson-gateway', 'Nicholson Gateway', 1.1),
];
