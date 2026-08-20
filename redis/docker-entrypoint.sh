#!/bin/sh
set -e

# Inside the container, data always lives on the mounted /data volume
# regardless of what REDIS_DATA_DIR points to on the host.
export REDIS_DATA_DIR=/data
mkdir -p "$REDIS_DATA_DIR"

envsubst '${REDIS_PORT} ${REDIS_PASSWORD} ${REDIS_MAXMEMORY} ${REDIS_MAXMEMORY_POLICY} ${REDIS_APPENDONLY} ${REDIS_APPENDFSYNC} ${REDIS_SAVE} ${REDIS_DATA_DIR}' \
  < /usr/local/etc/redis/redis.conf.template > /usr/local/etc/redis/redis.conf

exec redis-server /usr/local/etc/redis/redis.conf
