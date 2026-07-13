\set ON_ERROR_STOP on
\encoding UTF8

BEGIN;

-- ============================================================
-- 07_workflows.sql
-- Realistic multi-company example
--
-- Purpose:
-- Seed a substantial, internally consistent workflow dataset:
--
-- - company-scoped workflow definitions
-- - ordered steps and allowed transitions
-- - runtime instances linked to financial transactions,
--   documents, people, and branches
-- - completed, running, draft, paused, failed, and cancelled
--   execution examples
-- - actionable tasks with account and role assignments
-- - complete workflow status and step-movement histories
--
-- Notes:
-- - All organizations, people, workflows, identifiers, and
--   operational scenarios are synthetic.
-- - Generated identities are always resolved through stable
--   business keys; no BIGINT identity value is hard-coded.
-- - Shared permissions and access-role definitions remain owned
--   by 01_shared_reference_data.sql and are only consumed here.
-- - Cross-domain audit events are intentionally excluded. They
--   belong to 08_audit.sql.
-- - The script depends on 01_shared_reference_data.sql through
--   06_documents.sql.
-- - The script is safe to run more than once. Workflow records
--   owned by this fixture are rebuilt deterministically.
-- ============================================================

-- ============================================================
-- Fixture company profiles
-- ============================================================

CREATE TEMP TABLE fixture_workflow_profiles (
    company_slug TEXT PRIMARY KEY,
    workflow_prefix TEXT NOT NULL,
    company_label TEXT NOT NULL,
    creator_person_external_reference TEXT NOT NULL,
    completed_onboarding_person_external_reference TEXT NOT NULL,
    draft_onboarding_person_external_reference TEXT,
    operations_branch_code TEXT NOT NULL,
    representative_posted_transaction_number TEXT NOT NULL,
    representative_draft_transaction_number TEXT,
    completed_document_number TEXT NOT NULL,
    draft_document_number TEXT,
    operations_scenario_key TEXT NOT NULL,
    operations_status TEXT NOT NULL,
    operations_current_step_key TEXT NOT NULL,
    operations_completed_offset INTERVAL,
    reference_date DATE NOT NULL,
    archival_date DATE
) ON COMMIT DROP;

INSERT INTO fixture_workflow_profiles (
    company_slug,
    workflow_prefix,
    company_label,
    creator_person_external_reference,
    completed_onboarding_person_external_reference,
    draft_onboarding_person_external_reference,
    operations_branch_code,
    representative_posted_transaction_number,
    representative_draft_transaction_number,
    completed_document_number,
    draft_document_number,
    operations_scenario_key,
    operations_status,
    operations_current_step_key,
    operations_completed_offset,
    reference_date,
    archival_date
)
VALUES
    (
        'solara-retail-mx',
        'SRM',
        'Solara Retail Mexico',
        'SRM-P009',
        'SRM-P014',
        'SRM-P015',
        'MX-CMX-POL',
        'SRM-202606-OPEX',
        'SRM-202607-DRAFT',
        'SRM-DOC-OPS-SOP-001',
        'SRM-DOC-BCP-DRAFT-001',
        'operations_running',
        'running',
        'corrective_action',
        NULL,
        DATE '2026-06-30',
        NULL
    ),
    (
        'cobalto-industrial-mx',
        'CIS',
        'Cobalto Industrial Systems',
        'CIS-P010',
        'CIS-P014',
        'CIS-P015',
        'MX-APO-PLT',
        'CIS-202606-OPEX',
        'CIS-202607-DRAFT',
        'CIS-DOC-OPS-SOP-001',
        'CIS-DOC-BCP-DRAFT-001',
        'operations_running',
        'running',
        'corrective_action',
        NULL,
        DATE '2026-06-30',
        NULL
    ),
    (
        'bluepeak-advisory-us',
        'BPA',
        'BluePeak Advisory',
        'BPA-P009',
        'BPA-P014',
        'BPA-P015',
        'US-AUS-HQ',
        'BPA-202606-OPEX',
        'BPA-202607-DRAFT',
        'BPA-DOC-OPS-SOP-001',
        'BPA-DOC-BCP-DRAFT-001',
        'operations_completed',
        'completed',
        'closed',
        INTERVAL '120 hours',
        DATE '2026-06-30',
        NULL
    ),
    (
        'lumenforge-technologies-us',
        'LFT',
        'LumenForge Technologies',
        'LFT-P010',
        'LFT-P014',
        'LFT-P015',
        'US-SEA-HQ',
        'LFT-202606-OPEX',
        'LFT-202607-DRAFT',
        'LFT-DOC-OPS-SOP-001',
        'LFT-DOC-BCP-DRAFT-001',
        'operations_failed',
        'failed',
        'verification',
        NULL,
        DATE '2026-06-30',
        NULL
    ),
    (
        'cedarline-logistics-ca',
        'CLL',
        'CedarLine Logistics',
        'CLL-P010',
        'CLL-P014',
        'CLL-P015',
        'CA-TOR-HQ',
        'CLL-202606-OPEX',
        'CLL-202607-DRAFT',
        'CLL-DOC-OPS-SOP-001',
        'CLL-DOC-BCP-DRAFT-001',
        'operations_paused',
        'paused',
        'investigation',
        NULL,
        DATE '2026-06-30',
        NULL
    ),
    (
        'harvest-circle-foods-ca',
        'HCF',
        'Harvest Circle Foods',
        'HCF-P008',
        'HCF-P010',
        NULL,
        'CA-RIC-DC',
        'HCF-202409-OPEX',
        NULL,
        'HCF-DOC-OPS-SOP-001',
        NULL,
        'operations_completed',
        'completed',
        'closed',
        INTERVAL '120 hours',
        DATE '2024-09-20',
        DATE '2024-10-01'
    );

-- ============================================================
-- Dependency validation
-- ============================================================

DO $$
DECLARE
    expected_companies INTEGER;
    resolved_companies INTEGER;
BEGIN
    SELECT COUNT(*)
    INTO expected_companies
    FROM fixture_workflow_profiles;

    SELECT COUNT(*)
    INTO resolved_companies
    FROM fixture_workflow_profiles AS profiles
    JOIN core.companies AS companies
      ON companies.company_slug = profiles.company_slug;

    IF resolved_companies <> expected_companies THEN
        RAISE EXCEPTION
            '07_workflows.sql could resolve only % of % fixture companies. Run 02_organizations.sql first.',
            resolved_companies,
            expected_companies;
    END IF;

    IF EXISTS (
        SELECT 1
        FROM fixture_workflow_profiles AS profiles
        JOIN core.companies AS companies
          ON companies.company_slug = profiles.company_slug
        LEFT JOIN people.persons AS creators
          ON creators.company_id = companies.company_id
         AND creators.external_reference = profiles.creator_person_external_reference
        LEFT JOIN identity.user_accounts AS creator_accounts
          ON creator_accounts.person_id = creators.person_id
        LEFT JOIN people.persons AS completed_onboarding_people
          ON completed_onboarding_people.company_id = companies.company_id
         AND completed_onboarding_people.external_reference =
             profiles.completed_onboarding_person_external_reference
        LEFT JOIN people.persons AS draft_onboarding_people
          ON draft_onboarding_people.company_id = companies.company_id
         AND draft_onboarding_people.external_reference =
             profiles.draft_onboarding_person_external_reference
        WHERE creators.person_id IS NULL
           OR creator_accounts.account_id IS NULL
           OR completed_onboarding_people.person_id IS NULL
           OR (
                profiles.draft_onboarding_person_external_reference IS NOT NULL
                AND draft_onboarding_people.person_id IS NULL
           )
    ) THEN
        RAISE EXCEPTION
            '07_workflows.sql could not resolve one or more fixture people or creator accounts. Run the current 03_people_and_relationships.sql and 04_identity.sql first.';
    END IF;

    IF EXISTS (
        SELECT 1
        FROM fixture_workflow_profiles AS profiles
        JOIN core.companies AS companies
          ON companies.company_slug = profiles.company_slug
        LEFT JOIN core.branches AS branches
          ON branches.company_id = companies.company_id
         AND branches.branch_code = profiles.operations_branch_code
        WHERE branches.branch_id IS NULL
    ) THEN
        RAISE EXCEPTION
            '07_workflows.sql could not resolve one or more operating branches. Run the current 02_organizations.sql first.';
    END IF;

    IF EXISTS (
        SELECT 1
        FROM fixture_workflow_profiles AS profiles
        JOIN core.companies AS companies
          ON companies.company_slug = profiles.company_slug
        LEFT JOIN finance.financial_transactions AS posted_transactions
          ON posted_transactions.company_id = companies.company_id
         AND posted_transactions.transaction_number =
             profiles.representative_posted_transaction_number
        LEFT JOIN finance.financial_transactions AS draft_transactions
          ON draft_transactions.company_id = companies.company_id
         AND draft_transactions.transaction_number =
             profiles.representative_draft_transaction_number
        WHERE posted_transactions.transaction_id IS NULL
           OR (
                profiles.representative_draft_transaction_number IS NOT NULL
                AND draft_transactions.transaction_id IS NULL
           )
    ) THEN
        RAISE EXCEPTION
            '07_workflows.sql could not resolve one or more representative financial transactions. Run the current 05_finance.sql first.';
    END IF;

    IF EXISTS (
        SELECT 1
        FROM fixture_workflow_profiles AS profiles
        JOIN core.companies AS companies
          ON companies.company_slug = profiles.company_slug
        LEFT JOIN documents.document_records AS completed_documents
          ON completed_documents.company_id = companies.company_id
         AND completed_documents.document_number =
             profiles.completed_document_number
        LEFT JOIN documents.document_records AS draft_documents
          ON draft_documents.company_id = companies.company_id
         AND draft_documents.document_number = profiles.draft_document_number
        WHERE completed_documents.document_id IS NULL
           OR (
                profiles.draft_document_number IS NOT NULL
                AND draft_documents.document_id IS NULL
           )
    ) THEN
        RAISE EXCEPTION
            '07_workflows.sql could not resolve one or more representative documents. Run the current 06_documents.sql first.';
    END IF;

    IF EXISTS (
        SELECT required_role.role_key
        FROM (
            VALUES
                ('company_admin'),
                ('company_finance_manager'),
                ('company_people_manager'),
                ('company_operations_manager')
        ) AS required_role (role_key)
        LEFT JOIN identity.access_roles AS roles
          ON roles.role_key = required_role.role_key
        WHERE roles.role_id IS NULL
    ) THEN
        RAISE EXCEPTION
            '07_workflows.sql could not resolve one or more required access roles. Run the current 01_shared_reference_data.sql first.';
    END IF;
END;
$$;

-- ============================================================
-- Company and account context
-- ============================================================

CREATE TEMP TABLE fixture_workflow_account_context
ON COMMIT DROP
AS
SELECT
    profiles.*,
    companies.company_id,
    creator_accounts.account_id AS creator_account_id,
    COALESCE(company_admin.account_id, creator_accounts.account_id)
        AS admin_account_id,
    COALESCE(finance_manager.account_id, company_admin.account_id, creator_accounts.account_id)
        AS finance_account_id,
    COALESCE(people_manager.account_id, company_admin.account_id, creator_accounts.account_id)
        AS people_account_id,
    COALESCE(operations_manager.account_id, company_admin.account_id, creator_accounts.account_id)
        AS operations_account_id
FROM fixture_workflow_profiles AS profiles
JOIN core.companies AS companies
  ON companies.company_slug = profiles.company_slug
JOIN people.persons AS creators
  ON creators.company_id = companies.company_id
 AND creators.external_reference = profiles.creator_person_external_reference
JOIN identity.user_accounts AS creator_accounts
  ON creator_accounts.person_id = creators.person_id
LEFT JOIN LATERAL (
    SELECT assignments.account_id
    FROM identity.account_role_assignments AS assignments
    JOIN identity.access_roles AS roles
      ON roles.role_id = assignments.role_id
    JOIN identity.user_accounts AS accounts
      ON accounts.account_id = assignments.account_id
    WHERE assignments.company_id = companies.company_id
      AND assignments.scope_type = 'company'
      AND assignments.revoked_at IS NULL
      AND roles.role_key = 'company_admin'
      AND accounts.account_status = 'active'
    ORDER BY assignments.account_role_assignment_id
    LIMIT 1
) AS company_admin
  ON TRUE
LEFT JOIN LATERAL (
    SELECT assignments.account_id
    FROM identity.account_role_assignments AS assignments
    JOIN identity.access_roles AS roles
      ON roles.role_id = assignments.role_id
    JOIN identity.user_accounts AS accounts
      ON accounts.account_id = assignments.account_id
    WHERE assignments.company_id = companies.company_id
      AND assignments.scope_type = 'company'
      AND assignments.revoked_at IS NULL
      AND roles.role_key = 'company_finance_manager'
      AND accounts.account_status = 'active'
    ORDER BY assignments.account_role_assignment_id
    LIMIT 1
) AS finance_manager
  ON TRUE
LEFT JOIN LATERAL (
    SELECT assignments.account_id
    FROM identity.account_role_assignments AS assignments
    JOIN identity.access_roles AS roles
      ON roles.role_id = assignments.role_id
    JOIN identity.user_accounts AS accounts
      ON accounts.account_id = assignments.account_id
    WHERE assignments.company_id = companies.company_id
      AND assignments.scope_type = 'company'
      AND assignments.revoked_at IS NULL
      AND roles.role_key = 'company_people_manager'
      AND accounts.account_status = 'active'
    ORDER BY assignments.account_role_assignment_id
    LIMIT 1
) AS people_manager
  ON TRUE
LEFT JOIN LATERAL (
    SELECT assignments.account_id
    FROM identity.account_role_assignments AS assignments
    JOIN identity.access_roles AS roles
      ON roles.role_id = assignments.role_id
    JOIN identity.user_accounts AS accounts
      ON accounts.account_id = assignments.account_id
    WHERE assignments.company_id = companies.company_id
      AND assignments.scope_type = 'company'
      AND assignments.revoked_at IS NULL
      AND roles.role_key = 'company_operations_manager'
      AND accounts.account_status = 'active'
    ORDER BY assignments.account_role_assignment_id
    LIMIT 1
) AS operations_manager
  ON TRUE;

CREATE UNIQUE INDEX fixture_workflow_account_context_company_idx
    ON fixture_workflow_account_context (company_id);

-- ============================================================
-- Workflow definition specifications
-- ============================================================

CREATE TEMP TABLE fixture_workflow_definition_specs (
    workflow_key TEXT PRIMARY KEY,
    name TEXT NOT NULL,
    description TEXT NOT NULL,
    workflow_domain TEXT NOT NULL,
    target_entity_schema TEXT NOT NULL,
    target_entity_table TEXT NOT NULL
) ON COMMIT DROP;

INSERT INTO fixture_workflow_definition_specs (
    workflow_key,
    name,
    description,
    workflow_domain,
    target_entity_schema,
    target_entity_table
)
VALUES
    (
        'finance.transaction_approval',
        'Financial transaction approval',
        'Review, authorize, and post material financial transactions before they become authoritative ledger activity.',
        'finance',
        'finance',
        'financial_transactions'
    ),
    (
        'documents.controlled_document_approval',
        'Controlled document approval',
        'Coordinate operational review, compliance review, ownership approval, and controlled publication of business documents.',
        'documents',
        'documents',
        'document_records'
    ),
    (
        'people.employee_onboarding',
        'Employee onboarding',
        'Coordinate account provisioning, organizational setup, manager orientation, and acknowledgement activities for personnel.',
        'people',
        'people',
        'persons'
    ),
    (
        'operations.exception_resolution',
        'Operational exception resolution',
        'Triage, investigate, correct, verify, and close operational exceptions affecting a branch or operating location.',
        'operations',
        'core',
        'branches'
    );

-- ============================================================
-- Deterministic cleanup of fixture-owned workflow records
-- ============================================================

DELETE FROM workflows.workflow_instances AS instances
USING workflows.workflow_definitions AS definitions,
      fixture_workflow_account_context AS context,
      fixture_workflow_definition_specs AS specifications
WHERE instances.workflow_definition_id = definitions.workflow_definition_id
  AND definitions.company_id = context.company_id
  AND definitions.workflow_key = specifications.workflow_key
  AND definitions.version_number = 1;

DELETE FROM workflows.workflow_definitions AS definitions
USING fixture_workflow_account_context AS context,
      fixture_workflow_definition_specs AS specifications
WHERE definitions.company_id = context.company_id
  AND definitions.workflow_key = specifications.workflow_key
  AND definitions.version_number = 1;

-- ============================================================
-- Workflow definitions
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
    is_active,
    created_by_account_id,
    created_at,
    updated_at
)
SELECT
    context.company_id,
    specifications.workflow_key,
    1,
    specifications.name,
    specifications.description,
    specifications.workflow_domain,
    specifications.target_entity_schema,
    specifications.target_entity_table,
    context.archival_date IS NULL,
    context.creator_account_id,
    CASE
        WHEN context.archival_date IS NULL
            THEN TIMESTAMPTZ '2025-01-06 15:00:00+00'
        ELSE TIMESTAMPTZ '2024-01-08 15:00:00+00'
    END,
    CASE
        WHEN context.archival_date IS NULL
            THEN TIMESTAMPTZ '2026-01-05 15:00:00+00'
        ELSE TIMESTAMPTZ '2024-09-30 20:00:00+00'
    END
FROM fixture_workflow_account_context AS context
CROSS JOIN fixture_workflow_definition_specs AS specifications;

-- ============================================================
-- Workflow step specifications
-- ============================================================

CREATE TEMP TABLE fixture_workflow_step_specs (
    workflow_key TEXT NOT NULL,
    step_key TEXT NOT NULL,
    name TEXT NOT NULL,
    description TEXT NOT NULL,
    step_order INTEGER NOT NULL,
    step_type TEXT NOT NULL,
    is_required BOOLEAN NOT NULL,
    assignee_context TEXT NOT NULL,
    default_due_interval INTERVAL,
    PRIMARY KEY (workflow_key, step_key),
    UNIQUE (workflow_key, step_order)
) ON COMMIT DROP;

INSERT INTO fixture_workflow_step_specs (
    workflow_key,
    step_key,
    name,
    description,
    step_order,
    step_type,
    is_required,
    assignee_context,
    default_due_interval
)
VALUES
    -- Financial transaction approval
    ('finance.transaction_approval', 'submitted', 'Submitted', 'The transaction has entered the approval workflow.', 1, 'start', TRUE, 'initiator', NULL),
    ('finance.transaction_approval', 'finance_review', 'Finance review', 'Finance validates classification, supporting evidence, and journal completeness.', 2, 'task', TRUE, 'finance', INTERVAL '1 day'),
    ('finance.transaction_approval', 'management_approval', 'Management approval', 'An authorized company manager approves or returns the transaction.', 3, 'approval', TRUE, 'admin', INTERVAL '2 days'),
    ('finance.transaction_approval', 'posting', 'Ledger posting', 'The approved transaction is posted to the ledger.', 4, 'system', TRUE, 'finance', INTERVAL '4 hours'),
    ('finance.transaction_approval', 'completed', 'Completed', 'The transaction approval workflow has finished.', 5, 'end', TRUE, 'unassigned', NULL),

    -- Controlled document approval
    ('documents.controlled_document_approval', 'draft_submitted', 'Draft submitted', 'A controlled-document draft has been submitted for review.', 1, 'start', TRUE, 'initiator', NULL),
    ('documents.controlled_document_approval', 'operational_review', 'Operational review', 'Operations verifies that the document is practical, complete, and aligned with current processes.', 2, 'task', TRUE, 'operations', INTERVAL '2 days'),
    ('documents.controlled_document_approval', 'compliance_review', 'Compliance review', 'The document is checked for governance, control, and compliance implications.', 3, 'task', TRUE, 'admin', INTERVAL '2 days'),
    ('documents.controlled_document_approval', 'owner_approval', 'Document-owner approval', 'The accountable document owner authorizes publication.', 4, 'approval', TRUE, 'admin', INTERVAL '2 days'),
    ('documents.controlled_document_approval', 'publish', 'Controlled publication', 'The approved version is marked current and released for controlled use.', 5, 'system', TRUE, 'operations', INTERVAL '4 hours'),
    ('documents.controlled_document_approval', 'completed', 'Completed', 'The controlled-document approval workflow has finished.', 6, 'end', TRUE, 'unassigned', NULL),

    -- Employee onboarding
    ('people.employee_onboarding', 'initiated', 'Onboarding initiated', 'The onboarding checklist has been opened for the person.', 1, 'start', TRUE, 'initiator', NULL),
    ('people.employee_onboarding', 'identity_setup', 'Identity and access setup', 'Create or validate the application account and the required access baseline.', 2, 'task', TRUE, 'people', INTERVAL '1 day'),
    ('people.employee_onboarding', 'department_setup', 'Department setup', 'Confirm the organizational assignment, manager, branch, and department context.', 3, 'task', TRUE, 'people', INTERVAL '1 day'),
    ('people.employee_onboarding', 'manager_orientation', 'Manager orientation', 'The operating manager completes role-specific orientation and local onboarding.', 4, 'task', TRUE, 'operations', INTERVAL '3 days'),
    ('people.employee_onboarding', 'employee_acknowledgement', 'Employee acknowledgement', 'The person acknowledges the handbook, policies, and assigned responsibilities.', 5, 'approval', TRUE, 'people', INTERVAL '2 days'),
    ('people.employee_onboarding', 'completed', 'Completed', 'The employee onboarding workflow has finished.', 6, 'end', TRUE, 'unassigned', NULL),

    -- Operational exception resolution
    ('operations.exception_resolution', 'reported', 'Exception reported', 'An operational exception has been recorded for triage.', 1, 'start', TRUE, 'initiator', NULL),
    ('operations.exception_resolution', 'triage', 'Triage', 'Operations assesses severity, immediate containment, and required ownership.', 2, 'task', TRUE, 'operations', INTERVAL '4 hours'),
    ('operations.exception_resolution', 'investigation', 'Investigation', 'The assigned owner determines the cause, impact, and contributing conditions.', 3, 'task', TRUE, 'operations', INTERVAL '2 days'),
    ('operations.exception_resolution', 'corrective_action', 'Corrective action', 'The team implements and documents the agreed remediation.', 4, 'task', TRUE, 'operations', INTERVAL '5 days'),
    ('operations.exception_resolution', 'verification', 'Effectiveness verification', 'Management verifies that the corrective action resolved the exception.', 5, 'approval', TRUE, 'admin', INTERVAL '2 days'),
    ('operations.exception_resolution', 'closed', 'Closed', 'The operational exception has been closed.', 6, 'end', TRUE, 'unassigned', NULL);

-- ============================================================
-- Workflow steps
-- ============================================================

INSERT INTO workflows.workflow_steps (
    workflow_definition_id,
    step_key,
    name,
    description,
    step_order,
    step_type,
    is_required,
    default_assignee_type,
    default_assignee_account_id,
    default_due_interval,
    created_at,
    updated_at
)
SELECT
    definitions.workflow_definition_id,
    specifications.step_key,
    specifications.name,
    specifications.description,
    specifications.step_order,
    specifications.step_type,
    specifications.is_required,
    CASE
        WHEN specifications.assignee_context = 'initiator' THEN 'initiator'
        WHEN specifications.assignee_context = 'unassigned' THEN 'unassigned'
        ELSE 'specific_account'
    END,
    CASE specifications.assignee_context
        WHEN 'admin' THEN context.admin_account_id
        WHEN 'finance' THEN context.finance_account_id
        WHEN 'people' THEN context.people_account_id
        WHEN 'operations' THEN context.operations_account_id
        ELSE NULL::BIGINT
    END,
    specifications.default_due_interval,
    definitions.created_at,
    definitions.updated_at
FROM workflows.workflow_definitions AS definitions
JOIN fixture_workflow_account_context AS context
  ON context.company_id = definitions.company_id
JOIN fixture_workflow_step_specs AS specifications
  ON specifications.workflow_key = definitions.workflow_key
WHERE definitions.version_number = 1;

-- ============================================================
-- Workflow transition specifications
-- ============================================================

CREATE TEMP TABLE fixture_workflow_transition_specs (
    workflow_key TEXT NOT NULL,
    transition_key TEXT NOT NULL,
    from_step_key TEXT,
    to_step_key TEXT NOT NULL,
    name TEXT NOT NULL,
    outcome_value TEXT,
    condition_expression TEXT,
    sort_order INTEGER NOT NULL,
    PRIMARY KEY (workflow_key, transition_key)
) ON COMMIT DROP;

INSERT INTO fixture_workflow_transition_specs (
    workflow_key,
    transition_key,
    from_step_key,
    to_step_key,
    name,
    outcome_value,
    condition_expression,
    sort_order
)
VALUES
    -- Financial transaction approval
    ('finance.transaction_approval', 'begin', NULL, 'submitted', 'Begin workflow', 'started', NULL, 1),
    ('finance.transaction_approval', 'submit_for_review', 'submitted', 'finance_review', 'Submit for finance review', 'submitted', NULL, 1),
    ('finance.transaction_approval', 'send_for_approval', 'finance_review', 'management_approval', 'Send for management approval', 'reviewed', 'finance_review_outcome = ''accepted''', 1),
    ('finance.transaction_approval', 'return_for_correction', 'finance_review', 'submitted', 'Return for correction', 'changes_requested', 'finance_review_outcome = ''changes_requested''', 2),
    ('finance.transaction_approval', 'approve', 'management_approval', 'posting', 'Approve transaction', 'approved', 'management_outcome = ''approved''', 1),
    ('finance.transaction_approval', 'request_changes', 'management_approval', 'finance_review', 'Request finance changes', 'changes_requested', 'management_outcome = ''changes_requested''', 2),
    ('finance.transaction_approval', 'post', 'posting', 'completed', 'Post and complete', 'posted', NULL, 1),

    -- Controlled document approval
    ('documents.controlled_document_approval', 'begin', NULL, 'draft_submitted', 'Begin workflow', 'started', NULL, 1),
    ('documents.controlled_document_approval', 'route_operational_review', 'draft_submitted', 'operational_review', 'Route to operational review', 'submitted', NULL, 1),
    ('documents.controlled_document_approval', 'request_draft_revision', 'operational_review', 'draft_submitted', 'Request draft revision', 'changes_requested', 'operational_review_outcome = ''changes_requested''', 2),
    ('documents.controlled_document_approval', 'route_compliance_review', 'operational_review', 'compliance_review', 'Route to compliance review', 'accepted', 'operational_review_outcome = ''accepted''', 1),
    ('documents.controlled_document_approval', 'return_to_operations', 'compliance_review', 'operational_review', 'Return to operations', 'changes_requested', 'compliance_review_outcome = ''changes_requested''', 2),
    ('documents.controlled_document_approval', 'route_owner_approval', 'compliance_review', 'owner_approval', 'Route to owner approval', 'accepted', 'compliance_review_outcome = ''accepted''', 1),
    ('documents.controlled_document_approval', 'owner_requests_changes', 'owner_approval', 'operational_review', 'Owner requests changes', 'changes_requested', 'owner_outcome = ''changes_requested''', 2),
    ('documents.controlled_document_approval', 'approve_for_publication', 'owner_approval', 'publish', 'Approve for publication', 'approved', 'owner_outcome = ''approved''', 1),
    ('documents.controlled_document_approval', 'publish_document', 'publish', 'completed', 'Publish and complete', 'published', NULL, 1),

    -- Employee onboarding
    ('people.employee_onboarding', 'begin', NULL, 'initiated', 'Begin workflow', 'started', NULL, 1),
    ('people.employee_onboarding', 'create_identity', 'initiated', 'identity_setup', 'Start identity setup', 'started', NULL, 1),
    ('people.employee_onboarding', 'configure_department', 'identity_setup', 'department_setup', 'Configure organizational context', 'identity_ready', NULL, 1),
    ('people.employee_onboarding', 'return_to_identity_setup', 'department_setup', 'identity_setup', 'Return to identity setup', 'changes_requested', 'department_setup_outcome = ''identity_changes_required''', 2),
    ('people.employee_onboarding', 'schedule_orientation', 'department_setup', 'manager_orientation', 'Schedule manager orientation', 'organization_ready', NULL, 1),
    ('people.employee_onboarding', 'collect_acknowledgement', 'manager_orientation', 'employee_acknowledgement', 'Collect employee acknowledgement', 'orientation_complete', NULL, 1),
    ('people.employee_onboarding', 'complete_onboarding', 'employee_acknowledgement', 'completed', 'Complete onboarding', 'acknowledged', NULL, 1),

    -- Operational exception resolution
    ('operations.exception_resolution', 'begin', NULL, 'reported', 'Begin workflow', 'reported', NULL, 1),
    ('operations.exception_resolution', 'triage_report', 'reported', 'triage', 'Triage reported exception', 'triaged', NULL, 1),
    ('operations.exception_resolution', 'open_investigation', 'triage', 'investigation', 'Open investigation', 'investigation_required', NULL, 1),
    ('operations.exception_resolution', 'define_corrective_action', 'investigation', 'corrective_action', 'Define corrective action', 'cause_confirmed', NULL, 1),
    ('operations.exception_resolution', 'return_to_investigation', 'corrective_action', 'investigation', 'Return to investigation', 'more_analysis_required', 'corrective_action_outcome = ''insufficient_evidence''', 2),
    ('operations.exception_resolution', 'submit_for_verification', 'corrective_action', 'verification', 'Submit for effectiveness verification', 'implemented', NULL, 1),
    ('operations.exception_resolution', 'reopen_corrective_action', 'verification', 'corrective_action', 'Reopen corrective action', 'ineffective', 'verification_outcome = ''ineffective''', 2),
    ('operations.exception_resolution', 'close_exception', 'verification', 'closed', 'Close exception', 'verified', 'verification_outcome = ''effective''', 1);

-- ============================================================
-- Workflow transitions
-- ============================================================

INSERT INTO workflows.workflow_transitions (
    workflow_definition_id,
    from_step_id,
    to_step_id,
    transition_key,
    name,
    outcome_value,
    condition_expression,
    sort_order,
    created_at
)
SELECT
    definitions.workflow_definition_id,
    from_steps.workflow_step_id,
    to_steps.workflow_step_id,
    specifications.transition_key,
    specifications.name,
    specifications.outcome_value,
    specifications.condition_expression,
    specifications.sort_order,
    definitions.created_at
FROM workflows.workflow_definitions AS definitions
JOIN fixture_workflow_transition_specs AS specifications
  ON specifications.workflow_key = definitions.workflow_key
LEFT JOIN workflows.workflow_steps AS from_steps
  ON from_steps.workflow_definition_id = definitions.workflow_definition_id
 AND from_steps.step_key = specifications.from_step_key
JOIN workflows.workflow_steps AS to_steps
  ON to_steps.workflow_definition_id = definitions.workflow_definition_id
 AND to_steps.step_key = specifications.to_step_key
JOIN fixture_workflow_account_context AS context
  ON context.company_id = definitions.company_id
WHERE definitions.version_number = 1;

-- ============================================================
-- Workflow instance specifications
-- ============================================================

CREATE TEMP TABLE fixture_workflow_instance_specs (
    instance_key TEXT PRIMARY KEY,
    company_slug TEXT NOT NULL,
    workflow_key TEXT NOT NULL,
    title TEXT NOT NULL,
    subject_entity_schema TEXT NOT NULL,
    subject_entity_table TEXT NOT NULL,
    subject_business_key TEXT NOT NULL,
    status TEXT NOT NULL,
    current_step_key TEXT NOT NULL,
    started_by_context TEXT NOT NULL,
    started_at TIMESTAMPTZ NOT NULL,
    completed_offset INTERVAL,
    cancelled_offset INTERVAL,
    scenario_key TEXT NOT NULL,
    metadata JSONB NOT NULL
) ON COMMIT DROP;

-- Active-company examples.
INSERT INTO fixture_workflow_instance_specs (
    instance_key,
    company_slug,
    workflow_key,
    title,
    subject_entity_schema,
    subject_entity_table,
    subject_business_key,
    status,
    current_step_key,
    started_by_context,
    started_at,
    completed_offset,
    cancelled_offset,
    scenario_key,
    metadata
)
SELECT
    context.company_slug || ':' || specifications.instance_suffix,
    context.company_slug,
    specifications.workflow_key,
    specifications.title,
    specifications.subject_entity_schema,
    specifications.subject_entity_table,
    specifications.subject_business_key,
    specifications.status,
    specifications.current_step_key,
    specifications.started_by_context,
    specifications.started_at,
    specifications.completed_offset,
    specifications.cancelled_offset,
    specifications.scenario_key,
    jsonb_build_object(
        'fixture', 'realistic_multi_company',
        'scenario', specifications.scenario_key,
        'company_prefix', context.workflow_prefix,
        'business_key', specifications.subject_business_key
    )
FROM fixture_workflow_account_context AS context
CROSS JOIN LATERAL (
    VALUES
        (
            'finance_completed',
            'finance.transaction_approval',
            context.company_label || ' June 2026 operating-expense approval',
            'finance',
            'financial_transactions',
            context.representative_posted_transaction_number,
            'completed',
            'completed',
            'finance',
            TIMESTAMPTZ '2026-06-12 14:00:00+00',
            INTERVAL '31 hours',
            NULL::INTERVAL,
            'finance_completed'
        ),
        (
            'finance_current',
            'finance.transaction_approval',
            context.company_label || ' July 2026 budget-adjustment approval',
            'finance',
            'financial_transactions',
            context.representative_draft_transaction_number,
            'running',
            'management_approval',
            'finance',
            TIMESTAMPTZ '2026-07-08 14:00:00+00',
            NULL::INTERVAL,
            NULL::INTERVAL,
            'finance_running'
        ),
        (
            'document_completed',
            'documents.controlled_document_approval',
            context.company_label || ' primary operating procedure approval',
            'documents',
            'document_records',
            context.completed_document_number,
            'completed',
            'completed',
            'operations',
            TIMESTAMPTZ '2026-02-10 15:00:00+00',
            INTERVAL '74 hours',
            NULL::INTERVAL,
            'document_completed'
        ),
        (
            'document_current',
            'documents.controlled_document_approval',
            context.company_label || ' business continuity policy approval',
            'documents',
            'document_records',
            context.draft_document_number,
            'running',
            'owner_approval',
            'operations',
            TIMESTAMPTZ '2026-07-04 15:00:00+00',
            NULL::INTERVAL,
            NULL::INTERVAL,
            'document_running'
        ),
        (
            'onboarding_completed',
            'people.employee_onboarding',
            context.company_label || ' completed employee onboarding',
            'people',
            'persons',
            context.completed_onboarding_person_external_reference,
            'completed',
            'completed',
            'people',
            TIMESTAMPTZ '2026-05-04 14:00:00+00',
            INTERVAL '100 hours',
            NULL::INTERVAL,
            'onboarding_completed'
        ),
        (
            'onboarding_draft',
            'people.employee_onboarding',
            context.company_label || ' draft internal-transfer onboarding plan',
            'people',
            'persons',
            context.draft_onboarding_person_external_reference,
            'draft',
            'initiated',
            'people',
            TIMESTAMPTZ '2026-07-11 14:00:00+00',
            NULL::INTERVAL,
            NULL::INTERVAL,
            'onboarding_draft'
        ),
        (
            'operations_current',
            'operations.exception_resolution',
            context.company_label || ' operating-location exception resolution',
            'core',
            'branches',
            context.operations_branch_code,
            context.operations_status,
            context.operations_current_step_key,
            'operations',
            TIMESTAMPTZ '2026-07-06 13:00:00+00',
            context.operations_completed_offset,
            NULL::INTERVAL,
            context.operations_scenario_key
        )
) AS specifications (
    instance_suffix,
    workflow_key,
    title,
    subject_entity_schema,
    subject_entity_table,
    subject_business_key,
    status,
    current_step_key,
    started_by_context,
    started_at,
    completed_offset,
    cancelled_offset,
    scenario_key
)
WHERE context.archival_date IS NULL;

-- Historical examples for the archived company.
INSERT INTO fixture_workflow_instance_specs (
    instance_key,
    company_slug,
    workflow_key,
    title,
    subject_entity_schema,
    subject_entity_table,
    subject_business_key,
    status,
    current_step_key,
    started_by_context,
    started_at,
    completed_offset,
    cancelled_offset,
    scenario_key,
    metadata
)
SELECT
    context.company_slug || ':' || specifications.instance_suffix,
    context.company_slug,
    specifications.workflow_key,
    specifications.title,
    specifications.subject_entity_schema,
    specifications.subject_entity_table,
    specifications.subject_business_key,
    specifications.status,
    specifications.current_step_key,
    specifications.started_by_context,
    specifications.started_at,
    specifications.completed_offset,
    specifications.cancelled_offset,
    specifications.scenario_key,
    jsonb_build_object(
        'fixture', 'realistic_multi_company',
        'scenario', specifications.scenario_key,
        'historical', TRUE,
        'company_prefix', context.workflow_prefix,
        'business_key', specifications.subject_business_key
    )
FROM fixture_workflow_account_context AS context
CROSS JOIN LATERAL (
    VALUES
        (
            'finance_completed',
            'finance.transaction_approval',
            context.company_label || ' September 2024 operating-expense approval',
            'finance',
            'financial_transactions',
            context.representative_posted_transaction_number,
            'completed',
            'completed',
            'finance',
            TIMESTAMPTZ '2024-09-05 14:00:00+00',
            INTERVAL '31 hours',
            NULL::INTERVAL,
            'finance_completed'
        ),
        (
            'document_completed',
            'documents.controlled_document_approval',
            context.company_label || ' operating procedure approval',
            'documents',
            'document_records',
            context.completed_document_number,
            'completed',
            'completed',
            'operations',
            TIMESTAMPTZ '2024-07-08 15:00:00+00',
            INTERVAL '74 hours',
            NULL::INTERVAL,
            'document_completed'
        ),
        (
            'onboarding_cancelled',
            'people.employee_onboarding',
            context.company_label || ' cancelled employee onboarding',
            'people',
            'persons',
            context.completed_onboarding_person_external_reference,
            'cancelled',
            'identity_setup',
            'people',
            TIMESTAMPTZ '2024-09-18 14:00:00+00',
            NULL::INTERVAL,
            INTERVAL '4 hours',
            'onboarding_cancelled'
        ),
        (
            'operations_completed',
            'operations.exception_resolution',
            context.company_label || ' distribution-centre exception resolution',
            'core',
            'branches',
            context.operations_branch_code,
            'completed',
            'closed',
            'operations',
            TIMESTAMPTZ '2024-08-12 13:00:00+00',
            INTERVAL '120 hours',
            NULL::INTERVAL,
            'operations_completed'
        )
) AS specifications (
    instance_suffix,
    workflow_key,
    title,
    subject_entity_schema,
    subject_entity_table,
    subject_business_key,
    status,
    current_step_key,
    started_by_context,
    started_at,
    completed_offset,
    cancelled_offset,
    scenario_key
)
WHERE context.archival_date IS NOT NULL;

-- ============================================================
-- Resolve instance specifications to generated identities
-- ============================================================

CREATE TEMP TABLE fixture_resolved_workflow_instances
ON COMMIT DROP
AS
SELECT
    specifications.*,
    context.company_id,
    definitions.workflow_definition_id,
    current_steps.workflow_step_id AS current_step_id,
    CASE specifications.started_by_context
        WHEN 'admin' THEN context.admin_account_id
        WHEN 'finance' THEN context.finance_account_id
        WHEN 'people' THEN context.people_account_id
        WHEN 'operations' THEN context.operations_account_id
        ELSE context.creator_account_id
    END AS started_by_account_id,
    CASE
        WHEN specifications.subject_entity_schema = 'finance'
         AND specifications.subject_entity_table = 'financial_transactions'
            THEN (
                SELECT transactions.transaction_id
                FROM finance.financial_transactions AS transactions
                WHERE transactions.company_id = context.company_id
                  AND transactions.transaction_number =
                      specifications.subject_business_key
            )
        WHEN specifications.subject_entity_schema = 'documents'
         AND specifications.subject_entity_table = 'document_records'
            THEN (
                SELECT document_records.document_id
                FROM documents.document_records AS document_records
                WHERE document_records.company_id = context.company_id
                  AND document_records.document_number =
                      specifications.subject_business_key
            )
        WHEN specifications.subject_entity_schema = 'people'
         AND specifications.subject_entity_table = 'persons'
            THEN (
                SELECT persons.person_id
                FROM people.persons AS persons
                WHERE persons.company_id = context.company_id
                  AND persons.external_reference =
                      specifications.subject_business_key
            )
        WHEN specifications.subject_entity_schema = 'core'
         AND specifications.subject_entity_table = 'branches'
            THEN (
                SELECT branches.branch_id
                FROM core.branches AS branches
                WHERE branches.company_id = context.company_id
                  AND branches.branch_code =
                      specifications.subject_business_key
            )
        ELSE NULL::BIGINT
    END AS subject_entity_id
FROM fixture_workflow_instance_specs AS specifications
JOIN fixture_workflow_account_context AS context
  ON context.company_slug = specifications.company_slug
JOIN workflows.workflow_definitions AS definitions
  ON definitions.company_id = context.company_id
 AND definitions.workflow_key = specifications.workflow_key
 AND definitions.version_number = 1
JOIN workflows.workflow_steps AS current_steps
  ON current_steps.workflow_definition_id = definitions.workflow_definition_id
 AND current_steps.step_key = specifications.current_step_key;

CREATE UNIQUE INDEX fixture_resolved_workflow_instances_key_idx
    ON fixture_resolved_workflow_instances (instance_key);

DO $$
BEGIN
    IF EXISTS (
        SELECT 1
        FROM fixture_resolved_workflow_instances
        WHERE subject_entity_id IS NULL
           OR started_by_account_id IS NULL
           OR current_step_id IS NULL
    ) THEN
        RAISE EXCEPTION
            '07_workflows.sql could not resolve one or more instance subjects, starters, or current steps.';
    END IF;
END;
$$;

-- ============================================================
-- Workflow instances
-- ============================================================

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
    started_at,
    completed_at,
    cancelled_at,
    metadata,
    created_at,
    updated_at
)
SELECT
    specifications.company_id,
    specifications.workflow_definition_id,
    specifications.current_step_id,
    specifications.title,
    specifications.subject_entity_schema,
    specifications.subject_entity_table,
    specifications.subject_entity_id,
    specifications.status,
    specifications.started_by_account_id,
    specifications.started_at,
    CASE
        WHEN specifications.completed_offset IS NOT NULL
            THEN specifications.started_at + specifications.completed_offset
        ELSE NULL::TIMESTAMPTZ
    END,
    CASE
        WHEN specifications.cancelled_offset IS NOT NULL
            THEN specifications.started_at + specifications.cancelled_offset
        ELSE NULL::TIMESTAMPTZ
    END,
    specifications.metadata,
    specifications.started_at,
    COALESCE(
        specifications.started_at + specifications.completed_offset,
        specifications.started_at + specifications.cancelled_offset,
        specifications.started_at +
            CASE specifications.scenario_key
                WHEN 'finance_running' THEN INTERVAL '9 hours'
                WHEN 'document_running' THEN INTERVAL '47 hours'
                WHEN 'onboarding_draft' THEN INTERVAL '0 hours'
                WHEN 'operations_running' THEN INTERVAL '32 hours'
                WHEN 'operations_paused' THEN INTERVAL '30 hours'
                WHEN 'operations_failed' THEN INTERVAL '78 hours'
                ELSE INTERVAL '0 hours'
            END
    )
FROM fixture_resolved_workflow_instances AS specifications;

CREATE TEMP TABLE fixture_loaded_workflow_instances
ON COMMIT DROP
AS
SELECT
    specifications.*,
    instances.workflow_instance_id
FROM fixture_resolved_workflow_instances AS specifications
JOIN workflows.workflow_instances AS instances
  ON instances.company_id = specifications.company_id
 AND instances.workflow_definition_id = specifications.workflow_definition_id
 AND instances.title = specifications.title
 AND instances.subject_entity_schema = specifications.subject_entity_schema
 AND instances.subject_entity_table = specifications.subject_entity_table
 AND instances.subject_entity_id = specifications.subject_entity_id;

CREATE UNIQUE INDEX fixture_loaded_workflow_instances_key_idx
    ON fixture_loaded_workflow_instances (instance_key);

-- ============================================================
-- Workflow task specifications
-- ============================================================

CREATE TEMP TABLE fixture_workflow_task_specs (
    scenario_key TEXT NOT NULL,
    task_sequence INTEGER NOT NULL,
    step_key TEXT NOT NULL,
    task_key TEXT NOT NULL,
    title TEXT NOT NULL,
    description TEXT NOT NULL,
    status TEXT NOT NULL,
    priority TEXT NOT NULL,
    assignee_context TEXT NOT NULL,
    candidate_role_key TEXT NOT NULL,
    created_offset INTERVAL NOT NULL,
    due_offset INTERVAL,
    completed_offset INTERVAL,
    PRIMARY KEY (scenario_key, task_key),
    UNIQUE (scenario_key, task_sequence)
) ON COMMIT DROP;

INSERT INTO fixture_workflow_task_specs (
    scenario_key,
    task_sequence,
    step_key,
    task_key,
    title,
    description,
    status,
    priority,
    assignee_context,
    candidate_role_key,
    created_offset,
    due_offset,
    completed_offset
)
VALUES
    -- Completed financial approval
    ('finance_completed', 1, 'finance_review', 'finance_review', 'Validate transaction and supporting evidence', 'Review account classification, cost-centre attribution, evidence, and journal completeness.', 'completed', 'normal', 'finance', 'company_finance_manager', INTERVAL '1 hour', INTERVAL '24 hours', INTERVAL '8 hours'),
    ('finance_completed', 2, 'management_approval', 'management_approval', 'Authorize financial transaction', 'Confirm business purpose, authority, and materiality before posting.', 'completed', 'high', 'admin', 'company_admin', INTERVAL '9 hours', INTERVAL '48 hours', INTERVAL '29 hours'),
    ('finance_completed', 3, 'posting', 'posting', 'Post approved transaction', 'Post the approved journal and confirm its authoritative ledger status.', 'completed', 'normal', 'finance', 'company_finance_manager', INTERVAL '30 hours', INTERVAL '34 hours', INTERVAL '31 hours'),

    -- Running financial approval
    ('finance_running', 1, 'finance_review', 'finance_review', 'Validate draft budget adjustment', 'Review the proposed budget reclassification and complete the supporting journal detail.', 'completed', 'high', 'finance', 'company_finance_manager', INTERVAL '1 hour', INTERVAL '24 hours', INTERVAL '8 hours'),
    ('finance_running', 2, 'management_approval', 'management_approval', 'Approve draft budget adjustment', 'Approve or return the reviewed budget adjustment before ledger posting.', 'in_progress', 'high', 'admin', 'company_admin', INTERVAL '9 hours', INTERVAL '72 hours', NULL),

    -- Completed controlled-document approval
    ('document_completed', 1, 'operational_review', 'operational_review', 'Review operating procedure', 'Validate the procedure against actual operating practice and branch responsibilities.', 'completed', 'normal', 'operations', 'company_operations_manager', INTERVAL '2 hours', INTERVAL '48 hours', INTERVAL '18 hours'),
    ('document_completed', 2, 'compliance_review', 'compliance_review', 'Review procedure controls', 'Check governance, control ownership, retention, and compliance implications.', 'completed', 'normal', 'admin', 'company_admin', INTERVAL '20 hours', INTERVAL '68 hours', INTERVAL '42 hours'),
    ('document_completed', 3, 'owner_approval', 'owner_approval', 'Approve operating procedure', 'Authorize the reviewed procedure as the controlled operating standard.', 'completed', 'high', 'admin', 'company_admin', INTERVAL '44 hours', INTERVAL '92 hours', INTERVAL '70 hours'),
    ('document_completed', 4, 'publish', 'publish', 'Publish approved procedure', 'Mark the approved version current and release it for controlled use.', 'completed', 'normal', 'operations', 'company_operations_manager', INTERVAL '71 hours', INTERVAL '75 hours', INTERVAL '74 hours'),

    -- Running controlled-document approval
    ('document_running', 1, 'operational_review', 'operational_review', 'Review business continuity policy', 'Validate operating responsibilities, recovery assumptions, and branch-level applicability.', 'completed', 'high', 'operations', 'company_operations_manager', INTERVAL '2 hours', INTERVAL '48 hours', INTERVAL '20 hours'),
    ('document_running', 2, 'compliance_review', 'compliance_review', 'Review continuity governance', 'Check policy ownership, control language, escalation, and review cadence.', 'completed', 'high', 'admin', 'company_admin', INTERVAL '21 hours', INTERVAL '72 hours', INTERVAL '46 hours'),
    ('document_running', 3, 'owner_approval', 'owner_approval', 'Approve business continuity policy', 'Approve the reviewed policy or return it for additional operational changes.', 'open', 'urgent', 'admin', 'company_admin', INTERVAL '47 hours', INTERVAL '240 hours', NULL),

    -- Completed onboarding
    ('onboarding_completed', 1, 'identity_setup', 'identity_setup', 'Provision identity and baseline access', 'Create the account, authentication identity, and least-privilege access baseline.', 'completed', 'high', 'people', 'company_people_manager', INTERVAL '1 hour', INTERVAL '24 hours', INTERVAL '12 hours'),
    ('onboarding_completed', 2, 'department_setup', 'department_setup', 'Confirm organizational placement', 'Validate company role, branch, department, manager, and effective dates.', 'completed', 'normal', 'people', 'company_people_manager', INTERVAL '13 hours', INTERVAL '36 hours', INTERVAL '28 hours'),
    ('onboarding_completed', 3, 'manager_orientation', 'manager_orientation', 'Complete manager orientation', 'Review role expectations, operating procedures, objectives, and local escalation paths.', 'completed', 'normal', 'operations', 'company_operations_manager', INTERVAL '30 hours', INTERVAL '78 hours', INTERVAL '72 hours'),
    ('onboarding_completed', 4, 'employee_acknowledgement', 'employee_acknowledgement', 'Record employee acknowledgement', 'Confirm acknowledgement of the handbook, security policy, and assigned responsibilities.', 'completed', 'normal', 'people', 'company_people_manager', INTERVAL '74 hours', INTERVAL '100 hours', INTERVAL '100 hours'),

    -- Cancelled onboarding
    ('onboarding_cancelled', 1, 'identity_setup', 'identity_setup', 'Provision identity and baseline access', 'Prepare the account and access baseline before the onboarding request is cancelled.', 'cancelled', 'normal', 'people', 'company_people_manager', INTERVAL '1 hour', INTERVAL '24 hours', NULL),

    -- Running operational exception
    ('operations_running', 1, 'triage', 'triage', 'Triage operating-location exception', 'Assess severity, containment, business impact, and required ownership.', 'completed', 'urgent', 'operations', 'company_operations_manager', INTERVAL '30 minutes', INTERVAL '4 hours', INTERVAL '2 hours'),
    ('operations_running', 2, 'investigation', 'investigation', 'Investigate operating-location exception', 'Determine the cause, affected process, and contributing operating conditions.', 'completed', 'high', 'operations', 'company_operations_manager', INTERVAL '3 hours', INTERVAL '48 hours', INTERVAL '31 hours'),
    ('operations_running', 3, 'corrective_action', 'corrective_action', 'Implement corrective action', 'Implement, document, and evidence the agreed remediation.', 'in_progress', 'high', 'operations', 'company_operations_manager', INTERVAL '32 hours', INTERVAL '168 hours', NULL),

    -- Paused operational exception
    ('operations_paused', 1, 'triage', 'triage', 'Triage operating-location exception', 'Assess severity, containment, business impact, and required ownership.', 'completed', 'urgent', 'operations', 'company_operations_manager', INTERVAL '30 minutes', INTERVAL '4 hours', INTERVAL '2 hours'),
    ('operations_paused', 2, 'investigation', 'investigation', 'Investigate operating-location exception', 'Complete the investigation after required external evidence becomes available.', 'blocked', 'high', 'operations', 'company_operations_manager', INTERVAL '3 hours', INTERVAL '72 hours', NULL),

    -- Failed operational exception
    ('operations_failed', 1, 'triage', 'triage', 'Triage operating-location exception', 'Assess severity, containment, business impact, and required ownership.', 'completed', 'urgent', 'operations', 'company_operations_manager', INTERVAL '30 minutes', INTERVAL '4 hours', INTERVAL '2 hours'),
    ('operations_failed', 2, 'investigation', 'investigation', 'Investigate operating-location exception', 'Determine the cause, affected process, and contributing operating conditions.', 'completed', 'high', 'operations', 'company_operations_manager', INTERVAL '3 hours', INTERVAL '48 hours', INTERVAL '28 hours'),
    ('operations_failed', 3, 'corrective_action', 'corrective_action', 'Implement corrective action', 'Implement and document the agreed remediation before verification.', 'completed', 'high', 'operations', 'company_operations_manager', INTERVAL '29 hours', INTERVAL '120 hours', INTERVAL '70 hours'),
    ('operations_failed', 4, 'verification', 'verification', 'Verify corrective-action effectiveness', 'Verify that the corrective action produced the required operating result.', 'failed', 'urgent', 'admin', 'company_admin', INTERVAL '71 hours', INTERVAL '96 hours', INTERVAL '78 hours'),

    -- Completed operational exception
    ('operations_completed', 1, 'triage', 'triage', 'Triage operating-location exception', 'Assess severity, containment, business impact, and required ownership.', 'completed', 'urgent', 'operations', 'company_operations_manager', INTERVAL '30 minutes', INTERVAL '4 hours', INTERVAL '2 hours'),
    ('operations_completed', 2, 'investigation', 'investigation', 'Investigate operating-location exception', 'Determine the cause, affected process, and contributing operating conditions.', 'completed', 'high', 'operations', 'company_operations_manager', INTERVAL '3 hours', INTERVAL '48 hours', INTERVAL '30 hours'),
    ('operations_completed', 3, 'corrective_action', 'corrective_action', 'Implement corrective action', 'Implement and document the agreed remediation before verification.', 'completed', 'high', 'operations', 'company_operations_manager', INTERVAL '31 hours', INTERVAL '120 hours', INTERVAL '82 hours'),
    ('operations_completed', 4, 'verification', 'verification', 'Verify corrective-action effectiveness', 'Confirm that the remediation is effective and authorize closure.', 'completed', 'high', 'admin', 'company_admin', INTERVAL '83 hours', INTERVAL '120 hours', INTERVAL '120 hours');

-- ============================================================
-- Workflow tasks
-- ============================================================

INSERT INTO workflows.workflow_tasks (
    company_id,
    workflow_instance_id,
    workflow_definition_id,
    workflow_step_id,
    title,
    description,
    status,
    priority,
    assigned_to_account_id,
    due_at,
    completed_by_account_id,
    completed_at,
    metadata,
    created_at,
    updated_at
)
SELECT
    instances.company_id,
    instances.workflow_instance_id,
    instances.workflow_definition_id,
    steps.workflow_step_id,
    specifications.title,
    specifications.description,
    specifications.status,
    specifications.priority,
    CASE specifications.assignee_context
        WHEN 'admin' THEN context.admin_account_id
        WHEN 'finance' THEN context.finance_account_id
        WHEN 'people' THEN context.people_account_id
        WHEN 'operations' THEN context.operations_account_id
        ELSE context.creator_account_id
    END,
    CASE
        WHEN specifications.due_offset IS NOT NULL
            THEN instances.started_at + specifications.due_offset
        ELSE NULL::TIMESTAMPTZ
    END,
    CASE
        WHEN specifications.status IN ('completed', 'failed') THEN
            CASE specifications.assignee_context
                WHEN 'admin' THEN context.admin_account_id
                WHEN 'finance' THEN context.finance_account_id
                WHEN 'people' THEN context.people_account_id
                WHEN 'operations' THEN context.operations_account_id
                ELSE context.creator_account_id
            END
        ELSE NULL::BIGINT
    END,
    CASE
        WHEN specifications.completed_offset IS NOT NULL
            THEN instances.started_at + specifications.completed_offset
        ELSE NULL::TIMESTAMPTZ
    END,
    jsonb_build_object(
        'fixture', 'realistic_multi_company',
        'instance_key', instances.instance_key,
        'task_key', specifications.task_key,
        'candidate_role_key', specifications.candidate_role_key,
        'sequence', specifications.task_sequence
    ),
    instances.started_at + specifications.created_offset,
    COALESCE(
        instances.started_at + specifications.completed_offset,
        instances.started_at + specifications.created_offset
    )
FROM fixture_loaded_workflow_instances AS instances
JOIN fixture_workflow_task_specs AS specifications
  ON specifications.scenario_key = instances.scenario_key
JOIN workflows.workflow_steps AS steps
  ON steps.workflow_definition_id = instances.workflow_definition_id
 AND steps.step_key = specifications.step_key
JOIN fixture_workflow_account_context AS context
  ON context.company_id = instances.company_id;

CREATE TEMP TABLE fixture_loaded_workflow_tasks
ON COMMIT DROP
AS
SELECT
    instances.instance_key,
    instances.company_id,
    instances.workflow_instance_id,
    instances.workflow_definition_id,
    instances.started_by_account_id,
    specifications.scenario_key,
    specifications.task_sequence,
    specifications.task_key,
    specifications.step_key,
    specifications.candidate_role_key,
    specifications.status AS fixture_task_status,
    tasks.workflow_task_id,
    tasks.assigned_to_account_id,
    tasks.created_at AS task_created_at
FROM fixture_loaded_workflow_instances AS instances
JOIN fixture_workflow_task_specs AS specifications
  ON specifications.scenario_key = instances.scenario_key
JOIN workflows.workflow_steps AS steps
  ON steps.workflow_definition_id = instances.workflow_definition_id
 AND steps.step_key = specifications.step_key
JOIN workflows.workflow_tasks AS tasks
  ON tasks.company_id = instances.company_id
 AND tasks.workflow_instance_id = instances.workflow_instance_id
 AND tasks.workflow_definition_id = instances.workflow_definition_id
 AND tasks.workflow_step_id = steps.workflow_step_id
 AND tasks.title = specifications.title;

CREATE UNIQUE INDEX fixture_loaded_workflow_tasks_key_idx
    ON fixture_loaded_workflow_tasks (instance_key, task_key);

-- ============================================================
-- Task assignments
-- ============================================================

-- Every task receives an explicit account owner.
INSERT INTO workflows.workflow_task_assignments (
    company_id,
    workflow_task_id,
    assignment_type,
    account_id,
    role_id,
    assigned_by_account_id,
    assigned_at
)
SELECT
    tasks.company_id,
    tasks.workflow_task_id,
    'owner',
    tasks.assigned_to_account_id,
    NULL::BIGINT,
    tasks.started_by_account_id,
    tasks.task_created_at
FROM fixture_loaded_workflow_tasks AS tasks;

-- Active work also exposes the appropriate role as a candidate
-- pool, demonstrating role-targeted task assignment.
INSERT INTO workflows.workflow_task_assignments (
    company_id,
    workflow_task_id,
    assignment_type,
    account_id,
    role_id,
    assigned_by_account_id,
    assigned_at
)
SELECT
    tasks.company_id,
    tasks.workflow_task_id,
    'candidate',
    NULL::BIGINT,
    roles.role_id,
    tasks.started_by_account_id,
    tasks.task_created_at
FROM fixture_loaded_workflow_tasks AS tasks
JOIN identity.access_roles AS roles
  ON roles.role_key = tasks.candidate_role_key
WHERE tasks.fixture_task_status IN ('open', 'in_progress', 'blocked');

-- Approval tasks retain the company-administrator role as a
-- reviewer assignment, including completed historical examples.
INSERT INTO workflows.workflow_task_assignments (
    company_id,
    workflow_task_id,
    assignment_type,
    account_id,
    role_id,
    assigned_by_account_id,
    assigned_at
)
SELECT
    tasks.company_id,
    tasks.workflow_task_id,
    'reviewer',
    NULL::BIGINT,
    roles.role_id,
    tasks.started_by_account_id,
    tasks.task_created_at + INTERVAL '15 minutes'
FROM fixture_loaded_workflow_tasks AS tasks
JOIN workflows.workflow_steps AS steps
  ON steps.workflow_definition_id = tasks.workflow_definition_id
 AND steps.step_key = tasks.step_key
JOIN identity.access_roles AS roles
  ON roles.role_key = 'company_admin'
WHERE steps.step_type = 'approval';

-- Blocked and failed tasks expose the initiating account as an
-- observer so escalated work is visible outside the direct owner.
INSERT INTO workflows.workflow_task_assignments (
    company_id,
    workflow_task_id,
    assignment_type,
    account_id,
    role_id,
    assigned_by_account_id,
    assigned_at
)
SELECT
    tasks.company_id,
    tasks.workflow_task_id,
    'observer',
    tasks.started_by_account_id,
    NULL::BIGINT,
    tasks.started_by_account_id,
    tasks.task_created_at + INTERVAL '30 minutes'
FROM fixture_loaded_workflow_tasks AS tasks
WHERE tasks.fixture_task_status IN ('blocked', 'failed');

-- ============================================================
-- Workflow status-history specifications
-- ============================================================

CREATE TEMP TABLE fixture_workflow_history_specs (
    scenario_key TEXT NOT NULL,
    history_sequence INTEGER NOT NULL,
    from_status TEXT,
    to_status TEXT NOT NULL,
    from_step_key TEXT,
    to_step_key TEXT NOT NULL,
    changed_offset INTERVAL NOT NULL,
    note TEXT NOT NULL,
    PRIMARY KEY (scenario_key, history_sequence)
) ON COMMIT DROP;

INSERT INTO fixture_workflow_history_specs (
    scenario_key,
    history_sequence,
    from_status,
    to_status,
    from_step_key,
    to_step_key,
    changed_offset,
    note
)
VALUES
    -- Completed financial approval
    ('finance_completed', 1, NULL, 'running', NULL, 'submitted', INTERVAL '0 hours', 'Financial approval workflow started.'),
    ('finance_completed', 2, 'running', 'running', 'submitted', 'finance_review', INTERVAL '30 minutes', 'Transaction submitted for finance review.'),
    ('finance_completed', 3, 'running', 'running', 'finance_review', 'management_approval', INTERVAL '9 hours', 'Finance review completed and management approval requested.'),
    ('finance_completed', 4, 'running', 'running', 'management_approval', 'posting', INTERVAL '29 hours', 'Management approved the transaction for posting.'),
    ('finance_completed', 5, 'running', 'completed', 'posting', 'completed', INTERVAL '31 hours', 'Transaction posted and workflow completed.'),

    -- Running financial approval
    ('finance_running', 1, NULL, 'running', NULL, 'submitted', INTERVAL '0 hours', 'Financial approval workflow started.'),
    ('finance_running', 2, 'running', 'running', 'submitted', 'finance_review', INTERVAL '30 minutes', 'Draft transaction submitted for finance review.'),
    ('finance_running', 3, 'running', 'running', 'finance_review', 'management_approval', INTERVAL '9 hours', 'Finance review completed; management approval is in progress.'),

    -- Completed controlled-document approval
    ('document_completed', 1, NULL, 'running', NULL, 'draft_submitted', INTERVAL '0 hours', 'Controlled-document approval workflow started.'),
    ('document_completed', 2, 'running', 'running', 'draft_submitted', 'operational_review', INTERVAL '1 hour', 'Draft routed to operational review.'),
    ('document_completed', 3, 'running', 'running', 'operational_review', 'compliance_review', INTERVAL '20 hours', 'Operational review accepted the draft.'),
    ('document_completed', 4, 'running', 'running', 'compliance_review', 'owner_approval', INTERVAL '44 hours', 'Compliance review accepted the draft.'),
    ('document_completed', 5, 'running', 'running', 'owner_approval', 'publish', INTERVAL '70 hours', 'The document owner approved controlled publication.'),
    ('document_completed', 6, 'running', 'completed', 'publish', 'completed', INTERVAL '74 hours', 'The approved document was published and the workflow completed.'),

    -- Running controlled-document approval
    ('document_running', 1, NULL, 'running', NULL, 'draft_submitted', INTERVAL '0 hours', 'Controlled-document approval workflow started.'),
    ('document_running', 2, 'running', 'running', 'draft_submitted', 'operational_review', INTERVAL '1 hour', 'Draft routed to operational review.'),
    ('document_running', 3, 'running', 'running', 'operational_review', 'compliance_review', INTERVAL '21 hours', 'Operational review accepted the draft.'),
    ('document_running', 4, 'running', 'running', 'compliance_review', 'owner_approval', INTERVAL '47 hours', 'Compliance review completed; owner approval is pending.'),

    -- Completed onboarding
    ('onboarding_completed', 1, NULL, 'running', NULL, 'initiated', INTERVAL '0 hours', 'Employee onboarding workflow started.'),
    ('onboarding_completed', 2, 'running', 'running', 'initiated', 'identity_setup', INTERVAL '30 minutes', 'Identity and access setup started.'),
    ('onboarding_completed', 3, 'running', 'running', 'identity_setup', 'department_setup', INTERVAL '13 hours', 'Identity setup completed.'),
    ('onboarding_completed', 4, 'running', 'running', 'department_setup', 'manager_orientation', INTERVAL '30 hours', 'Organizational placement confirmed.'),
    ('onboarding_completed', 5, 'running', 'running', 'manager_orientation', 'employee_acknowledgement', INTERVAL '74 hours', 'Manager orientation completed.'),
    ('onboarding_completed', 6, 'running', 'completed', 'employee_acknowledgement', 'completed', INTERVAL '100 hours', 'Required acknowledgements were recorded and onboarding completed.'),

    -- Draft onboarding
    ('onboarding_draft', 1, NULL, 'draft', NULL, 'initiated', INTERVAL '0 hours', 'Draft onboarding plan created but not yet started.'),

    -- Cancelled onboarding
    ('onboarding_cancelled', 1, NULL, 'running', NULL, 'initiated', INTERVAL '0 hours', 'Employee onboarding workflow started.'),
    ('onboarding_cancelled', 2, 'running', 'running', 'initiated', 'identity_setup', INTERVAL '30 minutes', 'Identity and access setup started.'),
    ('onboarding_cancelled', 3, 'running', 'cancelled', 'identity_setup', 'identity_setup', INTERVAL '4 hours', 'Onboarding cancelled during the company wind-down process.'),

    -- Running operational exception
    ('operations_running', 1, NULL, 'running', NULL, 'reported', INTERVAL '0 hours', 'Operational exception workflow started.'),
    ('operations_running', 2, 'running', 'running', 'reported', 'triage', INTERVAL '15 minutes', 'Exception accepted for triage.'),
    ('operations_running', 3, 'running', 'running', 'triage', 'investigation', INTERVAL '3 hours', 'Triage completed and investigation opened.'),
    ('operations_running', 4, 'running', 'running', 'investigation', 'corrective_action', INTERVAL '32 hours', 'Cause confirmed and corrective action started.'),

    -- Paused operational exception
    ('operations_paused', 1, NULL, 'running', NULL, 'reported', INTERVAL '0 hours', 'Operational exception workflow started.'),
    ('operations_paused', 2, 'running', 'running', 'reported', 'triage', INTERVAL '15 minutes', 'Exception accepted for triage.'),
    ('operations_paused', 3, 'running', 'running', 'triage', 'investigation', INTERVAL '3 hours', 'Triage completed and investigation opened.'),
    ('operations_paused', 4, 'running', 'paused', 'investigation', 'investigation', INTERVAL '30 hours', 'Workflow paused while external operating evidence is collected.'),

    -- Failed operational exception
    ('operations_failed', 1, NULL, 'running', NULL, 'reported', INTERVAL '0 hours', 'Operational exception workflow started.'),
    ('operations_failed', 2, 'running', 'running', 'reported', 'triage', INTERVAL '15 minutes', 'Exception accepted for triage.'),
    ('operations_failed', 3, 'running', 'running', 'triage', 'investigation', INTERVAL '3 hours', 'Triage completed and investigation opened.'),
    ('operations_failed', 4, 'running', 'running', 'investigation', 'corrective_action', INTERVAL '29 hours', 'Investigation completed and corrective action started.'),
    ('operations_failed', 5, 'running', 'running', 'corrective_action', 'verification', INTERVAL '71 hours', 'Corrective action submitted for effectiveness verification.'),
    ('operations_failed', 6, 'running', 'failed', 'verification', 'verification', INTERVAL '78 hours', 'Effectiveness verification failed and the workflow requires administrative recovery.'),

    -- Completed operational exception
    ('operations_completed', 1, NULL, 'running', NULL, 'reported', INTERVAL '0 hours', 'Operational exception workflow started.'),
    ('operations_completed', 2, 'running', 'running', 'reported', 'triage', INTERVAL '15 minutes', 'Exception accepted for triage.'),
    ('operations_completed', 3, 'running', 'running', 'triage', 'investigation', INTERVAL '3 hours', 'Triage completed and investigation opened.'),
    ('operations_completed', 4, 'running', 'running', 'investigation', 'corrective_action', INTERVAL '31 hours', 'Investigation completed and corrective action started.'),
    ('operations_completed', 5, 'running', 'running', 'corrective_action', 'verification', INTERVAL '83 hours', 'Corrective action submitted for effectiveness verification.'),
    ('operations_completed', 6, 'running', 'completed', 'verification', 'closed', INTERVAL '120 hours', 'Corrective action verified as effective and the exception closed.');

-- ============================================================
-- Workflow status history
-- ============================================================

INSERT INTO workflows.workflow_status_history (
    company_id,
    workflow_instance_id,
    workflow_definition_id,
    from_status,
    to_status,
    from_step_id,
    to_step_id,
    changed_by_account_id,
    changed_at,
    note,
    metadata
)
SELECT
    instances.company_id,
    instances.workflow_instance_id,
    instances.workflow_definition_id,
    specifications.from_status,
    specifications.to_status,
    from_steps.workflow_step_id,
    to_steps.workflow_step_id,
    instances.started_by_account_id,
    instances.started_at + specifications.changed_offset,
    specifications.note,
    jsonb_build_object(
        'fixture', 'realistic_multi_company',
        'instance_key', instances.instance_key,
        'scenario', instances.scenario_key,
        'sequence', specifications.history_sequence
    )
FROM fixture_loaded_workflow_instances AS instances
JOIN fixture_workflow_history_specs AS specifications
  ON specifications.scenario_key = instances.scenario_key
LEFT JOIN workflows.workflow_steps AS from_steps
  ON from_steps.workflow_definition_id = instances.workflow_definition_id
 AND from_steps.step_key = specifications.from_step_key
JOIN workflows.workflow_steps AS to_steps
  ON to_steps.workflow_definition_id = instances.workflow_definition_id
 AND to_steps.step_key = specifications.to_step_key;

-- ============================================================
-- Post-load validation
-- ============================================================

DO $$
DECLARE
    expected_definition_count INTEGER;
    actual_definition_count INTEGER;
    expected_step_count INTEGER;
    actual_step_count INTEGER;
    expected_transition_count INTEGER;
    actual_transition_count INTEGER;
    expected_instance_count INTEGER;
    actual_instance_count INTEGER;
    expected_task_count INTEGER;
    actual_task_count INTEGER;
    expected_history_count INTEGER;
    actual_history_count INTEGER;
BEGIN
    SELECT
        COUNT(*)
    INTO expected_definition_count
    FROM fixture_workflow_account_context
    CROSS JOIN fixture_workflow_definition_specs;

    SELECT COUNT(*)
    INTO actual_definition_count
    FROM workflows.workflow_definitions AS definitions
    JOIN fixture_workflow_account_context AS context
      ON context.company_id = definitions.company_id
    JOIN fixture_workflow_definition_specs AS specifications
      ON specifications.workflow_key = definitions.workflow_key
    WHERE definitions.version_number = 1;

    IF actual_definition_count <> expected_definition_count THEN
        RAISE EXCEPTION
            '07_workflows.sql loaded % workflow definitions; expected %.',
            actual_definition_count,
            expected_definition_count;
    END IF;

    SELECT
        COUNT(*)
    INTO expected_step_count
    FROM fixture_workflow_account_context AS context
    CROSS JOIN fixture_workflow_step_specs AS specifications;

    SELECT COUNT(*)
    INTO actual_step_count
    FROM workflows.workflow_steps AS steps
    JOIN workflows.workflow_definitions AS definitions
      ON definitions.workflow_definition_id = steps.workflow_definition_id
    JOIN fixture_workflow_account_context AS context
      ON context.company_id = definitions.company_id
    JOIN fixture_workflow_step_specs AS specifications
      ON specifications.workflow_key = definitions.workflow_key
     AND specifications.step_key = steps.step_key
    WHERE definitions.version_number = 1;

    IF actual_step_count <> expected_step_count THEN
        RAISE EXCEPTION
            '07_workflows.sql loaded % workflow steps; expected %.',
            actual_step_count,
            expected_step_count;
    END IF;

    SELECT
        COUNT(*)
    INTO expected_transition_count
    FROM fixture_workflow_account_context AS context
    CROSS JOIN fixture_workflow_transition_specs AS specifications;

    SELECT COUNT(*)
    INTO actual_transition_count
    FROM workflows.workflow_transitions AS transitions
    JOIN workflows.workflow_definitions AS definitions
      ON definitions.workflow_definition_id = transitions.workflow_definition_id
    JOIN fixture_workflow_account_context AS context
      ON context.company_id = definitions.company_id
    JOIN fixture_workflow_transition_specs AS specifications
      ON specifications.workflow_key = definitions.workflow_key
     AND specifications.transition_key = transitions.transition_key
    WHERE definitions.version_number = 1;

    IF actual_transition_count <> expected_transition_count THEN
        RAISE EXCEPTION
            '07_workflows.sql loaded % workflow transitions; expected %.',
            actual_transition_count,
            expected_transition_count;
    END IF;

    SELECT COUNT(*)
    INTO expected_instance_count
    FROM fixture_workflow_instance_specs;

    SELECT COUNT(*)
    INTO actual_instance_count
    FROM fixture_loaded_workflow_instances;

    IF actual_instance_count <> expected_instance_count THEN
        RAISE EXCEPTION
            '07_workflows.sql loaded % workflow instances; expected %.',
            actual_instance_count,
            expected_instance_count;
    END IF;

    SELECT COUNT(*)
    INTO expected_task_count
    FROM fixture_loaded_workflow_instances AS instances
    JOIN fixture_workflow_task_specs AS specifications
      ON specifications.scenario_key = instances.scenario_key;

    SELECT COUNT(*)
    INTO actual_task_count
    FROM fixture_loaded_workflow_tasks;

    IF actual_task_count <> expected_task_count THEN
        RAISE EXCEPTION
            '07_workflows.sql loaded % workflow tasks; expected %.',
            actual_task_count,
            expected_task_count;
    END IF;

    SELECT COUNT(*)
    INTO expected_history_count
    FROM fixture_loaded_workflow_instances AS instances
    JOIN fixture_workflow_history_specs AS specifications
      ON specifications.scenario_key = instances.scenario_key;

    SELECT COUNT(*)
    INTO actual_history_count
    FROM fixture_loaded_workflow_instances AS instances
    JOIN workflows.workflow_status_history AS history
      ON history.company_id = instances.company_id
     AND history.workflow_instance_id = instances.workflow_instance_id
     AND history.workflow_definition_id = instances.workflow_definition_id;

    IF actual_history_count <> expected_history_count THEN
        RAISE EXCEPTION
            '07_workflows.sql loaded % workflow status-history rows; expected %.',
            actual_history_count,
            expected_history_count;
    END IF;

    IF EXISTS (
        SELECT 1
        FROM fixture_loaded_workflow_instances AS fixture
        JOIN workflows.workflow_instances AS instances
          ON instances.workflow_instance_id = fixture.workflow_instance_id
        LEFT JOIN LATERAL (
            SELECT
                history.to_status,
                history.to_step_id
            FROM workflows.workflow_status_history AS history
            WHERE history.company_id = instances.company_id
              AND history.workflow_instance_id = instances.workflow_instance_id
              AND history.workflow_definition_id = instances.workflow_definition_id
            ORDER BY
                history.changed_at DESC,
                history.workflow_status_history_id DESC
            LIMIT 1
        ) AS latest_history
          ON TRUE
        WHERE latest_history.to_status IS DISTINCT FROM instances.status
           OR latest_history.to_step_id IS DISTINCT FROM instances.current_step_id
    ) THEN
        RAISE EXCEPTION
            '07_workflows.sql found an instance whose latest status-history row does not match its current status and step.';
    END IF;

    IF EXISTS (
        SELECT 1
        FROM fixture_loaded_workflow_tasks AS tasks
        WHERE NOT EXISTS (
            SELECT 1
            FROM workflows.workflow_task_assignments AS assignments
            WHERE assignments.company_id = tasks.company_id
              AND assignments.workflow_task_id = tasks.workflow_task_id
              AND assignments.assignment_type = 'owner'
              AND assignments.account_id = tasks.assigned_to_account_id
        )
    ) THEN
        RAISE EXCEPTION
            '07_workflows.sql found a fixture task without its explicit account-owner assignment.';
    END IF;

    IF EXISTS (
        SELECT 1
        FROM fixture_loaded_workflow_tasks AS tasks
        WHERE tasks.fixture_task_status IN ('open', 'in_progress', 'blocked')
          AND NOT EXISTS (
              SELECT 1
              FROM workflows.workflow_task_assignments AS assignments
              JOIN identity.access_roles AS roles
                ON roles.role_id = assignments.role_id
              WHERE assignments.company_id = tasks.company_id
                AND assignments.workflow_task_id = tasks.workflow_task_id
                AND assignments.assignment_type = 'candidate'
                AND roles.role_key = tasks.candidate_role_key
          )
    ) THEN
        RAISE EXCEPTION
            '07_workflows.sql found an active fixture task without its role-based candidate assignment.';
    END IF;

    IF EXISTS (
        SELECT 1
        FROM fixture_workflow_account_context AS context
        JOIN workflows.workflow_definitions AS definitions
          ON definitions.company_id = context.company_id
        JOIN fixture_workflow_definition_specs AS specifications
          ON specifications.workflow_key = definitions.workflow_key
        WHERE definitions.version_number = 1
          AND definitions.is_active IS DISTINCT FROM (context.archival_date IS NULL)
    ) THEN
        RAISE EXCEPTION
            '07_workflows.sql found a workflow definition whose active state does not match its fixture company lifecycle.';
    END IF;
END;
$$;

COMMIT;

\echo '07_workflows.sql completed successfully.'
