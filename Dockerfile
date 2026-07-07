# --- Stage 1: Build ---
FROM node:22-bookworm-slim AS builder

RUN apt-get update && apt-get install -y --no-install-recommends \
    git python3 make g++ \
    && rm -rf /var/lib/apt/lists/*

RUN npm install -g pnpm@11.2.2

WORKDIR /project

# 1. lock file မရှိတဲ့အတွက် package.json တစ်ခုတည်းကိုပဲ ခွဲကူးပါမယ်
COPY matrix-js-sdk/package.json ./matrix-js-sdk/
COPY element-web/package.json ./element-web/

# 2. matrix-js-sdk Dependencies install လုပ်ခြင်း (--frozen-lockfile ဖြုတ်ထားပါတယ်)
WORKDIR /project/matrix-js-sdk
RUN pnpm install --ignore-scripts

# 3. element-web Dependencies install လုပ်ခြင်း (--frozen-lockfile ဖြုတ်ထားပါတယ်)
WORKDIR /project/element-web
RUN pnpm install --ignore-scripts

# 4. Source code တစ်ခုလုံးကို Copy ကူးယူခြင်း
WORKDIR /project
COPY . .

# 5. Build SDK first
WORKDIR /project/matrix-js-sdk
RUN pnpm build

# 6. Build Web App
WORKDIR /project/element-web
RUN echo "matrix-js-sdk=/project/matrix-js-sdk=apps/web" > .link-config
WORKDIR /project/element-web/apps/web
RUN pnpm build

# --- Stage 2: Production ---
FROM nginx:alpine
COPY --from=builder /project/element-web/apps/web/dist /usr/share/nginx/html
EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]