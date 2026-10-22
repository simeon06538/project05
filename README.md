# project05

Campus delivery app: customers request delivery of food they already paid for with
Paw Points, and couriers accept and deliver it. Payments are simulated for the demo.

- Task breakdown: [TASKS.txt](TASKS.txt)
- API contract: [docs/api.md](docs/api.md)

## Running the server locally

The backend is Node.js + Express with a SQLite database file (no separate database
server to install). It lives in [server/](server/).

### Requirements

- Node.js 22 or newer (`node --version`)

### Start it

```sh
cd server
npm install
npm start
```

You should see:

```
Server listening on http://localhost:3000 (bound to 0.0.0.0)
```

Check it's up: open <http://localhost:3000/health>. You should get `{"status":"ok"}`.

On first start the server creates `server/data/delivery.db` and adds the demo data:
campus locations, customers (ids 1-3) and couriers (ids 4-5). `npm run dev` does the
same but restarts automatically when you edit a file.

### Pointing the Flutter app at it

The app reads the base URL from [lib/services/api_config.dart](lib/services/api_config.dart)
(Android emulator defaults to `http://10.0.2.2:3000`; other platforms use `http://localhost:3000`). Override it when running:

| Where the app runs       | Command                                                                  |
|--------------------------|--------------------------------------------------------------------------|
| Web, desktop, iOS sim    | `flutter run` (default works)                                            |
| Android emulator         | `flutter run --dart-define=API_BASE_URL=http://10.0.2.2:3000`            |
| Real phone (same Wi-Fi)  | `flutter run --dart-define=API_BASE_URL=http://<your-computer-IP>:3000`  |

For a real phone, find your computer's IP with `ipconfig` (Windows) or
`ipconfig getifaddr en0` (Mac), and allow Node through the firewall if asked.

### Settings

Set these as environment variables before `npm start` if you need to change them:

| Variable      | Default                   | What it does                                        |
|---------------|---------------------------|-----------------------------------------------------|
| `PORT`        | `3000`                    | Port to listen on                                   |
| `HOST`        | `0.0.0.0`                 | Network interface (0.0.0.0 = reachable on your LAN) |
| `DB_PATH`     | `server/data/delivery.db` | SQLite file (`:memory:` for a throwaway DB)         |
| `CORS_ORIGIN` | `*`                       | Allowed browser origins, comma-separated            |

PowerShell example: `$env:PORT=4000; npm start`. Bash example: `PORT=4000 npm start`.

### Resetting demo data

Before recording the demo (or whenever test data piles up):

```sh
cd server
npm run reset
```

This deletes all orders and any users created while testing, sets courier earnings
back to $0, restarts ids at 1, and re-adds the demo locations and users. It works while
the server is running; refresh the app afterwards.

### Tests

```sh
cd server
npm test
```

Runs the unit tests (fee calculation, status transitions) and API tests for every
endpoint against an in-memory database.

### Quick manual test

```sh
# Customer 1 requests a delivery
curl -X POST http://localhost:3000/orders -H "Content-Type: application/json" \
  -d '{"customerId":1,"pickupLocation":"union","dropoffLocation":"west-campus-apts","tip":2,"pawPointsOrderNumber":"PP-1"}'

# Courier 4 accepts, picks up and delivers it
curl -X PATCH http://localhost:3000/orders/1/accept -H "Content-Type: application/json" -d '{"courierId":4}'
curl -X PATCH http://localhost:3000/orders/1/status -H "Content-Type: application/json" -d '{"status":"picked_up","courierId":4}'
curl -X PATCH http://localhost:3000/orders/1/status -H "Content-Type: application/json" -d '{"status":"delivered","courierId":4}'

# Courier 4's earnings
curl http://localhost:3000/couriers/4/earnings
```

(On Windows, run these in Git Bash, or use `curl.exe` in PowerShell.)

## Customer app (Person 1)

Start the server in one terminal (`cd server`, `npm ci`, `npm start`). In another terminal at the project root:

```sh
flutter pub get
flutter run
```

Run `lib/main.dart` in Android Studio with the Pixel emulator selected. The Android emulator defaults to `http://10.0.2.2:3000`; other platforms default to localhost. A physical phone needs `--dart-define=API_BASE_URL=http://YOUR_COMPUTER_LAN_IP:3000`. Local HTTP is enabled only for Android debug builds; release servers should use HTTPS.

Customer requests now use the server by default, including order name/restaurant and permanent deletion of the owner's waiting requests. Delivered orders remain in Past. Prices are recalculated by the server using approximate pickup-to-drop-off distance. [Location sources and estimate limitations](docs/locations.md).

For offline mock mode, run `flutter run --dart-define=USE_MOCK_CUSTOMER_API=true`. Previously saved mock orders remain on the device and are **not** automatically uploaded to the server. Server orders are stored in SQLite; the device stores the server user ID for each demo name. No password is used.

After a server demo reset, restart the app so its saved customer ID is rechecked.

Customer API smoke test against an isolated in-memory Node server (requires `npm ci` in `server/` first):

```sh
flutter test --dart-define=RUN_LIVE_CUSTOMER_API=true test/live_customer_api_test.dart
```

## Courier app (Person 2)

Choose **Courier** on the welcome screen. Couriers use the same server as customers (K-12): customer requests appear under Available, and accepting, picking up and delivering go through the server, which credits the pay to the courier's earnings. Like customers, each demo name is its own courier; the device remembers the server ID for each name and registers it again after a demo reset.

The server has no endpoints for giving back an accepted delivery (K-28) or reporting a problem (K-51), so those buttons are hidden in server mode. Accept and pickup times are kept on the device, so a delivery loaded later shows those steps as "Done" in its timeline.

For the offline demo (fake requests, a week of history, all features), run `flutter run --dart-define=USE_MOCK_COURIER_API=true`.

Courier API smoke test (customer order → accept → pick up → deliver → earnings) against an isolated in-memory Node server (requires `npm ci` in `server/` first):

```sh
flutter test --dart-define=RUN_LIVE_COURIER_API=true test/live_courier_api_test.dart
```
