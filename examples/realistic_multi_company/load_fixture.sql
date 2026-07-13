\set ON_ERROR_STOP on
\encoding UTF8
\pset pager off

\echo 'Loading realistic_multi_company fixture into database:' :DBNAME

\ir 01_shared_reference_data.sql
\ir 02_organizations.sql
\ir 03_people_and_relationships.sql
\ir 04_identity.sql
\ir 05_finance.sql
\ir 06_documents.sql
\ir 07_workflows.sql
\ir 08_audit.sql

\echo 'Running fixture validation...'

\ir validate_fixture.sql

\echo 'SUCCESS: realistic_multi_company fixture loaded and validated in database:' :DBNAME