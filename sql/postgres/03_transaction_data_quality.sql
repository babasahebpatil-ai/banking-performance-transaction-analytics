/*
Banking Performance & Transaction Analytics  |  PostgreSQL edition
03_transaction_data_quality.sql
Purpose: validate transaction records before reporting.
*/

SET search_path TO banksphere, public;

-- Q1. Dataset size and coverage.
SELECT
    COUNT(*)                        AS transaction_records,
    COUNT(DISTINCT customer_id)     AS unique_customers,
    COUNT(DISTINCT account_number)  AS unique_accounts,
    MIN(transaction_date)           AS first_transaction_date,
    MAX(transaction_date)           AS latest_transaction_date
FROM credit_debit_bank;

-- Q2. Critical NULL checks.
SELECT
    COUNT(*) FILTER (WHERE customer_id IS NULL OR TRIM(customer_id) = '')               AS null_customer_id,
    COUNT(*) FILTER (WHERE account_number IS NULL)                                      AS null_account_number,
    COUNT(*) FILTER (WHERE transaction_date IS NULL)                                    AS null_transaction_date,
    COUNT(*) FILTER (WHERE transaction_type IS NULL OR TRIM(transaction_type) = '')     AS null_transaction_type,
    COUNT(*) FILTER (WHERE amount IS NULL)                                              AS null_amount,
    COUNT(*) FILTER (WHERE branch IS NULL OR TRIM(branch) = '')                         AS null_branch,
    COUNT(*) FILTER (WHERE transaction_method IS NULL OR TRIM(transaction_method) = '') AS null_method,
    COUNT(*) FILTER (WHERE bank_name IS NULL OR TRIM(bank_name) = '')                   AS null_bank_name
FROM credit_debit_bank;

-- Q3. Potential exact duplicate records.
WITH ranked AS (
    SELECT
        ROW_NUMBER() OVER (
            PARTITION BY customer_id, account_number, transaction_date,
                         transaction_type, amount, balance, description,
                         branch, transaction_method, currency, bank_name
            ORDER BY customer_id
        ) AS duplicate_row_number
    FROM credit_debit_bank
)
SELECT COUNT(*) AS potential_duplicate_rows
FROM ranked
WHERE duplicate_row_number > 1;

-- Q4. Invalid/exception monetary values.
SELECT
    COUNT(*) FILTER (WHERE amount <= 0)  AS non_positive_amount_records,
    COUNT(*) FILTER (WHERE balance < 0)  AS negative_balance_records,
    MIN(amount)                          AS min_amount,
    MAX(amount)                          AS max_amount
FROM credit_debit_bank;

-- Q5. Validate transaction-type categories.
SELECT transaction_type, COUNT(*) AS records
FROM credit_debit_bank
GROUP BY transaction_type
ORDER BY records DESC;

-- Q6. Review currency values before aggregating amounts across currencies.
SELECT currency, COUNT(*) AS records, SUM(amount) AS amount
FROM credit_debit_bank
GROUP BY currency
ORDER BY records DESC;

-- Q7. Review bank/branch/method category cleanliness.
SELECT 'Bank' AS category_type, bank_name AS category_value, COUNT(*) AS records
FROM credit_debit_bank
GROUP BY bank_name
UNION ALL
SELECT 'Branch', branch, COUNT(*)
FROM credit_debit_bank
GROUP BY branch
UNION ALL
SELECT 'Transaction Method', transaction_method, COUNT(*)
FROM credit_debit_bank
GROUP BY transaction_method;

-- Q8. Month completeness check.
-- Prevents a partial month from being read as a full-month decline. (expect 2024-12 = Partial, 1 day)
SELECT
    TO_CHAR(transaction_date, 'YYYY-MM')            AS month_key,
    MIN(transaction_date)                           AS first_loaded_date,
    MAX(transaction_date)                           AS last_loaded_date,
    COUNT(DISTINCT transaction_date)                AS days_with_data,
    days_in_month(MAX(transaction_date))            AS calendar_days_in_month,
    CASE
        WHEN COUNT(DISTINCT transaction_date) = days_in_month(MAX(transaction_date))
        THEN 'Complete'
        ELSE 'Review / Partial'
    END                                             AS period_status,
    COUNT(*)                                        AS transaction_records
FROM credit_debit_bank
GROUP BY 1
ORDER BY month_key;

-- Q9. Account-to-customer mapping check.
-- NOTE: returns zero rows on the current data, but for a misleading reason: every account and
-- customer appears only once. See 07_consistency_checks.sql Q4.
SELECT
    account_number,
    COUNT(DISTINCT customer_id) AS distinct_customers
FROM credit_debit_bank
GROUP BY account_number
HAVING COUNT(DISTINCT customer_id) > 1
ORDER BY distinct_customers DESC, account_number;

-- Q10. High-value review rule reconciliation.  (expect 10,428 rows = 10.43%)
SELECT
    p.numeric_value                                              AS high_value_review_threshold,
    COUNT(*)                                                     AS flagged_transactions,
    ROUND(100.0 * COUNT(*) / (SELECT COUNT(*) FROM credit_debit_bank), 2) AS flagged_share_pct
FROM credit_debit_bank t
CROSS JOIN analytics_parameters p
WHERE p.parameter_name = 'high_value_review_threshold'
  AND t.amount > p.numeric_value
GROUP BY p.numeric_value;
