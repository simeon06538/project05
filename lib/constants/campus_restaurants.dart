/// Restaurant/building groupings from the user's LSU Dining screenshots
/// and their Panera location at Patrick F. Taylor Hall (PFT).
/// Hours and availability remain in LSU Dining, not this delivery demo.
class CampusRestaurant {
  const CampusRestaurant(this.name, this.pickupLocationId);
  final String name;
  final String pickupLocationId;
}

const campusRestaurants = <CampusRestaurant>[
  CampusRestaurant('Red Stick Subs', 'union'),
  CampusRestaurant('Death Valley Pizza', 'union'),
  CampusRestaurant('Prima Après', 'union'),
  CampusRestaurant('Smoothie King · Student Union', 'union'),
  CampusRestaurant('Chick-fil-A', 'union'),
  CampusRestaurant('Panda Express', 'union'),
  CampusRestaurant('CC Coffee · Student Union', 'union'),
  CampusRestaurant('Sonic', 'union'),
  CampusRestaurant('Einstein Bagel Bros', 'union'),
  CampusRestaurant('Food Locker', 'union'),
  CampusRestaurant('Sushi Nori', 'union'),
  CampusRestaurant('Tiger Traditions', 'union'),
  CampusRestaurant('Bibigo To Go', 'union'),
  CampusRestaurant('Popeyes', 'the-5'),
  CampusRestaurant('J Deckers', 'the-5'),
  CampusRestaurant('Smoothie King · UREC', 'urec'),
  CampusRestaurant('City Pork', 'art-design-building'),
  CampusRestaurant('CCs Law', 'law-center'),
  CampusRestaurant('CCs BEC', 'business-education-complex'),
  CampusRestaurant('WOW 459 Commons', '459-commons'),
  CampusRestaurant('Deli @ 459 Commons', '459-commons'),
  CampusRestaurant('CCs Library', 'middleton-library'),
  CampusRestaurant('PJs Coffee · Vet School', 'vet-school'),
  CampusRestaurant('City Sub', 'foster-hall'),
  CampusRestaurant('Panera Bread', 'patrick-taylor-hall'),
];

/// Unlisted restaurants and Panera do not use the LSU Dining order number.
bool usesMobileOrdering(String name) {
  String normalize(String value) =>
      value.trim().toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
  return campusRestaurants.any(
    (restaurant) =>
        restaurant.name != 'Panera Bread' &&
        normalize(restaurant.name) == normalize(name),
  );
}
