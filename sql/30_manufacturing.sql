-- ---------------------------------------------------------------------------
-- manufacturing: synthetic employees and suppliers.
--
-- ALL VALUES ARE FICTIONAL TEST DATA.
--   * emails use the reserved example.com domain (RFC 2606)
--   * phone numbers use the fictional +1-555-03xx range
--   * national IDs use the 900-xx-xxxx prefix, never issued by the SSA
--   * tax IDs and bank account numbers are made up, non-routable values
--   * every row is flagged with is_test_data = true
--
-- Drop/create/insert so that re-running `make seed` is idempotent.
-- ---------------------------------------------------------------------------
DROP TABLE IF EXISTS iceberg.manufacturing.suppliers;
DROP TABLE IF EXISTS iceberg.manufacturing.employees;

CREATE TABLE iceberg.manufacturing.employees (
    employee_id  bigint,
    full_name    varchar,
    email        varchar,
    phone        varchar,
    national_id  varchar,
    salary       decimal(12,2),
    badge_id     varchar,
    site         varchar,
    department   varchar,
    hire_date    date,
    is_test_data boolean
);

INSERT INTO iceberg.manufacturing.employees VALUES
(3001, 'Anders Kjellberg', 'anders.kjellberg@example.com', '+1-555-0301', '900-33-0001',  92500.00, 'BADGE-0001', 'PLANT-ALPHA',   'ASSEMBLY',    DATE '2016-04-11', true),
(3002, 'Beatriz Olmos',    'beatriz.olmos@example.com',    '+1-555-0302', '900-33-0002', 118400.00, 'BADGE-0002', 'PLANT-ALPHA',   'ENGINEERING', DATE '2014-09-01', true),
(3003, 'Caius Northwood',  'caius.northwood@example.com',  '+1-555-0303', '900-33-0003',  67300.00, 'BADGE-0003', 'PLANT-ALPHA',   'QUALITY',     DATE '2021-02-15', true),
(3004, 'Delphine Aubert',  'delphine.aubert@example.com',  '+1-555-0304', '900-33-0004',  84950.00, 'BADGE-0004', 'PLANT-BRAVO',   'MAINTENANCE', DATE '2018-06-25', true),
(3005, 'Ezra Mkhize',      'ezra.mkhize@example.com',      '+1-555-0305', '900-33-0005', 134000.00, 'BADGE-0005', 'PLANT-BRAVO',   'ENGINEERING', DATE '2012-11-05', true),
(3006, 'Freya Lindholm',   'freya.lindholm@example.com',   '+1-555-0306', '900-33-0006',  58200.00, 'BADGE-0006', 'PLANT-BRAVO',   'LOGISTICS',   DATE '2022-08-08', true),
(3007, 'Gustav Reinhart',  'gustav.reinhart@example.com',  '+1-555-0307', '900-33-0007',  76800.00, 'BADGE-0007', 'PLANT-CHARLIE', 'ASSEMBLY',    DATE '2019-03-18', true),
(3008, 'Halima Sow',       'halima.sow@example.com',       '+1-555-0308', '900-33-0008', 102600.00, 'BADGE-0008', 'PLANT-CHARLIE', 'QUALITY',     DATE '2017-01-30', true),
(3009, 'Ilia Petrova',     'ilia.petrova@example.com',     '+1-555-0309', '900-33-0009',  61450.00, 'BADGE-0009', 'PLANT-CHARLIE', 'LOGISTICS',   DATE '2023-05-22', true),
(3010, 'Jarrah Whitlock',  'jarrah.whitlock@example.com',  '+1-555-0310', '900-33-0010',  88300.00, 'BADGE-0010', 'PLANT-ALPHA',   'MAINTENANCE', DATE '2015-07-13', true),
(3011, 'Kenji Arakawa',    'kenji.arakawa@example.com',    '+1-555-0311', '900-33-0011', 145900.00, 'BADGE-0011', 'PLANT-ALPHA',   'ENGINEERING', DATE '2011-10-03', true),
(3012, 'Liesl Vandermeer', 'liesl.vandermeer@example.com', '+1-555-0312', '900-33-0012',  54700.00, 'BADGE-0012', 'PLANT-BRAVO',   'ASSEMBLY',    DATE '2024-02-19', true),
(3013, 'Mateo Quiroga',    'mateo.quiroga@example.com',    '+1-555-0313', '900-33-0013',  79250.00, 'BADGE-0013', 'PLANT-BRAVO',   'QUALITY',     DATE '2020-09-07', true),
(3014, 'Nilsa Berglund',   'nilsa.berglund@example.com',   '+1-555-0314', '900-33-0014',  96100.00, 'BADGE-0014', 'PLANT-CHARLIE', 'ENGINEERING', DATE '2018-12-10', true),
(3015, 'Osric Tanaka',     'osric.tanaka@example.com',     '+1-555-0315', '900-33-0015',  63900.00, 'BADGE-0015', 'PLANT-CHARLIE', 'LOGISTICS',   DATE '2022-04-04', true),
(3016, 'Perpetua Nwosu',   'perpetua.nwosu@example.com',   '+1-555-0316', '900-33-0016', 127300.00, 'BADGE-0016', 'PLANT-ALPHA',   'ENGINEERING', DATE '2013-08-26', true);

CREATE TABLE iceberg.manufacturing.suppliers (
    supplier_id         bigint,
    supplier_name       varchar,
    contact_email       varchar,
    contact_phone       varchar,
    tax_id              varchar,
    bank_account_number varchar,
    site                varchar,
    is_test_data        boolean
);

INSERT INTO iceberg.manufacturing.suppliers VALUES
(4001, 'Example Alloys Ltd',        'accounts@example-alloys.example.com',   '+1-555-0401', '98-0000001', '4000100000001', 'PLANT-ALPHA',   true),
(4002, 'Example Bearings GmbH',     'billing@example-bearings.example.com',  '+1-555-0402', '98-0000002', '4000100000002', 'PLANT-ALPHA',   true),
(4003, 'Example Castings Pty',      'finance@example-castings.example.com',  '+1-555-0403', '98-0000003', '4000100000003', 'PLANT-BRAVO',   true),
(4004, 'Example Dielectrics Inc',   'ap@example-dielectrics.example.com',    '+1-555-0404', '98-0000004', '4000100000004', 'PLANT-BRAVO',   true),
(4005, 'Example Extrusions SA',     'accounts@example-extrusions.example.com','+1-555-0405', '98-0000005', '4000100000005', 'PLANT-CHARLIE', true),
(4006, 'Example Fasteners BV',      'invoices@example-fasteners.example.com','+1-555-0406', '98-0000006', '4000100000006', 'PLANT-CHARLIE', true),
(4007, 'Example Gaskets Oy',        'billing@example-gaskets.example.com',   '+1-555-0407', '98-0000007', '4000100000007', 'PLANT-ALPHA',   true),
(4008, 'Example Hydraulics KK',     'ap@example-hydraulics.example.com',     '+1-555-0408', '98-0000008', '4000100000008', 'PLANT-BRAVO',   true),
(4009, 'Example Insulators AB',     'finance@example-insulators.example.com','+1-555-0409', '98-0000009', '4000100000009', 'PLANT-CHARLIE', true),
(4010, 'Example Joinery Pte',       'accounts@example-joinery.example.com',  '+1-555-0410', '98-0000010', '4000100000010', 'PLANT-ALPHA',   true);
