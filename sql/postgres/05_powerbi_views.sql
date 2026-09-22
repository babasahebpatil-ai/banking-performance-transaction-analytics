/*
Banking Performance & Transaction Analytics  |  PostgreSQL edition
05_powerbi_views.sql
Purpose: curated SQL views that Power BI (or any BI tool) can read.
*/

SET search_path TO banksphere, public;

CREATE OR REPLACE VIEW vw_loan_branch_performance AS
SELECT
    branch_name_x                                   AS branch_name,
    COUNT(*)                                        AS loan_records,
    COUNT(DISTINCT client_id)                       AS unique_clients,
    SUM(loan_amount)                                AS loan_amount,
    ROUND(AVG(loan_amount), 2)                      AS avg_loan_amount,
    SUM(total_rrec_int)                             AS recorded_interest_income,
    ROUND(100.0 * COUNT(*) FILTER (WHERE is_default_loan = 'Y') / COUNT(*), 2)     AS default_rate_pct,          -- legacy flag-based
    ROUND(100.0 * COUNT(*) FILTER (WHERE loan_status = 'Default') / COUNT(*), 2)   AS status_default_rate_pct,   -- recommended primary
    ROUND(100.0 * COUNT(*) FILTER (WHERE is_delinquent_loan = 'Y') / COUNT(*), 2)  AS delinquency_rate_pct,
    ROUND(100.0 * COUNT(*) FILTER (WHERE repayment_behavior = 'On-Time') / COUNT(*), 2) AS on_time_rate_pct
FROM final_fact_cleaned
GROUP BY branch_name_x;

CREATE OR REPLACE VIEW vw_loan_yearly_trend AS
SELECT
    EXTRACT(YEAR FROM disbursement_date)::INT AS loan_year,
    COUNT(*)                                  AS loan_records,
    COUNT(DISTINCT client_id)                 AS unique_clients,
    SUM(loan_amount)                          AS loan_amount,
    SUM(total_rrec_int)                       AS recorded_interest_income
FROM final_fact_cleaned
GROUP BY 1;

CREATE OR REPLACE VIEW vw_transaction_enriched AS
SELECT
    t.*,
    EXTRACT(YEAR    FROM t.transaction_date)::INT AS transaction_year,
    EXTRACT(MONTH   FROM t.transaction_date)::INT AS transaction_month_number,
    TO_CHAR(t.transaction_date, 'YYYY-MM')        AS month_key,
    EXTRACT(QUARTER FROM t.transaction_date)::INT AS transaction_quarter,
    CASE
        WHEN t.amount > p.numeric_value THEN 'Review'
        ELSE 'Standard'
    END AS high_value_review_flag
FROM credit_debit_bank t
JOIN analytics_parameters p
  ON p.parameter_name = 'high_value_review_threshold';

CREATE OR REPLACE VIEW vw_transaction_monthly AS
SELECT
    TO_CHAR(transaction_date, 'YYYY-MM')          AS month_key,
    COUNT(DISTINCT transaction_date)              AS days_with_data,
    days_in_month(MAX(transaction_date))          AS calendar_days_in_month,
    CASE
        WHEN COUNT(DISTINCT transaction_date) = days_in_month(MAX(transaction_date))
        THEN 'Complete'
        ELSE 'Review / Partial'
    END                                           AS period_status,
    COUNT(*)                                      AS transaction_count,
    ROUND(COUNT(*)::NUMERIC / COUNT(DISTINCT transaction_date), 1) AS avg_transactions_per_active_day,
    COALESCE(SUM(amount) FILTER (WHERE transaction_type = 'Credit'), 0) AS total_credit,
    COALESCE(SUM(amount) FILTER (WHERE transaction_type = 'Debit'), 0)  AS total_debit,
    SUM(CASE WHEN transaction_type = 'Credit' THEN amount ELSE -amount END) AS net_flow
FROM credit_debit_bank
GROUP BY 1;

CREATE OR REPLACE VIEW vw_transaction_branch_performance AS
SELECT
    t.bank_name,
    t.branch,
    COUNT(*)                        AS transaction_count,
    COUNT(DISTINCT t.customer_id)   AS unique_customers,
    COUNT(DISTINCT t.account_number) AS unique_accounts,
    SUM(t.amount)                   AS transaction_value,
    ROUND(AVG(t.amount), 2)         AS avg_transaction_amount,
    COUNT(*) FILTER (WHERE t.amount > p.numeric_value) AS high_value_review_count,
    ROUND(100.0 * COUNT(*) FILTER (WHERE t.amount > p.numeric_value) / COUNT(*), 2) AS high_value_review_rate_pct
FROM credit_debit_bank t
JOIN analytics_parameters p
  ON p.parameter_name = 'high_value_review_threshold'
GROUP BY t.bank_name, t.branch;
