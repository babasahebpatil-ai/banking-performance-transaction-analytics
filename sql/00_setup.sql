/*
Banking Performance & Transaction Analytics
00_setup.sql
Target: MySQL 8+

Assumption: the two source tables have already been imported from the Excel workbooks.

Column naming: the Excel header is "Client id". Depending on the import tool it
lands in MySQL as `Client id`, `Client_id` or `Client _id`. All scripts in this
repository use the standardised name client_id. Run SHOW COLUMNS (below) and, if
needed, the matching RENAME statement ONCE.

The workbook 'MAIN' sheet also carries three empty trailing columns
(Unnamed: 14-16) and a stray 'High Risk' text value in the last one. Do not import them.
*/

CREATE DATABASE IF NOT EXISTS banksphere_intelligence;
USE banksphere_intelligence;

-- Confirm the loan client-ID column name, then rename ONCE if it is not client_id.
SHOW COLUMNS FROM final_fact_cleaned LIKE '%lient%';
-- ALTER TABLE final_fact_cleaned RENAME COLUMN `Client _id` TO client_id;   -- MySQL 8+
-- ALTER TABLE final_fact_cleaned RENAME COLUMN `Client id`  TO client_id;

-- Keep governed business parameters in one place instead of hard-coding
-- different thresholds across SQL, Excel and Power BI.
CREATE TABLE IF NOT EXISTS analytics_parameters (
    parameter_name  VARCHAR(100) PRIMARY KEY,
    numeric_value   DECIMAL(18,2) NULL,
    text_value      VARCHAR(255) NULL,
    updated_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP
                      ON UPDATE CURRENT_TIMESTAMP
);

INSERT INTO analytics_parameters (parameter_name, numeric_value, text_value)
VALUES ('high_value_review_threshold', 4500, 'Transaction amount threshold used for manual review screening')
ON DUPLICATE KEY UPDATE
    numeric_value = VALUES(numeric_value),
    text_value = VALUES(text_value);

-- The source workbook's own 'High-Risk Flag' column uses a LOWER cut-off (4,000) than the
-- governed review threshold (4,500). It is stored only so the two can be reconciled
-- in 07_consistency_checks.sql; it is not used for KPI reporting.
INSERT INTO analytics_parameters (parameter_name, numeric_value, text_value)
VALUES ('source_flag_threshold', 4000, 'Cut-off implied by the legacy High-Risk Flag column in the source workbook (reconciliation only)')
ON DUPLICATE KEY UPDATE
    numeric_value = VALUES(numeric_value),
    text_value = VALUES(text_value);

-- Quick source-table availability checks.
SELECT COUNT(*) AS loan_rows FROM final_fact_cleaned;
SELECT COUNT(*) AS transaction_rows FROM credit_debit_bank;
