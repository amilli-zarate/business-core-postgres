\set ON_ERROR_STOP on
\encoding UTF8

BEGIN;

-- ============================================================
-- 08_audit.sql
-- Realistic multi-company example
--
-- Purpose:
-- Seed a substantial, internally consistent audit dataset:
--
-- - cross-domain business and system events
-- - successful and unsuccessful identity and security activity
-- - finance and document lifecycle events
-- - workflow status, task-assignment, and task-outcome events
-- - field-level before/after values for material changes
-- - request, session, source-system, client, and metadata context
--
-- Notes:
-- - All organizations, people, identifiers, network addresses,
--   user agents, and operational scenarios are synthetic.
-- - Generated identities are always resolved through stable
--   business keys; no BIGINT identity value is hard-coded.
-- - Workflow-owned execution history remains in 07_workflows.sql.
--   This script mirrors material workflow activity into the
--   cross-domain audit layer without modifying workflow state.
-- - The documentation and finance records audited here are not
--   changed by this script. The audit rows represent their
--   synthetic historical lifecycle.
-- - The script depends on 01_shared_reference_data.sql through
--   07_workflows.sql.
-- - The script is safe to run more than once. Audit records owned
--   by this fixture are rebuilt deterministically.
-- ============================================================

-- ============================================================
-- Fixture company profiles
-- ============================================================

CREATE TEMP TABLE fixture_audit_profiles (
    company_slug TEXT PRIMARY KEY,
    event_prefix TEXT NOT NULL,
    company_label TEXT NOT NULL,
    creator_person_external_reference TEXT NOT NULL,
    completed_onboarding_person_external_reference TEXT NOT NULL,
    representative_posted_transaction_number TEXT NOT NULL,
    representative_draft_transaction_number TEXT,
    completed_document_number TEXT NOT NULL,
    draft_document_number TEXT,
    reference_date DATE NOT NULL,
    archival_date DATE,
    client_ip INET NOT NULL
) ON COMMIT DROP;

INSERT INTO fixture_audit_profiles (
    company_slug,
    event_prefix,
    company_label,
    creator_person_external_reference,
    completed_onboarding_person_external_reference,
    representative_posted_transaction_number,
    representative_draft_transaction_number,
    completed_document_number,
    draft_document_number,
    reference_date,
    archival_date,
    client_ip
)
VALUES
    (
        'solara-retail-mx',
        'SRM',
        'Solara Retail Mexico',
        'SRM-P009',
        'SRM-P014',
        'SRM-202606-OPEX',
        'SRM-202607-DRAFT',
        'SRM-DOC-OPS-SOP-001',
        'SRM-DOC-BCP-DRAFT-001',
        DATE '2026-06-30',
        NULL,
        '192.0.2.11'::INET
    ),
    (
        'cobalto-industrial-mx',
        'CIS',
        'Cobalto Industrial Systems',
        'CIS-P010',
        'CIS-P014',
        'CIS-202606-OPEX',
        'CIS-202607-DRAFT',
        'CIS-DOC-OPS-SOP-001',
        'CIS-DOC-BCP-DRAFT-001',
        DATE '2026-06-30',
        NULL,
        '192.0.2.12'::INET
    ),
    (
        'bluepeak-advisory-us',
        'BPA',
        'BluePeak Advisory',
        'BPA-P009',
        'BPA-P014',
        'BPA-202606-OPEX',
        'BPA-202607-DRAFT',
        'BPA-DOC-OPS-SOP-001',
        'BPA-DOC-BCP-DRAFT-001',
        DATE '2026-06-30',
        NULL,
        '198.51.100.21'::INET
    ),
    (
        'lumenforge-technologies-us',
        'LFT',
        'LumenForge Technologies',
        'LFT-P010',
        'LFT-P014',
        'LFT-202606-OPEX',
        'LFT-202607-DRAFT',
        'LFT-DOC-OPS-SOP-001',
        'LFT-DOC-BCP-DRAFT-001',
        DATE '2026-06-30',
        NULL,
        '198.51.100.22'::INET
    ),
    (
        'cedarline-logistics-ca',
        'CLL',
        'CedarLine Logistics',
        'CLL-P010',
        'CLL-P014',
        'CLL-202606-OPEX',
        'CLL-202607-DRAFT',
        'CLL-DOC-OPS-SOP-001',
        'CLL-DOC-BCP-DRAFT-001',
        DATE '2026-06-30',
        NULL,
        '203.0.113.31'::INET
    ),
    (
        'harvest-circle-foods-ca',
        'HCF',
        'Harvest Circle Foods',
        'HCF-P008',
        'HCF-P010',
        'HCF-202409-OPEX',
        NULL,
        'HCF-DOC-OPS-SOP-001',
        NULL,
        DATE '2024-09-20',
        DATE '2024-10-01',
        '203.0.113.32'::INET
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
    FROM fixture_audit_profiles;

    SELECT COUNT(*)
    INTO resolved_companies
    FROM fixture_audit_profiles AS profiles
    JOIN core.companies AS companies
      ON companies.company_slug = profiles.company_slug;

    IF resolved_companies <> expected_companies THEN
        RAISE EXCEPTION
            '08_audit.sql could resolve only % of % fixture companies. Run 02_organizations.sql first.',
            resolved_companies,
            expected_companies;
    END IF;

    IF EXISTS (
        SELECT 1
        FROM fixture_audit_profiles AS profiles
        JOIN core.companies AS companies
          ON companies.company_slug = profiles.company_slug
        LEFT JOIN people.persons AS creators
          ON creators.company_id = companies.company_id
         AND creators.external_reference = profiles.creator_person_external_reference
        LEFT JOIN identity.user_accounts AS creator_accounts
          ON creator_accounts.person_id = creators.person_id
        LEFT JOIN people.persons AS onboarding_people
          ON onboarding_people.company_id = companies.company_id
         AND onboarding_people.external_reference = profiles.completed_onboarding_person_external_reference
        WHERE creators.person_id IS NULL
           OR creator_accounts.account_id IS NULL
           OR onboarding_people.person_id IS NULL
    ) THEN
        RAISE EXCEPTION
            '08_audit.sql could not resolve one or more fixture people or creator accounts. Run the current 03_people_and_relationships.sql and 04_identity.sql first.';
    END IF;

    IF EXISTS (
        SELECT 1
        FROM fixture_audit_profiles AS profiles
        JOIN core.companies AS companies
          ON companies.company_slug = profiles.company_slug
        LEFT JOIN finance.financial_transactions AS posted_transactions
          ON posted_transactions.company_id = companies.company_id
         AND posted_transactions.transaction_number = profiles.representative_posted_transaction_number
        LEFT JOIN finance.financial_transactions AS draft_transactions
          ON draft_transactions.company_id = companies.company_id
         AND draft_transactions.transaction_number = profiles.representative_draft_transaction_number
        WHERE posted_transactions.transaction_id IS NULL
           OR posted_transactions.status <> 'posted'
           OR posted_transactions.posting_date IS NULL
           OR (
                profiles.representative_draft_transaction_number IS NOT NULL
                AND (
                    draft_transactions.transaction_id IS NULL
                    OR draft_transactions.status <> 'draft'
                )
           )
    ) THEN
        RAISE EXCEPTION
            '08_audit.sql could not resolve the expected posted and draft fixture transactions. Run the current 05_finance.sql first.';
    END IF;

    IF EXISTS (
        SELECT 1
        FROM fixture_audit_profiles AS profiles
        JOIN core.companies AS companies
          ON companies.company_slug = profiles.company_slug
        LEFT JOIN documents.document_records AS completed_documents
          ON completed_documents.company_id = companies.company_id
         AND completed_documents.document_number = profiles.completed_document_number
        LEFT JOIN documents.document_records AS draft_documents
          ON draft_documents.company_id = companies.company_id
         AND draft_documents.document_number = profiles.draft_document_number
        WHERE completed_documents.document_id IS NULL
           OR completed_documents.effective_date IS NULL
           OR (
                profiles.draft_document_number IS NOT NULL
                AND (
                    draft_documents.document_id IS NULL
                    OR draft_documents.document_status <> 'draft'
                )
           )
    ) THEN
        RAISE EXCEPTION
            '08_audit.sql could not resolve the expected completed and draft fixture documents. Run the current 06_documents.sql first.';
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
            '08_audit.sql could not resolve one or more required access roles. Run the current 01_shared_reference_data.sql first.';
    END IF;
END;
$$;

-- ============================================================
-- Company and actor context
-- ============================================================

CREATE TEMP TABLE fixture_audit_company_context
ON COMMIT DROP
AS
SELECT
    profiles.*,
    (profiles.reference_date::TIMESTAMP AT TIME ZONE 'UTC') AS reference_at,
    companies.company_id,
    creators.person_id AS creator_person_id,
    creator_accounts.account_id AS creator_account_id,
    COALESCE(
        role_accounts.admin_account_id,
        creator_accounts.account_id
    ) AS admin_account_id,
    COALESCE(
        role_accounts.finance_account_id,
        role_accounts.admin_account_id,
        creator_accounts.account_id
    ) AS finance_account_id,
    COALESCE(
        role_accounts.people_account_id,
        role_accounts.admin_account_id,
        creator_accounts.account_id
    ) AS people_account_id,
    COALESCE(
        role_accounts.operations_account_id,
        role_accounts.admin_account_id,
        creator_accounts.account_id
    ) AS operations_account_id,
    COALESCE(
        service_accounts.account_id,
        role_accounts.finance_account_id,
        role_accounts.admin_account_id,
        creator_accounts.account_id
    ) AS integration_account_id
FROM fixture_audit_profiles AS profiles
JOIN core.companies AS companies
  ON companies.company_slug = profiles.company_slug
JOIN people.persons AS creators
  ON creators.company_id = companies.company_id
 AND creators.external_reference = profiles.creator_person_external_reference
JOIN identity.user_accounts AS creator_accounts
  ON creator_accounts.person_id = creators.person_id
LEFT JOIN LATERAL (
    SELECT
        MIN(assignments.account_id)
            FILTER (WHERE roles.role_key = 'company_admin')
            AS admin_account_id,
        MIN(assignments.account_id)
            FILTER (WHERE roles.role_key = 'company_finance_manager')
            AS finance_account_id,
        MIN(assignments.account_id)
            FILTER (WHERE roles.role_key = 'company_people_manager')
            AS people_account_id,
        MIN(assignments.account_id)
            FILTER (WHERE roles.role_key = 'company_operations_manager')
            AS operations_account_id
    FROM identity.account_role_assignments AS assignments
    JOIN identity.access_roles AS roles
      ON roles.role_id = assignments.role_id
    JOIN identity.user_accounts AS accounts
      ON accounts.account_id = assignments.account_id
    WHERE assignments.company_id = companies.company_id
      AND assignments.scope_type = 'company'
      AND assignments.revoked_at IS NULL
      AND accounts.account_status = 'active'
      AND roles.role_key IN (
            'company_admin',
            'company_finance_manager',
            'company_people_manager',
            'company_operations_manager'
      )
) AS role_accounts
  ON TRUE
LEFT JOIN LATERAL (
    SELECT accounts.account_id
    FROM identity.user_accounts AS accounts
    WHERE lower(accounts.account_email)
        = lower('automation@' || companies.company_slug || '.example')
      AND accounts.is_service_account
      AND accounts.account_status = 'active'
    ORDER BY accounts.account_id
    LIMIT 1
) AS service_accounts
  ON TRUE;

CREATE UNIQUE INDEX fixture_audit_company_context_company_idx
    ON fixture_audit_company_context (company_id);

-- ============================================================
-- Workflow context created by 07_workflows.sql
-- ============================================================

CREATE TEMP TABLE fixture_audit_workflow_context
ON COMMIT DROP
AS
SELECT
    context.company_slug,
    context.company_id,
    context.archival_date,
    instances.workflow_instance_id,
    instances.workflow_definition_id,
    definitions.workflow_key,
    instances.metadata ->> 'scenario' AS scenario_key,
    instances.title,
    instances.status,
    instances.current_step_id,
    instances.started_by_account_id,
    instances.started_at,
    instances.completed_at,
    instances.cancelled_at
FROM fixture_audit_company_context AS context
JOIN workflows.workflow_instances AS instances
  ON instances.company_id = context.company_id
 AND instances.metadata ->> 'fixture' = 'realistic_multi_company'
JOIN workflows.workflow_definitions AS definitions
  ON definitions.workflow_definition_id = instances.workflow_definition_id
 AND definitions.company_id = instances.company_id;

CREATE UNIQUE INDEX fixture_audit_workflow_context_scenario_idx
    ON fixture_audit_workflow_context (company_id, scenario_key);

DO $$
DECLARE
    expected_workflow_instances INTEGER;
    resolved_workflow_instances INTEGER;
BEGIN
    SELECT SUM(
        CASE
            WHEN archival_date IS NULL THEN 7
            ELSE 4
        END
    )
    INTO expected_workflow_instances
    FROM fixture_audit_company_context;

    SELECT COUNT(*)
    INTO resolved_workflow_instances
    FROM fixture_audit_workflow_context;

    IF resolved_workflow_instances <> expected_workflow_instances THEN
        RAISE EXCEPTION
            '08_audit.sql resolved % fixture workflow instances; expected %. Run the current 07_workflows.sql first.',
            resolved_workflow_instances,
            expected_workflow_instances;
    END IF;

    IF EXISTS (
        SELECT 1
        FROM fixture_audit_workflow_context
        WHERE scenario_key IS NULL
    ) THEN
        RAISE EXCEPTION
            '08_audit.sql found a fixture workflow instance without its scenario metadata.';
    END IF;
END;
$$;

-- ============================================================
-- Deterministic cleanup of fixture-owned audit records
-- ============================================================

DELETE FROM audit.audit_events
WHERE metadata ->> 'fixture' = 'realistic_multi_company';

-- ============================================================
-- Manual cross-domain audit-event specifications
-- ============================================================

CREATE TEMP TABLE fixture_manual_audit_event_specs (
    event_key TEXT PRIMARY KEY,
    company_slug TEXT NOT NULL,
    time_source TEXT NOT NULL,
    event_offset INTERVAL NOT NULL,
    action_category TEXT NOT NULL,
    action_type TEXT NOT NULL,
    event_outcome TEXT NOT NULL,
    severity TEXT NOT NULL,
    entity_kind TEXT NOT NULL,
    entity_business_key TEXT NOT NULL,
    actor_context TEXT NOT NULL,
    workflow_scenario_key TEXT,
    session_key TEXT,
    source_system TEXT NOT NULL,
    include_client_context BOOLEAN NOT NULL,
    event_summary TEXT NOT NULL,
    metadata JSONB NOT NULL
) ON COMMIT DROP;

-- Common audit scenarios for all fixture companies.
INSERT INTO fixture_manual_audit_event_specs (
    event_key,
    company_slug,
    time_source,
    event_offset,
    action_category,
    action_type,
    event_outcome,
    severity,
    entity_kind,
    entity_business_key,
    actor_context,
    workflow_scenario_key,
    session_key,
    source_system,
    include_client_context,
    event_summary,
    metadata
)
SELECT
    context.company_slug || ':' || specifications.event_suffix,
    context.company_slug,
    specifications.time_source,
    specifications.event_offset,
    specifications.action_category,
    specifications.action_type,
    specifications.event_outcome,
    specifications.severity,
    specifications.entity_kind,
    specifications.entity_business_key,
    specifications.actor_context,
    specifications.workflow_scenario_key,
    specifications.session_key,
    specifications.source_system,
    specifications.include_client_context,
    specifications.event_summary,
    specifications.metadata
FROM fixture_audit_company_context AS context
CROSS JOIN LATERAL (
    VALUES
        (
            'system.company_snapshot_imported',
            'entity_created',
            INTERVAL '0 seconds',
            'SYSTEM',
            'IMPORT',
            'SUCCESS',
            'INFO',
            'company',
            context.company_slug,
            'none',
            NULL::TEXT,
            NULL::TEXT,
            'fixture_loader',
            FALSE,
            'Imported the ' || context.company_label || ' company snapshot into the demonstration environment.',
            jsonb_build_object(
                'operation', 'fixture_snapshot_import',
                'backfilled_history', TRUE
            )
        ),
        (
            'security.admin_login_failed',
            'reference',
            INTERVAL '9 days 13 hours 55 minutes',
            'SECURITY',
            'LOGIN',
            'FAILURE',
            'WARNING',
            'user_account',
            context.creator_person_external_reference,
            'admin',
            NULL::TEXT,
            context.company_slug || ':admin:' || TO_CHAR(context.reference_date + 9, 'YYYYMMDD'),
            'identity_gateway',
            TRUE,
            'Rejected an administrative sign-in attempt for ' || context.company_label || ' after invalid credentials were supplied.',
            jsonb_build_object(
                'authentication_factor', 'password',
                'failure_reason', 'invalid_credentials',
                'attempt_number', 1
            )
        ),
        (
            'identity.admin_login_succeeded',
            'reference',
            INTERVAL '9 days 14 hours',
            'IDENTITY',
            'LOGIN',
            'SUCCESS',
            'INFO',
            'user_account',
            context.creator_person_external_reference,
            'admin',
            NULL::TEXT,
            context.company_slug || ':admin:' || TO_CHAR(context.reference_date + 9, 'YYYYMMDD'),
            'identity_gateway',
            TRUE,
            'Authenticated an administrative user for ' || context.company_label || '.',
            jsonb_build_object(
                'authentication_factor', 'password',
                'mfa_result', 'satisfied'
            )
        ),
        (
            'identity.admin_logout',
            'reference',
            INTERVAL '9 days 17 hours 30 minutes',
            'IDENTITY',
            'LOGOUT',
            'SUCCESS',
            'INFO',
            'user_account',
            context.creator_person_external_reference,
            'admin',
            NULL::TEXT,
            context.company_slug || ':admin:' || TO_CHAR(context.reference_date + 9, 'YYYYMMDD'),
            'identity_gateway',
            TRUE,
            'Closed the administrative session for ' || context.company_label || '.',
            jsonb_build_object(
                'logout_reason', 'user_initiated'
            )
        ),
        (
            'finance.transaction_created',
            'entity_created',
            INTERVAL '0 seconds',
            'FINANCE',
            'CREATE',
            'SUCCESS',
            'INFO',
            'financial_transaction',
            context.representative_posted_transaction_number,
            'finance',
            NULL::TEXT,
            NULL::TEXT,
            'finance_service',
            TRUE,
            'Created representative financial transaction ' || context.representative_posted_transaction_number || ' for ' || context.company_label || '.',
            jsonb_build_object(
                'transaction_number', context.representative_posted_transaction_number,
                'lifecycle_stage', 'draft_created'
            )
        ),
        (
            'finance.transaction_submitted',
            'workflow',
            INTERVAL '0 seconds',
            'FINANCE',
            'SUBMIT',
            'SUCCESS',
            'INFO',
            'financial_transaction',
            context.representative_posted_transaction_number,
            'finance',
            'finance_completed',
            NULL::TEXT,
            'finance_service',
            TRUE,
            'Submitted financial transaction ' || context.representative_posted_transaction_number || ' for approval.',
            jsonb_build_object(
                'transaction_number', context.representative_posted_transaction_number,
                'approval_route', 'finance.transaction_approval'
            )
        ),
        (
            'finance.transaction_approved',
            'workflow',
            INTERVAL '29 hours',
            'FINANCE',
            'APPROVE',
            'SUCCESS',
            'INFO',
            'financial_transaction',
            context.representative_posted_transaction_number,
            'admin',
            'finance_completed',
            NULL::TEXT,
            'finance_service',
            TRUE,
            'Approved financial transaction ' || context.representative_posted_transaction_number || ' for posting.',
            jsonb_build_object(
                'transaction_number', context.representative_posted_transaction_number,
                'approval_level', 'company_management'
            )
        ),
        (
            'finance.transaction_posted',
            'workflow',
            INTERVAL '31 hours',
            'FINANCE',
            'STATUS_CHANGE',
            'SUCCESS',
            'INFO',
            'financial_transaction',
            context.representative_posted_transaction_number,
            'finance',
            'finance_completed',
            NULL::TEXT,
            'finance_service',
            TRUE,
            'Posted financial transaction ' || context.representative_posted_transaction_number || ' to the authoritative ledger.',
            jsonb_build_object(
                'transaction_number', context.representative_posted_transaction_number,
                'lifecycle_stage', 'posted'
            )
        ),
        (
            'document.record_created',
            'entity_created',
            INTERVAL '0 seconds',
            'DOCUMENT',
            'CREATE',
            'SUCCESS',
            'INFO',
            'document_record',
            context.completed_document_number,
            'operations',
            NULL::TEXT,
            NULL::TEXT,
            'document_service',
            TRUE,
            'Created controlled document record ' || context.completed_document_number || ' for ' || context.company_label || '.',
            jsonb_build_object(
                'document_number', context.completed_document_number,
                'lifecycle_stage', 'draft_created'
            )
        ),
        (
            'document.record_submitted',
            'workflow',
            INTERVAL '0 seconds',
            'DOCUMENT',
            'SUBMIT',
            'SUCCESS',
            'INFO',
            'document_record',
            context.completed_document_number,
            'operations',
            'document_completed',
            NULL::TEXT,
            'document_service',
            TRUE,
            'Submitted controlled document ' || context.completed_document_number || ' for review and approval.',
            jsonb_build_object(
                'document_number', context.completed_document_number,
                'approval_route', 'documents.controlled_document_approval'
            )
        ),
        (
            'document.record_approved',
            'workflow',
            INTERVAL '70 hours',
            'DOCUMENT',
            'APPROVE',
            'SUCCESS',
            'INFO',
            'document_record',
            context.completed_document_number,
            'admin',
            'document_completed',
            NULL::TEXT,
            'document_service',
            TRUE,
            'Approved controlled document ' || context.completed_document_number || '.',
            jsonb_build_object(
                'document_number', context.completed_document_number,
                'approval_level', 'document_owner'
            )
        ),
        (
            'document.record_activated',
            'workflow',
            INTERVAL '74 hours',
            'DOCUMENT',
            'STATUS_CHANGE',
            'SUCCESS',
            'INFO',
            'document_record',
            context.completed_document_number,
            'operations',
            'document_completed',
            NULL::TEXT,
            'document_service',
            TRUE,
            'Activated controlled document ' || context.completed_document_number || ' for governed use.',
            jsonb_build_object(
                'document_number', context.completed_document_number,
                'lifecycle_stage', 'active'
            )
        ),
        (
            'integration.management_report_exported',
            'reference',
            INTERVAL '1 day 18 hours',
            'INTEGRATION',
            'EXPORT',
            'SUCCESS',
            'INFO',
            'company',
            context.company_slug,
            'integration',
            NULL::TEXT,
            NULL::TEXT,
            'reporting_service',
            FALSE,
            'Exported the monthly management reporting package for ' || context.company_label || '.',
            jsonb_build_object(
                'export_format', 'parquet',
                'destination', 'synthetic-analytics-lake',
                'record_scope', 'monthly_management'
            )
        )
) AS specifications (
    event_suffix,
    time_source,
    event_offset,
    action_category,
    action_type,
    event_outcome,
    severity,
    entity_kind,
    entity_business_key,
    actor_context,
    workflow_scenario_key,
    session_key,
    source_system,
    include_client_context,
    event_summary,
    metadata
);

-- Additional current-company scenarios.
INSERT INTO fixture_manual_audit_event_specs (
    event_key,
    company_slug,
    time_source,
    event_offset,
    action_category,
    action_type,
    event_outcome,
    severity,
    entity_kind,
    entity_business_key,
    actor_context,
    workflow_scenario_key,
    session_key,
    source_system,
    include_client_context,
    event_summary,
    metadata
)
SELECT
    context.company_slug || ':' || specifications.event_suffix,
    context.company_slug,
    specifications.time_source,
    specifications.event_offset,
    specifications.action_category,
    specifications.action_type,
    specifications.event_outcome,
    specifications.severity,
    specifications.entity_kind,
    specifications.entity_business_key,
    specifications.actor_context,
    specifications.workflow_scenario_key,
    NULL::TEXT,
    specifications.source_system,
    specifications.include_client_context,
    specifications.event_summary,
    specifications.metadata
FROM fixture_audit_company_context AS context
CROSS JOIN LATERAL (
    VALUES
        (
            'identity.account_activated',
            'reference',
            INTERVAL '-150 days 14 hours',
            'IDENTITY',
            'STATUS_CHANGE',
            'SUCCESS',
            'INFO',
            'user_account',
            context.creator_person_external_reference,
            'admin',
            NULL::TEXT,
            'identity_service',
            TRUE,
            'Activated the primary administrative account for ' || context.company_label || '.',
            jsonb_build_object(
                'activation_source', 'approved_access_request'
            )
        ),
        (
            'data.onboarding_person_activated',
            'workflow',
            INTERVAL '12 hours',
            'DATA',
            'UPDATE',
            'SUCCESS',
            'INFO',
            'person',
            context.completed_onboarding_person_external_reference,
            'people',
            'onboarding_completed',
            'people_service',
            TRUE,
            'Activated the employee profile ' || context.completed_onboarding_person_external_reference || ' during onboarding.',
            jsonb_build_object(
                'change_reason', 'employee_onboarding'
            )
        ),
        (
            'finance.draft_transaction_created',
            'entity_created',
            INTERVAL '0 seconds',
            'FINANCE',
            'CREATE',
            'SUCCESS',
            'INFO',
            'financial_transaction',
            context.representative_draft_transaction_number,
            'finance',
            NULL::TEXT,
            'finance_service',
            TRUE,
            'Created draft financial transaction ' || context.representative_draft_transaction_number || '.',
            jsonb_build_object(
                'transaction_number', context.representative_draft_transaction_number,
                'lifecycle_stage', 'draft_created'
            )
        ),
        (
            'finance.draft_transaction_submitted',
            'workflow',
            INTERVAL '0 seconds',
            'FINANCE',
            'SUBMIT',
            'SUCCESS',
            'INFO',
            'financial_transaction',
            context.representative_draft_transaction_number,
            'finance',
            'finance_running',
            'finance_service',
            TRUE,
            'Submitted draft financial transaction ' || context.representative_draft_transaction_number || ' for management approval.',
            jsonb_build_object(
                'transaction_number', context.representative_draft_transaction_number,
                'approval_route', 'finance.transaction_approval'
            )
        ),
        (
            'document.draft_record_created',
            'entity_created',
            INTERVAL '0 seconds',
            'DOCUMENT',
            'CREATE',
            'SUCCESS',
            'INFO',
            'document_record',
            context.draft_document_number,
            'operations',
            NULL::TEXT,
            'document_service',
            TRUE,
            'Created draft controlled document ' || context.draft_document_number || '.',
            jsonb_build_object(
                'document_number', context.draft_document_number,
                'lifecycle_stage', 'draft_created'
            )
        ),
        (
            'document.draft_record_submitted',
            'workflow',
            INTERVAL '0 seconds',
            'DOCUMENT',
            'SUBMIT',
            'SUCCESS',
            'INFO',
            'document_record',
            context.draft_document_number,
            'operations',
            'document_running',
            'document_service',
            TRUE,
            'Submitted draft controlled document ' || context.draft_document_number || ' for approval.',
            jsonb_build_object(
                'document_number', context.draft_document_number,
                'approval_route', 'documents.controlled_document_approval'
            )
        )
) AS specifications (
    event_suffix,
    time_source,
    event_offset,
    action_category,
    action_type,
    event_outcome,
    severity,
    entity_kind,
    entity_business_key,
    actor_context,
    workflow_scenario_key,
    source_system,
    include_client_context,
    event_summary,
    metadata
)
WHERE context.archival_date IS NULL;

-- Historical wind-down events for Harvest Circle Foods.
INSERT INTO fixture_manual_audit_event_specs (
    event_key,
    company_slug,
    time_source,
    event_offset,
    action_category,
    action_type,
    event_outcome,
    severity,
    entity_kind,
    entity_business_key,
    actor_context,
    workflow_scenario_key,
    session_key,
    source_system,
    include_client_context,
    event_summary,
    metadata
)
SELECT
    context.company_slug || ':' || specifications.event_suffix,
    context.company_slug,
    specifications.time_source,
    specifications.event_offset,
    specifications.action_category,
    specifications.action_type,
    specifications.event_outcome,
    specifications.severity,
    specifications.entity_kind,
    specifications.entity_business_key,
    specifications.actor_context,
    NULL::TEXT,
    NULL::TEXT,
    specifications.source_system,
    specifications.include_client_context,
    specifications.event_summary,
    specifications.metadata
FROM fixture_audit_company_context AS context
CROSS JOIN LATERAL (
    VALUES
        (
            'data.company_inactivated',
            'reference',
            INTERVAL '11 days 16 hours',
            'DATA',
            'STATUS_CHANGE',
            'SUCCESS',
            'INFO',
            'company',
            context.company_slug,
            'admin',
            'administration_portal',
            TRUE,
            'Changed ' || context.company_label || ' from active operations to inactive historical status.',
            jsonb_build_object(
                'change_reason', 'planned_company_wind_down'
            )
        ),
        (
            'document.record_archived',
            'reference',
            INTERVAL '11 days 17 hours',
            'DOCUMENT',
            'STATUS_CHANGE',
            'SUCCESS',
            'INFO',
            'document_record',
            context.completed_document_number,
            'operations',
            'document_service',
            TRUE,
            'Archived controlled document ' || context.completed_document_number || ' during the company wind-down.',
            jsonb_build_object(
                'document_number', context.completed_document_number,
                'change_reason', 'company_wind_down'
            )
        )
) AS specifications (
    event_suffix,
    time_source,
    event_offset,
    action_category,
    action_type,
    event_outcome,
    severity,
    entity_kind,
    entity_business_key,
    actor_context,
    source_system,
    include_client_context,
    event_summary,
    metadata
)
WHERE context.company_slug = 'harvest-circle-foods-ca';

-- Representative integration failure.
INSERT INTO fixture_manual_audit_event_specs (
    event_key,
    company_slug,
    time_source,
    event_offset,
    action_category,
    action_type,
    event_outcome,
    severity,
    entity_kind,
    entity_business_key,
    actor_context,
    workflow_scenario_key,
    session_key,
    source_system,
    include_client_context,
    event_summary,
    metadata
)
SELECT
    context.company_slug || ':integration.management_report_export_failed',
    context.company_slug,
    'reference',
    INTERVAL '10 days 3 hours',
    'INTEGRATION',
    'EXPORT',
    'FAILURE',
    'ERROR',
    'company',
    context.company_slug,
    'integration',
    NULL::TEXT,
    NULL::TEXT,
    'reporting_service',
    FALSE,
    'Failed to export the management reporting package for ' || context.company_label || ' after the synthetic destination rejected the write.',
    jsonb_build_object(
        'export_format', 'parquet',
        'destination', 'synthetic-analytics-lake',
        'failure_reason', 'destination_unavailable',
        'retry_scheduled', TRUE
    )
FROM fixture_audit_company_context AS context
WHERE context.company_slug = 'lumenforge-technologies-us';

-- ============================================================
-- Resolve manual event specifications to generated identities
-- ============================================================

CREATE TEMP TABLE fixture_resolved_manual_audit_events
ON COMMIT DROP
AS
SELECT
    specifications.*,
    context.company_id,
    entities.entity_schema,
    entities.entity_table,
    entities.entity_record_id,
    actor_selection.actor_account_id,
    actor_accounts.person_id AS actor_person_id,
    workflows.workflow_instance_id,
    CASE specifications.time_source
        WHEN 'reference' THEN context.reference_at
        WHEN 'entity_created' THEN entities.entity_created_at
        WHEN 'workflow' THEN workflows.started_at
        ELSE NULL::TIMESTAMPTZ
    END + specifications.event_offset AS event_occurred_at,
    CASE
        WHEN specifications.include_client_context
            THEN context.client_ip
        ELSE NULL::INET
    END AS client_ip,
    CASE
        WHEN specifications.include_client_context
            THEN 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) BusinessCoreFixture/1.0'
        ELSE NULL::TEXT
    END AS user_agent
FROM fixture_manual_audit_event_specs AS specifications
JOIN fixture_audit_company_context AS context
  ON context.company_slug = specifications.company_slug
LEFT JOIN fixture_audit_workflow_context AS workflows
  ON workflows.company_id = context.company_id
 AND workflows.scenario_key = specifications.workflow_scenario_key
LEFT JOIN LATERAL (
    SELECT
        CASE specifications.actor_context
            WHEN 'creator' THEN context.creator_account_id
            WHEN 'admin' THEN context.admin_account_id
            WHEN 'finance' THEN context.finance_account_id
            WHEN 'people' THEN context.people_account_id
            WHEN 'operations' THEN context.operations_account_id
            WHEN 'integration' THEN context.integration_account_id
            WHEN 'none' THEN NULL::BIGINT
            ELSE NULL::BIGINT
        END AS actor_account_id
) AS actor_selection
  ON TRUE
LEFT JOIN identity.user_accounts AS actor_accounts
  ON actor_accounts.account_id = actor_selection.actor_account_id
LEFT JOIN LATERAL (
    SELECT
        'core'::TEXT AS entity_schema,
        'companies'::TEXT AS entity_table,
        companies.company_id AS entity_record_id,
        companies.created_at AS entity_created_at
    FROM core.companies AS companies
    WHERE specifications.entity_kind = 'company'
      AND companies.company_id = context.company_id
      AND companies.company_slug = specifications.entity_business_key

    UNION ALL

    SELECT
        'people'::TEXT,
        'persons'::TEXT,
        persons.person_id,
        persons.created_at
    FROM people.persons AS persons
    WHERE specifications.entity_kind = 'person'
      AND persons.company_id = context.company_id
      AND persons.external_reference = specifications.entity_business_key

    UNION ALL

    SELECT
        'identity'::TEXT,
        'user_accounts'::TEXT,
        accounts.account_id,
        accounts.created_at
    FROM people.persons AS persons
    JOIN identity.user_accounts AS accounts
      ON accounts.person_id = persons.person_id
    WHERE specifications.entity_kind = 'user_account'
      AND persons.company_id = context.company_id
      AND persons.external_reference = specifications.entity_business_key

    UNION ALL

    SELECT
        'finance'::TEXT,
        'financial_transactions'::TEXT,
        transactions.transaction_id,
        transactions.created_at
    FROM finance.financial_transactions AS transactions
    WHERE specifications.entity_kind = 'financial_transaction'
      AND transactions.company_id = context.company_id
      AND transactions.transaction_number = specifications.entity_business_key

    UNION ALL

    SELECT
        'documents'::TEXT,
        'document_records'::TEXT,
        documents.document_id,
        documents.created_at
    FROM documents.document_records AS documents
    WHERE specifications.entity_kind = 'document_record'
      AND documents.company_id = context.company_id
      AND documents.document_number = specifications.entity_business_key
) AS entities
  ON TRUE;

CREATE UNIQUE INDEX fixture_resolved_manual_audit_events_key_idx
    ON fixture_resolved_manual_audit_events (event_key);

DO $$
DECLARE
    expected_events INTEGER;
    resolved_events INTEGER;
BEGIN
    SELECT COUNT(*)
    INTO expected_events
    FROM fixture_manual_audit_event_specs;

    SELECT COUNT(*)
    INTO resolved_events
    FROM fixture_resolved_manual_audit_events;

    IF resolved_events <> expected_events THEN
        RAISE EXCEPTION
            '08_audit.sql resolved % manual audit-event specifications; expected %.',
            resolved_events,
            expected_events;
    END IF;

    IF EXISTS (
        SELECT 1
        FROM fixture_resolved_manual_audit_events
        WHERE entity_schema IS NULL
           OR entity_table IS NULL
           OR entity_record_id IS NULL
           OR event_occurred_at IS NULL
    ) THEN
        RAISE EXCEPTION
            '08_audit.sql could not resolve an entity target or occurrence timestamp for one or more manual audit events.';
    END IF;

    IF EXISTS (
        SELECT 1
        FROM fixture_resolved_manual_audit_events
        WHERE workflow_scenario_key IS NOT NULL
          AND workflow_instance_id IS NULL
    ) THEN
        RAISE EXCEPTION
            '08_audit.sql could not resolve a workflow instance for one or more workflow-linked manual audit events.';
    END IF;

    IF EXISTS (
        SELECT 1
        FROM fixture_resolved_manual_audit_events
        WHERE actor_context <> 'none'
          AND actor_account_id IS NULL
    ) THEN
        RAISE EXCEPTION
            '08_audit.sql could not resolve an actor account for one or more manual audit events.';
    END IF;
END;
$$;

-- ============================================================
-- Manual cross-domain audit events
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
    request_id,
    session_id,
    source_system,
    client_ip,
    user_agent,
    event_summary,
    metadata
)
SELECT
    events.event_occurred_at,
    events.action_category,
    events.action_type,
    events.event_outcome,
    events.severity,
    events.entity_schema,
    events.entity_table,
    events.entity_record_id,
    events.actor_account_id,
    events.actor_person_id,
    events.company_id,
    events.workflow_instance_id,
    'req-' || md5(events.event_key),
    CASE
        WHEN events.session_key IS NOT NULL
            THEN 'sess-' || md5(events.session_key)
        ELSE NULL::TEXT
    END,
    events.source_system,
    events.client_ip,
    events.user_agent,
    events.event_summary,
    events.metadata
        || jsonb_build_object(
            'fixture', 'realistic_multi_company',
            'fixture_event_key', events.event_key,
            'event_family', 'manual_cross_domain',
            'company_slug', events.company_slug,
            'entity_business_key', events.entity_business_key
        )
FROM fixture_resolved_manual_audit_events AS events;

-- ============================================================
-- Workflow status-history audit-event specifications
-- ============================================================

CREATE TEMP TABLE fixture_workflow_history_audit_event_specs
ON COMMIT DROP
AS
WITH ranked_history AS (
    SELECT
        workflow_context.company_slug,
        workflow_context.company_id,
        workflow_context.workflow_instance_id,
        workflow_context.workflow_definition_id,
        workflow_context.workflow_key,
        workflow_context.scenario_key,
        workflow_context.title AS workflow_title,
        history.workflow_status_history_id,
        history.from_status,
        history.to_status,
        history.from_step_id,
        history.to_step_id,
        history.changed_by_account_id,
        history.changed_at,
        history.note,
        history.metadata AS history_metadata,
        ROW_NUMBER() OVER (
            PARTITION BY workflow_context.workflow_instance_id
            ORDER BY
                history.changed_at,
                history.workflow_status_history_id
        ) AS history_sequence
    FROM fixture_audit_workflow_context AS workflow_context
    JOIN workflows.workflow_status_history AS history
      ON history.company_id = workflow_context.company_id
     AND history.workflow_instance_id = workflow_context.workflow_instance_id
     AND history.workflow_definition_id = workflow_context.workflow_definition_id
)
SELECT
    ranked.company_slug
        || ':workflow:'
        || ranked.scenario_key
        || ':history:'
        || LPAD(ranked.history_sequence::TEXT, 3, '0')
        AS event_key,
    ranked.company_slug,
    ranked.company_id,
    ranked.workflow_instance_id,
    ranked.workflow_definition_id,
    ranked.workflow_key,
    ranked.scenario_key,
    ranked.workflow_title,
    ranked.workflow_status_history_id,
    ranked.history_sequence,
    ranked.from_status,
    ranked.to_status,
    ranked.from_step_id,
    ranked.to_step_id,
    from_steps.step_key AS from_step_key,
    to_steps.step_key AS to_step_key,
    ranked.changed_by_account_id AS actor_account_id,
    actor_accounts.person_id AS actor_person_id,
    ranked.changed_at AS event_occurred_at,
    CASE
        WHEN ranked.from_status IS NULL THEN 'CREATE'
        WHEN ranked.to_status = 'cancelled' THEN 'CANCEL'
        ELSE 'STATUS_CHANGE'
    END AS action_type,
    CASE
        WHEN ranked.to_status = 'failed' THEN 'FAILURE'
        WHEN ranked.to_status = 'paused' THEN 'WARNING'
        ELSE 'SUCCESS'
    END AS event_outcome,
    CASE
        WHEN ranked.to_status = 'failed' THEN 'ERROR'
        WHEN ranked.to_status = 'paused' THEN 'WARNING'
        ELSE 'INFO'
    END AS severity,
    CASE
        WHEN ranked.from_status IS NULL THEN
            'Created workflow instance "' || ranked.workflow_title || '" in status ' || ranked.to_status || '.'
        WHEN ranked.from_status IS DISTINCT FROM ranked.to_status THEN
            'Changed workflow "' || ranked.workflow_title || '" from status ' || ranked.from_status || ' to ' || ranked.to_status || '.'
        ELSE
            'Moved workflow "' || ranked.workflow_title || '" from step '
            || COALESCE(from_steps.step_key, 'none')
            || ' to '
            || COALESCE(to_steps.step_key, 'none')
            || '.'
    END AS event_summary,
    COALESCE(ranked.history_metadata, '{}'::JSONB)
        || jsonb_build_object(
            'fixture', 'realistic_multi_company',
            'event_family', 'workflow_history',
            'workflow_key', ranked.workflow_key,
            'workflow_scenario', ranked.scenario_key,
            'history_sequence', ranked.history_sequence,
            'from_status', ranked.from_status,
            'to_status', ranked.to_status,
            'from_step_key', from_steps.step_key,
            'to_step_key', to_steps.step_key,
            'history_note', ranked.note
        ) AS metadata
FROM ranked_history AS ranked
LEFT JOIN workflows.workflow_steps AS from_steps
  ON from_steps.workflow_definition_id = ranked.workflow_definition_id
 AND from_steps.workflow_step_id = ranked.from_step_id
LEFT JOIN workflows.workflow_steps AS to_steps
  ON to_steps.workflow_definition_id = ranked.workflow_definition_id
 AND to_steps.workflow_step_id = ranked.to_step_id
LEFT JOIN identity.user_accounts AS actor_accounts
  ON actor_accounts.account_id = ranked.changed_by_account_id;

CREATE UNIQUE INDEX fixture_workflow_history_audit_event_specs_key_idx
    ON fixture_workflow_history_audit_event_specs (event_key);

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
    request_id,
    session_id,
    source_system,
    event_summary,
    metadata
)
SELECT
    specifications.event_occurred_at,
    'WORKFLOW',
    specifications.action_type,
    specifications.event_outcome,
    specifications.severity,
    'workflows',
    'workflow_instances',
    specifications.workflow_instance_id,
    specifications.actor_account_id,
    specifications.actor_person_id,
    specifications.company_id,
    specifications.workflow_instance_id,
    'req-' || md5(specifications.event_key),
    'wf-' || md5(
        specifications.company_slug
        || ':'
        || specifications.scenario_key
    ),
    'workflow_engine',
    specifications.event_summary,
    specifications.metadata
        || jsonb_build_object(
            'fixture_event_key', specifications.event_key,
            'company_slug', specifications.company_slug
        )
FROM fixture_workflow_history_audit_event_specs AS specifications;

-- ============================================================
-- Workflow task-assignment audit-event specifications
-- ============================================================

CREATE TEMP TABLE fixture_task_assignment_audit_event_specs
ON COMMIT DROP
AS
SELECT
    workflow_context.company_slug
        || ':workflow:'
        || workflow_context.scenario_key
        || ':task:'
        || (tasks.metadata::jsonb ->> 'task_key')
        || ':assignment:'
        || assignments.assignment_type
        || ':'
        || CASE
            WHEN assignments.account_id IS NOT NULL
                THEN 'account:' || target_accounts.account_email
            ELSE 'role:' || target_roles.role_key
        END
        AS event_key,
    workflow_context.company_slug,
    workflow_context.company_id,
    workflow_context.workflow_instance_id,
    workflow_context.scenario_key,
    tasks.workflow_task_id,
    (tasks.metadata::jsonb ->> 'task_key') AS task_key,
    tasks.title AS task_title,
    assignments.workflow_task_assignment_id,
    assignments.assignment_type,
    assignments.account_id AS target_account_id,
    target_accounts.account_email AS target_account_email,
    assignments.role_id AS target_role_id,
    target_roles.role_key AS target_role_key,
    assignments.assigned_by_account_id AS actor_account_id,
    actor_accounts.person_id AS actor_person_id,
    assignments.assigned_at AS event_occurred_at,
    'Assigned '
        || CASE
            WHEN assignments.account_id IS NOT NULL
                THEN 'account ' || target_accounts.account_email
            ELSE 'role ' || target_roles.role_key
        END
        || ' as '
        || assignments.assignment_type
        || ' for workflow task "'
        || tasks.title
        || '".'
        AS event_summary,
    jsonb_build_object(
        'fixture', 'realistic_multi_company',
        'event_family', 'workflow_task_assignment',
        'workflow_scenario', workflow_context.scenario_key,
        'task_key', (tasks.metadata::jsonb ->> 'task_key'),
        'assignment_type', assignments.assignment_type,
        'target_account_email', target_accounts.account_email,
        'target_role_key', target_roles.role_key
    ) AS metadata
FROM fixture_audit_workflow_context AS workflow_context
JOIN workflows.workflow_tasks AS tasks
  ON tasks.company_id = workflow_context.company_id
 AND tasks.workflow_instance_id = workflow_context.workflow_instance_id
 AND tasks.workflow_definition_id = workflow_context.workflow_definition_id
 AND (tasks.metadata::jsonb ->> 'fixture') = 'realistic_multi_company'
JOIN workflows.workflow_task_assignments AS assignments
  ON assignments.company_id = tasks.company_id
 AND assignments.workflow_task_id = tasks.workflow_task_id
LEFT JOIN identity.user_accounts AS target_accounts
  ON target_accounts.account_id = assignments.account_id
LEFT JOIN identity.access_roles AS target_roles
  ON target_roles.role_id = assignments.role_id
LEFT JOIN identity.user_accounts AS actor_accounts
  ON actor_accounts.account_id = assignments.assigned_by_account_id;

CREATE UNIQUE INDEX fixture_task_assignment_audit_event_specs_key_idx
    ON fixture_task_assignment_audit_event_specs (event_key);

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
    request_id,
    session_id,
    source_system,
    event_summary,
    metadata
)
SELECT
    specifications.event_occurred_at,
    'WORKFLOW',
    'ASSIGN',
    'SUCCESS',
    'INFO',
    'workflows',
    'workflow_tasks',
    specifications.workflow_task_id,
    specifications.actor_account_id,
    specifications.actor_person_id,
    specifications.company_id,
    specifications.workflow_instance_id,
    'req-' || md5(specifications.event_key),
    'wf-' || md5(
        specifications.company_slug
        || ':'
        || specifications.scenario_key
    ),
    'workflow_engine',
    specifications.event_summary,
    specifications.metadata
        || jsonb_build_object(
            'fixture_event_key', specifications.event_key,
            'company_slug', specifications.company_slug
        )
FROM fixture_task_assignment_audit_event_specs AS specifications;

-- ============================================================
-- Workflow task-outcome audit-event specifications
-- ============================================================

CREATE TEMP TABLE fixture_task_status_audit_event_specs
ON COMMIT DROP
AS
SELECT
    workflow_context.company_slug
        || ':workflow:'
        || workflow_context.scenario_key
        || ':task:'
        || (tasks.metadata::jsonb ->> 'task_key')
        || ':status:'
        || tasks.status
        AS event_key,
    workflow_context.company_slug,
    workflow_context.company_id,
    workflow_context.workflow_instance_id,
    workflow_context.scenario_key,
    tasks.workflow_task_id,
    (tasks.metadata::jsonb ->> 'task_key') AS task_key,
    tasks.title AS task_title,
    tasks.status AS to_status,
    CASE
        WHEN tasks.status IN ('completed', 'failed') THEN 'in_progress'
        ELSE 'open'
    END AS from_status,
    COALESCE(
        tasks.completed_by_account_id,
        workflow_context.started_by_account_id
    ) AS actor_account_id,
    actor_accounts.person_id AS actor_person_id,
    COALESCE(
        tasks.completed_at,
        workflow_context.cancelled_at,
        workflow_context.completed_at,
        tasks.updated_at
    ) AS event_occurred_at,
    CASE
        WHEN tasks.status = 'cancelled' THEN 'CANCEL'
        WHEN tasks.status = 'failed' THEN 'REJECT'
        ELSE 'STATUS_CHANGE'
    END AS action_type,
    CASE
        WHEN tasks.status = 'failed' THEN 'FAILURE'
        ELSE 'SUCCESS'
    END AS event_outcome,
    CASE
        WHEN tasks.status = 'failed' THEN 'ERROR'
        ELSE 'INFO'
    END AS severity,
    CASE
        WHEN tasks.status = 'completed' THEN
            'Completed workflow task "' || tasks.title || '".'
        WHEN tasks.status = 'cancelled' THEN
            'Cancelled workflow task "' || tasks.title || '".'
        WHEN tasks.status = 'failed' THEN
            'Marked workflow task "' || tasks.title || '" as failed.'
        WHEN tasks.status = 'skipped' THEN
            'Skipped workflow task "' || tasks.title || '".'
        ELSE
            'Changed workflow task "' || tasks.title || '" to status ' || tasks.status || '.'
    END AS event_summary,
    jsonb_build_object(
        'fixture', 'realistic_multi_company',
        'event_family', 'workflow_task_status',
        'workflow_scenario', workflow_context.scenario_key,
        'task_key', (tasks.metadata::jsonb ->> 'task_key'),
        'from_status', CASE
            WHEN tasks.status IN ('completed', 'failed') THEN 'in_progress'
            ELSE 'open'
        END,
        'to_status', tasks.status,
        'priority', tasks.priority
    ) AS metadata
FROM fixture_audit_workflow_context AS workflow_context
JOIN workflows.workflow_tasks AS tasks
  ON tasks.company_id = workflow_context.company_id
 AND tasks.workflow_instance_id = workflow_context.workflow_instance_id
 AND tasks.workflow_definition_id = workflow_context.workflow_definition_id
 AND (tasks.metadata::jsonb ->> 'fixture') = 'realistic_multi_company'
LEFT JOIN identity.user_accounts AS actor_accounts
  ON actor_accounts.account_id = COALESCE(
        tasks.completed_by_account_id,
        workflow_context.started_by_account_id
  )
WHERE tasks.status IN (
    'completed',
    'cancelled',
    'skipped',
    'failed'
);

CREATE UNIQUE INDEX fixture_task_status_audit_event_specs_key_idx
    ON fixture_task_status_audit_event_specs (event_key);

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
    request_id,
    session_id,
    source_system,
    event_summary,
    metadata
)
SELECT
    specifications.event_occurred_at,
    'WORKFLOW',
    specifications.action_type,
    specifications.event_outcome,
    specifications.severity,
    'workflows',
    'workflow_tasks',
    specifications.workflow_task_id,
    specifications.actor_account_id,
    specifications.actor_person_id,
    specifications.company_id,
    specifications.workflow_instance_id,
    'req-' || md5(specifications.event_key),
    'wf-' || md5(
        specifications.company_slug
        || ':'
        || specifications.scenario_key
    ),
    'workflow_engine',
    specifications.event_summary,
    specifications.metadata
        || jsonb_build_object(
            'fixture_event_key', specifications.event_key,
            'company_slug', specifications.company_slug
        )
FROM fixture_task_status_audit_event_specs AS specifications;

-- ============================================================
-- Manual field-level audit changes
-- ============================================================

CREATE TEMP TABLE fixture_manual_audit_change_specs (
    event_key TEXT NOT NULL,
    field_name TEXT NOT NULL,
    old_value JSONB,
    new_value JSONB,
    PRIMARY KEY (event_key, field_name)
) ON COMMIT DROP;

INSERT INTO fixture_manual_audit_change_specs (
    event_key,
    field_name,
    old_value,
    new_value
)
SELECT
    events.event_key,
    'account_status',
    to_jsonb('pending'::TEXT),
    to_jsonb(accounts.account_status)
FROM fixture_resolved_manual_audit_events AS events
JOIN identity.user_accounts AS accounts
  ON accounts.account_id = events.entity_record_id
WHERE events.event_key LIKE '%:identity.account_activated'

UNION ALL

SELECT
    events.event_key,
    'person_status',
    to_jsonb('inactive'::TEXT),
    to_jsonb(persons.person_status)
FROM fixture_resolved_manual_audit_events AS events
JOIN people.persons AS persons
  ON persons.person_id = events.entity_record_id
WHERE events.event_key LIKE '%:data.onboarding_person_activated'

UNION ALL

SELECT
    events.event_key,
    'status',
    to_jsonb('draft'::TEXT),
    to_jsonb(transactions.status)
FROM fixture_resolved_manual_audit_events AS events
JOIN finance.financial_transactions AS transactions
  ON transactions.transaction_id = events.entity_record_id
WHERE events.event_key LIKE '%:finance.transaction_posted'

UNION ALL

SELECT
    events.event_key,
    'posting_date',
    NULL::JSONB,
    to_jsonb(transactions.posting_date)
FROM fixture_resolved_manual_audit_events AS events
JOIN finance.financial_transactions AS transactions
  ON transactions.transaction_id = events.entity_record_id
WHERE events.event_key LIKE '%:finance.transaction_posted'

UNION ALL

SELECT
    events.event_key,
    'document_status',
    to_jsonb('draft'::TEXT),
    to_jsonb('active'::TEXT)
FROM fixture_resolved_manual_audit_events AS events
WHERE events.event_key LIKE '%:document.record_activated'

UNION ALL

SELECT
    events.event_key,
    'effective_date',
    NULL::JSONB,
    to_jsonb(documents.effective_date)
FROM fixture_resolved_manual_audit_events AS events
JOIN documents.document_records AS documents
  ON documents.document_id = events.entity_record_id
WHERE events.event_key LIKE '%:document.record_activated'

UNION ALL

SELECT
    events.event_key,
    'company_status',
    to_jsonb('active'::TEXT),
    to_jsonb(companies.company_status)
FROM fixture_resolved_manual_audit_events AS events
JOIN core.companies AS companies
  ON companies.company_id = events.entity_record_id
WHERE events.event_key LIKE '%:data.company_inactivated'

UNION ALL

SELECT
    events.event_key,
    'document_status',
    to_jsonb('active'::TEXT),
    to_jsonb(documents.document_status)
FROM fixture_resolved_manual_audit_events AS events
JOIN documents.document_records AS documents
  ON documents.document_id = events.entity_record_id
WHERE events.event_key LIKE '%:document.record_archived';

INSERT INTO audit.audit_event_changes (
    audit_event_id,
    field_name,
    old_value,
    new_value
)
SELECT
    events.audit_event_id,
    changes.field_name,
    changes.old_value,
    changes.new_value
FROM fixture_manual_audit_change_specs AS changes
JOIN audit.audit_events AS events
  ON events.metadata ->> 'fixture_event_key' = changes.event_key
 AND events.metadata ->> 'fixture' = 'realistic_multi_company';

-- ============================================================
-- Workflow status and step changes
-- ============================================================

INSERT INTO audit.audit_event_changes (
    audit_event_id,
    field_name,
    old_value,
    new_value
)
SELECT
    events.audit_event_id,
    'status',
    CASE
        WHEN specifications.from_status IS NULL
            THEN NULL::JSONB
        ELSE to_jsonb(specifications.from_status)
    END,
    to_jsonb(specifications.to_status)
FROM fixture_workflow_history_audit_event_specs AS specifications
JOIN audit.audit_events AS events
  ON events.metadata ->> 'fixture_event_key' = specifications.event_key
 AND events.metadata ->> 'fixture' = 'realistic_multi_company'
WHERE specifications.from_status IS DISTINCT FROM specifications.to_status

UNION ALL

SELECT
    events.audit_event_id,
    'current_step_id',
    CASE
        WHEN specifications.from_step_id IS NULL
            THEN NULL::JSONB
        ELSE to_jsonb(specifications.from_step_id)
    END,
    CASE
        WHEN specifications.to_step_id IS NULL
            THEN NULL::JSONB
        ELSE to_jsonb(specifications.to_step_id)
    END
FROM fixture_workflow_history_audit_event_specs AS specifications
JOIN audit.audit_events AS events
  ON events.metadata ->> 'fixture_event_key' = specifications.event_key
 AND events.metadata ->> 'fixture' = 'realistic_multi_company'
WHERE specifications.from_step_id IS DISTINCT FROM specifications.to_step_id;

-- ============================================================
-- Workflow task-assignment changes
-- ============================================================

INSERT INTO audit.audit_event_changes (
    audit_event_id,
    field_name,
    old_value,
    new_value
)
SELECT
    events.audit_event_id,
    'assigned_to_account_id',
    NULL::JSONB,
    to_jsonb(specifications.target_account_id)
FROM fixture_task_assignment_audit_event_specs AS specifications
JOIN audit.audit_events AS events
  ON events.metadata ->> 'fixture_event_key' = specifications.event_key
 AND events.metadata ->> 'fixture' = 'realistic_multi_company'
WHERE specifications.assignment_type = 'owner'
  AND specifications.target_account_id IS NOT NULL;

-- ============================================================
-- Workflow task status changes
-- ============================================================

INSERT INTO audit.audit_event_changes (
    audit_event_id,
    field_name,
    old_value,
    new_value
)
SELECT
    events.audit_event_id,
    'status',
    to_jsonb(specifications.from_status),
    to_jsonb(specifications.to_status)
FROM fixture_task_status_audit_event_specs AS specifications
JOIN audit.audit_events AS events
  ON events.metadata ->> 'fixture_event_key' = specifications.event_key
 AND events.metadata ->> 'fixture' = 'realistic_multi_company';

-- ============================================================
-- Post-load validation
-- ============================================================

DO $$
DECLARE
    expected_event_count BIGINT;
    actual_event_count BIGINT;
    expected_change_count BIGINT;
    actual_change_count BIGINT;
BEGIN
    SELECT
        (SELECT COUNT(*) FROM fixture_manual_audit_event_specs)
        + (SELECT COUNT(*) FROM fixture_workflow_history_audit_event_specs)
        + (SELECT COUNT(*) FROM fixture_task_assignment_audit_event_specs)
        + (SELECT COUNT(*) FROM fixture_task_status_audit_event_specs)
    INTO expected_event_count;

    SELECT COUNT(*)
    INTO actual_event_count
    FROM audit.audit_events
    WHERE metadata ->> 'fixture' = 'realistic_multi_company';

    IF actual_event_count <> expected_event_count THEN
        RAISE EXCEPTION
            '08_audit.sql loaded % fixture audit events; expected %.',
            actual_event_count,
            expected_event_count;
    END IF;

    IF EXISTS (
        SELECT 1
        FROM audit.audit_events
        WHERE metadata ->> 'fixture' = 'realistic_multi_company'
        GROUP BY metadata ->> 'fixture_event_key'
        HAVING COUNT(*) <> 1
            OR metadata ->> 'fixture_event_key' IS NULL
    ) THEN
        RAISE EXCEPTION
            '08_audit.sql found a missing or duplicate fixture_event_key in the audit event set.';
    END IF;

    SELECT
        (SELECT COUNT(*) FROM fixture_manual_audit_change_specs)
        + (
            SELECT COUNT(*)
            FROM fixture_workflow_history_audit_event_specs
            WHERE from_status IS DISTINCT FROM to_status
        )
        + (
            SELECT COUNT(*)
            FROM fixture_workflow_history_audit_event_specs
            WHERE from_step_id IS DISTINCT FROM to_step_id
        )
        + (
            SELECT COUNT(*)
            FROM fixture_task_assignment_audit_event_specs
            WHERE assignment_type = 'owner'
              AND target_account_id IS NOT NULL
        )
        + (SELECT COUNT(*) FROM fixture_task_status_audit_event_specs)
    INTO expected_change_count;

    SELECT COUNT(*)
    INTO actual_change_count
    FROM audit.audit_event_changes AS changes
    JOIN audit.audit_events AS events
      ON events.audit_event_id = changes.audit_event_id
    WHERE events.metadata ->> 'fixture' = 'realistic_multi_company';

    IF actual_change_count <> expected_change_count THEN
        RAISE EXCEPTION
            '08_audit.sql loaded % fixture audit-event changes; expected %.',
            actual_change_count,
            expected_change_count;
    END IF;

    IF EXISTS (
        SELECT required_category.action_category
        FROM (
            VALUES
                ('DATA'),
                ('IDENTITY'),
                ('WORKFLOW'),
                ('FINANCE'),
                ('DOCUMENT'),
                ('SECURITY'),
                ('INTEGRATION'),
                ('SYSTEM')
        ) AS required_category (action_category)

        EXCEPT

        SELECT DISTINCT events.action_category
        FROM audit.audit_events AS events
        WHERE events.metadata ->> 'fixture' = 'realistic_multi_company'
    ) THEN
        RAISE EXCEPTION
            '08_audit.sql did not populate every supported audit action category.';
    END IF;

    IF EXISTS (
        SELECT 1
        FROM audit.audit_events AS events
        JOIN identity.user_accounts AS accounts
          ON accounts.account_id = events.actor_account_id
        WHERE events.metadata ->> 'fixture' = 'realistic_multi_company'
          AND events.actor_person_id IS DISTINCT FROM accounts.person_id
    ) THEN
        RAISE EXCEPTION
            '08_audit.sql found an actor_person_id that does not match its actor account.';
    END IF;

    IF EXISTS (
        SELECT 1
        FROM audit.audit_events AS events
        WHERE events.metadata ->> 'fixture' = 'realistic_multi_company'
          AND events.metadata ->> 'event_family' IN (
                'workflow_history',
                'workflow_task_assignment',
                'workflow_task_status'
          )
          AND events.workflow_instance_id IS NULL
    ) THEN
        RAISE EXCEPTION
            '08_audit.sql found a workflow-derived audit event without a workflow_instance_id.';
    END IF;

    IF EXISTS (
        SELECT 1
        FROM audit.audit_event_changes AS changes
        JOIN audit.audit_events AS events
          ON events.audit_event_id = changes.audit_event_id
        WHERE events.metadata ->> 'fixture' = 'realistic_multi_company'
          AND changes.old_value IS NOT DISTINCT FROM changes.new_value
    ) THEN
        RAISE EXCEPTION
            '08_audit.sql found a field-level change whose old and new values are equal.';
    END IF;
END;
$$;

COMMIT;

\echo '08_audit.sql completed successfully.'
