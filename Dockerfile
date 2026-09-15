FROM node:22-bookworm-slim

ENV DEBIAN_FRONTEND=noninteractive

# HTTPS + IPv4 + retries: Docker's default build network often fails HTTP/IPv6
# fetches of deb.debian.org on Linux VPS hosts.
RUN set -eux; \
    printf 'Acquire::ForceIPv4 "true";\nAcquire::Retries "5";\n' \
      > /etc/apt/apt.conf.d/99-docker-retries; \
    if [ -f /etc/apt/sources.list.d/debian.sources ]; then \
      sed -i 's|http://deb.debian.org|https://deb.debian.org|g' /etc/apt/sources.list.d/debian.sources; \
      sed -i 's|http://security.debian.org|https://security.debian.org|g' /etc/apt/sources.list.d/debian.sources; \
    fi; \
    if [ -f /etc/apt/sources.list ]; then \
      sed -i 's|http://deb.debian.org|https://deb.debian.org|g' /etc/apt/sources.list; \
      sed -i 's|http://security.debian.org|https://security.debian.org|g' /etc/apt/sources.list; \
    fi; \
    apt-get update; \
    apt-get install -y --no-install-recommends \
      ca-certificates \
      git \
      python3 \
      make \
      g++; \
    rm -rf /var/lib/apt/lists/*

RUN npm install -g pnpm@11.2.2

WORKDIR /project

COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

EXPOSE 8080

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
