#!/usr/bin/env bash
# Loads the synthetic finance / medical / manufacturing test data.
# Idempotent: each file drops and recreates its own tables.
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

SEED_USER="${SEED_USER:-data_admin}"
require_trino_running

head1 "Seeding Iceberg test data as '$SEED_USER'"
for f in sql/00_schemas.sql sql/10_finance.sql sql/20_medical.sql sql/30_manufacturing.sql; do
  info "  -> $f"
  run_trino "$SEED_USER" --file "/${f}" >/dev/null \
    || die "failed while executing $f"
done
ok "seed complete"

head1 "Row counts"
run_trino "$SEED_USER" --output-format ALIGNED --file /sql/90_counts.sql
