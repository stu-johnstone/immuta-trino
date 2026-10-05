#!/usr/bin/env bash
# Runs one SQL statement as a logical Trino user.
#   make query USER=finance_analyst SQL="SELECT * FROM iceberg.finance.customers LIMIT 5"
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

USER_NAME="${USER_NAME:-}"
SQL="${SQL:-}"

if [[ -z "$SQL" ]]; then
  fail 'SQL is required.'
  info 'Example:'
  info '  make query USER=finance_analyst SQL="SELECT * FROM iceberg.finance.customers LIMIT 5"'
  exit 2
fi

if [[ -z "$USER_NAME" ]]; then
  USER_NAME="data_admin"
  warn "USER not set, defaulting to '$USER_NAME' (see 'make users')"
fi

require_trino_running
run_trino "$USER_NAME" --execute "$SQL"
