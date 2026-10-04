#!/bin/bash
# run-quick-tunnel.sh — Cloudflare Quick Tunnel dari VM tanpa IP publik.
# Memberi hostname GRATIS *.trycloudflare.com (acak, TIDAK permanen).
#
# Prasyarat:
#   - cloudflared terinstall
#   - socat terinstall
#   - egress proxy yang mendukung HTTP CONNECT
#   - hosts.cf sudah disiapkan (lihat hosts.cf.example)
#
# Cara pakai:
#   PROXY_URL="http://user:pass@proxy-host:3128" ./run-quick-tunnel.sh 8080
#
set -e

LOCAL_PORT="${1:-8080}"
HOSTS_FILE="${HOSTS_FILE:-/tmp/hosts.cf}"
EDGE_IP="${EDGE_IP:-198.41.192.67}"   # salah satu IP edge Cloudflare (publik)
PROXY_URL="${PROXY_URL:?set PROXY_URL, contoh: http://user:pass@proxy-host:3128}"

PROXY_AUTH=$(echo "$PROXY_URL" | sed -E 's|http://([^@]+)@.*|\1|')
PROXY_HOSTPORT=$(echo "$PROXY_URL" | sed -E 's|http://[^@]+@([^/]+)|\1|')
PROXY_HOST=$(echo "$PROXY_HOSTPORT" | cut -d: -f1)
PROXY_PORT=$(echo "$PROXY_HOSTPORT" | cut -d: -f2)
CA_BUNDLE="${CA_BUNDLE:-/etc/ssl/certs/ca-certificates.crt}"

if [ ! -f "$HOSTS_FILE" ]; then
  echo "ERROR: hosts file tidak ditemukan: $HOSTS_FILE" >&2
  echo "Salin dari scripts/hosts.cf.example" >&2
  exit 1
fi

# 1. socat relay: 127.0.0.1:7844 -> via proxy -> Cloudflare edge
socat TCP-LISTEN:7844,bind=127.0.0.1,fork,reuseaddr \
  PROXY:"$PROXY_HOST":"$EDGE_IP":7844,proxyport="$PROXY_PORT",proxyauth="$PROXY_AUTH" &
RELAY_PID=$!
trap "kill $RELAY_PID 2>/dev/null" EXIT
sleep 2

# 2. cloudflared dalam mount namespace (hosts override)
exec unshare --mount bash -c "
mount --bind \"$HOSTS_FILE\" /etc/hosts
export SSL_CERT_FILE=\"$CA_BUNDLE\"
export -n http_proxy https_proxy HTTP_PROXY HTTPS_PROXY
exec cloudflared tunnel --no-autoupdate --protocol http2 \
  --edge region1.v2.argotunnel.com:7844 \
  --url http://127.0.0.1:\"$LOCAL_PORT\"
"
