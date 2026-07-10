\set ON_ERROR_STOP on

-- ---------------------------------------------------------------------------
-- Fixture precondition
-- ---------------------------------------------------------------------------

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1
        FROM core.companies
        WHERE company_slug = 'minimal-business'
    ) THEN
        RAISE EXCEPTION
            'Minimal fixture not found. Run 03_seed_minimal_business.sql first.';
    END IF;
END
$$;


-- ---------------------------------------------------------------------------
-- analytics.company_structure
-- ---------------------------------------------------------------------------

DO $$
DECLARE
    actual_count BIGINT;
BEGIN
    SELECT COUNT(*)
    INTO actual_count
    FROM analytics.company_structure
    WHERE company_slug = 'minimal-business';

    IF actual_count <> 2 THEN
        RAISE EXCEPTION
            'company_structure: expected 2 rows, found %',
            actual_count;
    END IF;

    IF NOT EXISTS (
        SELECT 1
        FROM analytics.company_structure
        WHERE company_slug = 'minimal-business'
          AND branch_code = 'HQ'
          AND department_code = 'OPS'
          AND department_name = 'Operations'
          AND parent_department_id IS NULL
    ) THEN
        RAISE EXCEPTION
            'company_structure: Operations department is incorrect or missing';
    END IF;

    IF NOT EXISTS (
        SELECT 1
        FROM analytics.company_structure
        WHERE company_slug = 'minimal-business'
          AND branch_code = 'HQ'
          AND department_code = 'DATA'
          AND department_name = 'Data'
          AND parent_department_code = 'OPS'
          AND parent_department_name = 'Operations'
    ) THEN
        RAISE EXCEPTION
            'company_structure: Data department hierarchy is incorrect';
    END IF;
END
$$;


-- ---------------------------------------------------------------------------
-- analytics.people_directory
-- ---------------------------------------------------------------------------

DO $$
DECLARE
    actual_count BIGINT;
BEGIN
    SELECT COUNT(*)
    INTO actual_count
    FROM analytics.people_directory
    WHERE company_slug = 'minimal-business';

    IF actual_count <> 1 THEN
        RAISE EXCEPTION
            'people_directory: expected 1 row, found %',
            actual_count;
    END IF;

    IF NOT EXISTS (
        SELECT 1
        FROM analytics.people_directory
        WHERE company_slug = 'minimal-business'
          AND external_reference = 'EMP-001'
          AND display_name = 'Alex Rivera'
          AND primary_email = 'alex.rivera@example.com'
          AND username = 'alex_rivera'
          AND account_email = 'alex.rivera@example.com'
          AND account_status = 'active'
    ) THEN
        RAISE EXCEPTION
            'people_directory: Alex Rivera directory data is incorrect';
    END IF;
END
$$;


-- ---------------------------------------------------------------------------
-- analytics.current_person_company_roles
-- ---------------------------------------------------------------------------

DO $$
DECLARE
    actual_count BIGINT;
BEGIN
    SELECT COUNT(*)
    INTO actual_count
    FROM analytics.current_person_company_roles
    WHERE company_slug = 'minimal-business';

    IF actual_count <> 1 THEN
        RAISE EXCEPTION
            'current_person_company_roles: expected 1 row, found %',
            actual_count;
    END IF;

    IF NOT EXISTS (
        SELECT 1
        FROM analytics.current_person_company_roles
        WHERE company_slug = 'minimal-business'
          AND display_name = 'Alex Rivera'
          AND role_type = 'employee'
          AND role_title = 'Data Analyst'
          AND status = 'active'
    ) THEN
        RAISE EXCEPTION
            'current_person_company_roles: active Data Analyst role is incorrect';
    END IF;
END
$$;


-- ---------------------------------------------------------------------------
-- analytics.finance_account_balances
-- ---------------------------------------------------------------------------

DO $$
DECLARE
    actual_count BIGINT;
BEGIN
    SELECT COUNT(*)
    INTO actual_count
    FROM analytics.finance_account_balances
    WHERE company_slug = 'minimal-business';

    IF actual_count <> 2 THEN
        RAISE EXCEPTION
            'finance_account_balances: expected 2 rows, found %',
            actual_count;
    END IF;

    IF NOT EXISTS (
        SELECT 1
        FROM analytics.finance_account_balances
        WHERE company_slug = 'minimal-business'
          AND account_code = '1100'
          AND account_name = 'Cash'
          AND total_debit = 1000.00
          AND total_credit = 0.00
          AND debit_minus_credit = 1000.00
    ) THEN
        RAISE EXCEPTION
            'finance_account_balances: Cash balance is incorrect';
    END IF;

    IF NOT EXISTS (
        SELECT 1
        FROM analytics.finance_account_balances
        WHERE company_slug = 'minimal-business'
          AND account_code = '4100'
          AND account_name = 'Service Revenue'
          AND total_debit = 0.00
          AND total_credit = 1000.00
          AND debit_minus_credit = -1000.00
    ) THEN
        RAISE EXCEPTION
            'finance_account_balances: Service Revenue balance is incorrect';
    END IF;
END
$$;


-- ---------------------------------------------------------------------------
-- analytics.finance_monthly_summary
-- ---------------------------------------------------------------------------

DO $$
DECLARE
    actual_count BIGINT;
BEGIN
    SELECT COUNT(*)
    INTO actual_count
    FROM analytics.finance_monthly_summary
    WHERE company_slug = 'minimal-business';

    IF actual_count <> 1 THEN
        RAISE EXCEPTION
            'finance_monthly_summary: expected 1 row, found %',
            actual_count;
    END IF;

    IF NOT EXISTS (
        SELECT 1
        FROM analytics.finance_monthly_summary
        WHERE company_slug = 'minimal-business'
          AND month_start = DATE '2026-01-01'
          AND currency_code = 'MXN'
          AND posted_transactions = 1
          AND posted_transaction_lines = 2
          AND total_debit = 1000.00
          AND total_credit = 1000.00
          AND net_amount = 0.00
    ) THEN
        RAISE EXCEPTION
            'finance_monthly_summary: January 2026 summary is incorrect';
    END IF;
END
$$;


-- ---------------------------------------------------------------------------
-- analytics.document_register
-- ---------------------------------------------------------------------------

DO $$
DECLARE
    actual_count BIGINT;
BEGIN
    SELECT COUNT(*)
    INTO actual_count
    FROM analytics.document_register
    WHERE company_slug = 'minimal-business';

    IF actual_count <> 1 THEN
        RAISE EXCEPTION
            'document_register: expected 1 row, found %',
            actual_count;
    END IF;

    IF NOT EXISTS (
        SELECT 1
        FROM analytics.document_register
        WHERE company_slug = 'minimal-business'
          AND document_number = 'POL-2026-001'
          AND document_title = 'Data Governance Policy'
          AND document_status = 'active'
          AND confidentiality_level = 'internal'
          AND type_key = 'fixture_policy'
          AND type_name = 'Fixture Policy'
          AND owner_display_name = 'Alex Rivera'
          AND created_by_username = 'alex_rivera'
          AND is_expired = FALSE
    ) THEN
        RAISE EXCEPTION
            'document_register: Data Governance Policy data is incorrect';
    END IF;
END
$$;


-- ---------------------------------------------------------------------------
-- analytics.workflow_task_backlog
-- ---------------------------------------------------------------------------

DO $$
DECLARE
    actual_count BIGINT;
BEGIN
    SELECT COUNT(*)
    INTO actual_count
    FROM analytics.workflow_task_backlog
    WHERE company_slug = 'minimal-business';

    IF actual_count <> 1 THEN
        RAISE EXCEPTION
            'workflow_task_backlog: expected 1 row, found %',
            actual_count;
    END IF;

    IF NOT EXISTS (
        SELECT 1
        FROM analytics.workflow_task_backlog
        WHERE company_slug = 'minimal-business'
          AND workflow_key = 'document_approval'
          AND workflow_name = 'Document Approval'
          AND workflow_instance_title = 'Approve Data Governance Policy'
          AND workflow_instance_status = 'running'
          AND task_title = 'Review Data Governance Policy'
          AND task_status = 'open'
          AND priority = 'high'
          AND assigned_to_username = 'alex_rivera'
          AND assigned_to_display_name = 'Alex Rivera'
          AND due_at = TIMESTAMPTZ '2020-01-20 12:00:00+00'
          AND is_overdue = TRUE
    ) THEN
        RAISE EXCEPTION
            'workflow_task_backlog: document review task is incorrect';
    END IF;
END
$$;


-- ---------------------------------------------------------------------------
-- analytics.audit_activity_daily
-- ---------------------------------------------------------------------------

DO $$
DECLARE
    actual_count BIGINT;
BEGIN
    SELECT COUNT(*)
    INTO actual_count
    FROM analytics.audit_activity_daily
    WHERE company_slug = 'minimal-business';

    IF actual_count <> 1 THEN
        RAISE EXCEPTION
            'audit_activity_daily: expected 1 row, found %',
            actual_count;
    END IF;

    IF NOT EXISTS (
        SELECT 1
        FROM analytics.audit_activity_daily
        WHERE company_slug = 'minimal-business'
          AND activity_date = DATE '2026-01-15'
          AND action_category = 'DOCUMENT'
          AND action_type = 'CREATE'
          AND event_outcome = 'SUCCESS'
          AND severity = 'INFO'
          AND entity_schema = 'documents'
          AND entity_table = 'document_records'
          AND event_count = 1
          AND distinct_actor_accounts = 1
          AND distinct_actor_persons = 1
    ) THEN
        RAISE EXCEPTION
            'audit_activity_daily: January 15 audit aggregation is incorrect';
    END IF;
END
$$;


\echo '04_analytics_view_tests.sql passed'