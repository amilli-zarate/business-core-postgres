BEGIN;

-- ============================================================
-- V006: Finance core tables
-- ============================================================
-- Purpose:
--   Create the generic financial foundation for any company:
--   currencies, fiscal periods, cost centers, chart of accounts,
--   financial transactions, and double-entry transaction lines.
--
-- Design notes:
--   - Uses BIGINT surrogate keys, consistent with previous migrations.
--   - Keeps finance generic: no invoices, orders, payroll, or commerce
--     concepts yet.
--   - Allows draft transactions to be incomplete.
--   - Enforces balance only when a transaction is posted.
-- ============================================================


-- ============================================================
-- 1. Currencies
-- ============================================================

CREATE TABLE finance.currencies (
    currency_code CHAR(3) PRIMARY KEY,
    currency_name TEXT NOT NULL,
    minor_units SMALLINT NOT NULL DEFAULT 2,

    is_active BOOLEAN NOT NULL DEFAULT TRUE,

    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),

    CONSTRAINT currencies_code_format_chk
        CHECK (currency_code ~ '^[A-Z]{3}$'),

    CONSTRAINT currencies_minor_units_chk
        CHECK (minor_units BETWEEN 0 AND 6)
);

COMMENT ON TABLE finance.currencies IS
    'ISO-style currency catalog used by financial transactions.';

COMMENT ON COLUMN finance.currencies.minor_units IS
    'Number of decimal places normally used by the currency. Example: MXN = 2.';


INSERT INTO finance.currencies (
    currency_code,
    currency_name,
    minor_units
)
VALUES
    ('MXN', 'Mexican peso', 2),
    ('USD', 'United States dollar', 2),
    ('EUR', 'Euro', 2)
ON CONFLICT (currency_code) DO NOTHING;


-- ============================================================
-- 2. Fiscal periods
-- ============================================================

CREATE TABLE finance.fiscal_periods (
    fiscal_period_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,

    company_id BIGINT NOT NULL,

    period_code TEXT NOT NULL,
    period_name TEXT NOT NULL,

    fiscal_year INTEGER NOT NULL,
    period_number SMALLINT NOT NULL,

    start_date DATE NOT NULL,
    end_date DATE NOT NULL,

    period_status TEXT NOT NULL DEFAULT 'open',

    closed_at TIMESTAMPTZ,

    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),

    CONSTRAINT fiscal_periods_company_fkey
        FOREIGN KEY (company_id)
        REFERENCES core.companies (company_id)
        ON DELETE CASCADE,

    CONSTRAINT fiscal_periods_company_period_code_key
        UNIQUE (company_id, period_code),

    CONSTRAINT fiscal_periods_company_period_number_key
        UNIQUE (company_id, fiscal_year, period_number),

    CONSTRAINT fiscal_periods_company_id_fiscal_period_id_key
        UNIQUE (company_id, fiscal_period_id),

    CONSTRAINT fiscal_periods_period_status_chk
        CHECK (period_status IN ('open', 'closed', 'locked')),

    CONSTRAINT fiscal_periods_year_chk
        CHECK (fiscal_year BETWEEN 1900 AND 2200),

    CONSTRAINT fiscal_periods_period_number_chk
        CHECK (period_number BETWEEN 1 AND 53),

    CONSTRAINT fiscal_periods_dates_chk
        CHECK (end_date > start_date),

    CONSTRAINT fiscal_periods_closed_at_chk
        CHECK (
            (
                period_status = 'open'
                AND closed_at IS NULL
            )
            OR
            (
                period_status IN ('closed', 'locked')
                AND closed_at IS NOT NULL
            )
        )
);

COMMENT ON TABLE finance.fiscal_periods IS
    'Fiscal periods used to group and control financial transactions.';

COMMENT ON COLUMN finance.fiscal_periods.end_date IS
    'Exclusive upper bound for the fiscal period.';


-- ============================================================
-- 3. Cost centers
-- ============================================================

CREATE TABLE finance.cost_centers (
    cost_center_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,

    company_id BIGINT NOT NULL,
    parent_cost_center_id BIGINT,

    cost_center_code TEXT NOT NULL,
    cost_center_name TEXT NOT NULL,

    description TEXT,

    is_active BOOLEAN NOT NULL DEFAULT TRUE,

    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),

    CONSTRAINT cost_centers_company_fkey
        FOREIGN KEY (company_id)
        REFERENCES core.companies (company_id)
        ON DELETE CASCADE,

    CONSTRAINT cost_centers_company_code_key
        UNIQUE (company_id, cost_center_code),

    CONSTRAINT cost_centers_company_id_cost_center_id_key
        UNIQUE (company_id, cost_center_id),

    CONSTRAINT cost_centers_parent_fkey
        FOREIGN KEY (company_id, parent_cost_center_id)
        REFERENCES finance.cost_centers (company_id, cost_center_id)
        ON DELETE RESTRICT,

    CONSTRAINT cost_centers_not_self_parent_chk
        CHECK (
            parent_cost_center_id IS NULL
            OR parent_cost_center_id <> cost_center_id
        ),

    CONSTRAINT cost_centers_code_not_blank_chk
        CHECK (btrim(cost_center_code) <> ''),

    CONSTRAINT cost_centers_name_not_blank_chk
        CHECK (btrim(cost_center_name) <> '')
);

COMMENT ON TABLE finance.cost_centers IS
    'Generic cost center hierarchy for financial attribution.';


-- ============================================================
-- 4. Chart of accounts
-- ============================================================

CREATE TABLE finance.accounts (
    account_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,

    company_id BIGINT NOT NULL,
    parent_account_id BIGINT,

    account_code TEXT NOT NULL,
    account_name TEXT NOT NULL,

    account_type TEXT NOT NULL,
    normal_balance TEXT NOT NULL,

    is_postable BOOLEAN NOT NULL DEFAULT TRUE,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,

    description TEXT,

    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),

    CONSTRAINT accounts_company_fkey
        FOREIGN KEY (company_id)
        REFERENCES core.companies (company_id)
        ON DELETE CASCADE,

    CONSTRAINT accounts_company_code_key
        UNIQUE (company_id, account_code),

    CONSTRAINT accounts_company_id_account_id_key
        UNIQUE (company_id, account_id),

    CONSTRAINT accounts_parent_fkey
        FOREIGN KEY (company_id, parent_account_id)
        REFERENCES finance.accounts (company_id, account_id)
        ON DELETE RESTRICT,

    CONSTRAINT accounts_not_self_parent_chk
        CHECK (
            parent_account_id IS NULL
            OR parent_account_id <> account_id
        ),

    CONSTRAINT accounts_account_type_chk
        CHECK (
            account_type IN (
                'asset',
                'liability',
                'equity',
                'revenue',
                'expense'
            )
        ),

    CONSTRAINT accounts_normal_balance_chk
        CHECK (normal_balance IN ('debit', 'credit')),

    CONSTRAINT accounts_code_not_blank_chk
        CHECK (btrim(account_code) <> ''),

    CONSTRAINT accounts_name_not_blank_chk
        CHECK (btrim(account_name) <> '')
);

COMMENT ON TABLE finance.accounts IS
    'Company-specific chart of accounts.';

COMMENT ON COLUMN finance.accounts.is_postable IS
    'If false, the account is a grouping account and should not receive transaction lines.';


-- ============================================================
-- 5. Financial transactions
-- ============================================================

CREATE TABLE finance.financial_transactions (
    transaction_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,

    company_id BIGINT NOT NULL,
    fiscal_period_id BIGINT NOT NULL,

    transaction_number TEXT NOT NULL,

    transaction_date DATE NOT NULL,
    posting_date DATE,

    currency_code CHAR(3) NOT NULL,

    transaction_type TEXT NOT NULL DEFAULT 'journal_entry',
    status TEXT NOT NULL DEFAULT 'draft',

    source_system TEXT,
    source_document_id TEXT,

    description TEXT,

    created_by_account_id BIGINT,

    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    posted_at TIMESTAMPTZ,
    voided_at TIMESTAMPTZ,

    CONSTRAINT financial_transactions_company_fkey
        FOREIGN KEY (company_id)
        REFERENCES core.companies (company_id)
        ON DELETE CASCADE,

    CONSTRAINT financial_transactions_fiscal_period_fkey
        FOREIGN KEY (company_id, fiscal_period_id)
        REFERENCES finance.fiscal_periods (company_id, fiscal_period_id)
        ON DELETE RESTRICT,

    CONSTRAINT financial_transactions_currency_fkey
        FOREIGN KEY (currency_code)
        REFERENCES finance.currencies (currency_code)
        ON DELETE RESTRICT,

    CONSTRAINT financial_transactions_created_by_fkey
        FOREIGN KEY (created_by_account_id)
        REFERENCES identity.user_accounts (account_id)
        ON DELETE SET NULL,

    CONSTRAINT financial_transactions_company_number_key
        UNIQUE (company_id, transaction_number),

    CONSTRAINT financial_transactions_company_id_transaction_id_key
        UNIQUE (company_id, transaction_id),

    CONSTRAINT financial_transactions_status_chk
        CHECK (status IN ('draft', 'posted', 'voided')),

    CONSTRAINT financial_transactions_number_not_blank_chk
        CHECK (btrim(transaction_number) <> ''),

    CONSTRAINT financial_transactions_posted_at_chk
        CHECK (
            status <> 'posted'
            OR posted_at IS NOT NULL
        ),

    CONSTRAINT financial_transactions_voided_at_chk
        CHECK (
            status <> 'voided'
            OR voided_at IS NOT NULL
        )
);

COMMENT ON TABLE finance.financial_transactions IS
    'Header table for generic financial transactions.';

COMMENT ON COLUMN finance.financial_transactions.status IS
    'Draft transactions may be incomplete. Posted transactions must be balanced.';


-- ============================================================
-- 6. Financial transaction lines
-- ============================================================

CREATE TABLE finance.transaction_lines (
    transaction_line_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,

    company_id BIGINT NOT NULL,
    transaction_id BIGINT NOT NULL,

    line_number INTEGER NOT NULL,

    account_id BIGINT NOT NULL,
    cost_center_id BIGINT,

    branch_id BIGINT,
    department_id BIGINT,

    counterparty_person_id BIGINT,

    debit_amount NUMERIC(18, 4) NOT NULL DEFAULT 0,
    credit_amount NUMERIC(18, 4) NOT NULL DEFAULT 0,

    net_amount NUMERIC(18, 4)
        GENERATED ALWAYS AS (debit_amount - credit_amount) STORED,

    line_description TEXT,

    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),

    CONSTRAINT transaction_lines_transaction_fkey
        FOREIGN KEY (company_id, transaction_id)
        REFERENCES finance.financial_transactions (company_id, transaction_id)
        ON DELETE CASCADE,

    CONSTRAINT transaction_lines_account_fkey
        FOREIGN KEY (company_id, account_id)
        REFERENCES finance.accounts (company_id, account_id)
        ON DELETE RESTRICT,

    CONSTRAINT transaction_lines_cost_center_fkey
        FOREIGN KEY (company_id, cost_center_id)
        REFERENCES finance.cost_centers (company_id, cost_center_id)
        ON DELETE RESTRICT,

    CONSTRAINT transaction_lines_branch_fkey
        FOREIGN KEY (branch_id)
        REFERENCES core.branches (branch_id)
        ON DELETE RESTRICT,

    CONSTRAINT transaction_lines_department_fkey
        FOREIGN KEY (department_id)
        REFERENCES core.departments (department_id)
        ON DELETE RESTRICT,

    CONSTRAINT transaction_lines_counterparty_person_fkey
        FOREIGN KEY (counterparty_person_id)
        REFERENCES people.persons (person_id)
        ON DELETE SET NULL,

    CONSTRAINT transaction_lines_transaction_line_number_key
        UNIQUE (transaction_id, line_number),

    CONSTRAINT transaction_lines_line_number_chk
        CHECK (line_number > 0),

    CONSTRAINT transaction_lines_debit_nonnegative_chk
        CHECK (debit_amount >= 0),

    CONSTRAINT transaction_lines_credit_nonnegative_chk
        CHECK (credit_amount >= 0),

    CONSTRAINT transaction_lines_one_side_only_chk
        CHECK (
            (
                debit_amount > 0
                AND credit_amount = 0
            )
            OR
            (
                credit_amount > 0
                AND debit_amount = 0
            )
        )
);

COMMENT ON TABLE finance.transaction_lines IS
    'Double-entry transaction lines. Each line is either debit or credit, never both.';

COMMENT ON COLUMN finance.transaction_lines.net_amount IS
    'Debit amount minus credit amount. Positive means debit; negative means credit.';


-- ============================================================
-- 7. Balance enforcement for posted transactions
-- ============================================================

CREATE OR REPLACE FUNCTION finance.assert_posted_transaction_is_balanced()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
DECLARE
    transaction_ids BIGINT[];
    checked_transaction_id BIGINT;

    current_status TEXT;

    line_count BIGINT;
    debit_total NUMERIC(18, 4);
    credit_total NUMERIC(18, 4);
BEGIN
    IF TG_TABLE_NAME = 'financial_transactions' THEN
        transaction_ids := ARRAY[NEW.transaction_id];

    ELSIF TG_OP = 'DELETE' THEN
        transaction_ids := ARRAY[OLD.transaction_id];

    ELSIF TG_OP = 'UPDATE' THEN
        transaction_ids := ARRAY[OLD.transaction_id, NEW.transaction_id];

    ELSE
        transaction_ids := ARRAY[NEW.transaction_id];
    END IF;

    transaction_ids := ARRAY(
        SELECT DISTINCT u.transaction_id
        FROM unnest(transaction_ids) AS u(transaction_id)
        WHERE u.transaction_id IS NOT NULL
    );

    FOREACH checked_transaction_id IN ARRAY transaction_ids
    LOOP
        SELECT ft.status
        INTO current_status
        FROM finance.financial_transactions AS ft
        WHERE ft.transaction_id = checked_transaction_id;

        -- If the transaction header no longer exists, there is nothing to check.
        IF current_status IS NULL THEN
            CONTINUE;
        END IF;

        IF current_status = 'posted' THEN
            SELECT
                COUNT(*),
                COALESCE(SUM(tl.debit_amount), 0),
                COALESCE(SUM(tl.credit_amount), 0)
            INTO
                line_count,
                debit_total,
                credit_total
            FROM finance.transaction_lines AS tl
            WHERE tl.transaction_id = checked_transaction_id;

            IF line_count < 2 THEN
                RAISE EXCEPTION
                    'Posted transaction % must have at least two lines.',
                    checked_transaction_id;
            END IF;

            IF debit_total <> credit_total THEN
                RAISE EXCEPTION
                    'Posted transaction % is not balanced. Debit total: %, credit total: %.',
                    checked_transaction_id,
                    debit_total,
                    credit_total;
            END IF;
        END IF;
    END LOOP;

    IF TG_OP = 'DELETE' THEN
        RETURN OLD;
    ELSE
        RETURN NEW;
    END IF;
END;
$$;


CREATE CONSTRAINT TRIGGER financial_transactions_balance_check
AFTER INSERT OR UPDATE OF status
ON finance.financial_transactions
DEFERRABLE INITIALLY DEFERRED
FOR EACH ROW
EXECUTE FUNCTION finance.assert_posted_transaction_is_balanced();


CREATE CONSTRAINT TRIGGER transaction_lines_balance_check
AFTER INSERT OR UPDATE OR DELETE
ON finance.transaction_lines
DEFERRABLE INITIALLY DEFERRED
FOR EACH ROW
EXECUTE FUNCTION finance.assert_posted_transaction_is_balanced();


-- ============================================================
-- 8. Indexes
-- ============================================================

CREATE INDEX currencies_is_active_idx
    ON finance.currencies (is_active);

CREATE INDEX fiscal_periods_company_status_idx
    ON finance.fiscal_periods (company_id, period_status);

CREATE INDEX fiscal_periods_company_dates_idx
    ON finance.fiscal_periods (company_id, start_date, end_date);

CREATE INDEX cost_centers_company_parent_idx
    ON finance.cost_centers (company_id, parent_cost_center_id);

CREATE INDEX cost_centers_company_active_idx
    ON finance.cost_centers (company_id, is_active);

CREATE INDEX accounts_company_parent_idx
    ON finance.accounts (company_id, parent_account_id);

CREATE INDEX accounts_company_type_idx
    ON finance.accounts (company_id, account_type);

CREATE INDEX accounts_company_active_idx
    ON finance.accounts (company_id, is_active);

CREATE INDEX financial_transactions_company_date_idx
    ON finance.financial_transactions (company_id, transaction_date);

CREATE INDEX financial_transactions_company_period_idx
    ON finance.financial_transactions (company_id, fiscal_period_id);

CREATE INDEX financial_transactions_company_status_idx
    ON finance.financial_transactions (company_id, status);

CREATE INDEX financial_transactions_source_idx
    ON finance.financial_transactions (source_system, source_document_id);

CREATE INDEX transaction_lines_transaction_idx
    ON finance.transaction_lines (transaction_id);

CREATE INDEX transaction_lines_company_account_idx
    ON finance.transaction_lines (company_id, account_id);

CREATE INDEX transaction_lines_company_cost_center_idx
    ON finance.transaction_lines (company_id, cost_center_id);

CREATE INDEX transaction_lines_branch_idx
    ON finance.transaction_lines (branch_id);

CREATE INDEX transaction_lines_department_idx
    ON finance.transaction_lines (department_id);

CREATE INDEX transaction_lines_counterparty_person_idx
    ON finance.transaction_lines (counterparty_person_id);


COMMIT;