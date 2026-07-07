# syntax=docker/dockerfile:1.7

#############################################
# Production multi-stage build
# Context: repository root (chat-frontend/)
#############################################

ARG NODE_VERSION=22-bookworm-slim
ARG PNPM_VERSION=11.2.2

#############################################
# base — shared Node.js + pnpm toolchain
#############################################
FROM node:${NODE_VERSION} AS base

ENV PNPM_HOME="/pnpm"
ENV PATH="${PNPM_HOME}:${PATH}"
ENV CI=true

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        ca-certificates \
        git \
        python3 \
        make \
        g++ \
    && rm -rf /var/lib/apt/lists/* \
    && corepack enable \
    && corepack prepare "pnpm@${PNPM_VERSION}" --activate

WORKDIR /project

#############################################
# sdk-deps — cache matrix-js-sdk dependencies
#############################################
FROM base AS sdk-deps

WORKDIR /project/matrix-js-sdk

COPY matrix-js-sdk/package.json matrix-js-sdk/pnpm-lock.yaml matrix-js-sdk/pnpm-workspace.yaml ./

RUN --mount=type=cache,id=chat-frontend-pnpm-store,target=/pnpm/store \
    pnpm install --frozen-lockfile --ignore-scripts

#############################################
# sdk-build — compile matrix-js-sdk (lib/ + .d.ts)
#############################################
FROM sdk-deps AS sdk-build

COPY matrix-js-sdk/ ./

RUN pnpm run build

#############################################
# web-deps — cache element-web workspace dependencies
#############################################
FROM base AS web-deps

WORKDIR /project/element-web

# Copy workspace manifests first for maximum Docker layer cache reuse
COPY element-web/package.json element-web/pnpm-lock.yaml element-web/pnpm-workspace.yaml ./
COPY element-web/patches ./patches
COPY element-web/scripts/pnpm-link.ts ./scripts/pnpm-link.ts
COPY element-web/.link-config ./.link-config
COPY element-web/apps/web/package.json ./apps/web/package.json
COPY element-web/apps/desktop/package.json ./apps/desktop/package.json
COPY element-web/packages/shared-components/package.json ./packages/shared-components/package.json
COPY element-web/packages/module-api/package.json ./packages/module-api/package.json
COPY element-web/packages/playwright-common/package.json ./packages/playwright-common/package.json
COPY element-web/modules/package.json ./modules/package.json
COPY element-web/modules/banner/package.json ./modules/banner/package.json
COPY element-web/modules/widget-lifecycle/package.json ./modules/widget-lifecycle/package.json
COPY element-web/modules/widget-toggles/package.json ./modules/widget-toggles/package.json
COPY element-web/modules/restricted-guests/package.json ./modules/restricted-guests/package.json

# Local SDK must exist before postinstall symlinks it into apps/web/node_modules
COPY --from=sdk-build /project/matrix-js-sdk /project/matrix-js-sdk

RUN --mount=type=cache,id=chat-frontend-pnpm-store,target=/pnpm/store \
    pnpm install --frozen-lockfile

#############################################
# web-build — compile Element Web static assets
#############################################
FROM web-deps AS web-build

COPY element-web/ ./

# Re-apply local SDK link after full source tree copy
RUN node scripts/pnpm-link.ts

ENV NODE_OPTIONS="--max-old-space-size=4096"
RUN VERSION=docker pnpm --dir apps/web build \
    && cp apps/web/config.sample.json apps/web/webapp/config.json

#############################################
# production — minimal nginx runtime image
#############################################
FROM nginxinc/nginx-unprivileged:1.27-alpine AS production

USER root

RUN apk add --no-cache jq gettext wget \
    && rm -rf /usr/share/nginx/html

COPY --from=web-build /project/element-web/apps/web/webapp /app
COPY nginx.conf /etc/nginx/templates/default.conf.template
COPY startup.sh /docker-entrypoint.d/40-element-startup.sh

RUN chmod +x /docker-entrypoint.d/40-element-startup.sh \
    && chown -R nginx:nginx /app

USER nginx

ENV ELEMENT_WEB_PORT=8080

EXPOSE 8080

HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
    CMD wget -q --spider "http://127.0.0.1:${ELEMENT_WEB_PORT}/config.json" || exit 1

CMD ["nginx", "-g", "daemon off;"]
