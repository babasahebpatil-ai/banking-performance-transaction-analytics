/*
Banking Performance & Transaction Analytics  |  PostgreSQL edition
02_loan_kpi_analysis.sql
Purpose: lending KPIs, segmentation, ranking and trend analysis.
*/

SET search_path TO banksphere, public;

-- Q1. Core portfolio population metrics.
SELECT
    COUNT(*)                                                      AS loan_records,
    COUNT(DISTINCT client_id)                                     AS unique_clients,
    COUNT(DISTINCT client_id) FILTER (WHERE loan_status = 'Active') AS active_clients
FROM final_fact_cleaned;

-- Q2. Loan value and funding metrics.
SELECT
    SUM(loan_amount)         AS total_loan_amount,
    SUM(funded_amount)       AS total_funded_amount,
    SUM(funded_amount_inv)   AS invested_funded_amount,
    ROUND(AVG(loan_amount), 2) AS average_loan_amount
FROM final_fact_cleaned;

-- Q3. Repayment and portfolio-quality KPIs.
-- NOTE: default_flag_rate_pct uses the is_default_loan flag (5.00%). loan_status = 'Default'
-- gives 10.30% and the two barely overlap. See reports/data_quality_report.md and
-- 07_consistency_checks.sql Q1.
SELECT
    SUM(total_pymnt)      AS total_payments,
    SUM(total_rec_prncp)  AS recovered_principal,
    SUM(total_rrec_int)   AS recorded_interest_income,
    ROUND(100.0 * SUM(total_rec_prncp) / NULLIF(SUM(loan_amount), 0), 2)                        AS principal_recovery_rate_pct,
    ROUND(100.0 * COUNT(*) FILTER (WHERE is_default_loan = 'Y') / COUNT(*), 2)                  AS default_flag_rate_pct,
    ROUND(100.0 * COUNT(*) FILTER (WHERE loan_status = 'Default') / COUNT(*), 2)                AS status_default_rate_pct,
    ROUND(100.0 * COUNT(*) FILTER (WHERE is_delinquent_loan = 'Y') / COUNT(*), 2)               AS delinquency_rate_pct,
    ROUND(100.0 * COUNT(*) FILTER (WHERE repayment_behavior = 'On-Time') / COUNT(*), 2)         AS on_time_repayment_rate_pct
FROM final_fact_cleaned;

-- Q4. New-client count for an analyst-defined reporting period.
-- MySQL used SET @start_date = ...; in Postgres the clean way is a parameters CTE.
WITH params AS (
    SELECT DATE '2021-01-01' AS start_date, DATE '2021-12-31' AS end_date
),
first_loan AS (
    SELECT client_id, MIN(disbursement_date) AS first_disbursement_date
    FROM final_fact_cleaned
    GROUP BY client_id
)
SELECT COUNT(*) AS new_clients
FROM first_loan f
CROSS JOIN params p
WHERE f.first_disbursement_date BETWEEN p.start_date AND p.end_date;

-- Q5. Correct cohort retention calculation.
-- Denominator = clients present in the previous period.  (expect 200 / 49 / 24.50 for 2020 -> 2021)
WITH params AS (
    SELECT DATE '2020-01-01' AS prev_start, DATE '2020-12-31' AS prev_end,
           DATE '2021-01-01' AS curr_start, DATE '2021-12-31' AS curr_end
),
prev_clients AS (
    SELECT DISTINCT f.client_id
    FROM final_fact_cleaned f, params p
    WHERE f.disbursement_date BETWEEN p.prev_start AND p.prev_end
),
curr_clients AS (
    SELECT DISTINCT f.client_id
    FROM final_fact_cleaned f, params p
    WHERE f.disbursement_date BETWEEN p.curr_start AND p.curr_end
)
SELECT
    COUNT(*)                                             AS previous_period_clients,
    COUNT(c.client_id)                                   AS retained_clients,   -- COUNT(col) skips NULLs
    ROUND(100.0 * COUNT(c.client_id) / NULLIF(COUNT(*), 0), 2) AS retention_rate_pct
FROM prev_clients p
LEFT JOIN curr_clients c ON p.client_id = c.client_id;

-- Q6. Annual loan trend and YoY growth using LAG().
WITH yearly AS (
    SELECT
        EXTRACT(YEAR FROM disbursement_date)::INT AS loan_year,
        SUM(loan_amount)                          AS loan_amount
    FROM final_fact_cleaned
    GROUP BY 1
),
with_prev AS (
    SELECT
        loan_year,
        loan_amount,
        LAG(loan_amount) OVER (ORDER BY loan_year) AS previous_year_amount
    FROM yearly
)
SELECT
    loan_year,
    loan_amount,
    previous_year_amount,
    ROUND(100.0 * (loan_amount - previous_year_amount) / NULLIF(previous_year_amount, 0), 2) AS yoy_growth_pct
FROM with_prev
ORDER BY loan_year;

-- Q7. Branch performance scorecard with ranking.
-- default_rate_pct is flag-based (legacy); status_default_rate_pct is the recommended definition.
WITH branch_metrics AS (
    SELECT
        branch_name_x                                   AS branch_name,
        COUNT(*)                                        AS loan_records,
        COUNT(DISTINCT client_id)                       AS unique_clients,
        SUM(loan_amount)                                AS loan_amount,
        ROUND(AVG(loan_amount), 2)                      AS avg_loan_amount,
        ROUND(100.0 * COUNT(*) FILTER (WHERE is_default_loan = 'Y') / COUNT(*), 2)      AS default_rate_pct,
        ROUND(100.0 * COUNT(*) FILTER (WHERE loan_status = 'Default') / COUNT(*), 2)    AS status_default_rate_pct,
        ROUND(100.0 * COUNT(*) FILTER (WHERE is_delinquent_loan = 'Y') / COUNT(*), 2)   AS delinquency_rate_pct,
        ROUND(100.0 * COUNT(*) FILTER (WHERE repayment_behavior = 'On-Time') / COUNT(*), 2) AS on_time_rate_pct
    FROM final_fact_cleaned
    GROUP BY branch_name_x
)
SELECT
    *,
    DENSE_RANK() OVER (ORDER BY loan_amount DESC)            AS loan_value_rank,
    DENSE_RANK() OVER (ORDER BY status_default_rate_pct ASC) AS default_quality_rank
FROM branch_metrics
ORDER BY loan_value_rank, branch_name;

-- Q8. Branch contribution to total loan value.
SELECT
    branch_name_x AS branch_name,
    SUM(loan_amount) AS loan_amount,
    ROUND(100.0 * SUM(loan_amount) / SUM(SUM(loan_amount)) OVER (), 2) AS loan_value_share_pct
FROM final_fact_cleaned
GROUP BY branch_name_x
ORDER BY loan_amount DESC;

-- Q9. Product-level loan volume and interest contribution.
-- Interest contribution is not "profitability": costs are unavailable.
SELECT
    product_id,
    COUNT(*)                AS loan_records,
    SUM(loan_amount)        AS loan_amount,
    SUM(total_rrec_int)     AS recorded_interest_income,
    ROUND(100.0 * SUM(total_rrec_int) / NULLIF(SUM(SUM(total_rrec_int)) OVER (), 0), 2) AS interest_contribution_pct,
    DENSE_RANK() OVER (ORDER BY SUM(loan_amount) DESC) AS loan_volume_rank
FROM final_fact_cleaned
GROUP BY product_id
ORDER BY loan_volume_rank;

-- Q10. Purpose-category performance.
SELECT
    purpose_category,
    COUNT(*)                     AS loan_records,
    SUM(loan_amount)             AS loan_amount,
    ROUND(AVG(loan_amount), 2)   AS avg_loan_amount,
    SUM(total_rrec_int)          AS recorded_interest_income,
    ROUND(100.0 * COUNT(*) FILTER (WHERE is_default_loan = 'Y') / COUNT(*), 2)    AS default_flag_rate_pct,
    ROUND(100.0 * COUNT(*) FILTER (WHERE loan_status = 'Default') / COUNT(*), 2)  AS status_default_rate_pct,
    ROUND(100.0 * COUNT(*) FILTER (WHERE is_delinquent_loan = 'Y') / COUNT(*), 2) AS delinquency_rate_pct
FROM final_fact_cleaned
GROUP BY purpose_category
ORDER BY loan_amount DESC;

-- Q11. Credit-score band analysis.
-- ORDER BY MIN(credit_score) keeps the bands in natural order (MySQL needed FIELD(); Postgres does not).
WITH scored AS (
    SELECT
        CASE
            WHEN credit_score IS NULL THEN 'Unknown'
            WHEN credit_score < 580   THEN '<580'
            WHEN credit_score < 670   THEN '580-669'
            WHEN credit_score < 740   THEN '670-739'
            WHEN credit_score < 800   THEN '740-799'
            ELSE '800+'
        END AS credit_score_band,
        credit_score,
        loan_amount,
        is_default_loan,
        loan_status,
        is_delinquent_loan
    FROM final_fact_cleaned
)
SELECT
    credit_score_band,
    COUNT(*)          AS loan_records,
    SUM(loan_amount)  AS loan_amount,
    ROUND(100.0 * COUNT(*) FILTER (WHERE is_default_loan = 'Y') / COUNT(*), 2)    AS default_flag_rate_pct,
    ROUND(100.0 * COUNT(*) FILTER (WHERE loan_status = 'Default') / COUNT(*), 2)  AS status_default_rate_pct,
    ROUND(100.0 * COUNT(*) FILTER (WHERE is_delinquent_loan = 'Y') / COUNT(*), 2) AS delinquency_rate_pct
FROM scored
GROUP BY credit_score_band
ORDER BY MIN(credit_score) NULLS LAST;

-- Q12. Employment-segment quality.
SELECT
    employment_type,
    COUNT(*)                     AS loan_records,
    COUNT(DISTINCT client_id)    AS unique_clients,
    ROUND(AVG(loan_amount), 2)   AS avg_loan_amount,
    ROUND(100.0 * COUNT(*) FILTER (WHERE is_default_loan = 'Y') / COUNT(*), 2)    AS default_flag_rate_pct,
    ROUND(100.0 * COUNT(*) FILTER (WHERE loan_status = 'Default') / COUNT(*), 2)  AS status_default_rate_pct,
    ROUND(100.0 * COUNT(*) FILTER (WHERE is_delinquent_loan = 'Y') / COUNT(*), 2) AS delinquency_rate_pct
FROM final_fact_cleaned
GROUP BY employment_type
ORDER BY loan_records DESC;

-- Q13. Delinquency priority list for operational review.
SELECT
    account_id,
    client_id,
    branch_name_x AS branch_name,
    product_id,
    loan_amount,
    credit_score,
    repayment_behavior,
    delinq_2_yrs,
    is_default_loan
FROM final_fact_cleaned
WHERE is_delinquent_loan = 'Y'
ORDER BY delinq_2_yrs DESC, loan_amount DESC;

-- Q14. Rolling 3-year average of loan value.
WITH yearly AS (
    SELECT
        EXTRACT(YEAR FROM disbursement_date)::INT AS loan_year,
        SUM(loan_amount)                          AS loan_amount
    FROM final_fact_cleaned
    GROUP BY 1
)
SELECT
    loan_year,
    loan_amount,
    ROUND(
        AVG(loan_amount) OVER (ORDER BY loan_year ROWS BETWEEN 2 PRECEDING AND CURRENT ROW),
        2
    ) AS rolling_3_year_avg_loan_amount
FROM yearly
ORDER BY loan_year;

-- Q15 (NEW). Region-level status default with sample size, so small groups are not over-read.
-- Expect Patna 19.6% (92 loans) and Bhubaneswar 23.3% (30 loans) above the 10.3% portfolio average.
SELECT
    region_name,
    state_name,
    COUNT(*)                                                                    AS loan_records,
    COUNT(*) FILTER (WHERE loan_status = 'Default')                             AS status_default_loans,
    ROUND(100.0 * COUNT(*) FILTER (WHERE loan_status = 'Default') / COUNT(*), 2) AS status_default_rate_pct
FROM final_fact_cleaned
GROUP BY region_name, state_name
ORDER BY status_default_rate_pct DESC, loan_records DESC;
