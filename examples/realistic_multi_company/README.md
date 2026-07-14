# Realistic Multi-Company Fixture

This directory contains a substantial synthetic dataset designed to demonstrate how **Business Core PostgreSQL** can model the operational core of multiple companies within a single database.

The fixture populates every current business domain in the project and connects them through realistic cross-domain relationships involving organizations, people, identity and access control, finance, documents, workflows, audit trails, and analytics.

All companies, people, identifiers, financial values, documents, credentials, addresses, and operational events are fictional and intended exclusively for demonstration, development, testing, and exploratory analysis.

## Scenario

The fixture models six companies operating across Mexico, the United States, and Canada:

| Company                    | Country       | Business domain                             | Currency | Status   |
| -------------------------- | ------------- | ------------------------------------------- | -------- | -------- |
| Solara Retail Mexico       | Mexico        | Omnichannel retail                          | MXN      | Active   |
| Cobalto Industrial Systems | Mexico        | Industrial manufacturing and distribution   | MXN      | Active   |
| BluePeak Advisory          | United States | Management and transformation consulting    | USD      | Active   |
| LumenForge Technologies    | United States | Enterprise software and technology          | USD      | Active   |
| CedarLine Logistics        | Canada        | Freight and logistics services              | CAD      | Active   |
| Harvest Circle Foods       | Canada        | Food distribution and cold-chain operations | CAD      | Inactive |

The companies differ in organizational structure, operating history, industry, financial activity, document lifecycles, workflow states, and audit scenarios. This provides a more representative demonstration than a minimal seed dataset.

## What the fixture demonstrates

The dataset exercises the complete current database model:

* Multi-company organizational structures with branches, hierarchical departments, and addresses.
* People, contact methods, organizational roles, department assignments, reporting lines, and interpersonal relationships.
* Human and service accounts, authentication identities, permissions, access roles, and company-, branch-, and department-scoped assignments.
* Fiscal periods, hierarchical cost centers, charts of accounts, balanced journal entries, and multiple transaction lifecycle states.
* Versioned documents with classifications, ownership, entity links, lifecycle histories, confidentiality levels, and expiration rules.
* Company-scoped workflow definitions, steps, transitions, runtime instances, tasks, assignments, and execution histories.
* Cross-domain audit events with actor, request, session, client, source-system, and field-level change context.
* Analytics views reconciled against their operational source tables.

The fixture also includes records in a variety of lifecycle states—such as active, inactive, completed, draft, paused, failed, cancelled, archived, and historical—depending on what each domain supports. For example, financial transactions may appear as draft or completed, documents may be active or archived, and workflows may be paused or failed.

## Directory contents

| File                              | Responsibility                                                                                            |
| --------------------------------- | --------------------------------------------------------------------------------------------------------- |
| `01_shared_reference_data.sql`    | Shared currencies, permissions, access roles, role-permission mappings, and document types                |
| `02_organizations.sql`            | Companies, branches, departments, and addresses                                                           |
| `03_people_and_relationships.sql` | People, contact methods, company roles, department assignments, reporting lines, and person relationships |
| `04_identity.sql`                 | User accounts, authentication identities, and scoped role assignments                                     |
| `05_finance.sql`                  | Fiscal periods, cost centers, charts of accounts, financial transactions, and transaction lines           |
| `06_documents.sql`                | Document records, versions, entity links, and status histories                                            |
| `07_workflows.sql`                | Workflow definitions, steps, transitions, instances, tasks, assignments, and workflow histories           |
| `08_audit.sql`                    | Cross-domain audit events and field-level audit changes                                                   |
| `validate_fixture.sql`            | Deterministic integrity, lifecycle, ownership, cardinality, and analytics validation                      |
| `load_fixture.sql`                | Canonical entry point that loads and validates the complete fixture                                       |

The numbered scripts are ordered by dependency. Later domains resolve records created by earlier scripts through stable business keys rather than hard-coded identity values.

## Prerequisites

Before loading the fixture:

1. PostgreSQL must be installed and running.
2. The PostgreSQL command-line tools must be available in `PATH`.
3. The target database must exist.
4. All project migrations must already have been applied to the target database.

The fixture is designed for the current Business Core PostgreSQL schema and should be kept synchronized with future schema changes.

## Quick start

From the repository root, rebuild an example database and apply all migrations:

```bash
bash scripts/rebuild_database.sh postgres example_multi_company
```

> **Warning:** `rebuild_database.sh` drops the target database when it already exists. Do not run it against a database containing data that must be preserved.

Then load the complete fixture:

```bash
psql \
  --username=postgres \
  --dbname=example_multi_company \
  --file=examples/realistic_multi_company/load_fixture.sql
```

The loader automatically:

1. Enables fail-fast execution with `ON_ERROR_STOP`.
2. Uses UTF-8 encoding.
3. Executes scripts `01` through `08` in dependency order.
4. Runs `validate_fixture.sql`.
5. Reports success only when loading and validation both complete successfully.

A successful execution ends with:

```text
SUCCESS: realistic_multi_company fixture loaded and validated in database: example_multi_company
```

Replace `postgres` and `example_multi_company` when using a different PostgreSQL user or database name.

## Validated dataset scale

The validation script verifies deterministic fixture cardinalities and structural invariants. Selected expected values include:

| Dataset                         | Expected records |
| ------------------------------- | ---------------- |
| Companies                       | 6                |
| Branches                        | 30               |
| Departments                     | 98               |
| Addresses                       | 39               |
| People                          | 127              |
| Contact methods                 | 221              |
| Fiscal periods                  | 135              |
| Cost centers                    | 63               |
| Financial accounts              | 210              |
| Financial transactions          | 886              |
| Transaction lines               | 1,791            |
| Document records                | 102              |
| Document versions               | 156              |
| Document links                  | 426              |
| Workflow definitions            | 24               |
| Workflow steps                  | 138              |
| Workflow transitions            | 186              |
| Workflow instances              | 39               |
| Workflow tasks                  | 108              |
| Workflow status-history records | 169              |

Shared reference data also includes canonical currencies, permissions, access roles, role-permission mappings, and document classifications.

These values describe the fixture-owned dataset. The validator allows additional shared reference records while requiring every canonical fixture record to remain present.

## Validation

Validation runs automatically as the final stage of `load_fixture.sql`.

It can also be executed independently:

```bash
psql \
  --username=postgres \
  --dbname=example_multi_company \
  --file=examples/realistic_multi_company/validate_fixture.sql
```

The validator checks:

* Required tables and analytics views.
* Canonical fixture records and deterministic cardinalities.
* Company ownership and tenant isolation.
* Organizational hierarchy integrity.
* People, account, authentication, and role-assignment consistency.
* Balanced financial transactions and valid accounting context.
* Document version sequences, links, lifecycle histories, and ownership.
* Workflow definitions, transitions, runtime state, tasks, assignments, and histories.
* Audit actor, company, workflow, event, and field-change consistency.
* Reconciliation between analytics views and operational source tables.

A compact `PASS` or `FAIL` report is printed by domain.

Any failed validation raises an exception. Because the loader enables `ON_ERROR_STOP`, a validation failure terminates the `psql` execution and prevents the fixture from being reported as successfully loaded.

## Re-running the fixture

The fixture is designed to be rerunnable against a migrated database.

Stable natural keys and explicit conflict handling prevent duplicate reference and master records. Domain datasets owned by the fixture are rebuilt deterministically where necessary so that repeated executions converge to the expected state.

Running the complete loader is preferred over executing individual files manually:

```bash
psql \
  --username=postgres \
  --dbname=example_multi_company \
  --file=examples/realistic_multi_company/load_fixture.sql
```

When executing scripts individually for development or debugging, preserve their numeric order because each domain depends on records created by previous scripts.

## Exploring the loaded data

The analytics schema provides convenient entry points for inspecting the completed fixture:

```sql
SELECT *
FROM analytics.company_structure
LIMIT 25;
```

```sql
SELECT *
FROM analytics.people_directory
LIMIT 25;
```

```sql
SELECT *
FROM analytics.finance_monthly_summary
LIMIT 25;
```

```sql
SELECT *
FROM analytics.document_register
LIMIT 25;
```

```sql
SELECT *
FROM analytics.workflow_task_backlog
LIMIT 25;
```

```sql
SELECT *
FROM analytics.audit_activity_daily
LIMIT 25;
```

These views demonstrate how normalized operational data can be exposed through reporting-oriented read models.

## Data safety and limitations

This fixture is demonstration data and must not be treated as production configuration or authoritative business information.

In particular:

* All organizations and people are fictional.
* Tax identifiers and business identifiers are illustrative placeholders.
* Email addresses use synthetic domains.
* Authentication provider data and password hashes are fake.
* Placeholder password hashes must never be used in a real application.
* Financial values and business activity are synthetic.
* Document storage locations contain metadata only; no document files are included.
* Retention periods are illustrative defaults and are not legal or regulatory guidance.
* Audit events, IP addresses, user agents, sessions, and request metadata are synthetic.
* The fixture is not intended to provide production credentials, regulatory rules, security policy, or accounting guidance.

Use this dataset for development, demonstrations, integration testing, analytics exploration, and evaluation of the Business Core PostgreSQL data model.
