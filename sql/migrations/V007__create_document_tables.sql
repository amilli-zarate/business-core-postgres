BEGIN;

-- ============================================================
-- V007__create_document_tables.sql
-- Business Core Postgres
--
-- Purpose:
--   Create a generic document metadata layer.
--
-- Design notes:
--   - Files are not stored as BYTEA/BLOBs.
--   - The database stores metadata, versions, storage URIs,
--     lifecycle status, and links to business entities.
--   - Actual files may live in local storage, S3, SharePoint,
--     Google Drive, etc.
-- ============================================================


-- ============================================================
-- Document types
-- ============================================================

CREATE TABLE documents.document_types (
    document_type_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,

    type_key TEXT NOT NULL UNIQUE,
    type_name TEXT NOT NULL,
    description TEXT,

    default_retention_months INTEGER,
    requires_expiration_date BOOLEAN NOT NULL DEFAULT FALSE,

    is_active BOOLEAN NOT NULL DEFAULT TRUE,

    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CONSTRAINT document_types_type_key_format_chk
        CHECK (type_key ~ '^[a-z][a-z0-9_]*$'),

    CONSTRAINT document_types_default_retention_positive_chk
        CHECK (
            default_retention_months IS NULL
            OR default_retention_months > 0
        )
);


-- ============================================================
-- Document records
-- ============================================================

CREATE TABLE documents.document_records (
    document_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,

    company_id BIGINT NOT NULL
        REFERENCES core.companies(company_id)
        ON DELETE RESTRICT,

    document_type_id BIGINT NOT NULL
        REFERENCES documents.document_types(document_type_id)
        ON DELETE RESTRICT,

    document_title TEXT NOT NULL,
    document_number TEXT,

    document_status TEXT NOT NULL DEFAULT 'draft',
    confidentiality_level TEXT NOT NULL DEFAULT 'internal',

    issue_date DATE,
    effective_date DATE,
    expiration_date DATE,

    owner_person_id BIGINT
        REFERENCES people.persons(person_id)
        ON DELETE SET NULL,

    created_by_account_id BIGINT
        REFERENCES identity.user_accounts(account_id)
        ON DELETE SET NULL,

    notes TEXT,

    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CONSTRAINT document_records_company_document_unique
        UNIQUE (document_id, company_id),

    CONSTRAINT document_records_number_unique_per_type
        UNIQUE (company_id, document_type_id, document_number),

    CONSTRAINT document_records_status_chk
        CHECK (
            document_status IN (
                'draft',
                'active',
                'superseded',
                'expired',
                'archived',
                'voided'
            )
        ),

    CONSTRAINT document_records_confidentiality_chk
        CHECK (
            confidentiality_level IN (
                'public',
                'internal',
                'confidential',
                'restricted'
            )
        ),

    CONSTRAINT document_records_document_number_not_blank_chk
        CHECK (
            document_number IS NULL
            OR LENGTH(BTRIM(document_number)) > 0
        ),

    CONSTRAINT document_records_title_not_blank_chk
        CHECK (LENGTH(BTRIM(document_title)) > 0),

    CONSTRAINT document_records_expiration_after_issue_chk
        CHECK (
            expiration_date IS NULL
            OR issue_date IS NULL
            OR expiration_date >= issue_date
        ),

    CONSTRAINT document_records_expiration_after_effective_chk
        CHECK (
            expiration_date IS NULL
            OR effective_date IS NULL
            OR expiration_date >= effective_date
        )
);


-- ============================================================
-- Document versions
-- ============================================================

CREATE TABLE documents.document_versions (
    document_version_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,

    document_id BIGINT NOT NULL
        REFERENCES documents.document_records(document_id)
        ON DELETE CASCADE,

    version_number INTEGER NOT NULL,

    storage_uri TEXT NOT NULL,
    mime_type TEXT,
    file_size_bytes BIGINT,
    content_hash TEXT,

    is_current BOOLEAN NOT NULL DEFAULT FALSE,

    uploaded_by_account_id BIGINT
        REFERENCES identity.user_accounts(account_id)
        ON DELETE SET NULL,

    uploaded_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    change_summary TEXT,

    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CONSTRAINT document_versions_unique_version
        UNIQUE (document_id, version_number),

    CONSTRAINT document_versions_version_number_positive_chk
        CHECK (version_number > 0),

    CONSTRAINT document_versions_storage_uri_not_blank_chk
        CHECK (LENGTH(BTRIM(storage_uri)) > 0),

    CONSTRAINT document_versions_file_size_nonnegative_chk
        CHECK (
            file_size_bytes IS NULL
            OR file_size_bytes >= 0
        )
);

CREATE UNIQUE INDEX document_versions_one_current_per_document_idx
    ON documents.document_versions (document_id)
    WHERE is_current;


-- ============================================================
-- Document links
--
-- This table allows documents to be linked to records from
-- different schemas without forcing every business domain to
-- know about documents directly.
--
-- linked_entity_id is expected to reference a BIGINT primary key.
-- The exact target table is represented by:
--   linked_entity_schema + linked_entity_table + linked_entity_id
-- ============================================================

CREATE TABLE documents.document_links (
    document_link_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,

    company_id BIGINT NOT NULL,

    document_id BIGINT NOT NULL,

    linked_entity_schema TEXT NOT NULL,
    linked_entity_table TEXT NOT NULL,
    linked_entity_id BIGINT NOT NULL,

    link_type TEXT NOT NULL DEFAULT 'related',

    linked_by_account_id BIGINT
        REFERENCES identity.user_accounts(account_id)
        ON DELETE SET NULL,

    linked_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    notes TEXT,

    CONSTRAINT document_links_document_company_fkey
        FOREIGN KEY (document_id, company_id)
        REFERENCES documents.document_records(document_id, company_id)
        ON DELETE CASCADE,

    CONSTRAINT document_links_unique_link
        UNIQUE (
            document_id,
            linked_entity_schema,
            linked_entity_table,
            linked_entity_id,
            link_type
        ),

    CONSTRAINT document_links_entity_schema_format_chk
        CHECK (linked_entity_schema ~ '^[a-z][a-z0-9_]*$'),

    CONSTRAINT document_links_entity_table_format_chk
        CHECK (linked_entity_table ~ '^[a-z][a-z0-9_]*$'),

    CONSTRAINT document_links_entity_id_positive_chk
        CHECK (linked_entity_id > 0),

    CONSTRAINT document_links_link_type_chk
        CHECK (
            link_type IN (
                'owner',
                'subject',
                'attachment',
                'evidence',
                'supporting',
                'generated_from',
                'related'
            )
        )
);


-- ============================================================
-- Document status history
-- ============================================================

CREATE TABLE documents.document_status_history (
    document_status_history_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,

    document_id BIGINT NOT NULL
        REFERENCES documents.document_records(document_id)
        ON DELETE CASCADE,

    previous_status TEXT,
    new_status TEXT NOT NULL,

    changed_by_account_id BIGINT
        REFERENCES identity.user_accounts(account_id)
        ON DELETE SET NULL,

    changed_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    change_reason TEXT,

    CONSTRAINT document_status_history_previous_status_chk
        CHECK (
            previous_status IS NULL
            OR previous_status IN (
                'draft',
                'active',
                'superseded',
                'expired',
                'archived',
                'voided'
            )
        ),

    CONSTRAINT document_status_history_new_status_chk
        CHECK (
            new_status IN (
                'draft',
                'active',
                'superseded',
                'expired',
                'archived',
                'voided'
            )
        ),

    CONSTRAINT document_status_history_status_changed_chk
        CHECK (
            previous_status IS NULL
            OR previous_status <> new_status
        )
);


-- ============================================================
-- Indexes
-- ============================================================

CREATE INDEX document_records_company_id_idx
    ON documents.document_records(company_id);

CREATE INDEX document_records_document_type_id_idx
    ON documents.document_records(document_type_id);

CREATE INDEX document_records_status_idx
    ON documents.document_records(document_status);

CREATE INDEX document_records_owner_person_id_idx
    ON documents.document_records(owner_person_id);

CREATE INDEX document_records_expiration_date_idx
    ON documents.document_records(expiration_date);

CREATE INDEX document_versions_document_id_idx
    ON documents.document_versions(document_id);

CREATE INDEX document_links_company_id_idx
    ON documents.document_links(company_id);

CREATE INDEX document_links_target_entity_idx
    ON documents.document_links(
        linked_entity_schema,
        linked_entity_table,
        linked_entity_id
    );

CREATE INDEX document_status_history_document_id_changed_at_idx
    ON documents.document_status_history(document_id, changed_at DESC);


-- ============================================================
-- Seed generic document types
-- ============================================================

INSERT INTO documents.document_types (
    type_key,
    type_name,
    description,
    default_retention_months,
    requires_expiration_date
)
VALUES
    (
        'general',
        'General Document',
        'Generic document without a more specific classification.',
        NULL,
        FALSE
    ),
    (
        'contract',
        'Contract',
        'Legal or commercial agreement between parties.',
        60,
        FALSE
    ),
    (
        'policy',
        'Policy',
        'Internal policy, standard, or operating rule.',
        60,
        FALSE
    ),
    (
        'report',
        'Report',
        'Analytical, operational, financial, or managerial report.',
        36,
        FALSE
    ),
    (
        'invoice',
        'Invoice',
        'Commercial or financial invoice document.',
        60,
        FALSE
    ),
    (
        'receipt',
        'Receipt',
        'Payment, purchase, or transaction receipt.',
        60,
        FALSE
    ),
    (
        'tax_document',
        'Tax Document',
        'Fiscal, tax, or compliance-related document.',
        60,
        FALSE
    ),
    (
        'identity_document',
        'Identity Document',
        'Document used to identify a person or legal entity.',
        60,
        TRUE
    )
ON CONFLICT (type_key) DO NOTHING;


-- ============================================================
-- Comments
-- ============================================================

COMMENT ON TABLE documents.document_types IS
    'Catalog of generic document types used by the business core.';

COMMENT ON TABLE documents.document_records IS
    'Company-scoped document metadata records. Actual files are represented through document_versions.';

COMMENT ON TABLE documents.document_versions IS
    'Versioned physical or external file references for each document record.';

COMMENT ON TABLE documents.document_links IS
    'Generic links between documents and business entities across schemas.';

COMMENT ON TABLE documents.document_status_history IS
    'Lifecycle status changes for document records.';

COMMENT ON COLUMN documents.document_versions.storage_uri IS
    'External location of the file, such as a local path, object storage URI, SharePoint URL, or another storage reference.';

COMMENT ON COLUMN documents.document_versions.content_hash IS
    'Optional hash used to verify file integrity or detect duplicate content.';

COMMENT ON COLUMN documents.document_links.linked_entity_schema IS
    'Schema of the linked business entity, for example core, people, finance, relationships, identity.';

COMMENT ON COLUMN documents.document_links.linked_entity_table IS
    'Table of the linked business entity.';

COMMENT ON COLUMN documents.document_links.linked_entity_id IS
    'BIGINT primary key of the linked business entity.';


COMMIT;