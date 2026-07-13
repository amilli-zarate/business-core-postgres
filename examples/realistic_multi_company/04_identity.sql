-- Revision: moved shared RBAC reference data to 01_shared_reference_data.sql (2026-07-12)
\set ON_ERROR_STOP on

BEGIN;

-- ============================================================
-- 04_identity.sql
-- Realistic multi-company example
--
-- Purpose:
-- Seed application accounts, authentication identities, and
-- scoped role assignments for the organizations and people
-- created by the previous fixture scripts.
--
-- Notes:
-- - All records are synthetic demonstration data.
-- - This script is safe to run more than once.
-- - Permissions, access roles, and role-permission mappings are
--   loaded by 01_shared_reference_data.sql.
-- - Human accounts are derived from internal company roles.
-- - Authentication provider data and password hashes are fake.
-- - The placeholder hashes below must never be used in production.
-- ============================================================

-- ------------------------------------------------------------
-- Prerequisite checks
-- ------------------------------------------------------------

DO $$
DECLARE
    missing_role_keys TEXT;
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

    WITH required_roles (role_key) AS (
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
            ('department_member')
    )
    SELECT string_agg(
        required_roles.role_key,
        ', '
        ORDER BY required_roles.role_key
    )
    INTO missing_role_keys
    FROM required_roles
    LEFT JOIN identity.access_roles AS role
        ON role.role_key = required_roles.role_key
    WHERE role.role_id IS NULL;

    IF missing_role_keys IS NOT NULL THEN
        RAISE EXCEPTION
            '04_identity.sql requires 01_shared_reference_data.sql to be loaded first. Missing access roles: %',
            missing_role_keys;
    END IF;
END
$$;

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
