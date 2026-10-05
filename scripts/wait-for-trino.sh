#!/usr/bin/env bash
# Blocks until Trino is healthy and the Iceberg catalog answers queries.
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

timeout="${TIMEOUT:-180}"
deadline=$(( $(date +%s) + timeout ))

printf 'Waiting for Trino to become healthy'
while :; do
  status="$(docker inspect "$TRINO_CONTAINER" --format '{{.State.Health.Status}}' 2>/dev/null || echo missing)"
  [[ "$status" == "healthy" ]] && break
  if (( $(date +%s) > deadline )); then
    printf '\n'
    die "Trino did not become healthy within ${timeout}s (last state: $status). Run 'make logs'."
  fi
  printf '.'
  sleep 3
done
printf '\n'
ok "Trino is healthy"

printf 'Waiting for the Iceberg catalog'
while :; do
  if run_trino immuta-system --output-format TSV --execute 'SHOW SCHEMAS FROM iceberg' >/dev/null 2>&1; then
    break
  fi
  if (( $(date +%s) > deadline )); then
    printf '\n'
    die "the Iceberg catalog did not respond within ${timeout}s. Run 'make logs SERVICE=iceberg-rest'."
  fi
  printf '.'
  sleep 3
done
printf '\n'
ok "Iceberg catalog is answering queries"
