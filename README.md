# flexIA-backend

Generic backend for the flexIA ecosystem.

Provides a configurable [Redis](https://redis.io) broker, plus an optional
[MQTT](https://mqtt.org) broker ([Mosquitto](https://mosquitto.org)), for
services in the flexIA ecosystem. Run it natively with a single command, or
containerized with Docker Compose.

## Configuration

All configuration lives in a single `.env` file.

```bash
cp .env.example .env
```

Edit `.env` to adjust things like Redis retention/eviction behavior or MQTT
broker settings. See the comments in [.env.example](.env.example) for every
available option, including:

- **Redis**: `REDIS_PORT`, `REDIS_PASSWORD`, `REDIS_MAXMEMORY`,
  `REDIS_MAXMEMORY_POLICY`, `REDIS_APPENDONLY` / `REDIS_APPENDFSYNC`
  (persistence), `REDIS_SAVE` (snapshot retention rules).
- **MQTT**: `ENABLE_MQTT` (toggle the broker on/off), `MQTT_PORT`,
  `MQTT_ALLOW_ANONYMOUS`, `MQTT_USERNAME` / `MQTT_PASSWORD`,
  `MQTT_MAX_PACKET_SIZE`, `MQTT_MAX_QUEUED_MESSAGES`, `MQTT_MAX_KEEPALIVE`.

If you skip this step, `./scripts/run.sh` creates `.env` from the example
automatically on first run.

## Quick start — native

A single command installs any missing dependencies (`redis-server`,
`envsubst`, and `mosquitto` if `ENABLE_MQTT=true`) and starts the backend in
the foreground:

```bash
./scripts/run.sh
```

or, equivalently:

```bash
make run
```

Press `Ctrl+C` to stop. Data is persisted under `./data/` and logs under
`./logs/` (both git-ignored).

Supported package managers for auto-install: Homebrew (macOS), apt
(Debian/Ubuntu), dnf (Fedora), pacman (Arch). To install dependencies
without starting anything, run `./scripts/install.sh` (add `--with-mqtt` to
also install Mosquitto).

## Quick start — Docker

Redis only:

```bash
docker compose up -d --build
```

Redis + MQTT:

```bash
docker compose --profile mqtt up -d --build
```

Both read configuration from `.env`. Stop everything with:

```bash
docker compose --profile mqtt down
```

`make docker-up`, `make docker-up-mqtt`, `make docker-down` and
`make docker-logs` wrap these for convenience.

## Project structure

```
.
├── docker-compose.yml       # Redis + optional MQTT services
├── redis/                   # Redis Dockerfile, config template, entrypoint
├── mosquitto/                # Mosquitto Dockerfile, config template, entrypoint
├── scripts/
│   ├── install.sh           # Native dependency installer
│   └── run.sh                # Native single-command runner
├── .env.example              # All configurable settings
└── Makefile                  # Convenience targets
```

Both the native and Docker paths render their broker configuration from the
same templates (`redis/redis.conf.template`,
`mosquitto/mosquitto.conf.template`) using the values in `.env`, so behavior
stays consistent between the two.

## License

Apache License 2.0 — see [LICENSE](LICENSE).
