/*
Banking Performance & Transaction Analytics  |  PostgreSQL edition
04_transaction_kpi_analysis.sql
Purpose: transaction KPIs, trends, rankings and review analytics.
*/

SET search_path TO banksphere, public;

-- Q1. Executive transaction summary.
-- Careful: in Postgres, integer / integer is INTEGER division (7/2 = 3). Cast one side to NUMERIC.
SELECT
    COUNT(*)                        AS transaction_count,
    COUNT(DISTINCT customer_id)     AS unique_customers,
    COUNT(DISTINCT account_number)  AS unique_accounts,
    SUM(amount) FILTER (WHERE transaction_type = 'Credit')  AS total_credit,
    SUM(amount) FILTER (WHERE transaction_type = 'Debit')   AS total_debit,
    SUM(CASE WHEN transaction_type = 'Credit' THEN amount ELSE -amount END) AS net_flow,
    ROUND(
        SUM(amount) FILTER (WHERE transaction_type = 'Credit')
        / NULLIF(SUM(amount) FILTER (WHERE transaction_type = 'Debit'), 0),
        4
    ) AS credit_to_debit_ratio,
    ROUND(AVG(amount), 2) AS avg_transaction_amount,
    ROUND(COUNT(*)::NUMERIC / NULLIF(COUNT(DISTINCT account_number), 0), 2) AS transactions_per_account -- = 1.00 here (one row per account)
FROM credit_debit_bank;

-- Q2. Daily activity.
SELECT
    transaction_date,
    COUNT(*)                 AS transaction_count,
    SUM(amount)              AS transaction_value,
    ROUND(AVG(amount), 2)    AS avg_transaction_amount
FROM credit_debit_bank
GROUP BY transaction_date
ORDER BY transaction_date;

-- Q3. Weekly activity using an ISO week key (MySQL: YEARWEEK(date, 3)).
SELECT
    TO_CHAR(transaction_date, 'IYYY-"W"IW') AS iso_year_week,
    COUNT(*)                                AS transaction_count,
    SUM(amount)                             AS transaction_value
FROM credit_debit_bank
GROUP BY 1
ORDER BY iso_year_week;

-- Q4. Monthly credit/debit performance with completeness flag.
-- In Postgres you may GROUP BY an output alias or position (GROUP BY 1).
WITH monthly AS (
    SELECT
        TO_CHAR(transaction_date, 'YYYY-MM')          AS month_key,
        COUNT(DISTINCT transaction_date)              AS days_with_data,
        days_in_month(MAX(transaction_date))          AS calendar_days,
        COUNT(*)                                      AS transaction_count,
        SUM(amount) FILTER (WHERE transaction_type = 'Credit') AS total_credit,
        SUM(amount) FILTER (WHERE transaction_type = 'Debit')  AS total_debit
    FROM credit_debit_bank
    GROUP BY 1
)
SELECT
    month_key,
    transaction_count,
    ROUND(transaction_count::NUMERIC / days_with_data, 1) AS avg_transactions_per_active_day,
    total_credit,
    total_debit,
    total_credit - total_debit AS net_flow,
    CASE WHEN days_with_data = calendar_days THEN 'Complete' ELSE 'Review / Partial' END AS period_status
FROM monthly
ORDER BY month_key;

-- Q5. Transaction-method mix by count and value.
SELECT
    transaction_method,
    COUNT(*)                  AS transaction_count,
    SUM(amount)               AS transaction_value,
    ROUND(AVG(amount), 2)     AS avg_transaction_amount,
    ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 2)       AS count_share_pct,
    ROUND(100.0 * SUM(amount) / SUM(SUM(amount)) OVER (), 2) AS value_share_pct
FROM credit_debit_bank
GROUP BY transaction_method
ORDER BY transaction_value DESC;

-- Q6. Bank performance scorecard.
WITH bank_metrics AS (
    SELECT
        bank_name,
        COUNT(*)                        AS transaction_count,
        COUNT(DISTINCT customer_id)     AS unique_customers,
        COUNT(DISTINCT account_number)  AS unique_accounts,
        SUM(amount)                     AS transaction_value,
        ROUND(AVG(amount), 2)           AS avg_transaction_amount,
        SUM(amount) FILTER (WHERE transaction_type = 'Credit') AS total_credit,
        SUM(amount) FILTER (WHERE transaction_type = 'Debit')  AS total_debit
    FROM credit_debit_bank
    GROUP BY bank_name
)
SELECT
    *,
    total_credit - total_debit                    AS net_flow,
    DENSE_RANK() OVER (ORDER BY transaction_value DESC) AS value_rank
FROM bank_metrics
ORDER BY value_rank, bank_name;

-- Q7. Branch scorecard with contribution share.
SELECT
    branch,
    COUNT(*)                       AS transaction_count,
    COUNT(DISTINCT customer_id)    AS unique_customers,
    SUM(amount)                    AS transaction_value,
    ROUND(AVG(amount), 2)          AS avg_transaction_amount,
    ROUND(100.0 * SUM(amount) / SUM(SUM(amount)) OVER (), 2) AS value_share_pct,
    DENSE_RANK() OVER (ORDER BY SUM(amount) DESC)            AS value_rank
FROM credit_debit_bank
GROUP BY branch
ORDER BY value_rank, branch;

-- Q8. Branch month-over-month growth (complete months only).
-- NOTE: raw monthly totals differ mostly because months have different lengths (28-31 days).
-- Treat this as a technique demo; see 07 Q6 and reports/key_findings.md.
WITH monthly_branch AS (
    SELECT
        branch,
        TO_CHAR(transaction_date, 'YYYY-MM')   AS month_key,
        COUNT(DISTINCT transaction_date)       AS days_with_data,
        days_in_month(MAX(transaction_date))   AS calendar_days,
        SUM(amount)                            AS transaction_value
    FROM credit_debit_bank
    GROUP BY branch, month_key
),
complete_months AS (
    SELECT *
    FROM monthly_branch
    WHERE days_with_data = calendar_days
),
with_prev AS (
    SELECT
        branch,
        month_key,
        transaction_value,
        LAG(transaction_value) OVER (PARTITION BY branch ORDER BY month_key) AS previous_month_value
    FROM complete_months
)
SELECT
    branch,
    month_key,
    transaction_value,
    previous_month_value,
    ROUND(100.0 * (transaction_value - previous_month_value) / NULLIF(previous_month_value, 0), 2) AS mom_growth_pct
FROM with_prev
ORDER BY branch, month_key;

-- Q9. Rolling 3-month total and average transaction value.
WITH monthly AS (
    SELECT
        TO_CHAR(transaction_date, 'YYYY-MM') AS month_key,
        SUM(amount)                          AS transaction_value
    FROM credit_debit_bank
    GROUP BY 1
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
-- DATA LIMITATION: every customer_id has exactly ONE transaction (see 07 Q4). This is a ranking
-- of single transactions, not of customer behaviour.
WITH customer_metrics AS (
    SELECT
        customer_id,
        MAX(customer_name)          AS customer_name,
        COUNT(*)                    AS transaction_count,
        SUM(amount)                 AS transaction_value,
        ROUND(AVG(amount), 2)       AS avg_transaction_amount
    FROM credit_debit_bank
    GROUP BY customer_id
)
SELECT
    *,
    DENSE_RANK() OVER (ORDER BY transaction_value DESC) AS customer_value_rank
FROM customer_metrics
ORDER BY customer_value_rank
LIMIT 50;

-- Q11. Customer activity segmentation.
-- DATA LIMITATION: with one transaction per customer, transaction_count is 1 for everyone, so
-- NTILE() splits identical values arbitrarily and the segments carry NO information.
-- Kept as a reusable pattern; do not report its output as findings.
WITH customer_metrics AS (
    SELECT
        customer_id,
        COUNT(*)      AS transaction_count,
        SUM(amount)   AS transaction_value
    FROM credit_debit_bank
    GROUP BY customer_id
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
    COUNT(*)                           AS customers,
    ROUND(AVG(transaction_count), 2)   AS avg_transactions,
    ROUND(AVG(transaction_value), 2)   AS avg_transaction_value
FROM segmented
GROUP BY activity_quartile
ORDER BY activity_quartile DESC;

-- Q12. Governed high-value review count and share.
SELECT
    p.numeric_value                                   AS review_threshold,
    COUNT(*)                                          AS high_value_review_count,
    SUM(t.amount)                                     AS high_value_review_amount,
    ROUND(100.0 * COUNT(*) / (SELECT COUNT(*) FROM credit_debit_bank), 2)    AS transaction_share_pct,
    ROUND(100.0 * SUM(t.amount) / (SELECT SUM(amount) FROM credit_debit_bank), 2) AS value_share_pct
FROM credit_debit_bank t
CROSS JOIN analytics_parameters p
WHERE p.parameter_name = 'high_value_review_threshold'
  AND t.amount > p.numeric_value
GROUP BY p.numeric_value;

-- Q13. High-value review concentration by description.
SELECT
    t.description,
    COUNT(*)                     AS high_value_review_count,
    SUM(t.amount)                AS high_value_review_amount,
    ROUND(AVG(t.amount), 2)      AS avg_high_value_amount
FROM credit_debit_bank t
JOIN analytics_parameters p
  ON p.parameter_name = 'high_value_review_threshold'
WHERE t.amount > p.numeric_value
GROUP BY t.description
ORDER BY high_value_review_count DESC, high_value_review_amount DESC;

-- Q14. High-value review concentration by bank and branch.
SELECT
    t.bank_name,
    t.branch,
    COUNT(*)                                            AS transaction_count,
    COUNT(*) FILTER (WHERE t.amount > p.numeric_value)  AS high_value_review_count,
    ROUND(100.0 * COUNT(*) FILTER (WHERE t.amount > p.numeric_value) / COUNT(*), 2) AS high_value_review_rate_pct,
    SUM(t.amount)                                       AS transaction_value
FROM credit_debit_bank t
JOIN analytics_parameters p
  ON p.parameter_name = 'high_value_review_threshold'
GROUP BY t.bank_name, t.branch
ORDER BY high_value_review_rate_pct DESC, transaction_value DESC;

-- Q15. Largest individual transactions for manual review.
SELECT
    customer_id,
    customer_name,
    account_number,
    transaction_date,
    transaction_type,
    amount,
    description,
    branch,
    bank_name,
    transaction_method
FROM credit_debit_bank
ORDER BY amount DESC, transaction_date DESC
LIMIT 100;
