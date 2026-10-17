# project05

Campus delivery app: customers request delivery of food they already paid for with
Paw Points, and couriers accept and deliver it. Payments are simulated for the demo.

- Task breakdown: [TASKS.txt](TASKS.txt)
- API contract: [docs/api.md](docs/api.md)

## Running the server locally

The backend is Node.js + Express with a SQLite database file (no separate database
server to install). It lives in [server/](server/).

### Requirements

- Node.js 20 or newer (`node --version`)

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
(default `http://localhost:3000`). Override it when running:

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
