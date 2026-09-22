/*
Banking Performance & Transaction Analytics
02_loan_kpi_analysis.sql
Purpose: lending KPIs, segmentation, ranking and trend analysis.
*/

USE banksphere_intelligence;

-- Q1. Core portfolio population metrics.
SELECT
    COUNT(*) AS loan_records,
    COUNT(DISTINCT client_id) AS unique_clients,
    COUNT(DISTINCT CASE WHEN Loan_Status = 'Active' THEN client_id END) AS active_clients
FROM final_fact_cleaned;

-- Q2. Loan value and funding metrics.
SELECT
    SUM(Loan_Amount) AS total_loan_amount,
    SUM(Funded_Amount) AS total_funded_amount,
    SUM(Funded_Amount_Inv) AS invested_funded_amount,
    AVG(Loan_Amount) AS average_loan_amount
FROM final_fact_cleaned;

-- Q3. Repayment and portfolio-quality KPIs.
-- NOTE: default_rate_pct here uses the Is_Default_Loan flag (5.00%). Loan_Status = 'Default'
-- gives 10.30% and the two barely overlap. The open definition question is documented in
-- reports/data_quality_report.md and quantified in 07_consistency_checks.sql Q1.
SELECT
    SUM(Total_Pymnt) AS total_payments,
    SUM(Total_Rec_Prncp) AS recovered_principal,
    SUM(Total_Rrec_Int) AS recorded_interest_income,
    ROUND(100.0 * SUM(Total_Rec_Prncp) / NULLIF(SUM(Loan_Amount), 0), 2) AS principal_recovery_rate_pct,
    ROUND(100.0 * SUM(CASE WHEN Is_Default_Loan = 'Y' THEN 1 ELSE 0 END) / COUNT(*), 2) AS default_flag_rate_pct,
    ROUND(100.0 * SUM(CASE WHEN Loan_Status = 'Default' THEN 1 ELSE 0 END) / COUNT(*), 2) AS status_default_rate_pct,
    ROUND(100.0 * SUM(CASE WHEN Is_Delinquent_Loan = 'Y' THEN 1 ELSE 0 END) / COUNT(*), 2) AS delinquency_rate_pct,
    ROUND(100.0 * SUM(CASE WHEN Repayment_Behavior = 'On-Time' THEN 1 ELSE 0 END) / COUNT(*), 2) AS on_time_repayment_rate_pct
FROM final_fact_cleaned;

-- Q4. New-client count for an analyst-defined reporting period.
SET @start_date = '2021-01-01';
SET @end_date   = '2021-12-31';

WITH first_loan AS (
    SELECT client_id, MIN(Disbursement_Date) AS first_disbursement_date
    FROM final_fact_cleaned
    GROUP BY client_id
)
SELECT COUNT(*) AS new_clients
FROM first_loan
WHERE first_disbursement_date BETWEEN @start_date AND @end_date;

-- Q5. Correct cohort retention calculation.
-- Denominator = clients present in the previous period.
SET @prev_start = '2020-01-01';
SET @prev_end   = '2020-12-31';
SET @curr_start = '2021-01-01';
SET @curr_end   = '2021-12-31';

WITH prev_clients AS (
    SELECT DISTINCT client_id
    FROM final_fact_cleaned
    WHERE Disbursement_Date BETWEEN @prev_start AND @prev_end
),
curr_clients AS (
    SELECT DISTINCT client_id
    FROM final_fact_cleaned
    WHERE Disbursement_Date BETWEEN @curr_start AND @curr_end
)
SELECT
    COUNT(*) AS previous_period_clients,
    SUM(CASE WHEN c.client_id IS NOT NULL THEN 1 ELSE 0 END) AS retained_clients,
    ROUND(
        100.0 * SUM(CASE WHEN c.client_id IS NOT NULL THEN 1 ELSE 0 END)
        / NULLIF(COUNT(*), 0),
        2
    ) AS retention_rate_pct
FROM prev_clients p
LEFT JOIN curr_clients c
    ON p.client_id = c.client_id;

-- Q6. Annual loan trend and YoY growth using LAG().
WITH yearly AS (
    SELECT
        YEAR(Disbursement_Date) AS loan_year,
        SUM(Loan_Amount) AS loan_amount
    FROM final_fact_cleaned
    GROUP BY YEAR(Disbursement_Date)
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
WITH branch_metrics AS (
    SELECT
        Branch_Name_x AS branch_name,
        COUNT(*) AS loan_records,
        COUNT(DISTINCT client_id) AS unique_clients,
        SUM(Loan_Amount) AS loan_amount,
        AVG(Loan_Amount) AS avg_loan_amount,
        ROUND(100.0 * SUM(CASE WHEN Is_Default_Loan = 'Y' THEN 1 ELSE 0 END) / COUNT(*), 2) AS default_rate_pct,
        ROUND(100.0 * SUM(CASE WHEN Is_Delinquent_Loan = 'Y' THEN 1 ELSE 0 END) / COUNT(*), 2) AS delinquency_rate_pct,
        ROUND(100.0 * SUM(CASE WHEN Repayment_Behavior = 'On-Time' THEN 1 ELSE 0 END) / COUNT(*), 2) AS on_time_rate_pct
    FROM final_fact_cleaned
    GROUP BY Branch_Name_x
)
SELECT
    *,
    DENSE_RANK() OVER (ORDER BY loan_amount DESC) AS loan_value_rank,
    DENSE_RANK() OVER (ORDER BY default_rate_pct ASC) AS default_quality_rank
FROM branch_metrics
ORDER BY loan_value_rank, branch_name;

-- Q8. Branch contribution to total loan value.
SELECT
    Branch_Name_x AS branch_name,
    SUM(Loan_Amount) AS loan_amount,
    ROUND(100.0 * SUM(Loan_Amount) / SUM(SUM(Loan_Amount)) OVER (), 2) AS loan_value_share_pct
FROM final_fact_cleaned
GROUP BY Branch_Name_x
ORDER BY loan_amount DESC;

-- Q9. Product-level loan volume and interest contribution.
-- Interest contribution is not labeled as "profitability" because costs are unavailable.
SELECT
    Product_Id,
    COUNT(*) AS loan_records,
    SUM(Loan_Amount) AS loan_amount,
    SUM(Total_Rrec_Int) AS recorded_interest_income,
    ROUND(100.0 * SUM(Total_Rrec_Int) / NULLIF(SUM(SUM(Total_Rrec_Int)) OVER (), 0), 2) AS interest_contribution_pct,
    DENSE_RANK() OVER (ORDER BY SUM(Loan_Amount) DESC) AS loan_volume_rank
FROM final_fact_cleaned
GROUP BY Product_Id
ORDER BY loan_volume_rank;

-- Q10. Purpose-category performance.
SELECT
    Purpose_Category,
    COUNT(*) AS loan_records,
    SUM(Loan_Amount) AS loan_amount,
    AVG(Loan_Amount) AS avg_loan_amount,
    SUM(Total_Rrec_Int) AS recorded_interest_income,
    ROUND(100.0 * SUM(CASE WHEN Is_Default_Loan = 'Y' THEN 1 ELSE 0 END) / COUNT(*), 2) AS default_rate_pct,
    ROUND(100.0 * SUM(CASE WHEN Is_Delinquent_Loan = 'Y' THEN 1 ELSE 0 END) / COUNT(*), 2) AS delinquency_rate_pct
FROM final_fact_cleaned
GROUP BY Purpose_Category
ORDER BY loan_amount DESC;

-- Q11. Credit-score band analysis.
WITH scored AS (
    SELECT
        CASE
            WHEN Credit_Score IS NULL THEN 'Unknown'
            WHEN Credit_Score < 580 THEN '<580'
            WHEN Credit_Score < 670 THEN '580-669'
            WHEN Credit_Score < 740 THEN '670-739'
            WHEN Credit_Score < 800 THEN '740-799'
            ELSE '800+'
        END AS credit_score_band,
        Loan_Amount,
        Is_Default_Loan,
        Is_Delinquent_Loan
    FROM final_fact_cleaned
)
SELECT
    credit_score_band,
    COUNT(*) AS loan_records,
    SUM(Loan_Amount) AS loan_amount,
    ROUND(100.0 * SUM(CASE WHEN Is_Default_Loan = 'Y' THEN 1 ELSE 0 END) / COUNT(*), 2) AS default_rate_pct,
    ROUND(100.0 * SUM(CASE WHEN Is_Delinquent_Loan = 'Y' THEN 1 ELSE 0 END) / COUNT(*), 2) AS delinquency_rate_pct
FROM scored
GROUP BY credit_score_band
ORDER BY FIELD(credit_score_band, '<580','580-669','670-739','740-799','800+','Unknown');

-- Q12. Employment-segment quality.
SELECT
    Employment_Type,
    COUNT(*) AS loan_records,
    COUNT(DISTINCT client_id) AS unique_clients,
    AVG(Loan_Amount) AS avg_loan_amount,
    ROUND(100.0 * SUM(CASE WHEN Is_Default_Loan = 'Y' THEN 1 ELSE 0 END) / COUNT(*), 2) AS default_rate_pct,
    ROUND(100.0 * SUM(CASE WHEN Is_Delinquent_Loan = 'Y' THEN 1 ELSE 0 END) / COUNT(*), 2) AS delinquency_rate_pct
FROM final_fact_cleaned
GROUP BY Employment_Type
ORDER BY loan_records DESC;

-- Q13. Delinquency priority list for operational review.
SELECT
    Account_ID,
    client_id AS client_id,
    Branch_Name_x AS branch_name,
    Product_Id,
    Loan_Amount,
    Credit_Score,
    Repayment_Behavior,
    Delinq_2_Yrs,
    Is_Default_Loan
FROM final_fact_cleaned
WHERE Is_Delinquent_Loan = 'Y'
ORDER BY Delinq_2_Yrs DESC, Loan_Amount DESC;

-- Q14. Rolling 3-year average of loan value.
WITH yearly AS (
    SELECT
        YEAR(Disbursement_Date) AS loan_year,
        SUM(Loan_Amount) AS loan_amount
    FROM final_fact_cleaned
    GROUP BY YEAR(Disbursement_Date)
)
SELECT
    loan_year,
    loan_amount,
    ROUND(
        AVG(loan_amount) OVER (
            ORDER BY loan_year
            ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
        ),
        2
    ) AS rolling_3_year_avg_loan_amount
FROM yearly
ORDER BY loan_year;
