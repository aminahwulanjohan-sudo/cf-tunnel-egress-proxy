#!/bin/bash
# run-named-tunnel.sh — Cloudflare Named Tunnel dari VM tanpa IP publik.
# Butuh token tunnel dari dashboard Cloudflare (Zero Trust > Networks > Tunnels).
# Hostname bisa: domain sendiri ATAU xxx.cfargotunnel.com (gratis, permanen).
#
# Cara pakai:
#   TUNNEL_TOKEN="eyJ..." PROXY_URL="http://user:pass@proxy:3128" ./run-named-tunnel.sh
#
set -e

TUNNEL_TOKEN="${TUNNEL_TOKEN:?set TUNNEL_TOKEN dari dashboard Cloudflare}"
HOSTS_FILE="${HOSTS_FILE:-/tmp/hosts.cf}"
EDGE_IP="${EDGE_IP:-198.41.192.67}"
PROXY_URL="${PROXY_URL:?set PROXY_URL, contoh: http://user:pass@proxy-host:3128}"

PROXY_AUTH=$(echo "$PROXY_URL" | sed -E 's|http://([^@]+)@.*|\1|')
PROXY_HOSTPORT=$(echo "$PROXY_URL" | sed -E 's|http://[^@]+@([^/]+)|\1|')
PROXY_HOST=$(echo "$PROXY_HOSTPORT" | cut -d: -f1)
PROXY_PORT=$(echo "$PROXY_HOSTPORT" | cut -d: -f2)
CA_BUNDLE="${CA_BUNDLE:-/etc/ssl/certs/ca-certificates.crt}"

[ -f "$HOSTS_FILE" ] || { echo "ERROR: $HOSTS_FILE tidak ada" >&2; exit 1; }

socat TCP-LISTEN:7844,bind=127.0.0.1,fork,reuseaddr \
  PROXY:"$PROXY_HOST":"$EDGE_IP":7844,proxyport="$PROXY_PORT",proxyauth="$PROXY_AUTH" &
RELAY_PID=$!
trap "kill $RELAY_PID 2>/dev/null" EXIT
sleep 2

exec unshare --mount bash -c "
mount --bind \"$HOSTS_FILE\" /etc/hosts
export SSL_CERT_FILE=\"$CA_BUNDLE\"
export -n http_proxy https_proxy HTTP_PROXY HTTPS_PROXY
exec cloudflared tunnel --no-autoupdate --protocol http2 \
  --edge region1.v2.argotunnel.com:7844 \
  run --token \"$TUNNEL_TOKEN\"
"
