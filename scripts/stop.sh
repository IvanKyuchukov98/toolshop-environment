#!/usr/bin/env bash
# Stops the Toolshop and deletes its data.
set -euo pipefail

cd "$(dirname "$0")/.."

docker compose down --volumes
