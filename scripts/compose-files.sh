#!/usr/bin/env bash
# Prints the value for COMPOSE_FILE: the base stack, plus the Immuta access
# control overlay when the plugin and the generated configuration are both
# present. Single source of truth, used by the Makefile and scripts/lib.sh.
set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")/.."

files="docker-compose.yml"
if [[ -f immuta/immuta-access-control.properties ]] \
  && compgen -G 'immuta/plugin/*.jar' >/dev/null; then
  files="${files}:docker-compose.immuta.yml"
fi
echo "$files"
