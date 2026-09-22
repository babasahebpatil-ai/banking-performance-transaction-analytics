/*
Banking Performance & Transaction Analytics  |  PostgreSQL edition
00_setup.sql
Target: PostgreSQL 13+ (tested on 16)

What this script does
  1. creates a schema called banksphere (Postgres has no "USE database")
  2. creates the two source tables (all column names are lowercase snake_case)
  3. creates a small parameter table and a helper function
Then load the CSV files with 00b_load_data_psql.sql (psql) or pgAdmin's Import tool.
*/

CREATE SCHEMA IF NOT EXISTS banksphere;
SET search_path TO banksphere, public;      -- every script starts with this line

-- ---------------------------------------------------------------------------
-- Source table 1: loan portfolio (2,000 rows)
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS final_fact_cleaned (
    account_id                   TEXT PRIMARY KEY,
    client_id                    INTEGER,
    branch_name_x                TEXT,
    product_id                   TEXT,
    loan_amount                  NUMERIC(14,2),
    funded_amount                NUMERIC(14,2),
    funded_amount_inv            NUMERIC(14,2),
    disbursement_date            DATE,
    loan_status                  TEXT,
    repayment_type               TEXT,
    center_id_x                  BIGINT,
    branchid                     TEXT,
    client_name                  TEXT,
    gender_id                    TEXT,
    age                          TEXT,
    age_t                        INTEGER,
    dateof_birth                 DATE,
    caste                        TEXT,
    religion                     TEXT,
    home_ownership               TEXT,
    client_income_range          TEXT,
    employment_type              TEXT,
    credit_score                 INTEGER,
    product_code                 TEXT,
    purpose_category             TEXT,
    term                         TEXT,
    int_rate                     NUMERIC(8,4),
    grade                        TEXT,
    sub_grade                    TEXT,
    branch_name_y                TEXT,
    bank_name                    TEXT,
    region_name                  TEXT,
    state_abbr                   TEXT,
    state_abbr_1                 TEXT,
    state_name                   TEXT,
    city                         TEXT,
    center_id_y                  BIGINT,
    bh_name                      TEXT,
    branch_performance_category  TEXT,
    total_pymnt                  NUMERIC(14,2),
    total_pymnt_inv              NUMERIC(14,2),
    total_rec_prncp              NUMERIC(14,2),
    total_fees                   NUMERIC(14,2),
    total_rrec_int               NUMERIC(14,2),
    is_delinquent_loan           CHAR(1),
    is_default_loan              CHAR(1),
    delinq_2_yrs                 INTEGER,
    repayment_behavior           TEXT,
    default_flag                 SMALLINT,
    delinquent_flag              SMALLINT,
    loan_count                   INTEGER,
    first_disbursement_date      DATE,
    new_client_flag              SMALLINT,
    month_year                   TEXT
);

-- ---------------------------------------------------------------------------
-- Source table 2: credit / debit transactions (100,000 rows)
-- The workbook's 3 empty trailing columns are NOT part of this table.
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS credit_debit_bank (
    customer_id         TEXT,
    customer_name       TEXT,
    account_number      BIGINT,
    transaction_date    DATE,
    transaction_type    TEXT,
    amount              NUMERIC(12,2),
    balance             NUMERIC(14,2),
    description         TEXT,
    branch              TEXT,
    transaction_method  TEXT,
    currency            TEXT,
    bank_name           TEXT,
    high_risk_flag      TEXT,      -- legacy flag in the workbook (>= 4,000); reconciliation only
    high_risk_count     SMALLINT   -- legacy 0/1 count of the same flag
);

-- ---------------------------------------------------------------------------
-- Governed business parameters (one place instead of hard-coded numbers)
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS analytics_parameters (
    parameter_name  TEXT PRIMARY KEY,
    numeric_value   NUMERIC(18,2),
    text_value      TEXT,
    updated_at      TIMESTAMPTZ DEFAULT now()
);

-- "UPSERT": insert, or update if the key already exists  (MySQL: ON DUPLICATE KEY UPDATE)
INSERT INTO analytics_parameters (parameter_name, numeric_value, text_value)
VALUES ('high_value_review_threshold', 4500, 'Transaction amount threshold used for manual review screening')
ON CONFLICT (parameter_name) DO UPDATE
SET numeric_value = EXCLUDED.numeric_value,
    text_value    = EXCLUDED.text_value,
    updated_at    = now();

-- The source workbook's own 'High-Risk Flag' uses a LOWER cut-off (4,000) than the governed
-- 4,500 rule. Stored only so 07_consistency_checks.sql can reconcile the two.
INSERT INTO analytics_parameters (parameter_name, numeric_value, text_value)
VALUES ('source_flag_threshold', 4000, 'Cut-off implied by the legacy High-Risk Flag column (reconciliation only)')
ON CONFLICT (parameter_name) DO UPDATE
SET numeric_value = EXCLUDED.numeric_value,
    text_value    = EXCLUDED.text_value,
    updated_at    = now();

-- ---------------------------------------------------------------------------
-- Helper function: number of days in the month of a given date.
-- (MySQL has DAY(LAST_DAY(x)); Postgres does not, so we define our own.)
-- Used by the period-completeness checks.
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION days_in_month(d DATE)
RETURNS INTEGER
LANGUAGE SQL IMMUTABLE AS $$
    SELECT EXTRACT(DAY FROM (date_trunc('month', d) + INTERVAL '1 month - 1 day'))::INTEGER;
$$;

-- Quick availability checks (run AFTER loading the data)
-- SELECT COUNT(*) AS loan_rows        FROM final_fact_cleaned;   -- expect 2,000
-- SELECT COUNT(*) AS transaction_rows FROM credit_debit_bank;    -- expect 100,000
