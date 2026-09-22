# SQL Analysis (MySQL)

> Learning or using **PostgreSQL**? Use the ported and tested scripts in [`postgres/`](postgres/README.md).

Database: **MySQL 8+**

Run order:

1. `00_setup.sql`
2. `01_loan_data_quality.sql`
3. `02_loan_kpi_analysis.sql`
4. `03_transaction_data_quality.sql`
5. `04_transaction_kpi_analysis.sql`
6. `05_powerbi_views.sql`
7. `06_reconciliation_queries.sql`
8. `07_consistency_checks.sql`

The source tables are expected to exist after importing the Excel data:

- `final_fact_cleaned`
- `credit_debit_bank`

The scripts intentionally separate **data quality**, **business analysis**, **BI views**, and **reconciliation** so the SQL layer mirrors a real analyst workflow rather than a collection of unrelated practice queries.

`07_consistency_checks.sql` quantifies source-data conflicts (default vs status, delinquency vs repayment behaviour, funded-field labelling, one-row-per-customer grain, threshold mismatch, calendar-length effect). Each query lists its expected result for the supplied workbooks.

Column naming: all scripts use `client_id`; see the rename step in `00_setup.sql` if your import produced a different name.
