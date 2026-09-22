"""
Export the two Excel workbooks to CSV files that match the PostgreSQL tables
created by sql/postgres/00_setup.sql.

Usage (from the project root):   python data/export_excel_to_csv.py
Requires: pandas, openpyxl
"""
import re
from pathlib import Path
import pandas as pd

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "data" / "csv"
OUT.mkdir(parents=True, exist_ok=True)


def snake(name: str) -> str:
    """'Client id' -> client_id, 'Age _T' -> age_t, 'Month-Year' -> month_year"""
    return re.sub(r"[^0-9a-zA-Z]+", "_", str(name).strip()).strip("_").lower()


# Loan portfolio: first sheet of the loan workbook (2,000 rows, 54 columns)
loans = pd.read_excel(ROOT / "excel" / "BankSphere_Loan_Portfolio_Analysis.xlsx", sheet_name=0)
loans.columns = [snake(c) for c in loans.columns]
loans.to_csv(OUT / "final_fact_cleaned.csv", index=False, date_format="%Y-%m-%d")

# Transactions: 'MAIN' sheet, first 14 columns only (columns 15-17 are empty in the workbook)
tx = pd.read_excel(ROOT / "excel" / "BankSphere_Transaction_Analysis.xlsx", sheet_name="MAIN").iloc[:, :14]
tx.columns = [snake(c) for c in tx.columns]
tx.to_csv(OUT / "credit_debit_bank.csv", index=False, date_format="%Y-%m-%d")

print(f"final_fact_cleaned.csv : {len(loans):,} rows")
print(f"credit_debit_bank.csv  : {len(tx):,} rows")
