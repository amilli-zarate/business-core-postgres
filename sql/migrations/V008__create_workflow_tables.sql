BEGIN;

CREATE SCHEMA IF NOT EXISTS workflows;

-- Generic updated_at trigger function for the workflows schema.
CREATE OR REPLACE FUNCTION workflows.set_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;


-- Workflow templates / definitions.
CREATE TABLE workflows.workflow_definitions (
    workflow_definition_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,

    company_id BIGINT NOT NULL,

    workflow_key TEXT NOT NULL,
    version_number INTEGER NOT NULL DEFAULT 1,

    name TEXT NOT NULL,
    description TEXT,

    workflow_domain TEXT,

    target_entity_schema TEXT,
    target_entity_table TEXT,

    is_active BOOLEAN NOT NULL DEFAULT TRUE,

    created_by_account_id BIGINT,

    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CONSTRAINT workflow_definitions_company_id_fkey
        FOREIGN KEY (company_id)
        REFERENCES core.companies (company_id)
        ON DELETE RESTRICT,

    CONSTRAINT workflow_definitions_created_by_account_id_fkey
        FOREIGN KEY (created_by_account_id)
        REFERENCES identity.user_accounts (account_id)
        ON DELETE SET NULL,

    CONSTRAINT workflow_definitions_company_definition_uq
        UNIQUE (company_id, workflow_definition_id),

    CONSTRAINT workflow_definitions_company_key_version_uq
        UNIQUE (company_id, workflow_key, version_number),

    CONSTRAINT workflow_definitions_version_positive_chk
        CHECK (version_number > 0),

    CONSTRAINT workflow_definitions_workflow_key_format_chk
        CHECK (workflow_key ~ '^[a-z][a-z0-9_]*(\.[a-z][a-z0-9_]*)*$'),

    CONSTRAINT workflow_definitions_target_pair_chk
        CHECK (
            (target_entity_schema IS NULL AND target_entity_table IS NULL)
            OR
            (target_entity_schema IS NOT NULL AND target_entity_table IS NOT NULL)
        ),

    CONSTRAINT workflow_definitions_target_schema_format_chk
        CHECK (
            target_entity_schema IS NULL
            OR target_entity_schema ~ '^[a-z_][a-z0-9_]*$'
        ),

    CONSTRAINT workflow_definitions_target_table_format_chk
        CHECK (
            target_entity_table IS NULL
            OR target_entity_table ~ '^[a-z_][a-z0-9_]*$'
        )
);


-- Only one active version of a workflow key per company.
CREATE UNIQUE INDEX workflow_definitions_one_active_version_uq
ON workflows.workflow_definitions (company_id, workflow_key)
WHERE is_active;


-- Ordered steps inside a workflow definition.
CREATE TABLE workflows.workflow_steps (
    workflow_step_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,

    workflow_definition_id BIGINT NOT NULL,

    step_key TEXT NOT NULL,
    name TEXT NOT NULL,
    description TEXT,

    step_order INTEGER NOT NULL,

    step_type TEXT NOT NULL DEFAULT 'task',

    is_required BOOLEAN NOT NULL DEFAULT TRUE,

    default_assignee_type TEXT NOT NULL DEFAULT 'unassigned',
    default_assignee_account_id BIGINT,

    default_due_interval INTERVAL,

    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CONSTRAINT workflow_steps_definition_id_fkey
        FOREIGN KEY (workflow_definition_id)
        REFERENCES workflows.workflow_definitions (workflow_definition_id)
        ON DELETE CASCADE,

    CONSTRAINT workflow_steps_default_assignee_account_id_fkey
        FOREIGN KEY (default_assignee_account_id)
        REFERENCES identity.user_accounts (account_id)
        ON DELETE SET NULL,

    CONSTRAINT workflow_steps_definition_step_uq
        UNIQUE (workflow_definition_id, workflow_step_id),

    CONSTRAINT workflow_steps_definition_step_key_uq
        UNIQUE (workflow_definition_id, step_key),

    CONSTRAINT workflow_steps_definition_order_uq
        UNIQUE (workflow_definition_id, step_order),

    CONSTRAINT workflow_steps_order_positive_chk
        CHECK (step_order > 0),

    CONSTRAINT workflow_steps_step_key_format_chk
        CHECK (step_key ~ '^[a-z][a-z0-9_]*$'),

    CONSTRAINT workflow_steps_step_type_chk
        CHECK (
            step_type IN (
                'start',
                'task',
                'approval',
                'decision',
                'system',
                'end'
            )
        ),

    CONSTRAINT workflow_steps_default_assignee_type_chk
        CHECK (
            default_assignee_type IN (
                'unassigned',
                'initiator',
                'specific_account',
                'role',
                'department'
            )
        )
);


-- Allowed transitions between workflow steps.
CREATE TABLE workflows.workflow_transitions (
    workflow_transition_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,

    workflow_definition_id BIGINT NOT NULL,

    from_step_id BIGINT,
    to_step_id BIGINT NOT NULL,

    transition_key TEXT NOT NULL,
    name TEXT,

    outcome_value TEXT,
    condition_expression TEXT,

    sort_order INTEGER NOT NULL DEFAULT 1,

    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CONSTRAINT workflow_transitions_definition_id_fkey
        FOREIGN KEY (workflow_definition_id)
        REFERENCES workflows.workflow_definitions (workflow_definition_id)
        ON DELETE CASCADE,

    CONSTRAINT workflow_transitions_from_step_fkey
        FOREIGN KEY (workflow_definition_id, from_step_id)
        REFERENCES workflows.workflow_steps (workflow_definition_id, workflow_step_id)
        ON DELETE CASCADE,

    CONSTRAINT workflow_transitions_to_step_fkey
        FOREIGN KEY (workflow_definition_id, to_step_id)
        REFERENCES workflows.workflow_steps (workflow_definition_id, workflow_step_id)
        ON DELETE CASCADE,

    CONSTRAINT workflow_transitions_definition_key_uq
        UNIQUE (workflow_definition_id, transition_key),

    CONSTRAINT workflow_transitions_transition_key_format_chk
        CHECK (transition_key ~ '^[a-z][a-z0-9_]*$'),

    CONSTRAINT workflow_transitions_not_self_transition_chk
        CHECK (from_step_id IS DISTINCT FROM to_step_id),

    CONSTRAINT workflow_transitions_sort_order_positive_chk
        CHECK (sort_order > 0)
);


-- Runtime workflow instances.
CREATE TABLE workflows.workflow_instances (
    workflow_instance_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,

    company_id BIGINT NOT NULL,

    workflow_definition_id BIGINT NOT NULL,
    current_step_id BIGINT,

    title TEXT NOT NULL,

    subject_entity_schema TEXT,
    subject_entity_table TEXT,
    subject_entity_id BIGINT,

    status TEXT NOT NULL DEFAULT 'running',

    started_by_account_id BIGINT,

    started_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    completed_at TIMESTAMPTZ,
    cancelled_at TIMESTAMPTZ,

    metadata JSONB NOT NULL DEFAULT '{}'::JSONB,

    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CONSTRAINT workflow_instances_company_definition_fkey
        FOREIGN KEY (company_id, workflow_definition_id)
        REFERENCES workflows.workflow_definitions (company_id, workflow_definition_id)
        ON DELETE RESTRICT,

    CONSTRAINT workflow_instances_current_step_fkey
        FOREIGN KEY (workflow_definition_id, current_step_id)
        REFERENCES workflows.workflow_steps (workflow_definition_id, workflow_step_id)
        ON DELETE SET NULL,

    CONSTRAINT workflow_instances_started_by_account_id_fkey
        FOREIGN KEY (started_by_account_id)
        REFERENCES identity.user_accounts (account_id)
        ON DELETE SET NULL,

    CONSTRAINT workflow_instances_company_instance_uq
        UNIQUE (company_id, workflow_instance_id),

    CONSTRAINT workflow_instances_company_instance_definition_uq
        UNIQUE (company_id, workflow_instance_id, workflow_definition_id),

    CONSTRAINT workflow_instances_subject_reference_chk
        CHECK (
            (
                subject_entity_schema IS NULL
                AND subject_entity_table IS NULL
                AND subject_entity_id IS NULL
            )
            OR
            (
                subject_entity_schema IS NOT NULL
                AND subject_entity_table IS NOT NULL
                AND subject_entity_id IS NOT NULL
            )
        ),

    CONSTRAINT workflow_instances_subject_schema_format_chk
        CHECK (
            subject_entity_schema IS NULL
            OR subject_entity_schema ~ '^[a-z_][a-z0-9_]*$'
        ),

    CONSTRAINT workflow_instances_subject_table_format_chk
        CHECK (
            subject_entity_table IS NULL
            OR subject_entity_table ~ '^[a-z_][a-z0-9_]*$'
        ),

    CONSTRAINT workflow_instances_status_chk
        CHECK (
            status IN (
                'draft',
                'running',
                'paused',
                'completed',
                'cancelled',
                'failed'
            )
        ),

    CONSTRAINT workflow_instances_completed_at_chk
        CHECK (completed_at IS NULL OR completed_at >= started_at),

    CONSTRAINT workflow_instances_cancelled_at_chk
        CHECK (cancelled_at IS NULL OR cancelled_at >= started_at),

    CONSTRAINT workflow_instances_metadata_object_chk
        CHECK (jsonb_typeof(metadata) = 'object')
);


-- Executable tasks generated by workflow steps.
CREATE TABLE workflows.workflow_tasks (
    workflow_task_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,

    company_id BIGINT NOT NULL,

    workflow_instance_id BIGINT NOT NULL,
    workflow_definition_id BIGINT NOT NULL,
    workflow_step_id BIGINT NOT NULL,

    title TEXT NOT NULL,
    description TEXT,

    status TEXT NOT NULL DEFAULT 'open',
    priority TEXT NOT NULL DEFAULT 'normal',

    assigned_to_account_id BIGINT,

    due_at TIMESTAMPTZ,

    completed_by_account_id BIGINT,
    completed_at TIMESTAMPTZ,

    metadata JSONB NOT NULL DEFAULT '{}'::JSONB,

    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CONSTRAINT workflow_tasks_instance_fkey
        FOREIGN KEY (company_id, workflow_instance_id, workflow_definition_id)
        REFERENCES workflows.workflow_instances (
            company_id,
            workflow_instance_id,
            workflow_definition_id
        )
        ON DELETE CASCADE,

    CONSTRAINT workflow_tasks_step_fkey
        FOREIGN KEY (workflow_definition_id, workflow_step_id)
        REFERENCES workflows.workflow_steps (workflow_definition_id, workflow_step_id)
        ON DELETE RESTRICT,

    CONSTRAINT workflow_tasks_assigned_to_account_id_fkey
        FOREIGN KEY (assigned_to_account_id)
        REFERENCES identity.user_accounts (account_id)
        ON DELETE SET NULL,

    CONSTRAINT workflow_tasks_completed_by_account_id_fkey
        FOREIGN KEY (completed_by_account_id)
        REFERENCES identity.user_accounts (account_id)
        ON DELETE SET NULL,

    CONSTRAINT workflow_tasks_company_task_uq
        UNIQUE (company_id, workflow_task_id),

    CONSTRAINT workflow_tasks_status_chk
        CHECK (
            status IN (
                'open',
                'in_progress',
                'blocked',
                'completed',
                'cancelled',
                'skipped',
                'failed'
            )
        ),

    CONSTRAINT workflow_tasks_priority_chk
        CHECK (
            priority IN (
                'low',
                'normal',
                'high',
                'urgent'
            )
        ),

    CONSTRAINT workflow_tasks_completed_at_chk
        CHECK (completed_at IS NULL OR completed_at >= created_at),

    CONSTRAINT workflow_tasks_metadata_object_chk
        CHECK (jsonb_typeof(metadata) = 'object')
);


-- Optional task assignment candidates, owners, reviewers, or observers.
CREATE TABLE workflows.workflow_task_assignments (
    workflow_task_assignment_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,

    company_id BIGINT NOT NULL,
    workflow_task_id BIGINT NOT NULL,

    assignment_type TEXT NOT NULL DEFAULT 'candidate',

    account_id BIGINT,
    role_id BIGINT,

    assigned_by_account_id BIGINT,

    assigned_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CONSTRAINT workflow_task_assignments_task_fkey
        FOREIGN KEY (company_id, workflow_task_id)
        REFERENCES workflows.workflow_tasks (company_id, workflow_task_id)
        ON DELETE CASCADE,

    CONSTRAINT workflow_task_assignments_account_id_fkey
        FOREIGN KEY (account_id)
        REFERENCES identity.user_accounts (account_id)
        ON DELETE CASCADE,

    CONSTRAINT workflow_task_assignments_role_id_fkey
        FOREIGN KEY (role_id)
        REFERENCES identity.access_roles (role_id)
        ON DELETE CASCADE,

    CONSTRAINT workflow_task_assignments_assigned_by_account_id_fkey
        FOREIGN KEY (assigned_by_account_id)
        REFERENCES identity.user_accounts (account_id)
        ON DELETE SET NULL,

    CONSTRAINT workflow_task_assignments_type_chk
        CHECK (
            assignment_type IN (
                'candidate',
                'owner',
                'reviewer',
                'observer'
            )
        ),

    CONSTRAINT workflow_task_assignments_target_chk
        CHECK (
            (
                CASE WHEN account_id IS NOT NULL THEN 1 ELSE 0 END
                +
                CASE WHEN role_id IS NOT NULL THEN 1 ELSE 0 END
            ) = 1
        ),

    CONSTRAINT workflow_task_assignments_account_uq
        UNIQUE (workflow_task_id, assignment_type, account_id),

    CONSTRAINT workflow_task_assignments_role_uq
        UNIQUE (workflow_task_id, assignment_type, role_id)
);


-- Workflow-level status and step movement history.
CREATE TABLE workflows.workflow_status_history (
    workflow_status_history_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,

    company_id BIGINT NOT NULL,

    workflow_instance_id BIGINT NOT NULL,
    workflow_definition_id BIGINT NOT NULL,

    from_status TEXT,
    to_status TEXT NOT NULL,

    from_step_id BIGINT,
    to_step_id BIGINT,

    changed_by_account_id BIGINT,
    changed_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    note TEXT,
    metadata JSONB NOT NULL DEFAULT '{}'::JSONB,

    CONSTRAINT workflow_status_history_instance_fkey
        FOREIGN KEY (company_id, workflow_instance_id, workflow_definition_id)
        REFERENCES workflows.workflow_instances (
            company_id,
            workflow_instance_id,
            workflow_definition_id
        )
        ON DELETE CASCADE,

    CONSTRAINT workflow_status_history_from_step_fkey
        FOREIGN KEY (workflow_definition_id, from_step_id)
        REFERENCES workflows.workflow_steps (workflow_definition_id, workflow_step_id)
        ON DELETE RESTRICT,

    CONSTRAINT workflow_status_history_to_step_fkey
        FOREIGN KEY (workflow_definition_id, to_step_id)
        REFERENCES workflows.workflow_steps (workflow_definition_id, workflow_step_id)
        ON DELETE RESTRICT,

    CONSTRAINT workflow_status_history_changed_by_account_id_fkey
        FOREIGN KEY (changed_by_account_id)
        REFERENCES identity.user_accounts (account_id)
        ON DELETE SET NULL,

    CONSTRAINT workflow_status_history_from_status_chk
        CHECK (
            from_status IS NULL
            OR from_status IN (
                'draft',
                'running',
                'paused',
                'completed',
                'cancelled',
                'failed'
            )
        ),

    CONSTRAINT workflow_status_history_to_status_chk
        CHECK (
            to_status IN (
                'draft',
                'running',
                'paused',
                'completed',
                'cancelled',
                'failed'
            )
        ),

    CONSTRAINT workflow_status_history_metadata_object_chk
        CHECK (jsonb_typeof(metadata) = 'object')
);


-- Indexes.
CREATE INDEX workflow_definitions_company_active_idx
ON workflows.workflow_definitions (company_id, is_active);

CREATE INDEX workflow_steps_definition_order_idx
ON workflows.workflow_steps (workflow_definition_id, step_order);

CREATE INDEX workflow_transitions_from_step_idx
ON workflows.workflow_transitions (workflow_definition_id, from_step_id);

CREATE INDEX workflow_transitions_to_step_idx
ON workflows.workflow_transitions (workflow_definition_id, to_step_id);

CREATE INDEX workflow_instances_company_status_idx
ON workflows.workflow_instances (company_id, status);

CREATE INDEX workflow_instances_subject_idx
ON workflows.workflow_instances (
    subject_entity_schema,
    subject_entity_table,
    subject_entity_id
);

CREATE INDEX workflow_instances_started_by_idx
ON workflows.workflow_instances (started_by_account_id);

CREATE INDEX workflow_tasks_company_status_due_idx
ON workflows.workflow_tasks (company_id, status, due_at);

CREATE INDEX workflow_tasks_assigned_to_status_due_idx
ON workflows.workflow_tasks (assigned_to_account_id, status, due_at)
WHERE assigned_to_account_id IS NOT NULL;

CREATE INDEX workflow_task_assignments_account_idx
ON workflows.workflow_task_assignments (account_id)
WHERE account_id IS NOT NULL;

CREATE INDEX workflow_task_assignments_role_idx
ON workflows.workflow_task_assignments (role_id)
WHERE role_id IS NOT NULL;

CREATE INDEX workflow_status_history_instance_idx
ON workflows.workflow_status_history (
    company_id,
    workflow_instance_id,
    changed_at DESC
);


-- updated_at triggers.
CREATE TRIGGER workflow_definitions_set_updated_at
BEFORE UPDATE ON workflows.workflow_definitions
FOR EACH ROW
EXECUTE FUNCTION workflows.set_updated_at();

CREATE TRIGGER workflow_steps_set_updated_at
BEFORE UPDATE ON workflows.workflow_steps
FOR EACH ROW
EXECUTE FUNCTION workflows.set_updated_at();

CREATE TRIGGER workflow_instances_set_updated_at
BEFORE UPDATE ON workflows.workflow_instances
FOR EACH ROW
EXECUTE FUNCTION workflows.set_updated_at();

CREATE TRIGGER workflow_tasks_set_updated_at
BEFORE UPDATE ON workflows.workflow_tasks
FOR EACH ROW
EXECUTE FUNCTION workflows.set_updated_at();


-- Documentation comments.
COMMENT ON TABLE workflows.workflow_definitions IS
'Reusable workflow templates scoped by company.';

COMMENT ON TABLE workflows.workflow_steps IS
'Ordered steps that compose a workflow definition.';

COMMENT ON TABLE workflows.workflow_transitions IS
'Allowed movements between workflow steps.';

COMMENT ON TABLE workflows.workflow_instances IS
'Runtime executions of workflow definitions over optional business entities.';

COMMENT ON TABLE workflows.workflow_tasks IS
'Actionable tasks produced during workflow execution.';

COMMENT ON TABLE workflows.workflow_task_assignments IS
'Additional account or role assignments for workflow tasks.';

COMMENT ON TABLE workflows.workflow_status_history IS
'Status and step movement history for workflow instances.';

COMMIT;