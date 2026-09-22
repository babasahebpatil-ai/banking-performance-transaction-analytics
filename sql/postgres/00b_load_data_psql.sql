/*
Banking Performance & Transaction Analytics  |  PostgreSQL edition
00b_load_data_psql.sql
Loads the CSV files into the tables created by 00_setup.sql.

Generate the CSVs first (from the project root):   python data/export_excel_to_csv.py
(The zip already contains them in data/csv/.)

\copy is a psql command, so run this file with psql from the PROJECT ROOT:
    psql -d your_database -f sql/postgres/00b_load_data_psql.sql

Using pgAdmin instead? Right-click each table > Import/Export Data, choose the CSV,
Format = csv, Header = ON, Delimiter = ','.
*/

SET search_path TO banksphere, public;

\copy final_fact_cleaned FROM 'data/csv/final_fact_cleaned.csv' WITH (FORMAT csv, HEADER true)
\copy credit_debit_bank  FROM 'data/csv/credit_debit_bank.csv'  WITH (FORMAT csv, HEADER true)

SELECT COUNT(*) AS loan_rows        FROM final_fact_cleaned;   -- expect 2,000
SELECT COUNT(*) AS transaction_rows FROM credit_debit_bank;    -- expect 100,000
