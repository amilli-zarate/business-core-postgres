\set ON_ERROR_STOP on

BEGIN;

-- ============================================================
-- Core
-- ============================================================

INSERT INTO core.companies (
    company_slug,
    company_name,
    legal_name,
    tax_id,
    default_currency_code,
    company_status
)
VALUES (
    'minimal-business',
    'Minimal Business',
    'Minimal Business, S.A. de C.V.',
    'MBU260101001',
    'MXN',
    'active'
)
RETURNING company_id AS fixture_company_id
\gset


INSERT INTO core.branches (
    company_id,
    branch_code,
    branch_name,
    branch_type,
    branch_status,
    opened_on
)
VALUES (
    :fixture_company_id,
    'HQ',
    'Headquarters',
    'headquarters',
    'active',
    DATE '2020-01-01'
)
RETURNING branch_id AS fixture_branch_id
\gset


INSERT INTO core.departments (
    company_id,
    branch_id,
    department_code,
    department_name,
    department_status
)
VALUES (
    :fixture_company_id,
    :fixture_branch_id,
    'OPS',
    'Operations',
    'active'
)
RETURNING department_id AS fixture_parent_department_id
\gset


INSERT INTO core.departments (
    company_id,
    branch_id,
    parent_department_id,
    department_code,
    department_name,
    department_status
)
VALUES (
    :fixture_company_id,
    :fixture_branch_id,
    :fixture_parent_department_id,
    'DATA',
    'Data',
    'active'
)
RETURNING department_id AS fixture_department_id
\gset


-- ============================================================
-- People and relationships
-- ============================================================

INSERT INTO people.persons (
    company_id,
    external_reference,
    display_name,
    given_name,
    family_name,
    person_status
)
VALUES (
    :fixture_company_id,
    'EMP-001',
    'Alex Rivera',
    'Alex',
    'Rivera',
    'active'
)
RETURNING person_id AS fixture_person_id
\gset


INSERT INTO people.person_contact_methods (
    company_id,
    person_id,
    contact_type,
    contact_label,
    contact_value,
    is_primary,
    is_verified
)
VALUES (
    :fixture_company_id,
    :fixture_person_id,
    'email',
    'Work',
    'alex.rivera@example.com',
    TRUE,
    TRUE
);


INSERT INTO relationships.person_company_roles (
    company_id,
    person_id,
    role_type,
    role_title,
    status,
    valid_from
)
VALUES (
    :fixture_company_id,
    :fixture_person_id,
    'employee',
    'Data Analyst',
    'active',
    DATE '2020-01-01'
)
RETURNING person_company_role_id AS fixture_role_id
\gset


INSERT INTO relationships.person_department_assignments (
    company_id,
    person_company_role_id,
    department_id,
    assignment_type,
    position_title,
    valid_from
)
VALUES (
    :fixture_company_id,
    :fixture_role_id,
    :fixture_department_id,
    'primary',
    'Data Analyst',
    DATE '2020-01-01'
);


-- ============================================================
-- Identity
-- ============================================================

INSERT INTO identity.user_accounts (
    person_id,
    account_email,
    username,
    account_status
)
VALUES (
    :fixture_person_id,
    'alex.rivera@example.com',
    'alex_rivera',
    'active'
)
RETURNING account_id AS fixture_account_id
\gset


-- ============================================================
-- Finance
-- ============================================================

INSERT INTO finance.currencies (
    currency_code,
    currency_name,
    minor_units
)
VALUES (
    'MXN',
    'Mexican Peso',
    2
)
ON CONFLICT (currency_code) DO NOTHING;


INSERT INTO finance.fiscal_periods (
    company_id,
    period_code,
    period_name,
    fiscal_year,
    period_number,
    start_date,
    end_date,
    period_status
)
VALUES (
    :fixture_company_id,
    '2026-01',
    'January 2026',
    2026,
    1,
    DATE '2026-01-01',
    DATE '2026-01-31',
    'open'
)
RETURNING fiscal_period_id AS fixture_fiscal_period_id
\gset


INSERT INTO finance.accounts (
    company_id,
    account_code,
    account_name,
    account_type,
    normal_balance
)
VALUES (
    :fixture_company_id,
    '1100',
    'Cash',
    'asset',
    'debit'
)
RETURNING account_id AS fixture_cash_account_id
\gset


INSERT INTO finance.accounts (
    company_id,
    account_code,
    account_name,
    account_type,
    normal_balance
)
VALUES (
    :fixture_company_id,
    '4100',
    'Service Revenue',
    'revenue',
    'credit'
)
RETURNING account_id AS fixture_revenue_account_id
\gset


INSERT INTO finance.financial_transactions (
    company_id,
    fiscal_period_id,
    transaction_number,
    transaction_date,
    posting_date,
    currency_code,
    transaction_type,
    status,
    description,
    created_by_account_id
)
VALUES (
    :fixture_company_id,
    :fixture_fiscal_period_id,
    'JE-2026-001',
    DATE '2026-01-15',
    DATE '2026-01-15',
    'MXN',
    'journal_entry',
    'draft',
    'Fixture service revenue',
    :fixture_account_id
)
RETURNING transaction_id AS fixture_transaction_id
\gset


INSERT INTO finance.transaction_lines (
    company_id,
    transaction_id,
    line_number,
    account_id,
    debit_amount,
    credit_amount,
    line_description
)
VALUES
(
    :fixture_company_id,
    :fixture_transaction_id,
    1,
    :fixture_cash_account_id,
    1000.0000,
    0.0000,
    'Cash received'
),
(
    :fixture_company_id,
    :fixture_transaction_id,
    2,
    :fixture_revenue_account_id,
    0.0000,
    1000.0000,
    'Service revenue recognized'
);


UPDATE finance.financial_transactions
SET
    status = 'posted',
    posted_at = TIMESTAMPTZ '2026-01-15 10:00:00+00'
WHERE transaction_id = :fixture_transaction_id;


-- ============================================================
-- Documents
-- ============================================================

INSERT INTO documents.document_types (
    type_key,
    type_name,
    description
)
VALUES (
    'fixture_policy',
    'Fixture Policy',
    'Document type used by the minimal business fixture'
)
RETURNING document_type_id AS fixture_document_type_id
\gset


INSERT INTO documents.document_records (
    company_id,
    document_type_id,
    document_title,
    document_number,
    document_status,
    confidentiality_level,
    issue_date,
    effective_date,
    expiration_date,
    owner_person_id,
    created_by_account_id
)
VALUES (
    :fixture_company_id,
    :fixture_document_type_id,
    'Data Governance Policy',
    'POL-2026-001',
    'active',
    'internal',
    DATE '2026-01-10',
    DATE '2026-01-15',
    DATE '2099-12-31',
    :fixture_person_id,
    :fixture_account_id
)
RETURNING document_id AS fixture_document_id
\gset


INSERT INTO documents.document_versions (
    document_id,
    version_number,
    storage_uri,
    mime_type,
    file_size_bytes,
    content_hash,
    is_current,
    uploaded_by_account_id,
    change_summary
)
VALUES (
    :fixture_document_id,
    1,
    's3://fixture/documents/POL-2026-001-v1.pdf',
    'application/pdf',
    1024,
    'fixture-document-hash',
    TRUE,
    :fixture_account_id,
    'Initial version'
);


-- ============================================================
-- Workflows
-- ============================================================

INSERT INTO workflows.workflow_definitions (
    company_id,
    workflow_key,
    version_number,
    name,
    description,
    workflow_domain,
    target_entity_schema,
    target_entity_table,
    created_by_account_id
)
VALUES (
    :fixture_company_id,
    'document_approval',
    1,
    'Document Approval',
    'Approval workflow used by the minimal business fixture',
    'documents',
    'documents',
    'document_records',
    :fixture_account_id
)
RETURNING workflow_definition_id AS fixture_workflow_definition_id
\gset


INSERT INTO workflows.workflow_steps (
    workflow_definition_id,
    step_key,
    name,
    step_order,
    step_type,
    default_assignee_type,
    default_assignee_account_id
)
VALUES (
    :fixture_workflow_definition_id,
    'review',
    'Review Document',
    1,
    'approval',
    'specific_account',
    :fixture_account_id
)
RETURNING workflow_step_id AS fixture_workflow_step_id
\gset


INSERT INTO workflows.workflow_instances (
    company_id,
    workflow_definition_id,
    current_step_id,
    title,
    subject_entity_schema,
    subject_entity_table,
    subject_entity_id,
    status,
    started_by_account_id,
    started_at
)
VALUES (
    :fixture_company_id,
    :fixture_workflow_definition_id,
    :fixture_workflow_step_id,
    'Approve Data Governance Policy',
    'documents',
    'document_records',
    :fixture_document_id,
    'running',
    :fixture_account_id,
    TIMESTAMPTZ '2026-01-15 09:00:00+00'
)
RETURNING workflow_instance_id AS fixture_workflow_instance_id
\gset


INSERT INTO workflows.workflow_tasks (
    company_id,
    workflow_instance_id,
    workflow_definition_id,
    workflow_step_id,
    title,
    status,
    priority,
    assigned_to_account_id,
    due_at
)
VALUES (
    :fixture_company_id,
    :fixture_workflow_instance_id,
    :fixture_workflow_definition_id,
    :fixture_workflow_step_id,
    'Review Data Governance Policy',
    'open',
    'high',
    :fixture_account_id,
    TIMESTAMPTZ '2020-01-20 12:00:00+00'
);


-- ============================================================
-- Audit
-- ============================================================

INSERT INTO audit.audit_events (
    event_occurred_at,
    action_category,
    action_type,
    event_outcome,
    severity,
    entity_schema,
    entity_table,
    entity_record_id,
    actor_account_id,
    actor_person_id,
    company_id,
    workflow_instance_id,
    source_system,
    event_summary,
    metadata
)
VALUES (
    TIMESTAMPTZ '2026-01-15 10:00:00+00',
    'DOCUMENT',
    'CREATE',
    'SUCCESS',
    'INFO',
    'documents',
    'document_records',
    :fixture_document_id,
    :fixture_account_id,
    :fixture_person_id,
    :fixture_company_id,
    :fixture_workflow_instance_id,
    'fixture',
    'Minimal fixture document created',
    '{"fixture": true}'::JSONB
);


COMMIT;

\echo '03_seed_minimal_business.sql completed'