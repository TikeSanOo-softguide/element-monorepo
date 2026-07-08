# Chat Frontend

Docker setup for local Element Web development and production static hosting.

Production domain:

```text
chat-x.burmalearn.site
```

Local and production Docker expose the app on host port `3080`.

## Project Layout

- `element-web/` - Element Web source.
- `matrix-js-sdk/` - Local Matrix JS SDK source linked into Element Web.
- `docker-compose.dev.yml` - Local development server with live source mounts.
- `docker/Dockerfile.dev` - Local development Dockerfile.
- `docker/Dockerfile.prod` - Multi-stage production image build.
- `docker-compose.prod.yml` - Production compose service.
- `docker/nginx.conf` - Nginx config inside the production Docker image.
- `Makefile` - Simple local and production commands.

## Local Development

Start local development:

```bash
make dev
```

Or run in the background:

```bash
make dev-bg
```

Open:

```text
http://localhost:3080
```

Stop local development:

```bash
make dev-down
```

View logs:

```bash
make dev-logs
```

Open a shell in the dev container:

```bash
make dev-shell
```

If dependencies get stale, remove the dev volumes and rebuild:

```bash
make dev-clean
make dev
```

The dev compose file mounts both `element-web` and `matrix-js-sdk` into the container, then installs dependencies and writes `.link-config` after the mounts are active. This keeps the local SDK linked correctly for webpack.

## Production With Docker

Build and start production:

```bash
make prod
```

Open directly on the server:

```text
http://localhost:3080
```

If testing from your browser before adding HTTPS, open:

```text
http://YOUR_EC2_PUBLIC_IP:3080
```

Stop production:

```bash
make prod-down
```

View production logs:

```bash
make prod-logs
```

Rebuild production image without cache:

```bash
make prod-rebuild
make prod
```

The production image uses `docker/Dockerfile.prod`:

1. Installs and builds `matrix-js-sdk`.
2. Links it into `element-web` with `.link-config`.
3. Builds the Element Web static output.
4. Copies `apps/web/webapp` into an nginx image.
5. Serves the container on internal port `80`, mapped to host port `3080`.

## Production Config

By default, the build copies `element-web/apps/web/config.sample.json` to `config.json` if no config exists.

For a real deployment, edit:

```bash
nano element-web/apps/web/config.json
```

If the file does not exist:

```bash
cp element-web/apps/web/config.sample.json element-web/apps/web/config.json
nano element-web/apps/web/config.json
```

Set your Matrix homeserver if needed:

```json
"default_server_config": {
  "m.homeserver": {
    "base_url": "https://your-matrix-server.com",
    "server_name": "your-matrix-server.com"
  }
}
```

Then rebuild:

```bash
make prod
```

## EC2 Deployment Steps

These steps assume Ubuntu on an EC2 `t2.small` instance.

### 1. SSH Into EC2

```bash
ssh -i your-key.pem ubuntu@YOUR_EC2_PUBLIC_IP
```

### 2. Install Basic Packages

```bash
sudo apt update
sudo apt upgrade -y
sudo apt install -y git make ca-certificates curl gnupg nginx certbot python3-certbot-nginx
```

### 3. Install Docker

```bash
sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
sudo chmod a+r /etc/apt/keyrings/docker.gpg
```

```bash
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
```

```bash
sudo apt update
sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
sudo usermod -aG docker ubuntu
```

Log out and SSH back in:

```bash
exit
ssh -i your-key.pem ubuntu@YOUR_EC2_PUBLIC_IP
```

Check Docker:

```bash
docker --version
docker compose version
```

### 4. Add Swap For t2.small

`t2.small` can run out of memory during the production build. Add swap before building:

```bash
sudo fallocate -l 2G /swapfile
sudo chmod 600 /swapfile
sudo mkswap /swapfile
sudo swapon /swapfile
echo '/swapfile none swap sw 0 0' | sudo tee -a /etc/fstab
```

### 5. Clone Project

```bash
git clone YOUR_REPO_URL chat-frontend
cd chat-frontend
```

### 6. Build And Start Docker Production

```bash
make prod
```

Check it locally on EC2:

```bash
curl -I http://127.0.0.1:3080
```

### 7. DNS Setup

In your DNS provider, create an A record:

```text
Type: A
Name: chat-x
Value: YOUR_EC2_PUBLIC_IP
```

The domain should become:

```text
chat-x.burmalearn.site
```

Check DNS:

```bash
nslookup chat-x.burmalearn.site
```

### 8. AWS Security Group

For production with Nginx and Certbot, allow:

```text
SSH    TCP 22   Your IP only
HTTP   TCP 80   0.0.0.0/0
HTTPS  TCP 443  0.0.0.0/0
```

Port `3080` does not need to be public when Nginx proxies to Docker on the same EC2 instance.

### 9. Configure Host Nginx Reverse Proxy

Create the Nginx site:

```bash
sudo nano /etc/nginx/sites-available/chat-x.burmalearn.site
```

Paste:

```nginx
server {
    listen 80;
    server_name chat-x.burmalearn.site;

    location / {
        proxy_pass http://127.0.0.1:3080;
        proxy_http_version 1.1;

        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
```

Enable the site:

```bash
sudo ln -s /etc/nginx/sites-available/chat-x.burmalearn.site /etc/nginx/sites-enabled/chat-x.burmalearn.site
sudo nginx -t
sudo systemctl reload nginx
```

### 10. Add HTTPS With Certbot

```bash
sudo certbot --nginx -d chat-x.burmalearn.site
```

Choose redirect HTTP to HTTPS when Certbot asks.

Test renewal:

```bash
sudo certbot renew --dry-run
```

Open:

```text
https://chat-x.burmalearn.site
```

## Update Production Later

```bash
cd ~/chat-frontend
git pull
make prod
sudo systemctl reload nginx
```

## Useful Commands

```bash
make help
make config-dev
make config-prod
make prod-logs
sudo tail -f /var/log/nginx/error.log
sudo journalctl -u nginx -f
```