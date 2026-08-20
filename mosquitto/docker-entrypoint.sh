#!/bin/sh
set -e

# Inside the container, paths are fixed regardless of the host-side
# MQTT_DATA_DIR / MQTT_LOG_DIR values used to set up the bind mounts.
export MQTT_PASSWORD_FILE=/mosquitto/config/passwd
export MQTT_PERSISTENCE_LOCATION=/mosquitto/data/
export MQTT_LOG_FILE=/mosquitto/log/mosquitto.log

mkdir -p /mosquitto/data /mosquitto/log
chown mosquitto:mosquitto /mosquitto/data /mosquitto/log

envsubst '${MQTT_PORT} ${MQTT_WEBSOCKETS_PORT} ${MQTT_ALLOW_ANONYMOUS} ${MQTT_PASSWORD_FILE} ${MQTT_PERSISTENCE} ${MQTT_PERSISTENCE_LOCATION} ${MQTT_MAX_QUEUED_MESSAGES} ${MQTT_MAX_KEEPALIVE} ${MQTT_LOG_FILE}' \
  < /mosquitto/config/mosquitto.conf.template > /mosquitto/config/mosquitto.conf

# mosquitto rejects "max_packet_size 0" outright (must be >= 20); 0 means
# "unlimited" only when the directive is omitted entirely, so only emit it
# when a real limit was requested.
if [ -n "$MQTT_MAX_PACKET_SIZE" ] && [ "$MQTT_MAX_PACKET_SIZE" != "0" ]; then
  echo "max_packet_size $MQTT_MAX_PACKET_SIZE" >> /mosquitto/config/mosquitto.conf
fi

touch "$MQTT_PASSWORD_FILE"
if [ -n "$MQTT_USERNAME" ]; then
  mosquitto_passwd -b "$MQTT_PASSWORD_FILE" "$MQTT_USERNAME" "$MQTT_PASSWORD"
fi
chown mosquitto:mosquitto "$MQTT_PASSWORD_FILE"
chmod 0600 "$MQTT_PASSWORD_FILE"

exec mosquitto -c /mosquitto/config/mosquitto.conf
