# Key Findings

All figures are reproduced from the supplied workbooks and can be re-run with the scripts in `sql/`. The data appears to be simulated (see `data_quality_report.md`, B7), so the findings are framed as **what the analysis shows and what it cannot support**.

## Loan portfolio

1. **Scale.** 2,000 loan records across 870 unique clients (about 2.3 loans per client), ₹52.36M disbursed, ₹26.18K average loan. Loan volume is steady at ₹5.4–5.8M a year from 2015–2020, rises to ₹6.7M in 2021, dips 18.6% in 2022 and recovers 16.2% in 2023. There is no 2024 data.
2. **Default depends on the definition.** Status-based default is **10.30%**; the flag-based figure is **5.00%**, and only 10 loans satisfy both. Delinquency and repayment behaviour also disagree (only 29 of 207 "Very Late" loans are flagged delinquent). Headline risk numbers should not be quoted without stating the definition.
3. **Standard risk indicators show almost no signal.** Credit score has a correlation of ~0.03 with status default, and default rates by credit-score band range from 9.5% to 14.0% with the *highest* rate in the 800+ band. Grade, product, purpose, employment type, income range and home ownership show no statistically meaningful difference either (all p > 0.1 on a chi-square test). In real portfolios these fields normally separate risk; here they do not, which supports the conclusion that the data is simulated and that segment rankings on these fields should not drive decisions.
4. **Geographic pockets worth a look.** Region and state differ significantly in status default (p ≈ 0.02 / 0.01). Bihar / Patna (19.6% on 92 loans) and Odisha / Bhubaneswar (23.3% on 30 loans) sit well above the 10.3% average. Sample sizes are small, so this is a prioritisation signal, not proof. No geographic difference is visible using the flag-based definition.
5. **Concentration.** The top five branches hold 40.4% of loan value. *Services* loans are 56.9% of records and 57.7% of recorded interest income, so interest income is closely tied to that one purpose category.
6. **Client retention is low.** Only 49 of the 200 clients who borrowed in 2020 borrowed again in 2021 (24.5%).
7. **Integrity flags.** 185 loans show recovered principal above total payment; 49.6% have funded amount above loan amount; recorded recovery of 99.05% sits oddly next to a 10.3% status-default rate.

## Transaction activity

1. **Scale and balance.** 100,000 records; ₹127.60M credit against ₹127.29M debit, a net flow of ₹0.32M (credit-to-debit ratio 1.0025). Amounts run from ₹100 to ₹5,000 with a mean of ₹2,549.
2. **Grain limitation.** Every customer and account appears once, so customer retention, top-customer and activity-segment analysis cannot be performed meaningfully. Transactions per account is a constant 1.00.
3. **High-value review.** The governed rule (> ₹4,500) flags 10,428 transactions (10.43%). The workbook's own legacy flag (≥ ₹4,000) flags 20,426 (20.4%). The two rules should not be mixed.
4. **Review rates are uniform.** The share of high-value transactions is 10.0–10.8% for every branch, bank, transaction method and description (none significantly different). There is no branch, bank or method to single out; a threshold rule alone cannot prioritise review effort here.
5. **Monthly "trends" are mostly calendar length.** Monthly counts vary between 8,578 and 9,344 because months differ in length; transactions per active day are stable at 292–301. February's apparent dip and any month-over-month "growth" on raw counts are calendar effects. December contains only 1 day of data (305 rows) and is excluded from conclusions.

## What these findings do not support

- Fraud or credit-risk conclusions for individual customers or loans.
- Profitability by product (no cost data).
- Behavioural customer analysis (one transaction per customer).
