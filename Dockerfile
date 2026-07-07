# --- Stage 1: Build ---
FROM node:22-bookworm-slim AS builder

RUN apt-get update && apt-get install -y --no-install-recommends \
    git python3 make g++ && rm -rf /var/lib/apt/lists/*
RUN npm install -g pnpm@11.2.2

WORKDIR /project

# 1. Copy ONLY manifest/lockfile/workspace-config files first for layer caching.
COPY --parents matrix-js-sdk/package.json matrix-js-sdk/pnpm-lock.yaml matrix-js-sdk/**/package.json /project/
COPY --parents element-web/package.json element-web/pnpm-lock.yaml element-web/pnpm-workspace.yaml element-web/patches element-web/**/package.json /project/

# 2. Install SDK dependencies
WORKDIR /project/matrix-js-sdk
RUN pnpm install --ignore-scripts

# 3. Install element-web dependencies
WORKDIR /project/element-web
RUN pnpm install --ignore-scripts

# 4. Copy the rest of the source code
WORKDIR /project
COPY . .

# 5. Build SDK first
WORKDIR /project/matrix-js-sdk
RUN pnpm build

# 6. Build Web App
WORKDIR /project/element-web
# Re-creating dev link
RUN echo "matrix-js-sdk=/project/matrix-js-sdk=apps/web" > .link-config
# Move to the app dir to trigger the build
WORKDIR /project/element-web/apps/web
RUN pnpm build

RUN cp config.sample.json webapp/config.json

# --- Stage 2: Production ---
FROM nginx:alpine
# Copy the built assets
COPY --from=builder /project/element-web/apps/web/webapp /usr/share/nginx/html
EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]