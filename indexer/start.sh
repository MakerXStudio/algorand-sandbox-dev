#!/bin/bash

# Start indexer daemon. There are various configurations controlled by
# environment variables.
#
# Configuration:
#   INDEXER_PORT      - port to start indexer on.
#   ALGOD_HOST        - host to connect to for algod.
#   ALGOD_PORT        - port to connect to for algod.
#   ALGOD_TOKEN       - token to use when connecting to algod.
#   POSTGRES_HOST     -
#   POSTGRES_PORT     -
#   POSTGRES_USER     -
#   POSTGRES_PASSWORD -
#   POSTGRES_DB       -
set -eu

echo "Starting indexer against algod."

ALGOD_ADDR="${ALGOD_HOST}:${ALGOD_PORT}"

for i in 1 2 3 4 5 6 7 8 9 10; do
  wget "${ALGOD_ADDR}/genesis" -O genesis.json && break
  echo "Algod not responding... waiting."
  sleep 10
done

if [ ! -f genesis.json ]; then
  echo "Failed to create genesis file!"
  exit 1
fi

for i in 1 2 3 4 5 6 7 8 9 10; do
  nc -z $POSTGRES_HOST $POSTGRES_PORT && break
  echo "Waiting for postgres to come alive..."
  sleep 5
done

echo "All services alive, starting indexer daemon"
exec /tmp/algorand-indexer daemon \
  --dev-mode \
  --server ":${INDEXER_PORT}" \
  -P "host=${POSTGRES_HOST} port=${POSTGRES_PORT} user=${POSTGRES_USER} password=${POSTGRES_PASSWORD} dbname=${POSTGRES_DB} sslmode=disable" \
  --algod-net "${ALGOD_ADDR}" \
  --algod-token "${ALGOD_TOKEN}" \
  --genesis "genesis.json"
