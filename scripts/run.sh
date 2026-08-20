#!/usr/bin/env bash
# Single-command native runner for the flexIA backend.
# Installs missing dependencies automatically, renders config from .env and
# starts Redis (and, if enabled, the MQTT broker) in the foreground.
set -euo pipefail
cd "$(dirname "$0")/.."
ROOT_DIR="$(pwd)"

if [ ! -f .env ]; then
  cp .env.example .env
  echo "Created .env from .env.example — edit it to customize your setup."
fi
set -a
# shellcheck disable=SC1091
source .env
set +a

NEEDS_INSTALL=false
command -v redis-server >/dev/null 2>&1 || NEEDS_INSTALL=true
command -v envsubst >/dev/null 2>&1 || NEEDS_INSTALL=true
if [ "${ENABLE_MQTT:-false}" = "true" ] && ! command -v mosquitto >/dev/null 2>&1; then
  NEEDS_INSTALL=true
fi
if [ "$NEEDS_INSTALL" = "true" ]; then
  if [ "${ENABLE_MQTT:-false}" = "true" ]; then
    ./scripts/install.sh --with-mqtt
  else
    ./scripts/install.sh
  fi
fi

RUN_DIR="$ROOT_DIR/run"
mkdir -p "$RUN_DIR"

# --- Redis --------------------------------------------------------------
export REDIS_DATA_DIR="$ROOT_DIR/${REDIS_DATA_DIR:-./data/redis}"
mkdir -p "$REDIS_DATA_DIR"

envsubst '${REDIS_PORT} ${REDIS_PASSWORD} ${REDIS_MAXMEMORY} ${REDIS_MAXMEMORY_POLICY} ${REDIS_APPENDONLY} ${REDIS_APPENDFSYNC} ${REDIS_SAVE} ${REDIS_DATA_DIR}' \
  < redis/redis.conf.template > "$RUN_DIR/redis.conf"

PIDS=()
cleanup() {
  echo ""
  echo "Stopping flexIA backend..."
  for pid in "${PIDS[@]:-}"; do
    kill "$pid" 2>/dev/null || true
  done
}
trap cleanup EXIT INT TERM

redis-server "$RUN_DIR/redis.conf" &
PIDS+=($!)
echo "Redis started on port ${REDIS_PORT:-6379} (pid $!)"

# --- MQTT (optional) ------------------------------------------------------
if [ "${ENABLE_MQTT:-false}" = "true" ]; then
  export MQTT_DATA_DIR="$ROOT_DIR/${MQTT_DATA_DIR:-./data/mosquitto}"
  export MQTT_LOG_DIR="$ROOT_DIR/${MQTT_LOG_DIR:-./logs/mosquitto}"
  mkdir -p "$MQTT_DATA_DIR" "$MQTT_LOG_DIR"

  export MQTT_PASSWORD_FILE="$RUN_DIR/mosquitto-passwd"
  export MQTT_PERSISTENCE_LOCATION="$MQTT_DATA_DIR/"
  export MQTT_LOG_FILE="$MQTT_LOG_DIR/mosquitto.log"

  envsubst '${MQTT_PORT} ${MQTT_WEBSOCKETS_PORT} ${MQTT_ALLOW_ANONYMOUS} ${MQTT_PASSWORD_FILE} ${MQTT_PERSISTENCE} ${MQTT_PERSISTENCE_LOCATION} ${MQTT_MAX_QUEUED_MESSAGES} ${MQTT_MAX_KEEPALIVE} ${MQTT_LOG_FILE}' \
    < mosquitto/mosquitto.conf.template > "$RUN_DIR/mosquitto.conf"

  # mosquitto rejects "max_packet_size 0" outright (must be >= 20); 0 means
  # "unlimited" only when the directive is omitted entirely, so only emit it
  # when a real limit was requested.
  if [ -n "${MQTT_MAX_PACKET_SIZE:-}" ] && [ "${MQTT_MAX_PACKET_SIZE:-0}" != "0" ]; then
    echo "max_packet_size ${MQTT_MAX_PACKET_SIZE}" >> "$RUN_DIR/mosquitto.conf"
  fi

  touch "$MQTT_PASSWORD_FILE"
  if [ -n "${MQTT_USERNAME:-}" ]; then
    mosquitto_passwd -b "$MQTT_PASSWORD_FILE" "$MQTT_USERNAME" "$MQTT_PASSWORD"
  fi
  chmod 0700 "$MQTT_PASSWORD_FILE"

  mosquitto -c "$RUN_DIR/mosquitto.conf" &
  PIDS+=($!)
  echo "MQTT broker started on port ${MQTT_PORT:-1883} (pid $!)"
fi

echo "flexIA backend is running. Press Ctrl+C to stop."
wait
