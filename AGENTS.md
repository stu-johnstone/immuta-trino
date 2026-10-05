# Trino and Immuta Iceberg Test Project

## Purpose

Build a disposable local development project for testing the Immuta integration with open-source Trino.

The project must run Trino in Docker, use Apache Iceberg for table storage, persist data across container restarts, and provide synthetic PII-like data for finance, medical, and manufacturing policy tests.

Do not add PostgreSQL. The persistence layer should use Docker-native volumes or bind mounts and an Iceberg-compatible catalog and storage approach.

## Required deliverables

Create:

- `README.md` with clear prerequisites, startup, shutdown, persistence, testing, Immuta setup, and troubleshooting instructions.
- `Makefile` with simple automation for repeatable setup, startup, health checks, seeding, querying, logs, reset, and cleanup.
- `docker-compose.yml` or an equivalent Docker setup.
- Any Trino configuration, Iceberg catalog configuration, initialization scripts, and test-data scripts required to run the project.

## Architecture requirements

- Use the official `trinodb/trino` Docker image.
- Pin a specific Trino version rather than using `latest`.
- Use Apache Iceberg for all test tables.
- Do not use PostgreSQL.
- Persist the Iceberg data files to a bind-mounted project directory.
- Persist the Iceberg catalog metadata as well. Do not use an in-memory-only catalog.
- Choose the simplest Iceberg catalog that works with the selected Trino version and does not require PostgreSQL. A lightweight REST catalog, Nessie, or another suitable catalog is acceptable.
- If an additional catalog or object-storage container is required, keep it minimal and persist its state with Docker volumes.
- Make clear in the README which local paths or Docker volumes contain the Iceberg warehouse and catalog state.
- Do not rely on the container filesystem for persistence.
- The Immuta SaaS tenant must be able to reach the Trino endpoint for connection registration and object sync.  Include some kind of tunnling to provide this

## Data requirements

Seed synthetic, clearly non-production data in these Iceberg schemas or equivalent domains:

- `finance`
  - Customers with names, email addresses, phone numbers, SSNs, account numbers, and balances.
  - Transactions with customer IDs, card last four digits, amounts, merchants, and timestamps.
- `medical`
  - Patients with names, email addresses, phone numbers, dates of birth, SSNs, medical record numbers, diagnoses, and insurance member IDs.
  - Encounters with patient IDs, providers, diagnosis codes, notes, and dates.
- `manufacturing`
  - Employees with names, email addresses, phone numbers, national IDs, salaries, badge IDs, and sites.
  - Suppliers with contact email, tax IDs, bank-account-like values, and sites.

Use fictional values and mark records as test data where useful. Never use customer or production data.

## User testing requirements

Provide logical Trino test usernames:

- `immuta-system`
- `finance_analyst`
- `medical_researcher`
- `manufacturing_operator`
- `data_admin`

Local Trino does not need full authentication for this disposable test. It is acceptable to send these usernames as the Trino request identity, provided the README clearly explains that they are logical test identities and not persisted Trino accounts.

Document how to map each exact Trino username to an Immuta user. The Immuta system username must be separate from the policy-testing users.

## Immuta integration requirements

Use Immuta's current Trino connection workflow:

1. Register the Trino connection in Immuta under **Data > Connections**.
2. Create or configure the Trino system account used by Immuta for object sync and identification.
3. Install the Immuta Trino plugin version matching the selected Trino version.
4. Apply the generated `immuta-access-control.properties` configuration.
5. Enable Immuta access control in Trino.
6. Map Trino usernames to Immuta users.
7. Register the Iceberg tables and test subscription, masking, row-filtering, and column-level policies.

The generated Immuta configuration contains an API key and must not be committed, printed, or included in documentation. Add it to `.gitignore` and provide a manual or parameterized Make target for installing it locally.

## Makefile expectations

Automate where practical:

- `make prereqs`
- `make up`
- `make down`
- `make restart`
- `make status`
- `make logs`
- `make seed`
- `make smoke`
- `make query USER=... SQL=...`
- `make users`
- `make install-immuta-config FILE=...`
- `make reset`

`make reset` must require an explicit confirmation and must clearly warn that it deletes local Iceberg data and catalog state.

## Working rules

- Prefer Makefile targets over undocumented shell commands.
- Keep configuration and seed scripts readable and idempotent where possible.
- Never commit secrets, API keys, passwords, certificates, or generated Immuta configuration.
- Keep the default deployment suitable for local development, not production.
- Explain manual steps whenever automation depends on credentials, Immuta access, plugin downloads, or external networking.
- Validate all Python, SQL, YAML, and Makefile files before finishing.