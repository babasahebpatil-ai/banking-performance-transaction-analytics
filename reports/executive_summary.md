# Executive Summary

Banking Performance & Transaction Analytics analyses a simulated retail bank in two independent modules: a **loan portfolio** (2,000 loans, 870 clients, ₹52.4M) and **transaction activity** (100,000 transactions, ₹255M in flows).

**Headline results.** The portfolio is stable in volume, but its risk metrics cannot yet be trusted: status-based default is 10.3% while the flag-based figure is 5.0%, with almost no overlap, and delinquency conflicts with recorded repayment behaviour. Standard risk fields (credit score, grade, employment) show no relationship with default. Two regions, Bihar/Patna and Odisha/Bhubaneswar, have default rates about double the average, on small samples. Only about one in four 2020 borrowers returned in 2021, and over half of loan value and interest income sits in one purpose category (Services).

In transactions, credit and debit balance almost exactly (net ₹0.32M). Review rates for the ₹4,500 high-value rule are uniform (~10%) across every branch, bank and method, and monthly variation is driven by month length, not behaviour. Because each customer has a single transaction, customer-level analysis is not possible on this dataset.

**Main analytical contribution.** Metric governance: separating loan records from unique clients, exposing conflicting default, delinquency and threshold definitions in the source data, and giving every KPI one documented meaning across SQL, Excel and Power BI.

**Use with care.** The data looks simulated. The outputs demonstrate method and highlight where deeper review is needed; they should not drive automated fraud, credit or customer-risk decisions.
