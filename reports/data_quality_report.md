# Data Quality Report

This report has two parts: **(A)** definition problems that were fixed in the analytical layer, and **(B)** conflicts that exist in the *source data itself* and are still open. Part B matters most: these are questions to raise with a data owner before any number is used for a decision. All figures were reproduced from the supplied workbooks and can be re-run with `sql/07_consistency_checks.sql`.

---

## A. Definition problems fixed in the SQL / documentation layer

### Loan module

| # | Problem | Fix |
|---|---|---|
| A1 | 2,000 loan rows were labelled "Total Clients". | Report **Loan Records** (2,000) and **Unique Clients** (870) separately. |
| A2 | Two funded-amount fields were mixed. `Funded_Amount` totals ₹52.36M; `Funded_Amount_Inv` totals ₹46.72M. | Both are kept as separate governed metrics. The legacy dashboard card "Funded Amount 47M" actually shows the *invested* field. |
| A3 | Interest income was called "profitability". | Renamed **Recorded Interest Income / Interest Contribution**; costs and margins are not in the data. |
| A4 | Retention used an inner-join denominator. | Rebuilt with a previous-period cohort denominator (2020 → 2021: 49 of 200 clients retained = **24.5%**). |

### Transaction module

| # | Problem | Fix |
|---|---|---|
| A5 | `COUNT(*) / SUM(Balance)` "Account Activity Ratio" mixed a count with money. | Removed; replaced by Unique Accounts and Transactions per Account. |
| A6 | Amount-based flag was called "suspicious / high risk". | Renamed **High-Value Review** (screening rule, not a fraud label). |
| A7 | Partial month (December 2024 = 1 day, 305 rows) could look like a collapse. | `period_status` in SQL views; December excluded from trend conclusions. |

---

## B. Open conflicts found in the source data

### B1. Two incompatible definitions of "default" (loan module) — HIGH impact

| Loan_Status | Loans | Flagged `Is_Default_Loan = Y` |
|---|---:|---:|
| Active | 402 | 18 |
| **Default** | **206** | **10** |
| Fully Paid | 787 | 41 |
| Paid Off | 605 | 31 |
| **Total** | 2,000 | **100** |

- `Loan_Status = 'Default'` gives **10.30%**; the `Is_Default_Loan` flag gives **5.00%**.
- Only 10 loans satisfy both. 90 of the 100 flagged loans have a status of Active / Paid, and 196 of 206 status-default loans are *not* flagged.
- The headline "5% default" therefore describes almost none of the loans whose status says Default.

**Handling in this project.** Both rates are reported, labelled **Default Flag Rate** (5.00%) and **Status Default Rate** (10.30%). The Status Default Rate is the recommended primary KPI because it reflects an observable loan outcome. The flag-based rate is kept only so results reconcile with the existing dashboard. **Open question for the data owner:** how is `Is_Default_Loan` derived?

### B2. Delinquency flag disagrees with repayment behaviour — HIGH impact

| Repayment_Behavior | Loans | Flagged delinquent |
|---|---:|---:|
| On-Time | 1,421 | 147 |
| Late | 372 | 31 |
| Very Late | 207 | 29 |

Both the flag and the "Very Late" bucket contain 207 loans, but only 29 loans are in both. 147 loans described as *on-time* are flagged delinquent. Delinquency (10.35%) and on-time (71.05%) are reported as recorded, but they are not consistent with each other.

### B3. Recovery looks too good for the outcome mix — MEDIUM

Principal recovery is **99.05%** while 10.3% of loans have status Default. Additionally, **185 loans** show recovered principal greater than total payment, and **991 loans (49.6%)** have `Funded_Amount` above `Loan_Amount`. These are integrity issues in the payment fields; recovery should be treated as "as recorded", not as a reliable performance measure.

### B4. Overlapping status labels — LOW

`Fully Paid` (787) and `Paid Off` (605) appear to describe the same outcome. Grouped as "Closed – repaid" only after confirmation.

### B5. One transaction per customer and per account (transaction module) — HIGH impact

100,000 rows = 100,000 distinct customers = 100,000 distinct accounts. Consequences:

- Transactions per Account is always **1.00**.
- Retention, customer-activity segmentation, top-customer ranking and account-to-customer mapping checks cannot describe behaviour over time. They are kept in the SQL as reusable patterns and are explicitly marked "not reportable on this dataset".

### B6. Two different high-value thresholds — MEDIUM

| Rule | Cut-off | Rows flagged | Share |
|---|---:|---:|---:|
| Governed High-Value Review (SQL / DAX) | > 4,500 | 10,428 | 10.4% |
| Legacy `High-Risk Flag` column in the workbook | ≥ 4,000 | 20,426 | 20.4% |

Amounts range from 100 to 5,000, so 4,500 already sits in the top decile. The governed rule stays at 4,500; the legacy cut-off is stored in `analytics_parameters` as `source_flag_threshold` for reconciliation only. Any report that quotes ~20K "high-risk" transactions is using the legacy column, not the governed rule.

### B7. Synthetic-looking data — CONTEXT

Transaction amounts are uniformly spread between 100 and 5,000, credit and debit totals differ by 0.25%, every segment shows the same review rate (10.0–10.8%), and risk indicators in the loan table carry almost no signal (see `key_findings.md`). This data should be presented as a **simulated banking dataset**. It is suitable for demonstrating method, not for drawing real-world credit or fraud conclusions.

### B8. Housekeeping

- The transaction `MAIN` sheet has three empty trailing columns (`Unnamed: 14–16`) and one stray text value ("High Risk") in the last one. They are ignored on import.
- Loan client-ID column name varies by import tool; all scripts use `client_id` (see `sql/00_setup.sql`).
- Numbered/generic Excel sheet names (`1`–`9`, `A`, `Sheet1`) should be renamed inside Excel by hand; renaming them by script would break PivotTable and formula references.

---

## SQL quality controls

Critical NULL checks · duplicate checks · invalid amounts · category review · credit-score range · account/customer grain · period completeness · cross-tool reconciliation · **default / delinquency / threshold consistency checks (`07_consistency_checks.sql`)**.
