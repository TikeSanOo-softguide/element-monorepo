# Production deploy — https://chat-app.burmalearn.site

Run these commands **on the VPS** (`103.110.183.48`), inside the repo.

## Goal

| Before (broken) | After (production) |
|---|---|
| nginx → webpack-dev-server `:8080` | nginx → static Element container `:8080` |
| version `1.12.22-dev` | version without `-dev` |
| `X-Powered-By: Express` | nginx only (no Express) |

Keep: host nginx + certbot + Synapse `/_matrix` + `config.json`.

---

## 1. Stop the current DEV Element container

```bash
cd /path/to/chat-frontend   # your repo on the VPS

# stop whatever is serving webpack on :8080
docker compose down
# or: docker stop <dev-container-name>
```

Confirm nothing else owns 8080:

```bash
ss -tlnp | grep 8080 || true
```

---

## 2. Build & start production Element

```bash
docker compose -f docker-compose.prod.yml up --build -d
```

First build is slow (pnpm + webpack). Check:

```bash
docker compose -f docker-compose.prod.yml ps
docker compose -f docker-compose.prod.yml logs -f --tail=100
curl -sS http://127.0.0.1:8080/version
curl -sS http://127.0.0.1:8080/config.json | head
```

Expected: version **without** `-dev`, and JSON config with `chat-app.burmalearn.site`.

---

## 3. Point host nginx at the prod container

Edit your existing site config (usually under `/etc/nginx/sites-available/`):

- Keep `/_matrix` → Synapse `:8008`
- Keep certbot SSL blocks
- Change Element `location /` upstream to `http://127.0.0.1:8080` (prod container)
- Remove any `/ws` webpack HMR proxy

Reference file in this repo: `docker/host-nginx.chat-app.conf`

Then:

```bash
sudo nginx -t
sudo systemctl reload nginx
```

---

## 4. Verify public site

```bash
curl -sSI https://chat-app.burmalearn.site/ | head
curl -sS https://chat-app.burmalearn.site/version
curl -sS -o /dev/null -w '%{http_code}\n' https://chat-app.burmalearn.site/_matrix/client/versions
```

Pass criteria:

- **No** `X-Powered-By: Express`
- `/version` is **not** `*-dev`
- `/_matrix/client/versions` still `200`

Browser:

1. Hard refresh or clear site data
2. Logout if stuck on Loading
3. Login again at https://chat-app.burmalearn.site/

---

## 5. Day-2 commands

```bash
# rebuild after code changes
docker compose -f docker-compose.prod.yml up --build -d

# logs
docker compose -f docker-compose.prod.yml logs -f

# change homeserver/brand without rebuild
# edit config/config.production.json then:
docker compose -f docker-compose.prod.yml restart
```

---

## Do not use for production

- `docker compose up` (default `Dockerfile` + `entrypoint.sh`) → **dev only**
- `pnpm start` / webpack-dev-server on the public domain
