#!/usr/bin/env bash
# End-to-end check: stack health, catalog, seeded data, persistence and the
# logical test identities. Exits non-zero if anything fails.
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

failures=0

check() { # check <description> <expected> <actual>
  local desc="$1" expected="$2" actual="$3"
  if [[ "$expected" == "$actual" ]]; then
    ok "$desc"
  else
    fail "$desc (expected '$expected', got '$actual')"
    failures=$((failures+1))
  fi
}

head1 "Stack"
require_trino_running
ok "Trino container is healthy"

catalog_health="$(docker inspect "$CATALOG_CONTAINER" --format '{{.State.Health.Status}}' 2>/dev/null || echo missing)"
check "Iceberg REST catalog is healthy" "healthy" "$catalog_health"

head1 "Catalog"
catalogs="$(query_scalar immuta-system 'SHOW CATALOGS' | tr -d '\"' | tr '\n' ' ')"
if [[ "$catalogs" == *iceberg* ]]; then ok "the 'iceberg' catalog is present"; else
  fail "the 'iceberg' catalog is missing (saw: $catalogs)"; failures=$((failures+1)); fi

for schema in finance medical manufacturing; do
  if query_scalar immuta-system 'SHOW SCHEMAS FROM iceberg' | tr -d '\"' | grep -qx "$schema"; then
    ok "schema iceberg.$schema exists"
  else
    fail "schema iceberg.$schema is missing. Run 'make seed'."; failures=$((failures+1))
  fi
done

head1 "Seeded row counts"
while read -r table expected; do
  actual="$(query_scalar immuta-system "SELECT count(*) FROM iceberg.${table}" 2>/dev/null || echo 'query failed')"
  check "iceberg.${table}" "$expected" "$actual"
done <<'TABLES'
finance.customers 20
finance.transactions 45
medical.patients 16
medical.encounters 30
manufacturing.employees 16
manufacturing.suppliers 10
TABLES

head1 "Sensitive columns are readable without Immuta policy"
# Baseline for policy testing: before Immuta masks anything, these return raw
# values. After you build policies, the same queries should change.
ssn="$(query_scalar finance_analyst \
  "SELECT ssn FROM iceberg.finance.customers WHERE customer_id = 1001" | tr -d '\"')"
check "raw finance SSN visible to finance_analyst" "900-11-0001" "$ssn"
mrn="$(query_scalar medical_researcher \
  "SELECT medical_record_number FROM iceberg.medical.patients WHERE patient_id = 2001" | tr -d '\"')"
check "raw medical MRN visible to medical_researcher" "MRN-000001" "$mrn"
salary="$(query_scalar manufacturing_operator \
  "SELECT salary FROM iceberg.manufacturing.employees WHERE employee_id = 3001" | tr -d '\"')"
check "raw manufacturing salary visible to manufacturing_operator" "92500.00" "$salary"

head1 "Logical test identities"
for u in immuta-system finance_analyst medical_researcher manufacturing_operator data_admin; do
  actual="$(query_scalar "$u" 'SELECT current_user' | tr -d '\"' || echo 'query failed')"
  check "Trino sees request identity '$u'" "$u" "$actual"
done

head1 "Writes work (Iceberg INSERT round trip)"
if run_trino data_admin --execute "
DROP TABLE IF EXISTS iceberg.finance.smoke_tmp;
CREATE TABLE iceberg.finance.smoke_tmp (id bigint, note varchar);
INSERT INTO iceberg.finance.smoke_tmp VALUES (1, 'smoke');
" >/dev/null 2>&1; then
  actual="$(query_scalar data_admin 'SELECT note FROM iceberg.finance.smoke_tmp' | tr -d '\"')"
  check "created a table, inserted and read it back" "smoke" "$actual"
  run_trino data_admin --execute 'DROP TABLE IF EXISTS iceberg.finance.smoke_tmp' >/dev/null 2>&1 || true
else
  fail "could not create and write an Iceberg table"; failures=$((failures+1))
fi

head1 "Persistence"
if [[ -f data/catalog/iceberg_catalog.db ]]; then
  ok "catalog database present at ./data/catalog/iceberg_catalog.db"
else
  fail "./data/catalog/iceberg_catalog.db is missing"; failures=$((failures+1))
fi
parquet_count="$(find data/warehouse -name '*.parquet' 2>/dev/null | wc -l | tr -d ' ')"
if (( parquet_count > 0 )); then
  ok "$parquet_count Parquet data file(s) on the ./data/warehouse bind mount"
else
  fail "no Parquet files under ./data/warehouse"; failures=$((failures+1))
fi

head1 "Access control mode"
if immuta_enabled; then
  ok "Immuta access control is enabled; the readable-sensitive-column checks"
  info "       above may legitimately fail once policies are applied in Immuta."
else
  info "       Immuta access control is not enabled yet: this run is the"
  info "       pre-policy baseline. See README.md > Immuta setup."
fi

head1 "Result"
if (( failures == 0 )); then
  ok "all smoke checks passed"
else
  die "$failures smoke check(s) failed"
fi
