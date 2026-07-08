BEGIN;

-- ============================================================
-- V005: Identity and access-control tables
-- ============================================================
-- Purpose:
--   Define application accounts, authentication identities,
--   access roles, permissions, and scoped role assignments.
--
-- Important:
--   This migration follows the repository-wide BIGINT surrogate
--   key strategy used by the previous migrations.
--
--   This migration does NOT model employment or organizational
--   relationships. Those belong to people.* and relationships.*.
-- ============================================================


-- ------------------------------------------------------------
-- Application user accounts
-- ------------------------------------------------------------

CREATE TABLE identity.user_accounts (
    account_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,

    person_id BIGINT UNIQUE
        REFERENCES people.persons(person_id)
        ON UPDATE CASCADE
        ON DELETE SET NULL,

    account_email TEXT NOT NULL,
    username TEXT,

    account_status TEXT NOT NULL DEFAULT 'pending'
        CHECK (
            account_status IN (
                'pending',
                'active',
                'suspended',
                'disabled',
                'closed'
            )
        ),

    is_service_account BOOLEAN NOT NULL DEFAULT FALSE,

    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),

    CHECK (btrim(account_email) <> ''),
    CHECK (username IS NULL OR btrim(username) <> '')
);

CREATE UNIQUE INDEX ux_user_accounts_account_email_lower
    ON identity.user_accounts (lower(account_email));

CREATE UNIQUE INDEX ux_user_accounts_username_lower
    ON identity.user_accounts (lower(username))
    WHERE username IS NOT NULL;

CREATE INDEX ix_user_accounts_person_id
    ON identity.user_accounts (person_id);

CREATE INDEX ix_user_accounts_status
    ON identity.user_accounts (account_status);


-- ------------------------------------------------------------
-- Authentication identities
-- ------------------------------------------------------------

CREATE TABLE identity.authentication_identities (
    authentication_identity_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,

    account_id BIGINT NOT NULL
        REFERENCES identity.user_accounts(account_id)
        ON UPDATE CASCADE
        ON DELETE CASCADE,

    provider TEXT NOT NULL,
    provider_subject TEXT NOT NULL,

    password_hash TEXT,
    provider_email TEXT,

    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    last_authenticated_at TIMESTAMPTZ,

    CHECK (btrim(provider) <> ''),
    CHECK (btrim(provider_subject) <> ''),
    CHECK (provider_email IS NULL OR btrim(provider_email) <> ''),
    CHECK (
        provider <> 'local'
        OR password_hash IS NOT NULL
    ),
    CHECK (
        password_hash IS NULL
        OR btrim(password_hash) <> ''
    )
);

CREATE UNIQUE INDEX ux_authentication_identities_provider_subject
    ON identity.authentication_identities (provider, provider_subject);

CREATE INDEX ix_authentication_identities_account_id
    ON identity.authentication_identities (account_id);

CREATE INDEX ix_authentication_identities_provider
    ON identity.authentication_identities (provider);


-- ------------------------------------------------------------
-- Access roles
-- ------------------------------------------------------------
-- These are system/application roles, not job positions.
-- ------------------------------------------------------------

CREATE TABLE identity.access_roles (
    role_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,

    role_key TEXT NOT NULL UNIQUE,
    role_name TEXT NOT NULL,
    role_description TEXT,

    role_scope TEXT NOT NULL
        CHECK (
            role_scope IN (
                'platform',
                'company',
                'branch',
                'department'
            )
        ),

    is_system_role BOOLEAN NOT NULL DEFAULT FALSE,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,

    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),

    UNIQUE (role_id, role_scope),

    CHECK (role_key ~ '^[a-z][a-z0-9_]*$'),
    CHECK (btrim(role_name) <> '')
);

CREATE INDEX ix_access_roles_role_scope
    ON identity.access_roles (role_scope);

CREATE INDEX ix_access_roles_is_active
    ON identity.access_roles (is_active);


-- ------------------------------------------------------------
-- Permissions
-- ------------------------------------------------------------

CREATE TABLE identity.permissions (
    permission_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,

    permission_key TEXT NOT NULL UNIQUE,
    permission_name TEXT NOT NULL,
    permission_description TEXT,

    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),

    CHECK (
        permission_key ~ '^[a-z][a-z0-9_]*(\.[a-z][a-z0-9_]*)+$'
    ),
    CHECK (btrim(permission_name) <> '')
);

CREATE INDEX ix_permissions_permission_key
    ON identity.permissions (permission_key);


-- ------------------------------------------------------------
-- Role-permission mapping
-- ------------------------------------------------------------

CREATE TABLE identity.role_permissions (
    role_id BIGINT NOT NULL
        REFERENCES identity.access_roles(role_id)
        ON UPDATE CASCADE
        ON DELETE CASCADE,

    permission_id BIGINT NOT NULL
        REFERENCES identity.permissions(permission_id)
        ON UPDATE CASCADE
        ON DELETE CASCADE,

    granted_at TIMESTAMPTZ NOT NULL DEFAULT now(),

    PRIMARY KEY (role_id, permission_id)
);

CREATE INDEX ix_role_permissions_permission_id
    ON identity.role_permissions (permission_id);


-- ------------------------------------------------------------
-- Scoped account-role assignments
-- ------------------------------------------------------------

CREATE TABLE identity.account_role_assignments (
    account_role_assignment_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,

    account_id BIGINT NOT NULL
        REFERENCES identity.user_accounts(account_id)
        ON UPDATE CASCADE
        ON DELETE CASCADE,

    role_id BIGINT NOT NULL,

    scope_type TEXT NOT NULL
        CHECK (
            scope_type IN (
                'platform',
                'company',
                'branch',
                'department'
            )
        ),

    company_id BIGINT
        REFERENCES core.companies(company_id)
        ON UPDATE CASCADE
        ON DELETE CASCADE,

    branch_id BIGINT
        REFERENCES core.branches(branch_id)
        ON UPDATE CASCADE
        ON DELETE CASCADE,

    department_id BIGINT
        REFERENCES core.departments(department_id)
        ON UPDATE CASCADE
        ON DELETE CASCADE,

    assigned_by_account_id BIGINT
        REFERENCES identity.user_accounts(account_id)
        ON UPDATE CASCADE
        ON DELETE SET NULL,

    revoked_by_account_id BIGINT
        REFERENCES identity.user_accounts(account_id)
        ON UPDATE CASCADE
        ON DELETE SET NULL,

    assigned_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    revoked_at TIMESTAMPTZ,

    valid_from TIMESTAMPTZ NOT NULL DEFAULT now(),
    valid_until TIMESTAMPTZ,

    FOREIGN KEY (role_id, scope_type)
        REFERENCES identity.access_roles(role_id, role_scope)
        ON UPDATE CASCADE
        ON DELETE RESTRICT,

    CHECK (
        (
            scope_type = 'platform'
            AND company_id IS NULL
            AND branch_id IS NULL
            AND department_id IS NULL
        )
        OR
        (
            scope_type = 'company'
            AND company_id IS NOT NULL
            AND branch_id IS NULL
            AND department_id IS NULL
        )
        OR
        (
            scope_type = 'branch'
            AND company_id IS NOT NULL
            AND branch_id IS NOT NULL
            AND department_id IS NULL
        )
        OR
        (
            scope_type = 'department'
            AND company_id IS NOT NULL
            AND branch_id IS NULL
            AND department_id IS NOT NULL
        )
    ),

    CHECK (
        valid_until IS NULL
        OR valid_until > valid_from
    ),

    CHECK (
        revoked_at IS NULL
        OR revoked_at >= assigned_at
    )
);

CREATE INDEX ix_account_role_assignments_account_id
    ON identity.account_role_assignments (account_id);

CREATE INDEX ix_account_role_assignments_role_id
    ON identity.account_role_assignments (role_id);

CREATE INDEX ix_account_role_assignments_company_id
    ON identity.account_role_assignments (company_id);

CREATE INDEX ix_account_role_assignments_branch_id
    ON identity.account_role_assignments (branch_id);

CREATE INDEX ix_account_role_assignments_department_id
    ON identity.account_role_assignments (department_id);

CREATE INDEX ix_account_role_assignments_scope_type
    ON identity.account_role_assignments (scope_type);

CREATE UNIQUE INDEX ux_account_role_assignments_platform_active
    ON identity.account_role_assignments (
        account_id,
        role_id
    )
    WHERE scope_type = 'platform'
      AND revoked_at IS NULL;

CREATE UNIQUE INDEX ux_account_role_assignments_company_active
    ON identity.account_role_assignments (
        account_id,
        role_id,
        company_id
    )
    WHERE scope_type = 'company'
      AND revoked_at IS NULL;

CREATE UNIQUE INDEX ux_account_role_assignments_branch_active
    ON identity.account_role_assignments (
        account_id,
        role_id,
        company_id,
        branch_id
    )
    WHERE scope_type = 'branch'
      AND revoked_at IS NULL;

CREATE UNIQUE INDEX ux_account_role_assignments_department_active
    ON identity.account_role_assignments (
        account_id,
        role_id,
        company_id,
        department_id
    )
    WHERE scope_type = 'department'
      AND revoked_at IS NULL;


-- ------------------------------------------------------------
-- Documentation comments
-- ------------------------------------------------------------

COMMENT ON TABLE identity.user_accounts IS
    'Application-level user accounts. Optionally linked to people.persons.';

COMMENT ON TABLE identity.authentication_identities IS
    'Authentication provider identities associated with application user accounts.';

COMMENT ON TABLE identity.access_roles IS
    'Application access roles such as platform_admin, company_admin, branch_manager, or read_only.';

COMMENT ON TABLE identity.permissions IS
    'Atomic application permissions using dotted permission keys.';

COMMENT ON TABLE identity.role_permissions IS
    'Many-to-many mapping between access roles and permissions.';

COMMENT ON TABLE identity.account_role_assignments IS
    'Scoped role assignments connecting user accounts to platform, company, branch, or department access.';


COMMIT;