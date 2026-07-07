#!/usr/bin/env bash
set -e

echo "==> Installing & building matrix-js-sdk"
cd /project/matrix-js-sdk
pnpm install
pnpm run build

echo "==> Linking matrix-js-sdk into element-web"
cd /project/element-web
pnpm install
pnpm link --dir /project/matrix-js-sdk

echo "==> Starting element-web dev server"
exec pnpm start -- --host 0.0.0.0 --port 8080