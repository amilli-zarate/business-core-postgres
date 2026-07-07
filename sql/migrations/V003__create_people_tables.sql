BEGIN;

-- ============================================================
-- Persons
-- ============================================================
-- Stores natural persons known by a company.
-- A person is role-neutral: they may later become an employee,
-- customer contact, supplier contact, system user, contractor, etc.
-- ============================================================

CREATE TABLE people.persons (
    person_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,

    company_id BIGINT NOT NULL
        REFERENCES core.companies(company_id),

    external_reference TEXT,

    display_name TEXT NOT NULL,

    given_name TEXT,
    middle_name TEXT,
    family_name TEXT,
    additional_family_name TEXT,

    person_status TEXT NOT NULL DEFAULT 'active',

    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),

    CONSTRAINT persons_unique_id_per_company
        UNIQUE (company_id, person_id),

    CONSTRAINT persons_unique_external_reference_per_company
        UNIQUE (company_id, external_reference),

    CONSTRAINT persons_display_name_not_empty
        CHECK (length(trim(display_name)) > 0),

    CONSTRAINT persons_external_reference_not_empty
        CHECK (
            external_reference IS NULL
            OR length(trim(external_reference)) > 0
        ),

    CONSTRAINT persons_given_name_not_empty
        CHECK (
            given_name IS NULL
            OR length(trim(given_name)) > 0
        ),

    CONSTRAINT persons_middle_name_not_empty
        CHECK (
            middle_name IS NULL
            OR length(trim(middle_name)) > 0
        ),

    CONSTRAINT persons_family_name_not_empty
        CHECK (
            family_name IS NULL
            OR length(trim(family_name)) > 0
        ),

    CONSTRAINT persons_additional_family_name_not_empty
        CHECK (
            additional_family_name IS NULL
            OR length(trim(additional_family_name)) > 0
        ),

    CONSTRAINT persons_valid_status
        CHECK (person_status IN (
            'active',
            'inactive',
            'archived'
        )),

    CONSTRAINT persons_updated_at_valid
        CHECK (updated_at >= created_at)
);


-- ============================================================
-- Person contact methods
-- ============================================================
-- Stores ways to contact a person: email, phone, mobile,
-- messaging app, social profile, website, etc.
-- ============================================================

CREATE TABLE people.person_contact_methods (
    contact_method_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,

    company_id BIGINT NOT NULL,
    person_id BIGINT NOT NULL,

    contact_type TEXT NOT NULL,
    contact_label TEXT,

    contact_value TEXT NOT NULL,

    is_primary BOOLEAN NOT NULL DEFAULT FALSE,
    is_verified BOOLEAN NOT NULL DEFAULT FALSE,

    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),

    CONSTRAINT person_contact_methods_unique_id_per_company
        UNIQUE (company_id, contact_method_id),

    CONSTRAINT person_contact_methods_person_belongs_to_company
        FOREIGN KEY (company_id, person_id)
        REFERENCES people.persons(company_id, person_id)
        ON DELETE CASCADE,

    CONSTRAINT person_contact_methods_valid_type
        CHECK (contact_type IN (
            'email',
            'phone',
            'mobile',
            'website',
            'messaging_app',
            'social_profile',
            'other'
        )),

    CONSTRAINT person_contact_methods_contact_label_not_empty
        CHECK (
            contact_label IS NULL
            OR length(trim(contact_label)) > 0
        ),

    CONSTRAINT person_contact_methods_contact_value_not_empty
        CHECK (length(trim(contact_value)) > 0),

    CONSTRAINT person_contact_methods_email_format
        CHECK (
            contact_type <> 'email'
            OR contact_value ~* '^[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}$'
        ),

    CONSTRAINT person_contact_methods_updated_at_valid
        CHECK (updated_at >= created_at)
);


-- ============================================================
-- Indexes
-- ============================================================

CREATE INDEX idx_persons_company_id
    ON people.persons(company_id);

CREATE INDEX idx_persons_display_name
    ON people.persons(display_name);

CREATE INDEX idx_persons_person_status
    ON people.persons(person_status);

CREATE INDEX idx_person_contact_methods_company_id
    ON people.person_contact_methods(company_id);

CREATE INDEX idx_person_contact_methods_person_id
    ON people.person_contact_methods(person_id);

CREATE INDEX idx_person_contact_methods_contact_type
    ON people.person_contact_methods(contact_type);

CREATE INDEX idx_person_contact_methods_contact_value
    ON people.person_contact_methods(contact_value);

CREATE UNIQUE INDEX idx_person_contact_methods_one_primary_per_type
    ON people.person_contact_methods(company_id, person_id, contact_type)
    WHERE is_primary = TRUE;

COMMIT;