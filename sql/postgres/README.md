# SQL Analysis – PostgreSQL edition

Target: **PostgreSQL 13+** (all scripts were executed end-to-end on PostgreSQL 16 against the supplied data; results match `reports/key_findings.md` and `reports/data_quality_report.md`).

The MySQL version of the same analysis is in `../` (one level up). Both give identical results.

## 1. Run order

| Step | File | What it does |
|---|---|---|
| 0 | `00_setup.sql` | creates schema `banksphere`, the two tables, `analytics_parameters`, helper function `days_in_month()` |
| 0b | `00b_load_data_psql.sql` | loads `data/csv/*.csv` with `\copy` |
| 1 | `01_loan_data_quality.sql` | NULLs, duplicates, invalid values, flag/category review |
| 2 | `02_loan_kpi_analysis.sql` | loan KPIs, retention, YoY, branch/product/segment analysis |
| 3 | `03_transaction_data_quality.sql` | transaction validation, month completeness |
| 4 | `04_transaction_kpi_analysis.sql` | transaction KPIs, trends, rankings, high-value review |
| 5 | `05_powerbi_views.sql` | BI-ready views |
| 6 | `06_reconciliation_queries.sql` | one-row checks for Excel / Power BI cards |
| 7 | `07_consistency_checks.sql` | source-data conflicts (default, delinquency, threshold, grain) |

## 2. Quick start

**With psql** (run from the project root, so the relative CSV paths work):

```bash
createdb banksphere_db
psql -d banksphere_db -f sql/postgres/00_setup.sql
psql -d banksphere_db -f sql/postgres/00b_load_data_psql.sql
psql -d banksphere_db -f sql/postgres/01_loan_data_quality.sql
# ... and so on
```

**With pgAdmin:**

1. Create a database, open the Query Tool and run `00_setup.sql`.
2. Right-click `banksphere` > Schemas > Tables > `final_fact_cleaned` > *Import/Export Data*. Choose `data/csv/final_fact_cleaned.csv`, Format `csv`, Header `ON`. Repeat for `credit_debit_bank`.
3. Open each remaining script in the Query Tool and run it. (Use *Explain > run selection* to execute one query at a time.)

If the CSVs are missing, create them with `python data/export_excel_to_csv.py`.

Every script starts with `SET search_path TO banksphere, public;` — this is how Postgres knows which schema to look in (the MySQL equivalent is `USE database;`).

## 3. MySQL → PostgreSQL cheat sheet (what changed and why)

Use this as a study guide: each row is a real change made in these scripts.

| Topic | MySQL (`sql/`) | PostgreSQL (`sql/postgres/`) |
|---|---|---|
| Select database | `USE banksphere_intelligence;` | `SET search_path TO banksphere, public;` (schemas) |
| Create database if missing | `CREATE DATABASE IF NOT EXISTS` | not supported; use `CREATE SCHEMA IF NOT EXISTS` |
| Count rows matching a condition | `SUM(cond)` or `SUM(CASE WHEN ... THEN 1 ELSE 0 END)` | `COUNT(*) FILTER (WHERE cond)` — booleans cannot be summed directly |
| Distinct count of matching rows | `COUNT(DISTINCT CASE WHEN ... THEN x END)` | `COUNT(DISTINCT x) FILTER (WHERE ...)` |
| Format date as month | `DATE_FORMAT(d, '%Y-%m')` | `TO_CHAR(d, 'YYYY-MM')` |
| Year / month / quarter | `YEAR(d)`, `MONTH(d)`, `QUARTER(d)` | `EXTRACT(YEAR FROM d)`, `EXTRACT(MONTH FROM d)`, `EXTRACT(QUARTER FROM d)` |
| Days in month | `DAY(LAST_DAY(d))` | custom function `days_in_month(d)` (see `00_setup.sql`) |
| ISO week key | `YEARWEEK(d, 3)` | `TO_CHAR(d, 'IYYY-"W"IW')` |
| Variables | `SET @start_date = '2021-01-01';` | a `params` CTE: `WITH params AS (SELECT DATE '2021-01-01' AS start_date)` |
| Upsert | `INSERT ... ON DUPLICATE KEY UPDATE` | `INSERT ... ON CONFLICT (key) DO UPDATE SET col = EXCLUDED.col` |
| Custom sort order | `ORDER BY FIELD(col, 'a','b')` | `ORDER BY MIN(numeric_col)` or a `CASE` expression |
| Quoting identifiers | backticks `` `Client _id` `` | double quotes `"Client id"` — avoided here by using lowercase snake_case names |
| Integer division | `7 / 2` = `3.5` | `7 / 2` = `3` — cast: `7::NUMERIC / 2` |
| `ROUND(x, 2)` | works on any number | needs `NUMERIC`; on `double precision` it errors |
| `GROUP BY` an expression | repeat the expression | may use the alias or position (`GROUP BY 1`) |
| Auto-update timestamp | `ON UPDATE CURRENT_TIMESTAMP` | not available; set in the `UPSERT` (`updated_at = now()`) or with a trigger |
| Case sensitivity | column names case-insensitive | unquoted names fold to lowercase (`Loan_Amount` = `loan_amount`) |

### Postgres features worth learning from these scripts

- `FILTER (WHERE ...)` on aggregates (`01`, `02`, `04`, `07`)
- `CREATE FUNCTION` in plain SQL (`days_in_month` in `00_setup.sql`)
- `ON CONFLICT` upserts (`00_setup.sql`)
- `::NUMERIC` casts and integer-division pitfalls (`04` Q1, Q4)
- window functions `LAG`, `DENSE_RANK`, `NTILE`, rolling frames (`02`, `04`)

## 4. Notes

- Logic is unchanged from the MySQL version, except: `02` Q7 ranks branches by the recommended `status_default_rate_pct`, and `02` Q10–Q12 show both default definitions; `02` Q15 (region-level default with sample size) is new.
- `04` Q10 and Q11 (top customers, activity segments) still illustrate the one-transaction-per-customer limitation: every segment shows `avg_transactions = 1.00`.
- Power BI can connect to PostgreSQL directly (Get Data > PostgreSQL database) and read the `vw_*` views in schema `banksphere`.
