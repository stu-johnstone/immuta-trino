-- ---------------------------------------------------------------------------
-- finance: synthetic customers and card transactions.
--
-- ALL VALUES ARE FICTIONAL TEST DATA.
--   * emails use the reserved example.com domain (RFC 2606)
--   * phone numbers use the fictional +1-555-01xx range
--   * SSNs use the 900-xx-xxxx prefix, which is never issued by the SSA
--   * every row is flagged with is_test_data = true
--
-- Drop/create/insert so that re-running `make seed` is idempotent.
-- ---------------------------------------------------------------------------
DROP TABLE IF EXISTS iceberg.finance.transactions;
DROP TABLE IF EXISTS iceberg.finance.customers;

CREATE TABLE iceberg.finance.customers (
    customer_id     bigint,
    full_name       varchar,
    email           varchar,
    phone           varchar,
    ssn             varchar,
    account_number  varchar,
    balance         decimal(12,2),
    account_type    varchar,
    region          varchar,
    opened_date     date,
    is_test_data    boolean
);

INSERT INTO iceberg.finance.customers VALUES
(1001, 'Avery Stone',    'avery.stone@example.com',    '+1-555-0101', '900-11-0001', '100000000001', 18240.55, 'CHECKING', 'AMER', DATE '2019-03-14', true),
(1002, 'Brooke Hollis',  'brooke.hollis@example.com',  '+1-555-0102', '900-11-0002', '100000000002',  4305.10, 'SAVINGS',  'AMER', DATE '2020-07-02', true),
(1003, 'Caden Mercer',   'caden.mercer@example.com',   '+1-555-0103', '900-11-0003', '100000000003', 92015.00, 'PREMIUM',  'EMEA', DATE '2018-11-30', true),
(1004, 'Dalia Fenwick',  'dalia.fenwick@example.com',  '+1-555-0104', '900-11-0004', '100000000004',   712.42, 'CHECKING', 'EMEA', DATE '2021-01-19', true),
(1005, 'Emerson Vale',   'emerson.vale@example.com',   '+1-555-0105', '900-11-0005', '100000000005', 33110.75, 'SAVINGS',  'APAC', DATE '2017-06-05', true),
(1006, 'Fiona Ashgrove', 'fiona.ashgrove@example.com', '+1-555-0106', '900-11-0006', '100000000006', 15680.20, 'CHECKING', 'APAC', DATE '2022-09-23', true),
(1007, 'Gideon Marsh',   'gideon.marsh@example.com',   '+1-555-0107', '900-11-0007', '100000000007',  2400.00, 'CHECKING', 'AMER', DATE '2023-02-11', true),
(1008, 'Hazel Quinton',  'hazel.quinton@example.com',  '+1-555-0108', '900-11-0008', '100000000008', 58790.33, 'PREMIUM',  'AMER', DATE '2016-08-17', true),
(1009, 'Ira Blackwood',  'ira.blackwood@example.com',  '+1-555-0109', '900-11-0009', '100000000009',   -85.60, 'CHECKING', 'EMEA', DATE '2024-04-08', true),
(1010, 'Juno Carraway',  'juno.carraway@example.com',  '+1-555-0110', '900-11-0010', '100000000010', 27345.90, 'SAVINGS',  'EMEA', DATE '2019-12-01', true),
(1011, 'Kai Lindqvist',  'kai.lindqvist@example.com',  '+1-555-0111', '900-11-0011', '100000000011',  8120.05, 'CHECKING', 'APAC', DATE '2020-10-14', true),
(1012, 'Lena Ostrander', 'lena.ostrander@example.com', '+1-555-0112', '900-11-0012', '100000000012', 41260.00, 'PREMIUM',  'APAC', DATE '2018-05-22', true),
(1013, 'Milo Thackery',  'milo.thackery@example.com',  '+1-555-0113', '900-11-0013', '100000000013',  1965.45, 'CHECKING', 'AMER', DATE '2023-07-19', true),
(1014, 'Nadia Prewitt',  'nadia.prewitt@example.com',  '+1-555-0114', '900-11-0014', '100000000014', 73402.18, 'PREMIUM',  'AMER', DATE '2015-02-27', true),
(1015, 'Oren Fairbanks', 'oren.fairbanks@example.com', '+1-555-0115', '900-11-0015', '100000000015', 10500.00, 'SAVINGS',  'EMEA', DATE '2021-11-09', true),
(1016, 'Petra Winslow',  'petra.winslow@example.com',  '+1-555-0116', '900-11-0016', '100000000016',  6230.77, 'CHECKING', 'EMEA', DATE '2022-03-30', true),
(1017, 'Quill Ramsey',   'quill.ramsey@example.com',   '+1-555-0117', '900-11-0017', '100000000017', 19875.60, 'SAVINGS',  'APAC', DATE '2019-09-12', true),
(1018, 'Rosalind Vance', 'rosalind.vance@example.com', '+1-555-0118', '900-11-0018', '100000000018', 84990.25, 'PREMIUM',  'APAC', DATE '2017-01-05', true),
(1019, 'Soren Delacroix','soren.delacroix@example.com','+1-555-0119', '900-11-0019', '100000000019',  3410.00, 'CHECKING', 'AMER', DATE '2024-01-22', true),
(1020, 'Thea Nakamura',  'thea.nakamura@example.com',  '+1-555-0120', '900-11-0020', '100000000020', 22615.80, 'SAVINGS',  'AMER', DATE '2020-04-16', true);

CREATE TABLE iceberg.finance.transactions (
    transaction_id    bigint,
    customer_id       bigint,
    card_last_four    varchar,
    amount            decimal(12,2),
    merchant          varchar,
    merchant_category varchar,
    transaction_ts    timestamp(6),
    is_test_data      boolean
);

INSERT INTO iceberg.finance.transactions VALUES
(5001, 1001, '4111',  82.40, 'Example Grocers',      'GROCERY',     TIMESTAMP '2026-01-04 09:12:00', true),
(5002, 1001, '4111', 1250.00, 'Example Air',          'TRAVEL',      TIMESTAMP '2026-01-09 17:45:00', true),
(5003, 1002, '4242',  34.99, 'Example Streaming',    'ENTERTAIN',   TIMESTAMP '2026-01-11 20:03:00', true),
(5004, 1003, '4018', 4320.00, 'Example Motors',       'AUTOMOTIVE',  TIMESTAMP '2026-01-12 11:30:00', true),
(5005, 1003, '4018',  215.75, 'Example Hardware',     'HOME',        TIMESTAMP '2026-01-15 08:55:00', true),
(5006, 1004, '4555',  19.20, 'Example Coffee',       'DINING',      TIMESTAMP '2026-01-16 07:40:00', true),
(5007, 1005, '4777', 640.00, 'Example Furnishings',  'HOME',        TIMESTAMP '2026-01-18 14:22:00', true),
(5008, 1005, '4777',  88.65, 'Example Pharmacy',     'HEALTH',      TIMESTAMP '2026-01-19 18:10:00', true),
(5009, 1006, '4903', 152.30, 'Example Grocers',      'GROCERY',     TIMESTAMP '2026-01-21 12:05:00', true),
(5010, 1007, '4310',  45.00, 'Example Transit',      'TRANSPORT',   TIMESTAMP '2026-01-22 06:48:00', true),
(5011, 1008, '4628', 2890.99, 'Example Electronics',  'RETAIL',      TIMESTAMP '2026-01-23 15:37:00', true),
(5012, 1008, '4628', 120.00, 'Example Fitness',      'HEALTH',      TIMESTAMP '2026-01-25 19:02:00', true),
(5013, 1009, '4041',  62.15, 'Example Fuel',         'FUEL',        TIMESTAMP '2026-01-26 10:14:00', true),
(5014, 1010, '4190', 310.80, 'Example Apparel',      'RETAIL',      TIMESTAMP '2026-01-28 13:50:00', true),
(5015, 1011, '4266',  27.45, 'Example Bakery',       'DINING',      TIMESTAMP '2026-01-29 08:20:00', true),
(5016, 1012, '4388', 5600.00, 'Example Jewellers',    'LUXURY',      TIMESTAMP '2026-01-30 16:05:00', true),
(5017, 1012, '4388', 740.25, 'Example Hotel',        'TRAVEL',      TIMESTAMP '2026-02-01 21:30:00', true),
(5018, 1013, '4412',  15.99, 'Example Streaming',    'ENTERTAIN',   TIMESTAMP '2026-02-02 22:11:00', true),
(5019, 1014, '4534', 9800.00, 'Example Investments',  'FINANCIAL',   TIMESTAMP '2026-02-03 09:00:00', true),
(5020, 1014, '4534', 230.40, 'Example Grocers',      'GROCERY',     TIMESTAMP '2026-02-04 17:25:00', true),
(5021, 1015, '4650', 410.00, 'Example Clinic',       'HEALTH',      TIMESTAMP '2026-02-05 11:45:00', true),
(5022, 1016, '4712',  73.10, 'Example Bookshop',     'RETAIL',      TIMESTAMP '2026-02-06 14:08:00', true),
(5023, 1017, '4824', 1890.50, 'Example Air',          'TRAVEL',      TIMESTAMP '2026-02-07 05:55:00', true),
(5024, 1018, '4936', 3250.00, 'Example Galleries',    'LUXURY',      TIMESTAMP '2026-02-08 18:40:00', true),
(5025, 1018, '4936',  96.80, 'Example Grocers',      'GROCERY',     TIMESTAMP '2026-02-09 10:30:00', true),
(5026, 1019, '4048',  52.00, 'Example Transit',      'TRANSPORT',   TIMESTAMP '2026-02-10 07:15:00', true),
(5027, 1020, '4160', 184.95, 'Example Pharmacy',     'HEALTH',      TIMESTAMP '2026-02-11 16:50:00', true),
(5028, 1020, '4160', 2100.00, 'Example Contractors',  'HOME',        TIMESTAMP '2026-02-12 09:35:00', true),
(5029, 1002, '4242', 505.60, 'Example Apparel',      'RETAIL',      TIMESTAMP '2026-02-13 12:28:00', true),
(5030, 1004, '4555', 1340.00, 'Example Dentist',      'HEALTH',      TIMESTAMP '2026-02-14 15:12:00', true),
(5031, 1006, '4903',  39.99, 'Example Streaming',    'ENTERTAIN',   TIMESTAMP '2026-02-15 20:45:00', true),
(5032, 1007, '4310', 760.00, 'Example Movers',       'SERVICES',    TIMESTAMP '2026-02-16 08:05:00', true),
(5033, 1009, '4041',  22.75, 'Example Coffee',       'DINING',      TIMESTAMP '2026-02-17 07:52:00', true),
(5034, 1010, '4190', 4480.00, 'Example Motors',       'AUTOMOTIVE',  TIMESTAMP '2026-02-18 13:33:00', true),
(5035, 1011, '4266', 118.40, 'Example Grocers',      'GROCERY',     TIMESTAMP '2026-02-19 17:18:00', true),
(5036, 1013, '4412', 265.00, 'Example Fuel',         'FUEL',        TIMESTAMP '2026-02-20 06:40:00', true),
(5037, 1015, '4650', 1575.25, 'Example Hotel',        'TRAVEL',      TIMESTAMP '2026-02-21 19:55:00', true),
(5038, 1016, '4712',  48.30, 'Example Bakery',       'DINING',      TIMESTAMP '2026-02-22 08:14:00', true),
(5039, 1017, '4824', 920.00, 'Example Electronics',  'RETAIL',      TIMESTAMP '2026-02-23 14:47:00', true),
(5040, 1019, '4048', 6300.00, 'Example Investments',  'FINANCIAL',   TIMESTAMP '2026-02-24 09:25:00', true),
(5041, 1001, '4111', 142.60, 'Example Pharmacy',     'HEALTH',      TIMESTAMP '2026-02-25 11:02:00', true),
(5042, 1003, '4018', 7850.00, 'Example Galleries',    'LUXURY',      TIMESTAMP '2026-02-26 16:19:00', true),
(5043, 1005, '4777',  67.85, 'Example Grocers',      'GROCERY',     TIMESTAMP '2026-02-27 18:36:00', true),
(5044, 1012, '4388', 395.00, 'Example Fitness',      'HEALTH',      TIMESTAMP '2026-02-28 07:30:00', true),
(5045, 1014, '4534',  83.20, 'Example Transit',      'TRANSPORT',   TIMESTAMP '2026-03-01 08:48:00', true);
