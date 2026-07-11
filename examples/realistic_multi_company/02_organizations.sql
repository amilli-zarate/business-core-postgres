\set ON_ERROR_STOP on

BEGIN;

-- ============================================================
-- 02_organizations.sql
-- Realistic multi-company example
--
-- Purpose:
-- Seed the complete organizational foundation used by the
-- realistic multi-company example:
--
-- - companies
-- - branches
-- - departments
-- - addresses
--
-- Notes:
-- - All companies, identifiers, addresses, and business details
--   are synthetic demonstration data.
-- - Tax identifiers are illustrative placeholders only.
-- - The script depends on 01_shared_reference_data.sql.
-- - The script is safe to run more than once.
-- ============================================================


-- ============================================================
-- Companies
-- ============================================================

INSERT INTO core.companies (
    company_slug,
    company_name,
    legal_name,
    tax_id,
    default_currency_code,
    company_status
)
VALUES
    (
        'solara-retail-mx',
        'Solara Retail Mexico',
        'Solara Retail Mexico, S.A. de C.V.',
        'DEMO-MX-SRM-001',
        'MXN',
        'active'
    ),
    (
        'cobalto-industrial-mx',
        'Cobalto Industrial Systems',
        'Cobalto Industrial Systems, S.A. de C.V.',
        'DEMO-MX-CIS-002',
        'MXN',
        'active'
    ),
    (
        'bluepeak-advisory-us',
        'BluePeak Advisory',
        'BluePeak Advisory LLC',
        'DEMO-US-BPA-003',
        'USD',
        'active'
    ),
    (
        'lumenforge-technologies-us',
        'LumenForge Technologies',
        'LumenForge Technologies, Inc.',
        'DEMO-US-LFT-004',
        'USD',
        'active'
    ),
    (
        'cedarline-logistics-ca',
        'Cedarline Logistics',
        'Cedarline Logistics Inc.',
        'DEMO-CA-CLL-005',
        'CAD',
        'active'
    ),
    (
        'harvest-circle-foods-ca',
        'Harvest Circle Foods',
        'Harvest Circle Foods Inc.',
        'DEMO-CA-HCF-006',
        'CAD',
        'inactive'
    )
ON CONFLICT (company_slug)
DO UPDATE SET
    company_name = EXCLUDED.company_name,
    legal_name = EXCLUDED.legal_name,
    tax_id = EXCLUDED.tax_id,
    default_currency_code = EXCLUDED.default_currency_code,
    company_status = EXCLUDED.company_status,
    updated_at = NOW();


-- ============================================================
-- Branches
-- ============================================================

CREATE TEMP TABLE fixture_organization_branches (
    company_slug TEXT NOT NULL,
    branch_code TEXT NOT NULL,
    branch_name TEXT NOT NULL,
    branch_type TEXT NOT NULL,
    branch_status TEXT NOT NULL,
    opened_on DATE,
    closed_on DATE
) ON COMMIT DROP;

INSERT INTO fixture_organization_branches (
    company_slug,
    branch_code,
    branch_name,
    branch_type,
    branch_status,
    opened_on,
    closed_on
)
VALUES
    -- Solara Retail Mexico
    (
        'solara-retail-mx',
        'MX-CMX-HQ',
        'Mexico City Headquarters',
        'headquarters',
        'active',
        DATE '2014-03-17',
        NULL
    ),
    (
        'solara-retail-mx',
        'MX-CMX-POL',
        'Polanco Flagship Store',
        'store',
        'active',
        DATE '2015-09-05',
        NULL
    ),
    (
        'solara-retail-mx',
        'MX-CMX-SUR',
        'South Mexico City Store',
        'store',
        'active',
        DATE '2018-11-10',
        NULL
    ),
    (
        'solara-retail-mx',
        'MX-GDL-AND',
        'Guadalajara Andares Store',
        'store',
        'active',
        DATE '2021-04-17',
        NULL
    ),
    (
        'solara-retail-mx',
        'MX-TOL-DC',
        'Toluca Distribution Center',
        'warehouse',
        'active',
        DATE '2019-06-03',
        NULL
    ),
    (
        'solara-retail-mx',
        'MX-REMOTE',
        'Digital Commerce Team',
        'remote',
        'active',
        DATE '2020-05-01',
        NULL
    ),

    -- Cobalto Industrial Systems
    (
        'cobalto-industrial-mx',
        'MX-MTY-HQ',
        'Monterrey Headquarters',
        'headquarters',
        'active',
        DATE '2008-08-11',
        NULL
    ),
    (
        'cobalto-industrial-mx',
        'MX-APO-PLT',
        'Apodaca Manufacturing Plant',
        'plant',
        'active',
        DATE '2010-02-22',
        NULL
    ),
    (
        'cobalto-industrial-mx',
        'MX-QRO-WH',
        'Queretaro Components Warehouse',
        'warehouse',
        'active',
        DATE '2016-07-18',
        NULL
    ),
    (
        'cobalto-industrial-mx',
        'MX-GDL-SVC',
        'Guadalajara Service Office',
        'office',
        'active',
        DATE '2018-10-01',
        NULL
    ),
    (
        'cobalto-industrial-mx',
        'MX-SLP-PLT',
        'San Luis Potosi Assembly Plant',
        'plant',
        'active',
        DATE '2022-01-24',
        NULL
    ),

    -- BluePeak Advisory
    (
        'bluepeak-advisory-us',
        'US-AUS-HQ',
        'Austin Headquarters',
        'headquarters',
        'active',
        DATE '2012-06-04',
        NULL
    ),
    (
        'bluepeak-advisory-us',
        'US-NYC-OFC',
        'New York Client Office',
        'office',
        'active',
        DATE '2015-02-09',
        NULL
    ),
    (
        'bluepeak-advisory-us',
        'US-CHI-OFC',
        'Chicago Client Office',
        'office',
        'active',
        DATE '2017-08-14',
        NULL
    ),
    (
        'bluepeak-advisory-us',
        'US-DEN-OFC',
        'Denver Delivery Center',
        'office',
        'active',
        DATE '2021-05-03',
        NULL
    ),
    (
        'bluepeak-advisory-us',
        'US-REMOTE',
        'Distributed Consulting Team',
        'remote',
        'active',
        DATE '2020-03-16',
        NULL
    ),

    -- LumenForge Technologies
    (
        'lumenforge-technologies-us',
        'US-SEA-HQ',
        'Seattle Headquarters',
        'headquarters',
        'active',
        DATE '2016-01-18',
        NULL
    ),
    (
        'lumenforge-technologies-us',
        'US-SJC-RND',
        'San Jose Research and Development Center',
        'office',
        'active',
        DATE '2018-09-10',
        NULL
    ),
    (
        'lumenforge-technologies-us',
        'US-PDX-LAB',
        'Portland Hardware Lab',
        'other',
        'active',
        DATE '2020-02-03',
        NULL
    ),
    (
        'lumenforge-technologies-us',
        'US-DAL-SUP',
        'Dallas Customer Support Office',
        'office',
        'active',
        DATE '2022-06-13',
        NULL
    ),
    (
        'lumenforge-technologies-us',
        'US-REMOTE',
        'Remote Engineering Hub',
        'remote',
        'active',
        DATE '2019-07-01',
        NULL
    ),

    -- Cedarline Logistics
    (
        'cedarline-logistics-ca',
        'CA-TOR-HQ',
        'Toronto Headquarters',
        'headquarters',
        'active',
        DATE '2006-04-03',
        NULL
    ),
    (
        'cedarline-logistics-ca',
        'CA-MIS-DC',
        'Mississauga Distribution Center',
        'warehouse',
        'active',
        DATE '2007-01-15',
        NULL
    ),
    (
        'cedarline-logistics-ca',
        'CA-VAN-OFC',
        'Vancouver Regional Office',
        'office',
        'active',
        DATE '2011-09-12',
        NULL
    ),
    (
        'cedarline-logistics-ca',
        'CA-CGY-DC',
        'Calgary Distribution Center',
        'warehouse',
        'active',
        DATE '2014-05-26',
        NULL
    ),
    (
        'cedarline-logistics-ca',
        'CA-MTL-OFC',
        'Montreal Regional Office',
        'office',
        'active',
        DATE '2019-10-07',
        NULL
    ),

    -- Harvest Circle Foods
    (
        'harvest-circle-foods-ca',
        'CA-VAN-HQ',
        'Vancouver Headquarters',
        'headquarters',
        'inactive',
        DATE '2011-02-14',
        NULL
    ),
    (
        'harvest-circle-foods-ca',
        'CA-RIC-DC',
        'Richmond Cold-Storage Center',
        'warehouse',
        'closed',
        DATE '2012-05-07',
        DATE '2025-03-31'
    ),
    (
        'harvest-circle-foods-ca',
        'CA-CGY-DC',
        'Calgary Distribution Center',
        'warehouse',
        'closed',
        DATE '2018-08-20',
        DATE '2024-11-30'
    ),
    (
        'harvest-circle-foods-ca',
        'CA-VIC-OFC',
        'Victoria Sales Office',
        'office',
        'archived',
        DATE '2016-04-11',
        DATE '2023-09-30'
    );

INSERT INTO core.branches (
    company_id,
    branch_code,
    branch_name,
    branch_type,
    branch_status,
    opened_on,
    closed_on
)
SELECT
    companies.company_id,
    fixture.branch_code,
    fixture.branch_name,
    fixture.branch_type,
    fixture.branch_status,
    fixture.opened_on,
    fixture.closed_on
FROM fixture_organization_branches AS fixture
JOIN core.companies AS companies
    ON companies.company_slug = fixture.company_slug
ON CONFLICT (company_id, branch_code)
DO UPDATE SET
    branch_name = EXCLUDED.branch_name,
    branch_type = EXCLUDED.branch_type,
    branch_status = EXCLUDED.branch_status,
    opened_on = EXCLUDED.opened_on,
    closed_on = EXCLUDED.closed_on,
    updated_at = NOW();


-- ============================================================
-- Departments
-- ============================================================

CREATE TEMP TABLE fixture_organization_departments (
    company_slug TEXT NOT NULL,
    branch_code TEXT,
    parent_department_code TEXT,
    department_code TEXT NOT NULL,
    department_name TEXT NOT NULL,
    department_status TEXT NOT NULL
) ON COMMIT DROP;

INSERT INTO fixture_organization_departments (
    company_slug,
    branch_code,
    parent_department_code,
    department_code,
    department_name,
    department_status
)
VALUES
    -- Solara Retail Mexico: company-level departments
    ('solara-retail-mx', NULL, NULL, 'EXE', 'Executive Office', 'active'),
    ('solara-retail-mx', NULL, NULL, 'FIN', 'Finance', 'active'),
    ('solara-retail-mx', NULL, NULL, 'PPL', 'People and Culture', 'active'),
    ('solara-retail-mx', NULL, NULL, 'TEC', 'Technology', 'active'),
    ('solara-retail-mx', NULL, NULL, 'MKT', 'Marketing and Customer Insights', 'active'),
    ('solara-retail-mx', NULL, NULL, 'RET', 'Retail Operations', 'active'),
    ('solara-retail-mx', NULL, NULL, 'SCM', 'Supply Chain', 'active'),
    ('solara-retail-mx', NULL, NULL, 'ECOM', 'Digital Commerce', 'active'),

    -- Solara Retail Mexico: specialized and branch departments
    ('solara-retail-mx', 'MX-CMX-HQ', 'FIN', 'FIN-ACC', 'Accounting', 'active'),
    ('solara-retail-mx', 'MX-CMX-HQ', 'FIN', 'FIN-FPA', 'Financial Planning and Analysis', 'active'),
    ('solara-retail-mx', 'MX-CMX-HQ', 'PPL', 'PPL-TAL', 'Talent and Development', 'active'),
    ('solara-retail-mx', 'MX-CMX-HQ', 'TEC', 'TEC-DAT', 'Data and Analytics', 'active'),
    ('solara-retail-mx', 'MX-CMX-HQ', 'MKT', 'MKT-CRM', 'CRM and Loyalty', 'active'),
    ('solara-retail-mx', 'MX-CMX-POL', 'RET', 'RET-POL', 'Polanco Store Operations', 'active'),
    ('solara-retail-mx', 'MX-CMX-SUR', 'RET', 'RET-SUR', 'South Mexico City Store Operations', 'active'),
    ('solara-retail-mx', 'MX-GDL-AND', 'RET', 'RET-AND', 'Guadalajara Store Operations', 'active'),
    ('solara-retail-mx', 'MX-TOL-DC', 'SCM', 'SCM-TOL', 'Distribution Operations', 'active'),
    ('solara-retail-mx', 'MX-REMOTE', 'ECOM', 'ECOM-OPS', 'E-commerce Operations', 'active'),

    -- Cobalto Industrial Systems: company-level departments
    ('cobalto-industrial-mx', NULL, NULL, 'EXE', 'Executive Office', 'active'),
    ('cobalto-industrial-mx', NULL, NULL, 'FIN', 'Finance', 'active'),
    ('cobalto-industrial-mx', NULL, NULL, 'PPL', 'People and Culture', 'active'),
    ('cobalto-industrial-mx', NULL, NULL, 'ENG', 'Engineering', 'active'),
    ('cobalto-industrial-mx', NULL, NULL, 'MFG', 'Manufacturing', 'active'),
    ('cobalto-industrial-mx', NULL, NULL, 'SCM', 'Supply Chain', 'active'),
    ('cobalto-industrial-mx', NULL, NULL, 'SAL', 'Sales', 'active'),
    ('cobalto-industrial-mx', NULL, NULL, 'QMS', 'Quality and Compliance', 'active'),
    ('cobalto-industrial-mx', NULL, NULL, 'SVC', 'Field Service', 'active'),

    -- Cobalto Industrial Systems: specialized and branch departments
    ('cobalto-industrial-mx', 'MX-MTY-HQ', 'FIN', 'FIN-ACC', 'Accounting', 'active'),
    ('cobalto-industrial-mx', 'MX-MTY-HQ', 'ENG', 'ENG-PRO', 'Product Engineering', 'active'),
    ('cobalto-industrial-mx', 'MX-APO-PLT', 'ENG', 'ENG-AUT', 'Automation Engineering', 'active'),
    ('cobalto-industrial-mx', 'MX-APO-PLT', 'MFG', 'MFG-APO', 'Apodaca Production', 'active'),
    ('cobalto-industrial-mx', 'MX-SLP-PLT', 'MFG', 'MFG-SLP', 'San Luis Potosi Production', 'active'),
    ('cobalto-industrial-mx', 'MX-QRO-WH', 'SCM', 'SCM-QRO', 'Warehouse Operations', 'active'),
    ('cobalto-industrial-mx', 'MX-MTY-HQ', 'SAL', 'SAL-KEY', 'Key Accounts', 'active'),
    ('cobalto-industrial-mx', 'MX-APO-PLT', 'QMS', 'QMS-EHS', 'Environmental Health and Safety', 'active'),
    ('cobalto-industrial-mx', 'MX-GDL-SVC', 'SVC', 'SVC-GDL', 'Guadalajara Service Operations', 'active'),

    -- BluePeak Advisory: company-level departments
    ('bluepeak-advisory-us', NULL, NULL, 'EXE', 'Executive Office', 'active'),
    ('bluepeak-advisory-us', NULL, NULL, 'FIN', 'Finance', 'active'),
    ('bluepeak-advisory-us', NULL, NULL, 'PPL', 'People and Culture', 'active'),
    ('bluepeak-advisory-us', NULL, NULL, 'OPS', 'Consulting Operations', 'active'),
    ('bluepeak-advisory-us', NULL, NULL, 'ADV', 'Advisory Practices', 'active'),
    ('bluepeak-advisory-us', NULL, NULL, 'SAL', 'Business Development', 'active'),
    ('bluepeak-advisory-us', NULL, NULL, 'KNO', 'Knowledge and Research', 'active'),
    ('bluepeak-advisory-us', NULL, NULL, 'TEC', 'Technology Enablement', 'active'),

    -- BluePeak Advisory: specialized and branch departments
    ('bluepeak-advisory-us', 'US-AUS-HQ', 'FIN', 'FIN-ACC', 'Accounting', 'active'),
    ('bluepeak-advisory-us', 'US-AUS-HQ', 'PPL', 'PPL-TAL', 'Talent Development', 'active'),
    ('bluepeak-advisory-us', 'US-AUS-HQ', 'OPS', 'OPS-PMO', 'Engagement Management Office', 'active'),
    ('bluepeak-advisory-us', 'US-AUS-HQ', 'ADV', 'ADV-STR', 'Strategy and Transformation', 'active'),
    ('bluepeak-advisory-us', 'US-NYC-OFC', 'ADV', 'ADV-RSK', 'Risk and Compliance Advisory', 'active'),
    ('bluepeak-advisory-us', 'US-CHI-OFC', 'ADV', 'ADV-DAT', 'Data and Analytics Advisory', 'active'),
    ('bluepeak-advisory-us', 'US-DEN-OFC', 'KNO', 'KNO-INS', 'Market Intelligence', 'active'),
    ('bluepeak-advisory-us', 'US-REMOTE', 'TEC', 'TEC-AUT', 'Automation and AI Enablement', 'active'),

    -- LumenForge Technologies: company-level departments
    ('lumenforge-technologies-us', NULL, NULL, 'EXE', 'Executive Office', 'active'),
    ('lumenforge-technologies-us', NULL, NULL, 'FIN', 'Finance', 'active'),
    ('lumenforge-technologies-us', NULL, NULL, 'PPL', 'People and Culture', 'active'),
    ('lumenforge-technologies-us', NULL, NULL, 'ENG', 'Engineering', 'active'),
    ('lumenforge-technologies-us', NULL, NULL, 'PRD', 'Product Management', 'active'),
    ('lumenforge-technologies-us', NULL, NULL, 'OPS', 'Business Operations', 'active'),
    ('lumenforge-technologies-us', NULL, NULL, 'SAL', 'Sales', 'active'),
    ('lumenforge-technologies-us', NULL, NULL, 'CS', 'Customer Success', 'active'),
    ('lumenforge-technologies-us', NULL, NULL, 'SEC', 'Security and Compliance', 'active'),

    -- LumenForge Technologies: specialized and branch departments
    ('lumenforge-technologies-us', 'US-SEA-HQ', 'FIN', 'FIN-ACC', 'Accounting', 'active'),
    ('lumenforge-technologies-us', 'US-SEA-HQ', 'PPL', 'PPL-TAL', 'Talent and Organizational Development', 'active'),
    ('lumenforge-technologies-us', 'US-SEA-HQ', 'ENG', 'ENG-PLT', 'Platform Engineering', 'active'),
    ('lumenforge-technologies-us', 'US-SJC-RND', 'ENG', 'ENG-ML', 'Applied AI', 'active'),
    ('lumenforge-technologies-us', 'US-PDX-LAB', 'ENG', 'ENG-HW', 'Hardware Systems', 'active'),
    ('lumenforge-technologies-us', 'US-SJC-RND', 'ENG', 'ENG-QA', 'Quality Engineering', 'active'),
    ('lumenforge-technologies-us', 'US-SEA-HQ', 'PRD', 'PRD-CORE', 'Core Products', 'active'),
    ('lumenforge-technologies-us', 'US-DAL-SUP', 'CS', 'CS-SUP', 'Customer Support', 'active'),
    ('lumenforge-technologies-us', 'US-SEA-HQ', 'SEC', 'SEC-GRC', 'Governance Risk and Compliance', 'active'),

    -- Cedarline Logistics: company-level departments
    ('cedarline-logistics-ca', NULL, NULL, 'EXE', 'Executive Office', 'active'),
    ('cedarline-logistics-ca', NULL, NULL, 'FIN', 'Finance', 'active'),
    ('cedarline-logistics-ca', NULL, NULL, 'PPL', 'People and Culture', 'active'),
    ('cedarline-logistics-ca', NULL, NULL, 'OPS', 'Network Operations', 'active'),
    ('cedarline-logistics-ca', NULL, NULL, 'WHS', 'Warehousing', 'active'),
    ('cedarline-logistics-ca', NULL, NULL, 'TRN', 'Transportation', 'active'),
    ('cedarline-logistics-ca', NULL, NULL, 'SAL', 'Commercial', 'active'),
    ('cedarline-logistics-ca', NULL, NULL, 'TEC', 'Technology', 'active'),
    ('cedarline-logistics-ca', NULL, NULL, 'SAF', 'Safety and Compliance', 'active'),

    -- Cedarline Logistics: specialized and branch departments
    ('cedarline-logistics-ca', 'CA-TOR-HQ', 'FIN', 'FIN-ACC', 'Accounting', 'active'),
    ('cedarline-logistics-ca', 'CA-TOR-HQ', 'PPL', 'PPL-TAL', 'Talent and Training', 'active'),
    ('cedarline-logistics-ca', 'CA-TOR-HQ', 'OPS', 'OPS-EAST', 'Eastern Network Operations', 'active'),
    ('cedarline-logistics-ca', 'CA-VAN-OFC', 'OPS', 'OPS-WEST', 'Western Network Operations', 'active'),
    ('cedarline-logistics-ca', 'CA-MIS-DC', 'WHS', 'WHS-MIS', 'Mississauga Warehouse Operations', 'active'),
    ('cedarline-logistics-ca', 'CA-CGY-DC', 'WHS', 'WHS-CGY', 'Calgary Warehouse Operations', 'active'),
    ('cedarline-logistics-ca', 'CA-MIS-DC', 'TRN', 'TRN-DSP', 'Dispatch and Fleet Operations', 'active'),
    ('cedarline-logistics-ca', 'CA-TOR-HQ', 'TEC', 'TEC-DAT', 'Data and Network Optimization', 'active'),
    ('cedarline-logistics-ca', 'CA-MTL-OFC', 'SAF', 'SAF-COM', 'Regulatory Compliance', 'active'),

    -- Harvest Circle Foods: retained historical structure
    ('harvest-circle-foods-ca', NULL, NULL, 'EXE', 'Executive Office', 'inactive'),
    ('harvest-circle-foods-ca', NULL, NULL, 'FIN', 'Finance', 'inactive'),
    ('harvest-circle-foods-ca', NULL, NULL, 'PPL', 'People and Culture', 'inactive'),
    ('harvest-circle-foods-ca', NULL, NULL, 'OPS', 'Operations', 'inactive'),
    ('harvest-circle-foods-ca', NULL, NULL, 'SAL', 'Sales', 'inactive'),
    ('harvest-circle-foods-ca', NULL, NULL, 'QUA', 'Quality and Food Safety', 'inactive'),
    ('harvest-circle-foods-ca', NULL, NULL, 'SCM', 'Supply Chain', 'inactive'),
    ('harvest-circle-foods-ca', 'CA-VAN-HQ', 'FIN', 'FIN-ACC', 'Accounting', 'inactive'),
    ('harvest-circle-foods-ca', 'CA-RIC-DC', 'OPS', 'OPS-RIC', 'Richmond Cold-Storage Operations', 'archived'),
    ('harvest-circle-foods-ca', 'CA-CGY-DC', 'SCM', 'SCM-CGY', 'Calgary Distribution Operations', 'archived');

-- Insert or refresh company-level departments first so every
-- parent department exists before child departments are loaded.
INSERT INTO core.departments (
    company_id,
    branch_id,
    parent_department_id,
    department_code,
    department_name,
    department_status
)
SELECT
    companies.company_id,
    branches.branch_id,
    NULL,
    fixture.department_code,
    fixture.department_name,
    fixture.department_status
FROM fixture_organization_departments AS fixture
JOIN core.companies AS companies
    ON companies.company_slug = fixture.company_slug
LEFT JOIN core.branches AS branches
    ON branches.company_id = companies.company_id
   AND branches.branch_code = fixture.branch_code
WHERE fixture.parent_department_code IS NULL
ON CONFLICT (company_id, department_code)
DO UPDATE SET
    branch_id = EXCLUDED.branch_id,
    parent_department_id = NULL,
    department_name = EXCLUDED.department_name,
    department_status = EXCLUDED.department_status,
    updated_at = NOW();

-- Insert or refresh specialized and branch-level departments.
INSERT INTO core.departments (
    company_id,
    branch_id,
    parent_department_id,
    department_code,
    department_name,
    department_status
)
SELECT
    companies.company_id,
    branches.branch_id,
    parent_departments.department_id,
    fixture.department_code,
    fixture.department_name,
    fixture.department_status
FROM fixture_organization_departments AS fixture
JOIN core.companies AS companies
    ON companies.company_slug = fixture.company_slug
JOIN core.departments AS parent_departments
    ON parent_departments.company_id = companies.company_id
   AND parent_departments.department_code = fixture.parent_department_code
LEFT JOIN core.branches AS branches
    ON branches.company_id = companies.company_id
   AND branches.branch_code = fixture.branch_code
WHERE fixture.parent_department_code IS NOT NULL
ON CONFLICT (company_id, department_code)
DO UPDATE SET
    branch_id = EXCLUDED.branch_id,
    parent_department_id = EXCLUDED.parent_department_id,
    department_name = EXCLUDED.department_name,
    department_status = EXCLUDED.department_status,
    updated_at = NOW();


-- ============================================================
-- Addresses
-- ============================================================

CREATE TEMP TABLE fixture_organization_addresses (
    company_slug TEXT NOT NULL,
    branch_code TEXT,
    address_label TEXT NOT NULL,
    address_type TEXT NOT NULL,
    address_line_1 TEXT NOT NULL,
    address_line_2 TEXT,
    city TEXT NOT NULL,
    state_region TEXT,
    postal_code TEXT,
    country_code CHAR(2) NOT NULL,
    latitude NUMERIC(9, 6),
    longitude NUMERIC(9, 6),
    is_primary BOOLEAN NOT NULL
) ON COMMIT DROP;

INSERT INTO fixture_organization_addresses (
    company_slug,
    branch_code,
    address_label,
    address_type,
    address_line_1,
    address_line_2,
    city,
    state_region,
    postal_code,
    country_code,
    latitude,
    longitude,
    is_primary
)
VALUES
    -- Solara Retail Mexico
    (
        'solara-retail-mx', NULL, 'Registered Office', 'legal',
        'Avenida del Horizonte 410', 'Floor 12, Colonia Juarez',
        'Ciudad de Mexico', 'Ciudad de Mexico', '06600', 'MX',
        19.428470, -99.127660, TRUE
    ),
    (
        'solara-retail-mx', NULL, 'Billing Correspondence', 'billing',
        'Avenida del Horizonte 410', 'Accounts Payable, Floor 12',
        'Ciudad de Mexico', 'Ciudad de Mexico', '06600', 'MX',
        19.428470, -99.127660, FALSE
    ),
    (
        'solara-retail-mx', 'MX-CMX-HQ', 'Mexico City Headquarters', 'branch',
        'Avenida del Horizonte 410', 'Floor 12, Colonia Juarez',
        'Ciudad de Mexico', 'Ciudad de Mexico', '06600', 'MX',
        19.428470, -99.127660, TRUE
    ),
    (
        'solara-retail-mx', 'MX-CMX-POL', 'Polanco Flagship Store', 'branch',
        'Calle Lago Esmeralda 82', 'Colonia Polanco',
        'Ciudad de Mexico', 'Ciudad de Mexico', '11560', 'MX',
        19.433300, -99.195100, TRUE
    ),
    (
        'solara-retail-mx', 'MX-CMX-SUR', 'South Mexico City Store', 'branch',
        'Boulevard del Pedregal 215', 'Jardines del Pedregal',
        'Ciudad de Mexico', 'Ciudad de Mexico', '01900', 'MX',
        19.305200, -99.190700, TRUE
    ),
    (
        'solara-retail-mx', 'MX-GDL-AND', 'Guadalajara Andares Store', 'branch',
        'Paseo de los Olivos 2085', 'Puerta de Hierro',
        'Zapopan', 'Jalisco', '45116', 'MX',
        20.676700, -103.421000, TRUE
    ),
    (
        'solara-retail-mx', 'MX-TOL-DC', 'Toluca Distribution Center', 'warehouse',
        'Circuito Logistico 120', 'Parque Industrial Lerma',
        'Toluca', 'Estado de Mexico', '50200', 'MX',
        19.282600, -99.655700, TRUE
    ),

    -- Cobalto Industrial Systems
    (
        'cobalto-industrial-mx', NULL, 'Registered Office', 'legal',
        'Avenida Acero 1450', 'Floor 8, Centro',
        'Monterrey', 'Nuevo Leon', '64000', 'MX',
        25.686600, -100.316100, TRUE
    ),
    (
        'cobalto-industrial-mx', NULL, 'Billing Correspondence', 'billing',
        'Avenida Acero 1450', 'Accounts Payable, Floor 8',
        'Monterrey', 'Nuevo Leon', '64000', 'MX',
        25.686600, -100.316100, FALSE
    ),
    (
        'cobalto-industrial-mx', 'MX-MTY-HQ', 'Monterrey Headquarters', 'branch',
        'Avenida Acero 1450', 'Floor 8, Centro',
        'Monterrey', 'Nuevo Leon', '64000', 'MX',
        25.686600, -100.316100, TRUE
    ),
    (
        'cobalto-industrial-mx', 'MX-APO-PLT', 'Apodaca Manufacturing Plant', 'branch',
        'Calle Fundicion 320', 'Parque Industrial Norte',
        'Apodaca', 'Nuevo Leon', '66600', 'MX',
        25.781000, -100.188000, TRUE
    ),
    (
        'cobalto-industrial-mx', 'MX-QRO-WH', 'Queretaro Components Warehouse', 'warehouse',
        'Circuito de Componentes 880', 'Parque Industrial El Marques',
        'El Marques', 'Queretaro', '76246', 'MX',
        20.588800, -100.389900, TRUE
    ),
    (
        'cobalto-industrial-mx', 'MX-GDL-SVC', 'Guadalajara Service Office', 'branch',
        'Avenida Innovacion 3320', 'Suite 405',
        'Guadalajara', 'Jalisco', '44130', 'MX',
        20.659700, -103.349600, TRUE
    ),
    (
        'cobalto-industrial-mx', 'MX-SLP-PLT', 'San Luis Potosi Assembly Plant', 'branch',
        'Eje Industrial 515', 'Zona Industrial Logistik',
        'Villa de Reyes', 'San Luis Potosi', '79526', 'MX',
        21.803000, -100.934000, TRUE
    ),

    -- BluePeak Advisory
    (
        'bluepeak-advisory-us', NULL, 'Registered Office', 'legal',
        '725 Meridian Avenue', 'Suite 900',
        'Austin', 'Texas', '78701', 'US',
        30.267200, -97.743100, TRUE
    ),
    (
        'bluepeak-advisory-us', NULL, 'Billing Correspondence', 'billing',
        '725 Meridian Avenue', 'Accounts Payable, Suite 900',
        'Austin', 'Texas', '78701', 'US',
        30.267200, -97.743100, FALSE
    ),
    (
        'bluepeak-advisory-us', 'US-AUS-HQ', 'Austin Headquarters', 'branch',
        '725 Meridian Avenue', 'Suite 900',
        'Austin', 'Texas', '78701', 'US',
        30.267200, -97.743100, TRUE
    ),
    (
        'bluepeak-advisory-us', 'US-NYC-OFC', 'New York Client Office', 'branch',
        '260 Eastbridge Plaza', 'Floor 18',
        'New York', 'New York', '10017', 'US',
        40.712800, -74.006000, TRUE
    ),
    (
        'bluepeak-advisory-us', 'US-CHI-OFC', 'Chicago Client Office', 'branch',
        '440 Lakeshore Exchange', 'Suite 1250',
        'Chicago', 'Illinois', '60606', 'US',
        41.878100, -87.629800, TRUE
    ),
    (
        'bluepeak-advisory-us', 'US-DEN-OFC', 'Denver Delivery Center', 'branch',
        '1550 Summit Market Street', 'Suite 600',
        'Denver', 'Colorado', '80202', 'US',
        39.739200, -104.990300, TRUE
    ),

    -- LumenForge Technologies
    (
        'lumenforge-technologies-us', NULL, 'Registered Office', 'legal',
        '801 Aurora Way', 'Floor 14',
        'Seattle', 'Washington', '98101', 'US',
        47.606200, -122.332100, TRUE
    ),
    (
        'lumenforge-technologies-us', NULL, 'Billing Correspondence', 'billing',
        '801 Aurora Way', 'Accounts Payable, Floor 14',
        'Seattle', 'Washington', '98101', 'US',
        47.606200, -122.332100, FALSE
    ),
    (
        'lumenforge-technologies-us', 'US-SEA-HQ', 'Seattle Headquarters', 'branch',
        '801 Aurora Way', 'Floor 14',
        'Seattle', 'Washington', '98101', 'US',
        47.606200, -122.332100, TRUE
    ),
    (
        'lumenforge-technologies-us', 'US-SJC-RND', 'San Jose Research and Development Center', 'branch',
        '2500 Circuit Drive', 'Building 3',
        'San Jose', 'California', '95113', 'US',
        37.338200, -121.886300, TRUE
    ),
    (
        'lumenforge-technologies-us', 'US-PDX-LAB', 'Portland Hardware Lab', 'branch',
        '935 Foundry Avenue', 'Suite 200',
        'Portland', 'Oregon', '97205', 'US',
        45.515200, -122.678400, TRUE
    ),
    (
        'lumenforge-technologies-us', 'US-DAL-SUP', 'Dallas Customer Support Office', 'branch',
        '6100 Trinity Commerce Boulevard', 'Suite 450',
        'Dallas', 'Texas', '75201', 'US',
        32.776700, -96.797000, TRUE
    ),

    -- Cedarline Logistics
    (
        'cedarline-logistics-ca', NULL, 'Registered Office', 'legal',
        '180 Frontline Avenue West', 'Suite 1600',
        'Toronto', 'Ontario', 'M5J 2N8', 'CA',
        43.653200, -79.383200, TRUE
    ),
    (
        'cedarline-logistics-ca', NULL, 'Billing Correspondence', 'billing',
        '180 Frontline Avenue West', 'Accounts Payable, Suite 1600',
        'Toronto', 'Ontario', 'M5J 2N8', 'CA',
        43.653200, -79.383200, FALSE
    ),
    (
        'cedarline-logistics-ca', 'CA-TOR-HQ', 'Toronto Headquarters', 'branch',
        '180 Frontline Avenue West', 'Suite 1600',
        'Toronto', 'Ontario', 'M5J 2N8', 'CA',
        43.653200, -79.383200, TRUE
    ),
    (
        'cedarline-logistics-ca', 'CA-MIS-DC', 'Mississauga Distribution Center', 'warehouse',
        '6900 Crossdock Road', 'Unit 12',
        'Mississauga', 'Ontario', 'L5T 2W6', 'CA',
        43.589000, -79.644100, TRUE
    ),
    (
        'cedarline-logistics-ca', 'CA-VAN-OFC', 'Vancouver Regional Office', 'branch',
        '980 Pacific Exchange Street', 'Suite 700',
        'Vancouver', 'British Columbia', 'V6B 1A1', 'CA',
        49.282700, -123.120700, TRUE
    ),
    (
        'cedarline-logistics-ca', 'CA-CGY-DC', 'Calgary Distribution Center', 'warehouse',
        '4200 Prairie Logistics Trail SE', 'Bay 18',
        'Calgary', 'Alberta', 'T2P 1J9', 'CA',
        51.044700, -114.071900, TRUE
    ),
    (
        'cedarline-logistics-ca', 'CA-MTL-OFC', 'Montreal Regional Office', 'branch',
        '1150 Rue du Portail', 'Bureau 900',
        'Montreal', 'Quebec', 'H3B 2Y5', 'CA',
        45.501700, -73.567300, TRUE
    ),

    -- Harvest Circle Foods
    (
        'harvest-circle-foods-ca', NULL, 'Registered Office', 'legal',
        '455 Harbour Market Street', 'Suite 1000',
        'Vancouver', 'British Columbia', 'V6B 1A1', 'CA',
        49.282700, -123.120700, TRUE
    ),
    (
        'harvest-circle-foods-ca', NULL, 'Billing Correspondence', 'billing',
        '455 Harbour Market Street', 'Legacy Accounts, Suite 1000',
        'Vancouver', 'British Columbia', 'V6B 1A1', 'CA',
        49.282700, -123.120700, FALSE
    ),
    (
        'harvest-circle-foods-ca', 'CA-VAN-HQ', 'Vancouver Headquarters', 'branch',
        '455 Harbour Market Street', 'Suite 1000',
        'Vancouver', 'British Columbia', 'V6B 1A1', 'CA',
        49.282700, -123.120700, TRUE
    ),
    (
        'harvest-circle-foods-ca', 'CA-RIC-DC', 'Richmond Cold-Storage Center', 'warehouse',
        '12700 Coldstream Way', 'Unit 6',
        'Richmond', 'British Columbia', 'V6V 2N9', 'CA',
        49.166600, -123.133600, TRUE
    ),
    (
        'harvest-circle-foods-ca', 'CA-CGY-DC', 'Calgary Distribution Center', 'warehouse',
        '3150 Harvest Distribution Road NE', 'Bay 4',
        'Calgary', 'Alberta', 'T2P 1J9', 'CA',
        51.044700, -114.071900, TRUE
    ),
    (
        'harvest-circle-foods-ca', 'CA-VIC-OFC', 'Victoria Sales Office', 'branch',
        '780 Island Commerce Avenue', 'Suite 310',
        'Victoria', 'British Columbia', 'V8W 1P6', 'CA',
        48.428400, -123.365600, TRUE
    );

-- Addresses do not currently have a natural-key uniqueness
-- constraint. Update fixture-owned rows by company, branch, and
-- label before inserting any missing rows.
UPDATE core.addresses AS addresses
SET
    address_type = fixture.address_type,
    address_line_1 = fixture.address_line_1,
    address_line_2 = fixture.address_line_2,
    city = fixture.city,
    state_region = fixture.state_region,
    postal_code = fixture.postal_code,
    country_code = fixture.country_code,
    latitude = fixture.latitude,
    longitude = fixture.longitude,
    is_primary = fixture.is_primary,
    updated_at = NOW()
FROM fixture_organization_addresses AS fixture
JOIN core.companies AS companies
    ON companies.company_slug = fixture.company_slug
LEFT JOIN core.branches AS branches
    ON branches.company_id = companies.company_id
   AND branches.branch_code = fixture.branch_code
WHERE addresses.company_id = companies.company_id
  AND addresses.branch_id IS NOT DISTINCT FROM branches.branch_id
  AND addresses.address_label = fixture.address_label;

INSERT INTO core.addresses (
    company_id,
    branch_id,
    address_label,
    address_type,
    address_line_1,
    address_line_2,
    city,
    state_region,
    postal_code,
    country_code,
    latitude,
    longitude,
    is_primary
)
SELECT
    companies.company_id,
    branches.branch_id,
    fixture.address_label,
    fixture.address_type,
    fixture.address_line_1,
    fixture.address_line_2,
    fixture.city,
    fixture.state_region,
    fixture.postal_code,
    fixture.country_code,
    fixture.latitude,
    fixture.longitude,
    fixture.is_primary
FROM fixture_organization_addresses AS fixture
JOIN core.companies AS companies
    ON companies.company_slug = fixture.company_slug
LEFT JOIN core.branches AS branches
    ON branches.company_id = companies.company_id
   AND branches.branch_code = fixture.branch_code
WHERE NOT EXISTS (
    SELECT 1
    FROM core.addresses AS addresses
    WHERE addresses.company_id = companies.company_id
      AND addresses.branch_id IS NOT DISTINCT FROM branches.branch_id
      AND addresses.address_label = fixture.address_label
);


COMMIT;

\echo '02_organizations.sql completed'