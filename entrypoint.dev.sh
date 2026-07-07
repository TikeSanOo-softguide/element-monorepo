#!/usr/bin/env bash
set -euo pipefail

SDK_DIR="/project/matrix-js-sdk"
WEB_DIR="/project/element-web"

link_local_sdk() {
    echo "==> Linking local matrix-js-sdk into element-web"
    cd "$WEB_DIR"
    # Ensure SDK deps exist (host volume may be empty on first boot)
    if [ ! -d "$SDK_DIR/node_modules" ]; then
        echo "==> Installing matrix-js-sdk dependencies"
        (cd "$SDK_DIR" && pnpm install --frozen-lockfile)
    fi
    node scripts/pnpm-link.ts
}

start_dev_stack() {
    echo "==> Starting Element Web dev stack (nx + webpack-dev-server)"
    cd "$WEB_DIR"
    export CHOKIDAR_USEPOLLING="${CHOKIDAR_USEPOLLING:-true}"
    exec pnpm nx start element-web -- --host 0.0.0.0 --port "${ELEMENT_WEB_PORT:-8080}"
}

link_local_sdk
start_dev_stack
