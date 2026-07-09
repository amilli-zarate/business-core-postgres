\set ON_ERROR_STOP on

BEGIN;

-- ============================================================================
-- Helper
-- ============================================================================

CREATE FUNCTION pg_temp.expect_error(
    test_name TEXT,
    expected_sqlstate TEXT,
    sql_statement TEXT
)
RETURNS VOID
LANGUAGE plpgsql
AS $$
DECLARE
    actual_sqlstate TEXT;
    actual_message TEXT;
BEGIN
    BEGIN
        EXECUTE sql_statement;

    EXCEPTION
        WHEN OTHERS THEN
            GET STACKED DIAGNOSTICS
                actual_sqlstate = RETURNED_SQLSTATE,
                actual_message = MESSAGE_TEXT;

            IF actual_sqlstate <> expected_sqlstate THEN
                RAISE EXCEPTION
                    '% failed: expected SQLSTATE %, got %: %',
                    test_name,
                    expected_sqlstate,
                    actual_sqlstate,
                    actual_message;
            END IF;

            RAISE NOTICE 'PASS: %', test_name;

            RETURN;
    END;

    RAISE EXCEPTION
        '% failed: expected SQLSTATE %, but the statement succeeded',
        test_name,
        expected_sqlstate;
END;
$$;


-- ============================================================================
-- Minimal local fixture
-- ============================================================================

INSERT INTO core.companies (
    company_slug,
    company_name
)
VALUES
    (
        'constraint-test-company',
        'Constraint Test Company'
    ),
    (
        'constraint-test-company-2',
        'Constraint Test Company 2'
    );


INSERT INTO core.departments (
    company_id,
    department_code,
    department_name
)
SELECT
    company_id,
    'ROOT',
    'Root Department'
FROM core.companies
WHERE company_slug = 'constraint-test-company';


INSERT INTO people.persons (
    company_id,
    display_name
)
SELECT
    company_id,
    'Constraint Test Person'
FROM core.companies
WHERE company_slug = 'constraint-test-company';


INSERT INTO people.persons (
    company_id,
    display_name
)
SELECT
    company_id,
    'Second Constraint Test Person'
FROM core.companies
WHERE company_slug = 'constraint-test-company';


INSERT INTO people.person_contact_methods (
    company_id,
    person_id,
    contact_type,
    contact_value,
    is_primary
)
SELECT
    company_id,
    person_id,
    'email',
    'primary@example.com',
    TRUE
FROM people.persons
WHERE display_name = 'Constraint Test Person';


INSERT INTO relationships.person_company_roles (
    company_id,
    person_id,
    role_type,
    role_title
)
SELECT
    company_id,
    person_id,
    'employee',
    'Constraint Test Employee'
FROM people.persons
WHERE display_name = 'Constraint Test Person';


INSERT INTO identity.user_accounts (
    person_id,
    account_email,
    username,
    account_status
)
SELECT
    person_id,
    'constraint.user@example.com',
    'constraint_user',
    'active'
FROM people.persons
WHERE display_name = 'Constraint Test Person';


INSERT INTO documents.document_records (
    company_id,
    document_type_id,
    document_title,
    document_number
)
SELECT
    companies.company_id,
    document_types.document_type_id,
    'Constraint Test Document',
    'CT-001'
FROM core.companies
CROSS JOIN documents.document_types
WHERE companies.company_slug = 'constraint-test-company'
  AND document_types.type_key = 'general';


INSERT INTO documents.document_versions (
    document_id,
    version_number,
    storage_uri,
    is_current
)
SELECT
    document_id,
    1,
    'constraint-test/document-v1.pdf',
    TRUE
FROM documents.document_records
WHERE document_number = 'CT-001';


INSERT INTO audit.audit_events (
    action_category,
    action_type,
    company_id,
    event_summary
)
SELECT
    'DATA',
    'UPDATE',
    company_id,
    'Constraint test audit event'
FROM core.companies
WHERE company_slug = 'constraint-test-company';


-- ============================================================================
-- Core constraints
-- ============================================================================

SELECT pg_temp.expect_error(
    'company slug format CHECK',
    '23514',
    $sql$
        INSERT INTO core.companies (
            company_slug,
            company_name
        )
        VALUES (
            'Invalid Slug',
            'Invalid Company'
        )
    $sql$
);


SELECT pg_temp.expect_error(
    'company slug UNIQUE constraint',
    '23505',
    $sql$
        INSERT INTO core.companies (
            company_slug,
            company_name
        )
        VALUES (
            'constraint-test-company',
            'Duplicate Company'
        )
    $sql$
);


SELECT pg_temp.expect_error(
    'department parent must belong to the same company',
    '23503',
    $sql$
        INSERT INTO core.departments (
            company_id,
            parent_department_id,
            department_code,
            department_name
        )
        VALUES (
            (
                SELECT company_id
                FROM core.companies
                WHERE company_slug = 'constraint-test-company-2'
            ),
            (
                SELECT department_id
                FROM core.departments
                WHERE department_code = 'ROOT'
            ),
            'INVALID-PARENT',
            'Invalid Child Department'
        )
    $sql$
);


-- ============================================================================
-- People constraints
-- ============================================================================

SELECT pg_temp.expect_error(
    'person display name NOT NULL constraint',
    '23502',
    $sql$
        INSERT INTO people.persons (
            company_id,
            display_name
        )
        VALUES (
            (
                SELECT company_id
                FROM core.companies
                WHERE company_slug = 'constraint-test-company'
            ),
            NULL
        )
    $sql$
);


SELECT pg_temp.expect_error(
    'person company FOREIGN KEY constraint',
    '23503',
    $sql$
        INSERT INTO people.persons (
            company_id,
            display_name
        )
        VALUES (
            9223372036854775807,
            'Person Without Company'
        )
    $sql$
);


SELECT pg_temp.expect_error(
    'person status CHECK',
    '23514',
    $sql$
        INSERT INTO people.persons (
            company_id,
            display_name,
            person_status
        )
        VALUES (
            (
                SELECT company_id
                FROM core.companies
                WHERE company_slug = 'constraint-test-company'
            ),
            'Invalid Status Person',
            'unknown'
        )
    $sql$
);


SELECT pg_temp.expect_error(
    'email format CHECK',
    '23514',
    $sql$
        INSERT INTO people.person_contact_methods (
            company_id,
            person_id,
            contact_type,
            contact_value
        )
        SELECT
            company_id,
            person_id,
            'email',
            'not-an-email'
        FROM people.persons
        WHERE display_name = 'Constraint Test Person'
    $sql$
);


SELECT pg_temp.expect_error(
    'one primary contact per type',
    '23505',
    $sql$
        INSERT INTO people.person_contact_methods (
            company_id,
            person_id,
            contact_type,
            contact_value,
            is_primary
        )
        SELECT
            company_id,
            person_id,
            'email',
            'another-primary@example.com',
            TRUE
        FROM people.persons
        WHERE display_name = 'Constraint Test Person'
    $sql$
);


-- ============================================================================
-- Relationship constraints
-- ============================================================================

SELECT pg_temp.expect_error(
    'company role validity date CHECK',
    '23514',
    $sql$
        INSERT INTO relationships.person_company_roles (
            company_id,
            person_id,
            role_type,
            valid_from,
            valid_to
        )
        SELECT
            company_id,
            person_id,
            'employee',
            DATE '2026-01-02',
            DATE '2026-01-01'
        FROM people.persons
        WHERE display_name = 'Constraint Test Person'
    $sql$
);


SELECT pg_temp.expect_error(
    'role cannot report to itself',
    '23514',
    $sql$
        INSERT INTO relationships.person_reporting_lines (
            company_id,
            manager_role_id,
            report_role_id,
            reporting_type
        )
        SELECT
            company_id,
            person_company_role_id,
            person_company_role_id,
            'direct'
        FROM relationships.person_company_roles
        WHERE role_title = 'Constraint Test Employee'
    $sql$
);


-- ============================================================================
-- Identity constraints
-- ============================================================================

SELECT pg_temp.expect_error(
    'account status CHECK',
    '23514',
    $sql$
        INSERT INTO identity.user_accounts (
            person_id,
            account_email,
            username,
            account_status
        )
        SELECT
            person_id,
            'invalid.status@example.com',
            'invalid_status_user',
            'unknown'
        FROM people.persons
        WHERE display_name = 'Second Constraint Test Person'
    $sql$
);


SELECT pg_temp.expect_error(
    'local authentication requires a password hash',
    '23514',
    $sql$
        INSERT INTO identity.authentication_identities (
            account_id,
            provider,
            provider_subject
        )
        SELECT
            account_id,
            'local',
            'constraint-test-local'
        FROM identity.user_accounts
        WHERE username = 'constraint_user'
    $sql$
);


-- ============================================================================
-- Finance constraints
-- ============================================================================

SELECT pg_temp.expect_error(
    'currency code format CHECK',
    '23514',
    $sql$
        INSERT INTO finance.currencies (
            currency_code,
            currency_name
        )
        VALUES (
            'usd',
            'Invalid lowercase currency'
        )
    $sql$
);


-- ============================================================================
-- Document constraints
-- ============================================================================

SELECT pg_temp.expect_error(
    'only one current version per document',
    '23505',
    $sql$
        INSERT INTO documents.document_versions (
            document_id,
            version_number,
            storage_uri,
            is_current
        )
        SELECT
            document_id,
            2,
            'constraint-test/document-v2.pdf',
            TRUE
        FROM documents.document_records
        WHERE document_number = 'CT-001'
    $sql$
);


-- ============================================================================
-- Audit constraints
-- ============================================================================

SELECT pg_temp.expect_error(
    'audit change must modify the value',
    '23514',
    $sql$
        INSERT INTO audit.audit_event_changes (
            audit_event_id,
            field_name,
            old_value,
            new_value
        )
        SELECT
            audit_event_id,
            'status',
            TO_JSONB('active'::TEXT),
            TO_JSONB('active'::TEXT)
        FROM audit.audit_events
        WHERE event_summary = 'Constraint test audit event'
    $sql$
);


INSERT INTO audit.audit_event_changes (
    audit_event_id,
    field_name,
    old_value,
    new_value
)
SELECT
    audit_event_id,
    'status',
    TO_JSONB('active'::TEXT),
    TO_JSONB('inactive'::TEXT)
FROM audit.audit_events
WHERE event_summary = 'Constraint test audit event';


SELECT pg_temp.expect_error(
    'one audit change per field and event',
    '23505',
    $sql$
        INSERT INTO audit.audit_event_changes (
            audit_event_id,
            field_name,
            old_value,
            new_value
        )
        SELECT
            audit_event_id,
            'status',
            TO_JSONB('inactive'::TEXT),
            TO_JSONB('archived'::TEXT)
        FROM audit.audit_events
        WHERE event_summary = 'Constraint test audit event'
    $sql$
);


-- ============================================================================
-- Cleanup
-- ============================================================================

ROLLBACK;

\echo '02_constraint_tests.sql passed'