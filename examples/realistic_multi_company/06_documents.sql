\set ON_ERROR_STOP on
\encoding UTF8

BEGIN;

-- ============================================================
-- 06_documents.sql
-- Realistic multi-company example
--
-- Purpose:
-- Seed a substantial, internally consistent document dataset:
--
-- - additional reusable document types
-- - company-scoped document records
-- - realistic lifecycle states
-- - versioned external file metadata
-- - links to companies, people, branches, departments, and
--   financial transactions
-- - complete status histories
--
-- Notes:
-- - All organizations, people, documents, identifiers, and file
--   locations are synthetic.
-- - No file contents are stored in PostgreSQL. Storage URIs are
--   illustrative metadata only.
-- - Generated identities are always resolved through stable
--   business keys; no BIGINT identity value is hard-coded.
-- - The script depends on 01_shared_reference_data.sql through
--   05_finance.sql.
-- - The script is safe to run more than once. Document records
--   owned by this fixture are rebuilt deterministically.
-- ============================================================

-- ============================================================
-- Fixture company profiles
-- ============================================================

CREATE TEMP TABLE fixture_document_profiles (
    company_slug TEXT PRIMARY KEY,
    document_prefix TEXT NOT NULL,
    company_label TEXT NOT NULL,
    business_domain TEXT NOT NULL,
    creator_person_external_reference TEXT NOT NULL,
    owner_person_external_reference TEXT NOT NULL,
    headquarters_branch_code TEXT NOT NULL,
    operating_branch_code TEXT NOT NULL,
    finance_department_code TEXT NOT NULL,
    operating_department_code TEXT NOT NULL,
    reference_date DATE NOT NULL,
    archival_date DATE
) ON COMMIT DROP;

INSERT INTO fixture_document_profiles (
    company_slug,
    document_prefix,
    company_label,
    business_domain,
    creator_person_external_reference,
    owner_person_external_reference,
    headquarters_branch_code,
    operating_branch_code,
    finance_department_code,
    operating_department_code,
    reference_date,
    archival_date
)
VALUES
    (
        'solara-retail-mx',
        'SRM',
        'Solara Retail Mexico',
        'omnichannel retail operations',
        'SRM-P009',
        'SRM-P009',
        'MX-CMX-HQ',
        'MX-CMX-POL',
        'FIN-ACC',
        'RET-POL',
        DATE '2026-06-30',
        NULL
    ),
    (
        'cobalto-industrial-mx',
        'CIS',
        'Cobalto Industrial Systems',
        'industrial manufacturing and distribution',
        'CIS-P010',
        'CIS-P010',
        'MX-MTY-HQ',
        'MX-APO-PLT',
        'FIN-ACC',
        'MFG-APO',
        DATE '2026-06-30',
        NULL
    ),
    (
        'bluepeak-advisory-us',
        'BPA',
        'BluePeak Advisory',
        'management and transformation consulting',
        'BPA-P009',
        'BPA-P009',
        'US-AUS-HQ',
        'US-AUS-HQ',
        'FIN-ACC',
        'ADV-STR',
        DATE '2026-06-30',
        NULL
    ),
    (
        'lumenforge-technologies-us',
        'LFT',
        'LumenForge Technologies',
        'enterprise software engineering',
        'LFT-P010',
        'LFT-P010',
        'US-SEA-HQ',
        'US-SEA-HQ',
        'FIN-ACC',
        'ENG-PLT',
        DATE '2026-06-30',
        NULL
    ),
    (
        'cedarline-logistics-ca',
        'CLL',
        'CedarLine Logistics',
        'regional freight and logistics services',
        'CLL-P010',
        'CLL-P010',
        'CA-TOR-HQ',
        'CA-TOR-HQ',
        'FIN-ACC',
        'OPS-EAST',
        DATE '2026-06-30',
        NULL
    ),
    (
        'harvest-circle-foods-ca',
        'HCF',
        'Harvest Circle Foods',
        'food distribution and cold-chain operations',
        'HCF-P008',
        'HCF-P008',
        'CA-VAN-HQ',
        'CA-RIC-DC',
        'FIN-ACC',
        'OPS-RIC',
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
    FROM fixture_document_profiles;

    SELECT COUNT(*)
    INTO resolved_companies
    FROM fixture_document_profiles AS profiles
    JOIN core.companies AS companies
      ON companies.company_slug = profiles.company_slug;

    IF resolved_companies <> expected_companies THEN
        RAISE EXCEPTION
            '06_documents.sql could resolve only % of % fixture companies. Run 02_organizations.sql first.',
            resolved_companies,
            expected_companies;
    END IF;

    IF EXISTS (
        SELECT 1
        FROM fixture_document_profiles AS profiles
        JOIN core.companies AS companies
          ON companies.company_slug = profiles.company_slug
        LEFT JOIN people.persons AS creators
          ON creators.company_id = companies.company_id
         AND creators.external_reference = profiles.creator_person_external_reference
        LEFT JOIN people.persons AS owners
          ON owners.company_id = companies.company_id
         AND owners.external_reference = profiles.owner_person_external_reference
        WHERE creators.person_id IS NULL
           OR owners.person_id IS NULL
    ) THEN
        RAISE EXCEPTION
            '06_documents.sql could not resolve one or more fixture people. Run the current 03_people_and_relationships.sql first.';
    END IF;

    IF EXISTS (
        SELECT 1
        FROM fixture_document_profiles AS profiles
        JOIN core.companies AS companies
          ON companies.company_slug = profiles.company_slug
        LEFT JOIN core.branches AS headquarters
          ON headquarters.company_id = companies.company_id
         AND headquarters.branch_code = profiles.headquarters_branch_code
        LEFT JOIN core.branches AS operating_branches
          ON operating_branches.company_id = companies.company_id
         AND operating_branches.branch_code = profiles.operating_branch_code
        LEFT JOIN core.departments AS finance_departments
          ON finance_departments.company_id = companies.company_id
         AND finance_departments.department_code = profiles.finance_department_code
        LEFT JOIN core.departments AS operating_departments
          ON operating_departments.company_id = companies.company_id
         AND operating_departments.department_code = profiles.operating_department_code
        WHERE headquarters.branch_id IS NULL
           OR operating_branches.branch_id IS NULL
           OR finance_departments.department_id IS NULL
           OR operating_departments.department_id IS NULL
    ) THEN
        RAISE EXCEPTION
            '06_documents.sql could not resolve one or more required branches or departments. Run the current 02_organizations.sql first.';
    END IF;

    IF EXISTS (
        SELECT 1
        FROM fixture_document_profiles AS profiles
        JOIN core.companies AS companies
          ON companies.company_slug = profiles.company_slug
        WHERE NOT EXISTS (
            SELECT 1
            FROM finance.financial_transactions AS transactions
            WHERE transactions.company_id = companies.company_id
              AND transactions.status = 'posted'
        )
    ) THEN
        RAISE EXCEPTION
            '06_documents.sql requires at least one posted financial transaction for every fixture company. Run 05_finance.sql first.';
    END IF;
END;
$$;

-- ============================================================
-- Additional generic document types
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
        'corporate_record',
        'Corporate Record',
        'Foundational governance, registration, or corporate administration record.',
        120,
        FALSE,
        TRUE
    ),
    (
        'employee_handbook',
        'Employee Handbook',
        'Controlled handbook containing company-wide employment and workplace guidance.',
        84,
        FALSE,
        TRUE
    ),
    (
        'security_policy',
        'Information Security Policy',
        'Controlled policy for information security, acceptable use, and data protection.',
        84,
        FALSE,
        TRUE
    ),
    (
        'operating_procedure',
        'Standard Operating Procedure',
        'Controlled procedure describing repeatable operational activities and responsibilities.',
        84,
        FALSE,
        TRUE
    ),
    (
        'customer_agreement',
        'Customer Agreement',
        'Commercial agreement governing services or products supplied to a customer.',
        84,
        FALSE,
        TRUE
    ),
    (
        'supplier_agreement',
        'Supplier Agreement',
        'Commercial agreement governing products or services obtained from a supplier.',
        84,
        FALSE,
        TRUE
    ),
    (
        'financial_statement',
        'Financial Statement',
        'Periodic financial statement or controlled year-end financial reporting package.',
        120,
        FALSE,
        TRUE
    ),
    (
        'insurance_certificate',
        'Insurance Certificate',
        'Certificate evidencing active insurance coverage for a defined period.',
        84,
        TRUE,
        TRUE
    )
ON CONFLICT (type_key) DO UPDATE
SET
    type_name = EXCLUDED.type_name,
    description = EXCLUDED.description,
    default_retention_months = EXCLUDED.default_retention_months,
    requires_expiration_date = EXCLUDED.requires_expiration_date,
    is_active = EXCLUDED.is_active;

-- ============================================================
-- Fixture document specifications
-- ============================================================

CREATE TEMP TABLE fixture_documents
ON COMMIT DROP
AS
SELECT
    profiles.company_slug,
    profiles.document_prefix,
    profiles.company_label,
    profiles.business_domain,
    profiles.creator_person_external_reference,
    profiles.reference_date,
    specifications.document_code,
    profiles.document_prefix || '-DOC-' || specifications.document_code AS document_number,
    specifications.type_key,
    specifications.document_title,
    specifications.document_status,
    specifications.confidentiality_level,
    specifications.issue_date,
    specifications.effective_date,
    specifications.expiration_date,
    specifications.final_status_date,
    specifications.owner_person_external_reference,
    specifications.branch_code,
    specifications.department_code,
    specifications.version_count,
    specifications.mime_type,
    specifications.file_extension,
    specifications.notes
FROM fixture_document_profiles AS profiles
CROSS JOIN LATERAL (
    VALUES
        (
            'CORP-REG-001',
            'corporate_record',
            profiles.company_label || ' corporate registration and governance record',
            CASE WHEN profiles.archival_date IS NULL THEN 'active' ELSE 'archived' END,
            'confidential',
            profiles.reference_date - 730,
            profiles.reference_date - 730,
            NULL::DATE,
            COALESCE(profiles.archival_date, profiles.reference_date - 730),
            profiles.owner_person_external_reference,
            profiles.headquarters_branch_code,
            NULL::TEXT,
            2,
            'application/pdf',
            'pdf',
            'Controlled corporate record for ' || profiles.company_label || '.'
        ),
        (
            'HR-HBK-2025',
            'employee_handbook',
            profiles.company_label || ' employee handbook',
            CASE WHEN profiles.archival_date IS NULL THEN 'active' ELSE 'archived' END,
            'internal',
            profiles.reference_date - 210,
            profiles.reference_date - 180,
            NULL::DATE,
            COALESCE(profiles.archival_date, profiles.reference_date - 180),
            profiles.owner_person_external_reference,
            profiles.headquarters_branch_code,
            profiles.operating_department_code,
            3,
            'application/pdf',
            'pdf',
            'Current workplace handbook covering conduct, leave, safety, and employee responsibilities.'
        ),
        (
            'IT-SEC-2025',
            'security_policy',
            profiles.company_label || ' information security and acceptable-use policy',
            CASE WHEN profiles.archival_date IS NULL THEN 'active' ELSE 'archived' END,
            'restricted',
            profiles.reference_date - 165,
            profiles.reference_date - 150,
            NULL::DATE,
            COALESCE(profiles.archival_date, profiles.reference_date - 150),
            profiles.owner_person_external_reference,
            profiles.headquarters_branch_code,
            profiles.operating_department_code,
            2,
            'application/pdf',
            'pdf',
            'Security policy tailored to ' || profiles.business_domain || '.'
        ),
        (
            'OPS-SOP-001',
            'operating_procedure',
            profiles.company_label || ' primary operating procedure',
            CASE WHEN profiles.archival_date IS NULL THEN 'active' ELSE 'archived' END,
            'internal',
            profiles.reference_date - 135,
            profiles.reference_date - 120,
            NULL::DATE,
            COALESCE(profiles.archival_date, profiles.reference_date - 120),
            profiles.owner_person_external_reference,
            profiles.operating_branch_code,
            profiles.operating_department_code,
            3,
            'application/pdf',
            'pdf',
            'Controlled procedure for the principal workflow in ' || profiles.business_domain || '.'
        ),
        (
            'CTR-CUST-2025',
            'customer_agreement',
            profiles.company_label || ' master customer services agreement',
            CASE WHEN profiles.archival_date IS NULL THEN 'active' ELSE 'archived' END,
            'confidential',
            profiles.reference_date - 110,
            profiles.reference_date - 100,
            CASE
                WHEN profiles.archival_date IS NULL THEN profiles.reference_date + 630
                ELSE profiles.archival_date
            END,
            COALESCE(profiles.archival_date, profiles.reference_date - 100),
            profiles.owner_person_external_reference,
            profiles.operating_branch_code,
            profiles.operating_department_code,
            2,
            'application/pdf',
            'pdf',
            'Synthetic master commercial agreement used to demonstrate contract metadata and versioning.'
        ),
        (
            'CTR-SUP-2025',
            'supplier_agreement',
            profiles.company_label || ' strategic supplier framework agreement',
            CASE WHEN profiles.archival_date IS NULL THEN 'active' ELSE 'archived' END,
            'confidential',
            profiles.reference_date - 95,
            profiles.reference_date - 90,
            CASE
                WHEN profiles.archival_date IS NULL THEN profiles.reference_date + 545
                ELSE profiles.archival_date
            END,
            COALESCE(profiles.archival_date, profiles.reference_date - 90),
            profiles.owner_person_external_reference,
            profiles.operating_branch_code,
            profiles.operating_department_code,
            2,
            'application/pdf',
            'pdf',
            'Synthetic supplier agreement supporting procurement and vendor-management scenarios.'
        ),
        (
            'FIN-AR-2025',
            'financial_statement',
            profiles.company_label || ' annual financial reporting package',
            CASE WHEN profiles.archival_date IS NULL THEN 'active' ELSE 'archived' END,
            'restricted',
            profiles.reference_date - 75,
            profiles.reference_date - 75,
            NULL::DATE,
            COALESCE(profiles.archival_date, profiles.reference_date - 75),
            profiles.owner_person_external_reference,
            profiles.headquarters_branch_code,
            profiles.finance_department_code,
            1,
            'application/pdf',
            'pdf',
            'Synthetic annual financial reporting package linked to representative ledger activity.'
        ),
        (
            'FIN-MR-' || TO_CHAR(profiles.reference_date, 'YYYY-MM'),
            'report',
            profiles.company_label || ' monthly management report for ' || TO_CHAR(profiles.reference_date, 'Mon YYYY'),
            CASE WHEN profiles.archival_date IS NULL THEN 'active' ELSE 'archived' END,
            'confidential',
            profiles.reference_date,
            profiles.reference_date,
            NULL::DATE,
            COALESCE(profiles.archival_date, profiles.reference_date),
            profiles.owner_person_external_reference,
            profiles.headquarters_branch_code,
            profiles.finance_department_code,
            1,
            'application/pdf',
            'pdf',
            'Management reporting package containing synthetic operational and financial indicators.'
        ),
        (
            'TAX-' || TO_CHAR(profiles.reference_date, 'YYYY'),
            'tax_document',
            profiles.company_label || ' annual tax compliance file for ' || TO_CHAR(profiles.reference_date, 'YYYY'),
            CASE WHEN profiles.archival_date IS NULL THEN 'active' ELSE 'archived' END,
            'restricted',
            profiles.reference_date - 30,
            profiles.reference_date - 30,
            NULL::DATE,
            COALESCE(profiles.archival_date, profiles.reference_date - 30),
            profiles.owner_person_external_reference,
            profiles.headquarters_branch_code,
            profiles.finance_department_code,
            1,
            'application/pdf',
            'pdf',
            'Synthetic tax and compliance support file. It is not a real filing or government document.'
        ),
        (
            'INS-' || TO_CHAR(profiles.reference_date, 'YYYY'),
            'insurance_certificate',
            profiles.company_label || ' commercial insurance certificate',
            CASE WHEN profiles.archival_date IS NULL THEN 'active' ELSE 'expired' END,
            'confidential',
            profiles.reference_date - 20,
            profiles.reference_date - 20,
            CASE
                WHEN profiles.archival_date IS NULL THEN profiles.reference_date + 345
                ELSE profiles.archival_date - 1
            END,
            CASE
                WHEN profiles.archival_date IS NULL THEN profiles.reference_date - 20
                ELSE profiles.archival_date
            END,
            profiles.owner_person_external_reference,
            profiles.headquarters_branch_code,
            profiles.operating_department_code,
            1,
            'application/pdf',
            'pdf',
            'Synthetic certificate demonstrating expiration tracking for time-bound documents.'
        ),
        (
            'INV-' || TO_CHAR(profiles.reference_date, 'YYYY') || '-001',
            'invoice',
            profiles.company_label || ' representative customer invoice',
            CASE WHEN profiles.archival_date IS NULL THEN 'active' ELSE 'archived' END,
            'confidential',
            profiles.reference_date - 12,
            profiles.reference_date - 12,
            NULL::DATE,
            COALESCE(profiles.archival_date, profiles.reference_date - 12),
            profiles.owner_person_external_reference,
            profiles.operating_branch_code,
            profiles.operating_department_code,
            1,
            'application/pdf',
            'pdf',
            'Synthetic invoice metadata linked to representative posted financial activity.'
        ),
        (
            'RCP-' || TO_CHAR(profiles.reference_date, 'YYYY') || '-001',
            'receipt',
            profiles.company_label || ' representative payment receipt',
            CASE WHEN profiles.archival_date IS NULL THEN 'active' ELSE 'archived' END,
            'confidential',
            profiles.reference_date - 8,
            profiles.reference_date - 8,
            NULL::DATE,
            COALESCE(profiles.archival_date, profiles.reference_date - 8),
            profiles.owner_person_external_reference,
            profiles.operating_branch_code,
            profiles.finance_department_code,
            1,
            'application/pdf',
            'pdf',
            'Synthetic receipt metadata linked to representative posted financial activity.'
        ),
        (
            'ID-OWNER-001',
            'identity_document',
            profiles.company_label || ' authorized representative identity record',
            CASE WHEN profiles.archival_date IS NULL THEN 'active' ELSE 'expired' END,
            'restricted',
            profiles.reference_date - 1460,
            profiles.reference_date - 1460,
            CASE
                WHEN profiles.archival_date IS NULL THEN profiles.reference_date + 900
                ELSE profiles.archival_date - 5
            END,
            CASE
                WHEN profiles.archival_date IS NULL THEN profiles.reference_date - 1460
                ELSE profiles.archival_date
            END,
            profiles.owner_person_external_reference,
            profiles.headquarters_branch_code,
            NULL::TEXT,
            1,
            'application/pdf',
            'pdf',
            'Synthetic restricted identity-document metadata. No real identifier or file is included.'
        ),
        (
            'BCP-DRAFT-001',
            'policy',
            profiles.company_label || ' draft business continuity policy',
            CASE WHEN profiles.archival_date IS NULL THEN 'draft' ELSE 'voided' END,
            'internal',
            NULL::DATE,
            NULL::DATE,
            NULL::DATE,
            CASE
                WHEN profiles.archival_date IS NULL THEN profiles.reference_date - 5
                ELSE profiles.archival_date - 15
            END,
            profiles.owner_person_external_reference,
            profiles.headquarters_branch_code,
            profiles.operating_department_code,
            1,
            'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
            'docx',
            CASE
                WHEN profiles.archival_date IS NULL
                    THEN 'Working draft awaiting operational and legal approval.'
                ELSE 'Draft abandoned during the company wind-down process.'
            END
        ),
        (
            'INV-VOID-001',
            'invoice',
            profiles.company_label || ' voided duplicate invoice',
            'voided',
            'confidential',
            profiles.reference_date - 4,
            profiles.reference_date - 4,
            NULL::DATE,
            profiles.reference_date - 3,
            profiles.owner_person_external_reference,
            profiles.operating_branch_code,
            profiles.finance_department_code,
            1,
            'application/pdf',
            'pdf',
            'Synthetic duplicate invoice voided before it became an authoritative business record.'
        ),
        (
            'HR-HBK-2023',
            'employee_handbook',
            profiles.company_label || ' superseded employee handbook',
            'superseded',
            'internal',
            profiles.reference_date - 900,
            profiles.reference_date - 870,
            profiles.reference_date - 181,
            profiles.reference_date - 180,
            profiles.owner_person_external_reference,
            profiles.headquarters_branch_code,
            profiles.operating_department_code,
            2,
            'application/pdf',
            'pdf',
            'Historical controlled handbook retained after replacement by the current edition.'
        ),
        (
            'INS-OLD-001',
            'insurance_certificate',
            profiles.company_label || ' expired prior insurance certificate',
            'expired',
            'confidential',
            profiles.reference_date - 520,
            profiles.reference_date - 520,
            profiles.reference_date - 156,
            profiles.reference_date - 155,
            profiles.owner_person_external_reference,
            profiles.headquarters_branch_code,
            profiles.operating_department_code,
            1,
            'application/pdf',
            'pdf',
            'Historical insurance certificate retained after its coverage period ended.'
        )
) AS specifications (
    document_code,
    type_key,
    document_title,
    document_status,
    confidentiality_level,
    issue_date,
    effective_date,
    expiration_date,
    final_status_date,
    owner_person_external_reference,
    branch_code,
    department_code,
    version_count,
    mime_type,
    file_extension,
    notes
);

CREATE UNIQUE INDEX fixture_documents_company_number_idx
    ON fixture_documents (company_slug, document_number);

-- ============================================================
-- Fixture specification validation
-- ============================================================

DO $$
DECLARE
    expected_documents INTEGER;
BEGIN
    SELECT COUNT(*)
    INTO expected_documents
    FROM fixture_documents;

    IF expected_documents <> 102 THEN
        RAISE EXCEPTION
            '06_documents.sql expected 102 document specifications but generated %.',
            expected_documents;
    END IF;

    IF EXISTS (
        SELECT 1
        FROM fixture_documents AS fixture
        LEFT JOIN documents.document_types AS document_types
          ON document_types.type_key = fixture.type_key
        WHERE document_types.document_type_id IS NULL
    ) THEN
        RAISE EXCEPTION
            '06_documents.sql could not resolve one or more required document types.';
    END IF;

    IF EXISTS (
        SELECT 1
        FROM fixture_documents AS fixture
        JOIN documents.document_types AS document_types
          ON document_types.type_key = fixture.type_key
        WHERE document_types.requires_expiration_date
          AND fixture.expiration_date IS NULL
    ) THEN
        RAISE EXCEPTION
            '06_documents.sql generated a document without the expiration date required by its type.';
    END IF;

    IF EXISTS (
        SELECT 1
        FROM fixture_documents
        WHERE version_count < 1
    ) THEN
        RAISE EXCEPTION
            '06_documents.sql generated a document without at least one version.';
    END IF;
END;
$$;

-- ============================================================
-- Deterministic cleanup of fixture-owned document records
-- ============================================================

DELETE FROM documents.document_records AS document_records
USING fixture_documents AS fixture,
      core.companies AS companies
WHERE companies.company_slug = fixture.company_slug
  AND document_records.company_id = companies.company_id
  AND document_records.document_number = fixture.document_number;

-- ============================================================
-- Document records
-- ============================================================

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
    created_by_account_id,
    notes,
    created_at,
    updated_at
)
SELECT
    companies.company_id,
    document_types.document_type_id,
    fixture.document_title,
    fixture.document_number,
    fixture.document_status,
    fixture.confidentiality_level,
    fixture.issue_date,
    fixture.effective_date,
    fixture.expiration_date,
    owners.person_id,
    creator_accounts.account_id,
    fixture.notes,
    (
        (COALESCE(fixture.issue_date, fixture.effective_date, fixture.reference_date) - 20)::TIMESTAMP
        + TIME '09:00'
    ) AT TIME ZONE 'UTC',
    (
        COALESCE(
            fixture.final_status_date,
            fixture.effective_date,
            fixture.issue_date,
            fixture.reference_date
        )::TIMESTAMP
        + TIME '17:00'
    ) AT TIME ZONE 'UTC'
FROM fixture_documents AS fixture
JOIN core.companies AS companies
  ON companies.company_slug = fixture.company_slug
JOIN documents.document_types AS document_types
  ON document_types.type_key = fixture.type_key
JOIN people.persons AS owners
  ON owners.company_id = companies.company_id
 AND owners.external_reference = fixture.owner_person_external_reference
JOIN people.persons AS creators
  ON creators.company_id = companies.company_id
 AND creators.external_reference = fixture.creator_person_external_reference
LEFT JOIN identity.user_accounts AS creator_accounts
  ON creator_accounts.person_id = creators.person_id;

-- ============================================================
-- Document versions
-- ============================================================

INSERT INTO documents.document_versions (
    document_id,
    version_number,
    storage_uri,
    mime_type,
    file_size_bytes,
    content_hash,
    is_current,
    uploaded_by_account_id,
    uploaded_at,
    change_summary,
    created_at
)
SELECT
    document_records.document_id,
    generated_versions.version_number,
    's3://business-core-fixture/'
        || fixture.company_slug
        || '/documents/'
        || LOWER(REPLACE(fixture.document_number, '-', '_'))
        || '/v'
        || generated_versions.version_number
        || '/'
        || LOWER(REPLACE(fixture.document_code, '-', '_'))
        || '.'
        || fixture.file_extension,
    fixture.mime_type,
    (
        85000
        + LENGTH(fixture.document_title) * 700
        + generated_versions.version_number * 9000
    )::BIGINT,
    'md5:' || MD5(
        fixture.company_slug
        || ':'
        || fixture.document_number
        || ':'
        || generated_versions.version_number::TEXT
        || ':synthetic-fixture-content'
    ),
    generated_versions.version_number = fixture.version_count,
    creator_accounts.account_id,
    document_records.created_at
        + MAKE_INTERVAL(days => generated_versions.version_number * 7),
    CASE generated_versions.version_number
        WHEN 1 THEN
            CASE
                WHEN fixture.version_count = 1 THEN 'Initial approved fixture version.'
                ELSE 'Initial controlled draft.'
            END
        WHEN 2 THEN 'Operational, legal, and formatting review incorporated.'
        ELSE 'Approved release with updated responsibilities and control metadata.'
    END,
    document_records.created_at
        + MAKE_INTERVAL(days => generated_versions.version_number * 7)
FROM fixture_documents AS fixture
JOIN core.companies AS companies
  ON companies.company_slug = fixture.company_slug
JOIN documents.document_records AS document_records
  ON document_records.company_id = companies.company_id
 AND document_records.document_number = fixture.document_number
JOIN people.persons AS creators
  ON creators.company_id = companies.company_id
 AND creators.external_reference = fixture.creator_person_external_reference
LEFT JOIN identity.user_accounts AS creator_accounts
  ON creator_accounts.person_id = creators.person_id
CROSS JOIN LATERAL GENERATE_SERIES(1, fixture.version_count)
    AS generated_versions(version_number);

-- ============================================================
-- Document links: company ownership
-- ============================================================

INSERT INTO documents.document_links (
    company_id,
    document_id,
    linked_entity_schema,
    linked_entity_table,
    linked_entity_id,
    link_type,
    linked_by_account_id,
    linked_at,
    notes
)
SELECT
    companies.company_id,
    document_records.document_id,
    'core',
    'companies',
    companies.company_id,
    'owner',
    creator_accounts.account_id,
    document_records.created_at,
    'Owning company for this fixture document.'
FROM fixture_documents AS fixture
JOIN core.companies AS companies
  ON companies.company_slug = fixture.company_slug
JOIN documents.document_records AS document_records
  ON document_records.company_id = companies.company_id
 AND document_records.document_number = fixture.document_number
JOIN people.persons AS creators
  ON creators.company_id = companies.company_id
 AND creators.external_reference = fixture.creator_person_external_reference
LEFT JOIN identity.user_accounts AS creator_accounts
  ON creator_accounts.person_id = creators.person_id;

-- ============================================================
-- Document links: responsible or subject person
-- ============================================================

INSERT INTO documents.document_links (
    company_id,
    document_id,
    linked_entity_schema,
    linked_entity_table,
    linked_entity_id,
    link_type,
    linked_by_account_id,
    linked_at,
    notes
)
SELECT
    companies.company_id,
    document_records.document_id,
    'people',
    'persons',
    owners.person_id,
    'subject',
    creator_accounts.account_id,
    document_records.created_at,
    'Responsible person or document subject resolved through a stable external reference.'
FROM fixture_documents AS fixture
JOIN core.companies AS companies
  ON companies.company_slug = fixture.company_slug
JOIN documents.document_records AS document_records
  ON document_records.company_id = companies.company_id
 AND document_records.document_number = fixture.document_number
JOIN people.persons AS owners
  ON owners.company_id = companies.company_id
 AND owners.external_reference = fixture.owner_person_external_reference
JOIN people.persons AS creators
  ON creators.company_id = companies.company_id
 AND creators.external_reference = fixture.creator_person_external_reference
LEFT JOIN identity.user_accounts AS creator_accounts
  ON creator_accounts.person_id = creators.person_id;

-- ============================================================
-- Document links: branch context
-- ============================================================

INSERT INTO documents.document_links (
    company_id,
    document_id,
    linked_entity_schema,
    linked_entity_table,
    linked_entity_id,
    link_type,
    linked_by_account_id,
    linked_at,
    notes
)
SELECT
    companies.company_id,
    document_records.document_id,
    'core',
    'branches',
    branches.branch_id,
    'related',
    creator_accounts.account_id,
    document_records.created_at,
    'Primary branch context for this document.'
FROM fixture_documents AS fixture
JOIN core.companies AS companies
  ON companies.company_slug = fixture.company_slug
JOIN documents.document_records AS document_records
  ON document_records.company_id = companies.company_id
 AND document_records.document_number = fixture.document_number
JOIN core.branches AS branches
  ON branches.company_id = companies.company_id
 AND branches.branch_code = fixture.branch_code
JOIN people.persons AS creators
  ON creators.company_id = companies.company_id
 AND creators.external_reference = fixture.creator_person_external_reference
LEFT JOIN identity.user_accounts AS creator_accounts
  ON creator_accounts.person_id = creators.person_id
WHERE fixture.branch_code IS NOT NULL;

-- ============================================================
-- Document links: department context
-- ============================================================

INSERT INTO documents.document_links (
    company_id,
    document_id,
    linked_entity_schema,
    linked_entity_table,
    linked_entity_id,
    link_type,
    linked_by_account_id,
    linked_at,
    notes
)
SELECT
    companies.company_id,
    document_records.document_id,
    'core',
    'departments',
    departments.department_id,
    'related',
    creator_accounts.account_id,
    document_records.created_at,
    'Primary department context for this document.'
FROM fixture_documents AS fixture
JOIN core.companies AS companies
  ON companies.company_slug = fixture.company_slug
JOIN documents.document_records AS document_records
  ON document_records.company_id = companies.company_id
 AND document_records.document_number = fixture.document_number
JOIN core.departments AS departments
  ON departments.company_id = companies.company_id
 AND departments.department_code = fixture.department_code
JOIN people.persons AS creators
  ON creators.company_id = companies.company_id
 AND creators.external_reference = fixture.creator_person_external_reference
LEFT JOIN identity.user_accounts AS creator_accounts
  ON creator_accounts.person_id = creators.person_id
WHERE fixture.department_code IS NOT NULL;

-- ============================================================
-- Document links: representative financial transactions
-- ============================================================

INSERT INTO documents.document_links (
    company_id,
    document_id,
    linked_entity_schema,
    linked_entity_table,
    linked_entity_id,
    link_type,
    linked_by_account_id,
    linked_at,
    notes
)
SELECT
    companies.company_id,
    document_records.document_id,
    'finance',
    'financial_transactions',
    representative_transactions.transaction_id,
    CASE
        WHEN fixture.type_key IN ('invoice', 'receipt') THEN 'generated_from'
        ELSE 'supporting'
    END,
    creator_accounts.account_id,
    document_records.created_at,
    'Representative cross-domain link to posted financial activity created by 05_finance.sql.'
FROM fixture_documents AS fixture
JOIN core.companies AS companies
  ON companies.company_slug = fixture.company_slug
JOIN documents.document_records AS document_records
  ON document_records.company_id = companies.company_id
 AND document_records.document_number = fixture.document_number
JOIN people.persons AS creators
  ON creators.company_id = companies.company_id
 AND creators.external_reference = fixture.creator_person_external_reference
LEFT JOIN identity.user_accounts AS creator_accounts
  ON creator_accounts.person_id = creators.person_id
CROSS JOIN LATERAL (
    SELECT transactions.transaction_id
    FROM finance.financial_transactions AS transactions
    WHERE transactions.company_id = companies.company_id
      AND transactions.status = 'posted'
    ORDER BY
        ABS(
            transactions.transaction_date
            - COALESCE(fixture.issue_date, fixture.reference_date)
        ),
        transactions.transaction_id
    LIMIT 1
) AS representative_transactions
WHERE fixture.type_key IN (
        'financial_statement',
        'report',
        'tax_document',
        'invoice',
        'receipt'
    )
  AND fixture.document_status NOT IN ('draft', 'voided');

-- ============================================================
-- Document status history
-- ============================================================

-- Every document starts in draft status.
INSERT INTO documents.document_status_history (
    document_id,
    previous_status,
    new_status,
    changed_by_account_id,
    changed_at,
    change_reason
)
SELECT
    document_records.document_id,
    NULL,
    'draft',
    creator_accounts.account_id,
    document_records.created_at,
    'Initial fixture document record created.'
FROM fixture_documents AS fixture
JOIN core.companies AS companies
  ON companies.company_slug = fixture.company_slug
JOIN documents.document_records AS document_records
  ON document_records.company_id = companies.company_id
 AND document_records.document_number = fixture.document_number
JOIN people.persons AS creators
  ON creators.company_id = companies.company_id
 AND creators.external_reference = fixture.creator_person_external_reference
LEFT JOIN identity.user_accounts AS creator_accounts
  ON creator_accounts.person_id = creators.person_id;

-- Documents that entered controlled use move from draft to active.
INSERT INTO documents.document_status_history (
    document_id,
    previous_status,
    new_status,
    changed_by_account_id,
    changed_at,
    change_reason
)
SELECT
    document_records.document_id,
    'draft',
    'active',
    creator_accounts.account_id,
    (
        COALESCE(fixture.effective_date, fixture.issue_date, fixture.reference_date)::TIMESTAMP
        + TIME '09:30'
    ) AT TIME ZONE 'UTC',
    'Document reviewed, approved, and released for controlled use.'
FROM fixture_documents AS fixture
JOIN core.companies AS companies
  ON companies.company_slug = fixture.company_slug
JOIN documents.document_records AS document_records
  ON document_records.company_id = companies.company_id
 AND document_records.document_number = fixture.document_number
JOIN people.persons AS creators
  ON creators.company_id = companies.company_id
 AND creators.external_reference = fixture.creator_person_external_reference
LEFT JOIN identity.user_accounts AS creator_accounts
  ON creator_accounts.person_id = creators.person_id
WHERE fixture.document_status IN (
    'active',
    'superseded',
    'expired',
    'archived'
);

-- Final transitions from active to a terminal or historical state.
INSERT INTO documents.document_status_history (
    document_id,
    previous_status,
    new_status,
    changed_by_account_id,
    changed_at,
    change_reason
)
SELECT
    document_records.document_id,
    'active',
    fixture.document_status,
    creator_accounts.account_id,
    (
        fixture.final_status_date::TIMESTAMP
        + TIME '17:00'
    ) AT TIME ZONE 'UTC',
    CASE fixture.document_status
        WHEN 'superseded' THEN 'Replaced by a newer controlled document.'
        WHEN 'expired' THEN 'Document validity or coverage period ended.'
        WHEN 'archived' THEN 'Retained as a historical record after organizational closure or wind-down.'
    END
FROM fixture_documents AS fixture
JOIN core.companies AS companies
  ON companies.company_slug = fixture.company_slug
JOIN documents.document_records AS document_records
  ON document_records.company_id = companies.company_id
 AND document_records.document_number = fixture.document_number
JOIN people.persons AS creators
  ON creators.company_id = companies.company_id
 AND creators.external_reference = fixture.creator_person_external_reference
LEFT JOIN identity.user_accounts AS creator_accounts
  ON creator_accounts.person_id = creators.person_id
WHERE fixture.document_status IN (
    'superseded',
    'expired',
    'archived'
);

-- Voided documents move directly from draft to voided.
INSERT INTO documents.document_status_history (
    document_id,
    previous_status,
    new_status,
    changed_by_account_id,
    changed_at,
    change_reason
)
SELECT
    document_records.document_id,
    'draft',
    'voided',
    creator_accounts.account_id,
    (
        fixture.final_status_date::TIMESTAMP
        + TIME '16:00'
    ) AT TIME ZONE 'UTC',
    CASE
        WHEN fixture.type_key = 'invoice'
            THEN 'Duplicate invoice identified before release and intentionally voided.'
        ELSE 'Draft abandoned before approval and retained only for traceability.'
    END
FROM fixture_documents AS fixture
JOIN core.companies AS companies
  ON companies.company_slug = fixture.company_slug
JOIN documents.document_records AS document_records
  ON document_records.company_id = companies.company_id
 AND document_records.document_number = fixture.document_number
JOIN people.persons AS creators
  ON creators.company_id = companies.company_id
 AND creators.external_reference = fixture.creator_person_external_reference
LEFT JOIN identity.user_accounts AS creator_accounts
  ON creator_accounts.person_id = creators.person_id
WHERE fixture.document_status = 'voided';

-- ============================================================
-- Post-load validation
-- ============================================================

DO $$
DECLARE
    expected_document_count INTEGER;
    actual_document_count INTEGER;
    expected_version_count INTEGER;
    actual_version_count INTEGER;
BEGIN
    SELECT COUNT(*)
    INTO expected_document_count
    FROM fixture_documents;

    SELECT COUNT(*)
    INTO actual_document_count
    FROM fixture_documents AS fixture
    JOIN core.companies AS companies
      ON companies.company_slug = fixture.company_slug
    JOIN documents.document_records AS document_records
      ON document_records.company_id = companies.company_id
     AND document_records.document_number = fixture.document_number;

    IF actual_document_count <> expected_document_count THEN
        RAISE EXCEPTION
            '06_documents.sql loaded % document records; expected %.',
            actual_document_count,
            expected_document_count;
    END IF;

    SELECT SUM(version_count)
    INTO expected_version_count
    FROM fixture_documents;

    SELECT COUNT(*)
    INTO actual_version_count
    FROM fixture_documents AS fixture
    JOIN core.companies AS companies
      ON companies.company_slug = fixture.company_slug
    JOIN documents.document_records AS document_records
      ON document_records.company_id = companies.company_id
     AND document_records.document_number = fixture.document_number
    JOIN documents.document_versions AS document_versions
      ON document_versions.document_id = document_records.document_id;

    IF actual_version_count <> expected_version_count THEN
        RAISE EXCEPTION
            '06_documents.sql loaded % document versions; expected %.',
            actual_version_count,
            expected_version_count;
    END IF;

    IF EXISTS (
        SELECT 1
        FROM fixture_documents AS fixture
        JOIN core.companies AS companies
          ON companies.company_slug = fixture.company_slug
        JOIN documents.document_records AS document_records
          ON document_records.company_id = companies.company_id
         AND document_records.document_number = fixture.document_number
        LEFT JOIN documents.document_versions AS current_versions
          ON current_versions.document_id = document_records.document_id
         AND current_versions.is_current
        GROUP BY document_records.document_id
        HAVING COUNT(current_versions.document_version_id) <> 1
    ) THEN
        RAISE EXCEPTION
            '06_documents.sql expected exactly one current version for every fixture document.';
    END IF;

    IF EXISTS (
        SELECT 1
        FROM fixture_documents AS fixture
        JOIN core.companies AS companies
          ON companies.company_slug = fixture.company_slug
        JOIN documents.document_records AS document_records
          ON document_records.company_id = companies.company_id
         AND document_records.document_number = fixture.document_number
        LEFT JOIN LATERAL (
            SELECT status_history.new_status
            FROM documents.document_status_history AS status_history
            WHERE status_history.document_id = document_records.document_id
            ORDER BY
                status_history.changed_at DESC,
                status_history.document_status_history_id DESC
            LIMIT 1
        ) AS latest_status
          ON TRUE
        WHERE latest_status.new_status IS DISTINCT FROM document_records.document_status
    ) THEN
        RAISE EXCEPTION
            '06_documents.sql found a document whose latest status-history entry does not match its current status.';
    END IF;

    IF EXISTS (
        SELECT 1
        FROM fixture_documents AS fixture
        JOIN core.companies AS companies
          ON companies.company_slug = fixture.company_slug
        JOIN documents.document_records AS document_records
          ON document_records.company_id = companies.company_id
         AND document_records.document_number = fixture.document_number
        WHERE NOT EXISTS (
            SELECT 1
            FROM documents.document_links AS document_links
            WHERE document_links.document_id = document_records.document_id
              AND document_links.linked_entity_schema = 'core'
              AND document_links.linked_entity_table = 'companies'
              AND document_links.linked_entity_id = companies.company_id
              AND document_links.link_type = 'owner'
        )
    ) THEN
        RAISE EXCEPTION
            '06_documents.sql found a fixture document without its owning-company link.';
    END IF;
END;
$$;

COMMIT;

\echo '06_documents.sql completed successfully.'