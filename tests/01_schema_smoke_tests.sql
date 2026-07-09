\set ON_ERROR_STOP on


-- ---------------------------------------------------------------------------
-- Verify schemas
-- ---------------------------------------------------------------------------

DO $$
DECLARE
    missing_schemas TEXT[];
BEGIN
    SELECT ARRAY_AGG(schema_name ORDER BY schema_name)
    INTO missing_schemas
    FROM UNNEST(
        ARRAY[
            'core',
            'people',
            'relationships',
            'identity',
            'finance',
            'documents',
            'workflows',
            'audit',
            'analytics'
        ]
    ) AS expected(schema_name)
    WHERE TO_REGNAMESPACE(schema_name) IS NULL;

    IF missing_schemas IS NOT NULL THEN
        RAISE EXCEPTION
            'Missing schemas:%',
            E'\n- ' || ARRAY_TO_STRING(missing_schemas, E'\n- ');
    END IF;
END
$$;


-- ---------------------------------------------------------------------------
-- Verify tables and views
-- ---------------------------------------------------------------------------

DO $$
DECLARE
    relation_problems TEXT[];
BEGIN
    WITH expected_relations (
        relation_name,
        expected_kind
    ) AS (
        VALUES

            -- Core

            ('core.companies', 'r'),
            ('core.branches', 'r'),
            ('core.departments', 'r'),
            ('core.addresses', 'r'),

            -- People

            ('people.persons', 'r'),
            ('people.person_contact_methods', 'r'),

            -- Relationships

            ('relationships.person_company_roles', 'r'),
            ('relationships.person_department_assignments', 'r'),
            ('relationships.person_reporting_lines', 'r'),
            ('relationships.person_relationships', 'r'),

            -- Identity

            ('identity.user_accounts', 'r'),
            ('identity.authentication_identities', 'r'),
            ('identity.access_roles', 'r'),
            ('identity.permissions', 'r'),
            ('identity.role_permissions', 'r'),
            ('identity.account_role_assignments', 'r'),

            -- Finance

            ('finance.currencies', 'r'),
            ('finance.fiscal_periods', 'r'),
            ('finance.cost_centers', 'r'),
            ('finance.accounts', 'r'),
            ('finance.financial_transactions', 'r'),
            ('finance.transaction_lines', 'r'),

            -- Documents

            ('documents.document_types', 'r'),
            ('documents.document_records', 'r'),
            ('documents.document_versions', 'r'),
            ('documents.document_links', 'r'),
            ('documents.document_status_history', 'r'),

            -- Workflows

            ('workflows.workflow_definitions', 'r'),
            ('workflows.workflow_steps', 'r'),
            ('workflows.workflow_transitions', 'r'),
            ('workflows.workflow_instances', 'r'),
            ('workflows.workflow_tasks', 'r'),
            ('workflows.workflow_task_assignments', 'r'),
            ('workflows.workflow_status_history', 'r'),

            -- Audit

            ('audit.audit_events', 'r'),
            ('audit.audit_event_changes', 'r'),

            -- Analytics

            ('analytics.company_structure', 'v'),
            ('analytics.people_directory', 'v'),
            ('analytics.current_person_company_roles', 'v'),
            ('analytics.finance_account_balances', 'v'),
            ('analytics.finance_monthly_summary', 'v'),
            ('analytics.document_register', 'v'),
            ('analytics.workflow_task_backlog', 'v'),
            ('analytics.audit_activity_daily', 'v')
    ),

    problems AS (
        SELECT
            CASE
                WHEN actual.oid IS NULL THEN
                    FORMAT(
                        '%s is missing',
                        expected.relation_name
                    )

                WHEN actual.relkind::TEXT <> expected.expected_kind THEN
                    FORMAT(
                        '%s has relkind %s; expected %s',
                        expected.relation_name,
                        actual.relkind,
                        expected.expected_kind
                    )
            END AS problem

        FROM expected_relations AS expected

        LEFT JOIN pg_catalog.pg_class AS actual
            ON actual.oid = TO_REGCLASS(expected.relation_name)
    )

    SELECT ARRAY_AGG(problem ORDER BY problem)
    INTO relation_problems
    FROM problems
    WHERE problem IS NOT NULL;

    IF relation_problems IS NOT NULL THEN
        RAISE EXCEPTION
            'Schema object problems:%',
            E'\n- ' || ARRAY_TO_STRING(
                relation_problems,
                E'\n- '
            );
    END IF;
END
$$;


\echo '01_schema_smoke_tests.sql passed'