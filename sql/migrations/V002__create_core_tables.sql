BEGIN;

CREATE TABLE core.companies (
    company_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,

    company_slug TEXT NOT NULL,
    company_name TEXT NOT NULL,
    legal_name TEXT,
    tax_id TEXT,

    default_currency_code CHAR(3) NOT NULL DEFAULT 'MXN',
    company_status TEXT NOT NULL DEFAULT 'active',

    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),

    CONSTRAINT companies_company_slug_unique
        UNIQUE (company_slug),

    CONSTRAINT companies_company_slug_format
        CHECK (company_slug ~ '^[a-z0-9]+(-[a-z0-9]+)*$'),

    CONSTRAINT companies_company_name_not_empty
        CHECK (length(trim(company_name)) > 0),

    CONSTRAINT companies_legal_name_not_empty
        CHECK (legal_name IS NULL OR length(trim(legal_name)) > 0),

    CONSTRAINT companies_tax_id_not_empty
        CHECK (tax_id IS NULL OR length(trim(tax_id)) > 0),

    CONSTRAINT companies_currency_code_format
        CHECK (default_currency_code ~ '^[A-Z]{3}$'),

    CONSTRAINT companies_valid_status
        CHECK (company_status IN (
            'active',
            'inactive',
            'suspended',
            'archived'
        )),

    CONSTRAINT companies_updated_at_valid
        CHECK (updated_at >= created_at)
);


CREATE TABLE core.branches (
    branch_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,

    company_id BIGINT NOT NULL
        REFERENCES core.companies(company_id),

    branch_code TEXT,
    branch_name TEXT NOT NULL,
    branch_type TEXT NOT NULL DEFAULT 'office',
    branch_status TEXT NOT NULL DEFAULT 'active',

    opened_on DATE,
    closed_on DATE,

    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),

    CONSTRAINT branches_unique_id_per_company
        UNIQUE (company_id, branch_id),

    CONSTRAINT branches_unique_code_per_company
        UNIQUE (company_id, branch_code),

    CONSTRAINT branches_unique_name_per_company
        UNIQUE (company_id, branch_name),

    CONSTRAINT branches_branch_name_not_empty
        CHECK (length(trim(branch_name)) > 0),

    CONSTRAINT branches_branch_code_not_empty
        CHECK (branch_code IS NULL OR length(trim(branch_code)) > 0),

    CONSTRAINT branches_valid_type
        CHECK (branch_type IN (
            'headquarters',
            'office',
            'store',
            'warehouse',
            'plant',
            'remote',
            'other'
        )),

    CONSTRAINT branches_valid_status
        CHECK (branch_status IN (
            'active',
            'inactive',
            'closed',
            'archived'
        )),

    CONSTRAINT branches_dates_valid
        CHECK (closed_on IS NULL OR opened_on IS NULL OR closed_on >= opened_on),

    CONSTRAINT branches_updated_at_valid
        CHECK (updated_at >= created_at)
);


CREATE TABLE core.departments (
    department_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,

    company_id BIGINT NOT NULL
        REFERENCES core.companies(company_id),

    branch_id BIGINT,
    parent_department_id BIGINT,

    department_code TEXT,
    department_name TEXT NOT NULL,
    department_status TEXT NOT NULL DEFAULT 'active',

    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),

    CONSTRAINT departments_unique_id_per_company
        UNIQUE (company_id, department_id),

    CONSTRAINT departments_unique_code_per_company
        UNIQUE (company_id, department_code),

    CONSTRAINT departments_branch_belongs_to_company
        FOREIGN KEY (company_id, branch_id)
        REFERENCES core.branches(company_id, branch_id),

    CONSTRAINT departments_parent_belongs_to_company
        FOREIGN KEY (company_id, parent_department_id)
        REFERENCES core.departments(company_id, department_id),

    CONSTRAINT departments_not_own_parent
        CHECK (parent_department_id IS NULL OR parent_department_id <> department_id),

    CONSTRAINT departments_department_name_not_empty
        CHECK (length(trim(department_name)) > 0),

    CONSTRAINT departments_department_code_not_empty
        CHECK (department_code IS NULL OR length(trim(department_code)) > 0),

    CONSTRAINT departments_valid_status
        CHECK (department_status IN (
            'active',
            'inactive',
            'archived'
        )),

    CONSTRAINT departments_updated_at_valid
        CHECK (updated_at >= created_at)
);


CREATE TABLE core.addresses (
    address_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,

    company_id BIGINT NOT NULL
        REFERENCES core.companies(company_id),

    branch_id BIGINT,

    address_label TEXT,
    address_type TEXT NOT NULL DEFAULT 'general',

    address_line_1 TEXT NOT NULL,
    address_line_2 TEXT,

    city TEXT NOT NULL,
    state_region TEXT,
    postal_code TEXT,
    country_code CHAR(2) NOT NULL DEFAULT 'MX',

    latitude NUMERIC(9, 6),
    longitude NUMERIC(9, 6),

    is_primary BOOLEAN NOT NULL DEFAULT FALSE,

    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),

    CONSTRAINT addresses_unique_id_per_company
        UNIQUE (company_id, address_id),

    CONSTRAINT addresses_branch_belongs_to_company
        FOREIGN KEY (company_id, branch_id)
        REFERENCES core.branches(company_id, branch_id),

    CONSTRAINT addresses_address_line_1_not_empty
        CHECK (length(trim(address_line_1)) > 0),

    CONSTRAINT addresses_city_not_empty
        CHECK (length(trim(city)) > 0),

    CONSTRAINT addresses_address_label_not_empty
        CHECK (address_label IS NULL OR length(trim(address_label)) > 0),

    CONSTRAINT addresses_address_line_2_not_empty
        CHECK (address_line_2 IS NULL OR length(trim(address_line_2)) > 0),

    CONSTRAINT addresses_state_region_not_empty
        CHECK (state_region IS NULL OR length(trim(state_region)) > 0),

    CONSTRAINT addresses_postal_code_not_empty
        CHECK (postal_code IS NULL OR length(trim(postal_code)) > 0),

    CONSTRAINT addresses_country_code_format
        CHECK (country_code ~ '^[A-Z]{2}$'),

    CONSTRAINT addresses_valid_type
        CHECK (address_type IN (
            'general',
            'legal',
            'billing',
            'shipping',
            'branch',
            'warehouse',
            'other'
        )),

    CONSTRAINT addresses_latitude_valid
        CHECK (latitude IS NULL OR latitude BETWEEN -90 AND 90),

    CONSTRAINT addresses_longitude_valid
        CHECK (longitude IS NULL OR longitude BETWEEN -180 AND 180),

    CONSTRAINT addresses_updated_at_valid
        CHECK (updated_at >= created_at)
);


CREATE INDEX idx_branches_company_id
    ON core.branches(company_id);

CREATE INDEX idx_departments_company_id
    ON core.departments(company_id);

CREATE INDEX idx_departments_branch_id
    ON core.departments(branch_id);

CREATE INDEX idx_departments_parent_department_id
    ON core.departments(parent_department_id);

CREATE INDEX idx_addresses_company_id
    ON core.addresses(company_id);

CREATE INDEX idx_addresses_branch_id
    ON core.addresses(branch_id);

CREATE INDEX idx_addresses_address_type
    ON core.addresses(address_type);

COMMIT;