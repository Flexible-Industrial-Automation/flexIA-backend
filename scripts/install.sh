#!/usr/bin/env bash
# Installs native dependencies for the flexIA backend: redis-server, envsubst
# (gettext) and, optionally, mosquitto.
set -euo pipefail
cd "$(dirname "$0")/.."

WITH_MQTT=false
for arg in "$@"; do
  case "$arg" in
    --with-mqtt) WITH_MQTT=true ;;
  esac
done

if [ -f .env ]; then
  set -a
  # shellcheck disable=SC1091
  source .env
  set +a
fi
[ "${ENABLE_MQTT:-false}" = "true" ] && WITH_MQTT=true

detect_pm() {
  if command -v brew >/dev/null 2>&1; then echo brew
  elif command -v apt-get >/dev/null 2>&1; then echo apt
  elif command -v dnf >/dev/null 2>&1; then echo dnf
  elif command -v pacman >/dev/null 2>&1; then echo pacman
  else echo none
  fi
}
PM=$(detect_pm)

pm_install() {
  case "$PM" in
    brew) brew install "$@" ;;
    apt) sudo apt-get update -y && sudo apt-get install -y "$@" ;;
    dnf) sudo dnf install -y "$@" ;;
    pacman) sudo pacman -Sy --noconfirm "$@" ;;
    *)
      echo "No supported package manager found (looked for brew/apt/dnf/pacman)." >&2
      echo "Please install manually: $*" >&2
      exit 1
      ;;
  esac
}

if ! command -v redis-server >/dev/null 2>&1; then
  echo "Installing redis-server..."
  case "$PM" in
    apt) pm_install redis-server ;;
    *) pm_install redis ;;
  esac
fi

if ! command -v envsubst >/dev/null 2>&1; then
  echo "Installing gettext (envsubst)..."
  case "$PM" in
    apt) pm_install gettext-base ;;
    *) pm_install gettext ;;
  esac
fi

if [ "$WITH_MQTT" = "true" ] && ! command -v mosquitto >/dev/null 2>&1; then
  echo "Installing mosquitto..."
  pm_install mosquitto
fi

echo "flexIA backend dependencies are installed."
