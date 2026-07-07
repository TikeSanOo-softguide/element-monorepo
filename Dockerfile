# syntax=docker/dockerfile:1.6

########################################
# Base: shared toolchain
########################################
FROM node:22-bookworm-slim AS base

RUN apt-get update && apt-get install -y --no-install-recommends \
    git python3 make g++ \
    && rm -rf /var/lib/apt/lists/*

RUN npm install -g pnpm@11.2.2

WORKDIR /project

########################################
# 1. Build matrix-js-sdk (dependency)
########################################
FROM base AS sdk-build

WORKDIR /project/matrix-js-sdk
COPY matrix-js-sdk/package.json matrix-js-sdk/pnpm-lock.yaml ./
RUN pnpm install --frozen-lockfile

COPY matrix-js-sdk/ ./
RUN pnpm run build

########################################
# 2. Build element-web, linked to the SDK
########################################
FROM base AS webapp-build

# Bring in the already-built SDK
COPY --from=sdk-build /project/matrix-js-sdk /project/matrix-js-sdk

WORKDIR /project/element-web
COPY element-web/package.json element-web/pnpm-lock.yaml ./
RUN pnpm install --frozen-lockfile

# Point element-web's matrix-js-sdk dependency at the local build
RUN pnpm link --dir /project/matrix-js-sdk

COPY element-web/ ./
RUN pnpm run build

########################################
# 3a. PRODUCTION: static files via nginx
########################################
FROM nginx:1.27-alpine AS production

COPY --from=webapp-build /project/element-web/webapp /usr/share/nginx/html
COPY nginx.conf /etc/nginx/conf.d/default.conf

EXPOSE 8080
CMD ["nginx", "-g", "daemon off;"]

########################################
# 3b. DEVELOPMENT: live dev server
########################################
FROM base AS development

WORKDIR /project
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

EXPOSE 8080
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]