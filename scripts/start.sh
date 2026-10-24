#!/usr/bin/env bash
# Starts the Toolshop, loads a fresh copy of the demo data and waits until the UI and API respond.
set -euo pipefail

cd "$(dirname "$0")/.."

UI_URL="http://localhost:4200"
API_URL="http://localhost:8091"

docker compose up -d --quiet-pull

# Retry until MariaDB accepts connections, then reset the database and load the demo data.
seeded=false
for _ in $(seq 1 30); do
  if docker compose exec -T laravel-api php artisan migrate:fresh --seed --force; then
    seeded=true
    break
  fi
  sleep 5
done
if [ "$seeded" != true ]; then
  echo "Seeding the database failed" >&2
  exit 1
fi

wait_for() {
  for _ in $(seq 1 60); do
    if curl -sf -o /dev/null "$1"; then
      echo "$1 is up"
      return 0
    fi
    sleep 5
  done
  echo "$1 did not come up within 5 minutes" >&2
  return 1
}

wait_for "$API_URL/products"
wait_for "$UI_URL" # ng serve answers only after the app is compiled

echo "Toolshop is ready: UI $UI_URL, API $API_URL"
