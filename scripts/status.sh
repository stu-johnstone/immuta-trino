#!/usr/bin/env bash
# Health and configuration summary for the local stack.
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

load_env

head1 "Containers"
docker compose ps --format 'table {{.Service}}\t{{.Image}}\t{{.Status}}\t{{.Ports}}' 2>/dev/null \
  || warn "compose is not running"

head1 "Endpoints"
info "  Trino HTTP / JDBC   http://localhost:${TRINO_HTTP_PORT:-8080}"
info "  Trino web UI        http://localhost:${TRINO_HTTP_PORT:-8080}/ui/ (any username, no password)"
info "  Iceberg REST        http://localhost:${ICEBERG_REST_PORT:-8181}/v1/config"

if docker ps --format '{{.Names}}' | grep -qx "$TUNNEL_CONTAINER"; then
  url="$(docker logs "$TUNNEL_CONTAINER" 2>&1 | grep -oE 'https://[a-z0-9-]+\.trycloudflare\.com' | tail -1 || true)"
  if [[ -n "$url" ]]; then
    info "  Public tunnel       $url"
  else
    info "  Public tunnel       running (named tunnel, or URL not in the log yet)"
  fi
else
  info "  Public tunnel       not running ('make tunnel' to expose Trino to Immuta)"
fi

head1 "Trino"
if docker inspect "$TRINO_CONTAINER" >/dev/null 2>&1; then
  health="$(docker inspect "$TRINO_CONTAINER" --format '{{.State.Health.Status}}')"
  [[ "$health" == "healthy" ]] && ok "health: $health" || warn "health: $health"
  if [[ "$health" == "healthy" ]]; then
    info "  version:    $(query_scalar immuta-system 'SELECT version()' 2>/dev/null | tr -d '\"')"
    info "  catalogs:   $(query_scalar immuta-system 'SHOW CATALOGS' 2>/dev/null | tr '\n' ' ')"
    info "  schemas:    $(query_scalar immuta-system 'SHOW SCHEMAS FROM iceberg' 2>/dev/null | tr '\n' ' ')"
  fi
else
  warn "the Trino container does not exist. Run 'make up'."
fi

head1 "Access control"
if immuta_enabled; then
  ok "Immuta access control overlay is ACTIVE (docker-compose.immuta.yml)"
  info "  plugin jars: $(ls immuta/plugin/*.jar 2>/dev/null | wc -l | tr -d ' ')"
else
  info "  Immuta access control is NOT enabled; Trino allows everything."
  info "  Install the plugin and config, then 'make restart'. See README.md."
fi

head1 "Persistence (bind mounts in this project)"
info "  Iceberg warehouse   ./data/warehouse  $(du -sh data/warehouse 2>/dev/null | cut -f1 || echo '-')"
info "  Iceberg catalog     ./data/catalog    $(du -sh data/catalog 2>/dev/null | cut -f1 || echo '-')"
