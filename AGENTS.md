# Business Core Postgres — Agent Instructions

## Project purpose

`business-core-postgres` is a robust and reproducible PostgreSQL database template for managing the end-to-end data flow of one or more companies.

The project must remain:

* general enough to support different companies and industries;
* scalable in both data volume and organizational complexity;
* practical for real operational scenarios;
* simple to understand, deploy, operate, and extend;
* complete enough to cover common business-data requirements without becoming unnecessarily complex;
* reproducible from a clean PostgreSQL environment.

Prefer the simplest production-suitable design that preserves data integrity, extensibility, and a clear path for future growth.

Do not introduce abstractions, dependencies, schemas, or infrastructure solely for hypothetical future requirements.

---

## Design priorities

When design goals compete, use the following order of priority:

1. Data correctness and integrity
2. Reproducibility
3. Safe and practical deployment
4. Simplicity and maintainability
5. Scalability and performance
6. Extensibility
7. Feature completeness

Avoid both under-design and premature overengineering.

A solution is preferred when it is easy to understand, test, deploy, and operate while still meeting realistic business requirements.

---

## Architectural principles

* PostgreSQL is the authoritative data platform.
* Organize database objects by business domain using PostgreSQL schemas.
* Keep transactional data normalized unless a documented requirement justifies denormalization.
* Use views for read-oriented, analytical, and reporting interfaces.
* Preserve explicit relationships between companies and company-scoped records.
* Do not assume that all data belongs to a single company.
* Prefer declarative database mechanisms such as primary keys, foreign keys, unique constraints, check constraints, and appropriate indexes.
* Enforce important business invariants at the database level whenever PostgreSQL can express them clearly.
* Keep migrations deterministic and reproducible.
* Keep deployment independent from manually executed SQL steps.
* Avoid application-specific assumptions unless they represent a reusable business concept.
* Avoid embedding organization names, customer names, credentials, local paths, or environment-specific values in the database definition.
* Avoid PostgreSQL extensions unless they provide a clear project-wide benefit and their deployment requirements are documented.
* Preserve compatibility with standard PostgreSQL tooling whenever practical.

---

## Database schemas

The current database architecture is organized into the following schemas:

* `core`: companies, organizational structure, locations, and shared business foundations;
* `people`: people and person-related information;
* `relationships`: relationships between people, companies, and other business entities;
* `identity`: user accounts, authentication identities, roles, permissions, and access assignments;
* `finance`: reusable financial data and business-finance structures;
* `documents`: document metadata and relationships between documents and business entities;
* `workflows`: workflow definitions, executions, tasks, and process-related data;
* `analytics`: read-oriented analytical views;
* `audit`: audit records and change history.

Respect existing schema boundaries.

Before adding an object, determine which existing business domain owns it. Create a new schema only when the new domain is clearly distinct and cannot be represented coherently by the current architecture.

Avoid duplicating the same concept across schemas.

---

## Repository structure

The repository has the following top-level structure:

```text
docker/
docs/
examples/
scripts/
sql/
tests/
```

Use each directory according to the following responsibilities.

### `docker/`

Container-related deployment resources belong here.

Examples include:

* Dockerfiles;
* Compose files;
* container initialization configuration;
* container-specific environment templates.

Containerized deployment must remain reproducible and must not depend on undocumented manual configuration.

Do not commit real credentials or secrets.

### `docs/`

Long-form project documentation belongs here.

Examples include:

* architecture documentation;
* schema documentation;
* deployment guides;
* operational procedures;
* design decisions;
* extension guides.

Keep `AGENTS.md` focused on durable working rules. Put detailed explanations and architectural rationale in `docs/`.

### `examples/`

Runnable or illustrative usage examples belong here.

Examples must:

* use generic business scenarios;
* avoid real or sensitive data;
* remain consistent with the current database schema;
* clearly distinguish demonstration data from production configuration.

### `scripts/`

Reusable automation belongs here.

Examples include:

* deployment helpers;
* database initialization utilities;
* backup and restore helpers;
* development utilities;
* maintenance automation.

Scripts must:

* fail clearly when a required command fails;
* avoid hardcoded credentials;
* expose environment-dependent values through arguments or environment variables;
* use safe defaults;
* document destructive behavior.

### `sql/`

Database implementation artifacts belong here.

The SQL directory is the source of the database definition.

Its intended responsibilities include:

```text
sql/
├── migrations/
├── seeds/
├── functions/
└── views/
```

Do not create `sql/tests/`. The top-level `tests/` directory is the single entry point for all repository tests.

#### `sql/migrations/`

Contains the ordered, deployable history of database changes.

Migrations are the canonical mechanism for creating and upgrading the database.

#### `sql/seeds/`

Contains optional reusable development or demonstration data.

When subdivisions are needed, prefer:

```text
sql/seeds/
├── dev/
└── demo/
```

Do not place test fixtures here. Test fixtures belong in `tests/`.

Seed data must never be required for creating the production schema unless that dependency is explicitly documented and represents essential reference data.

#### `sql/functions/`

May contain maintainable source definitions for reusable database functions when separating them improves clarity.

Any function required by a deployed database version must still be introduced or changed through a versioned migration.

#### `sql/views/`

May contain maintainable source definitions for views when separating them improves clarity.

When subdivisions are useful, prefer:

```text
sql/views/
├── analytics/
└── reporting/
```

Any view required by a deployed database version must still be introduced or changed through a versioned migration.

### `tests/`

Contains the complete repository-level database test suite.

This is the single testing entry point.

Do not duplicate tests under `sql/`.

---

## Migration conventions

Migration filenames must follow:

```text
VNNN__descriptive_name.sql
```

Examples:

```text
V001__create_schemas.sql
V002__create_core_tables.sql
V010__create_analytics_views.sql
```

Migration rules:

* Use a three-digit, monotonically increasing version number.
* Use lowercase `snake_case` after the double underscore.
* Create one migration per coherent database change.
* Do not create one migration per table when several tables belong to the same coherent domain change.
* Inspect the migration directory before choosing the next version number.
* Never reuse a migration version.
* Keep migrations deterministic.
* Ensure migrations execute successfully in ascending filename order.
* Prefer schema-qualified object names.
* Keep foreign-key column types exactly compatible with the referenced key types.
* Use explicit constraints for important data invariants.
* Add indexes when they support established joins, foreign keys, filters, or access patterns.
* Do not add indexes speculatively without a plausible access pattern.
* Avoid using `IF NOT EXISTS` merely to conceal schema drift or migration-order errors.
* Avoid destructive schema changes unless the task explicitly requires them.
* When a destructive change is necessary, preserve existing data whenever practical and document the migration behavior.

Treat committed migrations as immutable by default.

Prefer a new migration when changing an already established database version. Modify an existing migration only when the task explicitly establishes that migration history is still unreleased and may safely be corrected.

---

## SQL conventions

Follow the style already used by neighboring SQL files.

Unless an existing convention requires otherwise:

* use uppercase SQL keywords;
* use lowercase `snake_case` for schemas, tables, columns, constraints, indexes, views, and functions;
* use schema-qualified names in migrations and cross-schema queries;
* name objects descriptively;
* avoid unexplained abbreviations;
* avoid ambiguous generic names such as `data`, `value`, or `type` when a domain-specific name is available;
* keep SQL readable rather than excessively compact;
* use comments to explain non-obvious design decisions, not self-evident syntax;
* write explicit column lists in `INSERT` statements;
* avoid relying on implicit column order;
* avoid `SELECT *` in stable views and persistent interfaces;
* make ordering explicit whenever deterministic order is required.

Use:

```sql
BIGINT GENERATED ALWAYS AS IDENTITY
```

for new surrogate primary keys unless an existing domain design explicitly requires another key strategy.

Preserve the established `BIGINT` key strategy across foreign-key relationships.

Use natural keys as unique constraints when they represent genuine business uniqueness, but do not use mutable business values as surrogate replacements without a clear reason.

---

## Transaction and failure behavior

Migration and test execution must fail visibly when an SQL error occurs.

When invoking SQL through `psql`, use:

```bash
--set=ON_ERROR_STOP=1
```

or the equivalent behavior.

Use transactions when they provide atomicity and are compatible with the PostgreSQL operations being executed.

Do not silently ignore failed statements.

Do not convert errors into warnings merely to allow a migration or test suite to continue.

---

## Test database

The disposable test database is:

```text
business_core_test
```

Use this database for destructive rebuild and integration tests.

Never run destructive test operations against a development, staging, or production database.

The default PostgreSQL user for test scripts is:

```text
postgres
```

Scripts must allow the database user to be overridden.

Do not hardcode PostgreSQL passwords.

Use command-line arguments, standard PostgreSQL environment variables, or the local PostgreSQL authentication configuration.

---

## Test suite

The current test suite is ordered as follows:

```text
tests/
├── 00_rebuild_from_scratch.sh
├── 01_schema_smoke_tests.sql
├── 02_constraint_tests.sql
├── 03_seed_minimal_business.sql
├── 04_analytics_view_tests.sql
├── run_all_tests.sh
└── README.md
```

The numeric prefixes define execution order.

### `00_rebuild_from_scratch.sh`

Purpose:

* recreate `business_core_test`;
* apply every migration in order;
* verify that a clean database can be built from the repository alone.

This test does not require a fixture.

It may perform destructive operations only against the explicitly defined disposable test database.

### `01_schema_smoke_tests.sql`

Purpose:

* verify that expected schemas exist;
* verify that essential database objects exist;
* detect incomplete or failed migrations.

This test does not require a fixture.

### `02_constraint_tests.sql`

Purpose:

* verify primary keys;
* verify foreign keys;
* verify unique constraints;
* verify check constraints;
* verify other important database invariants.

This test does not require the complete shared fixture.

It may create only the minimal parent and child records needed by each test. Prefer transaction-local test data and rollback when compatible with the test design.

### `03_seed_minimal_business.sql`

Purpose:

* provide the canonical reusable integration-test fixture;
* create a deterministic minimal-business scenario;
* provide the data required by the analytics tests.

This fixture:

* uses fixed and predictable values;
* is committed intentionally;
* does not roll back;
* does not truncate the database;
* assumes execution against the disposable test database;
* must remain compatible with the current schema;
* must exercise every current analytics view.

Do not move this fixture to `sql/seeds/`.

### `04_analytics_view_tests.sql`

Purpose:

* validate all current analytics views;
* compare their results against deterministic expected values.

This test requires `03_seed_minimal_business.sql` to run first.

When an analytics view changes intentionally, update both the view implementation and its expected test results.

### `run_all_tests.sh`

Purpose:

* execute the complete test suite in numeric order;
* stop when a test fails;
* provide one reproducible entry point for database validation.

The script accepts the PostgreSQL user as an optional first positional argument.

The default is:

```bash
postgres
```

Run the complete suite with:

```bash
bash tests/run_all_tests.sh
```

Run it with another PostgreSQL user using:

```bash
bash tests/run_all_tests.sh <database_user>
```

---

## Testing rules

After modifying database code, run the relevant tests.

Prefer running the complete suite:

```bash
bash tests/run_all_tests.sh
```

At minimum:

* migration changes require the rebuild test and schema smoke tests;
* constraint changes require the constraint tests;
* fixture changes require the analytics tests;
* analytics-view changes require the fixture and analytics-view tests;
* cross-domain or architectural changes require the complete test suite.

Do not report that a change is complete without stating which tests were executed and whether they passed.

If tests cannot be executed, state the exact reason.

Do not claim that unexecuted tests passed.

Keep tests:

* deterministic;
* independent from external services;
* reproducible from a clean database;
* explicit about their prerequisites;
* focused on observable database behavior.

A failing test must produce a nonzero exit status.

---

## Working procedure

Before modifying the repository:

1. Read this file.
2. Inspect `README.md`.
3. Read relevant documentation under `docs/`.
4. Inspect the relevant migrations and tests.
5. Inspect the current Git diff before changing files.
6. Identify existing naming, formatting, and architectural conventions.

While modifying the repository:

* make the smallest coherent change that satisfies the task;
* preserve established architecture unless redesign is explicitly requested;
* do not modify unrelated files;
* avoid broad formatting changes;
* avoid duplicating existing database concepts;
* keep migrations, tests, and documentation synchronized;
* preserve backward compatibility when practical;
* do not introduce real credentials or sensitive data;
* do not assume that an empty directory must be populated.

After modifying the repository:

1. Review the complete diff.
2. Run the relevant tests.
3. Check for unintended changes.
4. Update documentation when behavior, deployment, architecture, or public database interfaces change.
5. Summarize the files changed.
6. Report the commands executed.
7. Report test results and unresolved limitations accurately.

---

## Documentation rules

Update documentation when changing:

* repository structure;
* deployment requirements;
* database architecture;
* schema responsibilities;
* required PostgreSQL versions or extensions;
* migration procedures;
* test procedures;
* public views;
* reusable functions;
* operational behavior.

Keep documentation consistent with executable code.

Do not document planned features as though they already exist.

Clearly label future proposals, incomplete functionality, and optional components.

---

## Safety rules

* Never commit passwords, private keys, connection strings containing credentials, or other secrets.
* Never execute destructive database commands against an unspecified database.
* Never use production-like database names for disposable tests.
* Never drop or recreate a database unless the target is explicitly verified.
* Never modify historical migrations casually.
* Never remove constraints or integrity checks merely to make test data load successfully.
* Never weaken database correctness to avoid fixing an invalid fixture or query.
* Never hide failed tests or migration errors.

---

## Definition of done

A database change is complete when:

* the implementation is coherent with the existing architecture;
* the migration path is deterministic;
* a clean database can be rebuilt when relevant;
* affected constraints and interfaces remain valid;
* relevant tests pass;
* documentation is updated when required;
* no unrelated files were changed;
* no credentials or environment-specific values were introduced;
* the final result remains simple, scalable, reproducible, and practical to deploy.
