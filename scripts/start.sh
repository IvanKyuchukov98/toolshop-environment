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

# The dev server prepares much of the app's JavaScript only on the first real browser load, which can
# take close to a minute. Do that load now with headless Chrome, so tests don't pay for it (and time out).
warm_up_ui() {
  local chrome
  chrome="$(command -v google-chrome || command -v google-chrome-stable || command -v chromium \
    || command -v chromium-browser || true)"
  if [ -z "$chrome" ]; then
    echo "No Chrome/Chromium found; skipping the UI warm-up"
    return 0
  fi
  for _ in $(seq 1 10); do
    if timeout 120 "$chrome" --headless=new --disable-gpu --no-first-run --virtual-time-budget=60000 \
        --dump-dom "$UI_URL" 2>/dev/null | grep -q 'data-test="product-name"'; then
      echo "$UI_URL renders products"
      return 0
    fi
    sleep 5
  done
  echo "$UI_URL did not render products after warm-up" >&2
  return 1
}

warm_up_ui

echo "Toolshop is ready: UI $UI_URL, API $API_URL"
