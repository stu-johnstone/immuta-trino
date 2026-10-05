#!/usr/bin/env bash
# Checks everything this project needs before `make up`.
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

problems=0

# Converts 1200m / 2g / 512M to MiB. Written for bash 3.2, which is what
# macOS ships, so no ${var,,} and no ${var//[^0-9]/}.
parse_mem() {
  local v n
  v="$(printf '%s' "$1" | tr '[:upper:]' '[:lower:]')"
  n="$(printf '%s' "$v" | tr -cd '0-9.')"
  [[ -n "$n" ]] || n=0
  case "$v" in
    *g) awk -v n="$n" 'BEGIN{printf "%d", n*1024}' ;;
    *m) awk -v n="$n" 'BEGIN{printf "%d", n}' ;;
    *)  awk -v n="$n" 'BEGIN{printf "%d", n/1048576}' ;;
  esac
}

port_in_use() {
  local port="$1"
  if command -v lsof >/dev/null 2>&1; then
    lsof -nP -iTCP:"$port" -sTCP:LISTEN >/dev/null 2>&1
  else
    nc -z 127.0.0.1 "$port" >/dev/null 2>&1
  fi
}

head1 "Tooling"
if command -v docker >/dev/null 2>&1; then
  ok "docker CLI: $(docker --version | cut -d, -f1)"
else
  fail "docker CLI not found. Install Docker Desktop, Colima or Rancher Desktop."; problems=$((problems+1))
fi

if docker info >/dev/null 2>&1; then
  ok "docker daemon reachable (context: $(docker context show 2>/dev/null))"
else
  fail "cannot reach the docker daemon. Start it (e.g. 'colima start' or Docker Desktop)."; problems=$((problems+1))
fi

if docker compose version >/dev/null 2>&1; then
  ok "docker compose: $(docker compose version --short 2>/dev/null)"
else
  fail "'docker compose' is unavailable. Install the Compose v2 plugin (brew install docker-compose)."
  info "       If Docker Desktop was removed, ~/.docker/cli-plugins may hold dangling symlinks."
  problems=$((problems+1))
fi

for t in curl jq; do
  if command -v "$t" >/dev/null 2>&1; then ok "$t present"; else warn "$t not found (only used by helper output)"; fi
done

head1 "Project layout"
if [[ -f .env ]]; then ok ".env present"; else warn ".env missing - 'make up' will create it from .env.example"; fi

# shellcheck disable=SC1091
if [[ -f .env ]]; then set -a; source ./.env; set +a; fi
TRINO_HTTP_PORT="${TRINO_HTTP_PORT:-8080}"
ICEBERG_REST_PORT="${ICEBERG_REST_PORT:-8181}"
TRINO_MEMORY="${TRINO_MEMORY:-1200m}"
ICEBERG_REST_MEMORY="${ICEBERG_REST_MEMORY:-512m}"

for f in docker-compose.yml trino/etc/config.properties trino/etc/catalog/iceberg.properties \
         sql/00_schemas.sql sql/10_finance.sql sql/20_medical.sql sql/30_manufacturing.sql; do
  if [[ -f "$f" ]]; then ok "$f"; else fail "missing $f"; problems=$((problems+1)); fi
done

mkdir -p data/warehouse data/catalog
ok "persistence directories: ./data/warehouse (Iceberg data) and ./data/catalog (catalog state)"

if [[ -f .env ]] && docker compose config -q 2>/dev/null; then
  ok "compose configuration is valid"
elif [[ -f .env ]]; then
  fail "'docker compose config' rejected the configuration:"
  docker compose config -q || true
  problems=$((problems+1))
fi

head1 "Ports"
stack_up="$(docker ps -q --filter "name=^${TRINO_CONTAINER}$" | wc -l | tr -d ' ')"
for p in "$TRINO_HTTP_PORT" "$ICEBERG_REST_PORT"; do
  if ! port_in_use "$p"; then
    ok "port $p free"
  elif [[ "$stack_up" != "0" ]]; then
    ok "port $p in use by this stack (already running)"
  else
    fail "port $p is already in use by another process."
    info "       Free it, or set TRINO_HTTP_PORT / ICEBERG_REST_PORT in .env."
    problems=$((problems+1))
  fi
done

head1 "Resources"
if docker info >/dev/null 2>&1; then
  vm_bytes="$(docker info --format '{{.MemTotal}}' 2>/dev/null || echo 0)"
  vm_mib=$(( vm_bytes / 1048576 ))
  need_mib=$(( $(parse_mem "$TRINO_MEMORY") + $(parse_mem "$ICEBERG_REST_MEMORY") ))
  info "       docker VM memory: ${vm_mib} MiB, stack limits: ${need_mib} MiB"
  if (( vm_mib >= need_mib + 256 )); then
    ok "enough memory for TRINO_MEMORY=${TRINO_MEMORY} + ICEBERG_REST_MEMORY=${ICEBERG_REST_MEMORY}"
  else
    fail "not enough memory for the configured limits."
    info "       Either lower TRINO_MEMORY in .env, or give the VM more RAM, e.g.:"
    info "         colima stop && colima start --cpu 4 --memory 8"
    problems=$((problems+1))
  fi
  (( vm_mib < 4096 )) && warn "4 GiB or more is recommended for comfortable query performance"
  cpus="$(docker info --format '{{.NCPU}}' 2>/dev/null || echo '?')"
  (( cpus < 4 )) && warn "docker VM has ${cpus} CPUs; 4 is recommended"
fi

head1 "Immuta access control"
if immuta_enabled; then
  ok "plugin and configuration found: Immuta access control WILL be enabled"
else
  info "       not enabled yet (the stack runs with Trino's default allow-all access control)."
  info "       See README.md > Immuta setup. Install with:"
  info "         make install-immuta-config FILE=/path/to/immuta-access-control.properties"
fi

head1 "Result"
if (( problems == 0 )); then
  ok "all prerequisites satisfied - run 'make up'"
else
  die "$problems problem(s) found; fix them before running 'make up'"
fi
