FROM node:22-bookworm-slim

RUN apt-get update && apt-get install -y --no-install-recommends \
    git python3 make g++ \
    && rm -rf /var/lib/apt/lists/*

RUN npm install -g pnpm@11.2.2

WORKDIR /project

COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

EXPOSE 8080

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
