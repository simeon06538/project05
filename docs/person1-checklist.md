# Person 1 customer handoff

Implemented customer scope:

- C-01–C-05: API models, name/role welcome screen, customer home, request form, food-only pickup buildings and campus drop-offs.
- C-06–C-10: route estimate and capped fee, pricing tests, default-zero tips up to $50, live totals, and validation. Mobile-order restaurants require an order number; Panera and unlisted restaurants do not.
- C-11–C-13: review/edit/confirm, persistent offline demo storage, and server-backed create/list/delete. Panera selects PFT automatically.
- C-14–C-15: tracking progress, manual refresh, five-second automatic refresh, background pause, and stopping automatic refresh for terminal or removed orders.
- C-16: owner deletion of waiting requests, following the agreed delete-instead-of-cancel behavior. Deleted requests stay out of history; fulfilled requests appear in Past.
- C-17–C-18: loading/error/retry states, retained last-loaded deliveries, accessible loading labels, and consistent customer empty/error panels.
- C-19: request form, restaurant mapping, tip validation, confirmation, persistence, tracking, and API regression tests.

## Demo checks

1. Start the server with `npm start` from `server/` and run the app from the Flutter project root.
2. Enter a name and choose Customer. Submit a request, review its locations/fee/tip, and confirm. It appears in Active.
3. Select Panera Bread: pickup changes to Patrick F. Taylor Hall and a blank order number is accepted. A mobile-order restaurant such as Sonic requires a number.
4. Return with the same name on the same device/server to see saved requests. Name matching ignores case and surrounding whitespace.
5. Delete a waiting request and check both Active and Past: it appears in neither.
6. Open tracking. Updates from the server appear automatically; after fulfillment, return to see the request in Past.
7. Stop the server and refresh. Previously loaded requests remain visible with a warning. Restart the server and use Try again.

## Remaining team integration

The courier screen still uses Person 2's mock service (K-12 remains theirs). Its starter requests, history, and minute-based generated requests are demo fixtures. Customer requests are saved to the real Node server and will not appear in that courier mock list.

The welcome name is a class-demo identity, not authentication. Server user IDs are remembered on each device per server address. Entering the same name on a different device does not guarantee a shared account. Offline mock orders are not uploaded automatically. Distance values are approximate demo estimates, documented in `locations.md`.

The iPhone signing/network setup was deferred at the user's request. Android remains the configured demo target.

## Verification (2026-10-20)

- 44 customer/model/pricing unit and widget tests passed.
- Live Flutter-to-Node regression passed for Popeyes and Panera: create, reload with remembered identity, and delete. It uses an isolated temporary server/database.
- All 50 server tests passed.
- Flutter analysis reported no issues.
- Android debug APK built successfully.
- The 14 courier filtering/list tests passed after the requested demo label corrections. Screenshot golden baselines were not refreshed in this customer handoff.
