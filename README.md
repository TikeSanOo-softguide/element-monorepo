# Element monorepo

Local Docker setup for **element-web** plus **matrix-js-sdk**. After clone, use Docker Compose — not `make`.

## Prerequisites

- [Git](https://git-scm.com/)
- [Docker Desktop](https://www.docker.com/products/docker-desktop/) (or Docker Engine with the Compose v2 plugin)

Confirm Compose is available:

```bash
docker compose version
```

## Setup process

1. **Clone**

   ```bash
   git clone https://github.com/TikeSanOo-softguide/element-monorepo.git
   cd element-monorepo
   ```

2. **Start Docker Desktop** so the daemon is running.

3. **Build and start** (first run installs dependencies inside the container)

   ```bash
   docker compose up --build
   ```

   Optional BuildKit bake (same as the old `make up` target):

   - PowerShell: `$env:COMPOSE_BAKE="true"; docker compose up --build`
   - Unix: `COMPOSE_BAKE=true docker compose up --build`

   First start can take many minutes. Watch the container logs for the steps below.

4. **Container setup** (printed by `entrypoint.sh` on the first run)

   1. `[1/6]` `matrix-js-sdk` — `pnpm install`
   2. `[2/6]` write `element-web/.link-config` (link local js-sdk into element-web)
   3. `[3/6]` `element-web` root — `pnpm install`
   4. `[4/6]` create `element-web/apps/web/config.json` from the sample if missing
   5. `[5/6]` `apps/web` — `pnpm install`
   6. `[6/6]` Nx prebuild of `@element-hq/web-shared-components` and `@element-hq/element-web-module-api`

   After that the entrypoint starts `pnpm start` on `0.0.0.0:8080`. Later starts skip this pipeline if `element-web/node_modules/.docker-setup-complete` exists in the volume.

5. **Open the app** at [http://localhost:8080](http://localhost:8080)

Do not mix a host-side `pnpm install` with this Docker flow unless you understand the named `node_modules` volumes in `docker-compose.yml`.

## Day-2 commands

**Stop** (keeps `node_modules` volumes so the next start stays fast):

```bash
docker compose down
```

**Logs:**

```bash
docker compose logs -f
```

**Shell in the running container:**

```bash
docker compose exec element-web bash
```

**Wipe install volumes** (full `[1/6]`–`[6/6]` setup on the next start):

```bash
docker compose down -v
```

**Force setup again without wiping volumes:**

- PowerShell: `$env:FORCE_SETUP="1"; docker compose up --build`
- Unix: `FORCE_SETUP=1 docker compose up --build`

## Troubleshooting

- **First run looks stuck** — wait for `[1/6]` through `[6/6]`; pnpm install is slow inside Docker.
- **Need a clean install** — `docker compose down -v`, then `docker compose up --build`.
- **Added a dependency but setup was skipped** — set `FORCE_SETUP=1` as above, or wipe volumes.
- **`COMPOSE_BAKE` errors** — omit it and use `docker compose up --build`.

## Optional: Make (Unix only)

A `Makefile` exists as a shortcut. On Windows/PowerShell, ignore it and use the Compose commands above.

- `make up` → `docker compose up --build`
- `make down` → `docker compose down`
- `make logs` → `docker compose logs -f`
- `make shell` → `docker compose exec element-web bash`
- `make clean` → `docker compose down -v`
- `make reset-setup` → `FORCE_SETUP=1 docker compose up --build`
