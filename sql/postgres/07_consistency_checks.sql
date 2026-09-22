/*
Banking Performance & Transaction Analytics  |  PostgreSQL edition
07_consistency_checks.sql
Purpose: quantify the source-data conflicts that affect KPI definitions.
Every result is documented in reports/data_quality_report.md.
Expected values are for the supplied workbooks.
*/

SET search_path TO banksphere, public;

-- ---------------------------------------------------------------------------
-- LOAN MODULE
-- ---------------------------------------------------------------------------

-- Q1. Default definitions: loan_status vs is_default_loan flag.
-- Expected: 206 loans have status 'Default', only 100 carry flag 'Y', and just 10 are in both.
SELECT
    loan_status,
    COUNT(*) FILTER (WHERE is_default_loan = 'Y')  AS flagged_default,
    COUNT(*) FILTER (WHERE is_default_loan = 'N')  AS not_flagged_default,
    COUNT(*)                                       AS loan_records,
    ROUND(100.0 * COUNT(*) FILTER (WHERE is_default_loan = 'Y') / COUNT(*), 2) AS pct_flagged
FROM final_fact_cleaned
GROUP BY loan_status
ORDER BY loan_records DESC;

-- Q2. Delinquency definitions: is_delinquent_loan flag vs repayment_behavior.
-- Expected: 'Very Late' has 207 loans but only 29 are flagged delinquent,
-- while 147 loans with 'On-Time' behaviour ARE flagged delinquent.
SELECT
    repayment_behavior,
    COUNT(*) FILTER (WHERE is_delinquent_loan = 'Y') AS flagged_delinquent,
    COUNT(*) FILTER (WHERE is_delinquent_loan = 'N') AS not_flagged,
    COUNT(*)                                         AS loan_records
FROM final_fact_cleaned
GROUP BY repayment_behavior
ORDER BY loan_records DESC;

-- Q3. Overlapping loan-status labels ('Fully Paid' vs 'Paid Off').
-- Expected: 787 vs 605. Confirm with the data owner whether these are one category.
SELECT
    loan_status,
    COUNT(*) AS loan_records,
    ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 2) AS share_pct
FROM final_fact_cleaned
GROUP BY loan_status
ORDER BY loan_records DESC;

-- Q3b. Payment-field integrity.
-- Expected: 185 loans have recovered principal greater than total payment;
-- about half of loans (991) have funded_amount above loan_amount.
SELECT
    COUNT(*) FILTER (WHERE total_rec_prncp > total_pymnt)      AS recovered_principal_exceeds_payment,
    COUNT(*) FILTER (WHERE funded_amount > loan_amount)        AS funded_exceeds_loan_amount,
    ROUND(100.0 * COUNT(*) FILTER (WHERE funded_amount > loan_amount) / COUNT(*), 2) AS funded_exceeds_loan_pct,
    COUNT(*) FILTER (WHERE funded_amount_inv > funded_amount)  AS invested_exceeds_funded
FROM final_fact_cleaned;

-- Q3c. Funded-field labelling check.
-- Expected: funded_amount ~ 52.36M (equals loan value); funded_amount_inv ~ 46.72M.
-- The legacy dashboard card "Funded Amount 47M" therefore shows the INVESTED field.
SELECT
    SUM(loan_amount)        AS total_loan_amount,
    SUM(funded_amount)      AS total_funded_amount,
    SUM(funded_amount_inv)  AS total_funded_amount_inv
FROM final_fact_cleaned;

-- ---------------------------------------------------------------------------
-- TRANSACTION MODULE
-- ---------------------------------------------------------------------------

-- Q4. Grain check: how many transactions does each customer / account have?
-- Expected: max_txn_per_customer = 1 and max_txn_per_account = 1.
-- Consequence: retention, customer segmentation, top-customer and per-account KPIs
-- cannot describe behaviour over time on this dataset.
WITH per_customer AS (
    SELECT customer_id, COUNT(*) AS txn_count FROM credit_debit_bank GROUP BY customer_id
),
per_account AS (
    SELECT account_number, COUNT(*) AS txn_count FROM credit_debit_bank GROUP BY account_number
)
SELECT
    (SELECT COUNT(*)       FROM credit_debit_bank) AS transaction_rows,
    (SELECT COUNT(*)       FROM per_customer)      AS distinct_customers,
    (SELECT COUNT(*)       FROM per_account)       AS distinct_accounts,
    (SELECT MAX(txn_count) FROM per_customer)      AS max_txn_per_customer,
    (SELECT MAX(txn_count) FROM per_account)       AS max_txn_per_account;

-- Q5. High-value rule reconciliation: governed threshold vs legacy source flag.
-- Expected: governed (> 4,500) = 10,428 rows; source flag (> 4,000) = 20,426 rows.
SELECT
    COUNT(*) FILTER (WHERE t.amount > gov.numeric_value) AS governed_review_count,
    COUNT(*) FILTER (WHERE t.amount > src.numeric_value) AS legacy_source_flag_count,
    COUNT(*) FILTER (WHERE t.amount > src.numeric_value AND t.amount <= gov.numeric_value) AS flagged_only_by_legacy_rule,
    ROUND(100.0 * COUNT(*) FILTER (WHERE t.amount > gov.numeric_value) / COUNT(*), 2) AS governed_share_pct,
    ROUND(100.0 * COUNT(*) FILTER (WHERE t.amount > src.numeric_value) / COUNT(*), 2) AS legacy_share_pct
FROM credit_debit_bank t
JOIN analytics_parameters gov ON gov.parameter_name = 'high_value_review_threshold'
JOIN analytics_parameters src ON src.parameter_name = 'source_flag_threshold';

-- Q6. Calendar-length effect in monthly volume.
-- Monthly counts differ mainly because months have different numbers of days.
-- Expected: avg_transactions_per_active_day stays within ~292-301 for all complete months.
SELECT
    TO_CHAR(transaction_date, 'YYYY-MM')                       AS month_key,
    COUNT(DISTINCT transaction_date)                           AS days_with_data,
    COUNT(*)                                                   AS transaction_count,
    ROUND(COUNT(*)::NUMERIC / COUNT(DISTINCT transaction_date), 1) AS avg_transactions_per_active_day,
    CASE WHEN COUNT(DISTINCT transaction_date) = days_in_month(MAX(transaction_date))
         THEN 'Complete' ELSE 'Partial - exclude from trend' END AS period_status
FROM credit_debit_bank
GROUP BY 1
ORDER BY month_key;
