# --- Stage 1: Build ---
FROM node:22-bookworm-slim AS builder

RUN apt-get update && apt-get install -y --no-install-recommends \
    git python3 make g++ && rm -rf /var/lib/apt/lists/*

RUN npm install -g pnpm@11.2.2

WORKDIR /project

# Copy package files first to leverage layer caching
COPY pnpm-lock.yaml ./
COPY matrix-js-sdk/package.json ./matrix-js-sdk/
COPY element-web/package.json ./element-web/
COPY element-web/apps/web/package.json ./element-web/apps/web/

# Install all dependencies
RUN pnpm install --frozen-lockfile

# Copy source code
COPY . .

# Run the build command (Adjust if your build command is different)
# Assuming Nx is used for production builds
RUN pnpm build 

# --- Stage 2: Production ---
FROM nginx:alpine

# Copy built assets from the builder stage
# Adjust the path based on where your project outputs the final static files
COPY --from=builder /project/element-web/apps/web/dist /usr/share/nginx/html

# Expose port
EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]