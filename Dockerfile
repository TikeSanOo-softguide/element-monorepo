# --- Stage 1: Build ---
FROM node:22-bookworm-slim AS builder

RUN apt-get update && apt-get install -y --no-install-recommends \
    git python3 make g++ \
    && rm -rf /var/lib/apt/lists/*

RUN npm install -g pnpm@11.2.2

# ... (အပေါ်ကအပိုင်းတွေ အတူတူပဲ)

WORKDIR /project

# 1. Root configuration file များကို အရင်ကူးပါ (ဒီအချက်က အဓိကပါ!)
COPY package.json pnpm-workspace.yaml* ./

# 2. သက်ဆိုင်ရာ folder အလိုက် package.json များကို ကူးပါ
COPY matrix-js-sdk/package.json ./matrix-js-sdk/
COPY element-web/package.json ./element-web/

# 3. matrix-js-sdk Dependencies install လုပ်ခြင်း
WORKDIR /project/matrix-js-sdk
RUN pnpm install --ignore-scripts

# 4. element-web Dependencies install လုပ်ခြင်း
WORKDIR /project/element-web
RUN pnpm install --ignore-scripts

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