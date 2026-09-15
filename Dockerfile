# Full node image (same pattern as Chat-App-Admin-UI's `node:lts`).
# It already includes git, python3, make, and g++ via buildpack-deps,
# so we never run apt-get (Debian mirrors fail on this VPS).
FROM node:22

WORKDIR /project

RUN corepack enable && corepack prepare pnpm@11.2.2 --activate

COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

EXPOSE 8080

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
