# Excel Workbooks

Excel represents approximately **20% of the intended project focus**.

## Files

- `BankSphere_Loan_Portfolio_Analysis.xlsx`
- `BankSphere_Transaction_Analysis.xlsx`

The original workbooks are preserved because they contain the actual working data, formulas, PivotTables/PivotCharts, and dashboard artifacts.

### Loan workbook structure observed

The workbook contains KPI-specific sheets, source/chart data, and a dashboard. Its package includes multiple PivotTables and chart objects.

### Transaction workbook structure observed

The workbook contains the transaction source sheet plus multiple analysis/dashboard sheets. Its package also includes PivotTables, charts, and extensive formulas.

## Recommended analyst workflow

Use Excel for:

1. source-level review
2. quick category/field checks
3. PivotTable ad-hoc analysis
4. KPI reconciliation with SQL
5. spot-checking Power BI totals
6. conditional-formatting based exception review

Do not treat Excel as the system of record for governed KPI definitions. The SQL scripts in `sql/` are the primary reusable analytical logic.
