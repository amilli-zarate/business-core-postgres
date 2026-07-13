\set ON_ERROR_STOP on
\set QUIET on
\encoding UTF8
\pset pager off

BEGIN;

-- ============================================================
-- validate_fixture.sql
-- Realistic multi-company example
--
-- Purpose:
-- Validate the complete fixture after 01_shared_reference_data.sql
-- through 08_audit.sql have been loaded.
--
-- Validation strategy:
-- - Resolve the six fixture companies through stable slugs.
-- - Check deterministic fixture cardinalities.
-- - Check cross-company ownership and cross-domain references.
-- - Check finance, document, workflow, and audit lifecycles.
-- - Reconcile the analytics views with their operational sources.
-- - Print one compact PASS/FAIL report and fail the psql run when
--   any validation does not pass.
--
-- Notes:
-- - This script is read-only with respect to application schemas.
-- - Temporary tables are used only for validation context/results.
-- - Additional shared reference records are allowed; the validator
--   checks that every canonical fixture key exists.
-- ============================================================

-- ------------------------------------------------------------
-- Prerequisite objects
-- ------------------------------------------------------------

DO $$
DECLARE
    required_relation TEXT;
    missing_relations TEXT[] := ARRAY[]::TEXT[];
BEGIN
    FOREACH required_relation IN ARRAY ARRAY[
        'core.companies',
        'core.branches',
        'core.departments',
        'core.addresses',
        'people.persons',
        'people.person_contact_methods',
        'relationships.person_company_roles',
        'relationships.person_department_assignments',
        'relationships.person_reporting_lines',
        'relationships.person_relationships',
        'identity.user_accounts',
        'identity.authentication_identities',
        'identity.access_roles',
        'identity.permissions',
        'identity.role_permissions',
        'identity.account_role_assignments',
        'finance.currencies',
        'finance.fiscal_periods',
        'finance.cost_centers',
        'finance.accounts',
        'finance.financial_transactions',
        'finance.transaction_lines',
        'documents.document_types',
        'documents.document_records',
        'documents.document_versions',
        'documents.document_links',
        'documents.document_status_history',
        'workflows.workflow_definitions',
        'workflows.workflow_steps',
        'workflows.workflow_transitions',
        'workflows.workflow_instances',
        'workflows.workflow_tasks',
        'workflows.workflow_task_assignments',
        'workflows.workflow_status_history',
        'audit.audit_events',
        'audit.audit_event_changes',
        'analytics.company_structure',
        'analytics.people_directory',
        'analytics.current_person_company_roles',
        'analytics.finance_account_balances',
        'analytics.finance_monthly_summary',
        'analytics.document_register',
        'analytics.workflow_task_backlog',
        'analytics.audit_activity_daily'
    ]::TEXT[]
    LOOP
        IF to_regclass(required_relation) IS NULL THEN
            missing_relations := array_append(
                missing_relations,
                required_relation
            );
        END IF;
    END LOOP;

    IF cardinality(missing_relations) > 0 THEN
        RAISE EXCEPTION
            'validate_fixture.sql is missing required relations/views: %',
            array_to_string(missing_relations, ', ');
    END IF;
END;
$$;

-- ------------------------------------------------------------
-- Validation result collector
-- ------------------------------------------------------------

CREATE TEMP TABLE fixture_validation_results (
    check_order INTEGER PRIMARY KEY,
    section_name TEXT NOT NULL,
    check_name TEXT NOT NULL,
    passed BOOLEAN NOT NULL,
    expected_value TEXT NOT NULL,
    actual_value TEXT NOT NULL
) ON COMMIT DROP;

-- ------------------------------------------------------------
-- Canonical fixture company scope
-- ------------------------------------------------------------

CREATE TEMP TABLE fixture_expected_companies (
    company_slug TEXT PRIMARY KEY,
    expected_status TEXT NOT NULL,
    expected_currency_code CHAR(3) NOT NULL
) ON COMMIT DROP;

INSERT INTO fixture_expected_companies (
    company_slug,
    expected_status,
    expected_currency_code
)
VALUES
    ('solara-retail-mx', 'active', 'MXN'),
    ('cobalto-industrial-mx', 'active', 'MXN'),
    ('bluepeak-advisory-us', 'active', 'USD'),
    ('lumenforge-technologies-us', 'active', 'USD'),
    ('cedarline-logistics-ca', 'active', 'CAD'),
    ('harvest-circle-foods-ca', 'inactive', 'CAD');

CREATE TEMP TABLE fixture_company_scope
ON COMMIT DROP
AS
SELECT
    expected.company_slug,
    expected.expected_status,
    expected.expected_currency_code,
    companies.company_id,
    companies.company_status,
    companies.default_currency_code
FROM fixture_expected_companies AS expected
LEFT JOIN core.companies AS companies
    ON companies.company_slug = expected.company_slug;

CREATE UNIQUE INDEX fixture_company_scope_slug_uq
    ON fixture_company_scope (company_slug);

CREATE UNIQUE INDEX fixture_company_scope_company_id_uq
    ON fixture_company_scope (company_id)
    WHERE company_id IS NOT NULL;

-- ------------------------------------------------------------
-- Canonical shared reference keys
-- ------------------------------------------------------------

CREATE TEMP TABLE fixture_expected_currencies (
    currency_code CHAR(3) PRIMARY KEY
) ON COMMIT DROP;

INSERT INTO fixture_expected_currencies (currency_code)
VALUES
    ('MXN'), ('USD'), ('CAD'), ('EUR'),
    ('GBP'), ('JPY'), ('CNY'), ('BRL'),
    ('COP'), ('CLP'), ('PEN'), ('ARS');

CREATE TEMP TABLE fixture_expected_permissions (
    permission_key TEXT PRIMARY KEY
) ON COMMIT DROP;

INSERT INTO fixture_expected_permissions (permission_key)
VALUES
    ('platform.settings.read'),
    ('platform.settings.manage'),
    ('platform.identity.manage'),
    ('platform.audit.read'),
    ('core.companies.read'),
    ('core.companies.manage'),
    ('core.branches.read'),
    ('core.branches.manage'),
    ('core.departments.read'),
    ('core.departments.manage'),
    ('people.persons.read'),
    ('people.persons.create'),
    ('people.persons.update'),
    ('people.persons.archive'),
    ('people.relationships.read'),
    ('people.relationships.manage'),
    ('identity.accounts.read'),
    ('identity.accounts.manage'),
    ('identity.roles.read'),
    ('identity.roles.manage'),
    ('finance.accounts.read'),
    ('finance.accounts.manage'),
    ('finance.transactions.read'),
    ('finance.transactions.create'),
    ('finance.transactions.post'),
    ('finance.transactions.approve'),
    ('documents.records.read'),
    ('documents.records.create'),
    ('documents.records.update'),
    ('documents.records.approve'),
    ('workflows.definitions.read'),
    ('workflows.definitions.manage'),
    ('workflows.instances.read'),
    ('workflows.instances.start'),
    ('workflows.tasks.manage'),
    ('analytics.views.read'),
    ('audit.events.read');

CREATE TEMP TABLE fixture_expected_roles (
    role_key TEXT PRIMARY KEY
) ON COMMIT DROP;

INSERT INTO fixture_expected_roles (role_key)
VALUES
    ('platform_admin'),
    ('platform_auditor'),
    ('company_admin'),
    ('company_finance_manager'),
    ('company_people_manager'),
    ('company_operations_manager'),
    ('company_analyst'),
    ('company_read_only'),
    ('service_integration'),
    ('branch_manager'),
    ('branch_operator'),
    ('department_manager'),
    ('department_member');

CREATE TEMP TABLE fixture_expected_document_types (
    type_key TEXT PRIMARY KEY
) ON COMMIT DROP;

INSERT INTO fixture_expected_document_types (type_key)
VALUES
    ('general'),
    ('contract'),
    ('policy'),
    ('procedure'),
    ('report'),
    ('invoice'),
    ('receipt'),
    ('tax_document'),
    ('identity_document'),
    ('purchase_order'),
    ('sales_order'),
    ('quotation'),
    ('credit_note'),
    ('financial_statement'),
    ('bank_statement'),
    ('expense_report'),
    ('employment_document'),
    ('supplier_document'),
    ('customer_document'),
    ('meeting_minutes'),
    ('audit_evidence'),
    ('compliance_certificate'),
    ('project_document'),
    ('technical_specification');

-- ------------------------------------------------------------
-- Fixture-owned workflow and audit scopes
-- ------------------------------------------------------------

CREATE TEMP TABLE fixture_workflow_definition_scope
ON COMMIT DROP
AS
SELECT
    definitions.*
FROM workflows.workflow_definitions AS definitions
JOIN fixture_company_scope AS scope
    ON scope.company_id = definitions.company_id
WHERE definitions.version_number = 1
  AND definitions.workflow_key IN (
        'finance.transaction_approval',
        'documents.controlled_document_approval',
        'people.employee_onboarding',
        'operations.exception_resolution'
      );

CREATE UNIQUE INDEX fixture_workflow_definition_scope_id_uq
    ON fixture_workflow_definition_scope (workflow_definition_id);

CREATE TEMP TABLE fixture_workflow_instance_scope
ON COMMIT DROP
AS
SELECT
    instances.*
FROM workflows.workflow_instances AS instances
JOIN fixture_workflow_definition_scope AS definitions
    ON definitions.company_id = instances.company_id
   AND definitions.workflow_definition_id = instances.workflow_definition_id
WHERE instances.metadata::JSONB ->> 'fixture'
    = 'realistic_multi_company';

CREATE UNIQUE INDEX fixture_workflow_instance_scope_id_uq
    ON fixture_workflow_instance_scope (workflow_instance_id);

CREATE TEMP TABLE fixture_workflow_task_scope
ON COMMIT DROP
AS
SELECT
    tasks.*
FROM workflows.workflow_tasks AS tasks
JOIN fixture_workflow_instance_scope AS instances
    ON instances.company_id = tasks.company_id
   AND instances.workflow_instance_id = tasks.workflow_instance_id
   AND instances.workflow_definition_id = tasks.workflow_definition_id
WHERE tasks.metadata::JSONB ->> 'fixture'
    = 'realistic_multi_company';

CREATE UNIQUE INDEX fixture_workflow_task_scope_id_uq
    ON fixture_workflow_task_scope (workflow_task_id);

CREATE TEMP TABLE fixture_workflow_history_scope
ON COMMIT DROP
AS
SELECT
    status_history.*
FROM workflows.workflow_status_history AS status_history
JOIN fixture_workflow_instance_scope AS instances
    ON instances.company_id = status_history.company_id
   AND instances.workflow_instance_id = status_history.workflow_instance_id
   AND instances.workflow_definition_id
        = status_history.workflow_definition_id
WHERE status_history.metadata::JSONB ->> 'fixture'
    = 'realistic_multi_company';

CREATE UNIQUE INDEX fixture_workflow_history_scope_id_uq
    ON fixture_workflow_history_scope (workflow_status_history_id);

CREATE TEMP TABLE fixture_audit_event_scope
ON COMMIT DROP
AS
SELECT
    events.*
FROM audit.audit_events AS events
WHERE events.metadata::JSONB ->> 'fixture'
    = 'realistic_multi_company';

CREATE UNIQUE INDEX fixture_audit_event_scope_id_uq
    ON fixture_audit_event_scope (audit_event_id);

-- ============================================================
-- 1. Shared reference data
-- ============================================================

INSERT INTO fixture_validation_results
SELECT
    100,
    'Shared reference data',
    'Canonical currencies are present',
    COUNT(currencies.currency_code) = 12,
    '12',
    COUNT(currencies.currency_code)::TEXT
FROM fixture_expected_currencies AS expected
LEFT JOIN finance.currencies AS currencies
    ON currencies.currency_code = expected.currency_code;

INSERT INTO fixture_validation_results
SELECT
    110,
    'Shared reference data',
    'Canonical permissions are present',
    COUNT(permissions.permission_id) = 37,
    '37',
    COUNT(permissions.permission_id)::TEXT
FROM fixture_expected_permissions AS expected
LEFT JOIN identity.permissions AS permissions
    ON permissions.permission_key = expected.permission_key;

INSERT INTO fixture_validation_results
SELECT
    120,
    'Shared reference data',
    'Canonical access roles are present',
    COUNT(roles.role_id) = 13,
    '13',
    COUNT(roles.role_id)::TEXT
FROM fixture_expected_roles AS expected
LEFT JOIN identity.access_roles AS roles
    ON roles.role_key = expected.role_key;

INSERT INTO fixture_validation_results
SELECT
    130,
    'Shared reference data',
    'Canonical document types are present',
    COUNT(document_types.document_type_id) = 24,
    '24',
    COUNT(document_types.document_type_id)::TEXT
FROM fixture_expected_document_types AS expected
LEFT JOIN documents.document_types AS document_types
    ON document_types.type_key = expected.type_key;

INSERT INTO fixture_validation_results
SELECT
    140,
    'Shared reference data',
    'Every canonical role has permissions',
    COUNT(*) FILTER (WHERE mapped_permission_count > 0) = 13,
    '13 roles mapped',
    COUNT(*) FILTER (WHERE mapped_permission_count > 0)::TEXT
        || ' roles mapped'
FROM (
    SELECT
        expected.role_key,
        COUNT(role_permissions.permission_id) AS mapped_permission_count
    FROM fixture_expected_roles AS expected
    LEFT JOIN identity.access_roles AS roles
        ON roles.role_key = expected.role_key
    LEFT JOIN identity.role_permissions AS role_permissions
        ON role_permissions.role_id = roles.role_id
    GROUP BY expected.role_key
) AS role_mappings;

INSERT INTO fixture_validation_results
SELECT
    150,
    'Shared reference data',
    'Platform administrator has every canonical permission',
    COUNT(DISTINCT permissions.permission_key) = 37,
    '37',
    COUNT(DISTINCT permissions.permission_key)::TEXT
FROM identity.access_roles AS roles
JOIN identity.role_permissions AS role_permissions
    ON role_permissions.role_id = roles.role_id
JOIN identity.permissions AS permissions
    ON permissions.permission_id = role_permissions.permission_id
JOIN fixture_expected_permissions AS expected
    ON expected.permission_key = permissions.permission_key
WHERE roles.role_key = 'platform_admin';

-- ============================================================
-- 2. Organizations
-- ============================================================

INSERT INTO fixture_validation_results
SELECT
    200,
    'Organizations',
    'Canonical companies are present',
    COUNT(company_id) = 6,
    '6',
    COUNT(company_id)::TEXT
FROM fixture_company_scope;

INSERT INTO fixture_validation_results
SELECT
    210,
    'Organizations',
    'Company status and default currency match the fixture',
    COUNT(*) FILTER (
        WHERE company_id IS NOT NULL
          AND company_status = expected_status
          AND default_currency_code = expected_currency_code
    ) = 6,
    '6 matching companies',
    COUNT(*) FILTER (
        WHERE company_id IS NOT NULL
          AND company_status = expected_status
          AND default_currency_code = expected_currency_code
    )::TEXT || ' matching companies'
FROM fixture_company_scope;

INSERT INTO fixture_validation_results
SELECT
    220,
    'Organizations',
    'Branch count',
    COUNT(*) = 30,
    '30',
    COUNT(*)::TEXT
FROM core.branches AS branches
JOIN fixture_company_scope AS scope
    ON scope.company_id = branches.company_id;

INSERT INTO fixture_validation_results
SELECT
    230,
    'Organizations',
    'Department count',
    COUNT(*) = 98,
    '98',
    COUNT(*)::TEXT
FROM core.departments AS departments
JOIN fixture_company_scope AS scope
    ON scope.company_id = departments.company_id;

INSERT INTO fixture_validation_results
SELECT
    240,
    'Organizations',
    'Address count',
    COUNT(*) = 39,
    '39',
    COUNT(*)::TEXT
FROM core.addresses AS addresses
JOIN fixture_company_scope AS scope
    ON scope.company_id = addresses.company_id;

INSERT INTO fixture_validation_results
SELECT
    250,
    'Organizations',
    'Every company has branches, departments, and addresses',
    COUNT(*) FILTER (
        WHERE branch_count > 0
          AND department_count > 0
          AND address_count > 0
    ) = 6,
    '6 companies',
    COUNT(*) FILTER (
        WHERE branch_count > 0
          AND department_count > 0
          AND address_count > 0
    )::TEXT || ' companies'
FROM (
    SELECT
        scope.company_id,
        (SELECT COUNT(*) FROM core.branches AS b
         WHERE b.company_id = scope.company_id) AS branch_count,
        (SELECT COUNT(*) FROM core.departments AS d
         WHERE d.company_id = scope.company_id) AS department_count,
        (SELECT COUNT(*) FROM core.addresses AS a
         WHERE a.company_id = scope.company_id) AS address_count
    FROM fixture_company_scope AS scope
) AS company_counts;

INSERT INTO fixture_validation_results
WITH RECURSIVE department_walk AS (
    SELECT
        departments.department_id AS origin_department_id,
        departments.parent_department_id AS current_parent_id,
        ARRAY[departments.department_id]::BIGINT[] AS path,
        FALSE AS has_cycle
    FROM core.departments AS departments
    JOIN fixture_company_scope AS scope
        ON scope.company_id = departments.company_id

    UNION ALL

    SELECT
        walk.origin_department_id,
        parent_department.parent_department_id,
        walk.path || parent_department.department_id,
        parent_department.department_id = ANY(walk.path)
    FROM department_walk AS walk
    JOIN core.departments AS parent_department
        ON parent_department.department_id = walk.current_parent_id
    WHERE NOT walk.has_cycle
)
SELECT
    260,
    'Organizations',
    'Department hierarchy is acyclic',
    COUNT(*) FILTER (WHERE has_cycle) = 0,
    '0 cycles',
    COUNT(*) FILTER (WHERE has_cycle)::TEXT || ' cycles'
FROM department_walk;

-- ============================================================
-- 3. People and relationships
-- ============================================================

INSERT INTO fixture_validation_results
SELECT
    300,
    'People and relationships',
    'Person count',
    COUNT(*) = 127,
    '127',
    COUNT(*)::TEXT
FROM people.persons AS persons
JOIN fixture_company_scope AS scope
    ON scope.company_id = persons.company_id;

INSERT INTO fixture_validation_results
SELECT
    310,
    'People and relationships',
    'Contact-method count',
    COUNT(*) = 221,
    '221',
    COUNT(*)::TEXT
FROM people.person_contact_methods AS contacts
JOIN fixture_company_scope AS scope
    ON scope.company_id = contacts.company_id;

INSERT INTO fixture_validation_results
SELECT
    315,
    'People and relationships',
    'Every role-bearing person has a primary email',
    COUNT(*) = 0,
    '0 violations',
    COUNT(*)::TEXT || ' violations'
FROM relationships.person_company_roles AS company_roles
JOIN fixture_company_scope AS scope
    ON scope.company_id = company_roles.company_id
WHERE NOT EXISTS (
    SELECT 1
    FROM people.person_contact_methods AS contacts
    WHERE contacts.company_id = company_roles.company_id
      AND contacts.person_id = company_roles.person_id
      AND contacts.contact_type = 'email'
      AND contacts.is_primary
);

INSERT INTO fixture_validation_results
SELECT
    320,
    'People and relationships',
    'Person-company-role count',
    COUNT(*) = 120,
    '120',
    COUNT(*)::TEXT
FROM relationships.person_company_roles AS company_roles
JOIN fixture_company_scope AS scope
    ON scope.company_id = company_roles.company_id;

INSERT INTO fixture_validation_results
SELECT
    325,
    'People and relationships',
    'Person-department-assignment count',
    COUNT(*) = 114,
    '114',
    COUNT(*)::TEXT
FROM relationships.person_department_assignments AS assignments
JOIN fixture_company_scope AS scope
    ON scope.company_id = assignments.company_id;

INSERT INTO fixture_validation_results
SELECT
    330,
    'People and relationships',
    'Reporting-line count',
    COUNT(*) = 108,
    '108',
    COUNT(*)::TEXT
FROM relationships.person_reporting_lines AS reporting_lines
JOIN fixture_company_scope AS scope
    ON scope.company_id = reporting_lines.company_id;

INSERT INTO fixture_validation_results
SELECT
    340,
    'People and relationships',
    'Person-relationship count',
    COUNT(*) = 31,
    '31',
    COUNT(*)::TEXT
FROM relationships.person_relationships AS person_relationships
JOIN fixture_company_scope AS scope
    ON scope.company_id = person_relationships.company_id;

INSERT INTO fixture_validation_results
SELECT
    350,
    'People and relationships',
    'Reporting lines never connect a person to themself',
    COUNT(*) = 0,
    '0 violations',
    COUNT(*)::TEXT || ' violations'
FROM relationships.person_reporting_lines AS reporting_lines
JOIN fixture_company_scope AS scope
    ON scope.company_id = reporting_lines.company_id
JOIN relationships.person_company_roles AS manager_role
    ON manager_role.company_id = reporting_lines.company_id
   AND manager_role.person_company_role_id = reporting_lines.manager_role_id
JOIN relationships.person_company_roles AS report_role
    ON report_role.company_id = reporting_lines.company_id
   AND report_role.person_company_role_id = reporting_lines.report_role_id
WHERE manager_role.person_id = report_role.person_id;

-- ============================================================
-- 4. Identity and access control
-- ============================================================

INSERT INTO fixture_validation_results
WITH expected_internal_people AS (
    SELECT DISTINCT
        company_roles.person_id
    FROM relationships.person_company_roles AS company_roles
    JOIN fixture_company_scope AS scope
        ON scope.company_id = company_roles.company_id
    WHERE company_roles.role_type IN ('owner', 'employee', 'contractor')
), account_people AS (
    SELECT DISTINCT
        accounts.person_id
    FROM identity.user_accounts AS accounts
    JOIN expected_internal_people AS expected
        ON expected.person_id = accounts.person_id
    WHERE NOT accounts.is_service_account
)
SELECT
    400,
    'Identity and access control',
    'Every internal person has a human account',
    (SELECT COUNT(*) FROM account_people)
        = (SELECT COUNT(*) FROM expected_internal_people),
    (SELECT COUNT(*) FROM expected_internal_people)::TEXT,
    (SELECT COUNT(*) FROM account_people)::TEXT;

INSERT INTO fixture_validation_results
WITH fixture_accounts AS (
    SELECT DISTINCT
        accounts.account_id
    FROM identity.user_accounts AS accounts
    LEFT JOIN people.persons AS persons
        ON persons.person_id = accounts.person_id
    LEFT JOIN fixture_company_scope AS person_scope
        ON person_scope.company_id = persons.company_id
    LEFT JOIN fixture_company_scope AS service_scope
        ON lower(accounts.account_email)
            = lower('automation@' || service_scope.company_slug || '.example')
    WHERE person_scope.company_id IS NOT NULL
       OR service_scope.company_id IS NOT NULL
), identity_counts AS (
    SELECT
        fixture_accounts.account_id,
        COUNT(authentication.authentication_identity_id) AS identity_count
    FROM fixture_accounts
    LEFT JOIN identity.authentication_identities AS authentication
        ON authentication.account_id = fixture_accounts.account_id
    GROUP BY fixture_accounts.account_id
)
SELECT
    410,
    'Identity and access control',
    'Every fixture account has an authentication identity',
    COUNT(*) FILTER (WHERE identity_count = 0) = 0,
    '0 accounts without identity',
    COUNT(*) FILTER (WHERE identity_count = 0)::TEXT
        || ' accounts without identity'
FROM identity_counts;

INSERT INTO fixture_validation_results
SELECT
    420,
    'Identity and access control',
    'Active companies have one automation service account',
    COUNT(accounts.account_id) = 5,
    '5',
    COUNT(accounts.account_id)::TEXT
FROM fixture_company_scope AS scope
LEFT JOIN identity.user_accounts AS accounts
    ON lower(accounts.account_email)
        = lower('automation@' || scope.company_slug || '.example')
   AND accounts.is_service_account
   AND accounts.account_status = 'active'
WHERE scope.expected_status = 'active';

INSERT INTO fixture_validation_results
SELECT
    430,
    'Identity and access control',
    'Active companies have a current company administrator',
    COUNT(DISTINCT assignments.company_id) = 5,
    '5 companies',
    COUNT(DISTINCT assignments.company_id)::TEXT || ' companies'
FROM identity.account_role_assignments AS assignments
JOIN identity.access_roles AS roles
    ON roles.role_id = assignments.role_id
JOIN fixture_company_scope AS scope
    ON scope.company_id = assignments.company_id
WHERE scope.expected_status = 'active'
  AND roles.role_key = 'company_admin'
  AND assignments.scope_type = 'company'
  AND assignments.revoked_at IS NULL;

INSERT INTO fixture_validation_results
SELECT
    440,
    'Identity and access control',
    'Active companies have a current service-integration assignment',
    COUNT(DISTINCT assignments.company_id) = 5,
    '5 companies',
    COUNT(DISTINCT assignments.company_id)::TEXT || ' companies'
FROM identity.account_role_assignments AS assignments
JOIN identity.access_roles AS roles
    ON roles.role_id = assignments.role_id
JOIN identity.user_accounts AS accounts
    ON accounts.account_id = assignments.account_id
JOIN fixture_company_scope AS scope
    ON scope.company_id = assignments.company_id
WHERE scope.expected_status = 'active'
  AND roles.role_key = 'service_integration'
  AND assignments.scope_type = 'company'
  AND assignments.revoked_at IS NULL
  AND accounts.is_service_account;

INSERT INTO fixture_validation_results
SELECT
    450,
    'Identity and access control',
    'Scoped role assignments use branches/departments from their company',
    COUNT(*) = 0,
    '0 violations',
    COUNT(*)::TEXT || ' violations'
FROM identity.account_role_assignments AS assignments
JOIN fixture_company_scope AS scope
    ON scope.company_id = assignments.company_id
LEFT JOIN core.branches AS branches
    ON branches.branch_id = assignments.branch_id
LEFT JOIN core.departments AS departments
    ON departments.department_id = assignments.department_id
WHERE (assignments.branch_id IS NOT NULL
       AND branches.company_id IS DISTINCT FROM assignments.company_id)
   OR (assignments.department_id IS NOT NULL
       AND departments.company_id IS DISTINCT FROM assignments.company_id);

INSERT INTO fixture_validation_results
SELECT
    460,
    'Identity and access control',
    'Current fixture assignments are not attached to closed accounts',
    COUNT(*) = 0,
    '0 violations',
    COUNT(*)::TEXT || ' violations'
FROM identity.account_role_assignments AS assignments
JOIN identity.user_accounts AS accounts
    ON accounts.account_id = assignments.account_id
LEFT JOIN people.persons AS persons
    ON persons.person_id = accounts.person_id
LEFT JOIN fixture_company_scope AS person_scope
    ON person_scope.company_id = persons.company_id
LEFT JOIN fixture_company_scope AS assignment_scope
    ON assignment_scope.company_id = assignments.company_id
WHERE assignments.revoked_at IS NULL
  AND (person_scope.company_id IS NOT NULL
       OR assignment_scope.company_id IS NOT NULL)
  AND accounts.account_status IN ('disabled', 'closed');

-- ============================================================
-- 5. Finance
-- ============================================================

INSERT INTO fixture_validation_results
SELECT
    500,
    'Finance',
    'Fiscal-period count',
    COUNT(*) = 135,
    '135',
    COUNT(*)::TEXT
FROM finance.fiscal_periods AS fiscal_periods
JOIN fixture_company_scope AS scope
    ON scope.company_id = fiscal_periods.company_id;

INSERT INTO fixture_validation_results
SELECT
    510,
    'Finance',
    'Cost-center count',
    COUNT(*) = 63,
    '63',
    COUNT(*)::TEXT
FROM finance.cost_centers AS cost_centers
JOIN fixture_company_scope AS scope
    ON scope.company_id = cost_centers.company_id;

INSERT INTO fixture_validation_results
SELECT
    520,
    'Finance',
    'Chart-of-accounts count',
    COUNT(*) = 210,
    '210',
    COUNT(*)::TEXT
FROM finance.accounts AS accounts
JOIN fixture_company_scope AS scope
    ON scope.company_id = accounts.company_id;

INSERT INTO fixture_validation_results
SELECT
    530,
    'Finance',
    'Financial-transaction count',
    COUNT(*) = 886,
    '886',
    COUNT(*)::TEXT
FROM finance.financial_transactions AS transactions
JOIN fixture_company_scope AS scope
    ON scope.company_id = transactions.company_id
WHERE transactions.source_system = 'realistic_multi_company_fixture';

INSERT INTO fixture_validation_results
WITH status_counts AS (
    SELECT
        COUNT(*) FILTER (WHERE transactions.status = 'draft') AS draft_count,
        COUNT(*) FILTER (WHERE transactions.status = 'posted') AS posted_count,
        COUNT(*) FILTER (WHERE transactions.status = 'voided') AS voided_count
    FROM finance.financial_transactions AS transactions
    JOIN fixture_company_scope AS scope
        ON scope.company_id = transactions.company_id
    WHERE transactions.source_system = 'realistic_multi_company_fixture'
)
SELECT
    540,
    'Finance',
    'Transaction lifecycle distribution',
    draft_count = 5
        AND posted_count = 876
        AND voided_count = 5,
    'draft=5, posted=876, voided=5',
    format(
        'draft=%s, posted=%s, voided=%s',
        draft_count,
        posted_count,
        voided_count
    )
FROM status_counts;

INSERT INTO fixture_validation_results
SELECT
    550,
    'Finance',
    'Transaction-line count',
    COUNT(*) = 1791,
    '1791',
    COUNT(*)::TEXT
FROM finance.transaction_lines AS lines
JOIN finance.financial_transactions AS transactions
    ON transactions.company_id = lines.company_id
   AND transactions.transaction_id = lines.transaction_id
JOIN fixture_company_scope AS scope
    ON scope.company_id = transactions.company_id
WHERE transactions.source_system = 'realistic_multi_company_fixture';

INSERT INTO fixture_validation_results
WITH posted_totals AS (
    SELECT
        transactions.transaction_id,
        COUNT(lines.transaction_line_id) AS line_count,
        COALESCE(SUM(lines.debit_amount), 0) AS total_debit,
        COALESCE(SUM(lines.credit_amount), 0) AS total_credit
    FROM finance.financial_transactions AS transactions
    JOIN fixture_company_scope AS scope
        ON scope.company_id = transactions.company_id
    LEFT JOIN finance.transaction_lines AS lines
        ON lines.company_id = transactions.company_id
       AND lines.transaction_id = transactions.transaction_id
    WHERE transactions.source_system = 'realistic_multi_company_fixture'
      AND transactions.status = 'posted'
    GROUP BY transactions.transaction_id
)
SELECT
    560,
    'Finance',
    'Posted transactions are complete and balanced',
    COUNT(*) FILTER (
        WHERE line_count < 2
           OR total_debit <> total_credit
    ) = 0,
    '0 violations',
    COUNT(*) FILTER (
        WHERE line_count < 2
           OR total_debit <> total_credit
    )::TEXT || ' violations'
FROM posted_totals;

INSERT INTO fixture_validation_results
SELECT
    570,
    'Finance',
    'Transaction lines use postable accounts',
    COUNT(*) = 0,
    '0 violations',
    COUNT(*)::TEXT || ' violations'
FROM finance.transaction_lines AS lines
JOIN finance.financial_transactions AS transactions
    ON transactions.company_id = lines.company_id
   AND transactions.transaction_id = lines.transaction_id
JOIN finance.accounts AS accounts
    ON accounts.company_id = lines.company_id
   AND accounts.account_id = lines.account_id
JOIN fixture_company_scope AS scope
    ON scope.company_id = transactions.company_id
WHERE transactions.source_system = 'realistic_multi_company_fixture'
  AND NOT accounts.is_postable;

INSERT INTO fixture_validation_results
SELECT
    580,
    'Finance',
    'Transaction-line context remains inside the owning company',
    COUNT(*) = 0,
    '0 violations',
    COUNT(*)::TEXT || ' violations'
FROM finance.transaction_lines AS lines
JOIN finance.financial_transactions AS transactions
    ON transactions.company_id = lines.company_id
   AND transactions.transaction_id = lines.transaction_id
JOIN fixture_company_scope AS scope
    ON scope.company_id = transactions.company_id
LEFT JOIN core.branches AS branches
    ON branches.branch_id = lines.branch_id
LEFT JOIN core.departments AS departments
    ON departments.department_id = lines.department_id
LEFT JOIN people.persons AS counterparties
    ON counterparties.person_id = lines.counterparty_person_id
WHERE transactions.source_system = 'realistic_multi_company_fixture'
  AND (
        (lines.branch_id IS NOT NULL
         AND branches.company_id IS DISTINCT FROM lines.company_id)
        OR
        (lines.department_id IS NOT NULL
         AND departments.company_id IS DISTINCT FROM lines.company_id)
        OR
        (lines.counterparty_person_id IS NOT NULL
         AND counterparties.company_id IS DISTINCT FROM lines.company_id)
      );

INSERT INTO fixture_validation_results
SELECT
    590,
    'Finance',
    'Transaction dates fall inside their fiscal periods',
    COUNT(*) = 0,
    '0 violations',
    COUNT(*)::TEXT || ' violations'
FROM finance.financial_transactions AS transactions
JOIN finance.fiscal_periods AS fiscal_periods
    ON fiscal_periods.company_id = transactions.company_id
   AND fiscal_periods.fiscal_period_id = transactions.fiscal_period_id
JOIN fixture_company_scope AS scope
    ON scope.company_id = transactions.company_id
WHERE transactions.source_system = 'realistic_multi_company_fixture'
  AND NOT (
        transactions.transaction_date >= fiscal_periods.start_date
        AND transactions.transaction_date < fiscal_periods.end_date
      );

INSERT INTO fixture_validation_results
SELECT
    600,
    'Finance',
    'Posted and voided transactions have lifecycle timestamps',
    COUNT(*) = 0,
    '0 violations',
    COUNT(*)::TEXT || ' violations'
FROM finance.financial_transactions AS transactions
JOIN fixture_company_scope AS scope
    ON scope.company_id = transactions.company_id
WHERE transactions.source_system = 'realistic_multi_company_fixture'
  AND (
        (transactions.status = 'posted'
         AND transactions.posted_at IS NULL)
        OR
        (transactions.status = 'voided'
         AND transactions.voided_at IS NULL)
      );

INSERT INTO fixture_validation_results
SELECT
    610,
    'Finance',
    'Every company has fixture financial activity',
    COUNT(DISTINCT transactions.company_id) = 6,
    '6 companies',
    COUNT(DISTINCT transactions.company_id)::TEXT || ' companies'
FROM finance.financial_transactions AS transactions
JOIN fixture_company_scope AS scope
    ON scope.company_id = transactions.company_id
WHERE transactions.source_system = 'realistic_multi_company_fixture';

-- ============================================================
-- 6. Documents
-- ============================================================

INSERT INTO fixture_validation_results
SELECT
    700,
    'Documents',
    'Document-record count',
    COUNT(*) = 102,
    '102',
    COUNT(*)::TEXT
FROM documents.document_records AS documents
JOIN fixture_company_scope AS scope
    ON scope.company_id = documents.company_id;

INSERT INTO fixture_validation_results
SELECT
    710,
    'Documents',
    'Document-version count',
    COUNT(*) = 156,
    '156',
    COUNT(*)::TEXT
FROM documents.document_versions AS versions
JOIN documents.document_records AS documents
    ON documents.document_id = versions.document_id
JOIN fixture_company_scope AS scope
    ON scope.company_id = documents.company_id;

INSERT INTO fixture_validation_results
SELECT
    720,
    'Documents',
    'Document-link count',
    COUNT(*) = 426,
    '426',
    COUNT(*)::TEXT
FROM documents.document_links AS links
JOIN fixture_company_scope AS scope
    ON scope.company_id = links.company_id;

INSERT INTO fixture_validation_results
SELECT
    730,
    'Documents',
    'Document-status-history count',
    COUNT(*) = 224,
    '224',
    COUNT(*)::TEXT
FROM documents.document_status_history AS status_history
JOIN documents.document_records AS documents
    ON documents.document_id = status_history.document_id
JOIN fixture_company_scope AS scope
    ON scope.company_id = documents.company_id;

INSERT INTO fixture_validation_results
SELECT
    740,
    'Documents',
    'All document lifecycle states are represented',
    COUNT(DISTINCT documents.document_status) = 6,
    '6 states',
    COUNT(DISTINCT documents.document_status)::TEXT || ' states'
FROM documents.document_records AS documents
JOIN fixture_company_scope AS scope
    ON scope.company_id = documents.company_id;

INSERT INTO fixture_validation_results
WITH current_version_counts AS (
    SELECT
        documents.document_id,
        COUNT(*) FILTER (WHERE versions.is_current) AS current_count
    FROM documents.document_records AS documents
    JOIN fixture_company_scope AS scope
        ON scope.company_id = documents.company_id
    LEFT JOIN documents.document_versions AS versions
        ON versions.document_id = documents.document_id
    GROUP BY documents.document_id
)
SELECT
    750,
    'Documents',
    'Every document has exactly one current version',
    COUNT(*) FILTER (WHERE current_count <> 1) = 0,
    '0 violations',
    COUNT(*) FILTER (WHERE current_count <> 1)::TEXT || ' violations'
FROM current_version_counts;

INSERT INTO fixture_validation_results
WITH version_integrity AS (
    SELECT
        documents.document_id,
        MIN(versions.version_number) AS minimum_version,
        MAX(versions.version_number) AS maximum_version,
        COUNT(*) AS version_count,
        MAX(versions.version_number) FILTER (
            WHERE versions.is_current
        ) AS current_version
    FROM documents.document_records AS documents
    JOIN fixture_company_scope AS scope
        ON scope.company_id = documents.company_id
    JOIN documents.document_versions AS versions
        ON versions.document_id = documents.document_id
    GROUP BY documents.document_id
)
SELECT
    760,
    'Documents',
    'Version sequences are gapless and current points to the maximum',
    COUNT(*) FILTER (
        WHERE minimum_version <> 1
           OR maximum_version <> version_count
           OR current_version IS DISTINCT FROM maximum_version
    ) = 0,
    '0 violations',
    COUNT(*) FILTER (
        WHERE minimum_version <> 1
           OR maximum_version <> version_count
           OR current_version IS DISTINCT FROM maximum_version
    )::TEXT || ' violations'
FROM version_integrity;

INSERT INTO fixture_validation_results
WITH ordered_history AS (
    SELECT
        documents.document_id,
        documents.document_status,
        status_history.previous_status,
        status_history.new_status,
        ROW_NUMBER() OVER (
            PARTITION BY documents.document_id
            ORDER BY
                status_history.changed_at,
                status_history.document_status_history_id
        ) AS history_position,
        LAG(status_history.new_status) OVER (
            PARTITION BY documents.document_id
            ORDER BY
                status_history.changed_at,
                status_history.document_status_history_id
        ) AS preceding_new_status,
        LAST_VALUE(status_history.new_status) OVER (
            PARTITION BY documents.document_id
            ORDER BY
                status_history.changed_at,
                status_history.document_status_history_id
            ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING
        ) AS final_history_status
    FROM documents.document_records AS documents
    JOIN fixture_company_scope AS scope
        ON scope.company_id = documents.company_id
    JOIN documents.document_status_history AS status_history
        ON status_history.document_id = documents.document_id
), violations AS (
    SELECT DISTINCT
        document_id
    FROM ordered_history
    WHERE (history_position = 1 AND previous_status IS NOT NULL)
       OR (history_position > 1
           AND previous_status IS DISTINCT FROM preceding_new_status)
       OR final_history_status IS DISTINCT FROM document_status
)
SELECT
    770,
    'Documents',
    'Status histories are continuous and end at current status',
    COUNT(*) = 0,
    '0 violations',
    COUNT(*)::TEXT || ' violations'
FROM violations;

INSERT INTO fixture_validation_results
SELECT
    780,
    'Documents',
    'Every document has its owning-company link',
    COUNT(*) FILTER (WHERE NOT has_owner_link) = 0,
    '0 missing links',
    COUNT(*) FILTER (WHERE NOT has_owner_link)::TEXT || ' missing links'
FROM (
    SELECT
        documents.document_id,
        EXISTS (
            SELECT 1
            FROM documents.document_links AS links
            WHERE links.document_id = documents.document_id
              AND links.company_id = documents.company_id
              AND links.linked_entity_schema = 'core'
              AND links.linked_entity_table = 'companies'
              AND links.linked_entity_id = documents.company_id
              AND links.link_type = 'owner'
        ) AS has_owner_link
    FROM documents.document_records AS documents
    JOIN fixture_company_scope AS scope
        ON scope.company_id = documents.company_id
) AS owner_links;

INSERT INTO fixture_validation_results
SELECT
    790,
    'Documents',
    'Expiration-required document types have expiration dates',
    COUNT(*) = 0,
    '0 violations',
    COUNT(*)::TEXT || ' violations'
FROM documents.document_records AS documents
JOIN documents.document_types AS document_types
    ON document_types.document_type_id = documents.document_type_id
JOIN fixture_company_scope AS scope
    ON scope.company_id = documents.company_id
WHERE document_types.requires_expiration_date
  AND documents.expiration_date IS NULL;

INSERT INTO fixture_validation_results
SELECT
    800,
    'Documents',
    'Document owners and human creators belong to the owning company',
    COUNT(*) = 0,
    '0 violations',
    COUNT(*)::TEXT || ' violations'
FROM documents.document_records AS documents
JOIN fixture_company_scope AS scope
    ON scope.company_id = documents.company_id
LEFT JOIN people.persons AS owners
    ON owners.person_id = documents.owner_person_id
LEFT JOIN identity.user_accounts AS creator_accounts
    ON creator_accounts.account_id = documents.created_by_account_id
LEFT JOIN people.persons AS creator_people
    ON creator_people.person_id = creator_accounts.person_id
WHERE (documents.owner_person_id IS NOT NULL
       AND owners.company_id IS DISTINCT FROM documents.company_id)
   OR (creator_people.person_id IS NOT NULL
       AND creator_people.company_id IS DISTINCT FROM documents.company_id);

INSERT INTO fixture_validation_results
SELECT
    810,
    'Documents',
    'Document links resolve to supported records in the same company',
    COUNT(*) = 0,
    '0 violations',
    COUNT(*)::TEXT || ' violations'
FROM documents.document_links AS links
JOIN fixture_company_scope AS scope
    ON scope.company_id = links.company_id
WHERE
    CASE
        WHEN links.linked_entity_schema = 'core'
         AND links.linked_entity_table = 'companies'
        THEN NOT EXISTS (
            SELECT 1
            FROM core.companies AS companies
            WHERE companies.company_id = links.linked_entity_id
              AND companies.company_id = links.company_id
        )

        WHEN links.linked_entity_schema = 'core'
         AND links.linked_entity_table = 'branches'
        THEN NOT EXISTS (
            SELECT 1
            FROM core.branches AS branches
            WHERE branches.branch_id = links.linked_entity_id
              AND branches.company_id = links.company_id
        )

        WHEN links.linked_entity_schema = 'core'
         AND links.linked_entity_table = 'departments'
        THEN NOT EXISTS (
            SELECT 1
            FROM core.departments AS departments
            WHERE departments.department_id = links.linked_entity_id
              AND departments.company_id = links.company_id
        )

        WHEN links.linked_entity_schema = 'people'
         AND links.linked_entity_table = 'persons'
        THEN NOT EXISTS (
            SELECT 1
            FROM people.persons AS persons
            WHERE persons.person_id = links.linked_entity_id
              AND persons.company_id = links.company_id
        )

        WHEN links.linked_entity_schema = 'finance'
         AND links.linked_entity_table = 'financial_transactions'
        THEN NOT EXISTS (
            SELECT 1
            FROM finance.financial_transactions AS transactions
            WHERE transactions.transaction_id = links.linked_entity_id
              AND transactions.company_id = links.company_id
        )

        ELSE TRUE
    END;

-- ============================================================
-- 7. Workflows
-- ============================================================

INSERT INTO fixture_validation_results
SELECT
    900,
    'Workflows',
    'Workflow-definition count',
    COUNT(*) = 24,
    '24',
    COUNT(*)::TEXT
FROM fixture_workflow_definition_scope AS definitions;

INSERT INTO fixture_validation_results
SELECT
    910,
    'Workflows',
    'Every company has four workflow definitions',
    COUNT(*) FILTER (WHERE definition_count = 4) = 6,
    '6 companies',
    COUNT(*) FILTER (WHERE definition_count = 4)::TEXT || ' companies'
FROM (
    SELECT
        scope.company_id,
        COUNT(definitions.workflow_definition_id) AS definition_count
    FROM fixture_company_scope AS scope
    LEFT JOIN fixture_workflow_definition_scope AS definitions
        ON definitions.company_id = scope.company_id
    GROUP BY scope.company_id
) AS company_definitions;

INSERT INTO fixture_validation_results
SELECT
    920,
    'Workflows',
    'Workflow-step count',
    COUNT(*) = 138,
    '138',
    COUNT(*)::TEXT
FROM workflows.workflow_steps AS steps
JOIN fixture_workflow_definition_scope AS definitions
    ON definitions.workflow_definition_id = steps.workflow_definition_id;

INSERT INTO fixture_validation_results
SELECT
    930,
    'Workflows',
    'Workflow-transition count',
    COUNT(*) = 186,
    '186',
    COUNT(*)::TEXT
FROM workflows.workflow_transitions AS transitions
JOIN fixture_workflow_definition_scope AS definitions
    ON definitions.workflow_definition_id = transitions.workflow_definition_id;

INSERT INTO fixture_validation_results
SELECT
    940,
    'Workflows',
    'Workflow-instance count',
    COUNT(*) = 39,
    '39',
    COUNT(*)::TEXT
FROM fixture_workflow_instance_scope AS instances;

INSERT INTO fixture_validation_results
SELECT
    950,
    'Workflows',
    'Workflow-task count',
    COUNT(*) = 108,
    '108',
    COUNT(*)::TEXT
FROM fixture_workflow_task_scope AS tasks;

INSERT INTO fixture_validation_results
SELECT
    960,
    'Workflows',
    'Workflow-status-history count',
    COUNT(*) = 169,
    '169',
    COUNT(*)::TEXT
FROM fixture_workflow_history_scope AS status_history;

INSERT INTO fixture_validation_results
SELECT
    970,
    'Workflows',
    'All workflow-instance lifecycle states are represented',
    COUNT(DISTINCT instances.status) = 6,
    '6 states',
    COUNT(DISTINCT instances.status)::TEXT || ' states'
FROM fixture_workflow_instance_scope AS instances;

INSERT INTO fixture_validation_results
WITH definition_step_counts AS (
    SELECT
        definitions.workflow_definition_id,
        COUNT(*) FILTER (WHERE steps.step_type = 'start') AS start_count,
        COUNT(*) FILTER (WHERE steps.step_type = 'end') AS end_count
    FROM fixture_workflow_definition_scope AS definitions
    LEFT JOIN workflows.workflow_steps AS steps
        ON steps.workflow_definition_id = definitions.workflow_definition_id
    GROUP BY definitions.workflow_definition_id
)
SELECT
    980,
    'Workflows',
    'Every definition has one start step and at least one end step',
    COUNT(*) FILTER (
        WHERE start_count <> 1
           OR end_count < 1
    ) = 0,
    '0 violations',
    COUNT(*) FILTER (
        WHERE start_count <> 1
           OR end_count < 1
    )::TEXT || ' violations'
FROM definition_step_counts;

INSERT INTO fixture_validation_results
SELECT
    990,
    'Workflows',
    'Workflow instances match definition targets',
    COUNT(*) = 0,
    '0 violations',
    COUNT(*)::TEXT || ' violations'
FROM fixture_workflow_instance_scope AS instances
JOIN fixture_workflow_definition_scope AS definitions
    ON definitions.workflow_definition_id = instances.workflow_definition_id
WHERE definitions.company_id <> instances.company_id
   OR (
        definitions.target_entity_schema IS NOT NULL
        AND (
            instances.subject_entity_schema
                IS DISTINCT FROM definitions.target_entity_schema
            OR instances.subject_entity_table
                IS DISTINCT FROM definitions.target_entity_table
        )
      );

INSERT INTO fixture_validation_results
SELECT
    1000,
    'Workflows',
    'Workflow lifecycle timestamps match terminal states',
    COUNT(*) = 0,
    '0 violations',
    COUNT(*)::TEXT || ' violations'
FROM fixture_workflow_instance_scope AS instances
WHERE (instances.status = 'completed'
       AND instances.completed_at IS NULL)
   OR (instances.status = 'cancelled'
       AND instances.cancelled_at IS NULL)
   OR (instances.status <> 'draft'
       AND instances.started_at IS NULL);

INSERT INTO fixture_validation_results
SELECT
    1010,
    'Workflows',
    'Completed tasks have completion timestamps',
    COUNT(*) = 0,
    '0 violations',
    COUNT(*)::TEXT || ' violations'
FROM fixture_workflow_task_scope AS tasks
WHERE tasks.status = 'completed'
  AND tasks.completed_at IS NULL;

INSERT INTO fixture_validation_results
SELECT
    1020,
    'Workflows',
    'Direct task assignees remain inside the owning company',
    COUNT(*) = 0,
    '0 violations',
    COUNT(*)::TEXT || ' violations'
FROM fixture_workflow_task_scope AS tasks
JOIN identity.user_accounts AS accounts
    ON accounts.account_id = tasks.assigned_to_account_id
JOIN people.persons AS persons
    ON persons.person_id = accounts.person_id
WHERE persons.company_id <> tasks.company_id;

INSERT INTO fixture_validation_results
WITH ordered_history AS (
    SELECT
        instances.workflow_instance_id,
        instances.status AS current_status,
        instances.current_step_id,
        status_history.from_status,
        status_history.to_status,
        status_history.to_step_id,
        ROW_NUMBER() OVER (
            PARTITION BY instances.workflow_instance_id
            ORDER BY
                status_history.changed_at,
                status_history.workflow_status_history_id
        ) AS history_position,
        LAG(status_history.to_status) OVER (
            PARTITION BY instances.workflow_instance_id
            ORDER BY
                status_history.changed_at,
                status_history.workflow_status_history_id
        ) AS preceding_to_status,
        LAST_VALUE(status_history.to_status) OVER (
            PARTITION BY instances.workflow_instance_id
            ORDER BY
                status_history.changed_at,
                status_history.workflow_status_history_id
            ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING
        ) AS final_history_status,
        LAST_VALUE(status_history.to_step_id) OVER (
            PARTITION BY instances.workflow_instance_id
            ORDER BY
                status_history.changed_at,
                status_history.workflow_status_history_id
            ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING
        ) AS final_history_step_id
    FROM fixture_workflow_instance_scope AS instances
    JOIN fixture_workflow_history_scope AS status_history
        ON status_history.company_id = instances.company_id
       AND status_history.workflow_instance_id = instances.workflow_instance_id
       AND status_history.workflow_definition_id
            = instances.workflow_definition_id
), violations AS (
    SELECT DISTINCT
        workflow_instance_id
    FROM ordered_history
    WHERE (history_position = 1 AND from_status IS NOT NULL)
       OR (history_position > 1
           AND from_status IS DISTINCT FROM preceding_to_status)
       OR final_history_status IS DISTINCT FROM current_status
       OR final_history_step_id IS DISTINCT FROM current_step_id
)
SELECT
    1030,
    'Workflows',
    'Status histories are continuous and end at the current state',
    COUNT(*) = 0,
    '0 violations',
    COUNT(*)::TEXT || ' violations'
FROM violations;

INSERT INTO fixture_validation_results
SELECT
    1040,
    'Workflows',
    'Every task has an explicit owner assignment',
    COUNT(*) = 0,
    '0 violations',
    COUNT(*)::TEXT || ' violations'
FROM fixture_workflow_task_scope AS tasks
WHERE NOT EXISTS (
    SELECT 1
    FROM workflows.workflow_task_assignments AS assignments
    WHERE assignments.company_id = tasks.company_id
      AND assignments.workflow_task_id = tasks.workflow_task_id
      AND assignments.assignment_type = 'owner'
      AND assignments.account_id = tasks.assigned_to_account_id
);

INSERT INTO fixture_validation_results
SELECT
    1050,
    'Workflows',
    'Active tasks have their expected candidate-role assignment',
    COUNT(*) = 0,
    '0 violations',
    COUNT(*)::TEXT || ' violations'
FROM fixture_workflow_task_scope AS tasks
WHERE tasks.status IN ('open', 'in_progress', 'blocked')
  AND NOT EXISTS (
      SELECT 1
      FROM workflows.workflow_task_assignments AS assignments
      JOIN identity.access_roles AS roles
          ON roles.role_id = assignments.role_id
      WHERE assignments.company_id = tasks.company_id
        AND assignments.workflow_task_id = tasks.workflow_task_id
        AND assignments.assignment_type = 'candidate'
        AND roles.role_key = (tasks.metadata::JSONB ->> 'candidate_role_key')
  );

INSERT INTO fixture_validation_results
SELECT
    1060,
    'Workflows',
    'Definition active states follow company lifecycle states',
    COUNT(*) = 0,
    '0 violations',
    COUNT(*)::TEXT || ' violations'
FROM fixture_workflow_definition_scope AS definitions
JOIN fixture_company_scope AS scope
    ON scope.company_id = definitions.company_id
WHERE definitions.is_active
        IS DISTINCT FROM (scope.expected_status = 'active');

INSERT INTO fixture_validation_results
SELECT
    1070,
    'Workflows',
    'Workflow task assignments are populated',
    COUNT(*) > 0,
    '> 0',
    COUNT(*)::TEXT
FROM workflows.workflow_task_assignments AS assignments
JOIN fixture_workflow_task_scope AS tasks
    ON tasks.company_id = assignments.company_id
   AND tasks.workflow_task_id = assignments.workflow_task_id;

-- ============================================================
-- 8. Audit
-- ============================================================

INSERT INTO fixture_validation_results
SELECT
    1100,
    'Audit',
    'Audit events are populated',
    COUNT(*) > 0,
    '> 0',
    COUNT(*)::TEXT
FROM fixture_audit_event_scope AS events;

INSERT INTO fixture_validation_results
SELECT
    1110,
    'Audit',
    'Field-level audit changes are populated',
    COUNT(*) > 0,
    '> 0',
    COUNT(*)::TEXT
FROM audit.audit_event_changes AS changes
JOIN fixture_audit_event_scope AS events
    ON events.audit_event_id = changes.audit_event_id;

INSERT INTO fixture_validation_results
WITH expected_categories (action_category) AS (
    VALUES
        ('DATA'),
        ('IDENTITY'),
        ('WORKFLOW'),
        ('FINANCE'),
        ('DOCUMENT'),
        ('SECURITY'),
        ('INTEGRATION'),
        ('SYSTEM')
)
SELECT
    1120,
    'Audit',
    'All audit categories are represented',
    COUNT(DISTINCT events.action_category) = 8,
    '8 categories',
    COUNT(DISTINCT events.action_category)::TEXT || ' categories'
FROM expected_categories AS expected
LEFT JOIN fixture_audit_event_scope AS events
    ON events.action_category = expected.action_category;

INSERT INTO fixture_validation_results
SELECT
    1130,
    'Audit',
    'Audit actor account/person pairs are consistent',
    COUNT(*) = 0,
    '0 violations',
    COUNT(*)::TEXT || ' violations'
FROM fixture_audit_event_scope AS events
JOIN identity.user_accounts AS accounts
    ON accounts.account_id = events.actor_account_id
WHERE accounts.person_id IS DISTINCT FROM events.actor_person_id;

INSERT INTO fixture_validation_results
SELECT
    1140,
    'Audit',
    'Audit workflow/company context is consistent',
    COUNT(*) = 0,
    '0 violations',
    COUNT(*)::TEXT || ' violations'
FROM fixture_audit_event_scope AS events
JOIN workflows.workflow_instances AS instances
    ON instances.workflow_instance_id = events.workflow_instance_id
WHERE events.company_id IS DISTINCT FROM instances.company_id;

INSERT INTO fixture_validation_results
SELECT
    1150,
    'Audit',
    'Audit changes have nonblank fields and distinct values',
    COUNT(*) = 0,
    '0 violations',
    COUNT(*)::TEXT || ' violations'
FROM audit.audit_event_changes AS changes
JOIN fixture_audit_event_scope AS events
    ON events.audit_event_id = changes.audit_event_id
WHERE btrim(changes.field_name) = ''
   OR changes.old_value IS NOT DISTINCT FROM changes.new_value;

INSERT INTO fixture_validation_results
SELECT
    1160,
    'Audit',
    'Every fixture company has audit activity',
    COUNT(DISTINCT events.company_id) = 6,
    '6 companies',
    COUNT(DISTINCT events.company_id)::TEXT || ' companies'
FROM fixture_audit_event_scope AS events
JOIN fixture_company_scope AS scope
    ON scope.company_id = events.company_id;

INSERT INTO fixture_validation_results
SELECT
    1170,
    'Audit',
    'Fixture audit-event keys are present and unique',
    COUNT(*) = 0,
    '0 violations',
    COUNT(*)::TEXT || ' violations'
FROM (
    SELECT
        events.metadata::JSONB ->> 'fixture_event_key' AS fixture_event_key
    FROM fixture_audit_event_scope AS events
    GROUP BY events.metadata::JSONB ->> 'fixture_event_key'
    HAVING COUNT(*) <> 1
        OR events.metadata::JSONB ->> 'fixture_event_key' IS NULL
) AS invalid_keys;

INSERT INTO fixture_validation_results
SELECT
    1180,
    'Audit',
    'Workflow-derived audit events retain workflow context',
    COUNT(*) = 0,
    '0 violations',
    COUNT(*)::TEXT || ' violations'
FROM fixture_audit_event_scope AS events
WHERE events.metadata::JSONB ->> 'event_family' IN (
        'workflow_history',
        'workflow_task_assignment',
        'workflow_task_status'
      )
  AND events.workflow_instance_id IS NULL;

-- ============================================================
-- 9. Analytics reconciliation
-- ============================================================

INSERT INTO fixture_validation_results
SELECT
    1200,
    'Analytics',
    'Company-structure view covers every fixture company',
    COUNT(DISTINCT structure.company_id) = 6,
    '6 companies',
    COUNT(DISTINCT structure.company_id)::TEXT || ' companies'
FROM analytics.company_structure AS structure
JOIN fixture_company_scope AS scope
    ON scope.company_id = structure.company_id;

INSERT INTO fixture_validation_results
SELECT
    1210,
    'Analytics',
    'Company-structure view covers every fixture branch',
    COUNT(DISTINCT structure.branch_id) = 30,
    '30 branches',
    COUNT(DISTINCT structure.branch_id)::TEXT || ' branches'
FROM analytics.company_structure AS structure
JOIN fixture_company_scope AS scope
    ON scope.company_id = structure.company_id;

INSERT INTO fixture_validation_results
SELECT
    1220,
    'Analytics',
    'People-directory row count',
    COUNT(*) = 127,
    '127',
    COUNT(*)::TEXT
FROM analytics.people_directory AS directory
JOIN fixture_company_scope AS scope
    ON scope.company_id = directory.company_id;

INSERT INTO fixture_validation_results
WITH base_count AS (
    SELECT COUNT(*) AS row_count
    FROM relationships.person_company_roles AS company_roles
    JOIN fixture_company_scope AS scope
        ON scope.company_id = company_roles.company_id
    WHERE company_roles.status = 'active'
      AND company_roles.valid_from <= CURRENT_DATE
      AND (
            company_roles.valid_to IS NULL
            OR company_roles.valid_to >= CURRENT_DATE
          )
), view_count AS (
    SELECT COUNT(*) AS row_count
    FROM analytics.current_person_company_roles AS current_roles
    JOIN fixture_company_scope AS scope
        ON scope.company_id = current_roles.company_id
)
SELECT
    1230,
    'Analytics',
    'Current-role view matches its operational source',
    view_count.row_count = base_count.row_count,
    base_count.row_count::TEXT,
    view_count.row_count::TEXT
FROM base_count
CROSS JOIN view_count;

INSERT INTO fixture_validation_results
SELECT
    1240,
    'Analytics',
    'Finance-account-balance row count',
    COUNT(*) = 210,
    '210',
    COUNT(*)::TEXT
FROM analytics.finance_account_balances AS balances
JOIN fixture_company_scope AS scope
    ON scope.company_id = balances.company_id;

INSERT INTO fixture_validation_results
SELECT
    1250,
    'Analytics',
    'Monthly finance summary includes every posted fixture transaction',
    COALESCE(SUM(summary.posted_transactions), 0) = 876,
    '876',
    COALESCE(SUM(summary.posted_transactions), 0)::TEXT
FROM analytics.finance_monthly_summary AS summary
JOIN fixture_company_scope AS scope
    ON scope.company_id = summary.company_id;

INSERT INTO fixture_validation_results
SELECT
    1260,
    'Analytics',
    'Monthly finance summary remains balanced',
    COUNT(*) = 0,
    '0 unbalanced rows',
    COUNT(*)::TEXT || ' unbalanced rows'
FROM analytics.finance_monthly_summary AS summary
JOIN fixture_company_scope AS scope
    ON scope.company_id = summary.company_id
WHERE summary.total_debit <> summary.total_credit
   OR summary.net_amount <> 0;

INSERT INTO fixture_validation_results
SELECT
    1270,
    'Analytics',
    'Document-register row count',
    COUNT(*) = 102,
    '102',
    COUNT(*)::TEXT
FROM analytics.document_register AS document_register
JOIN fixture_company_scope AS scope
    ON scope.company_id = document_register.company_id;

INSERT INTO fixture_validation_results
WITH base_count AS (
    SELECT COUNT(*) AS row_count
    FROM fixture_workflow_task_scope AS tasks
    WHERE tasks.status NOT IN ('completed', 'cancelled')
), view_count AS (
    SELECT COUNT(*) AS row_count
    FROM analytics.workflow_task_backlog AS backlog
    JOIN fixture_workflow_task_scope AS tasks
        ON tasks.company_id = backlog.company_id
       AND tasks.workflow_task_id = backlog.workflow_task_id
)
SELECT
    1280,
    'Analytics',
    'Workflow backlog matches its operational source',
    view_count.row_count = base_count.row_count,
    base_count.row_count::TEXT,
    view_count.row_count::TEXT
FROM base_count
CROSS JOIN view_count;

INSERT INTO fixture_validation_results
WITH base_count AS (
    SELECT COUNT(*) AS row_count
    FROM audit.audit_events
), view_count AS (
    SELECT COALESCE(SUM(event_count), 0) AS row_count
    FROM analytics.audit_activity_daily
)
SELECT
    1290,
    'Analytics',
    'Daily audit activity reconciles to audit events',
    view_count.row_count = base_count.row_count,
    base_count.row_count::TEXT,
    view_count.row_count::TEXT
FROM base_count
CROSS JOIN view_count;

-- ============================================================
-- Validation report and final assertion
-- ============================================================

\unset QUIET
\echo
\echo 'Realistic multi-company fixture validation'
\echo '==========================================='

SELECT
    CASE
        WHEN BOOL_AND(passed) THEN 'PASS'
        ELSE 'FAIL'
    END AS result,
    section_name AS section,
    COUNT(*) FILTER (WHERE passed) AS passed_checks,
    COUNT(*) FILTER (WHERE NOT passed) AS failed_checks,
    COUNT(*) AS total_checks
FROM fixture_validation_results
GROUP BY section_name
ORDER BY MIN(check_order);

\echo
\echo 'Failed checks'
\echo '-------------'

SELECT
    section_name AS section,
    check_name AS validation,
    expected_value AS expected,
    actual_value AS actual
FROM fixture_validation_results
WHERE NOT passed
ORDER BY check_order;

SELECT
    COUNT(*) FILTER (WHERE passed) AS passed_checks,
    COUNT(*) FILTER (WHERE NOT passed) AS failed_checks,
    COUNT(*) AS total_checks
FROM fixture_validation_results;

DO $$
DECLARE
    failed_check_count INTEGER;
    failed_check_names TEXT;
BEGIN
    SELECT
        COUNT(*),
        string_agg(
            section_name || ': ' || check_name,
            E'\n- '
            ORDER BY check_order
        )
    INTO
        failed_check_count,
        failed_check_names
    FROM fixture_validation_results
    WHERE NOT passed;

    IF failed_check_count > 0 THEN
        RAISE EXCEPTION E'Fixture validation failed: % check(s) failed.\n- %',
            failed_check_count,
            failed_check_names;
    END IF;
END;
$$;

COMMIT;

\echo 'validate_fixture.sql completed successfully.'
