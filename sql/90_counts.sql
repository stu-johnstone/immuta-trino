-- Row counts across all seeded test tables.
SELECT 'finance.customers'          AS table_name, count(*) AS row_count FROM iceberg.finance.customers
UNION ALL SELECT 'finance.transactions',          count(*) FROM iceberg.finance.transactions
UNION ALL SELECT 'medical.patients',              count(*) FROM iceberg.medical.patients
UNION ALL SELECT 'medical.encounters',            count(*) FROM iceberg.medical.encounters
UNION ALL SELECT 'manufacturing.employees',       count(*) FROM iceberg.manufacturing.employees
UNION ALL SELECT 'manufacturing.suppliers',       count(*) FROM iceberg.manufacturing.suppliers
ORDER BY table_name;
