\set ON_ERROR_STOP on
\encoding UTF8

BEGIN;

-- ============================================================
-- 05_finance.sql
-- Realistic multi-company example
--
-- Purpose:
-- Seed a substantial, internally consistent financial dataset:
--
-- - monthly fiscal periods
-- - hierarchical cost centers
-- - company-specific charts of accounts
-- - opening balances
-- - recurring operational journal entries
-- - draft and voided transaction examples
--
-- Notes:
-- - All financial records and amounts are synthetic.
-- - Amounts are denominated in each company's default currency.
-- - Posted transactions are balanced by construction.
-- - Generated identities are always resolved through stable
--   business keys; no BIGINT identity value is hard-coded.
-- - User accounts are resolved through the person records seeded
--   by 03_people_and_relationships.sql. If a matching account was
--   not created by 04_identity.sql, created_by_account_id remains
--   NULL, which is valid for the finance schema.
-- - The script depends on 01_shared_reference_data.sql through
--   04_identity.sql.
-- - The script is safe to run more than once. Transactions owned
--   by this fixture are rebuilt deterministically on every run.
-- ============================================================


-- ============================================================
-- Finance profiles
-- ============================================================
-- One profile centralizes the stable organizational keys and the
-- synthetic operating assumptions used to generate transactions.

CREATE TEMP TABLE fixture_finance_profiles (
    company_slug TEXT PRIMARY KEY,
    transaction_prefix TEXT NOT NULL,
    creator_person_external_reference TEXT,
    finance_branch_code TEXT NOT NULL,
    finance_department_code TEXT NOT NULL,
    finance_cost_center_code TEXT NOT NULL,
    operating_branch_code TEXT NOT NULL,
    operating_department_code TEXT NOT NULL,
    operating_cost_center_code TEXT NOT NULL,
    customer_person_external_reference TEXT,
    supplier_person_external_reference TEXT,
    revenue_account_code TEXT NOT NULL,
    direct_cost_account_code TEXT NOT NULL,
    direct_cost_offset_account_code TEXT NOT NULL,
    opening_working_asset_account_code TEXT NOT NULL,
    opening_equity_account_code TEXT NOT NULL,
    is_product_company BOOLEAN NOT NULL,
    transaction_start_month DATE NOT NULL,
    transaction_end_month DATE NOT NULL,
    base_monthly_revenue NUMERIC(18, 2) NOT NULL,
    base_monthly_payroll NUMERIC(18, 2) NOT NULL,
    base_monthly_operating_expense NUMERIC(18, 2) NOT NULL,
    base_monthly_direct_cost NUMERIC(18, 2) NOT NULL,
    base_monthly_depreciation NUMERIC(18, 2) NOT NULL,
    base_monthly_tax_expense NUMERIC(18, 2) NOT NULL,
    annual_growth_rate NUMERIC(7, 4) NOT NULL
) ON COMMIT DROP;

INSERT INTO fixture_finance_profiles (
    company_slug,
    transaction_prefix,
    creator_person_external_reference,
    finance_branch_code,
    finance_department_code,
    finance_cost_center_code,
    operating_branch_code,
    operating_department_code,
    operating_cost_center_code,
    customer_person_external_reference,
    supplier_person_external_reference,
    revenue_account_code,
    direct_cost_account_code,
    direct_cost_offset_account_code,
    opening_working_asset_account_code,
    opening_equity_account_code,
    is_product_company,
    transaction_start_month,
    transaction_end_month,
    base_monthly_revenue,
    base_monthly_payroll,
    base_monthly_operating_expense,
    base_monthly_direct_cost,
    base_monthly_depreciation,
    base_monthly_tax_expense,
    annual_growth_rate
)
VALUES
    (
        'solara-retail-mx',
        'SRM',
        'SRM-P009',
        'MX-CMX-HQ',
        'FIN-ACC',
        'CORP-FIN',
        'MX-CMX-POL',
        'RET-POL',
        'RETAIL-CMX',
        'SRM-P022',
        'SRM-P023',
        '4100',
        '5100',
        '1300',
        '1300',
        '3100',
        TRUE,
        DATE '2025-01-01',
        DATE '2026-06-01',
        18500000.00,
        4300000.00,
        1850000.00,
        8600000.00,
        320000.00,
        720000.00,
        0.0800
    ),
    (
        'cobalto-industrial-mx',
        'CIS',
        'CIS-P010',
        'MX-MTY-HQ',
        'FIN-ACC',
        'CORP-FIN',
        'MX-APO-PLT',
        'MFG-APO',
        'MFG-APO',
        'CIS-P023',
        'CIS-P022',
        '4100',
        '5100',
        '1300',
        '1300',
        '3100',
        TRUE,
        DATE '2025-01-01',
        DATE '2026-06-01',
        27000000.00,
        6800000.00,
        2900000.00,
        13200000.00,
        850000.00,
        1150000.00,
        0.0650
    ),
    (
        'bluepeak-advisory-us',
        'BPA',
        'BPA-P009',
        'US-AUS-HQ',
        'FIN-ACC',
        'CORP-FIN',
        'US-AUS-HQ',
        'ADV-STR',
        'ADV-STR',
        NULL,
        'BPA-P019',
        '4200',
        '5200',
        '2100',
        '1400',
        '3100',
        FALSE,
        DATE '2025-01-01',
        DATE '2026-06-01',
        3400000.00,
        1450000.00,
        440000.00,
        650000.00,
        65000.00,
        210000.00,
        0.0550
    ),
    (
        'lumenforge-technologies-us',
        'LFT',
        'LFT-P010',
        'US-SEA-HQ',
        'FIN-ACC',
        'CORP-FIN',
        'US-SEA-HQ',
        'ENG-PLT',
        'ENG-PLT',
        NULL,
        'LFT-P021',
        '4200',
        '5200',
        '2100',
        '1400',
        '3100',
        FALSE,
        DATE '2025-01-01',
        DATE '2026-06-01',
        5800000.00,
        2350000.00,
        780000.00,
        1150000.00,
        190000.00,
        340000.00,
        0.1200
    ),
    (
        'cedarline-logistics-ca',
        'CLL',
        'CLL-P010',
        'CA-TOR-HQ',
        'FIN-ACC',
        'CORP-FIN',
        'CA-TOR-HQ',
        'OPS-EAST',
        'NET-EAST',
        'CLL-P020',
        'CLL-P021',
        '4200',
        '5300',
        '2100',
        '1400',
        '3100',
        FALSE,
        DATE '2025-01-01',
        DATE '2026-06-01',
        7200000.00,
        2100000.00,
        1100000.00,
        2450000.00,
        310000.00,
        390000.00,
        0.0450
    ),
    (
        'harvest-circle-foods-ca',
        'HCF',
        'HCF-P008',
        'CA-VAN-HQ',
        'FIN-ACC',
        'CORP-FIN',
        'CA-RIC-DC',
        'OPS-RIC',
        'OPS-RIC',
        NULL,
        'HCF-P012',
        '4100',
        '5100',
        '1300',
        '1300',
        '3200',
        TRUE,
        DATE '2024-01-01',
        DATE '2024-09-01',
        4600000.00,
        1350000.00,
        650000.00,
        2050000.00,
        140000.00,
        190000.00,
        -0.0600
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
    FROM fixture_finance_profiles;

    SELECT COUNT(*)
    INTO resolved_companies
    FROM fixture_finance_profiles AS profiles
    JOIN core.companies AS companies
        ON companies.company_slug = profiles.company_slug;

    IF resolved_companies <> expected_companies THEN
        RAISE EXCEPTION
            '05_finance.sql could resolve only % of % fixture companies. Run 02_organizations.sql first.',
            resolved_companies,
            expected_companies;
    END IF;

    IF EXISTS (
        SELECT 1
        FROM fixture_finance_profiles AS profiles
        JOIN core.companies AS companies
            ON companies.company_slug = profiles.company_slug
        LEFT JOIN core.branches AS finance_branches
            ON finance_branches.company_id = companies.company_id
           AND finance_branches.branch_code = profiles.finance_branch_code
        LEFT JOIN core.departments AS finance_departments
            ON finance_departments.company_id = companies.company_id
           AND finance_departments.department_code = profiles.finance_department_code
        LEFT JOIN core.branches AS operating_branches
            ON operating_branches.company_id = companies.company_id
           AND operating_branches.branch_code = profiles.operating_branch_code
        LEFT JOIN core.departments AS operating_departments
            ON operating_departments.company_id = companies.company_id
           AND operating_departments.department_code = profiles.operating_department_code
        WHERE finance_branches.branch_id IS NULL
           OR finance_departments.department_id IS NULL
           OR operating_branches.branch_id IS NULL
           OR operating_departments.department_id IS NULL
    ) THEN
        RAISE EXCEPTION
            '05_finance.sql could not resolve one or more required branches or departments. Run the current 02_organizations.sql first.';
    END IF;

    IF EXISTS (
        SELECT 1
        FROM fixture_finance_profiles AS profiles
        JOIN core.companies AS companies
            ON companies.company_slug = profiles.company_slug
        LEFT JOIN people.persons AS creators
            ON creators.company_id = companies.company_id
           AND creators.external_reference = profiles.creator_person_external_reference
        LEFT JOIN people.persons AS customers
            ON customers.company_id = companies.company_id
           AND customers.external_reference = profiles.customer_person_external_reference
        LEFT JOIN people.persons AS suppliers
            ON suppliers.company_id = companies.company_id
           AND suppliers.external_reference = profiles.supplier_person_external_reference
        WHERE (
                profiles.creator_person_external_reference IS NOT NULL
                AND creators.person_id IS NULL
              )
           OR (
                profiles.customer_person_external_reference IS NOT NULL
                AND customers.person_id IS NULL
              )
           OR (
                profiles.supplier_person_external_reference IS NOT NULL
                AND suppliers.person_id IS NULL
              )
    ) THEN
        RAISE EXCEPTION
            '05_finance.sql could not resolve one or more fixture people. Run the current 03_people_and_relationships.sql first.';
    END IF;
END;
$$;


-- ============================================================
-- Fiscal periods
-- ============================================================

CREATE TEMP TABLE fixture_finance_period_ranges (
    company_slug TEXT PRIMARY KEY,
    first_month DATE NOT NULL,
    last_month DATE NOT NULL
) ON COMMIT DROP;

INSERT INTO fixture_finance_period_ranges (
    company_slug,
    first_month,
    last_month
)
VALUES
    ('solara-retail-mx', DATE '2025-01-01', DATE '2026-12-01'),
    ('cobalto-industrial-mx', DATE '2025-01-01', DATE '2026-12-01'),
    ('bluepeak-advisory-us', DATE '2025-01-01', DATE '2026-12-01'),
    ('lumenforge-technologies-us', DATE '2025-01-01', DATE '2026-12-01'),
    ('cedarline-logistics-ca', DATE '2025-01-01', DATE '2026-12-01'),
    ('harvest-circle-foods-ca', DATE '2024-01-01', DATE '2025-03-01');

WITH generated_periods AS (
    SELECT
        ranges.company_slug,
        months.period_start::DATE AS period_start,
        (months.period_start + INTERVAL '1 month')::DATE AS period_end,
        EXTRACT(YEAR FROM months.period_start)::INTEGER AS fiscal_year,
        EXTRACT(MONTH FROM months.period_start)::SMALLINT AS period_number
    FROM fixture_finance_period_ranges AS ranges
    CROSS JOIN LATERAL generate_series(
        ranges.first_month::TIMESTAMP,
        ranges.last_month::TIMESTAMP,
        INTERVAL '1 month'
    ) AS months(period_start)
), classified_periods AS (
    SELECT
        generated.*,
        CASE
            WHEN generated.company_slug = 'harvest-circle-foods-ca' THEN 'locked'
            WHEN generated.fiscal_year < 2026 THEN 'locked'
            WHEN generated.period_start <= DATE '2026-06-01' THEN 'closed'
            ELSE 'open'
        END AS period_status
    FROM generated_periods AS generated
)
INSERT INTO finance.fiscal_periods (
    company_id,
    period_code,
    period_name,
    fiscal_year,
    period_number,
    start_date,
    end_date,
    period_status,
    closed_at
)
SELECT
    companies.company_id,
    FORMAT('FY%s-P%s',
        classified.fiscal_year,
        LPAD(classified.period_number::TEXT, 2, '0')
    ),
    FORMAT(
        '%s %s',
        CASE classified.period_number
            WHEN 1 THEN 'January'
            WHEN 2 THEN 'February'
            WHEN 3 THEN 'March'
            WHEN 4 THEN 'April'
            WHEN 5 THEN 'May'
            WHEN 6 THEN 'June'
            WHEN 7 THEN 'July'
            WHEN 8 THEN 'August'
            WHEN 9 THEN 'September'
            WHEN 10 THEN 'October'
            WHEN 11 THEN 'November'
            WHEN 12 THEN 'December'
        END,
        classified.fiscal_year
    ),
    classified.fiscal_year,
    classified.period_number,
    classified.period_start,
    classified.period_end,
    classified.period_status,
    CASE
        WHEN classified.period_status = 'open' THEN NULL
        ELSE (
            classified.period_end::TIMESTAMP
            + INTERVAL '5 days 18 hours'
        ) AT TIME ZONE 'UTC'
    END
FROM classified_periods AS classified
JOIN core.companies AS companies
    ON companies.company_slug = classified.company_slug
ON CONFLICT (company_id, period_code)
DO UPDATE SET
    period_name = EXCLUDED.period_name,
    fiscal_year = EXCLUDED.fiscal_year,
    period_number = EXCLUDED.period_number,
    start_date = EXCLUDED.start_date,
    end_date = EXCLUDED.end_date,
    period_status = EXCLUDED.period_status,
    closed_at = EXCLUDED.closed_at;


-- ============================================================
-- Cost centers
-- ============================================================

CREATE TEMP TABLE fixture_finance_cost_centers (
    company_slug TEXT NOT NULL,
    parent_cost_center_code TEXT,
    cost_center_code TEXT NOT NULL,
    cost_center_name TEXT NOT NULL,
    description TEXT,
    is_active BOOLEAN NOT NULL,
    PRIMARY KEY (company_slug, cost_center_code)
) ON COMMIT DROP;

INSERT INTO fixture_finance_cost_centers (
    company_slug,
    parent_cost_center_code,
    cost_center_code,
    cost_center_name,
    description,
    is_active
)
VALUES
    -- Solara Retail Mexico
    ('solara-retail-mx', NULL, 'CORP', 'Corporate Functions', 'Company-wide leadership and shared services.', TRUE),
    ('solara-retail-mx', NULL, 'RETAIL', 'Retail Network', 'Physical store operations.', TRUE),
    ('solara-retail-mx', NULL, 'DIGITAL', 'Digital Commerce', 'E-commerce and digital customer operations.', TRUE),
    ('solara-retail-mx', NULL, 'SUPPLY', 'Supply Chain', 'Distribution and replenishment operations.', TRUE),
    ('solara-retail-mx', 'CORP', 'CORP-FIN', 'Finance and Accounting', 'Corporate accounting, treasury, and planning.', TRUE),
    ('solara-retail-mx', 'CORP', 'CORP-PPL', 'People and Culture', 'Corporate people operations.', TRUE),
    ('solara-retail-mx', 'CORP', 'CORP-TEC', 'Technology and Data', 'Technology, analytics, and platform operations.', TRUE),
    ('solara-retail-mx', 'RETAIL', 'RETAIL-CMX', 'Mexico City Stores', 'Combined Mexico City retail operations.', TRUE),
    ('solara-retail-mx', 'RETAIL', 'RETAIL-GDL', 'Guadalajara Store', 'Guadalajara retail operations.', TRUE),
    ('solara-retail-mx', 'DIGITAL', 'DIGITAL-ECOM', 'E-commerce Operations', 'Online sales and fulfillment coordination.', TRUE),
    ('solara-retail-mx', 'SUPPLY', 'SUPPLY-TOL', 'Toluca Distribution Center', 'Distribution-center operating costs.', TRUE),

    -- Cobalto Industrial Systems
    ('cobalto-industrial-mx', NULL, 'CORP', 'Corporate Functions', 'Company-wide leadership and shared services.', TRUE),
    ('cobalto-industrial-mx', NULL, 'MFG', 'Manufacturing', 'Manufacturing and plant operations.', TRUE),
    ('cobalto-industrial-mx', NULL, 'ENG', 'Engineering', 'Product and automation engineering.', TRUE),
    ('cobalto-industrial-mx', NULL, 'COMM', 'Commercial and Service', 'Sales and field-service activities.', TRUE),
    ('cobalto-industrial-mx', 'CORP', 'CORP-FIN', 'Finance and Accounting', 'Corporate accounting and financial control.', TRUE),
    ('cobalto-industrial-mx', 'MFG', 'MFG-APO', 'Apodaca Manufacturing', 'Apodaca plant production costs.', TRUE),
    ('cobalto-industrial-mx', 'MFG', 'MFG-SLP', 'San Luis Potosi Manufacturing', 'San Luis Potosi plant production costs.', TRUE),
    ('cobalto-industrial-mx', 'ENG', 'ENG-PRO', 'Product Engineering', 'Product design and engineering costs.', TRUE),
    ('cobalto-industrial-mx', 'ENG', 'ENG-AUT', 'Automation Engineering', 'Industrial automation engineering costs.', TRUE),
    ('cobalto-industrial-mx', 'COMM', 'COMM-SALES', 'Key Accounts', 'Strategic account sales activities.', TRUE),
    ('cobalto-industrial-mx', 'COMM', 'COMM-SVC', 'Field Service', 'Installation and field-service operations.', TRUE),

    -- BluePeak Advisory
    ('bluepeak-advisory-us', NULL, 'CORP', 'Corporate Functions', 'Firm-wide leadership and shared services.', TRUE),
    ('bluepeak-advisory-us', NULL, 'ADV', 'Advisory Practices', 'Client-facing advisory practices.', TRUE),
    ('bluepeak-advisory-us', NULL, 'DELIVERY', 'Engagement Delivery', 'Engagement governance and delivery enablement.', TRUE),
    ('bluepeak-advisory-us', NULL, 'GROWTH', 'Growth and Market Development', 'Business development and market expansion.', TRUE),
    ('bluepeak-advisory-us', 'CORP', 'CORP-FIN', 'Finance and Accounting', 'Firm accounting, treasury, and planning.', TRUE),
    ('bluepeak-advisory-us', 'ADV', 'ADV-STR', 'Strategy and Transformation', 'Strategy and transformation engagements.', TRUE),
    ('bluepeak-advisory-us', 'ADV', 'ADV-RSK', 'Risk and Compliance', 'Risk and compliance advisory engagements.', TRUE),
    ('bluepeak-advisory-us', 'ADV', 'ADV-DAT', 'Data and Analytics', 'Data and analytics advisory engagements.', TRUE),
    ('bluepeak-advisory-us', 'DELIVERY', 'DELIVERY-PMO', 'Engagement Management Office', 'Portfolio and engagement governance.', TRUE),
    ('bluepeak-advisory-us', 'DELIVERY', 'DELIVERY-TECH', 'Technology Enablement', 'Automation and AI delivery enablement.', TRUE),
    ('bluepeak-advisory-us', 'GROWTH', 'GROWTH-SALES', 'Business Development', 'Sales and account-development costs.', TRUE),

    -- LumenForge Technologies
    ('lumenforge-technologies-us', NULL, 'CORP', 'Corporate Functions', 'Company-wide leadership and shared services.', TRUE),
    ('lumenforge-technologies-us', NULL, 'ENG', 'Engineering', 'Software, AI, hardware, and quality engineering.', TRUE),
    ('lumenforge-technologies-us', NULL, 'PRODUCT', 'Product', 'Product strategy and lifecycle management.', TRUE),
    ('lumenforge-technologies-us', NULL, 'CUSTOMER', 'Customer Operations', 'Customer success and support.', TRUE),
    ('lumenforge-technologies-us', 'CORP', 'CORP-FIN', 'Finance and Accounting', 'Corporate accounting and financial planning.', TRUE),
    ('lumenforge-technologies-us', 'CORP', 'CORP-SEC', 'Security and Compliance', 'Security governance and compliance.', TRUE),
    ('lumenforge-technologies-us', 'ENG', 'ENG-PLT', 'Platform Engineering', 'Core platform engineering costs.', TRUE),
    ('lumenforge-technologies-us', 'ENG', 'ENG-AI', 'Applied AI', 'Machine-learning research and productization.', TRUE),
    ('lumenforge-technologies-us', 'ENG', 'ENG-HW', 'Hardware Systems', 'Hardware prototyping and validation.', TRUE),
    ('lumenforge-technologies-us', 'PRODUCT', 'PRODUCT-CORE', 'Core Products', 'Core product management.', TRUE),
    ('lumenforge-technologies-us', 'CUSTOMER', 'CUSTOMER-SUPPORT', 'Customer Support', 'Customer support operations.', TRUE),

    -- Cedarline Logistics
    ('cedarline-logistics-ca', NULL, 'CORP', 'Corporate Functions', 'Company-wide leadership and shared services.', TRUE),
    ('cedarline-logistics-ca', NULL, 'NETWORK', 'Network Operations', 'Regional network planning and operations.', TRUE),
    ('cedarline-logistics-ca', NULL, 'WHS', 'Warehousing', 'Distribution-center and warehouse operations.', TRUE),
    ('cedarline-logistics-ca', NULL, 'FLEET', 'Fleet and Transportation', 'Fleet, dispatch, and transportation operations.', TRUE),
    ('cedarline-logistics-ca', 'CORP', 'CORP-FIN', 'Finance and Accounting', 'Corporate accounting, treasury, and planning.', TRUE),
    ('cedarline-logistics-ca', 'CORP', 'CORP-TEC', 'Technology and Optimization', 'Data, technology, and network optimization.', TRUE),
    ('cedarline-logistics-ca', 'CORP', 'CORP-SAF', 'Safety and Compliance', 'Safety, claims prevention, and compliance.', TRUE),
    ('cedarline-logistics-ca', 'NETWORK', 'NET-EAST', 'Eastern Network', 'Eastern Canada network operations.', TRUE),
    ('cedarline-logistics-ca', 'NETWORK', 'NET-WEST', 'Western Network', 'Western Canada network operations.', TRUE),
    ('cedarline-logistics-ca', 'WHS', 'WHS-MIS', 'Mississauga Warehouse', 'Mississauga distribution-center operations.', TRUE),
    ('cedarline-logistics-ca', 'WHS', 'WHS-CGY', 'Calgary Warehouse', 'Calgary distribution-center operations.', TRUE),
    ('cedarline-logistics-ca', 'FLEET', 'FLEET-DSP', 'Dispatch and Fleet', 'Dispatch, fleet, and carrier coordination.', TRUE),

    -- Harvest Circle Foods: retained historical cost centers
    ('harvest-circle-foods-ca', NULL, 'CORP', 'Corporate Functions', 'Historical corporate shared services.', FALSE),
    ('harvest-circle-foods-ca', NULL, 'OPS', 'Operations', 'Historical food-production and storage operations.', FALSE),
    ('harvest-circle-foods-ca', NULL, 'COMM', 'Commercial', 'Historical sales and customer operations.', FALSE),
    ('harvest-circle-foods-ca', 'CORP', 'CORP-FIN', 'Finance and Accounting', 'Historical finance and accounting function.', FALSE),
    ('harvest-circle-foods-ca', 'OPS', 'OPS-RIC', 'Richmond Cold Storage', 'Historical Richmond cold-storage operations.', FALSE),
    ('harvest-circle-foods-ca', 'OPS', 'OPS-CGY', 'Calgary Distribution', 'Historical Calgary distribution operations.', FALSE),
    ('harvest-circle-foods-ca', 'COMM', 'COMM-SALES', 'Sales', 'Historical commercial operations.', FALSE);

-- Parent cost centers first.
INSERT INTO finance.cost_centers (
    company_id,
    parent_cost_center_id,
    cost_center_code,
    cost_center_name,
    description,
    is_active
)
SELECT
    companies.company_id,
    NULL,
    fixture.cost_center_code,
    fixture.cost_center_name,
    fixture.description,
    fixture.is_active
FROM fixture_finance_cost_centers AS fixture
JOIN core.companies AS companies
    ON companies.company_slug = fixture.company_slug
WHERE fixture.parent_cost_center_code IS NULL
ON CONFLICT (company_id, cost_center_code)
DO UPDATE SET
    parent_cost_center_id = NULL,
    cost_center_name = EXCLUDED.cost_center_name,
    description = EXCLUDED.description,
    is_active = EXCLUDED.is_active;

-- Child cost centers after their parents exist.
INSERT INTO finance.cost_centers (
    company_id,
    parent_cost_center_id,
    cost_center_code,
    cost_center_name,
    description,
    is_active
)
SELECT
    companies.company_id,
    parents.cost_center_id,
    fixture.cost_center_code,
    fixture.cost_center_name,
    fixture.description,
    fixture.is_active
FROM fixture_finance_cost_centers AS fixture
JOIN core.companies AS companies
    ON companies.company_slug = fixture.company_slug
JOIN finance.cost_centers AS parents
    ON parents.company_id = companies.company_id
   AND parents.cost_center_code = fixture.parent_cost_center_code
WHERE fixture.parent_cost_center_code IS NOT NULL
ON CONFLICT (company_id, cost_center_code)
DO UPDATE SET
    parent_cost_center_id = EXCLUDED.parent_cost_center_id,
    cost_center_name = EXCLUDED.cost_center_name,
    description = EXCLUDED.description,
    is_active = EXCLUDED.is_active;


-- ============================================================
-- Chart of accounts
-- ============================================================

CREATE TEMP TABLE fixture_account_templates (
    parent_account_code TEXT,
    account_code TEXT PRIMARY KEY,
    account_name TEXT NOT NULL,
    account_type TEXT NOT NULL,
    normal_balance TEXT NOT NULL,
    is_postable BOOLEAN NOT NULL,
    description TEXT
) ON COMMIT DROP;

INSERT INTO fixture_account_templates (
    parent_account_code,
    account_code,
    account_name,
    account_type,
    normal_balance,
    is_postable,
    description
)
VALUES
    -- Grouping accounts
    (NULL, '1000', 'Assets', 'asset', 'debit', FALSE, 'Top-level asset grouping account.'),
    (NULL, '2000', 'Liabilities', 'liability', 'credit', FALSE, 'Top-level liability grouping account.'),
    (NULL, '3000', 'Equity', 'equity', 'credit', FALSE, 'Top-level equity grouping account.'),
    (NULL, '4000', 'Revenue', 'revenue', 'credit', FALSE, 'Top-level revenue grouping account.'),
    (NULL, '5000', 'Direct Costs', 'expense', 'debit', FALSE, 'Top-level direct-cost grouping account.'),
    (NULL, '6000', 'Operating Expenses', 'expense', 'debit', FALSE, 'Top-level operating-expense grouping account.'),

    -- Assets
    ('1000', '1100', 'Operating Bank Account', 'asset', 'debit', TRUE, 'Primary operating cash account.'),
    ('1000', '1110', 'Cash on Hand', 'asset', 'debit', TRUE, 'Petty cash and local cash holdings.'),
    ('1000', '1200', 'Accounts Receivable', 'asset', 'debit', TRUE, 'Trade receivables from customers.'),
    ('1000', '1300', 'Inventory', 'asset', 'debit', TRUE, 'Merchandise, materials, and finished goods inventory.'),
    ('1000', '1400', 'Prepaid Expenses', 'asset', 'debit', TRUE, 'Prepaid subscriptions, insurance, and services.'),
    ('1000', '1500', 'Property and Equipment', 'asset', 'debit', TRUE, 'Capitalized property, equipment, and technology assets.'),
    ('1000', '1600', 'Accumulated Depreciation', 'asset', 'credit', TRUE, 'Contra-asset for accumulated depreciation.'),

    -- Liabilities
    ('2000', '2100', 'Accounts Payable', 'liability', 'credit', TRUE, 'Trade obligations to suppliers and service providers.'),
    ('2000', '2200', 'Accrued Liabilities', 'liability', 'credit', TRUE, 'Accrued payroll, services, and other obligations.'),
    ('2000', '2300', 'Taxes Payable', 'liability', 'credit', TRUE, 'Current tax obligations.'),
    ('2000', '2400', 'Deferred Revenue', 'liability', 'credit', TRUE, 'Customer billings not yet recognized as revenue.'),

    -- Equity
    ('3000', '3100', 'Contributed Capital', 'equity', 'credit', TRUE, 'Owner and shareholder capital contributions.'),
    ('3000', '3200', 'Retained Earnings', 'equity', 'credit', TRUE, 'Accumulated retained earnings and historical equity.'),

    -- Revenue
    ('4000', '4100', 'Product Revenue', 'revenue', 'credit', TRUE, 'Revenue from products, merchandise, and equipment.'),
    ('4000', '4200', 'Service Revenue', 'revenue', 'credit', TRUE, 'Revenue from consulting, subscriptions, logistics, and services.'),
    ('4000', '4300', 'Other Operating Revenue', 'revenue', 'credit', TRUE, 'Ancillary operating revenue.'),

    -- Direct costs
    ('5000', '5100', 'Cost of Goods Sold', 'expense', 'debit', TRUE, 'Cost of merchandise, materials, and finished goods sold.'),
    ('5000', '5200', 'Direct Labor and Delivery', 'expense', 'debit', TRUE, 'Direct professional and technical delivery costs.'),
    ('5000', '5300', 'Freight and Fulfillment', 'expense', 'debit', TRUE, 'Carrier, freight, fulfillment, and direct logistics costs.'),

    -- Operating expenses
    ('6000', '6100', 'Payroll and Benefits', 'expense', 'debit', TRUE, 'Payroll, benefits, and employer-related personnel costs.'),
    ('6000', '6200', 'Occupancy and Facilities', 'expense', 'debit', TRUE, 'Rent, utilities, maintenance, and facilities costs.'),
    ('6000', '6300', 'Technology and Software', 'expense', 'debit', TRUE, 'Software, cloud, communications, and technology services.'),
    ('6000', '6400', 'Marketing and Sales', 'expense', 'debit', TRUE, 'Advertising, campaigns, events, and sales enablement.'),
    ('6000', '6500', 'Professional Services', 'expense', 'debit', TRUE, 'Legal, audit, advisory, and specialist services.'),
    ('6000', '6600', 'Travel and Training', 'expense', 'debit', TRUE, 'Business travel, conferences, and employee development.'),
    ('6000', '6700', 'Depreciation Expense', 'expense', 'debit', TRUE, 'Periodic depreciation of property and equipment.'),
    ('6000', '6800', 'Bank and Payment Fees', 'expense', 'debit', TRUE, 'Bank charges, merchant fees, and payment-processing costs.'),
    ('6000', '6850', 'Income Tax Expense', 'expense', 'debit', TRUE, 'Current-period income tax expense.'),
    ('6000', '6900', 'Other Operating Expense', 'expense', 'debit', TRUE, 'Other operating expenses not classified elsewhere.');

-- Grouping accounts first.
INSERT INTO finance.accounts (
    company_id,
    parent_account_id,
    account_code,
    account_name,
    account_type,
    normal_balance,
    is_postable,
    is_active,
    description
)
SELECT
    companies.company_id,
    NULL,
    templates.account_code,
    templates.account_name,
    templates.account_type,
    templates.normal_balance,
    templates.is_postable,
    companies.company_status = 'active',
    templates.description
FROM fixture_account_templates AS templates
CROSS JOIN core.companies AS companies
WHERE companies.company_slug IN (
    SELECT company_slug
    FROM fixture_finance_profiles
)
  AND templates.parent_account_code IS NULL
ON CONFLICT (company_id, account_code)
DO UPDATE SET
    parent_account_id = NULL,
    account_name = EXCLUDED.account_name,
    account_type = EXCLUDED.account_type,
    normal_balance = EXCLUDED.normal_balance,
    is_postable = EXCLUDED.is_postable,
    is_active = EXCLUDED.is_active,
    description = EXCLUDED.description;

-- Postable accounts after grouping accounts exist.
INSERT INTO finance.accounts (
    company_id,
    parent_account_id,
    account_code,
    account_name,
    account_type,
    normal_balance,
    is_postable,
    is_active,
    description
)
SELECT
    companies.company_id,
    parents.account_id,
    templates.account_code,
    templates.account_name,
    templates.account_type,
    templates.normal_balance,
    templates.is_postable,
    companies.company_status = 'active',
    templates.description
FROM fixture_account_templates AS templates
CROSS JOIN core.companies AS companies
JOIN finance.accounts AS parents
    ON parents.company_id = companies.company_id
   AND parents.account_code = templates.parent_account_code
WHERE companies.company_slug IN (
    SELECT company_slug
    FROM fixture_finance_profiles
)
  AND templates.parent_account_code IS NOT NULL
ON CONFLICT (company_id, account_code)
DO UPDATE SET
    parent_account_id = EXCLUDED.parent_account_id,
    account_name = EXCLUDED.account_name,
    account_type = EXCLUDED.account_type,
    normal_balance = EXCLUDED.normal_balance,
    is_postable = EXCLUDED.is_postable,
    is_active = EXCLUDED.is_active,
    description = EXCLUDED.description;


-- ============================================================
-- Monthly operating metrics
-- ============================================================
-- The generator uses deterministic seasonality and a modest
-- company-specific growth rate. No random function is used, so
-- rerunning the fixture always produces the same amounts.

CREATE TEMP TABLE fixture_monthly_finance_metrics
ON COMMIT DROP
AS
WITH generated_months AS (
    SELECT
        profiles.*,
        months.month_start::DATE AS month_start,
        ROW_NUMBER() OVER (
            PARTITION BY profiles.company_slug
            ORDER BY months.month_start
        ) - 1 AS month_index
    FROM fixture_finance_profiles AS profiles
    CROSS JOIN LATERAL generate_series(
        profiles.transaction_start_month::TIMESTAMP,
        profiles.transaction_end_month::TIMESTAMP,
        INTERVAL '1 month'
    ) AS months(month_start)
), seasonally_adjusted AS (
    SELECT
        generated.*,
        CASE EXTRACT(MONTH FROM generated.month_start)::INTEGER
            WHEN 1 THEN 0.92
            WHEN 2 THEN 0.95
            WHEN 3 THEN 1.00
            WHEN 4 THEN 1.02
            WHEN 5 THEN 1.04
            WHEN 6 THEN 1.00
            WHEN 7 THEN 1.03
            WHEN 8 THEN 1.05
            WHEN 9 THEN 1.08
            WHEN 10 THEN 1.10
            WHEN 11 THEN 1.18
            WHEN 12 THEN 1.30
        END::NUMERIC(6, 4) AS seasonality_factor,
        (
            1
            + generated.annual_growth_rate
              * generated.month_index::NUMERIC
              / 12.0
        )::NUMERIC(12, 6) AS growth_factor
    FROM generated_months AS generated
)
SELECT
    adjusted.*,
    ROUND(
        adjusted.base_monthly_revenue
        * adjusted.seasonality_factor
        * adjusted.growth_factor,
        2
    ) AS revenue_amount,
    ROUND(
        adjusted.base_monthly_revenue
        * adjusted.seasonality_factor
        * adjusted.growth_factor
        * 0.97,
        2
    ) AS collection_amount,
    ROUND(
        adjusted.base_monthly_payroll
        * (1 + adjusted.annual_growth_rate * adjusted.month_index::NUMERIC / 18.0),
        2
    ) AS payroll_amount,
    ROUND(
        adjusted.base_monthly_operating_expense
        * (0.96 + adjusted.seasonality_factor * 0.04)
        * adjusted.growth_factor,
        2
    ) AS operating_expense_amount,
    ROUND(
        adjusted.base_monthly_direct_cost
        * adjusted.seasonality_factor
        * adjusted.growth_factor,
        2
    ) AS direct_cost_amount,
    ROUND(
        adjusted.base_monthly_depreciation,
        2
    ) AS depreciation_amount,
    ROUND(
        adjusted.base_monthly_tax_expense
        * adjusted.seasonality_factor
        * adjusted.growth_factor,
        2
    ) AS tax_amount
FROM seasonally_adjusted AS adjusted;


-- ============================================================
-- Transaction headers
-- ============================================================

CREATE TEMP TABLE fixture_finance_transaction_headers (
    company_slug TEXT NOT NULL,
    transaction_number TEXT NOT NULL,
    transaction_date DATE NOT NULL,
    posting_date DATE,
    transaction_type TEXT NOT NULL,
    status TEXT NOT NULL,
    source_document_id TEXT NOT NULL,
    description TEXT,
    posted_at TIMESTAMPTZ,
    voided_at TIMESTAMPTZ,
    PRIMARY KEY (company_slug, transaction_number)
) ON COMMIT DROP;

-- Opening balances.
INSERT INTO fixture_finance_transaction_headers (
    company_slug,
    transaction_number,
    transaction_date,
    posting_date,
    transaction_type,
    status,
    source_document_id,
    description,
    posted_at,
    voided_at
)
SELECT
    profiles.company_slug,
    FORMAT(
        '%s-%s-OPEN',
        profiles.transaction_prefix,
        TO_CHAR(profiles.transaction_start_month, 'YYYYMM')
    ),
    profiles.transaction_start_month,
    profiles.transaction_start_month,
    'opening_balance',
    'posted',
    FORMAT(
        '%s-%s-OPEN',
        profiles.transaction_prefix,
        TO_CHAR(profiles.transaction_start_month, 'YYYYMM')
    ),
    'Synthetic opening balance for the fixture ledger.',
    (
        profiles.transaction_start_month::TIMESTAMP
        + INTERVAL '18 hours'
    ) AT TIME ZONE 'UTC',
    NULL
FROM fixture_finance_profiles AS profiles;

-- Eight recurring monthly journal types.
INSERT INTO fixture_finance_transaction_headers (
    company_slug,
    transaction_number,
    transaction_date,
    posting_date,
    transaction_type,
    status,
    source_document_id,
    description,
    posted_at,
    voided_at
)
SELECT
    metrics.company_slug,
    FORMAT(
        '%s-%s-%s',
        metrics.transaction_prefix,
        TO_CHAR(metrics.month_start, 'YYYYMM'),
        events.event_code
    ),
    CASE
        WHEN events.use_month_end THEN
            (metrics.month_start + INTERVAL '1 month - 1 day')::DATE
        ELSE
            metrics.month_start + events.day_offset
    END AS transaction_date,
    CASE
        WHEN events.use_month_end THEN
            (metrics.month_start + INTERVAL '1 month - 1 day')::DATE
        ELSE
            metrics.month_start + events.day_offset
    END AS posting_date,
    events.transaction_type,
    'posted',
    FORMAT(
        '%s-%s-%s',
        metrics.transaction_prefix,
        TO_CHAR(metrics.month_start, 'YYYYMM'),
        events.event_code
    ),
    FORMAT('%s for %s.', events.description_prefix, TO_CHAR(metrics.month_start, 'YYYY-MM')),
    (
        CASE
            WHEN events.use_month_end THEN
                (metrics.month_start + INTERVAL '1 month - 1 day')::TIMESTAMP
            ELSE
                (metrics.month_start + events.day_offset)::TIMESTAMP
        END
        + INTERVAL '18 hours'
    ) AT TIME ZONE 'UTC',
    NULL
FROM fixture_monthly_finance_metrics AS metrics
CROSS JOIN LATERAL (
    VALUES
        ('REV',  'revenue_recognition',  9, FALSE, 'Monthly revenue recognition'),
        ('COL',  'customer_collection', 19, FALSE, 'Customer cash collections'),
        ('COST', 'direct_cost',          9, FALSE, 'Monthly direct-cost recognition'),
        ('PAY',  'payroll',             24, FALSE, 'Monthly payroll'),
        ('OPEX', 'vendor_bill',         14, FALSE, 'Monthly operating-expense accrual'),
        ('VPAY', 'vendor_payment',      23, FALSE, 'Supplier and service-provider payments'),
        ('DEP',  'depreciation',         0, TRUE,  'Monthly depreciation'),
        ('TAX',  'tax_accrual',          0, TRUE,  'Monthly tax accrual')
) AS events (
    event_code,
    transaction_type,
    day_offset,
    use_month_end,
    description_prefix
);

-- Product companies replenish inventory monthly.
INSERT INTO fixture_finance_transaction_headers (
    company_slug,
    transaction_number,
    transaction_date,
    posting_date,
    transaction_type,
    status,
    source_document_id,
    description,
    posted_at,
    voided_at
)
SELECT
    metrics.company_slug,
    FORMAT(
        '%s-%s-INV',
        metrics.transaction_prefix,
        TO_CHAR(metrics.month_start, 'YYYYMM')
    ),
    metrics.month_start + 4,
    metrics.month_start + 4,
    'inventory_purchase',
    'posted',
    FORMAT(
        '%s-%s-INV',
        metrics.transaction_prefix,
        TO_CHAR(metrics.month_start, 'YYYYMM')
    ),
    FORMAT('Monthly inventory replenishment for %s.', TO_CHAR(metrics.month_start, 'YYYY-MM')),
    (
        (metrics.month_start + 4)::TIMESTAMP
        + INTERVAL '18 hours'
    ) AT TIME ZONE 'UTC',
    NULL
FROM fixture_monthly_finance_metrics AS metrics
WHERE metrics.is_product_company;

-- Quarterly tax payments.
INSERT INTO fixture_finance_transaction_headers (
    company_slug,
    transaction_number,
    transaction_date,
    posting_date,
    transaction_type,
    status,
    source_document_id,
    description,
    posted_at,
    voided_at
)
SELECT
    metrics.company_slug,
    FORMAT(
        '%s-%s-TAXPAY',
        metrics.transaction_prefix,
        TO_CHAR(metrics.month_start, 'YYYYMM')
    ),
    metrics.month_start + 20,
    metrics.month_start + 20,
    'tax_payment',
    'posted',
    FORMAT(
        '%s-%s-TAXPAY',
        metrics.transaction_prefix,
        TO_CHAR(metrics.month_start, 'YYYYMM')
    ),
    FORMAT('Quarterly tax payment recorded in %s.', TO_CHAR(metrics.month_start, 'YYYY-MM')),
    (
        (metrics.month_start + 20)::TIMESTAMP
        + INTERVAL '18 hours'
    ) AT TIME ZONE 'UTC',
    NULL
FROM fixture_monthly_finance_metrics AS metrics
WHERE EXTRACT(MONTH FROM metrics.month_start)::INTEGER IN (3, 6, 9, 12);

-- One incomplete draft per active company. Draft transactions may
-- contain incomplete journal lines and are intentionally excluded
-- from posted-balance analytics.
INSERT INTO fixture_finance_transaction_headers (
    company_slug,
    transaction_number,
    transaction_date,
    posting_date,
    transaction_type,
    status,
    source_document_id,
    description,
    posted_at,
    voided_at
)
SELECT
    profiles.company_slug,
    FORMAT('%s-202607-DRAFT', profiles.transaction_prefix),
    DATE '2026-07-08',
    NULL,
    'budget_adjustment',
    'draft',
    FORMAT('%s-202607-DRAFT', profiles.transaction_prefix),
    'Draft budget reclassification awaiting review and completion.',
    NULL,
    NULL
FROM fixture_finance_profiles AS profiles
JOIN core.companies AS companies
    ON companies.company_slug = profiles.company_slug
WHERE companies.company_status = 'active';

-- One voided example per active company.
INSERT INTO fixture_finance_transaction_headers (
    company_slug,
    transaction_number,
    transaction_date,
    posting_date,
    transaction_type,
    status,
    source_document_id,
    description,
    posted_at,
    voided_at
)
SELECT
    profiles.company_slug,
    FORMAT('%s-202606-VOID', profiles.transaction_prefix),
    DATE '2026-06-10',
    NULL,
    'vendor_bill',
    'voided',
    FORMAT('%s-202606-VOID', profiles.transaction_prefix),
    'Voided duplicate supplier invoice retained for auditability.',
    NULL,
    TIMESTAMPTZ '2026-06-12 16:30:00+00'
FROM fixture_finance_profiles AS profiles
JOIN core.companies AS companies
    ON companies.company_slug = profiles.company_slug
WHERE companies.company_status = 'active';

-- Rebuild only the transactions owned by this fixture. Other data
-- in the database remains untouched.
DELETE FROM finance.financial_transactions
WHERE source_system = 'realistic_multi_company_fixture';

INSERT INTO finance.financial_transactions (
    company_id,
    fiscal_period_id,
    transaction_number,
    transaction_date,
    posting_date,
    currency_code,
    transaction_type,
    status,
    source_system,
    source_document_id,
    description,
    created_by_account_id,
    posted_at,
    voided_at
)
SELECT
    companies.company_id,
    periods.fiscal_period_id,
    fixture.transaction_number,
    fixture.transaction_date,
    fixture.posting_date,
    companies.default_currency_code,
    fixture.transaction_type,
    fixture.status,
    'realistic_multi_company_fixture',
    fixture.source_document_id,
    fixture.description,
    creator_accounts.account_id,
    fixture.posted_at,
    fixture.voided_at
FROM fixture_finance_transaction_headers AS fixture
JOIN fixture_finance_profiles AS profiles
    ON profiles.company_slug = fixture.company_slug
JOIN core.companies AS companies
    ON companies.company_slug = fixture.company_slug
JOIN finance.fiscal_periods AS periods
    ON periods.company_id = companies.company_id
   AND periods.fiscal_year = EXTRACT(YEAR FROM fixture.transaction_date)::INTEGER
   AND periods.period_number = EXTRACT(MONTH FROM fixture.transaction_date)::SMALLINT
LEFT JOIN people.persons AS creator_people
    ON creator_people.company_id = companies.company_id
   AND creator_people.external_reference = profiles.creator_person_external_reference
LEFT JOIN identity.user_accounts AS creator_accounts
    ON creator_accounts.person_id = creator_people.person_id;


-- ============================================================
-- Transaction lines
-- ============================================================

CREATE TEMP TABLE fixture_finance_transaction_lines (
    company_slug TEXT NOT NULL,
    transaction_number TEXT NOT NULL,
    line_number INTEGER NOT NULL,
    account_code TEXT NOT NULL,
    cost_center_code TEXT NOT NULL,
    branch_code TEXT NOT NULL,
    department_code TEXT NOT NULL,
    counterparty_person_external_reference TEXT,
    debit_amount NUMERIC(18, 4) NOT NULL,
    credit_amount NUMERIC(18, 4) NOT NULL,
    line_description TEXT,
    PRIMARY KEY (company_slug, transaction_number, line_number)
) ON COMMIT DROP;

-- Opening-balance lines.
INSERT INTO fixture_finance_transaction_lines (
    company_slug,
    transaction_number,
    line_number,
    account_code,
    cost_center_code,
    branch_code,
    department_code,
    counterparty_person_external_reference,
    debit_amount,
    credit_amount,
    line_description
)
SELECT
    profiles.company_slug,
    FORMAT(
        '%s-%s-OPEN',
        profiles.transaction_prefix,
        TO_CHAR(profiles.transaction_start_month, 'YYYYMM')
    ),
    lines.line_number,
    lines.account_code,
    profiles.finance_cost_center_code,
    profiles.finance_branch_code,
    profiles.finance_department_code,
    NULL,
    lines.debit_amount,
    lines.credit_amount,
    lines.line_description
FROM fixture_finance_profiles AS profiles
CROSS JOIN LATERAL (
    SELECT
        1 AS line_number,
        '1100'::TEXT AS account_code,
        ROUND(
            profiles.base_monthly_payroll * 3
            + profiles.base_monthly_operating_expense * 2,
            2
        )::NUMERIC(18, 4) AS debit_amount,
        0::NUMERIC(18, 4) AS credit_amount,
        'Opening operating cash balance.'::TEXT AS line_description

    UNION ALL

    SELECT
        2,
        '1200',
        ROUND(profiles.base_monthly_revenue * 0.45, 2)::NUMERIC(18, 4),
        0::NUMERIC(18, 4),
        'Opening trade receivables.'

    UNION ALL

    SELECT
        3,
        profiles.opening_working_asset_account_code,
        ROUND(
            profiles.base_monthly_direct_cost
            * CASE WHEN profiles.is_product_company THEN 2.20 ELSE 0.40 END,
            2
        )::NUMERIC(18, 4),
        0::NUMERIC(18, 4),
        CASE
            WHEN profiles.is_product_company THEN 'Opening inventory balance.'
            ELSE 'Opening prepaid operating assets.'
        END

    UNION ALL

    SELECT
        4,
        '1500',
        ROUND(profiles.base_monthly_depreciation * 36, 2)::NUMERIC(18, 4),
        0::NUMERIC(18, 4),
        'Opening property and equipment balance.'

    UNION ALL

    SELECT
        5,
        '2100',
        0::NUMERIC(18, 4),
        ROUND(
            profiles.base_monthly_operating_expense * 0.60
            + profiles.base_monthly_direct_cost
              * CASE WHEN profiles.is_product_company THEN 0.40 ELSE 0.30 END,
            2
        )::NUMERIC(18, 4),
        'Opening supplier and service-provider obligations.'

    UNION ALL

    SELECT
        6,
        profiles.opening_equity_account_code,
        0::NUMERIC(18, 4),
        ROUND(
            (
                profiles.base_monthly_payroll * 3
                + profiles.base_monthly_operating_expense * 2
            )
            + profiles.base_monthly_revenue * 0.45
            + profiles.base_monthly_direct_cost
              * CASE WHEN profiles.is_product_company THEN 2.20 ELSE 0.40 END
            + profiles.base_monthly_depreciation * 36
            - (
                profiles.base_monthly_operating_expense * 0.60
                + profiles.base_monthly_direct_cost
                  * CASE WHEN profiles.is_product_company THEN 0.40 ELSE 0.30 END
              ),
            2
        )::NUMERIC(18, 4),
        CASE
            WHEN profiles.opening_equity_account_code = '3200'
                THEN 'Opening retained-earnings balance.'
            ELSE 'Opening contributed-capital balance.'
        END
) AS lines;

-- Recurring monthly two-line journals.
INSERT INTO fixture_finance_transaction_lines (
    company_slug,
    transaction_number,
    line_number,
    account_code,
    cost_center_code,
    branch_code,
    department_code,
    counterparty_person_external_reference,
    debit_amount,
    credit_amount,
    line_description
)
SELECT
    metrics.company_slug,
    lines.transaction_number,
    lines.line_number,
    lines.account_code,
    lines.cost_center_code,
    lines.branch_code,
    lines.department_code,
    lines.counterparty_person_external_reference,
    lines.debit_amount,
    lines.credit_amount,
    lines.line_description
FROM fixture_monthly_finance_metrics AS metrics
CROSS JOIN LATERAL (
    VALUES
        -- Revenue recognition
        (
            FORMAT('%s-%s-REV', metrics.transaction_prefix, TO_CHAR(metrics.month_start, 'YYYYMM')),
            1,
            '1200',
            metrics.operating_cost_center_code,
            metrics.operating_branch_code,
            metrics.operating_department_code,
            metrics.customer_person_external_reference,
            metrics.revenue_amount::NUMERIC(18, 4),
            0::NUMERIC(18, 4),
            'Trade receivable recognized for monthly revenue.'
        ),
        (
            FORMAT('%s-%s-REV', metrics.transaction_prefix, TO_CHAR(metrics.month_start, 'YYYYMM')),
            2,
            metrics.revenue_account_code,
            metrics.operating_cost_center_code,
            metrics.operating_branch_code,
            metrics.operating_department_code,
            metrics.customer_person_external_reference,
            0::NUMERIC(18, 4),
            metrics.revenue_amount::NUMERIC(18, 4),
            'Monthly operating revenue.'
        ),

        -- Customer collections
        (
            FORMAT('%s-%s-COL', metrics.transaction_prefix, TO_CHAR(metrics.month_start, 'YYYYMM')),
            1,
            '1100',
            metrics.finance_cost_center_code,
            metrics.finance_branch_code,
            metrics.finance_department_code,
            metrics.customer_person_external_reference,
            metrics.collection_amount::NUMERIC(18, 4),
            0::NUMERIC(18, 4),
            'Cash received from customers.'
        ),
        (
            FORMAT('%s-%s-COL', metrics.transaction_prefix, TO_CHAR(metrics.month_start, 'YYYYMM')),
            2,
            '1200',
            metrics.finance_cost_center_code,
            metrics.finance_branch_code,
            metrics.finance_department_code,
            metrics.customer_person_external_reference,
            0::NUMERIC(18, 4),
            metrics.collection_amount::NUMERIC(18, 4),
            'Reduction of trade receivables after collection.'
        ),

        -- Direct cost recognition
        (
            FORMAT('%s-%s-COST', metrics.transaction_prefix, TO_CHAR(metrics.month_start, 'YYYYMM')),
            1,
            metrics.direct_cost_account_code,
            metrics.operating_cost_center_code,
            metrics.operating_branch_code,
            metrics.operating_department_code,
            metrics.supplier_person_external_reference,
            metrics.direct_cost_amount::NUMERIC(18, 4),
            0::NUMERIC(18, 4),
            'Direct cost recognized for the month.'
        ),
        (
            FORMAT('%s-%s-COST', metrics.transaction_prefix, TO_CHAR(metrics.month_start, 'YYYYMM')),
            2,
            metrics.direct_cost_offset_account_code,
            metrics.operating_cost_center_code,
            metrics.operating_branch_code,
            metrics.operating_department_code,
            metrics.supplier_person_external_reference,
            0::NUMERIC(18, 4),
            metrics.direct_cost_amount::NUMERIC(18, 4),
            CASE
                WHEN metrics.is_product_company THEN 'Inventory relieved for goods sold.'
                ELSE 'Direct delivery costs accrued to suppliers.'
            END
        ),

        -- Payroll
        (
            FORMAT('%s-%s-PAY', metrics.transaction_prefix, TO_CHAR(metrics.month_start, 'YYYYMM')),
            1,
            '6100',
            metrics.operating_cost_center_code,
            metrics.finance_branch_code,
            metrics.finance_department_code,
            NULL,
            metrics.payroll_amount::NUMERIC(18, 4),
            0::NUMERIC(18, 4),
            'Monthly payroll and employee benefits.'
        ),
        (
            FORMAT('%s-%s-PAY', metrics.transaction_prefix, TO_CHAR(metrics.month_start, 'YYYYMM')),
            2,
            '1100',
            metrics.finance_cost_center_code,
            metrics.finance_branch_code,
            metrics.finance_department_code,
            NULL,
            0::NUMERIC(18, 4),
            metrics.payroll_amount::NUMERIC(18, 4),
            'Cash disbursed for payroll and benefits.'
        ),

        -- Operating-expense accrual
        (
            FORMAT('%s-%s-OPEX', metrics.transaction_prefix, TO_CHAR(metrics.month_start, 'YYYYMM')),
            1,
            CASE EXTRACT(MONTH FROM metrics.month_start)::INTEGER
                WHEN 1 THEN '6200'
                WHEN 2 THEN '6300'
                WHEN 3 THEN '6400'
                WHEN 4 THEN '6500'
                WHEN 5 THEN '6600'
                WHEN 6 THEN '6900'
                WHEN 7 THEN '6200'
                WHEN 8 THEN '6300'
                WHEN 9 THEN '6400'
                WHEN 10 THEN '6500'
                WHEN 11 THEN '6600'
                WHEN 12 THEN '6900'
            END,
            metrics.operating_cost_center_code,
            metrics.operating_branch_code,
            metrics.operating_department_code,
            metrics.supplier_person_external_reference,
            metrics.operating_expense_amount::NUMERIC(18, 4),
            0::NUMERIC(18, 4),
            'Monthly operating expense accrued from supplier activity.'
        ),
        (
            FORMAT('%s-%s-OPEX', metrics.transaction_prefix, TO_CHAR(metrics.month_start, 'YYYYMM')),
            2,
            '2100',
            metrics.operating_cost_center_code,
            metrics.operating_branch_code,
            metrics.operating_department_code,
            metrics.supplier_person_external_reference,
            0::NUMERIC(18, 4),
            metrics.operating_expense_amount::NUMERIC(18, 4),
            'Supplier obligation recognized for operating expenses.'
        ),

        -- Vendor payment
        (
            FORMAT('%s-%s-VPAY', metrics.transaction_prefix, TO_CHAR(metrics.month_start, 'YYYYMM')),
            1,
            '2100',
            metrics.finance_cost_center_code,
            metrics.finance_branch_code,
            metrics.finance_department_code,
            metrics.supplier_person_external_reference,
            ROUND(
                metrics.operating_expense_amount * 0.92
                + metrics.direct_cost_amount * 0.95,
                2
            )::NUMERIC(18, 4),
            0::NUMERIC(18, 4),
            'Supplier obligations settled during the month.'
        ),
        (
            FORMAT('%s-%s-VPAY', metrics.transaction_prefix, TO_CHAR(metrics.month_start, 'YYYYMM')),
            2,
            '1100',
            metrics.finance_cost_center_code,
            metrics.finance_branch_code,
            metrics.finance_department_code,
            metrics.supplier_person_external_reference,
            0::NUMERIC(18, 4),
            ROUND(
                metrics.operating_expense_amount * 0.92
                + metrics.direct_cost_amount * 0.95,
                2
            )::NUMERIC(18, 4),
            'Cash paid to suppliers and service providers.'
        ),

        -- Depreciation
        (
            FORMAT('%s-%s-DEP', metrics.transaction_prefix, TO_CHAR(metrics.month_start, 'YYYYMM')),
            1,
            '6700',
            metrics.finance_cost_center_code,
            metrics.finance_branch_code,
            metrics.finance_department_code,
            NULL,
            metrics.depreciation_amount::NUMERIC(18, 4),
            0::NUMERIC(18, 4),
            'Monthly depreciation expense.'
        ),
        (
            FORMAT('%s-%s-DEP', metrics.transaction_prefix, TO_CHAR(metrics.month_start, 'YYYYMM')),
            2,
            '1600',
            metrics.finance_cost_center_code,
            metrics.finance_branch_code,
            metrics.finance_department_code,
            NULL,
            0::NUMERIC(18, 4),
            metrics.depreciation_amount::NUMERIC(18, 4),
            'Monthly increase in accumulated depreciation.'
        ),

        -- Tax accrual
        (
            FORMAT('%s-%s-TAX', metrics.transaction_prefix, TO_CHAR(metrics.month_start, 'YYYYMM')),
            1,
            '6850',
            metrics.finance_cost_center_code,
            metrics.finance_branch_code,
            metrics.finance_department_code,
            NULL,
            metrics.tax_amount::NUMERIC(18, 4),
            0::NUMERIC(18, 4),
            'Monthly income tax expense.'
        ),
        (
            FORMAT('%s-%s-TAX', metrics.transaction_prefix, TO_CHAR(metrics.month_start, 'YYYYMM')),
            2,
            '2300',
            metrics.finance_cost_center_code,
            metrics.finance_branch_code,
            metrics.finance_department_code,
            NULL,
            0::NUMERIC(18, 4),
            metrics.tax_amount::NUMERIC(18, 4),
            'Monthly tax obligation accrued.'
        )
) AS lines (
    transaction_number,
    line_number,
    account_code,
    cost_center_code,
    branch_code,
    department_code,
    counterparty_person_external_reference,
    debit_amount,
    credit_amount,
    line_description
);

-- Product-company inventory purchases.
INSERT INTO fixture_finance_transaction_lines (
    company_slug,
    transaction_number,
    line_number,
    account_code,
    cost_center_code,
    branch_code,
    department_code,
    counterparty_person_external_reference,
    debit_amount,
    credit_amount,
    line_description
)
SELECT
    metrics.company_slug,
    FORMAT('%s-%s-INV', metrics.transaction_prefix, TO_CHAR(metrics.month_start, 'YYYYMM')),
    lines.line_number,
    lines.account_code,
    metrics.operating_cost_center_code,
    metrics.operating_branch_code,
    metrics.operating_department_code,
    metrics.supplier_person_external_reference,
    lines.debit_amount,
    lines.credit_amount,
    lines.line_description
FROM fixture_monthly_finance_metrics AS metrics
CROSS JOIN LATERAL (
    VALUES
        (
            1,
            '1300',
            ROUND(metrics.direct_cost_amount * 1.03, 2)::NUMERIC(18, 4),
            0::NUMERIC(18, 4),
            'Inventory replenishment received from suppliers.'
        ),
        (
            2,
            '2100',
            0::NUMERIC(18, 4),
            ROUND(metrics.direct_cost_amount * 1.03, 2)::NUMERIC(18, 4),
            'Supplier obligation recognized for inventory replenishment.'
        )
) AS lines (
    line_number,
    account_code,
    debit_amount,
    credit_amount,
    line_description
)
WHERE metrics.is_product_company;

-- Quarterly tax payments.
INSERT INTO fixture_finance_transaction_lines (
    company_slug,
    transaction_number,
    line_number,
    account_code,
    cost_center_code,
    branch_code,
    department_code,
    counterparty_person_external_reference,
    debit_amount,
    credit_amount,
    line_description
)
SELECT
    metrics.company_slug,
    FORMAT('%s-%s-TAXPAY', metrics.transaction_prefix, TO_CHAR(metrics.month_start, 'YYYYMM')),
    lines.line_number,
    lines.account_code,
    metrics.finance_cost_center_code,
    metrics.finance_branch_code,
    metrics.finance_department_code,
    NULL,
    lines.debit_amount,
    lines.credit_amount,
    lines.line_description
FROM fixture_monthly_finance_metrics AS metrics
CROSS JOIN LATERAL (
    VALUES
        (
            1,
            '2300',
            ROUND(metrics.tax_amount * 2.50, 2)::NUMERIC(18, 4),
            0::NUMERIC(18, 4),
            'Quarterly reduction of taxes payable.'
        ),
        (
            2,
            '1100',
            0::NUMERIC(18, 4),
            ROUND(metrics.tax_amount * 2.50, 2)::NUMERIC(18, 4),
            'Cash remitted for quarterly taxes.'
        )
) AS lines (
    line_number,
    account_code,
    debit_amount,
    credit_amount,
    line_description
)
WHERE EXTRACT(MONTH FROM metrics.month_start)::INTEGER IN (3, 6, 9, 12);

-- Incomplete draft examples: one debit line only, intentionally
-- unbalanced because the transaction status is draft.
INSERT INTO fixture_finance_transaction_lines (
    company_slug,
    transaction_number,
    line_number,
    account_code,
    cost_center_code,
    branch_code,
    department_code,
    counterparty_person_external_reference,
    debit_amount,
    credit_amount,
    line_description
)
SELECT
    profiles.company_slug,
    FORMAT('%s-202607-DRAFT', profiles.transaction_prefix),
    1,
    '6900',
    profiles.finance_cost_center_code,
    profiles.finance_branch_code,
    profiles.finance_department_code,
    NULL,
    ROUND(profiles.base_monthly_operating_expense * 0.05, 2)::NUMERIC(18, 4),
    0::NUMERIC(18, 4),
    'Unfinished draft reclassification line.'
FROM fixture_finance_profiles AS profiles
JOIN core.companies AS companies
    ON companies.company_slug = profiles.company_slug
WHERE companies.company_status = 'active';

-- Balanced lines retained on voided examples.
INSERT INTO fixture_finance_transaction_lines (
    company_slug,
    transaction_number,
    line_number,
    account_code,
    cost_center_code,
    branch_code,
    department_code,
    counterparty_person_external_reference,
    debit_amount,
    credit_amount,
    line_description
)
SELECT
    profiles.company_slug,
    FORMAT('%s-202606-VOID', profiles.transaction_prefix),
    lines.line_number,
    lines.account_code,
    profiles.finance_cost_center_code,
    profiles.finance_branch_code,
    profiles.finance_department_code,
    profiles.supplier_person_external_reference,
    lines.debit_amount,
    lines.credit_amount,
    lines.line_description
FROM fixture_finance_profiles AS profiles
JOIN core.companies AS companies
    ON companies.company_slug = profiles.company_slug
CROSS JOIN LATERAL (
    VALUES
        (
            1,
            '6500',
            ROUND(profiles.base_monthly_operating_expense * 0.075, 2)::NUMERIC(18, 4),
            0::NUMERIC(18, 4),
            'Voided duplicate professional-services expense.'
        ),
        (
            2,
            '2100',
            0::NUMERIC(18, 4),
            ROUND(profiles.base_monthly_operating_expense * 0.075, 2)::NUMERIC(18, 4),
            'Voided duplicate supplier obligation.'
        )
) AS lines (
    line_number,
    account_code,
    debit_amount,
    credit_amount,
    line_description
)
WHERE companies.company_status = 'active';


-- ============================================================
-- Resolve stable line keys to generated identities
-- ============================================================

CREATE TEMP TABLE fixture_resolved_finance_transaction_lines
ON COMMIT DROP
AS
SELECT
    companies.company_id,
    transactions.transaction_id,
    fixture.line_number,
    accounts.account_id,
    cost_centers.cost_center_id,
    branches.branch_id,
    departments.department_id,
    counterparties.person_id AS counterparty_person_id,
    fixture.debit_amount,
    fixture.credit_amount,
    fixture.line_description
FROM fixture_finance_transaction_lines AS fixture
JOIN core.companies AS companies
    ON companies.company_slug = fixture.company_slug
JOIN finance.financial_transactions AS transactions
    ON transactions.company_id = companies.company_id
   AND transactions.transaction_number = fixture.transaction_number
JOIN finance.accounts AS accounts
    ON accounts.company_id = companies.company_id
   AND accounts.account_code = fixture.account_code
JOIN finance.cost_centers AS cost_centers
    ON cost_centers.company_id = companies.company_id
   AND cost_centers.cost_center_code = fixture.cost_center_code
JOIN core.branches AS branches
    ON branches.company_id = companies.company_id
   AND branches.branch_code = fixture.branch_code
JOIN core.departments AS departments
    ON departments.company_id = companies.company_id
   AND departments.department_code = fixture.department_code
LEFT JOIN people.persons AS counterparties
    ON counterparties.company_id = companies.company_id
   AND counterparties.external_reference = fixture.counterparty_person_external_reference
WHERE fixture.counterparty_person_external_reference IS NULL
   OR counterparties.person_id IS NOT NULL;

DO $$
DECLARE
    fixture_line_count BIGINT;
    resolved_line_count BIGINT;
BEGIN
    SELECT COUNT(*)
    INTO fixture_line_count
    FROM fixture_finance_transaction_lines;

    SELECT COUNT(*)
    INTO resolved_line_count
    FROM fixture_resolved_finance_transaction_lines;

    IF resolved_line_count <> fixture_line_count THEN
        RAISE EXCEPTION
            '05_finance.sql resolved only % of % transaction lines. Check account, cost-center, branch, department, and person business keys.',
            resolved_line_count,
            fixture_line_count;
    END IF;
END;
$$;

INSERT INTO finance.transaction_lines (
    company_id,
    transaction_id,
    line_number,
    account_id,
    cost_center_id,
    branch_id,
    department_id,
    counterparty_person_id,
    debit_amount,
    credit_amount,
    line_description
)
SELECT
    resolved.company_id,
    resolved.transaction_id,
    resolved.line_number,
    resolved.account_id,
    resolved.cost_center_id,
    resolved.branch_id,
    resolved.department_id,
    resolved.counterparty_person_id,
    resolved.debit_amount,
    resolved.credit_amount,
    resolved.line_description
FROM fixture_resolved_finance_transaction_lines AS resolved
ON CONFLICT (transaction_id, line_number)
DO UPDATE SET
    company_id = EXCLUDED.company_id,
    account_id = EXCLUDED.account_id,
    cost_center_id = EXCLUDED.cost_center_id,
    branch_id = EXCLUDED.branch_id,
    department_id = EXCLUDED.department_id,
    counterparty_person_id = EXCLUDED.counterparty_person_id,
    debit_amount = EXCLUDED.debit_amount,
    credit_amount = EXCLUDED.credit_amount,
    line_description = EXCLUDED.line_description;


-- ============================================================
-- Fixture validation
-- ============================================================

DO $$
BEGIN
    -- Every managed posted transaction must have at least two
    -- lines and exactly equal debit and credit totals.
    IF EXISTS (
        SELECT 1
        FROM finance.financial_transactions AS transactions
        LEFT JOIN finance.transaction_lines AS lines
            ON lines.transaction_id = transactions.transaction_id
        WHERE transactions.source_system = 'realistic_multi_company_fixture'
          AND transactions.status = 'posted'
        GROUP BY transactions.transaction_id
        HAVING COUNT(lines.transaction_line_id) < 2
            OR COALESCE(SUM(lines.debit_amount), 0)
               <> COALESCE(SUM(lines.credit_amount), 0)
    ) THEN
        RAISE EXCEPTION
            '05_finance.sql generated an incomplete or unbalanced posted transaction.';
    END IF;

    -- The branch and department columns on transaction_lines use
    -- independent foreign keys in the MVP schema. Validate the
    -- company relationship explicitly inside the fixture.
    IF EXISTS (
        SELECT 1
        FROM finance.transaction_lines AS lines
        JOIN finance.financial_transactions AS transactions
            ON transactions.transaction_id = lines.transaction_id
        JOIN core.branches AS branches
            ON branches.branch_id = lines.branch_id
        JOIN core.departments AS departments
            ON departments.department_id = lines.department_id
        WHERE transactions.source_system = 'realistic_multi_company_fixture'
          AND (
                branches.company_id <> lines.company_id
                OR departments.company_id <> lines.company_id
              )
    ) THEN
        RAISE EXCEPTION
            '05_finance.sql generated a cross-company branch or department reference.';
    END IF;

    -- Every fixture header must have been inserted.
    IF (
        SELECT COUNT(*)
        FROM finance.financial_transactions
        WHERE source_system = 'realistic_multi_company_fixture'
    ) <> (
        SELECT COUNT(*)
        FROM fixture_finance_transaction_headers
    ) THEN
        RAISE EXCEPTION
            '05_finance.sql did not insert every generated transaction header.';
    END IF;
END;
$$;

COMMIT;

\echo '05_finance.sql completed'