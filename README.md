# Local Trino + Apache Iceberg lab for Immuta

A disposable local lab for testing the Immuta Trino integration end to end:
open source Trino over Apache Iceberg tables, seeded with synthetic data for
three domains, reachable from an Immuta SaaS tenant through a tunnel.

Everything is driven by `make`. Run `make` to see every target.

```
make prereqs     # check Docker, Compose, ports and memory
make up          # start the stack and wait until it is ready
make seed        # load the synthetic test data
make smoke       # verify the whole thing works
```

> **This lab is deliberately insecure.** Trino runs with no authentication and
> no TLS of its own, and `make tunnel` publishes it on the public internet.
> Only ever put synthetic data in it, and run `make tunnel-down` when you are
> finished. See [Security](#security).

## Architecture

```
          your machine                             Immuta SaaS tenant
  +---------------------------+                   +--------------------+
  |  Trino (coordinator)      |<--- HTTPS --------|  connection +      |
  |  trinodb/trino, pinned    |   cloudflared     |  policies          |
  +---------------------------+     tunnel        +--------------------+
        |              |
        | Iceberg REST  | file:///warehouse
        v              v
  +------------------+  +-----------------------------+
  |  Iceberg REST    |  |  ./data/warehouse           |
  |  catalog         |  |  Parquet + Iceberg metadata |
  |  (SQLite file)   |  +-----------------------------+
  |  ./data/catalog  |
  +------------------+
```

Three containers, all pinned by version in `.env`:

| Service        | Image                         | Purpose                                      |
| -------------- | ----------------------------- | -------------------------------------------- |
| `trino`        | `trinodb/trino`               | Query engine, where Immuta enforces policy   |
| `iceberg-rest` | `apache/iceberg-rest-fixture` | Iceberg REST catalog, backed by a SQLite file |
| `tunnel`       | `cloudflare/cloudflared`      | Makes Trino reachable from Immuta (optional) |

Design choices worth knowing:

- **No PostgreSQL.** The Iceberg catalog is the Apache REST catalog service
  backed by a single SQLite file in `./data/catalog`. It is a real persistent
  catalog, not an in-memory one.
- **Everything persists to this project directory.** Iceberg data and metadata
  live in `./data/warehouse`, catalog state in `./data/catalog`. Both are bind
  mounts, so `make down`, `make restart` and container upgrades do not lose
  data. Nothing important is kept inside a container.
- **No object storage container.** Trino and the catalog service share the same
  `./data/warehouse` bind mount at the same path (`/warehouse`), so the
  warehouse is plain local files you can inspect with `ls`.
- **The Trino version is pinned** in `.env` and must match the Immuta plugin.

## Prerequisites

- Docker with Compose v2 (`docker compose version`). Docker Desktop, Colima or
  Rancher Desktop are all fine.
- A Docker VM with at least **4 GiB** of memory and 4 CPUs recommended. The
  defaults in `.env.example` (`TRINO_MEMORY=1200m`) are sized to fit in a 2 GiB
  VM; raise them if you have more.
- `make`, `curl` and `bash`. The scripts are written for the bash 3.2 that
  macOS ships.

`make prereqs` checks all of this, including port conflicts and whether the
configured memory limits actually fit in your Docker VM.

Using Colima with a small VM? Give it more room:

```
colima stop && colima start --cpu 4 --memory 8
```

## Quick start

```
make prereqs                 # verify the environment
make up                      # start Trino + the Iceberg catalog
make seed                    # create and populate the test tables
make smoke                   # assert that everything works
make status                  # endpoints, health, access control mode
```

`make up` creates `.env` from `.env.example` on first run. `.env` is gitignored:
put local overrides and any tunnel token there.

Query the data as a given test identity:

```
make query USER=finance_analyst SQL="SELECT full_name, ssn, balance FROM iceberg.finance.customers LIMIT 5"
make cli   USER=medical_researcher      # interactive Trino shell
```

The Trino web UI is at <http://localhost:8080/ui/> and accepts any username
with no password.

## Make targets

| Target                  | What it does                                                     |
| ----------------------- | ---------------------------------------------------------------- |
| `make help`             | List all targets (default)                                        |
| `make prereqs`          | Check Docker, Compose, ports, memory and project layout           |
| `make up`               | Start the stack and block until Trino and the catalog are ready   |
| `make down`             | Stop and remove containers, **keeping** all data                  |
| `make restart`          | Recreate the stack, picking up `.env` and Trino config changes    |
| `make status`           | Health, endpoints, access control mode, data sizes, tunnel URL    |
| `make logs`             | Follow logs; `make logs SERVICE=trino` for one service            |
| `make seed`             | Load the synthetic test data (idempotent)                         |
| `make smoke`            | Verify stack, catalog, row counts, identities and persistence     |
| `make query`            | Run one statement: `make query USER=... SQL="..."`                |
| `make cli`              | Interactive Trino shell: `make cli USER=...`                      |
| `make users`            | List the logical test users and how to map them in Immuta         |
| `make tunnel`           | Publish Trino through cloudflared so Immuta can reach it          |
| `make tunnel-url`       | Print the current public Trino URL                                |
| `make tunnel-down`      | Stop the tunnel; Trino becomes local-only again                    |
| `make install-immuta-config` | Install Immuta's generated access control properties file     |
| `make reset`            | **Destructive.** Delete containers and all local Iceberg data     |

## Test data

`make seed` creates three schemas in the `iceberg` catalog. It is idempotent:
each SQL file drops and recreates its own tables, so re-running returns the
lab to a known state.

| Table                              | Rows | Sensitive columns to write policy against          |
| ---------------------------------- | ---: | -------------------------------------------------- |
| `iceberg.finance.customers`        |   20 | `full_name`, `email`, `phone`, `ssn`, `account_number`, `balance` |
| `iceberg.finance.transactions`     |   45 | `card_last_four`, `amount`, `merchant`             |
| `iceberg.medical.patients`         |   16 | `full_name`, `email`, `phone`, `date_of_birth`, `ssn`, `medical_record_number`, `primary_diagnosis`, `insurance_member_id` |
| `iceberg.medical.encounters`       |   30 | `provider_name`, `diagnosis_code`, `encounter_notes` |
| `iceberg.manufacturing.employees`  |   16 | `full_name`, `email`, `phone`, `national_id`, `salary`, `badge_id` |
| `iceberg.manufacturing.suppliers`  |   10 | `contact_email`, `tax_id`, `bank_account_number`   |

There are also low-cardinality columns that are useful for row-level policies
and attribute-based access: `finance.customers.region` (`AMER`, `EMEA`,
`APAC`), `medical.patients.care_site` (`CLINIC-NORTH`, `CLINIC-SOUTH`,
`CLINIC-EAST`) and `manufacturing.employees.site` (`PLANT-ALPHA`,
`PLANT-BRAVO`, `PLANT-CHARLIE`).

### All of this data is fake

Every value is invented, and the formats are chosen so that Immuta's sensitive
data discovery still recognises the column types:

- Emails use the reserved `example.com` / `example.org` domains (RFC 2606).
- Phone numbers use the fictional `+1-555-01xx` range.
- SSNs and national IDs use a `900-xx-xxxx` prefix, which the SSA never issues.
- Tax IDs, bank account numbers and card digits are made-up, non-routable values.
- Every row carries `is_test_data = true`.

Never point this lab at real data, and never load real data into it.

## Test users

This Trino has **no authentication configured**. Whatever username a client
sends is taken as the request identity, and Immuta applies policy to that exact
string. These are therefore *logical test identities*, not persisted Trino
accounts: there are no passwords and nothing to create.

| Username                 | Purpose                                                     |
| ------------------------ | ----------------------------------------------------------- |
| `immuta-system`          | Immuta's own system account for object sync; keep it separate from the policy-testing users |
| `finance_analyst`        | Subject of finance policies                                 |
| `medical_researcher`     | Subject of medical policies                                 |
| `manufacturing_operator` | Subject of manufacturing policies                           |
| `data_admin`             | Table owner, used by `make seed`                            |

Run `make users` for the same list plus the exact mapping steps. To make these
identities meaningful in Immuta, add each username to the matching Immuta user
so Immuta can tie a Trino request to a principal it knows:

1. In Immuta go to **People > Users** and select (or create) the user.
2. Edit the user's connected accounts / aliases.
3. Add the Trino username **exactly** as written above, including underscores
   and hyphens. These identities are case sensitive.
4. Save, then confirm the Trino identity is listed on the user's profile.

Do not map `immuta-system` to a policy-testing user. It is the system account
on the connection itself and is excluded from policy enforcement.

## Immuta setup

Two separate things have to happen, and they are independent:

1. **Immuta must be able to reach Trino** to register the connection and sync
   objects. That is the tunnel.
2. **Trino must enforce Immuta policy**, which needs the Immuta Trino plugin
   and its generated configuration inside the Trino container.

You can do step 1 alone and Immuta will see the tables, but nothing will be
masked or filtered until step 2 is done.

### Step 1: expose Trino to your Immuta tenant

```
make tunnel        # starts cloudflared and prints the public URL
make tunnel-url    # print it again later
```

By default this uses a Cloudflare **quick tunnel**: no Cloudflare account, and
a random `https://<something>.trycloudflare.com` hostname. The hostname changes
every time the tunnel restarts, so if Immuta stores it you will have to update
the connection. For a stable hostname, create a named tunnel in Cloudflare and
put its token in `.env` as `TUNNEL_TOKEN`; `make tunnel` then uses it
automatically.

Trino is configured with `http-server.process-forwarded=true` so that the URIs
it returns to clients point at the tunnel hostname over HTTPS rather than at
`localhost`. Without that, Immuta would submit a query successfully and then
fail to fetch the results.

Then register the connection in Immuta:

| Field    | Value                                      |
| -------- | ------------------------------------------ |
| Host     | the tunnel hostname from `make tunnel-url` |
| Port     | `443`                                      |
| SSL/TLS  | enabled                                    |
| Username | `immuta-system`                            |
| Password | anything; this Trino ignores credentials   |

In Immuta, go to **Data > Connections**, add a Trino connection with those
values, and run object sync. The six tables should appear as data sources. Then
run sensitive data discovery and build policies against the columns listed in
[Test data](#test-data).

Sanity check the tunnel yourself at any time. `make tunnel-url` prints a
ready-to-paste command for the current hostname:

```
curl -s -H 'X-Trino-User: immuta-system' https://<your-tunnel-host>/v1/info
{"nodeVersion":{"version":"476"},"environment":"docker","coordinator":true,"starting":false,...}
```

### Step 2: enable Immuta access control in Trino

**This step is manual, because the Immuta Trino plugin is not publicly
downloadable.** It is distributed per Trino version and requires Immuta
credentials.

1. **Get the plugin.** Obtain the Immuta Trino plugin built for the Trino
   version pinned in `.env` (`TRINO_VERSION`, currently `476`) from your
   Immuta tenant's download page or Immuta support. The plugin version must
   match the Trino version. If only a different version is available, change
   `TRINO_VERSION` in `.env` to match it and run `make restart` (see
   [Changing the Trino version](#changing-the-trino-version)).

2. **Unpack the jars** into `./immuta/plugin/`, flat, so the directory
   contains the `.jar` files directly:

   ```
   ls immuta/plugin/
   immuta-trino-<version>.jar   ...other jars...
   ```

3. **Get the configuration file.** In Immuta, generate the Trino
   `immuta-access-control.properties` file for your tenant. It contains
   `access-control.name=immuta`, your Immuta endpoint and an **API key**.

4. **Install it:**

   ```
   make install-immuta-config FILE=~/Downloads/immuta-access-control.properties
   ```

   The file is copied to `./immuta/immuta-access-control.properties` with mode
   `600`. It is gitignored, and the command verifies that git cannot see it.
   Its contents are never printed.

5. **Restart and verify:**

   ```
   make restart
   make status     # should report: Immuta access control overlay is ACTIVE
   ```

The stack picks this up automatically: once both the plugin jars and the
properties file exist, the Makefile adds `docker-compose.immuta.yml`, which
mounts the plugin into `/usr/lib/trino/plugin/immuta` and the properties file
over `/etc/trino/access-control.properties`. Remove either one and
`make restart` returns Trino to its default allow-all behaviour, which is a
quick way to compare policy on versus off.

### Step 3: confirm policies are actually applied

`make smoke` records the **pre-policy baseline**: it asserts that sensitive
columns come back raw. Once your Immuta policies are live, run the same
queries and watch them change:

```
make query USER=finance_analyst        SQL="SELECT full_name, ssn FROM iceberg.finance.customers LIMIT 5"
make query USER=medical_researcher     SQL="SELECT full_name, medical_record_number FROM iceberg.medical.patients LIMIT 5"
make query USER=manufacturing_operator SQL="SELECT full_name, salary FROM iceberg.manufacturing.employees LIMIT 5"
```

Masked or missing rows mean Immuta is enforcing. Unchanged output means it is
not: check `make status`, then `make logs SERVICE=trino` for plugin errors.

## Security

This is a throwaway test lab, and it is not hardened:

- **Trino has no authentication.** Any username is accepted as-is. That is what
  makes the test identities work without user management.
- **`make tunnel` publishes Trino on the public internet.** While it is
  running, anyone who learns the URL can query everything in the lab. Use
  `make tunnel-down` as soon as you are done, and prefer a named tunnel with
  Cloudflare Access in front of it if you need it up for long.
- **Only synthetic data.** Everything seeded here is fictional by design. Do
  not add real customer, patient or employee data.
- **The Immuta properties file contains an API key.** It lives in
  `./immuta/`, is gitignored, and is installed with mode `600`. Never commit
  it. If it leaks, rotate the key in Immuta.
- Trino and the Iceberg catalog only bind to `127.0.0.1`, so nothing is exposed
  on your LAN unless the tunnel is running.

## Persistence and resetting

| Path               | Contents                                          |
| ------------------ | ------------------------------------------------- |
| `./data/warehouse` | Iceberg data (Parquet) and table metadata         |
| `./data/catalog`   | Iceberg REST catalog database (SQLite)            |

Both are bind mounts in this project and both are gitignored.

- `make down` / `make restart` keep all data. `make smoke` after a restart
  proves the tables are still there.
- `make reset` deletes the containers **and** both directories. It refuses to
  run unless you type `RESET`, or pass `CONFIRM=RESET` for scripted use.
  Afterwards, `make up && make seed` rebuilds the lab from scratch.

After a reset, data sources already registered in Immuta point at tables that
no longer exist. Re-seed and re-run object sync in Immuta.

## Project layout

```
Makefile                      every workflow, start here (`make help`)
docker-compose.yml            Trino, Iceberg REST catalog, tunnel services
docker-compose.immuta.yml     overlay that turns on Immuta access control
.env.example                  pinned versions, ports and memory limits
trino/etc/config.properties   single-node coordinator configuration
trino/etc/catalog/iceberg.properties   the Iceberg catalog definition
sql/00_schemas.sql            creates the three schemas
sql/10_finance.sql            finance test data
sql/20_medical.sql            medical test data
sql/30_manufacturing.sql      manufacturing test data
sql/90_counts.sql             row count summary
scripts/                      implementation behind the make targets
immuta/plugin/                where the Immuta plugin jars go (gitignored)
data/                         Iceberg warehouse + catalog state (gitignored)
```

## Troubleshooting

**`make up` fails with a port conflict.** Something already uses 8080 or 8181.
Either free it or change `TRINO_HTTP_PORT` / `ICEBERG_REST_PORT` in `.env`.
`make prereqs` reports this before you start. Shell environment variables win
over `.env`, so `TRINO_HTTP_PORT=18080 make up` works for a one-off.

**Trino keeps dying, or exits with code 137.** That is the kernel OOM-killing
it. Your Docker VM is too small for `TRINO_MEMORY` plus everything else you are
running. Lower `TRINO_MEMORY` in `.env`, stop other containers, or enlarge the
VM (`colima stop && colima start --cpu 4 --memory 8`). `make prereqs` warns
when the limits only just fit.

**Queries work but the data vanishes after a restart.** Check
`make smoke`, which asserts that Parquet files exist under `./data/warehouse`.
The Iceberg catalog must use `fs.hadoop.enabled=true` for `file://` URIs. Do
not switch it to `fs.native-local.enabled`: that filesystem silently resolves
every `file://` path under a sandbox root inside the container (`/tmp` by
default), so Trino writes the data into the container and loses it on restart
while the catalog service writes metadata to the real bind mount.

**Immuta cannot connect.** Confirm `make tunnel-url` still prints a URL (quick
tunnel hostnames change on every restart) and that `curl .../v1/info` works
through it. Remember the port in Immuta is `443`, not 8080.

**Immuta sees the tables but nothing is masked.** Access control is not
enabled. `make status` tells you which mode you are in; you need both the
plugin jars and the properties file, then `make restart`.

**Trino will not start after installing the plugin.** Almost always a version
mismatch between the plugin and `TRINO_VERSION`. Check
`make logs SERVICE=trino`.

**Running on native Linux rather than macOS.** Docker Desktop and Colima map
bind mount ownership to the container user, but a native Linux host does not.
If Trino or the catalog service report permission errors on `./data`, run
`sudo chown -R 1000:1000 data`.

### Changing the Trino version

The Immuta plugin dictates the Trino version. To change it:

```
# edit TRINO_VERSION in .env, then
make restart
make smoke
```

Iceberg data and catalog state survive the upgrade. Be aware that Trino
occasionally renames configuration properties between releases, so if Trino
fails to start after a large version jump, check
`make logs SERVICE=trino` for rejected properties in
`trino/etc/config.properties` or `trino/etc/catalog/iceberg.properties`.
This lab was built and verified against the version pinned in `.env.example`.
