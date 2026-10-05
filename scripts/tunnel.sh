#!/usr/bin/env bash
# Manages the cloudflared tunnel that makes this local Trino reachable from
# the Immuta SaaS tenant.
#   scripts/tunnel.sh up | url | down
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

load_env

action="${1:-up}"

tunnel_profile() {
  if [[ -n "${TUNNEL_TOKEN:-}" ]]; then echo "tunnel-named"; else echo "tunnel"; fi
}

case "$action" in
  up)
    require_trino_running
    profile="$(tunnel_profile)"
    head1 "Starting cloudflared ($profile)"
    if [[ "$profile" == "tunnel" ]]; then
      info "  Quick tunnel: no Cloudflare account, random hostname, changes on restart."
      info "  Set TUNNEL_TOKEN in .env for a stable named tunnel."
    fi
    warn "Trino has NO authentication. While the tunnel is up, anyone with the"
    warn "URL can query this synthetic data. Run 'make tunnel-down' when done."
    docker compose --profile "$profile" up -d "$profile"
    exec "$0" url
    ;;
  url)
    docker ps --format '{{.Names}}' | grep -qx "$TUNNEL_CONTAINER" \
      || die "the tunnel is not running. Start it with 'make tunnel'."
    if [[ -n "${TUNNEL_TOKEN:-}" ]]; then
      head1 "Named tunnel is running"
      info "  Use the public hostname you configured for this tunnel in Cloudflare."
      exit 0
    fi
    head1 "Public Trino URL"
    url=""
    for _ in $(seq 1 30); do
      url="$(docker logs "$TUNNEL_CONTAINER" 2>&1 \
        | grep -oE 'https://[a-z0-9-]+\.trycloudflare\.com' | tail -1 || true)"
      [[ -n "$url" ]] && break
      sleep 2
    done
    [[ -n "$url" ]] || die "could not find the tunnel URL yet. Check 'docker logs $TUNNEL_CONTAINER'."
    host="${url#https://}"
    ok "$url"
    cat <<TXT

  Register this in Immuta under Data > Connections > Trino:
    Host      $host
    Port      443
    SSL/TLS   enabled
    Username  immuta-system

  Quick check from your machine:
    curl -s -H 'X-Trino-User: immuta-system' $url/v1/info
TXT
    ;;
  down)
    head1 "Stopping cloudflared"
    docker compose --profile tunnel --profile tunnel-named rm -s -f tunnel tunnel-named >/dev/null 2>&1 || true
    docker rm -f "$TUNNEL_CONTAINER" >/dev/null 2>&1 || true
    ok "tunnel stopped; Trino is local-only again"
    ;;
  *)
    die "unknown action '$action' (expected up, url or down)"
    ;;
esac
