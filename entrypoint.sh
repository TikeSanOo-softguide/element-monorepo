#!/usr/bin/env bash
set -euo pipefail

PROJECT_ROOT="/project"
JS_SDK_DIR="${PROJECT_ROOT}/matrix-js-sdk"
WEB_DIR="${PROJECT_ROOT}/element-web"
APP_DIR="${WEB_DIR}/apps/web"

# Lives inside the web_node_modules named volume, so it persists across
# container stop/start (e.g. Docker Desktop's play button) but automatically
# resets if you ever wipe volumes (`make clean` / `docker compose down -v`).
SETUP_MARKER="${WEB_DIR}/node_modules/.docker-setup-complete"

# Set FORCE_SETUP=1 to force the full install/link/prebuild pipeline to rerun
# even if the marker is present (e.g. after adding a new dependency).
FORCE_SETUP="${FORCE_SETUP:-0}"

start_dev_server() {
  cd "${WEB_DIR}"
  # Nx tracks in-progress task ownership in workspace-data. If the previous
  # run was stopped (container stop, Docker Desktop pause, etc.) while nx
  # start's child tasks were mid-flight, this state can be left claiming a
  # task is "owned" by a process PID that no longer exists - causing the
  # next start to hang forever on "Waiting for X in another nx process".
  # Clear it every time, not just on full setup, since restarts hit this too.
  if [ -d ".nx/workspace-data" ]; then
    echo "    clearing .nx/workspace-data (stale in-progress task state from last stop)"
    rm -rf .nx/workspace-data
  fi
  cd "${APP_DIR}"
  export HOST="0.0.0.0"
  export PORT="${PORT:-8080}"
  exec pnpm start
}

if [ -f "${SETUP_MARKER}" ] && [ "${FORCE_SETUP}" != "1" ]; then
  echo "==> Setup already completed previously (found ${SETUP_MARKER})"
  echo "==> Skipping straight to the dev server. Set FORCE_SETUP=1 to redo setup."
  start_dev_server
fi

# Set SKIP_INSTALL=1 to skip the pnpm install steps on restart (faster iteration
# once node_modules volumes are already populated and lockfiles haven't changed).
SKIP_INSTALL="${SKIP_INSTALL:-0}"

echo "==> [1/6] matrix-js-sdk dependencies"
cd "${JS_SDK_DIR}"
if [ "${SKIP_INSTALL}" != "1" ]; then
  pnpm install
else
  echo "    skipped (SKIP_INSTALL=1)"
fi

echo "==> [2/6] element-web link-config"
cd "${WEB_DIR}"
echo "matrix-js-sdk=${JS_SDK_DIR}=apps/web" > .link-config
echo "    wrote .link-config -> matrix-js-sdk=${JS_SDK_DIR}=apps/web"

echo "==> [3/6] element-web root install"
cd "${WEB_DIR}"
if [ -d ".nx/cache" ]; then
  echo "    removing potentially stale .nx/cache (may have leaked in from host bind mount)"
  rm -rf .nx/cache
fi
if [ -d ".nx/workspace-data" ]; then
  echo "    removing potentially stale .nx/workspace-data (daemon socket/lock state)"
  rm -rf .nx/workspace-data
fi
if [ "${SKIP_INSTALL}" != "1" ]; then
  pnpm install
else
  echo "    skipped (SKIP_INSTALL=1)"
fi

echo "==> [4/6] apps/web config.json"
cd "${APP_DIR}"
if [ ! -f config.json ]; then
  cp config.sample.json config.json
  echo "    created config.json from config.sample.json"
else
  echo "    config.json already exists, leaving it as is"
fi

echo "==> [5/6] apps/web dependencies"
if [ "${SKIP_INSTALL}" != "1" ]; then
  pnpm install
else
  echo "    skipped (SKIP_INSTALL=1)"
fi

echo "==> [6/6] pre-building watch-mode dependencies (closes the webpack/vite-watch race)"
cd "${WEB_DIR}"
pnpm exec nx run-many --target=build --projects=@element-hq/web-shared-components,@element-hq/element-web-module-api

echo "==> setup complete, writing marker so future starts skip straight to the dev server"
mkdir -p "$(dirname "${SETUP_MARKER}")"
touch "${SETUP_MARKER}"

echo "==> starting dev server on port ${PORT:-8080}"
start_dev_server