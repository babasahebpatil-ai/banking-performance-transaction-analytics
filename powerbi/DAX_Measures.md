# Recommended DAX Measures

Use the exact table/column names from your model when implementing these in Power BI.

## Loan portfolio

```DAX
Loan Records =
COUNTROWS('final_fact_cleaned')
```

```DAX
Unique Clients =
DISTINCTCOUNT('final_fact_cleaned'[Client _id])
```

```DAX
Active Clients =
CALCULATE(
    DISTINCTCOUNT('final_fact_cleaned'[Client _id]),
    'final_fact_cleaned'[Loan_Status] = "Active"
)
```

```DAX
Total Loan Amount =
SUM('final_fact_cleaned'[Loan_Amount])
```

```DAX
Principal Recovery Rate =
DIVIDE(
    SUM('final_fact_cleaned'[Total_Rec_Prncp]),
    SUM('final_fact_cleaned'[Loan_Amount])
)
```

```DAX
-- Legacy, flag-based (5.00%). Label the card "Default Flag Rate".
Default Flag Rate =
DIVIDE(
    CALCULATE(COUNTROWS('final_fact_cleaned'), 'final_fact_cleaned'[Is_Default_Loan] = "Y"),
    COUNTROWS('final_fact_cleaned')
)
```

```DAX
-- Recommended primary definition (10.30%).
Status Default Rate =
DIVIDE(
    CALCULATE(COUNTROWS('final_fact_cleaned'), 'final_fact_cleaned'[Loan_Status] = "Default"),
    COUNTROWS('final_fact_cleaned')
)
```

```DAX
Delinquency Rate =
DIVIDE(
    CALCULATE(COUNTROWS('final_fact_cleaned'), 'final_fact_cleaned'[Is_Delinquent_Loan] = "Y"),
    COUNTROWS('final_fact_cleaned')
)
```

## Transaction operations

```DAX
Transaction Count =
COUNTROWS('credit_debit_bank')
```

```DAX
Unique Customers =
DISTINCTCOUNT('credit_debit_bank'[Customer_ID])
```

```DAX
Unique Accounts =
DISTINCTCOUNT('credit_debit_bank'[Account_Number])
```

```DAX
Transactions per Account =
DIVIDE([Transaction Count], [Unique Accounts])
```

```DAX
Total Credit =
CALCULATE(
    SUM('credit_debit_bank'[Amount]),
    'credit_debit_bank'[Transaction_Type] = "Credit"
)
```

```DAX
Total Debit =
CALCULATE(
    SUM('credit_debit_bank'[Amount]),
    'credit_debit_bank'[Transaction_Type] = "Debit"
)
```

```DAX
Net Flow =
[Total Credit] - [Total Debit]
```

```DAX
Credit to Debit Ratio =
DIVIDE([Total Credit], [Total Debit])
```

For the current project threshold of 4,500:

```DAX
High-Value Review Count =
CALCULATE(
    [Transaction Count],
    'credit_debit_bank'[Amount] > 4500
)
```

```DAX
High-Value Review Share =
DIVIDE([High-Value Review Count], [Transaction Count])
```

## Required naming changes

Use:

- `High-Value Review Count` instead of `Suspicious Transaction Count`
- `High-Value Review Flag` instead of `High Risk`
- `Transactions per Account` or `Unique Accounts` instead of the existing `Account Activity Ratio`
- `Product Interest Contribution` instead of `Product Profitability` when only interest income is available
