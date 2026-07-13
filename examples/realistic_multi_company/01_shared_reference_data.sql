\set ON_ERROR_STOP on

BEGIN;

-- ============================================================
-- 01_shared_reference_data.sql
-- Realistic multi-company example
--
-- Purpose:
-- Seed reference records and platform-wide access-control
-- definitions that are shared by every company in the example database.
--
-- Notes:
-- - All records are synthetic demonstration data.
-- - This script is safe to run more than once.
-- - Permissions, access roles, and role-permission mappings are
--   defined here and consumed by 04_identity.sql.
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
