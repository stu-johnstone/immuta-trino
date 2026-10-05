#!/usr/bin/env bash
# Shared helpers for the Makefile targets. Source this, do not execute it.
# shellcheck shell=bash
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$PROJECT_ROOT"

TRINO_CONTAINER="immuta-trino"
CATALOG_CONTAINER="immuta-trino-catalog"
TUNNEL_CONTAINER="immuta-trino-tunnel"
TRINO_INTERNAL_URL="http://localhost:8080"

# Docker Compose reads COMPOSE_FILE natively. The Makefile exports it; set it
# here too so every script also works when run directly.
if [[ -z "${COMPOSE_FILE:-}" ]]; then
  COMPOSE_FILE="$(scripts/compose-files.sh)"
  export COMPOSE_FILE
fi

# Loads .env, but never overrides a variable that is already set in the
# environment. This matches Docker Compose's own precedence rules, so
# `TRINO_HTTP_PORT=18080 make status` reports the port actually in use.
load_env() {
  [[ -f .env ]] || return 0
  local line key val
  while IFS= read -r line || [[ -n "$line" ]]; do
    case "$line" in ''|\#*) continue ;; esac
    [[ "$line" == *=* ]] || continue
    key="$(printf '%s' "${line%%=*}" | tr -d '[:space:]')"
    val="${line#*=}"
    [[ -n "$key" ]] || continue
    if [[ -z "${!key:-}" ]]; then
      export "$key=$val"
    fi
  done < .env
}

if [[ -t 1 && -z "${NO_COLOR:-}" ]]; then
  C_RESET=$'\033[0m'; C_RED=$'\033[31m'; C_GREEN=$'\033[32m'
  C_YELLOW=$'\033[33m'; C_BLUE=$'\033[34m'; C_BOLD=$'\033[1m'
else
  C_RESET=""; C_RED=""; C_GREEN=""; C_YELLOW=""; C_BLUE=""; C_BOLD=""
fi

info()  { printf '%s\n' "$*"; }
head1() { printf '\n%s%s%s\n' "$C_BOLD" "$*" "$C_RESET"; }
ok()    { printf '%s  ok  %s %s\n' "$C_GREEN" "$C_RESET" "$*"; }
warn()  { printf '%s warn %s %s\n' "$C_YELLOW" "$C_RESET" "$*"; }
fail()  { printf '%s fail %s %s\n' "$C_RED" "$C_RESET" "$*"; }
die()   { fail "$*"; exit 1; }

# True when the Immuta access control overlay is active.
immuta_enabled() { [[ "$COMPOSE_FILE" == *docker-compose.immuta.yml* ]]; }

require_trino_running() {
  docker inspect "$TRINO_CONTAINER" >/dev/null 2>&1 \
    || die "Trino is not running. Start it with 'make up'."
  local status
  status="$(docker inspect "$TRINO_CONTAINER" --format '{{.State.Health.Status}}' 2>/dev/null || echo unknown)"
  [[ "$status" == "healthy" ]] \
    || die "Trino container is '$status', not healthy. Try 'make status' and 'make logs'."
}

# Run the Trino CLI inside the Trino container as a given logical user.
#   run_trino <user> <cli args...>
# Keeps the CLI exit code and drops the harmless jline terminal warning that
# the CLI prints when it runs without a TTY.
#
# Deliberately no `docker exec -i`: with stdin attached, the CLI consumes the
# caller's stdin, which silently swallows the input of enclosing `while read`
# loops (as in scripts/smoke.sh).
run_trino() {
  local user="$1"; shift
  local errfile rc=0
  errfile="$(mktemp)"
  docker exec "$TRINO_CONTAINER" \
    trino --server "$TRINO_INTERNAL_URL" --user "$user" "$@" 2>"$errfile" || rc=$?
  grep -v -E 'org\.jline|Unable to create a system terminal|^WARNING: ' "$errfile" >&2 || true
  rm -f "$errfile"
  return "$rc"
}

# Single scalar value from a query, unquoted.
query_scalar() {
  local user="$1" sql="$2"
  run_trino "$user" --output-format TSV --execute "$sql"
}
