-- Revision: corrected BIGINT scope identifiers (2026-07-11)
\set ON_ERROR_STOP on

BEGIN;

-- ============================================================
-- 04_identity.sql
-- Realistic multi-company example
--
-- Purpose:
-- Seed application accounts, authentication identities,
-- permissions, access roles, role-permission mappings, and
-- scoped role assignments for the organizations and people
-- created by the previous fixture scripts.
--
-- Notes:
-- - All records are synthetic demonstration data.
-- - This script is safe to run more than once.
-- - Human accounts are derived from internal company roles.
-- - Authentication provider data and password hashes are fake.
-- - The placeholder hashes below must never be used in production.
-- ============================================================

-- ------------------------------------------------------------
-- Prerequisite checks
-- ------------------------------------------------------------

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1
        FROM core.companies
    ) THEN
        RAISE EXCEPTION
            '04_identity.sql requires 02_organizations.sql to be loaded first';
    END IF;

    IF NOT EXISTS (
        SELECT 1
        FROM relationships.person_company_roles
        WHERE role_type IN ('owner', 'employee', 'contractor')
    ) THEN
        RAISE EXCEPTION
            '04_identity.sql requires 03_people_and_relationships.sql to be loaded first';
    END IF;
END
$$;

-- ============================================================
-- Permissions
-- ============================================================

INSERT INTO identity.permissions (
    permission_key,
    permission_name,
    permission_description
)
VALUES
    (
        'platform.settings.read',
        'Read platform settings',
        'View global platform configuration and shared settings.'
    ),
    (
        'platform.settings.manage',
        'Manage platform settings',
        'Create or modify global platform configuration.'
    ),
    (
        'platform.identity.manage',
        'Manage platform identity',
        'Administer accounts, roles, and permissions across the platform.'
    ),
    (
        'platform.audit.read',
        'Read platform audit data',
        'View audit information across every company.'
    ),
    (
        'core.companies.read',
        'Read companies',
        'View company master data.'
    ),
    (
        'core.companies.manage',
        'Manage companies',
        'Create or modify company master data.'
    ),
    (
        'core.branches.read',
        'Read branches',
        'View company branches and operating locations.'
    ),
    (
        'core.branches.manage',
        'Manage branches',
        'Create or modify company branches and operating locations.'
    ),
    (
        'core.departments.read',
        'Read departments',
        'View organizational departments and reporting structure.'
    ),
    (
        'core.departments.manage',
        'Manage departments',
        'Create or modify organizational departments.'
    ),
    (
        'people.persons.read',
        'Read people',
        'View person profiles and contact information.'
    ),
    (
        'people.persons.create',
        'Create people',
        'Create person profiles and contact information.'
    ),
    (
        'people.persons.update',
        'Update people',
        'Modify person profiles and contact information.'
    ),
    (
        'people.persons.archive',
        'Archive people',
        'Archive person profiles that are no longer operationally active.'
    ),
    (
        'people.relationships.read',
        'Read people relationships',
        'View company roles, department assignments, reporting lines, and person relationships.'
    ),
    (
        'people.relationships.manage',
        'Manage people relationships',
        'Create or modify company roles, department assignments, reporting lines, and person relationships.'
    ),
    (
        'identity.accounts.read',
        'Read user accounts',
        'View application accounts and authentication identities.'
    ),
    (
        'identity.accounts.manage',
        'Manage user accounts',
        'Create, activate, suspend, disable, or close application accounts.'
    ),
    (
        'identity.roles.read',
        'Read access roles',
        'View roles, permissions, and scoped role assignments.'
    ),
    (
        'identity.roles.manage',
        'Manage access roles',
        'Create roles, grant permissions, and administer scoped role assignments.'
    ),
    (
        'finance.accounts.read',
        'Read financial accounts',
        'View the chart of accounts and account balances.'
    ),
    (
        'finance.accounts.manage',
        'Manage financial accounts',
        'Create or modify chart-of-account records.'
    ),
    (
        'finance.transactions.read',
        'Read financial transactions',
        'View financial transactions and transaction lines.'
    ),
    (
        'finance.transactions.create',
        'Create financial transactions',
        'Create draft financial transactions and transaction lines.'
    ),
    (
        'finance.transactions.post',
        'Post financial transactions',
        'Post validated financial transactions to the ledger.'
    ),
    (
        'finance.transactions.approve',
        'Approve financial transactions',
        'Approve financial transactions that require authorization.'
    ),
    (
        'documents.records.read',
        'Read documents',
        'View document records and current document versions.'
    ),
    (
        'documents.records.create',
        'Create documents',
        'Create document records and upload initial versions.'
    ),
    (
        'documents.records.update',
        'Update documents',
        'Modify document metadata and create new versions.'
    ),
    (
        'documents.records.approve',
        'Approve documents',
        'Approve controlled documents and policy records.'
    ),
    (
        'workflows.definitions.read',
        'Read workflow definitions',
        'View workflow definitions and workflow steps.'
    ),
    (
        'workflows.definitions.manage',
        'Manage workflow definitions',
        'Create or modify workflow definitions and workflow steps.'
    ),
    (
        'workflows.instances.read',
        'Read workflow instances',
        'View workflow instances, tasks, and execution status.'
    ),
    (
        'workflows.instances.start',
        'Start workflow instances',
        'Start workflow instances for supported business entities.'
    ),
    (
        'workflows.tasks.manage',
        'Manage workflow tasks',
        'Assign, complete, reject, or otherwise process workflow tasks.'
    ),
    (
        'analytics.views.read',
        'Read analytics views',
        'Query operational and management analytics views.'
    ),
    (
        'audit.events.read',
        'Read audit events',
        'View company-scoped audit events and activity history.'
    )
ON CONFLICT (permission_key) DO UPDATE
SET
    permission_name = EXCLUDED.permission_name,
    permission_description = EXCLUDED.permission_description;

-- ============================================================
-- Access roles
-- ============================================================

INSERT INTO identity.access_roles (
    role_key,
    role_name,
    role_description,
    role_scope,
    is_system_role,
    is_active
)
VALUES
    (
        'platform_admin',
        'Platform Administrator',
        'Full administrative access across the complete platform.',
        'platform',
        TRUE,
        TRUE
    ),
    (
        'platform_auditor',
        'Platform Auditor',
        'Cross-company read access for governance, risk, and audit review.',
        'platform',
        TRUE,
        TRUE
    ),
    (
        'company_admin',
        'Company Administrator',
        'Administrative access within one company.',
        'company',
        TRUE,
        TRUE
    ),
    (
        'company_finance_manager',
        'Company Finance Manager',
        'Company-wide finance administration and transaction authority.',
        'company',
        TRUE,
        TRUE
    ),
    (
        'company_people_manager',
        'Company People Manager',
        'Company-wide people and organizational relationship administration.',
        'company',
        TRUE,
        TRUE
    ),
    (
        'company_operations_manager',
        'Company Operations Manager',
        'Company-wide operational coordination across branches and departments.',
        'company',
        TRUE,
        TRUE
    ),
    (
        'company_analyst',
        'Company Analyst',
        'Company-wide read access to operational data and analytics.',
        'company',
        TRUE,
        TRUE
    ),
    (
        'company_read_only',
        'Company Read Only',
        'Broad company-scoped read access without modification privileges.',
        'company',
        TRUE,
        TRUE
    ),
    (
        'service_integration',
        'Service Integration',
        'Non-human integration access for controlled automated processes.',
        'company',
        TRUE,
        TRUE
    ),
    (
        'branch_manager',
        'Branch Manager',
        'Operational management access within one branch.',
        'branch',
        TRUE,
        TRUE
    ),
    (
        'branch_operator',
        'Branch Operator',
        'Day-to-day operational access within one branch.',
        'branch',
        TRUE,
        TRUE
    ),
    (
        'department_manager',
        'Department Manager',
        'Management and approval access within one department.',
        'department',
        TRUE,
        TRUE
    ),
    (
        'department_member',
        'Department Member',
        'Standard operational access within one department.',
        'department',
        TRUE,
        TRUE
    )
ON CONFLICT (role_key) DO UPDATE
SET
    role_name = EXCLUDED.role_name,
    role_description = EXCLUDED.role_description,
    role_scope = EXCLUDED.role_scope,
    is_system_role = EXCLUDED.is_system_role,
    is_active = EXCLUDED.is_active,
    updated_at = now();

-- ============================================================
-- Role-permission mappings
-- ============================================================

-- Platform administrators receive every permission in the fixture.

INSERT INTO identity.role_permissions (
    role_id,
    permission_id
)
SELECT
    r.role_id,
    p.permission_id
FROM identity.access_roles AS r
CROSS JOIN identity.permissions AS p
WHERE r.role_key = 'platform_admin'
ON CONFLICT DO NOTHING;

-- All other roles receive explicit least-privilege permission sets.

WITH role_permission_pairs (
    role_key,
    permission_key
) AS (
    VALUES
        -- Platform auditor
        ('platform_auditor', 'platform.settings.read'),
        ('platform_auditor', 'platform.audit.read'),
        ('platform_auditor', 'core.companies.read'),
        ('platform_auditor', 'core.branches.read'),
        ('platform_auditor', 'core.departments.read'),
        ('platform_auditor', 'people.persons.read'),
        ('platform_auditor', 'people.relationships.read'),
        ('platform_auditor', 'identity.accounts.read'),
        ('platform_auditor', 'identity.roles.read'),
        ('platform_auditor', 'finance.accounts.read'),
        ('platform_auditor', 'finance.transactions.read'),
        ('platform_auditor', 'documents.records.read'),
        ('platform_auditor', 'workflows.definitions.read'),
        ('platform_auditor', 'workflows.instances.read'),
        ('platform_auditor', 'analytics.views.read'),
        ('platform_auditor', 'audit.events.read'),

        -- Company administrator
        ('company_admin', 'core.companies.read'),
        ('company_admin', 'core.companies.manage'),
        ('company_admin', 'core.branches.read'),
        ('company_admin', 'core.branches.manage'),
        ('company_admin', 'core.departments.read'),
        ('company_admin', 'core.departments.manage'),
        ('company_admin', 'people.persons.read'),
        ('company_admin', 'people.persons.create'),
        ('company_admin', 'people.persons.update'),
        ('company_admin', 'people.persons.archive'),
        ('company_admin', 'people.relationships.read'),
        ('company_admin', 'people.relationships.manage'),
        ('company_admin', 'identity.accounts.read'),
        ('company_admin', 'identity.accounts.manage'),
        ('company_admin', 'identity.roles.read'),
        ('company_admin', 'identity.roles.manage'),
        ('company_admin', 'finance.accounts.read'),
        ('company_admin', 'finance.accounts.manage'),
        ('company_admin', 'finance.transactions.read'),
        ('company_admin', 'finance.transactions.create'),
        ('company_admin', 'finance.transactions.post'),
        ('company_admin', 'finance.transactions.approve'),
        ('company_admin', 'documents.records.read'),
        ('company_admin', 'documents.records.create'),
        ('company_admin', 'documents.records.update'),
        ('company_admin', 'documents.records.approve'),
        ('company_admin', 'workflows.definitions.read'),
        ('company_admin', 'workflows.definitions.manage'),
        ('company_admin', 'workflows.instances.read'),
        ('company_admin', 'workflows.instances.start'),
        ('company_admin', 'workflows.tasks.manage'),
        ('company_admin', 'analytics.views.read'),
        ('company_admin', 'audit.events.read'),

        -- Company finance manager
        ('company_finance_manager', 'core.companies.read'),
        ('company_finance_manager', 'core.branches.read'),
        ('company_finance_manager', 'core.departments.read'),
        ('company_finance_manager', 'people.persons.read'),
        ('company_finance_manager', 'people.relationships.read'),
        ('company_finance_manager', 'finance.accounts.read'),
        ('company_finance_manager', 'finance.accounts.manage'),
        ('company_finance_manager', 'finance.transactions.read'),
        ('company_finance_manager', 'finance.transactions.create'),
        ('company_finance_manager', 'finance.transactions.post'),
        ('company_finance_manager', 'finance.transactions.approve'),
        ('company_finance_manager', 'documents.records.read'),
        ('company_finance_manager', 'documents.records.create'),
        ('company_finance_manager', 'documents.records.update'),
        ('company_finance_manager', 'workflows.definitions.read'),
        ('company_finance_manager', 'workflows.instances.read'),
        ('company_finance_manager', 'workflows.instances.start'),
        ('company_finance_manager', 'workflows.tasks.manage'),
        ('company_finance_manager', 'analytics.views.read'),
        ('company_finance_manager', 'audit.events.read'),

        -- Company people manager
        ('company_people_manager', 'core.companies.read'),
        ('company_people_manager', 'core.branches.read'),
        ('company_people_manager', 'core.departments.read'),
        ('company_people_manager', 'core.departments.manage'),
        ('company_people_manager', 'people.persons.read'),
        ('company_people_manager', 'people.persons.create'),
        ('company_people_manager', 'people.persons.update'),
        ('company_people_manager', 'people.persons.archive'),
        ('company_people_manager', 'people.relationships.read'),
        ('company_people_manager', 'people.relationships.manage'),
        ('company_people_manager', 'identity.accounts.read'),
        ('company_people_manager', 'documents.records.read'),
        ('company_people_manager', 'documents.records.create'),
        ('company_people_manager', 'documents.records.update'),
        ('company_people_manager', 'workflows.definitions.read'),
        ('company_people_manager', 'workflows.instances.read'),
        ('company_people_manager', 'workflows.instances.start'),
        ('company_people_manager', 'workflows.tasks.manage'),
        ('company_people_manager', 'analytics.views.read'),
        ('company_people_manager', 'audit.events.read'),

        -- Company operations manager
        ('company_operations_manager', 'core.companies.read'),
        ('company_operations_manager', 'core.branches.read'),
        ('company_operations_manager', 'core.branches.manage'),
        ('company_operations_manager', 'core.departments.read'),
        ('company_operations_manager', 'core.departments.manage'),
        ('company_operations_manager', 'people.persons.read'),
        ('company_operations_manager', 'people.relationships.read'),
        ('company_operations_manager', 'finance.accounts.read'),
        ('company_operations_manager', 'finance.transactions.read'),
        ('company_operations_manager', 'finance.transactions.create'),
        ('company_operations_manager', 'documents.records.read'),
        ('company_operations_manager', 'documents.records.create'),
        ('company_operations_manager', 'documents.records.update'),
        ('company_operations_manager', 'workflows.definitions.read'),
        ('company_operations_manager', 'workflows.instances.read'),
        ('company_operations_manager', 'workflows.instances.start'),
        ('company_operations_manager', 'workflows.tasks.manage'),
        ('company_operations_manager', 'analytics.views.read'),

        -- Company analyst
        ('company_analyst', 'core.companies.read'),
        ('company_analyst', 'core.branches.read'),
        ('company_analyst', 'core.departments.read'),
        ('company_analyst', 'people.persons.read'),
        ('company_analyst', 'people.relationships.read'),
        ('company_analyst', 'finance.accounts.read'),
        ('company_analyst', 'finance.transactions.read'),
        ('company_analyst', 'documents.records.read'),
        ('company_analyst', 'workflows.definitions.read'),
        ('company_analyst', 'workflows.instances.read'),
        ('company_analyst', 'analytics.views.read'),

        -- Company read only
        ('company_read_only', 'core.companies.read'),
        ('company_read_only', 'core.branches.read'),
        ('company_read_only', 'core.departments.read'),
        ('company_read_only', 'people.persons.read'),
        ('company_read_only', 'people.relationships.read'),
        ('company_read_only', 'finance.accounts.read'),
        ('company_read_only', 'finance.transactions.read'),
        ('company_read_only', 'documents.records.read'),
        ('company_read_only', 'workflows.definitions.read'),
        ('company_read_only', 'workflows.instances.read'),
        ('company_read_only', 'analytics.views.read'),

        -- Service integration
        ('service_integration', 'core.companies.read'),
        ('service_integration', 'core.branches.read'),
        ('service_integration', 'core.departments.read'),
        ('service_integration', 'people.persons.read'),
        ('service_integration', 'finance.accounts.read'),
        ('service_integration', 'finance.transactions.read'),
        ('service_integration', 'finance.transactions.create'),
        ('service_integration', 'documents.records.read'),
        ('service_integration', 'documents.records.create'),
        ('service_integration', 'workflows.definitions.read'),
        ('service_integration', 'workflows.instances.read'),
        ('service_integration', 'workflows.instances.start'),

        -- Branch manager
        ('branch_manager', 'core.branches.read'),
        ('branch_manager', 'core.branches.manage'),
        ('branch_manager', 'core.departments.read'),
        ('branch_manager', 'core.departments.manage'),
        ('branch_manager', 'people.persons.read'),
        ('branch_manager', 'people.relationships.read'),
        ('branch_manager', 'finance.accounts.read'),
        ('branch_manager', 'finance.transactions.read'),
        ('branch_manager', 'finance.transactions.create'),
        ('branch_manager', 'documents.records.read'),
        ('branch_manager', 'documents.records.create'),
        ('branch_manager', 'documents.records.update'),
        ('branch_manager', 'workflows.definitions.read'),
        ('branch_manager', 'workflows.instances.read'),
        ('branch_manager', 'workflows.instances.start'),
        ('branch_manager', 'workflows.tasks.manage'),
        ('branch_manager', 'analytics.views.read'),

        -- Branch operator
        ('branch_operator', 'core.branches.read'),
        ('branch_operator', 'core.departments.read'),
        ('branch_operator', 'people.persons.read'),
        ('branch_operator', 'finance.accounts.read'),
        ('branch_operator', 'finance.transactions.read'),
        ('branch_operator', 'finance.transactions.create'),
        ('branch_operator', 'documents.records.read'),
        ('branch_operator', 'documents.records.create'),
        ('branch_operator', 'workflows.definitions.read'),
        ('branch_operator', 'workflows.instances.read'),
        ('branch_operator', 'workflows.instances.start'),
        ('branch_operator', 'analytics.views.read'),

        -- Department manager
        ('department_manager', 'core.departments.read'),
        ('department_manager', 'people.persons.read'),
        ('department_manager', 'people.persons.update'),
        ('department_manager', 'people.relationships.read'),
        ('department_manager', 'documents.records.read'),
        ('department_manager', 'documents.records.create'),
        ('department_manager', 'documents.records.update'),
        ('department_manager', 'documents.records.approve'),
        ('department_manager', 'workflows.definitions.read'),
        ('department_manager', 'workflows.instances.read'),
        ('department_manager', 'workflows.instances.start'),
        ('department_manager', 'workflows.tasks.manage'),
        ('department_manager', 'analytics.views.read'),

        -- Department member
        ('department_member', 'core.departments.read'),
        ('department_member', 'people.persons.read'),
        ('department_member', 'documents.records.read'),
        ('department_member', 'documents.records.create'),
        ('department_member', 'workflows.definitions.read'),
        ('department_member', 'workflows.instances.read'),
        ('department_member', 'workflows.instances.start'),
        ('department_member', 'analytics.views.read')
)
INSERT INTO identity.role_permissions (
    role_id,
    permission_id
)
SELECT
    r.role_id,
    p.permission_id
FROM role_permission_pairs AS pair
JOIN identity.access_roles AS r
    ON r.role_key = pair.role_key
JOIN identity.permissions AS p
    ON p.permission_key = pair.permission_key
ON CONFLICT DO NOTHING;

-- ============================================================
-- Human user accounts
-- ============================================================

WITH account_sources AS (
    SELECT
        p.person_id,
        p.company_id,
        c.company_slug,
        p.external_reference,
        COALESCE(
            email.contact_value,
            lower(
                regexp_replace(
                    COALESCE(p.external_reference, 'person-' || p.person_id::TEXT),
                    '[^a-zA-Z0-9]+',
                    '.',
                    'g'
                )
            ) || '@' || c.company_slug || '.example'
        ) AS account_email,
        CASE
            WHEN p.person_status <> 'active' THEN 'disabled'
            WHEN EXISTS (
                SELECT 1
                FROM relationships.person_company_roles AS active_role
                WHERE active_role.person_id = p.person_id
                  AND active_role.company_id = p.company_id
                  AND active_role.role_type IN ('owner', 'employee', 'contractor')
                  AND active_role.status = 'active'
                  AND active_role.valid_to IS NULL
            ) THEN 'active'
            WHEN EXISTS (
                SELECT 1
                FROM relationships.person_company_roles AS suspended_role
                WHERE suspended_role.person_id = p.person_id
                  AND suspended_role.company_id = p.company_id
                  AND suspended_role.role_type IN ('owner', 'employee', 'contractor')
                  AND suspended_role.status = 'suspended'
                  AND suspended_role.valid_to IS NULL
            ) THEN 'suspended'
            ELSE 'disabled'
        END AS account_status
    FROM people.persons AS p
    JOIN core.companies AS c
        ON c.company_id = p.company_id
    LEFT JOIN LATERAL (
        SELECT
            pcm.contact_value
        FROM people.person_contact_methods AS pcm
        WHERE pcm.person_id = p.person_id
          AND pcm.company_id = p.company_id
          AND pcm.contact_type = 'email'
        ORDER BY
            pcm.is_primary DESC,
            pcm.is_verified DESC,
            pcm.contact_method_id
        LIMIT 1
    ) AS email
        ON TRUE
    WHERE EXISTS (
        SELECT 1
        FROM relationships.person_company_roles AS internal_role
        WHERE internal_role.person_id = p.person_id
          AND internal_role.company_id = p.company_id
          AND internal_role.role_type IN ('owner', 'employee', 'contractor')
    )
), prepared_accounts AS (
    SELECT
        person_id,
        account_email,
        regexp_replace(
            lower(
                company_slug
                || '_'
                || COALESCE(external_reference, 'person_' || person_id::TEXT)
            ),
            '[^a-z0-9]+',
            '_',
            'g'
        ) AS username,
        account_status
    FROM account_sources
)
INSERT INTO identity.user_accounts (
    person_id,
    account_email,
    username,
    account_status,
    is_service_account
)
SELECT
    person_id,
    account_email,
    username,
    account_status,
    FALSE
FROM prepared_accounts
ON CONFLICT (person_id) DO UPDATE
SET
    account_email = EXCLUDED.account_email,
    username = EXCLUDED.username,
    account_status = EXCLUDED.account_status,
    is_service_account = FALSE,
    updated_at = now();

-- ============================================================
-- Company integration service accounts
-- ============================================================

INSERT INTO identity.user_accounts (
    person_id,
    account_email,
    username,
    account_status,
    is_service_account
)
SELECT
    NULL::BIGINT,
    'automation@' || c.company_slug || '.example',
    regexp_replace(
        lower('svc_' || c.company_slug || '_automation'),
        '[^a-z0-9]+',
        '_',
        'g'
    ),
    'active',
    TRUE
FROM core.companies AS c
WHERE c.company_status = 'active'
  AND NOT EXISTS (
      SELECT 1
      FROM identity.user_accounts AS existing_account
      WHERE lower(existing_account.account_email)
          = lower('automation@' || c.company_slug || '.example')
  );

-- ============================================================
-- Authentication identities
-- ============================================================

-- Companies rotate among three representative identity-provider
-- strategies: Google Workspace, Microsoft Entra ID, and local
-- authentication. All subjects and hashes are synthetic.

WITH company_providers AS (
    SELECT
        ranked_company.company_id,
        ranked_company.company_slug,
        CASE
            WHEN (ranked_company.company_rank - 1) % 3 = 0
                THEN 'google_workspace'
            WHEN (ranked_company.company_rank - 1) % 3 = 1
                THEN 'microsoft_entra_id'
            ELSE 'local'
        END AS provider
    FROM (
        SELECT
            c.company_id,
            c.company_slug,
            ROW_NUMBER() OVER (ORDER BY c.company_slug) AS company_rank
        FROM core.companies AS c
    ) AS ranked_company
), human_identities AS (
    SELECT
        ua.account_id,
        cp.provider,
        cp.company_slug
            || ':'
            || COALESCE(p.external_reference, p.person_id::TEXT)
            AS provider_subject,
        CASE
            WHEN cp.provider = 'local' THEN
                '$argon2id$v=19$m=65536,t=3,p=1$fixture-only$not-a-real-password-hash'
            ELSE NULL
        END AS password_hash,
        ua.account_email AS provider_email,
        CASE
            WHEN ua.account_status = 'active' THEN
                TIMESTAMPTZ '2026-07-09 15:00:00+00'
            ELSE NULL
        END AS last_authenticated_at
    FROM identity.user_accounts AS ua
    JOIN people.persons AS p
        ON p.person_id = ua.person_id
    JOIN company_providers AS cp
        ON cp.company_id = p.company_id
    WHERE ua.is_service_account = FALSE
)
INSERT INTO identity.authentication_identities (
    account_id,
    provider,
    provider_subject,
    password_hash,
    provider_email,
    last_authenticated_at
)
SELECT
    account_id,
    provider,
    provider_subject,
    password_hash,
    provider_email,
    last_authenticated_at
FROM human_identities
ON CONFLICT (provider, provider_subject) DO UPDATE
SET
    account_id = EXCLUDED.account_id,
    password_hash = EXCLUDED.password_hash,
    provider_email = EXCLUDED.provider_email,
    last_authenticated_at = EXCLUDED.last_authenticated_at;

INSERT INTO identity.authentication_identities (
    account_id,
    provider,
    provider_subject,
    password_hash,
    provider_email,
    last_authenticated_at
)
SELECT
    ua.account_id,
    'local',
    ua.username,
    '$argon2id$v=19$m=65536,t=3,p=1$fixture-only$not-a-real-service-hash',
    ua.account_email,
    TIMESTAMPTZ '2026-07-10 02:00:00+00'
FROM identity.user_accounts AS ua
WHERE ua.is_service_account = TRUE
  AND ua.username LIKE 'svc_%_automation'
  AND ua.account_email LIKE 'automation@%.example'
ON CONFLICT (provider, provider_subject) DO UPDATE
SET
    account_id = EXCLUDED.account_id,
    password_hash = EXCLUDED.password_hash,
    provider_email = EXCLUDED.provider_email,
    last_authenticated_at = EXCLUDED.last_authenticated_at;

-- ============================================================
-- Temporary fixture context
-- ============================================================

-- Current internal accounts: one representative active internal
-- company role per human account.

CREATE TEMP TABLE fixture_current_internal_accounts
ON COMMIT DROP
AS
WITH ranked_roles AS (
    SELECT
        ua.account_id,
        p.person_id,
        p.company_id,
        c.company_slug,
        p.display_name,
        pcr.person_company_role_id,
        pcr.role_type,
        pcr.role_title,
        ROW_NUMBER() OVER (
            PARTITION BY ua.account_id
            ORDER BY
                CASE pcr.role_type
                    WHEN 'owner' THEN 1
                    WHEN 'employee' THEN 2
                    WHEN 'contractor' THEN 3
                    ELSE 4
                END,
                pcr.valid_from DESC,
                pcr.person_company_role_id
        ) AS role_rank
    FROM identity.user_accounts AS ua
    JOIN people.persons AS p
        ON p.person_id = ua.person_id
    JOIN core.companies AS c
        ON c.company_id = p.company_id
    JOIN relationships.person_company_roles AS pcr
        ON pcr.person_id = p.person_id
       AND pcr.company_id = p.company_id
    WHERE ua.account_status = 'active'
      AND ua.is_service_account = FALSE
      AND p.person_status = 'active'
      AND pcr.role_type IN ('owner', 'employee', 'contractor')
      AND pcr.status = 'active'
      AND pcr.valid_to IS NULL
)
SELECT
    account_id,
    person_id,
    company_id,
    company_slug,
    display_name,
    person_company_role_id,
    role_type,
    role_title
FROM ranked_roles
WHERE role_rank = 1;

CREATE UNIQUE INDEX fixture_current_internal_accounts_account_id_uq
    ON fixture_current_internal_accounts (account_id);

-- Current department memberships: one active assignment per
-- account and department.

CREATE TEMP TABLE fixture_current_department_memberships
ON COMMIT DROP
AS
SELECT DISTINCT ON (
    ua.account_id,
    pda.department_id
)
    ua.account_id,
    p.person_id,
    p.company_id,
    pcr.person_company_role_id,
    pcr.role_type,
    pcr.role_title,
    pda.department_id,
    d.department_code,
    d.department_name,
    d.branch_id,
    pda.assignment_type,
    pda.position_title,
    pda.valid_from
FROM identity.user_accounts AS ua
JOIN people.persons AS p
    ON p.person_id = ua.person_id
JOIN relationships.person_company_roles AS pcr
    ON pcr.person_id = p.person_id
   AND pcr.company_id = p.company_id
JOIN relationships.person_department_assignments AS pda
    ON pda.person_company_role_id = pcr.person_company_role_id
   AND pda.company_id = p.company_id
JOIN core.departments AS d
    ON d.department_id = pda.department_id
   AND d.company_id = p.company_id
WHERE ua.account_status = 'active'
  AND ua.is_service_account = FALSE
  AND p.person_status = 'active'
  AND pcr.role_type IN ('owner', 'employee', 'contractor')
  AND pcr.status = 'active'
  AND pcr.valid_to IS NULL
  AND pda.assignment_type IN ('primary', 'secondary', 'temporary')
  AND pda.valid_to IS NULL
  AND d.department_status = 'active'
ORDER BY
    ua.account_id,
    pda.department_id,
    CASE pda.assignment_type
        WHEN 'primary' THEN 1
        WHEN 'secondary' THEN 2
        WHEN 'temporary' THEN 3
        ELSE 4
    END,
    pda.valid_from DESC,
    pda.person_department_assignment_id;

CREATE UNIQUE INDEX fixture_current_department_memberships_uq
    ON fixture_current_department_memberships (
        account_id,
        department_id
    );

-- One company administrator candidate is selected per company.
-- Owners and executive titles are preferred when present.

CREATE TEMP TABLE fixture_company_admin_accounts
ON COMMIT DROP
AS
WITH ranked_candidates AS (
    SELECT
        internal_account.company_id,
        internal_account.account_id,
        internal_account.person_id,
        ROW_NUMBER() OVER (
            PARTITION BY internal_account.company_id
            ORDER BY
                CASE
                    WHEN internal_account.role_type = 'owner' THEN 1
                    WHEN lower(COALESCE(internal_account.role_title, ''))
                        ~ '(chief|director|president|founder|general manager|managing partner|owner)'
                        THEN 2
                    ELSE 3
                END,
                internal_account.account_id
        ) AS candidate_rank
    FROM fixture_current_internal_accounts AS internal_account
)
SELECT
    company_id,
    account_id,
    person_id
FROM ranked_candidates
WHERE candidate_rank = 1;

CREATE UNIQUE INDEX fixture_company_admin_accounts_company_id_uq
    ON fixture_company_admin_accounts (company_id);

CREATE TEMP TABLE fixture_platform_admin_account
ON COMMIT DROP
AS
SELECT
    company_id,
    account_id,
    person_id
FROM fixture_company_admin_accounts
ORDER BY company_id
LIMIT 1;

-- ============================================================
-- Platform-scoped role assignments
-- ============================================================

INSERT INTO identity.account_role_assignments (
    account_id,
    role_id,
    scope_type,
    company_id,
    branch_id,
    department_id,
    assigned_by_account_id,
    assigned_at,
    valid_from
)
SELECT
    platform_admin.account_id,
    role.role_id,
    'platform',
    NULL::BIGINT,
    NULL::BIGINT,
    NULL::BIGINT,
    NULL::BIGINT,
    TIMESTAMPTZ '2026-01-02 09:00:00+00',
    TIMESTAMPTZ '2026-01-02 09:00:00+00'
FROM fixture_platform_admin_account AS platform_admin
JOIN identity.access_roles AS role
    ON role.role_key = 'platform_admin'
ON CONFLICT DO NOTHING;

WITH auditor_candidates AS (
    SELECT DISTINCT
        internal_account.account_id,
        CASE
            WHEN lower(
                concat_ws(
                    ' ',
                    internal_account.role_title,
                    membership.position_title,
                    membership.department_name
                )
            ) ~ '(audit|compliance|risk|finance|accounting|control)'
                THEN 1
            ELSE 2
        END AS candidate_priority
    FROM fixture_current_internal_accounts AS internal_account
    LEFT JOIN fixture_current_department_memberships AS membership
        ON membership.account_id = internal_account.account_id
    WHERE NOT EXISTS (
        SELECT 1
        FROM fixture_platform_admin_account AS platform_admin
        WHERE platform_admin.account_id = internal_account.account_id
    )
), selected_auditor AS (
    SELECT
        account_id
    FROM auditor_candidates
    ORDER BY
        candidate_priority,
        account_id
    LIMIT 1
)
INSERT INTO identity.account_role_assignments (
    account_id,
    role_id,
    scope_type,
    company_id,
    branch_id,
    department_id,
    assigned_by_account_id,
    assigned_at,
    valid_from
)
SELECT
    auditor.account_id,
    role.role_id,
    'platform',
    NULL::BIGINT,
    NULL::BIGINT,
    NULL::BIGINT,
    platform_admin.account_id,
    TIMESTAMPTZ '2026-01-03 09:00:00+00',
    TIMESTAMPTZ '2026-01-03 09:00:00+00'
FROM selected_auditor AS auditor
CROSS JOIN fixture_platform_admin_account AS platform_admin
JOIN identity.access_roles AS role
    ON role.role_key = 'platform_auditor'
ON CONFLICT DO NOTHING;

-- ============================================================
-- Company-scoped role assignments
-- ============================================================

-- One company administrator per company.

INSERT INTO identity.account_role_assignments (
    account_id,
    role_id,
    scope_type,
    company_id,
    branch_id,
    department_id,
    assigned_by_account_id,
    assigned_at,
    valid_from
)
SELECT
    company_admin.account_id,
    role.role_id,
    'company',
    company_admin.company_id,
    NULL::BIGINT,
    NULL::BIGINT,
    platform_admin.account_id,
    TIMESTAMPTZ '2026-01-05 09:00:00+00',
    TIMESTAMPTZ '2026-01-05 09:00:00+00'
FROM fixture_company_admin_accounts AS company_admin
CROSS JOIN fixture_platform_admin_account AS platform_admin
JOIN identity.access_roles AS role
    ON role.role_key = 'company_admin'
ON CONFLICT DO NOTHING;

-- One service-integration role for each active company.

INSERT INTO identity.account_role_assignments (
    account_id,
    role_id,
    scope_type,
    company_id,
    branch_id,
    department_id,
    assigned_by_account_id,
    assigned_at,
    valid_from
)
SELECT
    service_account.account_id,
    role.role_id,
    'company',
    company.company_id,
    NULL::BIGINT,
    NULL::BIGINT,
    company_admin.account_id,
    TIMESTAMPTZ '2026-01-06 08:00:00+00',
    TIMESTAMPTZ '2026-01-06 08:00:00+00'
FROM core.companies AS company
JOIN identity.user_accounts AS service_account
    ON lower(service_account.account_email)
        = lower('automation@' || company.company_slug || '.example')
JOIN fixture_company_admin_accounts AS company_admin
    ON company_admin.company_id = company.company_id
JOIN identity.access_roles AS role
    ON role.role_key = 'service_integration'
WHERE company.company_status = 'active'
ON CONFLICT DO NOTHING;

-- Finance manager: one best-matching finance or accounting
-- leader per company, when the company has such a profile.

WITH ranked_finance_candidates AS (
    SELECT
        membership.company_id,
        membership.account_id,
        ROW_NUMBER() OVER (
            PARTITION BY membership.company_id
            ORDER BY
                CASE
                    WHEN lower(
                        concat_ws(
                            ' ',
                            membership.department_code,
                            membership.department_name,
                            membership.role_title,
                            membership.position_title
                        )
                    ) ~ '(finance|financial|account|treasury|controller|financ|contab|tesorer)'
                        THEN 1
                    ELSE 2
                END,
                CASE
                    WHEN lower(
                        concat_ws(
                            ' ',
                            membership.role_title,
                            membership.position_title
                        )
                    ) ~ '(manager|director|head|lead|chief|supervisor|coordinator|gerente|jefe|lider|coordinador)'
                        THEN 1
                    ELSE 2
                END,
                membership.account_id
        ) AS candidate_rank
    FROM fixture_current_department_memberships AS membership
    WHERE lower(
        concat_ws(
            ' ',
            membership.department_code,
            membership.department_name,
            membership.role_title,
            membership.position_title
        )
    ) ~ '(finance|financial|account|treasury|controller|financ|contab|tesorer)'
)
INSERT INTO identity.account_role_assignments (
    account_id,
    role_id,
    scope_type,
    company_id,
    branch_id,
    department_id,
    assigned_by_account_id,
    assigned_at,
    valid_from
)
SELECT
    candidate.account_id,
    role.role_id,
    'company',
    candidate.company_id,
    NULL::BIGINT,
    NULL::BIGINT,
    company_admin.account_id,
    TIMESTAMPTZ '2026-01-06 09:00:00+00',
    TIMESTAMPTZ '2026-01-06 09:00:00+00'
FROM ranked_finance_candidates AS candidate
JOIN fixture_company_admin_accounts AS company_admin
    ON company_admin.company_id = candidate.company_id
JOIN identity.access_roles AS role
    ON role.role_key = 'company_finance_manager'
WHERE candidate.candidate_rank = 1
ON CONFLICT DO NOTHING;

-- People manager: one best-matching HR, people, or talent
-- leader per company, when the company has such a profile.

WITH ranked_people_candidates AS (
    SELECT
        membership.company_id,
        membership.account_id,
        ROW_NUMBER() OVER (
            PARTITION BY membership.company_id
            ORDER BY
                CASE
                    WHEN lower(
                        concat_ws(
                            ' ',
                            membership.department_code,
                            membership.department_name,
                            membership.role_title,
                            membership.position_title
                        )
                    ) ~ '(human resources|people|talent|personnel|recursos humanos|(^|[^a-z])hr([^a-z]|$))'
                        THEN 1
                    ELSE 2
                END,
                CASE
                    WHEN lower(
                        concat_ws(
                            ' ',
                            membership.role_title,
                            membership.position_title
                        )
                    ) ~ '(manager|director|head|lead|chief|supervisor|coordinator|gerente|jefe|lider|coordinador)'
                        THEN 1
                    ELSE 2
                END,
                membership.account_id
        ) AS candidate_rank
    FROM fixture_current_department_memberships AS membership
    WHERE lower(
        concat_ws(
            ' ',
            membership.department_code,
            membership.department_name,
            membership.role_title,
            membership.position_title
        )
    ) ~ '(human resources|people|talent|personnel|recursos humanos|(^|[^a-z])hr([^a-z]|$))'
)
INSERT INTO identity.account_role_assignments (
    account_id,
    role_id,
    scope_type,
    company_id,
    branch_id,
    department_id,
    assigned_by_account_id,
    assigned_at,
    valid_from
)
SELECT
    candidate.account_id,
    role.role_id,
    'company',
    candidate.company_id,
    NULL::BIGINT,
    NULL::BIGINT,
    company_admin.account_id,
    TIMESTAMPTZ '2026-01-06 09:15:00+00',
    TIMESTAMPTZ '2026-01-06 09:15:00+00'
FROM ranked_people_candidates AS candidate
JOIN fixture_company_admin_accounts AS company_admin
    ON company_admin.company_id = candidate.company_id
JOIN identity.access_roles AS role
    ON role.role_key = 'company_people_manager'
WHERE candidate.candidate_rank = 1
ON CONFLICT DO NOTHING;

-- Operations manager: one best-matching operations, logistics,
-- supply-chain, warehouse, plant, or production leader per company.

WITH ranked_operations_candidates AS (
    SELECT
        membership.company_id,
        membership.account_id,
        ROW_NUMBER() OVER (
            PARTITION BY membership.company_id
            ORDER BY
                CASE
                    WHEN lower(
                        concat_ws(
                            ' ',
                            membership.department_code,
                            membership.department_name,
                            membership.role_title,
                            membership.position_title
                        )
                    ) ~ '(operations|operaciones|logistics|logistica|supply|warehouse|plant|production|manufactur|fulfillment)'
                        THEN 1
                    ELSE 2
                END,
                CASE
                    WHEN lower(
                        concat_ws(
                            ' ',
                            membership.role_title,
                            membership.position_title
                        )
                    ) ~ '(manager|director|head|lead|chief|supervisor|coordinator|gerente|jefe|lider|coordinador)'
                        THEN 1
                    ELSE 2
                END,
                membership.account_id
        ) AS candidate_rank
    FROM fixture_current_department_memberships AS membership
    WHERE lower(
        concat_ws(
            ' ',
            membership.department_code,
            membership.department_name,
            membership.role_title,
            membership.position_title
        )
    ) ~ '(operations|operaciones|logistics|logistica|supply|warehouse|plant|production|manufactur|fulfillment)'
)
INSERT INTO identity.account_role_assignments (
    account_id,
    role_id,
    scope_type,
    company_id,
    branch_id,
    department_id,
    assigned_by_account_id,
    assigned_at,
    valid_from
)
SELECT
    candidate.account_id,
    role.role_id,
    'company',
    candidate.company_id,
    NULL::BIGINT,
    NULL::BIGINT,
    company_admin.account_id,
    TIMESTAMPTZ '2026-01-06 09:30:00+00',
    TIMESTAMPTZ '2026-01-06 09:30:00+00'
FROM ranked_operations_candidates AS candidate
JOIN fixture_company_admin_accounts AS company_admin
    ON company_admin.company_id = candidate.company_id
JOIN identity.access_roles AS role
    ON role.role_key = 'company_operations_manager'
WHERE candidate.candidate_rank = 1
ON CONFLICT DO NOTHING;

-- Analysts receive company-wide read and analytics access.

INSERT INTO identity.account_role_assignments (
    account_id,
    role_id,
    scope_type,
    company_id,
    branch_id,
    department_id,
    assigned_by_account_id,
    assigned_at,
    valid_from
)
SELECT DISTINCT
    membership.account_id,
    role.role_id,
    'company',
    membership.company_id,
    NULL::BIGINT,
    NULL::BIGINT,
    company_admin.account_id,
    TIMESTAMPTZ '2026-01-06 10:00:00+00',
    TIMESTAMPTZ '2026-01-06 10:00:00+00'
FROM fixture_current_department_memberships AS membership
JOIN fixture_company_admin_accounts AS company_admin
    ON company_admin.company_id = membership.company_id
JOIN identity.access_roles AS role
    ON role.role_key = 'company_analyst'
WHERE lower(
    concat_ws(
        ' ',
        membership.department_code,
        membership.department_name,
        membership.role_title,
        membership.position_title
    )
) ~ '(analyst|analytics|data|business intelligence)'
ON CONFLICT DO NOTHING;

-- Active contractors receive broad read-only company access.

INSERT INTO identity.account_role_assignments (
    account_id,
    role_id,
    scope_type,
    company_id,
    branch_id,
    department_id,
    assigned_by_account_id,
    assigned_at,
    valid_from
)
SELECT
    internal_account.account_id,
    role.role_id,
    'company',
    internal_account.company_id,
    NULL::BIGINT,
    NULL::BIGINT,
    company_admin.account_id,
    TIMESTAMPTZ '2026-01-06 10:15:00+00',
    TIMESTAMPTZ '2026-01-06 10:15:00+00'
FROM fixture_current_internal_accounts AS internal_account
JOIN fixture_company_admin_accounts AS company_admin
    ON company_admin.company_id = internal_account.company_id
JOIN identity.access_roles AS role
    ON role.role_key = 'company_read_only'
WHERE internal_account.role_type = 'contractor'
ON CONFLICT DO NOTHING;

-- ============================================================
-- Branch-scoped role assignments
-- ============================================================

-- Select one manager for every staffed active branch. Explicit
-- management titles are preferred; otherwise the first active
-- member provides a deterministic fallback.

WITH ranked_branch_managers AS (
    SELECT
        membership.company_id,
        membership.branch_id,
        membership.account_id,
        ROW_NUMBER() OVER (
            PARTITION BY membership.company_id, membership.branch_id
            ORDER BY
                CASE
                    WHEN lower(
                        concat_ws(
                            ' ',
                            membership.role_title,
                            membership.position_title
                        )
                    ) ~ '(manager|director|head|lead|chief|supervisor|coordinator|gerente|jefe|lider|coordinador)'
                        THEN 1
                    ELSE 2
                END,
                membership.account_id
        ) AS candidate_rank
    FROM fixture_current_department_memberships AS membership
    JOIN core.branches AS branch
        ON branch.branch_id = membership.branch_id
       AND branch.company_id = membership.company_id
    WHERE membership.branch_id IS NOT NULL
      AND branch.branch_status = 'active'
)
INSERT INTO identity.account_role_assignments (
    account_id,
    role_id,
    scope_type,
    company_id,
    branch_id,
    department_id,
    assigned_by_account_id,
    assigned_at,
    valid_from
)
SELECT
    candidate.account_id,
    role.role_id,
    'branch',
    candidate.company_id,
    candidate.branch_id,
    NULL::BIGINT,
    company_admin.account_id,
    TIMESTAMPTZ '2026-01-07 09:00:00+00',
    TIMESTAMPTZ '2026-01-07 09:00:00+00'
FROM ranked_branch_managers AS candidate
JOIN fixture_company_admin_accounts AS company_admin
    ON company_admin.company_id = candidate.company_id
JOIN identity.access_roles AS role
    ON role.role_key = 'branch_manager'
WHERE candidate.candidate_rank = 1
ON CONFLICT DO NOTHING;

-- Remaining branch-based personnel receive branch-operator access.

INSERT INTO identity.account_role_assignments (
    account_id,
    role_id,
    scope_type,
    company_id,
    branch_id,
    department_id,
    assigned_by_account_id,
    assigned_at,
    valid_from
)
SELECT DISTINCT
    membership.account_id,
    role.role_id,
    'branch',
    membership.company_id,
    membership.branch_id,
    NULL::BIGINT,
    company_admin.account_id,
    TIMESTAMPTZ '2026-01-07 09:30:00+00',
    TIMESTAMPTZ '2026-01-07 09:30:00+00'
FROM fixture_current_department_memberships AS membership
JOIN fixture_company_admin_accounts AS company_admin
    ON company_admin.company_id = membership.company_id
JOIN identity.access_roles AS role
    ON role.role_key = 'branch_operator'
WHERE membership.branch_id IS NOT NULL
  AND NOT EXISTS (
      SELECT 1
      FROM identity.account_role_assignments AS manager_assignment
      JOIN identity.access_roles AS manager_role
          ON manager_role.role_id = manager_assignment.role_id
      WHERE manager_assignment.account_id = membership.account_id
        AND manager_assignment.company_id = membership.company_id
        AND manager_assignment.branch_id = membership.branch_id
        AND manager_assignment.scope_type = 'branch'
        AND manager_assignment.revoked_at IS NULL
        AND manager_role.role_key = 'branch_manager'
  )
ON CONFLICT DO NOTHING;

-- ============================================================
-- Department-scoped role assignments
-- ============================================================

-- Select one manager for every staffed active department.

WITH ranked_department_managers AS (
    SELECT
        membership.company_id,
        membership.department_id,
        membership.account_id,
        ROW_NUMBER() OVER (
            PARTITION BY membership.company_id, membership.department_id
            ORDER BY
                CASE
                    WHEN lower(
                        concat_ws(
                            ' ',
                            membership.role_title,
                            membership.position_title
                        )
                    ) ~ '(manager|director|head|lead|chief|supervisor|coordinator|gerente|jefe|lider|coordinador)'
                        THEN 1
                    ELSE 2
                END,
                CASE membership.assignment_type
                    WHEN 'primary' THEN 1
                    WHEN 'secondary' THEN 2
                    WHEN 'temporary' THEN 3
                    ELSE 4
                END,
                membership.account_id
        ) AS candidate_rank
    FROM fixture_current_department_memberships AS membership
)
INSERT INTO identity.account_role_assignments (
    account_id,
    role_id,
    scope_type,
    company_id,
    branch_id,
    department_id,
    assigned_by_account_id,
    assigned_at,
    valid_from
)
SELECT
    candidate.account_id,
    role.role_id,
    'department',
    candidate.company_id,
    NULL::BIGINT,
    candidate.department_id,
    company_admin.account_id,
    TIMESTAMPTZ '2026-01-08 09:00:00+00',
    TIMESTAMPTZ '2026-01-08 09:00:00+00'
FROM ranked_department_managers AS candidate
JOIN fixture_company_admin_accounts AS company_admin
    ON company_admin.company_id = candidate.company_id
JOIN identity.access_roles AS role
    ON role.role_key = 'department_manager'
WHERE candidate.candidate_rank = 1
ON CONFLICT DO NOTHING;

-- Remaining active personnel receive standard department access.

INSERT INTO identity.account_role_assignments (
    account_id,
    role_id,
    scope_type,
    company_id,
    branch_id,
    department_id,
    assigned_by_account_id,
    assigned_at,
    valid_from
)
SELECT DISTINCT
    membership.account_id,
    role.role_id,
    'department',
    membership.company_id,
    NULL::BIGINT,
    membership.department_id,
    company_admin.account_id,
    TIMESTAMPTZ '2026-01-08 09:30:00+00',
    TIMESTAMPTZ '2026-01-08 09:30:00+00'
FROM fixture_current_department_memberships AS membership
JOIN fixture_company_admin_accounts AS company_admin
    ON company_admin.company_id = membership.company_id
JOIN identity.access_roles AS role
    ON role.role_key = 'department_member'
WHERE NOT EXISTS (
    SELECT 1
    FROM identity.account_role_assignments AS manager_assignment
    JOIN identity.access_roles AS manager_role
        ON manager_role.role_id = manager_assignment.role_id
    WHERE manager_assignment.account_id = membership.account_id
      AND manager_assignment.company_id = membership.company_id
      AND manager_assignment.department_id = membership.department_id
      AND manager_assignment.scope_type = 'department'
      AND manager_assignment.revoked_at IS NULL
      AND manager_role.role_key = 'department_manager'
)
ON CONFLICT DO NOTHING;

-- ============================================================
-- Historical revoked access
-- ============================================================

-- When former internal personnel exist, preserve one historical
-- read-only assignment per company to demonstrate access revocation.

WITH ranked_former_accounts AS (
    SELECT
        p.company_id,
        ua.account_id,
        ROW_NUMBER() OVER (
            PARTITION BY p.company_id
            ORDER BY ua.account_id
        ) AS account_rank
    FROM identity.user_accounts AS ua
    JOIN people.persons AS p
        ON p.person_id = ua.person_id
    WHERE ua.account_status IN ('disabled', 'closed')
      AND ua.is_service_account = FALSE
), historical_assignments AS (
    SELECT
        former_account.company_id,
        former_account.account_id,
        company_admin.account_id AS assigned_by_account_id,
        role.role_id
    FROM ranked_former_accounts AS former_account
    JOIN fixture_company_admin_accounts AS company_admin
        ON company_admin.company_id = former_account.company_id
    JOIN identity.access_roles AS role
        ON role.role_key = 'company_read_only'
    WHERE former_account.account_rank = 1
)
INSERT INTO identity.account_role_assignments (
    account_id,
    role_id,
    scope_type,
    company_id,
    branch_id,
    department_id,
    assigned_by_account_id,
    revoked_by_account_id,
    assigned_at,
    revoked_at,
    valid_from,
    valid_until
)
SELECT
    historical.account_id,
    historical.role_id,
    'company',
    historical.company_id,
    NULL::BIGINT,
    NULL::BIGINT,
    historical.assigned_by_account_id,
    historical.assigned_by_account_id,
    TIMESTAMPTZ '2024-01-15 09:00:00+00',
    TIMESTAMPTZ '2025-12-31 18:00:00+00',
    TIMESTAMPTZ '2024-01-15 09:00:00+00',
    TIMESTAMPTZ '2025-12-31 18:00:00+00'
FROM historical_assignments AS historical
WHERE NOT EXISTS (
    SELECT 1
    FROM identity.account_role_assignments AS existing_assignment
    WHERE existing_assignment.account_id = historical.account_id
      AND existing_assignment.role_id = historical.role_id
      AND existing_assignment.scope_type = 'company'
      AND existing_assignment.company_id = historical.company_id
      AND existing_assignment.assigned_at
          = TIMESTAMPTZ '2024-01-15 09:00:00+00'
);

COMMIT;

\echo '04_identity.sql completed'
