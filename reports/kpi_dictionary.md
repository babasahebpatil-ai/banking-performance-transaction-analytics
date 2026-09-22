# KPI Dictionary

## Loan portfolio

| KPI | Definition | Value | Notes |
|---|---|---:|---|
| Loan Records | `COUNT(*)` | 2,000 | Never label as "clients" |
| Unique Clients | distinct `client_id` | 870 | Population metric |
| Active Clients | distinct `client_id` with `Loan_Status = 'Active'` | 324 | 402 active loans |
| Total Loan Amount | sum of `Loan_Amount` | ₹52.36M | |
| Total Funded Amount | sum of `Funded_Amount` | ₹52.36M | Separate from invested field |
| Invested Funded Amount | sum of `Funded_Amount_Inv` | ₹46.72M | The legacy "Funded Amount 47M" card shows this field |
| Average Loan Amount | mean of `Loan_Amount` | ₹26.18K | |
| Principal Recovery Rate | recovered principal / loan amount | 99.05% | "As recorded" – see data-quality items B3 |
| Recorded Interest Income | sum of `Total_Rrec_Int` | ₹5.06M | Revenue component, not profit |
| **Status Default Rate** *(recommended primary)* | loans with `Loan_Status = 'Default'` / loan records | **10.30%** | Observable outcome |
| Default Flag Rate *(legacy, reconciliation only)* | loans with `Is_Default_Loan = 'Y'` / loan records | 5.00% | Only 10 loans overlap with status default (B1) |
| Delinquency Rate | loans with `Is_Delinquent_Loan = 'Y'` / loan records | 10.35% | Not consistent with `Repayment_Behavior` (B2) |
| On-Time Repayment Rate | `Repayment_Behavior = 'On-Time'` / loan records | 71.05% | Record-level rate |
| Client Retention (period) | clients in previous *and* current period / clients in previous period | 24.5% (2020→2021) | Cohort denominator |

## Transaction operations

| KPI | Definition | Value | Notes |
|---|---|---:|---|
| Transaction Count | rows | 100,000 | |
| Unique Customers / Accounts | distinct IDs | 100,000 / 100,000 | Equal to row count – see B5 |
| Transactions per Account | count / unique accounts | 1.00 | Constant on this dataset; meaningful only with repeat transactions |
| Total Credit | sum of credit amounts | ₹127.60M | |
| Total Debit | sum of debit amounts | ₹127.29M | |
| Net Flow | credit − debit | ₹0.32M | |
| Credit-to-Debit Ratio | credit / debit | 1.0025 | |
| Average Transaction Amount | mean amount | ₹2,549 | |
| **High-Value Review Count** | amount > governed threshold (4,500) | 10,428 | Screening only; not fraud |
| High-Value Review Share | review count / transaction count | 10.43% | |
| Legacy Source Flag Count | source `High-Risk Flag` (≥ 4,000) | 20,426 | Reconciliation only (B6) |
| Avg Transactions per Active Day | monthly count / days with data | 292–301 | Use instead of raw monthly counts to compare months |
| Branch MoM Growth | complete-month value vs previous complete month | — | Exclude partial periods; prefer per-day normalisation |
