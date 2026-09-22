/*
Banking Performance & Transaction Analytics  |  PostgreSQL edition
06_reconciliation_queries.sql
Purpose: one-row checks to compare with Excel and Power BI cards.
*/

SET search_path TO banksphere, public;

-- Loan KPI reconciliation output.
SELECT
    COUNT(*)                                                        AS loan_records,          -- 2,000
    COUNT(DISTINCT client_id)                                       AS unique_clients,        -- 870
    COUNT(DISTINCT client_id) FILTER (WHERE loan_status = 'Active') AS active_clients,        -- 324
    ROUND(SUM(loan_amount), 2)                                      AS total_loan_amount,     -- 52,361,121
    ROUND(SUM(funded_amount), 2)                                    AS total_funded_amount,   -- 52,361,094
    ROUND(SUM(funded_amount_inv), 2)                                AS invested_funded_amount,-- 46,719,384
    ROUND(AVG(loan_amount), 2)                                      AS avg_loan_amount,       -- 26,180.56
    ROUND(SUM(total_rrec_int), 2)                                   AS recorded_interest_income, -- 5,055,223.46
    ROUND(100.0 * SUM(total_rec_prncp) / NULLIF(SUM(loan_amount), 0), 2)                 AS principal_recovery_rate_pct, -- 99.05
    ROUND(100.0 * COUNT(*) FILTER (WHERE is_default_loan = 'Y') / COUNT(*), 2)           AS default_flag_rate_pct,       -- 5.00
    ROUND(100.0 * COUNT(*) FILTER (WHERE loan_status = 'Default') / COUNT(*), 2)         AS status_default_rate_pct,     -- 10.30
    ROUND(100.0 * COUNT(*) FILTER (WHERE is_delinquent_loan = 'Y') / COUNT(*), 2)        AS delinquency_rate_pct,        -- 10.35
    ROUND(100.0 * COUNT(*) FILTER (WHERE repayment_behavior = 'On-Time') / COUNT(*), 2)  AS on_time_repayment_rate_pct   -- 71.05
FROM final_fact_cleaned;

-- Transaction KPI reconciliation output.
SELECT
    COUNT(*)                                                    AS transaction_count,        -- 100,000
    COUNT(DISTINCT customer_id)                                 AS unique_customers,         -- 100,000
    COUNT(DISTINCT account_number)                              AS unique_accounts,          -- 100,000
    ROUND(SUM(amount) FILTER (WHERE transaction_type = 'Credit'), 2) AS total_credit,        -- ~127.60M
    ROUND(SUM(amount) FILTER (WHERE transaction_type = 'Debit'), 2)  AS total_debit,         -- ~127.29M
    ROUND(SUM(CASE WHEN transaction_type = 'Credit' THEN amount ELSE -amount END), 2) AS net_flow,  -- ~318K
    ROUND(COUNT(*)::NUMERIC / NULLIF(COUNT(DISTINCT account_number), 0), 2) AS transactions_per_account, -- 1.00
    COUNT(*) FILTER (WHERE amount > (
        SELECT numeric_value FROM analytics_parameters
        WHERE parameter_name = 'high_value_review_threshold'
    ))                                                          AS high_value_review_count,  -- governed rule (4,500) -> 10,428
    COUNT(*) FILTER (WHERE amount > (
        SELECT numeric_value FROM analytics_parameters
        WHERE parameter_name = 'source_flag_threshold'
    ))                                                          AS legacy_source_flag_count  -- source flag (4,000)   -> 20,426
FROM credit_debit_bank;

-- Monthly completeness for BI trend validation.
SELECT
    TO_CHAR(transaction_date, 'YYYY-MM')   AS month_key,
    COUNT(DISTINCT transaction_date)       AS days_with_data,
    days_in_month(MAX(transaction_date))   AS calendar_days_in_month,
    CASE
        WHEN COUNT(DISTINCT transaction_date) = days_in_month(MAX(transaction_date))
        THEN 'Complete'
        ELSE 'Review / Partial'
    END                                    AS period_status
FROM credit_debit_bank
GROUP BY 1
ORDER BY month_key;
