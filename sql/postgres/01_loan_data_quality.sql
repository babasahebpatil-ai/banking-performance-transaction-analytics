/*
Banking Performance & Transaction Analytics  |  PostgreSQL edition
01_loan_data_quality.sql
Purpose: profile the lending dataset before KPI analysis.
*/

SET search_path TO banksphere, public;

-- Q1. Dataset size, client count and date coverage.
SELECT
    COUNT(*)                   AS loan_records,
    COUNT(DISTINCT client_id)  AS unique_clients,
    MIN(disbursement_date)     AS first_disbursement_date,
    MAX(disbursement_date)     AS latest_disbursement_date
FROM final_fact_cleaned;

-- Q2. Critical NULL checks.
-- COUNT(*) FILTER (WHERE ...) is the Postgres way to "count rows that meet a condition".
SELECT
    COUNT(*) FILTER (WHERE account_id IS NULL OR TRIM(account_id) = '')  AS null_account_id,
    COUNT(*) FILTER (WHERE client_id IS NULL)                            AS null_client_id,
    COUNT(*) FILTER (WHERE disbursement_date IS NULL)                    AS null_disbursement_date,
    COUNT(*) FILTER (WHERE loan_amount IS NULL)                          AS null_loan_amount,
    COUNT(*) FILTER (WHERE loan_status IS NULL OR TRIM(loan_status) = '') AS null_loan_status,
    COUNT(*) FILTER (WHERE is_default_loan IS NULL)                      AS null_default_flag,
    COUNT(*) FILTER (WHERE is_delinquent_loan IS NULL)                   AS null_delinquency_flag
FROM final_fact_cleaned;

-- Q3. Potential duplicate loan records.
-- Do not delete automatically; first investigate whether repeated rows are legitimate.
WITH duplicate_check AS (
    SELECT
        account_id,
        client_id,
        disbursement_date,
        loan_amount,
        COUNT(*) AS row_count
    FROM final_fact_cleaned
    GROUP BY account_id, client_id, disbursement_date, loan_amount
)
SELECT *
FROM duplicate_check
WHERE row_count > 1
ORDER BY row_count DESC, account_id;

-- Q4. Invalid/non-positive monetary values.
SELECT
    COUNT(*) FILTER (WHERE loan_amount <= 0)      AS non_positive_loan_amount,
    COUNT(*) FILTER (WHERE funded_amount < 0)     AS negative_funded_amount,
    COUNT(*) FILTER (WHERE total_pymnt < 0)       AS negative_total_payment,
    COUNT(*) FILTER (WHERE total_rec_prncp < 0)   AS negative_recovered_principal,
    COUNT(*) FILTER (WHERE total_rrec_int < 0)    AS negative_interest_amount
FROM final_fact_cleaned;

-- Q5. Recovery values that exceed recorded total payment.  (expect 185 rows)
SELECT
    account_id,
    client_id,
    loan_amount,
    total_pymnt,
    total_rec_prncp,
    total_rrec_int
FROM final_fact_cleaned
WHERE total_rec_prncp > total_pymnt
ORDER BY (total_rec_prncp - total_pymnt) DESC;

-- Q6. Validate expected binary flag values.
SELECT 'Default Flag' AS field_name, is_default_loan::TEXT AS field_value, COUNT(*) AS records
FROM final_fact_cleaned
GROUP BY is_default_loan
UNION ALL
SELECT 'Delinquency Flag', is_delinquent_loan::TEXT, COUNT(*)
FROM final_fact_cleaned
GROUP BY is_delinquent_loan;

-- Q7. Review key categorical values before reporting.
SELECT 'Loan_Status' AS field_name, loan_status AS field_value, COUNT(*) AS records
FROM final_fact_cleaned
GROUP BY loan_status
UNION ALL
SELECT 'Repayment_Behavior', repayment_behavior, COUNT(*)
FROM final_fact_cleaned
GROUP BY repayment_behavior
UNION ALL
SELECT 'Employment_Type', employment_type, COUNT(*)
FROM final_fact_cleaned
GROUP BY employment_type;

-- Q8. Credit-score range review.
-- The common 300-850 range is a validation rule only if this source is confirmed to use it.
SELECT
    MIN(credit_score) AS min_credit_score,
    MAX(credit_score) AS max_credit_score,
    COUNT(*) FILTER (WHERE credit_score < 300 OR credit_score > 850) AS outside_300_850_range
FROM final_fact_cleaned;

-- Q9. Compare overlapping funded-amount fields so BI labels can be governed.
SELECT
    SUM(funded_amount)                          AS funded_amount,
    SUM(funded_amount_inv)                      AS invested_funded_amount,
    SUM(funded_amount) - SUM(funded_amount_inv) AS difference
FROM final_fact_cleaned;

-- Q10. Annual row counts to identify partial years.
SELECT
    EXTRACT(YEAR FROM disbursement_date)::INT AS disbursement_year,
    COUNT(*)                                  AS loan_records,
    COUNT(DISTINCT client_id)                 AS unique_clients,
    SUM(loan_amount)                          AS loan_amount
FROM final_fact_cleaned
GROUP BY 1
ORDER BY disbursement_year;
