.PHONY: run install docker-up docker-up-mqtt docker-down docker-logs

## Native: install dependencies (if missing) and run in the foreground
run:
	./scripts/run.sh

## Native: install dependencies only
install:
	./scripts/install.sh

## Docker: build and start Redis only, detached
docker-up:
	docker compose up -d --build

## Docker: build and start Redis + MQTT, detached
docker-up-mqtt:
	docker compose --profile mqtt up -d --build

## Docker: stop and remove containers
docker-down:
	docker compose --profile mqtt down

## Docker: follow logs
docker-logs:
	docker compose --profile mqtt logs -f
