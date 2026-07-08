-- ============================================================
-- V004__create_relationship_tables.sql
-- Business Core Postgres
--
-- Purpose:
--   Create role-neutral relationship tables connecting persons
--   to companies, departments, managers, and other persons.
--
-- Depends on:
--   V001__create_schemas.sql
--   V002__create_core_tables.sql
--   V003__create_people_tables.sql
-- ============================================================


-- ------------------------------------------------------------
-- Supporting unique indexes for composite foreign keys
-- ------------------------------------------------------------

CREATE UNIQUE INDEX IF NOT EXISTS ux_core_departments_company_department
ON core.departments (company_id, department_id);

CREATE UNIQUE INDEX IF NOT EXISTS ux_people_persons_company_person
ON people.persons (company_id, person_id);


-- ------------------------------------------------------------
-- Person-company roles
--
-- This table turns a generic person into something meaningful
-- inside a company: employee, contractor, owner, customer contact,
-- supplier contact, advisor, etc.
-- ------------------------------------------------------------

CREATE TABLE IF NOT EXISTS relationships.person_company_roles (
    person_company_role_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,

    company_id BIGINT NOT NULL,
    person_id BIGINT NOT NULL,

    role_type TEXT NOT NULL,
    role_title TEXT,

    status TEXT NOT NULL DEFAULT 'active',

    valid_from DATE NOT NULL DEFAULT CURRENT_DATE,
    valid_to DATE,

    notes TEXT,

    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CONSTRAINT uq_person_company_roles_company_role
        UNIQUE (company_id, person_company_role_id),

    CONSTRAINT fk_person_company_roles_company
        FOREIGN KEY (company_id)
        REFERENCES core.companies (company_id),

    CONSTRAINT fk_person_company_roles_person
        FOREIGN KEY (company_id, person_id)
        REFERENCES people.persons (company_id, person_id),

    CONSTRAINT chk_person_company_roles_role_type
        CHECK (
            role_type IN (
                'employee',
                'contractor',
                'owner',
                'customer_contact',
                'supplier_contact',
                'partner_contact',
                'advisor',
                'other'
            )
        ),

    CONSTRAINT chk_person_company_roles_status
        CHECK (
            status IN (
                'active',
                'inactive',
                'suspended',
                'ended'
            )
        ),

    CONSTRAINT chk_person_company_roles_valid_dates
        CHECK (
            valid_to IS NULL
            OR valid_to >= valid_from
        )
);


-- ------------------------------------------------------------
-- Person-department assignments
--
-- This connects a person-company role to a department.
-- For example: a person with role_type = 'employee' can be
-- assigned to Finance, Sales, Operations, etc.
-- ------------------------------------------------------------

CREATE TABLE IF NOT EXISTS relationships.person_department_assignments (
    person_department_assignment_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,

    company_id BIGINT NOT NULL,
    person_company_role_id BIGINT NOT NULL,
    department_id BIGINT NOT NULL,

    assignment_type TEXT NOT NULL DEFAULT 'primary',
    position_title TEXT,

    valid_from DATE NOT NULL DEFAULT CURRENT_DATE,
    valid_to DATE,

    notes TEXT,

    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CONSTRAINT fk_person_department_assignments_role
        FOREIGN KEY (company_id, person_company_role_id)
        REFERENCES relationships.person_company_roles (
            company_id,
            person_company_role_id
        ),

    CONSTRAINT fk_person_department_assignments_department
        FOREIGN KEY (company_id, department_id)
        REFERENCES core.departments (
            company_id,
            department_id
        ),

    CONSTRAINT chk_person_department_assignments_type
        CHECK (
            assignment_type IN (
                'primary',
                'secondary',
                'temporary',
                'historical'
            )
        ),

    CONSTRAINT chk_person_department_assignments_valid_dates
        CHECK (
            valid_to IS NULL
            OR valid_to >= valid_from
        )
);


CREATE UNIQUE INDEX IF NOT EXISTS ux_person_department_assignments_one_active_primary
ON relationships.person_department_assignments (
    company_id,
    person_company_role_id
)
WHERE assignment_type = 'primary'
  AND valid_to IS NULL;


-- ------------------------------------------------------------
-- Person reporting lines
--
-- This models manager/subordinate relationships.
-- It does not require a separate employees table because both
-- sides reference person_company_roles.
-- ------------------------------------------------------------

CREATE TABLE IF NOT EXISTS relationships.person_reporting_lines (
    person_reporting_line_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,

    company_id BIGINT NOT NULL,

    manager_role_id BIGINT NOT NULL,
    report_role_id BIGINT NOT NULL,

    reporting_type TEXT NOT NULL DEFAULT 'direct',

    valid_from DATE NOT NULL DEFAULT CURRENT_DATE,
    valid_to DATE,

    notes TEXT,

    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CONSTRAINT fk_person_reporting_lines_manager_role
        FOREIGN KEY (company_id, manager_role_id)
        REFERENCES relationships.person_company_roles (
            company_id,
            person_company_role_id
        ),

    CONSTRAINT fk_person_reporting_lines_report_role
        FOREIGN KEY (company_id, report_role_id)
        REFERENCES relationships.person_company_roles (
            company_id,
            person_company_role_id
        ),

    CONSTRAINT chk_person_reporting_lines_not_self
        CHECK (manager_role_id <> report_role_id),

    CONSTRAINT chk_person_reporting_lines_type
        CHECK (
            reporting_type IN (
                'direct',
                'dotted',
                'functional',
                'temporary'
            )
        ),

    CONSTRAINT chk_person_reporting_lines_valid_dates
        CHECK (
            valid_to IS NULL
            OR valid_to >= valid_from
        )
);


CREATE UNIQUE INDEX IF NOT EXISTS ux_person_reporting_lines_one_active_direct_manager
ON relationships.person_reporting_lines (
    company_id,
    report_role_id
)
WHERE reporting_type = 'direct'
  AND valid_to IS NULL;


-- ------------------------------------------------------------
-- Person-person relationships
--
-- Generic human relationships inside a company context.
-- Useful for emergency contacts, representatives, referrers,
-- dependents, mentors, etc.
-- ------------------------------------------------------------

CREATE TABLE IF NOT EXISTS relationships.person_relationships (
    person_relationship_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,

    company_id BIGINT NOT NULL,

    source_person_id BIGINT NOT NULL,
    target_person_id BIGINT NOT NULL,

    relationship_type TEXT NOT NULL,

    valid_from DATE NOT NULL DEFAULT CURRENT_DATE,
    valid_to DATE,

    notes TEXT,

    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CONSTRAINT fk_person_relationships_source_person
        FOREIGN KEY (company_id, source_person_id)
        REFERENCES people.persons (
            company_id,
            person_id
        ),

    CONSTRAINT fk_person_relationships_target_person
        FOREIGN KEY (company_id, target_person_id)
        REFERENCES people.persons (
            company_id,
            person_id
        ),

    CONSTRAINT chk_person_relationships_not_self
        CHECK (source_person_id <> target_person_id),

    CONSTRAINT chk_person_relationships_type
        CHECK (
            relationship_type IN (
                'emergency_contact',
                'dependent',
                'representative',
                'referrer',
                'mentor',
                'other'
            )
        ),

    CONSTRAINT chk_person_relationships_valid_dates
        CHECK (
            valid_to IS NULL
            OR valid_to >= valid_from
        )
);


-- ------------------------------------------------------------
-- Indexes
-- ------------------------------------------------------------

CREATE INDEX IF NOT EXISTS idx_person_company_roles_company_id
ON relationships.person_company_roles (company_id);

CREATE INDEX IF NOT EXISTS idx_person_company_roles_person_id
ON relationships.person_company_roles (person_id);

CREATE INDEX IF NOT EXISTS idx_person_company_roles_role_type
ON relationships.person_company_roles (role_type);

CREATE INDEX IF NOT EXISTS idx_person_department_assignments_company_id
ON relationships.person_department_assignments (company_id);

CREATE INDEX IF NOT EXISTS idx_person_department_assignments_role_id
ON relationships.person_department_assignments (person_company_role_id);

CREATE INDEX IF NOT EXISTS idx_person_department_assignments_department_id
ON relationships.person_department_assignments (department_id);

CREATE INDEX IF NOT EXISTS idx_person_reporting_lines_company_id
ON relationships.person_reporting_lines (company_id);

CREATE INDEX IF NOT EXISTS idx_person_reporting_lines_manager_role_id
ON relationships.person_reporting_lines (manager_role_id);

CREATE INDEX IF NOT EXISTS idx_person_reporting_lines_report_role_id
ON relationships.person_reporting_lines (report_role_id);

CREATE INDEX IF NOT EXISTS idx_person_relationships_company_id
ON relationships.person_relationships (company_id);

CREATE INDEX IF NOT EXISTS idx_person_relationships_source_person_id
ON relationships.person_relationships (source_person_id);

CREATE INDEX IF NOT EXISTS idx_person_relationships_target_person_id
ON relationships.person_relationships (target_person_id);