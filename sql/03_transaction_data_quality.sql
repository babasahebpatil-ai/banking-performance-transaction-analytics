/*
Banking Performance & Transaction Analytics
03_transaction_data_quality.sql
Purpose: validate transaction records before reporting.
*/

USE banksphere_intelligence;

-- Q1. Dataset size and coverage.
SELECT
    COUNT(*) AS transaction_records,
    COUNT(DISTINCT Customer_ID) AS unique_customers,
    COUNT(DISTINCT Account_Number) AS unique_accounts,
    MIN(Transaction_Date) AS first_transaction_date,
    MAX(Transaction_Date) AS latest_transaction_date
FROM credit_debit_bank;

-- Q2. Critical NULL checks.
SELECT
    SUM(Customer_ID IS NULL OR TRIM(Customer_ID) = '') AS null_customer_id,
    SUM(Account_Number IS NULL) AS null_account_number,
    SUM(Transaction_Date IS NULL) AS null_transaction_date,
    SUM(Transaction_Type IS NULL OR TRIM(Transaction_Type) = '') AS null_transaction_type,
    SUM(Amount IS NULL) AS null_amount,
    SUM(Branch IS NULL OR TRIM(Branch) = '') AS null_branch,
    SUM(Transaction_Method IS NULL OR TRIM(Transaction_Method) = '') AS null_method,
    SUM(Bank_Name IS NULL OR TRIM(Bank_Name) = '') AS null_bank_name
FROM credit_debit_bank;

-- Q3. Potential exact duplicate records.
WITH ranked AS (
    SELECT
        Customer_ID,
        Account_Number,
        Transaction_Date,
        Transaction_Type,
        Amount,
        Balance,
        Description,
        Branch,
        Transaction_Method,
        Currency,
        Bank_Name,
        ROW_NUMBER() OVER (
            PARTITION BY Customer_ID, Account_Number, Transaction_Date,
                         Transaction_Type, Amount, Balance, Description,
                         Branch, Transaction_Method, Currency, Bank_Name
            ORDER BY Customer_ID
        ) AS duplicate_row_number
    FROM credit_debit_bank
)
SELECT COUNT(*) AS potential_duplicate_rows
FROM ranked
WHERE duplicate_row_number > 1;

-- Q4. Invalid/exception monetary values.
SELECT
    SUM(Amount <= 0) AS non_positive_amount_records,
    SUM(Balance < 0) AS negative_balance_records,
    MIN(Amount) AS min_amount,
    MAX(Amount) AS max_amount
FROM credit_debit_bank;

-- Q5. Validate transaction-type categories.
SELECT Transaction_Type, COUNT(*) AS records
FROM credit_debit_bank
GROUP BY Transaction_Type
ORDER BY records DESC;

-- Q6. Review currency values before aggregating amounts across currencies.
SELECT Currency, COUNT(*) AS records, SUM(Amount) AS amount
FROM credit_debit_bank
GROUP BY Currency
ORDER BY records DESC;

-- Q7. Review bank/branch/method category cleanliness.
SELECT 'Bank' AS category_type, Bank_Name AS category_value, COUNT(*) AS records
FROM credit_debit_bank
GROUP BY Bank_Name
UNION ALL
SELECT 'Branch', Branch, COUNT(*)
FROM credit_debit_bank
GROUP BY Branch
UNION ALL
SELECT 'Transaction Method', Transaction_Method, COUNT(*)
FROM credit_debit_bank
GROUP BY Transaction_Method;

-- Q8. Month completeness check.
-- This prevents a partial month from being interpreted as a full-month decline.
SELECT
    DATE_FORMAT(Transaction_Date, '%Y-%m') AS month_key,
    MIN(Transaction_Date) AS first_loaded_date,
    MAX(Transaction_Date) AS last_loaded_date,
    COUNT(DISTINCT Transaction_Date) AS days_with_data,
    DAY(LAST_DAY(MAX(Transaction_Date))) AS calendar_days_in_month,
    CASE
        WHEN COUNT(DISTINCT Transaction_Date) = DAY(LAST_DAY(MAX(Transaction_Date)))
        THEN 'Complete'
        ELSE 'Review / Partial'
    END AS period_status,
    COUNT(*) AS transaction_records
FROM credit_debit_bank
GROUP BY DATE_FORMAT(Transaction_Date, '%Y-%m')
ORDER BY month_key;

-- Q9. Account-to-customer mapping check.
-- NOTE: this check returns zero rows on the current data, but for a misleading reason:
-- every account and customer appears only once. See 07_consistency_checks.sql Q4.
-- Accounts mapped to multiple customer IDs deserve review unless joint-account behavior is expected.
SELECT
    Account_Number,
    COUNT(DISTINCT Customer_ID) AS distinct_customers
FROM credit_debit_bank
GROUP BY Account_Number
HAVING COUNT(DISTINCT Customer_ID) > 1
ORDER BY distinct_customers DESC, Account_Number;

-- Q10. High-value review rule reconciliation.
SELECT
    p.numeric_value AS high_value_review_threshold,
    COUNT(*) AS flagged_transactions,
    ROUND(100.0 * COUNT(*) / (SELECT COUNT(*) FROM credit_debit_bank), 2) AS flagged_share_pct
FROM credit_debit_bank t
CROSS JOIN analytics_parameters p
WHERE p.parameter_name = 'high_value_review_threshold'
  AND t.Amount > p.numeric_value
GROUP BY p.numeric_value;
