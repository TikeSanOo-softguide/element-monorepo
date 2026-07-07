#!/bin/sh
set -eu

log() {
    if [ -z "${NGINX_ENTRYPOINT_QUIET_LOGS:-}" ]; then
        echo "$@"
    fi
}

# Materialize config.json from the baked sample, then apply runtime overrides.
mkdir -p /tmp/element-web-config
cp /app/config.sample.json /tmp/element-web-config/config.json

if [ -n "${ELEMENT_DEFAULT_HS_URL:-}" ]; then
    log "Applying ELEMENT_DEFAULT_HS_URL=${ELEMENT_DEFAULT_HS_URL}"
    jq --arg url "$ELEMENT_DEFAULT_HS_URL" \
        '.default_server_config["m.homeserver"].base_url = $url' \
        /tmp/element-web-config/config.json > /tmp/element-web-config/config.json.tmp
    mv /tmp/element-web-config/config.json.tmp /tmp/element-web-config/config.json
fi

if [ -n "${ELEMENT_DEFAULT_SERVER_NAME:-}" ]; then
    log "Applying ELEMENT_DEFAULT_SERVER_NAME=${ELEMENT_DEFAULT_SERVER_NAME}"
    jq --arg name "$ELEMENT_DEFAULT_SERVER_NAME" \
        '.default_server_config["m.homeserver"].server_name = $name' \
        /tmp/element-web-config/config.json > /tmp/element-web-config/config.json.tmp
    mv /tmp/element-web-config/config.json.tmp /tmp/element-web-config/config.json
fi

if [ -n "${ELEMENT_BRAND:-}" ]; then
    log "Applying ELEMENT_BRAND=${ELEMENT_BRAND}"
    jq --arg brand "$ELEMENT_BRAND" '.brand = $brand' \
        /tmp/element-web-config/config.json > /tmp/element-web-config/config.json.tmp
    mv /tmp/element-web-config/config.json.tmp /tmp/element-web-config/config.json
fi

# Optional runtime modules under /modules
if [ -d /modules ] && [ "$(ls -A /modules 2>/dev/null || true)" ]; then
    for module_dir in /modules/*; do
        [ -d "$module_dir" ] || continue
        module_name="$(basename "$module_dir")"
        entrypoint="index.js"
        if [ -f "$module_dir/package.json" ]; then
            entrypoint="$(jq -r '.main // "index.js"' "$module_dir/package.json")"
        fi
        log "Registering module ${module_name} -> ${entrypoint}"
        jq --arg path "/modules/${module_name}/${entrypoint}" \
            '.modules += [$path]' \
            /tmp/element-web-config/config.json > /tmp/element-web-config/config.json.tmp
        mv /tmp/element-web-config/config.json.tmp /tmp/element-web-config/config.json
    done
fi

export ELEMENT_WEB_PORT="${ELEMENT_WEB_PORT:-8080}"
log "Element Web config ready; nginx will listen on port ${ELEMENT_WEB_PORT}"
