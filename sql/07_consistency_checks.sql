/*
Banking Performance & Transaction Analytics
07_consistency_checks.sql
Purpose: quantify the source-data conflicts that affect KPI definitions.
Every result here is documented in reports/data_quality_report.md.
Run after 00_setup.sql. Expected values are for the supplied workbooks.
*/

USE banksphere_intelligence;

-- ---------------------------------------------------------------------------
-- LOAN MODULE
-- ---------------------------------------------------------------------------

-- Q1. Default definitions: Loan_Status vs Is_Default_Loan flag.
-- Expected: 206 loans have status 'Default', only 100 carry flag 'Y', and just 10 are in both.
SELECT
    Loan_Status,
    SUM(Is_Default_Loan = 'Y')  AS flagged_default,
    SUM(Is_Default_Loan = 'N')  AS not_flagged_default,
    COUNT(*)                    AS loan_records,
    ROUND(100.0 * SUM(Is_Default_Loan = 'Y') / COUNT(*), 2) AS pct_flagged
FROM final_fact_cleaned
GROUP BY Loan_Status
ORDER BY loan_records DESC;

-- Q2. Delinquency definitions: Is_Delinquent_Loan flag vs Repayment_Behavior.
-- Expected: 'Very Late' has 207 loans but only 29 are flagged delinquent,
-- while 147 loans with 'On-Time' behaviour ARE flagged delinquent.
SELECT
    Repayment_Behavior,
    SUM(Is_Delinquent_Loan = 'Y') AS flagged_delinquent,
    SUM(Is_Delinquent_Loan = 'N') AS not_flagged,
    COUNT(*)                      AS loan_records
FROM final_fact_cleaned
GROUP BY Repayment_Behavior
ORDER BY loan_records DESC;

-- Q3. Overlapping loan-status labels ('Fully Paid' vs 'Paid Off').
-- Expected: 787 vs 605. Confirm with the data owner whether these are one category.
SELECT Loan_Status, COUNT(*) AS loan_records,
       ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 2) AS share_pct
FROM final_fact_cleaned
GROUP BY Loan_Status
ORDER BY loan_records DESC;

-- Q3b. Payment-field integrity.
-- Expected: 185 loans have recovered principal greater than total payment;
-- about half of loans have Funded_Amount above Loan_Amount.
SELECT
    SUM(Total_Rec_Prncp > Total_Pymnt)                       AS recovered_principal_exceeds_payment,
    SUM(Funded_Amount > Loan_Amount)                          AS funded_exceeds_loan_amount,
    ROUND(100.0 * SUM(Funded_Amount > Loan_Amount) / COUNT(*), 2) AS funded_exceeds_loan_pct,
    SUM(Funded_Amount_Inv > Funded_Amount)                    AS invested_exceeds_funded
FROM final_fact_cleaned;

-- Q3c. Funded-field labelling check.
-- Expected: Funded_Amount ~ 52.36M (equals loan value); Funded_Amount_Inv ~ 46.72M.
-- The legacy dashboard card labelled "Funded Amount 47M" therefore shows the INVESTED field.
SELECT
    SUM(Loan_Amount)        AS total_loan_amount,
    SUM(Funded_Amount)      AS total_funded_amount,
    SUM(Funded_Amount_Inv)  AS total_funded_amount_inv
FROM final_fact_cleaned;

-- ---------------------------------------------------------------------------
-- TRANSACTION MODULE
-- ---------------------------------------------------------------------------

-- Q4. Grain check: how many transactions does each customer / account have?
-- Expected: max_txn_per_customer = 1 and max_txn_per_account = 1.
-- Consequence: retention, customer segmentation, top-customer and per-account KPIs
-- cannot describe behaviour over time on this dataset.
WITH per_customer AS (
    SELECT Customer_ID, COUNT(*) AS txn_count FROM credit_debit_bank GROUP BY Customer_ID
),
per_account AS (
    SELECT Account_Number, COUNT(*) AS txn_count FROM credit_debit_bank GROUP BY Account_Number
)
SELECT
    (SELECT COUNT(*)               FROM credit_debit_bank) AS transaction_rows,
    (SELECT COUNT(*)               FROM per_customer)      AS distinct_customers,
    (SELECT COUNT(*)               FROM per_account)       AS distinct_accounts,
    (SELECT MAX(txn_count)         FROM per_customer)      AS max_txn_per_customer,
    (SELECT MAX(txn_count)         FROM per_account)       AS max_txn_per_account;

-- Q5. High-value rule reconciliation: governed threshold vs legacy source flag.
-- Expected: governed (>4,500) = 10,428 rows; source flag (>= 4,000) = 20,426 rows.
SELECT
    SUM(Amount > gov.numeric_value) AS governed_review_count,
    SUM(Amount > src.numeric_value) AS legacy_source_flag_count,
    SUM(Amount > src.numeric_value AND Amount <= gov.numeric_value) AS flagged_only_by_legacy_rule,
    ROUND(100.0 * SUM(Amount > gov.numeric_value) / COUNT(*), 2) AS governed_share_pct,
    ROUND(100.0 * SUM(Amount > src.numeric_value) / COUNT(*), 2) AS legacy_share_pct
FROM credit_debit_bank t
JOIN analytics_parameters gov ON gov.parameter_name = 'high_value_review_threshold'
JOIN analytics_parameters src ON src.parameter_name = 'source_flag_threshold';

-- Q6. Calendar-length effect in monthly volume.
-- Monthly counts differ mainly because months have different numbers of days.
-- Expected: avg_transactions_per_active_day stays within ~292-301 for all complete months.
SELECT
    DATE_FORMAT(Transaction_Date, '%Y-%m')             AS month_key,
    COUNT(DISTINCT Transaction_Date)                   AS days_with_data,
    COUNT(*)                                           AS transaction_count,
    ROUND(COUNT(*) / COUNT(DISTINCT Transaction_Date), 1) AS avg_transactions_per_active_day,
    CASE WHEN COUNT(DISTINCT Transaction_Date) = DAY(LAST_DAY(MAX(Transaction_Date)))
         THEN 'Complete' ELSE 'Partial - exclude from trend' END AS period_status
FROM credit_debit_bank
GROUP BY DATE_FORMAT(Transaction_Date, '%Y-%m')
ORDER BY month_key;
