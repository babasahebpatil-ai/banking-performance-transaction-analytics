/*
Banking Performance & Transaction Analytics
01_loan_data_quality.sql
Purpose: profile the lending dataset before KPI analysis.
*/

USE banksphere_intelligence;

-- Q1. Dataset size, client count and date coverage.
SELECT
    COUNT(*) AS loan_records,
    COUNT(DISTINCT client_id) AS unique_clients,
    MIN(Disbursement_Date) AS first_disbursement_date,
    MAX(Disbursement_Date) AS latest_disbursement_date
FROM final_fact_cleaned;

-- Q2. Critical NULL checks.
SELECT
    SUM(Account_ID IS NULL OR TRIM(Account_ID) = '') AS null_account_id,
    SUM(client_id IS NULL) AS null_client_id,
    SUM(Disbursement_Date IS NULL) AS null_disbursement_date,
    SUM(Loan_Amount IS NULL) AS null_loan_amount,
    SUM(Loan_Status IS NULL OR TRIM(Loan_Status) = '') AS null_loan_status,
    SUM(Is_Default_Loan IS NULL) AS null_default_flag,
    SUM(Is_Delinquent_Loan IS NULL) AS null_delinquency_flag
FROM final_fact_cleaned;

-- Q3. Potential duplicate loan records.
-- Do not delete automatically; first investigate whether repeated rows are legitimate.
WITH duplicate_check AS (
    SELECT
        Account_ID,
        client_id,
        Disbursement_Date,
        Loan_Amount,
        COUNT(*) AS row_count
    FROM final_fact_cleaned
    GROUP BY Account_ID, client_id, Disbursement_Date, Loan_Amount
)
SELECT *
FROM duplicate_check
WHERE row_count > 1
ORDER BY row_count DESC, Account_ID;

-- Q4. Invalid/non-positive monetary values.
SELECT
    SUM(Loan_Amount <= 0) AS non_positive_loan_amount,
    SUM(Funded_Amount < 0) AS negative_funded_amount,
    SUM(Total_Pymnt < 0) AS negative_total_payment,
    SUM(Total_Rec_Prncp < 0) AS negative_recovered_principal,
    SUM(Total_Rrec_Int < 0) AS negative_interest_amount
FROM final_fact_cleaned;

-- Q5. Recovery values that exceed recorded total payment.
SELECT
    Account_ID,
    client_id,
    Loan_Amount,
    Total_Pymnt,
    Total_Rec_Prncp,
    Total_Rrec_Int
FROM final_fact_cleaned
WHERE Total_Rec_Prncp > Total_Pymnt
ORDER BY (Total_Rec_Prncp - Total_Pymnt) DESC;

-- Q6. Validate expected binary flag values.
SELECT 'Default Flag' AS field_name, Is_Default_Loan AS field_value, COUNT(*) AS records
FROM final_fact_cleaned
GROUP BY Is_Default_Loan
UNION ALL
SELECT 'Delinquency Flag', Is_Delinquent_Loan, COUNT(*)
FROM final_fact_cleaned
GROUP BY Is_Delinquent_Loan;

-- Q7. Review key categorical values before reporting.
SELECT 'Loan_Status' AS field_name, Loan_Status AS field_value, COUNT(*) AS records
FROM final_fact_cleaned
GROUP BY Loan_Status
UNION ALL
SELECT 'Repayment_Behavior', Repayment_Behavior, COUNT(*)
FROM final_fact_cleaned
GROUP BY Repayment_Behavior
UNION ALL
SELECT 'Employment_Type', Employment_Type, COUNT(*)
FROM final_fact_cleaned
GROUP BY Employment_Type;

-- Q8. Credit-score range review.
-- The commonly used 300-850 range is treated as a validation rule only if
-- this source is confirmed to use that scale.
SELECT
    MIN(Credit_Score) AS min_credit_score,
    MAX(Credit_Score) AS max_credit_score,
    SUM(Credit_Score < 300 OR Credit_Score > 850) AS outside_300_850_range
FROM final_fact_cleaned;

-- Q9. Compare overlapping funded-amount fields so BI labels can be governed.
SELECT
    SUM(Funded_Amount) AS funded_amount,
    SUM(Funded_Amount_Inv) AS invested_funded_amount,
    SUM(Funded_Amount) - SUM(Funded_Amount_Inv) AS difference
FROM final_fact_cleaned;

-- Q10. Annual row counts to identify partial years.
SELECT
    YEAR(Disbursement_Date) AS disbursement_year,
    COUNT(*) AS loan_records,
    COUNT(DISTINCT client_id) AS unique_clients,
    SUM(Loan_Amount) AS loan_amount
FROM final_fact_cleaned
GROUP BY YEAR(Disbursement_Date)
ORDER BY disbursement_year;
