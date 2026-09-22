/*
Banking Performance & Transaction Analytics
06_reconciliation_queries.sql
Purpose: one-row checks that can be compared with Excel and Power BI cards.
*/

USE banksphere_intelligence;

-- Loan KPI reconciliation output.
SELECT
    COUNT(*) AS loan_records,
    COUNT(DISTINCT client_id) AS unique_clients,
    COUNT(DISTINCT CASE WHEN Loan_Status = 'Active' THEN client_id END) AS active_clients,
    ROUND(SUM(Loan_Amount), 2) AS total_loan_amount,
    ROUND(SUM(Funded_Amount), 2) AS total_funded_amount,
    ROUND(SUM(Funded_Amount_Inv), 2) AS invested_funded_amount,
    ROUND(AVG(Loan_Amount), 2) AS avg_loan_amount,
    ROUND(SUM(Total_Rrec_Int), 2) AS recorded_interest_income,
    ROUND(100.0 * SUM(Total_Rec_Prncp) / NULLIF(SUM(Loan_Amount), 0), 2) AS principal_recovery_rate_pct,
    ROUND(100.0 * SUM(CASE WHEN Is_Default_Loan = 'Y' THEN 1 ELSE 0 END) / COUNT(*), 2) AS default_flag_rate_pct,
    ROUND(100.0 * SUM(CASE WHEN Loan_Status = 'Default' THEN 1 ELSE 0 END) / COUNT(*), 2) AS status_default_rate_pct,
    ROUND(100.0 * SUM(CASE WHEN Is_Delinquent_Loan = 'Y' THEN 1 ELSE 0 END) / COUNT(*), 2) AS delinquency_rate_pct,
    ROUND(100.0 * SUM(CASE WHEN Repayment_Behavior = 'On-Time' THEN 1 ELSE 0 END) / COUNT(*), 2) AS on_time_repayment_rate_pct
FROM final_fact_cleaned;

-- Transaction KPI reconciliation output.
SELECT
    COUNT(*) AS transaction_count,
    COUNT(DISTINCT Customer_ID) AS unique_customers,
    COUNT(DISTINCT Account_Number) AS unique_accounts,
    ROUND(SUM(CASE WHEN Transaction_Type = 'Credit' THEN Amount ELSE 0 END), 2) AS total_credit,
    ROUND(SUM(CASE WHEN Transaction_Type = 'Debit' THEN Amount ELSE 0 END), 2) AS total_debit,
    ROUND(SUM(CASE WHEN Transaction_Type = 'Credit' THEN Amount ELSE -Amount END), 2) AS net_flow,
    ROUND(COUNT(*) / NULLIF(COUNT(DISTINCT Account_Number), 0), 2) AS transactions_per_account,
    SUM(CASE WHEN Amount > (
        SELECT numeric_value
        FROM analytics_parameters
        WHERE parameter_name = 'high_value_review_threshold'
    ) THEN 1 ELSE 0 END) AS high_value_review_count,          -- governed rule (4,500)  -> 10,428
    SUM(CASE WHEN Amount > (
        SELECT numeric_value
        FROM analytics_parameters
        WHERE parameter_name = 'source_flag_threshold'
    ) THEN 1 ELSE 0 END) AS legacy_source_flag_count            -- source workbook flag (4,000) -> 20,426
FROM credit_debit_bank;

-- Monthly completeness for BI trend validation.
SELECT
    DATE_FORMAT(Transaction_Date, '%Y-%m') AS month_key,
    COUNT(DISTINCT Transaction_Date) AS days_with_data,
    DAY(LAST_DAY(MAX(Transaction_Date))) AS calendar_days_in_month,
    CASE
        WHEN COUNT(DISTINCT Transaction_Date) = DAY(LAST_DAY(MAX(Transaction_Date)))
        THEN 'Complete'
        ELSE 'Review / Partial'
    END AS period_status
FROM credit_debit_bank
GROUP BY DATE_FORMAT(Transaction_Date, '%Y-%m')
ORDER BY month_key;
