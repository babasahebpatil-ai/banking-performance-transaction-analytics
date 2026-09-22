/*
Banking Performance & Transaction Analytics
04_transaction_kpi_analysis.sql
Purpose: transaction KPIs, trends, rankings and review analytics.
*/

USE banksphere_intelligence;

-- Q1. Executive transaction summary.
SELECT
    COUNT(*) AS transaction_count,
    COUNT(DISTINCT Customer_ID) AS unique_customers,
    COUNT(DISTINCT Account_Number) AS unique_accounts,
    SUM(CASE WHEN Transaction_Type = 'Credit' THEN Amount ELSE 0 END) AS total_credit,
    SUM(CASE WHEN Transaction_Type = 'Debit' THEN Amount ELSE 0 END) AS total_debit,
    SUM(CASE WHEN Transaction_Type = 'Credit' THEN Amount ELSE -Amount END) AS net_flow,
    ROUND(
        SUM(CASE WHEN Transaction_Type = 'Credit' THEN Amount ELSE 0 END)
        / NULLIF(SUM(CASE WHEN Transaction_Type = 'Debit' THEN Amount ELSE 0 END), 0),
        4
    ) AS credit_to_debit_ratio,
    AVG(Amount) AS avg_transaction_amount,
    ROUND(COUNT(*) / NULLIF(COUNT(DISTINCT Account_Number), 0), 2) AS transactions_per_account -- = 1.00 in this dataset (one row per account)
FROM credit_debit_bank;

-- Q2. Daily activity.
SELECT
    Transaction_Date,
    COUNT(*) AS transaction_count,
    SUM(Amount) AS transaction_value,
    AVG(Amount) AS avg_transaction_amount
FROM credit_debit_bank
GROUP BY Transaction_Date
ORDER BY Transaction_Date;

-- Q3. Weekly activity using ISO-style week key.
SELECT
    YEARWEEK(Transaction_Date, 3) AS year_week,
    COUNT(*) AS transaction_count,
    SUM(Amount) AS transaction_value
FROM credit_debit_bank
GROUP BY YEARWEEK(Transaction_Date, 3)
ORDER BY year_week;

-- Q4. Monthly credit/debit performance with completeness flag.
WITH monthly AS (
    SELECT
        DATE_FORMAT(Transaction_Date, '%Y-%m') AS month_key,
        COUNT(DISTINCT Transaction_Date) AS days_with_data,
        DAY(LAST_DAY(MAX(Transaction_Date))) AS days_in_month,
        COUNT(*) AS transaction_count,
        SUM(CASE WHEN Transaction_Type = 'Credit' THEN Amount ELSE 0 END) AS total_credit,
        SUM(CASE WHEN Transaction_Type = 'Debit' THEN Amount ELSE 0 END) AS total_debit
    FROM credit_debit_bank
    GROUP BY DATE_FORMAT(Transaction_Date, '%Y-%m')
)
SELECT
    month_key,
    transaction_count,
    total_credit,
    total_debit,
    total_credit - total_debit AS net_flow,
    CASE WHEN days_with_data = days_in_month THEN 'Complete' ELSE 'Review / Partial' END AS period_status
FROM monthly
ORDER BY month_key;

-- Q5. Transaction-method mix by count and value.
SELECT
    Transaction_Method,
    COUNT(*) AS transaction_count,
    SUM(Amount) AS transaction_value,
    AVG(Amount) AS avg_transaction_amount,
    ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 2) AS count_share_pct,
    ROUND(100.0 * SUM(Amount) / SUM(SUM(Amount)) OVER (), 2) AS value_share_pct
FROM credit_debit_bank
GROUP BY Transaction_Method
ORDER BY transaction_value DESC;

-- Q6. Bank performance scorecard.
WITH bank_metrics AS (
    SELECT
        Bank_Name,
        COUNT(*) AS transaction_count,
        COUNT(DISTINCT Customer_ID) AS unique_customers,
        COUNT(DISTINCT Account_Number) AS unique_accounts,
        SUM(Amount) AS transaction_value,
        AVG(Amount) AS avg_transaction_amount,
        SUM(CASE WHEN Transaction_Type = 'Credit' THEN Amount ELSE 0 END) AS total_credit,
        SUM(CASE WHEN Transaction_Type = 'Debit' THEN Amount ELSE 0 END) AS total_debit
    FROM credit_debit_bank
    GROUP BY Bank_Name
)
SELECT
    *,
    total_credit - total_debit AS net_flow,
    DENSE_RANK() OVER (ORDER BY transaction_value DESC) AS value_rank
FROM bank_metrics
ORDER BY value_rank, Bank_Name;

-- Q7. Branch scorecard with contribution share.
SELECT
    Branch,
    COUNT(*) AS transaction_count,
    COUNT(DISTINCT Customer_ID) AS unique_customers,
    SUM(Amount) AS transaction_value,
    AVG(Amount) AS avg_transaction_amount,
    ROUND(100.0 * SUM(Amount) / SUM(SUM(Amount)) OVER (), 2) AS value_share_pct,
    DENSE_RANK() OVER (ORDER BY SUM(Amount) DESC) AS value_rank
FROM credit_debit_bank
GROUP BY Branch
ORDER BY value_rank, Branch;

-- Q8. Branch month-over-month growth.
WITH monthly_branch AS (
    SELECT
        Branch,
        DATE_FORMAT(Transaction_Date, '%Y-%m') AS month_key,
        COUNT(DISTINCT Transaction_Date) AS days_with_data,
        DAY(LAST_DAY(MAX(Transaction_Date))) AS days_in_month,
        SUM(Amount) AS transaction_value
    FROM credit_debit_bank
    GROUP BY Branch, DATE_FORMAT(Transaction_Date, '%Y-%m')
),
complete_months AS (
    SELECT *
    FROM monthly_branch
    WHERE days_with_data = days_in_month
),
with_prev AS (
    SELECT
        Branch,
        month_key,
        transaction_value,
        LAG(transaction_value) OVER (PARTITION BY Branch ORDER BY month_key) AS previous_month_value
    FROM complete_months
)
SELECT
    Branch,
    month_key,
    transaction_value,
    previous_month_value,
    ROUND(100.0 * (transaction_value - previous_month_value) / NULLIF(previous_month_value, 0), 2) AS mom_growth_pct
FROM with_prev
ORDER BY Branch, month_key;

-- Q9. Rolling 3-month total and average transaction value.
WITH monthly AS (
    SELECT
        DATE_FORMAT(Transaction_Date, '%Y-%m') AS month_key,
        SUM(Amount) AS transaction_value
    FROM credit_debit_bank
    GROUP BY DATE_FORMAT(Transaction_Date, '%Y-%m')
)
SELECT
    month_key,
    transaction_value,
    SUM(transaction_value) OVER (
        ORDER BY month_key ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
    ) AS rolling_3_month_value,
    ROUND(AVG(transaction_value) OVER (
        ORDER BY month_key ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
    ), 2) AS rolling_3_month_avg
FROM monthly
ORDER BY month_key;

-- Q10. Top customers by transaction value.
-- DATA LIMITATION: in the current dataset every Customer_ID has exactly ONE transaction
-- (100,000 rows = 100,000 customers = 100,000 accounts; see 07_consistency_checks.sql Q4).
-- This ranking is therefore a ranking of single transactions, not of customer behaviour.
-- It becomes meaningful only when the source has multiple transactions per customer.
WITH customer_metrics AS (
    SELECT
        Customer_ID,
        MAX(Customer_Name) AS customer_name,
        COUNT(*) AS transaction_count,
        SUM(Amount) AS transaction_value,
        AVG(Amount) AS avg_transaction_amount
    FROM credit_debit_bank
    GROUP BY Customer_ID
)
SELECT
    *,
    DENSE_RANK() OVER (ORDER BY transaction_value DESC) AS customer_value_rank
FROM customer_metrics
ORDER BY customer_value_rank
LIMIT 50;

-- Q11. Customer activity segmentation.
-- DATA LIMITATION: with one transaction per customer, transaction_count is 1 for everyone,
-- so NTILE() splits identical values arbitrarily and the segments carry NO information.
-- Kept as a reusable pattern for a production dataset; do not report its output as findings.
WITH customer_metrics AS (
    SELECT
        Customer_ID,
        COUNT(*) AS transaction_count,
        SUM(Amount) AS transaction_value
    FROM credit_debit_bank
    GROUP BY Customer_ID
),
segmented AS (
    SELECT
        *,
        NTILE(4) OVER (ORDER BY transaction_count) AS activity_quartile
    FROM customer_metrics
)
SELECT
    CASE activity_quartile
        WHEN 4 THEN 'Very High Activity'
        WHEN 3 THEN 'High Activity'
        WHEN 2 THEN 'Moderate Activity'
        ELSE 'Low Activity'
    END AS activity_segment,
    COUNT(*) AS customers,
    AVG(transaction_count) AS avg_transactions,
    AVG(transaction_value) AS avg_transaction_value
FROM segmented
GROUP BY activity_quartile
ORDER BY activity_quartile DESC;

-- Q12. Governed high-value review count and share.
SELECT
    p.numeric_value AS review_threshold,
    COUNT(*) AS high_value_review_count,
    SUM(t.Amount) AS high_value_review_amount,
    ROUND(100.0 * COUNT(*) / (SELECT COUNT(*) FROM credit_debit_bank), 2) AS transaction_share_pct,
    ROUND(100.0 * SUM(t.Amount) / (SELECT SUM(Amount) FROM credit_debit_bank), 2) AS value_share_pct
FROM credit_debit_bank t
CROSS JOIN analytics_parameters p
WHERE p.parameter_name = 'high_value_review_threshold'
  AND t.Amount > p.numeric_value
GROUP BY p.numeric_value;

-- Q13. High-value review concentration by description.
SELECT
    t.Description,
    COUNT(*) AS high_value_review_count,
    SUM(t.Amount) AS high_value_review_amount,
    AVG(t.Amount) AS avg_high_value_amount
FROM credit_debit_bank t
JOIN analytics_parameters p
  ON p.parameter_name = 'high_value_review_threshold'
WHERE t.Amount > p.numeric_value
GROUP BY t.Description
ORDER BY high_value_review_count DESC, high_value_review_amount DESC;

-- Q14. High-value review concentration by bank and branch.
SELECT
    t.Bank_Name,
    t.Branch,
    COUNT(*) AS transaction_count,
    SUM(CASE WHEN t.Amount > p.numeric_value THEN 1 ELSE 0 END) AS high_value_review_count,
    ROUND(
        100.0 * SUM(CASE WHEN t.Amount > p.numeric_value THEN 1 ELSE 0 END) / COUNT(*),
        2
    ) AS high_value_review_rate_pct,
    SUM(t.Amount) AS transaction_value
FROM credit_debit_bank t
JOIN analytics_parameters p
  ON p.parameter_name = 'high_value_review_threshold'
GROUP BY t.Bank_Name, t.Branch
ORDER BY high_value_review_rate_pct DESC, transaction_value DESC;

-- Q15. Largest individual transactions for manual review.
SELECT
    Customer_ID,
    Customer_Name,
    Account_Number,
    Transaction_Date,
    Transaction_Type,
    Amount,
    Description,
    Branch,
    Bank_Name,
    Transaction_Method
FROM credit_debit_bank
ORDER BY Amount DESC
LIMIT 100;
