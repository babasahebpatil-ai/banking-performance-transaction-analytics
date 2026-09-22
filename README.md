# Banking Performance & Transaction Analytics

**Banking Performance & Transaction Analytics** is a SQL, Excel, and Power BI focused banking case study built around two operational areas:

1. **Loan portfolio performance** — client activity, loan value, recovery, delinquency/default indicators, branch performance, and product/purpose analysis.
2. **Credit/debit transaction monitoring** — inflow/outflow value, bank and branch activity, transaction methods, time trends, customer/account activity, and high-value review flags.

The project is intentionally positioned as a **Data Analyst / BI Analyst portfolio project**, not as a fraud-detection or credit-scoring system.

> **Core skill focus:** SQL 40% · Power BI 40% · Excel 20%

---

## Business Scenario

A retail bank needs a consistent management view across lending operations and day-to-day transaction activity. Existing reports contain useful analysis, but KPI definitions and labels are not fully standardized across tools.

Management wants answers to questions such as:

- How large is the lending portfolio and how many unique clients does it actually represent?
- What are the recorded recovery, delinquency, default, and on-time repayment indicators?
- Which branches and loan segments deserve deeper review?
- How are credit and debit flows changing over time?
- Which banks, branches, customers, and transaction methods drive the most activity?
- Which transactions exceed the governed high-value review threshold?
- Are monthly trends based on complete data periods?

The project therefore follows this workflow:

```text
Business Questions
      ↓
Excel Source Review & Reconciliation
      ↓
SQL Data Quality Checks
      ↓
SQL KPI / Trend / Segment Analysis
      ↓
Power BI Modeling & Reporting
      ↓
Business Findings
      ↓
Recommendations & Monitoring
```

---

## Technology Focus

| Tool | Focus | Role in the project |
|---|---:|---|
| **SQL / PostgreSQL 13+** (MySQL 8 version also included) | **40%** | validation, aggregation, joins/CTEs, window functions, rankings, KPI logic, trends, segmentation, reconciliation views |
| **Power BI** | **40%** | dashboarding, DAX measures, filtering, drill-down, management reporting, decision-support views |
| **Excel** | **20%** | source review, PivotTables/PivotCharts, calculations, reconciliation, ad-hoc analyst checks |

Python and Tableau are intentionally not presented as core technologies in this version.

---

## SQL Coverage

The corrected SQL layer includes practical Data Analyst topics:

- `SELECT`, `WHERE`, `GROUP BY`, `HAVING`, `ORDER BY`
- `CASE WHEN`
- aggregate functions
- distinct-customer/account metrics
- data-quality checks for NULLs, duplicates, invalid values, incomplete periods, and cross-field consistency (default / delinquency / threshold)
- CTEs
- subqueries
- window functions
- `LAG()`
- `ROW_NUMBER()`
- `RANK()` / `DENSE_RANK()`
- rolling 3-month averages
- contribution percentages
- month-over-month growth
- customer/branch/product segmentation
- cross-tool reconciliation queries
- Power BI-ready SQL views

See [`sql/README.md`](sql/README.md).

---

## Key KPI Definitions

### Loan portfolio

- **Loan Records** = row count in the loan fact table
- **Unique Clients** = distinct client IDs
- **Active Clients** = distinct clients with active loan status
- **Total Loan Amount** = sum of loan amount
- **Principal Recovery Rate** = recovered principal / loan amount
- **Status Default Rate** (recommended) = loans with status "Default" / loan records (10.30%)
- **Default Flag Rate** (legacy) = `Is_Default_Loan = Y` records / loan records (5.00%)
- **Delinquency Rate** = delinquent loan records / loan records
- **On-Time Repayment Rate** = on-time records / loan records

### Transaction operations

- **Total Credit** = sum of credit transaction amount
- **Total Debit** = sum of debit transaction amount
- **Net Flow** = total credit − total debit
- **Transaction Count** = number of transaction records
- **Unique Customers** = distinct customer IDs
- **Unique Accounts** = distinct account numbers
- **Transactions per Account** = transaction count / unique accounts
- **High-Value Review Count** = transactions above the governed review threshold

The high-value rule is a **screening/review rule**, not a fraud label.

---

## Data Notice & Known Limitations

- **The data appears to be simulated.** Transaction amounts are uniformly distributed, credit and debit totals almost match, review rates are identical across segments, and loan risk fields show no relationship with default. The project demonstrates analytical *method*; it does not make real-world credit or fraud claims.
- **Two conflicting "default" definitions exist in the source** (`Loan_Status = 'Default'` → 10.30%, `Is_Default_Loan = 'Y'` → 5.00%, only 10 loans in both). Both are reported and labelled; see `reports/data_quality_report.md`.
- **Delinquency flag and repayment behaviour disagree** (only 29 of 207 "Very Late" loans are flagged delinquent).
- **One transaction per customer and per account.** Retention, customer segmentation and top-customer SQL are kept as reusable patterns but are marked non-reportable on this dataset.
- **Two high-value thresholds exist** (governed 4,500 → 10,428 rows; legacy workbook flag 4,000 → 20,426 rows). The governed rule is used for KPIs.
- **December 2024 has one day of data** and is excluded from trend conclusions.
- **Power BI correction status.** The corrected copy updates the PBIX report layer where it can be verified safely outside Power BI Desktop. Loan dashboards now label the 2,000 value as **Loan Records**, relabel the 5% card as **Default Flag Rate**, fix **Delinquency Rate**, and rename **Product Profitability** to **Product Interest Contribution**. The transaction dashboard replaces the invalid **Account Activity Ratio** with **Transaction Count** and rewrites the review-count visuals to count rows with `Amount > 4500` at the visual layer. The legacy source flag remains available only as an explicitly labelled **Legacy Source Flag (>= Rs 4,000)** slicer. Power BI Desktop refresh and interaction testing remain unverified; see `docs/powerbi_dashboard_audit.md`.

---

## Analytical Corrections Made

- **Loan Records vs Unique Clients** are separated (2,000 vs 870).
- **Retention** is rebuilt with the previous-period cohort as the denominator.
- **Account Activity Ratio** (`COUNT(*) / SUM(Balance)`) is removed and replaced with interpretable metrics.
- **"High Risk / Suspicious"** is renamed **High-Value Review**; the threshold is stored in `analytics_parameters`.
- **"Product Profitability"** becomes **Product Interest Contribution** (no cost data exists).
- **Funded fields** are separated: `Funded_Amount` (₹52.36M) vs `Funded_Amount_Inv` (₹46.72M).
- **Period completeness** checks prevent partial months being read as declines.
- **Source-data conflicts** (default, delinquency, threshold, grain) are quantified in `sql/07_consistency_checks.sql`.
- **Client-ID column name** is standardised to `client_id` across all scripts.

The original ZIP supplied by the user remains unchanged. In this corrected copy, only report-definition/package content that could be inspected and validated structurally was edited. The embedded semantic models were not rewritten. Power BI Desktop refresh, DAX execution, and interaction testing were not available in this environment.

---

## Repository Structure

```text
BankSphere_Intelligence_SQL_Excel_PowerBI/
├── README.md
├── CHANGELOG.md
├── .gitignore
├── data/
│   ├── README.md
│   ├── export_excel_to_csv.py
│   └── csv/                    # CSVs for PostgreSQL import
├── sql/                        # MySQL 8 scripts
│   ├── postgres/               # PostgreSQL scripts (00_setup … 07_consistency_checks, README)
│   ├── README.md
│   ├── 00_setup.sql
│   ├── 01_loan_data_quality.sql
│   ├── 02_loan_kpi_analysis.sql
│   ├── 03_transaction_data_quality.sql
│   ├── 04_transaction_kpi_analysis.sql
│   ├── 05_powerbi_views.sql
│   ├── 06_reconciliation_queries.sql
│   └── 07_consistency_checks.sql
├── excel/
│   ├── README.md
│   ├── BankSphere_Loan_Portfolio_Analysis.xlsx
│   └── BankSphere_Transaction_Analysis.xlsx
├── powerbi/
│   ├── DAX_Measures.md
│   ├── BankSphere_Loan_Portfolio_Dashboard_1.pbix
│   ├── BankSphere_Loan_Portfolio_Dashboard_2.pbix
│   └── BankSphere_Transaction_Intelligence_Dashboard.pbix
├── reports/
│   ├── business_problem.md
│   ├── stakeholder_requirements.md
│   ├── kpi_dictionary.md
│   ├── data_quality_report.md
│   ├── key_findings.md
│   ├── recommendations.md
│   └── executive_summary.md
├── docs/
│   ├── project_architecture.md
│   ├── sql_query_catalog.md
│   ├── excel_workbook_audit.md
│   ├── powerbi_dashboard_audit.md
│   ├── job_description_coverage.md
│   └── interview_guide.md
└── images/
    └── *_legacy.png
```

---

## How to Review the Project

1. Start with [`reports/business_problem.md`](reports/business_problem.md).
2. Read [`reports/kpi_dictionary.md`](reports/kpi_dictionary.md) before interpreting dashboard metrics.
3. Run the SQL scripts in the order documented in [`sql/postgres/README.md`](sql/postgres/README.md) (PostgreSQL) or [`sql/README.md`](sql/README.md) (MySQL).
4. Use the Excel workbooks for source-level validation and reconciliation.
5. Read [`reports/data_quality_report.md`](reports/data_quality_report.md) (part B) for the open source-data conflicts.
6. Review [`docs/powerbi_dashboard_audit.md`](docs/powerbi_dashboard_audit.md) for completed Power BI corrections and the remaining Desktop-only verification items.
7. Use [`docs/interview_guide.md`](docs/interview_guide.md) to prepare for project discussion.

---

## Portfolio Positioning

**Resume title:**  
**Banking Performance & Transaction Analytics**

**Recommended repo name:**  
`banksphere-intelligence-banking-analytics`

**One-line description:**  
SQL, Excel, and Power BI banking analytics project focused on loan portfolio performance, transaction monitoring, KPI governance, data quality, and management reporting.
