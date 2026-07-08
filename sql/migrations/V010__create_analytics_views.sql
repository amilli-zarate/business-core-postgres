BEGIN;

CREATE SCHEMA IF NOT EXISTS analytics;

COMMENT ON SCHEMA analytics IS
'Read-oriented analytics layer with reusable business views built from the operational core schemas.';


-- ============================================================
-- Company structure
-- ============================================================

CREATE OR REPLACE VIEW analytics.company_structure AS
SELECT
    c.company_id,
    c.company_slug,
    c.company_name,
    c.legal_name,
    c.tax_id,
    c.default_currency_code,
    c.company_status,

    b.branch_id,
    b.branch_code,
    b.branch_name,
    b.branch_type,
    b.branch_status,

    d.department_id,
    d.department_code,
    d.department_name,
    d.department_status,

    d.parent_department_id,
    parent_d.department_code AS parent_department_code,
    parent_d.department_name AS parent_department_name

FROM core.companies AS c
LEFT JOIN core.branches AS b
    ON b.company_id = c.company_id
LEFT JOIN core.departments AS d
    ON d.company_id = c.company_id
   AND d.branch_id = b.branch_id
LEFT JOIN core.departments AS parent_d
    ON parent_d.company_id = d.company_id
   AND parent_d.department_id = d.parent_department_id;

COMMENT ON VIEW analytics.company_structure IS
'Denormalized company, branch, and department structure, including department hierarchy.';


-- ============================================================
-- People directory
-- ============================================================

CREATE OR REPLACE VIEW analytics.people_directory AS
SELECT
    p.company_id,
    c.company_slug,
    c.company_name,

    p.person_id,
    p.external_reference,
    p.display_name,
    p.given_name,
    p.middle_name,
    p.family_name,
    p.additional_family_name,
    p.person_status,

    primary_email_cm.contact_value AS primary_email,
    primary_phone_cm.contact_value AS primary_phone,

    account_u.account_id,
    account_u.username,
    account_u.account_email,
    account_u.account_status,

    p.created_at,
    p.updated_at

FROM people.persons AS p
JOIN core.companies AS c
    ON c.company_id = p.company_id

LEFT JOIN LATERAL (
    SELECT
        cm.contact_value
    FROM people.person_contact_methods AS cm
    WHERE cm.company_id = p.company_id
      AND cm.person_id = p.person_id
      AND cm.contact_type = 'email'
    ORDER BY
        cm.is_primary DESC,
        cm.is_verified DESC,
        cm.contact_method_id ASC
    LIMIT 1
) AS primary_email_cm ON TRUE

LEFT JOIN LATERAL (
    SELECT
        cm.contact_value
    FROM people.person_contact_methods AS cm
    WHERE cm.company_id = p.company_id
      AND cm.person_id = p.person_id
      AND cm.contact_type IN ('phone', 'mobile')
    ORDER BY
        cm.is_primary DESC,
        cm.is_verified DESC,
        cm.contact_method_id ASC
    LIMIT 1
) AS primary_phone_cm ON TRUE

LEFT JOIN LATERAL (
    SELECT
        ua.account_id,
        ua.username,
        ua.account_email,
        ua.account_status
    FROM identity.user_accounts AS ua
    WHERE ua.person_id = p.person_id
    ORDER BY ua.account_id ASC
    LIMIT 1
) AS account_u ON TRUE;

COMMENT ON VIEW analytics.people_directory IS
'Person directory with primary contact information and associated user account data.';


-- ============================================================
-- Current person-company roles
-- ============================================================

CREATE OR REPLACE VIEW analytics.current_person_company_roles AS
SELECT
    r.company_id,
    c.company_slug,
    c.company_name,

    r.person_company_role_id,
    r.person_id,
    p.display_name,

    r.role_type,
    r.role_title,
    r.status,
    r.valid_from,
    r.valid_to,

    r.created_at,
    r.updated_at

FROM relationships.person_company_roles AS r
JOIN core.companies AS c
    ON c.company_id = r.company_id
JOIN people.persons AS p
    ON p.company_id = r.company_id
   AND p.person_id = r.person_id
WHERE r.status = 'active'
  AND r.valid_from <= CURRENT_DATE
  AND (
        r.valid_to IS NULL
        OR r.valid_to >= CURRENT_DATE
      );

COMMENT ON VIEW analytics.current_person_company_roles IS
'Currently active person-company roles, including employees, contractors, owners, contacts, advisors, and other role types.';


-- ============================================================
-- Finance account balances
-- ============================================================

CREATE OR REPLACE VIEW analytics.finance_account_balances AS
SELECT
    a.company_id,
    c.company_slug,
    c.company_name,

    a.account_id,
    a.account_code,
    a.account_name,
    a.account_type,
    a.normal_balance,
    a.is_active,

    COALESCE(
        SUM(
            CASE
                WHEN t.transaction_id IS NOT NULL THEN l.debit_amount
                ELSE 0
            END
        ),
        0
    )::NUMERIC(18, 2) AS total_debit,

    COALESCE(
        SUM(
            CASE
                WHEN t.transaction_id IS NOT NULL THEN l.credit_amount
                ELSE 0
            END
        ),
        0
    )::NUMERIC(18, 2) AS total_credit,

    COALESCE(
        SUM(
            CASE
                WHEN t.transaction_id IS NOT NULL THEN l.debit_amount - l.credit_amount
                ELSE 0
            END
        ),
        0
    )::NUMERIC(18, 2) AS debit_minus_credit,

    CASE
        WHEN a.normal_balance = 'debit' THEN
            COALESCE(
                SUM(
                    CASE
                        WHEN t.transaction_id IS NOT NULL THEN l.debit_amount - l.credit_amount
                        ELSE 0
                    END
                ),
                0
            )::NUMERIC(18, 2)

        WHEN a.normal_balance = 'credit' THEN
            COALESCE(
                SUM(
                    CASE
                        WHEN t.transaction_id IS NOT NULL THEN l.credit_amount - l.debit_amount
                        ELSE 0
                    END
                ),
                0
            )::NUMERIC(18, 2)

        ELSE 0::NUMERIC(18, 2)
    END AS account_balance

FROM finance.accounts AS a
JOIN core.companies AS c
    ON c.company_id = a.company_id
LEFT JOIN finance.transaction_lines AS l
    ON l.company_id = a.company_id
   AND l.account_id = a.account_id
LEFT JOIN finance.financial_transactions AS t
    ON t.company_id = l.company_id
   AND t.transaction_id = l.transaction_id
   AND t.status = 'posted'
GROUP BY
    a.company_id,
    c.company_slug,
    c.company_name,
    a.account_id,
    a.account_code,
    a.account_name,
    a.account_type,
    a.normal_balance,
    a.is_active;

COMMENT ON VIEW analytics.finance_account_balances IS
'Posted financial balances by company and account, respecting each account normal balance.';


-- ============================================================
-- Finance monthly summary
-- ============================================================

CREATE OR REPLACE VIEW analytics.finance_monthly_summary AS
SELECT
    t.company_id,
    c.company_slug,
    c.company_name,

    DATE_TRUNC('month', t.transaction_date)::DATE AS month_start,
    t.currency_code,

    COUNT(DISTINCT t.transaction_id)::INTEGER AS posted_transactions,
    COUNT(l.transaction_line_id)::INTEGER AS posted_transaction_lines,

    COALESCE(SUM(l.debit_amount), 0)::NUMERIC(18, 2) AS total_debit,
    COALESCE(SUM(l.credit_amount), 0)::NUMERIC(18, 2) AS total_credit,
    COALESCE(SUM(l.debit_amount - l.credit_amount), 0)::NUMERIC(18, 2) AS net_amount

FROM finance.financial_transactions AS t
JOIN finance.transaction_lines AS l
    ON l.company_id = t.company_id
   AND l.transaction_id = t.transaction_id
JOIN core.companies AS c
    ON c.company_id = t.company_id
WHERE t.status = 'posted'
GROUP BY
    t.company_id,
    c.company_slug,
    c.company_name,
    DATE_TRUNC('month', t.transaction_date)::DATE,
    t.currency_code;

COMMENT ON VIEW analytics.finance_monthly_summary IS
'Monthly posted financial activity by company and currency.';


-- ============================================================
-- Document register
-- ============================================================

CREATE OR REPLACE VIEW analytics.document_register AS
SELECT
    d.company_id,
    c.company_slug,
    c.company_name,

    d.document_id,
    d.document_title,
    d.document_number,
    d.document_status,
    d.confidentiality_level,

    dt.document_type_id,
    dt.type_key,
    dt.type_name,

    d.issue_date,
    d.effective_date,
    d.expiration_date,

    CASE
        WHEN d.expiration_date IS NOT NULL
         AND d.expiration_date < CURRENT_DATE
        THEN TRUE
        ELSE FALSE
    END AS is_expired,

    d.owner_person_id,
    owner_p.display_name AS owner_display_name,

    d.created_by_account_id,
    creator_u.username AS created_by_username,

    d.created_at,
    d.updated_at

FROM documents.document_records AS d
JOIN core.companies AS c
    ON c.company_id = d.company_id
JOIN documents.document_types AS dt
    ON dt.document_type_id = d.document_type_id
LEFT JOIN people.persons AS owner_p
    ON owner_p.person_id = d.owner_person_id
LEFT JOIN identity.user_accounts AS creator_u
    ON creator_u.account_id = d.created_by_account_id;

COMMENT ON VIEW analytics.document_register IS
'Document register with document type, status, confidentiality, ownership, and expiration indicators.';


-- ============================================================
-- Workflow task backlog
-- ============================================================

CREATE OR REPLACE VIEW analytics.workflow_task_backlog AS
SELECT
    wi.company_id,
    c.company_slug,
    c.company_name,

    wd.workflow_definition_id,
    wd.workflow_key,
    wd.name AS workflow_name,

    wi.workflow_instance_id,
    wi.title AS workflow_instance_title,
    wi.subject_entity_schema,
    wi.subject_entity_table,
    wi.subject_entity_id,
    wi.status AS workflow_instance_status,

    wt.workflow_task_id,
    wt.workflow_step_id,
    wt.title AS task_title,
    wt.status AS task_status,
    wt.priority,
    wt.assigned_to_account_id,

    assigned_u.username AS assigned_to_username,
    assigned_p.display_name AS assigned_to_display_name,

    wt.due_at,
    wt.completed_at,

    CASE
        WHEN wt.completed_at IS NULL
         AND wt.due_at IS NOT NULL
         AND wt.due_at < NOW()
         AND wt.status NOT IN ('completed', 'cancelled')
        THEN TRUE
        ELSE FALSE
    END AS is_overdue,

    wt.created_at,
    wt.updated_at

FROM workflows.workflow_tasks AS wt
JOIN workflows.workflow_instances AS wi
    ON wi.workflow_instance_id = wt.workflow_instance_id
JOIN workflows.workflow_definitions AS wd
    ON wd.workflow_definition_id = wi.workflow_definition_id
JOIN core.companies AS c
    ON c.company_id = wi.company_id
LEFT JOIN identity.user_accounts AS assigned_u
    ON assigned_u.account_id = wt.assigned_to_account_id
LEFT JOIN people.persons AS assigned_p
    ON assigned_p.person_id = assigned_u.person_id
WHERE wt.status NOT IN ('completed', 'cancelled');

COMMENT ON VIEW analytics.workflow_task_backlog IS
'Open workflow tasks with workflow context, assignee information, due dates, and overdue flag.';


-- ============================================================
-- Daily audit activity
-- ============================================================

CREATE OR REPLACE VIEW analytics.audit_activity_daily AS
SELECT
    ae.company_id,
    c.company_slug,
    c.company_name,

    ae.event_occurred_at::DATE AS activity_date,
    ae.action_category,
    ae.action_type,
    ae.event_outcome,
    ae.severity,
    ae.entity_schema,
    ae.entity_table,

    COUNT(*)::INTEGER AS event_count,
    COUNT(DISTINCT ae.actor_account_id)::INTEGER AS distinct_actor_accounts,
    COUNT(DISTINCT ae.actor_person_id)::INTEGER AS distinct_actor_persons

FROM audit.audit_events AS ae
LEFT JOIN core.companies AS c
    ON c.company_id = ae.company_id
GROUP BY
    ae.company_id,
    c.company_slug,
    c.company_name,
    ae.event_occurred_at::DATE,
    ae.action_category,
    ae.action_type,
    ae.event_outcome,
    ae.severity,
    ae.entity_schema,
    ae.entity_table;

COMMENT ON VIEW analytics.audit_activity_daily IS
'Daily audit activity grouped by company, action, outcome, severity, and target entity.';


COMMIT;