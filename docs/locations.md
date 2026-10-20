# Campus location catalog

Verified October 20, 2026 using LSU sources:

- [LSU Residential Life housing comparison](https://www.lsu.edu/housing/options/at-a-glance.php): 23 residence halls and three apartment communities. Pentagon halls are individual destinations. Crane and Pelican Halls are excluded because this source lists their opening as fall 2027.
- [LSU housing options and campus areas](https://www.lsu.edu/housing/options/index.php).
- [LSU Living on Campus handbook](https://www.lsu.edu/housing/files/loc_handbook/loc_handbook.pdf): Nicholson Gateway's Bayou, Canal, Delta, Gulf, Marsh, Oxbow, and Riverbend buildings. These are additional apartment destinations, not seven additional communities.
- [LSU Popeyes announcement](https://www.lsu.edu/auxiliary-services/news/2022/popeyes-press-release.php): Popeyes pickup is at The 5 Dining Hall.

The 47 destinations include the existing campus landmarks, all 23 listed currently available residence halls, three apartment communities, and seven Nicholson Gateway building options. This is not every LSU academic building or off-campus apartment complex. The three apartment communities can use their main meeting points; individual East/West Campus apartment units are not listed.

The currently offered student-housing list is the scope: [Louise Garig Hall](https://www.lsu.edu/housing/options/halls/louise-garig.php) is not a student room-selection option. [East Hall](https://discover.lsu.edu/housing/options/residential-colleges/arts.php) houses the faculty-in-residence apartment; neither is presented as a student residence-hall option here.

## One shared catalog

Edit `assets/data/campus_locations.json`, then run `python3 tools/generate_locations.py` and `dart format lib/constants/campus_locations.dart`. The server seeds directly from JSON; Flutter uses the generated constants. Server startup upserts added locations without resetting existing orders or users.

## Demo distance estimates

LSU sources establish the destination names and general campus areas. **The numeric distances and `demoXMiles`/`demoYMiles` offsets are project-authored, coarse schematic estimates; they are not LSU-provided measurements, GPS coordinates, walking directions, or an accessibility routing service.** The original Union distance estimates are retained for compatibility with the team's demo pricing.

Union pickups use the destination's `distanceFromUnionMiles`. Other pickups use the straight-line distance between the two schematic offsets, rounded to three decimals. Thus Popeyes at The 5 uses The 5 as the origin rather than charging distance from the Union. The client and server share this rule and catalog; the server calculates the authoritative price. UI labels these distances approximate demo estimates.

Future work: replace these estimates with measured entrance coordinates and pedestrian routing once the team chooses a map/routing provider.

## Restaurant pickup dropdown

`lib/constants/campus_restaurants.dart` follows the pickup-building headings in the provided LSU Dining screenshots, with explicit Union/UREC/Library/Law/BEC variants where necessary. Selecting a restaurant fills its pickup building, and typing an exact unambiguous restaurant name also updates it. Other allows manual restaurant and building entry. No restaurant hours or live availability are inferred.

Five additional campus pickup buildings (Art & Design, Law Center, Business Education Complex, Foster Hall, and Veterinary Medicine) support the screenshot locations. Their offsets are schematic demo estimates under the same rules above. [LSU's dining-location listing](https://www.lsu.edu/bos/docs/agendas/2023/2023-02-10-lsu-bos-meeting-agenda.pdf) also documents the building groupings; restaurant names follow the newer user screenshots when they differ from that older listing.

Pentagon residence destinations explicitly include the community name: Pentagon · Beauregard, Jackson, LeJeune, and Taylor Halls. IDs are unchanged, so saved requests remain valid. [LSU Pentagon Community](https://www.lsu.edu/housing/options/halls/pentagon.php).
