# --- Stage 1: Build ---
FROM node:22-bookworm-slim AS builder

RUN apt-get update && apt-get install -y --no-install-recommends \
    git python3 make g++ && rm -rf /var/lib/apt/lists/*

RUN npm install -g pnpm@11.2.2

WORKDIR /project

# 1. Copy necessary files for each folder
COPY matrix-js-sdk/package.json matrix-js-sdk/pnpm-lock.yaml matrix-js-sdk/pnpm-workspace.yaml ./matrix-js-sdk/
COPY element-web/package.json element-web/pnpm-lock.yaml element-web/pnpm-workspace.yaml ./element-web/

# 2. Install dependencies for each folder individually
WORKDIR /project/matrix-js-sdk
RUN pnpm install --frozen-lockfile

# 3. Create the .link-config exactly as you do in entrypoint.sh
WORKDIR /project/element-web
RUN echo "matrix-js-sdk=/project/matrix-js-sdk=apps/web" > .link-config

# 4. Install dependencies for element-web
RUN pnpm install --frozen-lockfile

# 5. Copy the rest of the source code
WORKDIR /project
COPY . .

# 6. Build projects
WORKDIR /project/element-web
RUN pnpm build

# --- Stage 2: Production ---
FROM nginx:alpine

# Copy built assets
COPY --from=builder /project/element-web/apps/web/dist /usr/share/nginx/html

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]