-- ---------------------------------------------------------------------------
-- medical: synthetic patients and clinical encounters.
--
-- ALL VALUES ARE FICTIONAL TEST DATA. No real patient data, ever.
--   * emails use the reserved example.org domain (RFC 2606)
--   * phone numbers use the fictional +1-555-02xx range
--   * SSNs use the 900-xx-xxxx prefix, which is never issued by the SSA
--   * every row is flagged with is_test_data = true
--
-- Drop/create/insert so that re-running `make seed` is idempotent.
-- ---------------------------------------------------------------------------
DROP TABLE IF EXISTS iceberg.medical.encounters;
DROP TABLE IF EXISTS iceberg.medical.patients;

CREATE TABLE iceberg.medical.patients (
    patient_id           bigint,
    full_name            varchar,
    email                varchar,
    phone                varchar,
    date_of_birth        date,
    ssn                  varchar,
    medical_record_number varchar,
    primary_diagnosis    varchar,
    insurance_member_id  varchar,
    care_site            varchar,
    is_test_data         boolean
);

INSERT INTO iceberg.medical.patients VALUES
(2001, 'Imani Rookwood',  'imani.rookwood@example.org',  '+1-555-0201', DATE '1948-05-12', '900-22-0001', 'MRN-000001', 'Type 2 diabetes mellitus',      'INS-TEST-000001', 'CLINIC-NORTH', true),
(2002, 'Jonas Fairweather','jonas.fairweather@example.org','+1-555-0202', DATE '1954-11-03', '900-22-0002', 'MRN-000002', 'Essential hypertension',        'INS-TEST-000002', 'CLINIC-NORTH', true),
(2003, 'Keziah Alcott',   'keziah.alcott@example.org',   '+1-555-0203', DATE '1979-02-21', '900-22-0003', 'MRN-000003', 'Asthma, unspecified',           'INS-TEST-000003', 'CLINIC-SOUTH', true),
(2004, 'Lucian Hartsfield','lucian.hartsfield@example.org','+1-555-0204', DATE '1991-08-30', '900-22-0004', 'MRN-000004', 'Major depressive disorder',     'INS-TEST-000004', 'CLINIC-SOUTH', true),
(2005, 'Maren Oyelaran',  'maren.oyelaran@example.org',  '+1-555-0205', DATE '1966-04-17', '900-22-0005', 'MRN-000005', 'Chronic kidney disease, stage 3','INS-TEST-000005', 'CLINIC-NORTH', true),
(2006, 'Niko Vasquez',    'niko.vasquez@example.org',    '+1-555-0206', DATE '2001-12-09', '900-22-0006', 'MRN-000006', 'Seasonal allergic rhinitis',    'INS-TEST-000006', 'CLINIC-EAST',  true),
(2007, 'Odalys Brennan',  'odalys.brennan@example.org',  '+1-555-0207', DATE '1947-07-25', '900-22-0007', 'MRN-000007', 'Atrial fibrillation',           'INS-TEST-000007', 'CLINIC-EAST',  true),
(2008, 'Pascal Nyberg',   'pascal.nyberg@example.org',   '+1-555-0208', DATE '1985-03-14', '900-22-0008', 'MRN-000008', 'Hyperlipidaemia',               'INS-TEST-000008', 'CLINIC-SOUTH', true),
(2009, 'Quinlan Afolabi', 'quinlan.afolabi@example.org', '+1-555-0209', DATE '1973-09-28', '900-22-0009', 'MRN-000009', 'Rheumatoid arthritis',          'INS-TEST-000009', 'CLINIC-NORTH', true),
(2010, 'Rhiannon Castel', 'rhiannon.castel@example.org', '+1-555-0210', DATE '1996-06-06', '900-22-0010', 'MRN-000010', 'Migraine without aura',         'INS-TEST-000010', 'CLINIC-EAST',  true),
(2011, 'Sayid Thorne',    'sayid.thorne@example.org',    '+1-555-0211', DATE '1960-01-23', '900-22-0011', 'MRN-000011', 'COPD, moderate',                'INS-TEST-000011', 'CLINIC-SOUTH', true),
(2012, 'Tamsin Everly',   'tamsin.everly@example.org',   '+1-555-0212', DATE '1988-10-11', '900-22-0012', 'MRN-000012', 'Hypothyroidism',                'INS-TEST-000012', 'CLINIC-NORTH', true),
(2013, 'Ulrich Danvers',  'ulrich.danvers@example.org',  '+1-555-0213', DATE '1942-02-02', '900-22-0013', 'MRN-000013', 'Osteoarthritis of knee',        'INS-TEST-000013', 'CLINIC-EAST',  true),
(2014, 'Verity Mbeki',    'verity.mbeki@example.org',    '+1-555-0214', DATE '2004-05-19', '900-22-0014', 'MRN-000014', 'Iron deficiency anaemia',       'INS-TEST-000014', 'CLINIC-SOUTH', true),
(2015, 'Wendell Priya',   'wendell.priya@example.org',   '+1-555-0215', DATE '1970-08-08', '900-22-0015', 'MRN-000015', 'Gastro-oesophageal reflux',     'INS-TEST-000015', 'CLINIC-NORTH', true),
(2016, 'Ximena Lowell',   'ximena.lowell@example.org',   '+1-555-0216', DATE '1958-12-30', '900-22-0016', 'MRN-000016', 'Type 1 diabetes mellitus',      'INS-TEST-000016', 'CLINIC-EAST',  true);

CREATE TABLE iceberg.medical.encounters (
    encounter_id    bigint,
    patient_id      bigint,
    provider_name   varchar,
    diagnosis_code  varchar,
    encounter_notes varchar,
    encounter_date  date,
    care_site       varchar,
    is_test_data    boolean
);

INSERT INTO iceberg.medical.encounters VALUES
(6001, 2001, 'Dr Elspeth Varga',   'E11.9',  'Routine review. HbA1c trending down; continue current therapy.',        DATE '2026-01-06', 'CLINIC-NORTH', true),
(6002, 2001, 'Dr Elspeth Varga',   'E11.9',  'Follow-up. Patient reports improved adherence to medication.',           DATE '2026-02-10', 'CLINIC-NORTH', true),
(6003, 2002, 'Dr Hugo Lindmark',   'I10',    'Blood pressure 148/92. Dose adjustment discussed with patient.',         DATE '2026-01-08', 'CLINIC-NORTH', true),
(6004, 2003, 'Dr Priya Raman',     'J45.909','Spirometry performed. Inhaler technique reviewed.',                      DATE '2026-01-13', 'CLINIC-SOUTH', true),
(6005, 2004, 'Dr Noor Haddad',     'F32.1',  'Mood assessment completed. Referred to talking therapy service.',        DATE '2026-01-14', 'CLINIC-SOUTH', true),
(6006, 2005, 'Dr Hugo Lindmark',   'N18.3',  'eGFR stable. Nephrology review scheduled for next quarter.',             DATE '2026-01-17', 'CLINIC-NORTH', true),
(6007, 2006, 'Dr Alma Serrano',    'J30.2',  'Seasonal symptoms. Antihistamine prescribed.',                           DATE '2026-01-20', 'CLINIC-EAST',  true),
(6008, 2007, 'Dr Felix Osei',      'I48.91', 'Rate controlled. Anticoagulation reviewed, no bleeding reported.',        DATE '2026-01-24', 'CLINIC-EAST',  true),
(6009, 2008, 'Dr Priya Raman',     'E78.5',  'Lipid panel ordered. Dietary advice provided.',                           DATE '2026-01-27', 'CLINIC-SOUTH', true),
(6010, 2009, 'Dr Elspeth Varga',   'M06.9',  'Joint swelling reduced. Continue DMARD therapy.',                        DATE '2026-01-31', 'CLINIC-NORTH', true),
(6011, 2010, 'Dr Alma Serrano',    'G43.009','Headache diary reviewed. Trigger avoidance discussed.',                  DATE '2026-02-02', 'CLINIC-EAST',  true),
(6012, 2011, 'Dr Felix Osei',      'J44.1',  'Exacerbation resolved. Pulmonary rehabilitation referral made.',          DATE '2026-02-04', 'CLINIC-SOUTH', true),
(6013, 2012, 'Dr Hugo Lindmark',   'E03.9',  'TSH within range. Annual review booked.',                                DATE '2026-02-06', 'CLINIC-NORTH', true),
(6014, 2013, 'Dr Noor Haddad',     'M17.0',  'Mobility assessed. Physiotherapy plan agreed with patient.',             DATE '2026-02-09', 'CLINIC-EAST',  true),
(6015, 2014, 'Dr Priya Raman',     'D50.9',  'Ferritin low. Oral iron commenced, recheck in eight weeks.',             DATE '2026-02-11', 'CLINIC-SOUTH', true),
(6016, 2015, 'Dr Alma Serrano',    'K21.9',  'Symptoms controlled on PPI. Lifestyle measures reinforced.',             DATE '2026-02-13', 'CLINIC-NORTH', true),
(6017, 2016, 'Dr Felix Osei',      'E10.9',  'Pump settings reviewed. Continuous glucose monitoring data discussed.',  DATE '2026-02-16', 'CLINIC-EAST',  true),
(6018, 2002, 'Dr Hugo Lindmark',   'I10',    'Home readings submitted. Target achieved.',                              DATE '2026-02-18', 'CLINIC-NORTH', true),
(6019, 2003, 'Dr Priya Raman',     'J45.909','Peak flow improved. Rescue inhaler use reduced.',                        DATE '2026-02-19', 'CLINIC-SOUTH', true),
(6020, 2004, 'Dr Noor Haddad',     'F32.1',  'Therapy commenced. Patient reports better sleep.',                       DATE '2026-02-20', 'CLINIC-SOUTH', true),
(6021, 2005, 'Dr Elspeth Varga',   'N18.3',  'Fluid balance stable. Medication list reconciled.',                      DATE '2026-02-21', 'CLINIC-NORTH', true),
(6022, 2006, 'Dr Alma Serrano',    'J30.2',  'Symptom-free since last visit. No change to treatment.',                 DATE '2026-02-22', 'CLINIC-EAST',  true),
(6023, 2007, 'Dr Felix Osei',      'I48.91', 'ECG unchanged. Annual cardiology review arranged.',                      DATE '2026-02-23', 'CLINIC-EAST',  true),
(6024, 2008, 'Dr Priya Raman',     'E78.5',  'Statin tolerated well. Repeat lipids in three months.',                  DATE '2026-02-24', 'CLINIC-SOUTH', true),
(6025, 2009, 'Dr Elspeth Varga',   'M06.9',  'Flare managed with short steroid course.',                               DATE '2026-02-25', 'CLINIC-NORTH', true),
(6026, 2010, 'Dr Alma Serrano',    'G43.009','Preventive therapy discussed. Patient opted to continue monitoring.',    DATE '2026-02-26', 'CLINIC-EAST',  true),
(6027, 2011, 'Dr Felix Osei',      'J44.1',  'Smoking cessation support offered and accepted.',                        DATE '2026-02-27', 'CLINIC-SOUTH', true),
(6028, 2012, 'Dr Hugo Lindmark',   'E03.9',  'Dose unchanged. Bloods repeated for confirmation.',                      DATE '2026-02-28', 'CLINIC-NORTH', true),
(6029, 2013, 'Dr Noor Haddad',     'M17.0',  'Pain scores improved after physiotherapy block.',                        DATE '2026-03-02', 'CLINIC-EAST',  true),
(6030, 2014, 'Dr Priya Raman',     'D50.9',  'Haemoglobin rising. Continue supplementation.',                          DATE '2026-03-03', 'CLINIC-SOUTH', true);
