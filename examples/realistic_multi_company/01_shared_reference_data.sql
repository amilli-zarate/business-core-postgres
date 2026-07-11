\set ON_ERROR_STOP on

BEGIN;

-- ============================================================
-- 01_shared_reference_data.sql
-- Realistic multi-company example
--
-- Purpose:
-- Seed reference records that are intentionally shared by every
-- company in the example database.
--
-- Notes:
-- - All records are synthetic demonstration data.
-- - This script is safe to run more than once.
-- - Retention periods are illustrative defaults only; they are
--   not legal or regulatory guidance.
-- ============================================================


-- ============================================================
-- Currencies
-- ============================================================

INSERT INTO finance.currencies (
    currency_code,
    currency_name,
    minor_units,
    is_active
)
VALUES
    ('MXN', 'Mexican peso', 2, TRUE),
    ('USD', 'United States dollar', 2, TRUE),
    ('CAD', 'Canadian dollar', 2, TRUE),
    ('EUR', 'Euro', 2, TRUE),
    ('GBP', 'Pound sterling', 2, TRUE),
    ('JPY', 'Japanese yen', 0, TRUE),
    ('CNY', 'Chinese yuan', 2, TRUE),
    ('BRL', 'Brazilian real', 2, TRUE),
    ('COP', 'Colombian peso', 2, TRUE),
    ('CLP', 'Chilean peso', 0, TRUE),
    ('PEN', 'Peruvian sol', 2, TRUE),
    ('ARS', 'Argentine peso', 2, TRUE)
ON CONFLICT (currency_code) DO UPDATE
SET
    currency_name = EXCLUDED.currency_name,
    minor_units = EXCLUDED.minor_units,
    is_active = EXCLUDED.is_active;


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
        'platform.manage',
        'Manage platform',
        'Manage platform-wide configuration and shared reference data.'
    ),
    (
        'company.read',
        'View companies',
        'View company profiles and company-level configuration.'
    ),
    (
        'company.manage',
        'Manage companies',
        'Create and update company profiles and company-level configuration.'
    ),
    (
        'organization.read',
        'View organizational structure',
        'View branches, departments, addresses, and organizational hierarchies.'
    ),
    (
        'organization.manage',
        'Manage organizational structure',
        'Create and update branches, departments, addresses, and organizational hierarchies.'
    ),
    (
        'people.read',
        'View people',
        'View people and their contact information.'
    ),
    (
        'people.manage',
        'Manage people',
        'Create and update people and their contact information.'
    ),
    (
        'relationships.read',
        'View business relationships',
        'View company roles, department assignments, reporting lines, and person relationships.'
    ),
    (
        'relationships.manage',
        'Manage business relationships',
        'Create and update company roles, department assignments, reporting lines, and person relationships.'
    ),
    (
        'identity.accounts.read',
        'View user accounts',
        'View application user accounts and authentication identities.'
    ),
    (
        'identity.accounts.manage',
        'Manage user accounts',
        'Create, update, suspend, and close application user accounts.'
    ),
    (
        'identity.access.read',
        'View access control',
        'View access roles, permissions, and scoped role assignments.'
    ),
    (
        'identity.access.manage',
        'Manage access control',
        'Manage access roles, permissions, and scoped role assignments.'
    ),
    (
        'finance.read',
        'View finance data',
        'View fiscal periods, cost centers, accounts, and financial transactions.'
    ),
    (
        'finance.manage',
        'Manage finance data',
        'Create and update fiscal periods, cost centers, accounts, and draft financial transactions.'
    ),
    (
        'finance.post',
        'Post financial transactions',
        'Post and void financial transactions after validation.'
    ),
    (
        'finance.periods.close',
        'Close fiscal periods',
        'Close and lock fiscal periods.'
    ),
    (
        'documents.read',
        'View documents',
        'View document metadata, versions, links, and status history.'
    ),
    (
        'documents.manage',
        'Manage documents',
        'Create and update document metadata, versions, links, and lifecycle information.'
    ),
    (
        'documents.approve',
        'Approve documents',
        'Approve, activate, supersede, or reject controlled documents.'
    ),
    (
        'workflows.read',
        'View workflows',
        'View workflow definitions, instances, tasks, assignments, and history.'
    ),
    (
        'workflows.manage',
        'Manage workflows',
        'Create and maintain workflow definitions, steps, and transitions.'
    ),
    (
        'workflows.execute',
        'Execute workflows',
        'Start workflows and act on assigned workflow tasks.'
    ),
    (
        'analytics.read',
        'View analytics',
        'View analytical and reporting interfaces.'
    ),
    (
        'audit.read',
        'View audit trail',
        'View audit events and operational history.'
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
        'Full administrative access across the platform and all companies.',
        'platform',
        TRUE,
        TRUE
    ),
    (
        'company_admin',
        'Company Administrator',
        'Full administrative access within one company.',
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
        'department_manager',
        'Department Manager',
        'People, document, workflow, and reporting access within one department.',
        'department',
        TRUE,
        TRUE
    ),
    (
        'finance_manager',
        'Finance Manager',
        'Full finance operations, transaction posting, period control, and financial reporting.',
        'company',
        TRUE,
        TRUE
    ),
    (
        'finance_analyst',
        'Finance Analyst',
        'Finance preparation, analysis, document review, and reporting access without posting authority.',
        'company',
        TRUE,
        TRUE
    ),
    (
        'people_manager',
        'People Manager',
        'Management of people, organizational relationships, and related documents and workflows.',
        'company',
        TRUE,
        TRUE
    ),
    (
        'operations_manager',
        'Operations Manager',
        'Management of organizational operations, relationships, documents, and workflows.',
        'company',
        TRUE,
        TRUE
    ),
    (
        'document_manager',
        'Document Manager',
        'Management and approval of controlled business documents.',
        'company',
        TRUE,
        TRUE
    ),
    (
        'workflow_manager',
        'Workflow Manager',
        'Design, maintenance, execution, and supervision of business workflows.',
        'company',
        TRUE,
        TRUE
    ),
    (
        'auditor',
        'Auditor',
        'Read-only access to business records, access configuration, analytics, and audit history.',
        'company',
        TRUE,
        TRUE
    ),
    (
        'read_only',
        'Read Only',
        'General read-only access to operational records and analytics within one company.',
        'company',
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
    updated_at = NOW();


-- ============================================================
-- Role-permission mappings
-- ============================================================

WITH seeded_permissions AS (
    SELECT
        permission_id,
        permission_key
    FROM identity.permissions
    WHERE permission_key = ANY (
        ARRAY[
            'platform.manage',
            'company.read',
            'company.manage',
            'organization.read',
            'organization.manage',
            'people.read',
            'people.manage',
            'relationships.read',
            'relationships.manage',
            'identity.accounts.read',
            'identity.accounts.manage',
            'identity.access.read',
            'identity.access.manage',
            'finance.read',
            'finance.manage',
            'finance.post',
            'finance.periods.close',
            'documents.read',
            'documents.manage',
            'documents.approve',
            'workflows.read',
            'workflows.manage',
            'workflows.execute',
            'analytics.read',
            'audit.read'
        ]::TEXT[]
    )
),
role_permission_keys (role_key, permission_key) AS (
    -- Platform administrators receive every permission defined by this file.
    SELECT
        'platform_admin',
        permission_key
    FROM seeded_permissions

    UNION ALL

    -- Company administrators receive every seeded permission except
    -- platform-wide administration.
    SELECT
        'company_admin',
        permission_key
    FROM seeded_permissions
    WHERE permission_key <> 'platform.manage'

    UNION ALL

    SELECT
        role_key,
        permission_key
    FROM (
        VALUES
            -- Branch manager
            ('branch_manager', 'company.read'),
            ('branch_manager', 'organization.read'),
            ('branch_manager', 'organization.manage'),
            ('branch_manager', 'people.read'),
            ('branch_manager', 'people.manage'),
            ('branch_manager', 'relationships.read'),
            ('branch_manager', 'relationships.manage'),
            ('branch_manager', 'finance.read'),
            ('branch_manager', 'documents.read'),
            ('branch_manager', 'documents.manage'),
            ('branch_manager', 'workflows.read'),
            ('branch_manager', 'workflows.execute'),
            ('branch_manager', 'analytics.read'),

            -- Department manager
            ('department_manager', 'company.read'),
            ('department_manager', 'organization.read'),
            ('department_manager', 'people.read'),
            ('department_manager', 'relationships.read'),
            ('department_manager', 'relationships.manage'),
            ('department_manager', 'finance.read'),
            ('department_manager', 'documents.read'),
            ('department_manager', 'documents.manage'),
            ('department_manager', 'workflows.read'),
            ('department_manager', 'workflows.execute'),
            ('department_manager', 'analytics.read'),

            -- Finance manager
            ('finance_manager', 'company.read'),
            ('finance_manager', 'organization.read'),
            ('finance_manager', 'people.read'),
            ('finance_manager', 'finance.read'),
            ('finance_manager', 'finance.manage'),
            ('finance_manager', 'finance.post'),
            ('finance_manager', 'finance.periods.close'),
            ('finance_manager', 'documents.read'),
            ('finance_manager', 'documents.manage'),
            ('finance_manager', 'workflows.read'),
            ('finance_manager', 'workflows.execute'),
            ('finance_manager', 'analytics.read'),
            ('finance_manager', 'audit.read'),

            -- Finance analyst
            ('finance_analyst', 'company.read'),
            ('finance_analyst', 'organization.read'),
            ('finance_analyst', 'finance.read'),
            ('finance_analyst', 'finance.manage'),
            ('finance_analyst', 'documents.read'),
            ('finance_analyst', 'workflows.read'),
            ('finance_analyst', 'workflows.execute'),
            ('finance_analyst', 'analytics.read'),

            -- People manager
            ('people_manager', 'company.read'),
            ('people_manager', 'organization.read'),
            ('people_manager', 'people.read'),
            ('people_manager', 'people.manage'),
            ('people_manager', 'relationships.read'),
            ('people_manager', 'relationships.manage'),
            ('people_manager', 'identity.accounts.read'),
            ('people_manager', 'documents.read'),
            ('people_manager', 'documents.manage'),
            ('people_manager', 'workflows.read'),
            ('people_manager', 'workflows.execute'),
            ('people_manager', 'analytics.read'),
            ('people_manager', 'audit.read'),

            -- Operations manager
            ('operations_manager', 'company.read'),
            ('operations_manager', 'organization.read'),
            ('operations_manager', 'organization.manage'),
            ('operations_manager', 'people.read'),
            ('operations_manager', 'relationships.read'),
            ('operations_manager', 'relationships.manage'),
            ('operations_manager', 'finance.read'),
            ('operations_manager', 'documents.read'),
            ('operations_manager', 'documents.manage'),
            ('operations_manager', 'workflows.read'),
            ('operations_manager', 'workflows.manage'),
            ('operations_manager', 'workflows.execute'),
            ('operations_manager', 'analytics.read'),
            ('operations_manager', 'audit.read'),

            -- Document manager
            ('document_manager', 'company.read'),
            ('document_manager', 'organization.read'),
            ('document_manager', 'people.read'),
            ('document_manager', 'documents.read'),
            ('document_manager', 'documents.manage'),
            ('document_manager', 'documents.approve'),
            ('document_manager', 'workflows.read'),
            ('document_manager', 'workflows.execute'),
            ('document_manager', 'audit.read'),

            -- Workflow manager
            ('workflow_manager', 'company.read'),
            ('workflow_manager', 'organization.read'),
            ('workflow_manager', 'people.read'),
            ('workflow_manager', 'relationships.read'),
            ('workflow_manager', 'documents.read'),
            ('workflow_manager', 'workflows.read'),
            ('workflow_manager', 'workflows.manage'),
            ('workflow_manager', 'workflows.execute'),
            ('workflow_manager', 'analytics.read'),
            ('workflow_manager', 'audit.read'),

            -- Auditor
            ('auditor', 'company.read'),
            ('auditor', 'organization.read'),
            ('auditor', 'people.read'),
            ('auditor', 'relationships.read'),
            ('auditor', 'identity.accounts.read'),
            ('auditor', 'identity.access.read'),
            ('auditor', 'finance.read'),
            ('auditor', 'documents.read'),
            ('auditor', 'workflows.read'),
            ('auditor', 'analytics.read'),
            ('auditor', 'audit.read'),

            -- General read-only user
            ('read_only', 'company.read'),
            ('read_only', 'organization.read'),
            ('read_only', 'people.read'),
            ('read_only', 'relationships.read'),
            ('read_only', 'finance.read'),
            ('read_only', 'documents.read'),
            ('read_only', 'workflows.read'),
            ('read_only', 'analytics.read')
    ) AS specialized_roles (role_key, permission_key)
)
INSERT INTO identity.role_permissions (
    role_id,
    permission_id
)
SELECT
    roles.role_id,
    permissions.permission_id
FROM role_permission_keys
JOIN identity.access_roles AS roles
    USING (role_key)
JOIN identity.permissions AS permissions
    USING (permission_key)
ON CONFLICT (role_id, permission_id) DO NOTHING;


-- ============================================================
-- Document types
-- ============================================================

INSERT INTO documents.document_types (
    type_key,
    type_name,
    description,
    default_retention_months,
    requires_expiration_date,
    is_active
)
VALUES
    (
        'general',
        'General Document',
        'Generic business document without a more specific classification.',
        NULL,
        FALSE,
        TRUE
    ),
    (
        'contract',
        'Contract',
        'Legal, commercial, employment, or service agreement between parties.',
        60,
        FALSE,
        TRUE
    ),
    (
        'policy',
        'Policy',
        'Internal policy, standard, governance rule, or control document.',
        60,
        FALSE,
        TRUE
    ),
    (
        'procedure',
        'Procedure',
        'Documented operating procedure, work instruction, or process guide.',
        60,
        FALSE,
        TRUE
    ),
    (
        'report',
        'Report',
        'Analytical, operational, financial, managerial, or technical report.',
        36,
        FALSE,
        TRUE
    ),
    (
        'invoice',
        'Invoice',
        'Commercial or financial invoice issued by or received by a company.',
        60,
        FALSE,
        TRUE
    ),
    (
        'receipt',
        'Receipt',
        'Payment, purchase, reimbursement, or transaction receipt.',
        60,
        FALSE,
        TRUE
    ),
    (
        'tax_document',
        'Tax Document',
        'Tax filing, tax receipt, fiscal record, or related compliance document.',
        60,
        FALSE,
        TRUE
    ),
    (
        'identity_document',
        'Identity Document',
        'Document used to identify a person or legal entity.',
        60,
        TRUE,
        TRUE
    ),
    (
        'purchase_order',
        'Purchase Order',
        'Authorization to purchase goods or services from a supplier.',
        60,
        FALSE,
        TRUE
    ),
    (
        'sales_order',
        'Sales Order',
        'Commercial order documenting goods or services requested by a customer.',
        60,
        FALSE,
        TRUE
    ),
    (
        'quotation',
        'Quotation',
        'Commercial quotation, estimate, or proposal with defined terms.',
        36,
        TRUE,
        TRUE
    ),
    (
        'credit_note',
        'Credit Note',
        'Document that reduces or corrects a previously issued financial charge.',
        60,
        FALSE,
        TRUE
    ),
    (
        'financial_statement',
        'Financial Statement',
        'Balance sheet, income statement, cash-flow statement, or related financial report.',
        84,
        FALSE,
        TRUE
    ),
    (
        'bank_statement',
        'Bank Statement',
        'Periodic statement issued by a financial institution.',
        84,
        FALSE,
        TRUE
    ),
    (
        'expense_report',
        'Expense Report',
        'Employee or contractor expense report and supporting reimbursement record.',
        60,
        FALSE,
        TRUE
    ),
    (
        'employment_document',
        'Employment Document',
        'Employment offer, agreement, personnel form, evaluation, or related record.',
        84,
        FALSE,
        TRUE
    ),
    (
        'supplier_document',
        'Supplier Document',
        'Supplier registration, qualification, commercial, or compliance document.',
        60,
        FALSE,
        TRUE
    ),
    (
        'customer_document',
        'Customer Document',
        'Customer onboarding, commercial, service, or compliance document.',
        60,
        FALSE,
        TRUE
    ),
    (
        'meeting_minutes',
        'Meeting Minutes',
        'Formal record of decisions, agreements, and actions from a meeting.',
        60,
        FALSE,
        TRUE
    ),
    (
        'audit_evidence',
        'Audit Evidence',
        'Evidence collected to support an internal or external audit conclusion.',
        84,
        FALSE,
        TRUE
    ),
    (
        'compliance_certificate',
        'Compliance Certificate',
        'Certificate, permit, license, or attestation with a defined validity period.',
        84,
        TRUE,
        TRUE
    ),
    (
        'project_document',
        'Project Document',
        'Project charter, plan, deliverable, status report, or closure record.',
        60,
        FALSE,
        TRUE
    ),
    (
        'technical_specification',
        'Technical Specification',
        'Technical requirement, design specification, data sheet, or engineering document.',
        60,
        FALSE,
        TRUE
    )
ON CONFLICT (type_key) DO UPDATE
SET
    type_name = EXCLUDED.type_name,
    description = EXCLUDED.description,
    default_retention_months = EXCLUDED.default_retention_months,
    requires_expiration_date = EXCLUDED.requires_expiration_date,
    is_active = EXCLUDED.is_active;

COMMIT;

\echo '01_shared_reference_data.sql completed'