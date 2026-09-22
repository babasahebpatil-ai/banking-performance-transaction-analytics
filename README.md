# 🏦 Banking Performance & Transaction Analytics

Banking Performance & Transaction Analytics is an end-to-end Data Analytics project focused on understanding loan portfolio performance and banking transaction activity using SQL,Excel, and Power BI.
The project analyzes lending performance, client activity, repayment behavior, default and delinquency indicators, branch-level patterns, credit/debit transactions, and high-value transaction reviews.
The objective is to convert raw banking data into consistent KPIs, analytical findings, and management-ready reporting while also identifying data-quality and KPI-definition issues.

---

## 🎯 Business Problem

A banking organization needs a reliable analytical view of two major operational areas:
1. Loan Portfolio Performance
2. Credit & Debit Transaction Activity
Existing data contains useful information, but several KPI definitions and source fields are not fully consistent.
The analysis is designed to answer questions such as:
- How many loans and unique clients are present in the portfolio?
- What is the total lending exposure?
- What are the recorded default, delinquency, recovery, and repayment patterns?
- Which branches and loan segments require closer review?
- Which loan purposes contribute most to portfolio activity?
- How are credit and debit transactions distributed?
- Which transaction methods, banks, and branches generate the most activity?
- How many transactions exceed the governed high-value review threshold?
- Are KPI definitions consistent across SQL, Excel, and Power BI?
- Are incomplete reporting periods affecting trend interpretation?
The project focuses on turning these questions into measurable KPIs and actionable business insights.

---

## ✅ Project Objectives

Analyze overall loan portfolio performance.

Distinguish loan records from unique banking clients.

Evaluate default, delinquency, repayment, and recovery indicators.

Identify branch and loan-purpose concentration.

Analyze credit and debit transaction activity.

Monitor transaction volume across banks, branches, and transaction methods.

Identify transactions above a governed high-value review threshold.

Perform SQL-based data-quality and consistency checks.

Reconcile KPI definitions across SQL, Excel, and Power BI.

Build management-ready dashboards and analytical reports.

Convert analytical findings into practical business recommendations.

---

## 📊 Dataset Overview

| Dataset | Records |
|---|---:|
| Loan Portfolio | 2,000 |
| Banking Transactions | 100,000 |

### Key Loan Metrics

| Metric | Value |
|---|---:|
| Loan Records | 2,000 |
| Unique Clients | 870 |
| Total Loan Amount | ₹52.36M |
| Status Default Rate | 10.30% |
| Legacy Default Flag Rate | 5.00% |
| Delinquency Rate | 10.35% |
| On-Time Repayment Rate | 71.05% |

### Transaction Metrics

| Metric | Value |
|---|---:|
| Transactions | 100,000 |
| High-Value Threshold | > ₹4,500 |
| High-Value Transactions | 10,428 |
| High-Value Transaction Share | 10.43% |

---

## 🛠️ Tools Used

| Tool | Purpose |
|---|---|
| **PostgreSQL / SQL** | Data validation, KPI analysis, aggregation, CTEs, window functions, trends and reconciliation |
| **Excel** | Data exploration, PivotTables, KPI validation and analysis |
| **Power BI** | Interactive dashboards, KPIs, filters and business reporting |
| **DAX** | Dashboard measures and calculated KPIs |

---

## 🔄 Project Workflow

```text id="4jr4sp"
Raw Banking Data
       |
       v
Data Quality Checks
       |
       v
SQL Analysis
       |
       v
Excel Validation
       |
       v
Power BI Dashboard
       |
       v
Business Insights
       |
       v
Recommendations
```

---

## 🧮 SQL Analysis

SQL is used for data validation, KPI calculations, trend analysis and business analysis.

Key techniques include:

- Aggregations
- `CASE WHEN`
- Subqueries
- Common Table Expressions
- Window Functions
- Ranking
- Conditional Aggregation
- Month-over-Month Analysis
- Data Quality Checks
- KPI Reconciliation

---

## 📗 Excel Analysis

Excel is used for:

- Data exploration
- PivotTables
- KPI calculations
- Trend analysis
- Business validation
- SQL and Power BI reconciliation

Main workbooks:

```text id="vrm0f5"
excel/BankSphere_Loan_Portfolio_Analysis.xlsx
excel/BankSphere_Transaction_Analysis.xlsx
```

---

## 📈 Power BI Dashboard

The project includes interactive Power BI reports for loan and transaction analysis.

### Dashboard Areas

- Loan Portfolio KPIs
- Unique Clients
- Default Rate
- Delinquency Rate
- Repayment Performance
- Branch Performance
- Loan Purpose Analysis
- Credit vs Debit Activity
- Transaction Trends
- High-Value Transactions

Power BI files are available inside:

```text id="uvxk6l"
powerbi/
```

---

## 🖼️ Dashboard Preview

### Loan Portfolio Dashboard

![Loan Portfolio Dashboard](images/loan_portfolio_overview_legacy.png)

### Transaction Dashboard

![Transaction Dashboard](images/transaction_overview_legacy.png)

---

## 🔍 Key Findings

### 1. Loan Records vs Unique Clients

The portfolio contains:

- **2,000 loan records**
- **870 unique clients**

This distinction prevents loan records from being incorrectly reported as customer count.

### 2. Default Definitions Differ

Two default definitions exist in the source data:

- **Status Default Rate:** 10.30%
- **Legacy Default Flag Rate:** 5.00%

The project reports both separately to avoid KPI inconsistency.

### 3. Portfolio Concentration

The Services loan purpose represents approximately:

- **56.9% of loans**
- **57.7% of recorded interest income**

### 4. Branch Concentration

The top five branches contribute approximately:

**40.4% of portfolio value**

### 5. High-Value Transactions

Using the ₹4,500 review threshold:

- **10,428 transactions**
- **10.43% of total transactions**

were identified for high-value review.

---

## 💡 Business Recommendations

- Standardize default and delinquency KPI definitions.
- Monitor concentration across loan purposes and branches.
- Improve borrower retention and repeat-loan strategies.
- Use consistent high-value transaction rules across reporting tools.
- Validate SQL, Excel, and Power BI KPIs before dashboard publication.
- Monitor incomplete reporting periods before interpreting trends.

---

## 📁 Repository Structure

```text id="k69t6g"
banking-performance-transaction-analytics/
│
├── README.md
│
├── data/
│   └── csv/
│
├── sql/
│   ├── 00_setup.sql
│   ├── 01_loan_data_quality.sql
│   ├── 02_loan_kpi_analysis.sql
│   ├── 03_transaction_data_quality.sql
│   ├── 04_transaction_kpi_analysis.sql
│   ├── 05_powerbi_views.sql
│   ├── 06_reconciliation_queries.sql
│   └── 07_consistency_checks.sql
│
├── excel/
│   ├── BankSphere_Loan_Portfolio_Analysis.xlsx
│   └── BankSphere_Transaction_Analysis.xlsx
│
├── powerbi/
│   ├── BankSphere_Loan_Portfolio_Dashboard_1.pbix
│   ├── BankSphere_Loan_Portfolio_Dashboard_2.pbix
│   ├── BankSphere_Transaction_Intelligence_Dashboard.pbix
│   └── DAX_Measures.md
│
├── images/
│
└── reports/
```

---

## 🚀 How to Explore the Project

Clone the repository:

```bash id="3s745k"
git clone https://github.com/babasahebpatil-ai/banking-performance-transaction-analytics.git
```

Move into the project folder:

```bash id="zxf75e"
cd banking-performance-transaction-analytics
```

For PostgreSQL analysis, run the scripts inside:

```text id="p0wpen"
sql/postgres/
```

For dashboard analysis, open the `.pbix` files inside:

```text id="neyn1w"
powerbi/
```

using Power BI Desktop.

---

## 🧠 Skills Demonstrated

`SQL` `PostgreSQL` `Excel` `Power BI` `DAX` `Data Cleaning` `Data Validation` `Data Analysis` `CTEs` `Window Functions` `KPI Analysis` `Dashboard Development` `Business Analysis` `Data Visualization`

---

## ⭐ Project Highlights

- Analyzed **2,000 loan records**
- Identified **870 unique clients**
- Analyzed **100,000 transactions**
- Built SQL-based KPI and validation workflows
- Identified **10.30% status-based default rate**
- Reconciled a **5.00% legacy default flag**
- Identified **10,428 high-value transactions**
- Developed Excel analytical workbooks
- Built interactive Power BI dashboards
- Generated business insights and recommendations

---

## 👤 Author

**Babasaheb Patil**

- GitHub: [babasahebpatil-ai](https://github.com/babasahebpatil-ai)
- LinkedIn: [Babasaheb Patil](https://www.linkedin.com/in/babasaheb-patil-22a476319)
