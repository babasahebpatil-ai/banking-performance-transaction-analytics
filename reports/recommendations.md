# Business Recommendations

## 1. Resolve the default and delinquency definitions before reporting risk
**Evidence:** Status default = 10.30%, flag default = 5.00%, overlap = 10 loans; delinquency flag and repayment behaviour also disagree.
**Action:** Ask the data owner how `Is_Default_Loan` and `Is_Delinquent_Loan` are derived; adopt one definition per KPI and record it in the KPI dictionary. Until then report both rates, labelled.
**Owner:** Data Owner / BI  |  **Monitor:** overlap between status and flag (target: near-complete agreement).

## 2. Prioritise review of higher-default regions, with a sample-size caveat
**Evidence:** Bihar / Patna 19.6% (92 loans) and Odisha / Bhubaneswar 23.3% (30 loans) versus a 10.3% portfolio average.
**Action:** Review branch-level collections and underwriting in these regions; re-test when more loans accumulate.
**Owner:** Lending Operations / Collections  |  **Monitor:** status default rate by region, with loan counts alongside.

## 3. Do not rely on credit score, grade or employment type for risk decisions on this data
**Evidence:** No usable relationship between these fields and default (correlation ≈ 0.03; no significant group differences).
**Action:** Validate the scoring fields against outcomes on real data before using them in policy.
**Owner:** Risk / Portfolio Management.

## 4. Address low repeat-borrowing
**Evidence:** Only 24.5% of 2020 borrowers borrowed again in 2021.
**Action:** Investigate why clients do not return (product fit, repayment experience, competition); consider retention offers for clients with good repayment records.
**Owner:** Lending Operations  |  **Monitor:** yearly retention rate (cohort denominator).

## 5. Diversify beyond the Services purpose category
**Evidence:** Services is 56.9% of loans and 57.7% of recorded interest income; the top five branches hold 40.4% of value.
**Action:** Track concentration monthly and set exposure limits by purpose and branch.
**Owner:** Portfolio Management.

## 6. Use one high-value threshold and treat it as a workload rule
**Evidence:** Governed 4,500 rule = 10.4% of transactions; legacy 4,000 flag = 20.4%.
**Action:** Publish one threshold (stored in `analytics_parameters`); recalibrate against confirmed review outcomes. Because review rates are uniform across branches, banks and methods, use risk-based sampling rather than a bare amount cut-off if review capacity is limited.
**Owner:** Transaction Operations / Risk Review.

## 7. Compare months on a per-day basis and exclude partial periods
**Evidence:** Monthly counts vary only with month length; December 2024 has one day of data.
**Action:** Report average transactions per active day and apply `period_status` before any month-over-month statement.
**Owner:** BI / Data Operations.

## 8. Capture transaction history at customer level
**Evidence:** One transaction per customer and account.
**Action:** Extract multi-transaction history per account before building retention, segmentation or behavioural monitoring.
**Owner:** Data Engineering.

## 9. Reconcile SQL, Excel and Power BI before every release
**Action:** Run `sql/06_reconciliation_queries.sql` and `sql/07_consistency_checks.sql` as a release checklist; investigate any card that does not match.
**Owner:** Analyst / BI Developer.
