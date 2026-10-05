#!/usr/bin/env bash
# DESTRUCTIVE: removes the containers and every local Iceberg artefact.
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

head1 "WARNING: this deletes local Iceberg data and catalog state"
cat <<TXT
  About to permanently delete:
    * all stack containers and the compose network
    * ./data/warehouse  ALL Iceberg data and metadata files
    * ./data/catalog    the Iceberg REST catalog database (every table pointer)

  Every seeded table disappears. Any table you created by hand is lost too.
  Your .env, the Immuta configuration in ./immuta and all tracked files are
  left untouched. Recreate the lab afterwards with: make up && make seed

  Data objects already registered in Immuta will point at tables that no
  longer exist until you re-seed and re-run object sync.
TXT

if [[ "${CONFIRM:-}" == "RESET" ]]; then
  info ""
  warn "CONFIRM=RESET supplied, proceeding without prompting"
else
  info ""
  printf 'Type RESET (all caps) to continue, anything else aborts: '
  read -r answer
  if [[ "$answer" != "RESET" ]]; then
    info "Aborted. Nothing was deleted."
    exit 1
  fi
fi

head1 "Removing containers"
docker compose down --remove-orphans --volumes || true
docker rm -f "$TUNNEL_CONTAINER" >/dev/null 2>&1 || true

head1 "Deleting local Iceberg state"
rm -rf data/warehouse data/catalog
mkdir -p data/warehouse data/catalog
ok "./data/warehouse and ./data/catalog are empty"
ok "reset complete - run 'make up && make seed' to rebuild the lab"
