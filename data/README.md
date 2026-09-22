# Data Source Notes

The working source data lives inside the two Excel workbooks in `excel/`. No separate CSV export is included because the original upload did not provide a governed raw-data extract.

**The data is simulated.** Do not treat results as real banking evidence (see `reports/data_quality_report.md`, B7).

## CSV files for PostgreSQL

`data/csv/final_fact_cleaned.csv` (2,000 rows) and `data/csv/credit_debit_bank.csv` (100,000 rows) are generated from the workbooks by `python data/export_excel_to_csv.py`. Headers are lowercase snake_case and match `sql/postgres/00_setup.sql`. The 3 empty workbook columns are already dropped.

## Expected MySQL tables

- `final_fact_cleaned` – loan portfolio (sheet `Final_Fact_Cleaned - For Charts`, 2,000 rows)
- `credit_debit_bank` – credit/debit transactions (sheet `MAIN`, 100,000 rows)

## Import mapping

| Workbook header | MySQL column used by the scripts |
|---|---|
| `Client id` | `client_id` (see the rename step in `sql/00_setup.sql`) |
| other headers | header with spaces replaced by underscores, e.g. `Loan Amount` → `Loan_Amount`, `Customer ID` → `Customer_ID` |

Import only the first 14 columns of the `MAIN` sheet. Columns `Unnamed: 14–16` are empty (one stray text value, "High Risk", sits in the last one) and must be dropped.
The `High-Risk Flag` / `High - Risk count` columns use a 4,000 cut-off and are **not** the governed review rule (4,500); they are kept only for reconciliation.

## Modeling note

The loan and transaction datasets are two independent analytical modules. They share no business key and must not be joined.
