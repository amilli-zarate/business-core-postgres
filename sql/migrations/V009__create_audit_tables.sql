BEGIN;

CREATE SCHEMA IF NOT EXISTS audit;

CREATE TABLE audit.audit_events (
    audit_event_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,

    event_occurred_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    action_category TEXT NOT NULL,
    action_type TEXT NOT NULL,
    event_outcome TEXT NOT NULL DEFAULT 'SUCCESS',
    severity TEXT NOT NULL DEFAULT 'INFO',

    entity_schema TEXT,
    entity_table TEXT,
    entity_record_id BIGINT,

    actor_account_id BIGINT,
    actor_person_id BIGINT,
    company_id BIGINT,
    workflow_instance_id BIGINT,

    request_id TEXT,
    session_id TEXT,
    source_system TEXT NOT NULL DEFAULT 'database',
    client_ip INET,
    user_agent TEXT,

    event_summary TEXT,
    metadata JSONB NOT NULL DEFAULT '{}'::JSONB,

    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CONSTRAINT audit_events_action_category_chk
        CHECK (
            action_category IN (
                'DATA',
                'IDENTITY',
                'WORKFLOW',
                'FINANCE',
                'DOCUMENT',
                'SECURITY',
                'INTEGRATION',
                'SYSTEM'
            )
        ),

    CONSTRAINT audit_events_action_type_chk
        CHECK (
            action_type IN (
                'CREATE',
                'READ',
                'UPDATE',
                'DELETE',
                'LOGIN',
                'LOGOUT',
                'STATUS_CHANGE',
                'ASSIGN',
                'UNASSIGN',
                'SUBMIT',
                'APPROVE',
                'REJECT',
                'CANCEL',
                'COMMENT',
                'EXPORT',
                'IMPORT',
                'SYSTEM_EVENT'
            )
        ),

    CONSTRAINT audit_events_event_outcome_chk
        CHECK (
            event_outcome IN (
                'SUCCESS',
                'FAILURE',
                'WARNING',
                'INFO'
            )
        ),

    CONSTRAINT audit_events_severity_chk
        CHECK (
            severity IN (
                'DEBUG',
                'INFO',
                'WARNING',
                'ERROR',
                'CRITICAL'
            )
        ),

    CONSTRAINT audit_events_entity_target_chk
        CHECK (
            (
                entity_schema IS NULL
                AND entity_table IS NULL
            )
            OR
            (
                entity_schema IS NOT NULL
                AND entity_table IS NOT NULL
            )
        ),

    CONSTRAINT audit_events_entity_record_id_chk
        CHECK (
            entity_record_id IS NULL
            OR entity_record_id > 0
        ),

    CONSTRAINT audit_events_actor_account_id_fkey
        FOREIGN KEY (actor_account_id)
        REFERENCES identity.user_accounts(account_id)
        ON DELETE SET NULL,

    CONSTRAINT audit_events_actor_person_id_fkey
        FOREIGN KEY (actor_person_id)
        REFERENCES people.persons(person_id)
        ON DELETE SET NULL,

    CONSTRAINT audit_events_company_id_fkey
        FOREIGN KEY (company_id)
        REFERENCES core.companies(company_id)
        ON DELETE SET NULL,

    CONSTRAINT audit_events_workflow_instance_id_fkey
        FOREIGN KEY (workflow_instance_id)
        REFERENCES workflows.workflow_instances(workflow_instance_id)
        ON DELETE SET NULL
);

CREATE TABLE audit.audit_event_changes (
    audit_event_change_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,

    audit_event_id BIGINT NOT NULL,

    field_name TEXT NOT NULL,
    old_value JSONB,
    new_value JSONB,

    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CONSTRAINT audit_event_changes_audit_event_id_fkey
        FOREIGN KEY (audit_event_id)
        REFERENCES audit.audit_events(audit_event_id)
        ON DELETE CASCADE,

    CONSTRAINT audit_event_changes_value_changed_chk
        CHECK (
            old_value IS DISTINCT FROM new_value
        ),

    CONSTRAINT audit_event_changes_field_unique
        UNIQUE (audit_event_id, field_name)
);

CREATE INDEX audit_events_event_occurred_at_idx
    ON audit.audit_events (event_occurred_at DESC);

CREATE INDEX audit_events_actor_account_id_idx
    ON audit.audit_events (actor_account_id, event_occurred_at DESC);

CREATE INDEX audit_events_actor_person_id_idx
    ON audit.audit_events (actor_person_id, event_occurred_at DESC);

CREATE INDEX audit_events_company_id_idx
    ON audit.audit_events (company_id, event_occurred_at DESC);

CREATE INDEX audit_events_entity_target_idx
    ON audit.audit_events (
        entity_schema,
        entity_table,
        entity_record_id,
        event_occurred_at DESC
    );

CREATE INDEX audit_events_workflow_instance_id_idx
    ON audit.audit_events (workflow_instance_id, event_occurred_at DESC);

CREATE INDEX audit_events_metadata_gin_idx
    ON audit.audit_events
    USING GIN (metadata);

CREATE INDEX audit_event_changes_audit_event_id_idx
    ON audit.audit_event_changes (audit_event_id);

CREATE INDEX audit_event_changes_field_name_idx
    ON audit.audit_event_changes (field_name);

COMMENT ON SCHEMA audit IS
    'Audit and traceability layer for business-core-postgres.';

COMMENT ON TABLE audit.audit_events IS
    'Immutable log of business, data, workflow, identity, security, integration, and system events.';

COMMENT ON COLUMN audit.audit_events.entity_schema IS
    'Schema of the affected entity. Used instead of a polymorphic foreign key.';

COMMENT ON COLUMN audit.audit_events.entity_table IS
    'Table of the affected entity. Used together with entity_schema and entity_record_id.';

COMMENT ON COLUMN audit.audit_events.entity_record_id IS
    'Primary key of the affected record when applicable. This follows the repository-wide BIGINT surrogate key convention.';

COMMENT ON COLUMN audit.audit_events.metadata IS
    'Flexible JSONB payload for extra context that does not deserve a first-class column.';

COMMENT ON TABLE audit.audit_event_changes IS
    'Field-level before/after values associated with an audit event.';

COMMIT;