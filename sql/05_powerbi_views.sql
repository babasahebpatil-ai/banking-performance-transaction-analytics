/*
Banking Performance & Transaction Analytics
05_powerbi_views.sql
Purpose: curated SQL views that can be consumed by Power BI.
*/

USE banksphere_intelligence;

CREATE OR REPLACE VIEW vw_loan_branch_performance AS
SELECT
    Branch_Name_x AS branch_name,
    COUNT(*) AS loan_records,
    COUNT(DISTINCT client_id) AS unique_clients,
    SUM(Loan_Amount) AS loan_amount,
    AVG(Loan_Amount) AS avg_loan_amount,
    SUM(Total_Rrec_Int) AS recorded_interest_income,
    ROUND(100.0 * SUM(CASE WHEN Is_Default_Loan = 'Y' THEN 1 ELSE 0 END) / COUNT(*), 2) AS default_rate_pct,          -- legacy flag-based (kept for dashboard compatibility)
    ROUND(100.0 * SUM(CASE WHEN Loan_Status = 'Default' THEN 1 ELSE 0 END) / COUNT(*), 2) AS status_default_rate_pct, -- recommended primary definition
    ROUND(100.0 * SUM(CASE WHEN Is_Delinquent_Loan = 'Y' THEN 1 ELSE 0 END) / COUNT(*), 2) AS delinquency_rate_pct,
    ROUND(100.0 * SUM(CASE WHEN Repayment_Behavior = 'On-Time' THEN 1 ELSE 0 END) / COUNT(*), 2) AS on_time_rate_pct
FROM final_fact_cleaned
GROUP BY Branch_Name_x;

CREATE OR REPLACE VIEW vw_loan_yearly_trend AS
SELECT
    YEAR(Disbursement_Date) AS loan_year,
    COUNT(*) AS loan_records,
    COUNT(DISTINCT client_id) AS unique_clients,
    SUM(Loan_Amount) AS loan_amount,
    SUM(Total_Rrec_Int) AS recorded_interest_income
FROM final_fact_cleaned
GROUP BY YEAR(Disbursement_Date);

CREATE OR REPLACE VIEW vw_transaction_enriched AS
SELECT
    t.*,
    YEAR(t.Transaction_Date) AS transaction_year,
    MONTH(t.Transaction_Date) AS transaction_month_number,
    DATE_FORMAT(t.Transaction_Date, '%Y-%m') AS month_key,
    QUARTER(t.Transaction_Date) AS transaction_quarter,
    CASE
        WHEN t.Amount > p.numeric_value THEN 'Review'
        ELSE 'Standard'
    END AS high_value_review_flag
FROM credit_debit_bank t
JOIN analytics_parameters p
  ON p.parameter_name = 'high_value_review_threshold';

CREATE OR REPLACE VIEW vw_transaction_monthly AS
SELECT
    DATE_FORMAT(Transaction_Date, '%Y-%m') AS month_key,
    COUNT(DISTINCT Transaction_Date) AS days_with_data,
    DAY(LAST_DAY(MAX(Transaction_Date))) AS calendar_days_in_month,
    CASE
        WHEN COUNT(DISTINCT Transaction_Date) = DAY(LAST_DAY(MAX(Transaction_Date)))
        THEN 'Complete'
        ELSE 'Review / Partial'
    END AS period_status,
    COUNT(*) AS transaction_count,
    ROUND(COUNT(*) / COUNT(DISTINCT Transaction_Date), 1) AS avg_transactions_per_active_day, -- removes the calendar-length effect
    SUM(CASE WHEN Transaction_Type = 'Credit' THEN Amount ELSE 0 END) AS total_credit,
    SUM(CASE WHEN Transaction_Type = 'Debit' THEN Amount ELSE 0 END) AS total_debit,
    SUM(CASE WHEN Transaction_Type = 'Credit' THEN Amount ELSE -Amount END) AS net_flow
FROM credit_debit_bank
GROUP BY DATE_FORMAT(Transaction_Date, '%Y-%m');

CREATE OR REPLACE VIEW vw_transaction_branch_performance AS
SELECT
    t.Bank_Name,
    t.Branch,
    COUNT(*) AS transaction_count,
    COUNT(DISTINCT t.Customer_ID) AS unique_customers,
    COUNT(DISTINCT t.Account_Number) AS unique_accounts,
    SUM(t.Amount) AS transaction_value,
    AVG(t.Amount) AS avg_transaction_amount,
    SUM(CASE WHEN t.Amount > p.numeric_value THEN 1 ELSE 0 END) AS high_value_review_count,
    ROUND(100.0 * SUM(CASE WHEN t.Amount > p.numeric_value THEN 1 ELSE 0 END) / COUNT(*), 2) AS high_value_review_rate_pct
FROM credit_debit_bank t
JOIN analytics_parameters p
  ON p.parameter_name = 'high_value_review_threshold'
GROUP BY t.Bank_Name, t.Branch;
