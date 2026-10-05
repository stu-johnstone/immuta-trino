#!/usr/bin/env bash
# Documents the logical Trino test identities and how to map them in Immuta.
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

head1 "Logical Trino test users"
cat <<'TXT'
  These are NOT persisted Trino accounts. This local Trino has no
  authentication configured, so whatever username a client sends is taken as
  the request identity. Immuta applies policy based on that exact string.

  USERNAME                  PURPOSE
  immuta-system             Immuta's own system account: object sync and
                            identification. Keep it separate from the
                            policy-testing users below.
  finance_analyst           Subject of finance policies.
  medical_researcher        Subject of medical policies.
  manufacturing_operator    Subject of manufacturing policies.
  data_admin                Local table owner / seeding identity.
TXT

head1 "Mapping each username to an Immuta user"
cat <<'TXT'
  In Immuta, for each policy-testing user above:
    1. Open People > Users and select (or create) the Immuta user.
    2. Open the user's profile and edit their connected accounts / aliases.
    3. Add a Trino username that matches the string below EXACTLY, including
       underscores and hyphens. Trino identities are case sensitive here.
    4. Save, then confirm under the user's profile that the Trino identity is
       listed.

  Map:
    finance_analyst        -> the Immuta user who should see finance data
    medical_researcher     -> the Immuta user who should see medical data
    manufacturing_operator -> the Immuta user who should see manufacturing data
    data_admin             -> an Immuta user with no special policy exemptions

  Do NOT map immuta-system to a policy-testing user. It is the system account
  configured on the Immuta connection itself and is excluded from policy.
TXT

head1 "Try them"
cat <<'TXT'
  make query USER=finance_analyst        SQL="SELECT * FROM iceberg.finance.customers LIMIT 5"
  make query USER=medical_researcher     SQL="SELECT * FROM iceberg.medical.patients LIMIT 5"
  make query USER=manufacturing_operator SQL="SELECT * FROM iceberg.manufacturing.employees LIMIT 5"
  make query USER=data_admin             SQL="SELECT current_user"
TXT
