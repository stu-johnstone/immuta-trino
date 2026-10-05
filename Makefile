# Disposable local Trino + Apache Iceberg lab for Immuta integration testing.
# Run `make` or `make help` to see everything you can do.
SHELL := /usr/bin/env bash
.DEFAULT_GOAL := help

# Docker Compose reads COMPOSE_FILE natively, so no -f flags are needed in any
# target. scripts/compose-files.sh appends the Immuta access control overlay
# once the plugin and the generated configuration are both present.
export COMPOSE_FILE := $(shell scripts/compose-files.sh)

# For `make query USER=... SQL="..."` and `make cli USER=...`.
#
# USER is only honoured when it comes from the command line: make also imports
# the shell's own USER variable, and silently querying as your login name
# instead of a test identity would be confusing.
# Both are exported rather than interpolated into the recipe so that SQL
# containing quotes (WHERE region = 'EMEA') survives intact.
USER_NAME := $(if $(filter command line,$(origin USER)),$(USER),)
SQL ?=
export USER_NAME
export SQL

# Optional service filter, e.g. `make logs SERVICE=iceberg-rest`.
SERVICE ?=
# Path to Immuta's generated properties file, for install-immuta-config.
FILE ?=

.PHONY: help prereqs up down restart status logs seed smoke query cli users \
        tunnel tunnel-url tunnel-down install-immuta-config reset

help: ## Show this help
	@printf '\nLocal Trino + Apache Iceberg lab for Immuta integration testing\n\n'
	@grep -hE '^[a-zA-Z_-]+:.*?## ' $(MAKEFILE_LIST) \
	  | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-23s\033[0m %s\n", $$1, $$2}'
	@printf '\nFirst run:  make prereqs && make up && make seed && make smoke\n'
	@printf 'Immuta:     make tunnel  (expose Trino), then see README.md\n\n'

prereqs: ## Check Docker, Compose, ports, memory and project layout
	@scripts/prereqs.sh

# Real file target: .env is gitignored and created on demand.
.env:
	@cp .env.example .env
	@printf 'Created .env from .env.example\n'

up: .env ## Start Trino and the Iceberg REST catalog, wait until ready
	@mkdir -p data/warehouse data/catalog
	docker compose up -d
	@scripts/wait-for-trino.sh

down: ## Stop the stack and remove containers, keeping all data
	docker compose down

restart: ## Recreate the stack, picking up .env and Trino config changes
	@$(MAKE) --no-print-directory down
	@$(MAKE) --no-print-directory up

status: ## Health, endpoints, access control mode and data sizes
	@scripts/status.sh

logs: ## Follow container logs, e.g. make logs SERVICE=trino
	docker compose logs -f --tail=200 $(SERVICE)

seed: ## Load the synthetic finance / medical / manufacturing test data
	@scripts/seed.sh

smoke: ## Verify the stack, the seeded data and the test identities
	@scripts/smoke.sh

query: ## Run SQL as a test user: make query USER=finance_analyst SQL="SELECT 1"
	@scripts/query.sh

cli: ## Interactive Trino shell: make cli USER=finance_analyst
	docker compose exec trino trino --server http://localhost:8080 \
	  --user "$${USER_NAME:-data_admin}"

users: ## List the logical test users and how to map them in Immuta
	@scripts/users.sh

tunnel: ## Expose Trino to the Immuta tenant through a cloudflared tunnel
	@scripts/tunnel.sh up

tunnel-url: ## Print the current public Trino URL for Immuta
	@scripts/tunnel.sh url

tunnel-down: ## Stop the tunnel and make Trino local-only again
	@scripts/tunnel.sh down

install-immuta-config: ## Install Immuta's properties: make install-immuta-config FILE=...
	@scripts/install-immuta-config.sh "$(FILE)"

reset: ## DESTRUCTIVE: delete containers and ALL local Iceberg data
	@scripts/reset.sh
