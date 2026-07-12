\set ON_ERROR_STOP on
\encoding UTF8

BEGIN;

-- ============================================================
-- 03_people_and_relationships.sql
-- Realistic multi-company example
--
-- Purpose:
-- Seed people, contact methods, company roles, department
-- assignments, reporting lines, and person-to-person
-- relationships for the realistic multi-company example.
--
-- Notes:
-- - All people, contact details, and relationship histories are
--   synthetic demonstration data.
-- - Email domains use the reserved .example namespace.
-- - Person records are resolved through company slugs and stable
--   external references; generated identity values are never
--   hard-coded.
-- - The script depends on 02_organizations.sql.
-- - The script is safe to run more than once.
-- ============================================================

-- ============================================================
-- Persons
-- ============================================================

CREATE TEMP TABLE fixture_people (
    company_slug TEXT NOT NULL,
    external_reference TEXT NOT NULL,
    display_name TEXT NOT NULL,
    given_name TEXT,
    middle_name TEXT,
    family_name TEXT,
    additional_family_name TEXT,
    person_status TEXT NOT NULL
) ON COMMIT DROP;

INSERT INTO fixture_people (
    company_slug,
    external_reference,
    display_name,
    given_name,
    middle_name,
    family_name,
    additional_family_name,
    person_status
)
VALUES
    -- Solara Retail Mexico
    ('solara-retail-mx', 'SRM-P001', 'Valeria Montes Aguirre', 'Valeria', NULL, 'Montes', 'Aguirre', 'active'),
    ('solara-retail-mx', 'SRM-P002', 'Daniel Ríos Benítez', 'Daniel', NULL, 'Ríos', 'Benítez', 'active'),
    ('solara-retail-mx', 'SRM-P003', 'Fernanda Alcázar Gómez', 'Fernanda', NULL, 'Alcázar', 'Gómez', 'active'),
    ('solara-retail-mx', 'SRM-P004', 'Diego Sarmiento Ruiz', 'Diego', NULL, 'Sarmiento', 'Ruiz', 'active'),
    ('solara-retail-mx', 'SRM-P005', 'Sofía Cárdenas Luna', 'Sofía', NULL, 'Cárdenas', 'Luna', 'active'),
    ('solara-retail-mx', 'SRM-P006', 'Mauricio Leal Herrera', 'Mauricio', NULL, 'Leal', 'Herrera', 'active'),
    ('solara-retail-mx', 'SRM-P007', 'Karla Núñez Soto', 'Karla', NULL, 'Núñez', 'Soto', 'active'),
    ('solara-retail-mx', 'SRM-P008', 'Andrés Villaseñor Ponce', 'Andrés', NULL, 'Villaseñor', 'Ponce', 'active'),
    ('solara-retail-mx', 'SRM-P009', 'Paula Ibarra Torres', 'Paula', NULL, 'Ibarra', 'Torres', 'active'),
    ('solara-retail-mx', 'SRM-P010', 'Jorge Téllez Mora', 'Jorge', NULL, 'Téllez', 'Mora', 'active'),
    ('solara-retail-mx', 'SRM-P011', 'Camila Ortega Salgado', 'Camila', NULL, 'Ortega', 'Salgado', 'active'),
    ('solara-retail-mx', 'SRM-P012', 'Emiliano Cruz Varela', 'Emiliano', NULL, 'Cruz', 'Varela', 'active'),
    ('solara-retail-mx', 'SRM-P013', 'Renata Silva Campos', 'Renata', NULL, 'Silva', 'Campos', 'active'),
    ('solara-retail-mx', 'SRM-P014', 'Luis Treviño Castañeda', 'Luis', NULL, 'Treviño', 'Castañeda', 'active'),
    ('solara-retail-mx', 'SRM-P015', 'Mariana Rosales Peña', 'Mariana', NULL, 'Rosales', 'Peña', 'active'),
    ('solara-retail-mx', 'SRM-P016', 'Héctor Navarro Solís', 'Héctor', NULL, 'Navarro', 'Solís', 'active'),
    ('solara-retail-mx', 'SRM-P017', 'Omar Velasco Durán', 'Omar', NULL, 'Velasco', 'Durán', 'active'),
    ('solara-retail-mx', 'SRM-P018', 'Ximena Paredes Rojas', 'Ximena', NULL, 'Paredes', 'Rojas', 'active'),
    ('solara-retail-mx', 'SRM-P019', 'Arturo Beltrán Mejía', 'Arturo', NULL, 'Beltrán', 'Mejía', 'active'),
    ('solara-retail-mx', 'SRM-P020', 'Lucía Mejía Fuentes', 'Lucía', NULL, 'Mejía', 'Fuentes', 'active'),
    ('solara-retail-mx', 'SRM-P021', 'Ricardo Salas Ochoa', 'Ricardo', NULL, 'Salas', 'Ochoa', 'active'),
    ('solara-retail-mx', 'SRM-P022', 'Nora Jiménez Lara', 'Nora', NULL, 'Jiménez', 'Lara', 'active'),
    ('solara-retail-mx', 'SRM-P023', 'Gabriel Mena Lozano', 'Gabriel', NULL, 'Mena', 'Lozano', 'active'),
    ('solara-retail-mx', 'SRM-P024', 'Elena Aguirre Pardo', 'Elena', NULL, 'Aguirre', 'Pardo', 'active'),
    ('solara-retail-mx', 'SRM-P025', 'Tomás Ríos Vega', 'Tomás', NULL, 'Ríos', 'Vega', 'active'),
    ('solara-retail-mx', 'SRM-P026', 'Isabel Cruz Varela', 'Isabel', NULL, 'Cruz', 'Varela', 'active'),
    ('solara-retail-mx', 'SRM-P027', 'Mateo Paredes Rojas', 'Mateo', NULL, 'Paredes', 'Rojas', 'active'),
    -- Cobalto Industrial Systems
    ('cobalto-industrial-mx', 'CIS-P001', 'Alejandro Barragán Lozano', 'Alejandro', NULL, 'Barragán', 'Lozano', 'active'),
    ('cobalto-industrial-mx', 'CIS-P002', 'Mónica Cantú Garza', 'Mónica', NULL, 'Cantú', 'Garza', 'active'),
    ('cobalto-industrial-mx', 'CIS-P003', 'Patricia Elizondo Villarreal', 'Patricia', NULL, 'Elizondo', 'Villarreal', 'active'),
    ('cobalto-industrial-mx', 'CIS-P004', 'Roberto Garza Medina', 'Roberto', NULL, 'Garza', 'Medina', 'active'),
    ('cobalto-industrial-mx', 'CIS-P005', 'Eduardo Villarreal Santos', 'Eduardo', NULL, 'Villarreal', 'Santos', 'active'),
    ('cobalto-industrial-mx', 'CIS-P006', 'Silvia Castañón Reyes', 'Silvia', NULL, 'Castañón', 'Reyes', 'active'),
    ('cobalto-industrial-mx', 'CIS-P007', 'Javier de la Fuente Treviño', 'Javier', NULL, 'de la Fuente', 'Treviño', 'active'),
    ('cobalto-industrial-mx', 'CIS-P008', 'Claudia Cepeda Montemayor', 'Claudia', NULL, 'Cepeda', 'Montemayor', 'active'),
    ('cobalto-industrial-mx', 'CIS-P009', 'Raúl Zambrano Leal', 'Raúl', NULL, 'Zambrano', 'Leal', 'active'),
    ('cobalto-industrial-mx', 'CIS-P010', 'Adriana Flores Cantú', 'Adriana', NULL, 'Flores', 'Cantú', 'active'),
    ('cobalto-industrial-mx', 'CIS-P011', 'Manuel Guerra Salinas', 'Manuel', NULL, 'Guerra', 'Salinas', 'active'),
    ('cobalto-industrial-mx', 'CIS-P012', 'Verónica Lozano Peña', 'Verónica', NULL, 'Lozano', 'Peña', 'active'),
    ('cobalto-industrial-mx', 'CIS-P013', 'Sergio Maldonado Cruz', 'Sergio', NULL, 'Maldonado', 'Cruz', 'active'),
    ('cobalto-industrial-mx', 'CIS-P014', 'Irene Valdés Rocha', 'Irene', NULL, 'Valdés', 'Rocha', 'active'),
    ('cobalto-industrial-mx', 'CIS-P015', 'Óscar Padilla Ramos', 'Óscar', NULL, 'Padilla', 'Ramos', 'active'),
    ('cobalto-industrial-mx', 'CIS-P016', 'Natalia Guerra Cárdenas', 'Natalia', NULL, 'Guerra', 'Cárdenas', 'active'),
    ('cobalto-industrial-mx', 'CIS-P017', 'Ernesto Saldaña Ibarra', 'Ernesto', NULL, 'Saldaña', 'Ibarra', 'active'),
    ('cobalto-industrial-mx', 'CIS-P018', 'Beatriz Robles Tamez', 'Beatriz', NULL, 'Robles', 'Tamez', 'active'),
    ('cobalto-industrial-mx', 'CIS-P019', 'Miguel Ángel Ceballos Ortiz', 'Miguel Ángel', NULL, 'Ceballos', 'Ortiz', 'active'),
    ('cobalto-industrial-mx', 'CIS-P020', 'Rocío Esquivel Prado', 'Rocío', NULL, 'Esquivel', 'Prado', 'active'),
    ('cobalto-industrial-mx', 'CIS-P021', 'Hugo Santillán Mora', 'Hugo', NULL, 'Santillán', 'Mora', 'active'),
    ('cobalto-industrial-mx', 'CIS-P022', 'Teresa Becerra Molina', 'Teresa', NULL, 'Becerra', 'Molina', 'active'),
    ('cobalto-industrial-mx', 'CIS-P023', 'Iván Sepúlveda Guerra', 'Iván', NULL, 'Sepúlveda', 'Guerra', 'active'),
    ('cobalto-industrial-mx', 'CIS-P024', 'Laura Medina Lozano', 'Laura', NULL, 'Medina', 'Lozano', 'active'),
    ('cobalto-industrial-mx', 'CIS-P025', 'Diego Zambrano Leal', 'Diego', NULL, 'Zambrano', 'Leal', 'active'),
    -- BluePeak Advisory
    ('bluepeak-advisory-us', 'BPA-P001', 'Olivia Bennett', 'Olivia', NULL, 'Bennett', NULL, 'active'),
    ('bluepeak-advisory-us', 'BPA-P002', 'Ethan Parker', 'Ethan', NULL, 'Parker', NULL, 'active'),
    ('bluepeak-advisory-us', 'BPA-P003', 'Maya Thompson', 'Maya', NULL, 'Thompson', NULL, 'active'),
    ('bluepeak-advisory-us', 'BPA-P004', 'Jonathan Reed', 'Jonathan', NULL, 'Reed', NULL, 'active'),
    ('bluepeak-advisory-us', 'BPA-P005', 'Priya Shah', 'Priya', NULL, 'Shah', NULL, 'active'),
    ('bluepeak-advisory-us', 'BPA-P006', 'Marcus Hill', 'Marcus', NULL, 'Hill', NULL, 'active'),
    ('bluepeak-advisory-us', 'BPA-P007', 'Claire Donovan', 'Claire', NULL, 'Donovan', NULL, 'active'),
    ('bluepeak-advisory-us', 'BPA-P008', 'Noah Williams', 'Noah', NULL, 'Williams', NULL, 'active'),
    ('bluepeak-advisory-us', 'BPA-P009', 'Grace Kim', 'Grace', NULL, 'Kim', NULL, 'active'),
    ('bluepeak-advisory-us', 'BPA-P010', 'Avery Collins', 'Avery', NULL, 'Collins', NULL, 'active'),
    ('bluepeak-advisory-us', 'BPA-P011', 'Liam Foster', 'Liam', NULL, 'Foster', NULL, 'active'),
    ('bluepeak-advisory-us', 'BPA-P012', 'Amelia Brooks', 'Amelia', NULL, 'Brooks', NULL, 'active'),
    ('bluepeak-advisory-us', 'BPA-P013', 'David Chen', 'David', NULL, 'Chen', NULL, 'active'),
    ('bluepeak-advisory-us', 'BPA-P014', 'Rachel Morgan', 'Rachel', NULL, 'Morgan', NULL, 'active'),
    ('bluepeak-advisory-us', 'BPA-P015', 'Samuel Ortiz', 'Samuel', NULL, 'Ortiz', NULL, 'active'),
    ('bluepeak-advisory-us', 'BPA-P016', 'Nina Patel', 'Nina', NULL, 'Patel', NULL, 'active'),
    ('bluepeak-advisory-us', 'BPA-P017', 'Jordan Ellis', 'Jordan', NULL, 'Ellis', NULL, 'active'),
    ('bluepeak-advisory-us', 'BPA-P018', 'Taylor Monroe', 'Taylor', NULL, 'Monroe', NULL, 'active'),
    ('bluepeak-advisory-us', 'BPA-P019', 'Christopher Lang', 'Christopher', NULL, 'Lang', NULL, 'active'),
    ('bluepeak-advisory-us', 'BPA-P020', 'Emma Bennett', 'Emma', NULL, 'Bennett', NULL, 'active'),
    -- LumenForge Technologies
    ('lumenforge-technologies-us', 'LFT-P001', 'Aisha Rahman', 'Aisha', NULL, 'Rahman', NULL, 'active'),
    ('lumenforge-technologies-us', 'LFT-P002', 'Benjamin Carter', 'Benjamin', NULL, 'Carter', NULL, 'active'),
    ('lumenforge-technologies-us', 'LFT-P003', 'Elena Rodriguez', 'Elena', NULL, 'Rodriguez', NULL, 'active'),
    ('lumenforge-technologies-us', 'LFT-P004', 'Kevin Wu', 'Kevin', NULL, 'Wu', NULL, 'active'),
    ('lumenforge-technologies-us', 'LFT-P005', 'Morgan Price', 'Morgan', NULL, 'Price', NULL, 'active'),
    ('lumenforge-technologies-us', 'LFT-P006', 'Natalie Green', 'Natalie', NULL, 'Green', NULL, 'active'),
    ('lumenforge-technologies-us', 'LFT-P007', 'Owen Murphy', 'Owen', NULL, 'Murphy', NULL, 'active'),
    ('lumenforge-technologies-us', 'LFT-P008', 'Sierra James', 'Sierra', NULL, 'James', NULL, 'active'),
    ('lumenforge-technologies-us', 'LFT-P009', 'Caleb Turner', 'Caleb', NULL, 'Turner', NULL, 'active'),
    ('lumenforge-technologies-us', 'LFT-P010', 'Hannah Lee', 'Hannah', NULL, 'Lee', NULL, 'active'),
    ('lumenforge-technologies-us', 'LFT-P011', 'Victor Alvarez', 'Victor', NULL, 'Alvarez', NULL, 'active'),
    ('lumenforge-technologies-us', 'LFT-P012', 'Mei Lin', 'Mei', NULL, 'Lin', NULL, 'active'),
    ('lumenforge-technologies-us', 'LFT-P013', 'Isaac Coleman', 'Isaac', NULL, 'Coleman', NULL, 'active'),
    ('lumenforge-technologies-us', 'LFT-P014', 'Zoe Martin', 'Zoe', NULL, 'Martin', NULL, 'active'),
    ('lumenforge-technologies-us', 'LFT-P015', 'Daniel Okafor', 'Daniel', NULL, 'Okafor', NULL, 'active'),
    ('lumenforge-technologies-us', 'LFT-P016', 'Chloe Nguyen', 'Chloe', NULL, 'Nguyen', NULL, 'active'),
    ('lumenforge-technologies-us', 'LFT-P017', 'Ryan Scott', 'Ryan', NULL, 'Scott', NULL, 'active'),
    ('lumenforge-technologies-us', 'LFT-P018', 'Fatima Hassan', 'Fatima', NULL, 'Hassan', NULL, 'active'),
    ('lumenforge-technologies-us', 'LFT-P019', 'Lucas Grant', 'Lucas', NULL, 'Grant', NULL, 'active'),
    ('lumenforge-technologies-us', 'LFT-P020', 'Madison Cole', 'Madison', NULL, 'Cole', NULL, 'active'),
    ('lumenforge-technologies-us', 'LFT-P021', 'Derek Stone', 'Derek', NULL, 'Stone', NULL, 'active'),
    ('lumenforge-technologies-us', 'LFT-P022', 'Sophia Rahman', 'Sophia', NULL, 'Rahman', NULL, 'active'),
    -- Cedarline Logistics
    ('cedarline-logistics-ca', 'CLL-P001', 'Charlotte Tremblay', 'Charlotte', NULL, 'Tremblay', NULL, 'active'),
    ('cedarline-logistics-ca', 'CLL-P002', 'Liam McKenzie', 'Liam', NULL, 'McKenzie', NULL, 'active'),
    ('cedarline-logistics-ca', 'CLL-P003', 'Sophie Gagnon', 'Sophie', NULL, 'Gagnon', NULL, 'active'),
    ('cedarline-logistics-ca', 'CLL-P004', 'Nathan Wong', 'Nathan', NULL, 'Wong', NULL, 'active'),
    ('cedarline-logistics-ca', 'CLL-P005', 'Emily Fraser', 'Emily', NULL, 'Fraser', NULL, 'active'),
    ('cedarline-logistics-ca', 'CLL-P006', 'Jacob Singh', 'Jacob', NULL, 'Singh', NULL, 'active'),
    ('cedarline-logistics-ca', 'CLL-P007', 'Amélie Roy', 'Amélie', NULL, 'Roy', NULL, 'active'),
    ('cedarline-logistics-ca', 'CLL-P008', 'Connor Hughes', 'Connor', NULL, 'Hughes', NULL, 'active'),
    ('cedarline-logistics-ca', 'CLL-P009', 'Mia Campbell', 'Mia', NULL, 'Campbell', NULL, 'active'),
    ('cedarline-logistics-ca', 'CLL-P010', 'William Chen', 'William', NULL, 'Chen', NULL, 'active'),
    ('cedarline-logistics-ca', 'CLL-P011', 'Ava MacDonald', 'Ava', NULL, 'MacDonald', NULL, 'active'),
    ('cedarline-logistics-ca', 'CLL-P012', 'Noah Bouchard', 'Noah', NULL, 'Bouchard', NULL, 'active'),
    ('cedarline-logistics-ca', 'CLL-P013', 'Isabelle Martin', 'Isabelle', NULL, 'Martin', NULL, 'active'),
    ('cedarline-logistics-ca', 'CLL-P014', 'Ethan Brown', 'Ethan', NULL, 'Brown', NULL, 'active'),
    ('cedarline-logistics-ca', 'CLL-P015', 'Layla Ahmed', 'Layla', NULL, 'Ahmed', NULL, 'active'),
    ('cedarline-logistics-ca', 'CLL-P016', 'Mason Clarke', 'Mason', NULL, 'Clarke', NULL, 'active'),
    ('cedarline-logistics-ca', 'CLL-P017', 'Zoé Pelletier', 'Zoé', NULL, 'Pelletier', NULL, 'active'),
    ('cedarline-logistics-ca', 'CLL-P018', 'Arjun Mehta', 'Arjun', NULL, 'Mehta', NULL, 'active'),
    ('cedarline-logistics-ca', 'CLL-P019', 'Grace Tremblay', 'Grace', NULL, 'Tremblay', NULL, 'active'),
    ('cedarline-logistics-ca', 'CLL-P020', 'Oliver Singh', 'Oliver', NULL, 'Singh', NULL, 'active'),
    ('cedarline-logistics-ca', 'CLL-P021', 'Luc Martin', 'Luc', NULL, 'Martin', NULL, 'active'),
    -- Harvest Circle Foods
    ('harvest-circle-foods-ca', 'HCF-P001', 'Margaret Wilson', 'Margaret', NULL, 'Wilson', NULL, 'inactive'),
    ('harvest-circle-foods-ca', 'HCF-P002', 'Robert Sinclair', 'Robert', NULL, 'Sinclair', NULL, 'inactive'),
    ('harvest-circle-foods-ca', 'HCF-P003', 'Janet Liu', 'Janet', NULL, 'Liu', NULL, 'inactive'),
    ('harvest-circle-foods-ca', 'HCF-P004', 'Peter Dubois', 'Peter', NULL, 'Dubois', NULL, 'inactive'),
    ('harvest-circle-foods-ca', 'HCF-P005', 'Caroline Grant', 'Caroline', NULL, 'Grant', NULL, 'inactive'),
    ('harvest-circle-foods-ca', 'HCF-P006', 'Ahmed Khan', 'Ahmed', NULL, 'Khan', NULL, 'inactive'),
    ('harvest-circle-foods-ca', 'HCF-P007', 'Melissa Turner', 'Melissa', NULL, 'Turner', NULL, 'inactive'),
    ('harvest-circle-foods-ca', 'HCF-P008', 'George Bennett', 'George', NULL, 'Bennett', NULL, 'inactive'),
    ('harvest-circle-foods-ca', 'HCF-P009', 'Diane Fraser', 'Diane', NULL, 'Fraser', NULL, 'inactive'),
    ('harvest-circle-foods-ca', 'HCF-P010', 'Thomas Wilson', 'Thomas', NULL, 'Wilson', NULL, 'inactive'),
    ('harvest-circle-foods-ca', 'HCF-P011', 'Nadia Khan', 'Nadia', NULL, 'Khan', NULL, 'inactive'),
    ('harvest-circle-foods-ca', 'HCF-P012', 'Victor Moreau', 'Victor', NULL, 'Moreau', NULL, 'archived');

INSERT INTO people.persons (
    company_id,
    external_reference,
    display_name,
    given_name,
    middle_name,
    family_name,
    additional_family_name,
    person_status
)
SELECT
    companies.company_id,
    fixture.external_reference,
    fixture.display_name,
    fixture.given_name,
    fixture.middle_name,
    fixture.family_name,
    fixture.additional_family_name,
    fixture.person_status
FROM fixture_people AS fixture
JOIN core.companies AS companies
    ON companies.company_slug = fixture.company_slug
ON CONFLICT (company_id, external_reference)
DO UPDATE SET
    display_name = EXCLUDED.display_name,
    given_name = EXCLUDED.given_name,
    middle_name = EXCLUDED.middle_name,
    family_name = EXCLUDED.family_name,
    additional_family_name = EXCLUDED.additional_family_name,
    person_status = EXCLUDED.person_status,
    updated_at = NOW();

-- ============================================================
-- Person contact methods
-- ============================================================

CREATE TEMP TABLE fixture_person_contact_methods (
    company_slug TEXT NOT NULL,
    contact_key TEXT NOT NULL,
    person_external_reference TEXT NOT NULL,
    contact_type TEXT NOT NULL,
    contact_label TEXT,
    contact_value TEXT NOT NULL,
    is_primary BOOLEAN NOT NULL,
    is_verified BOOLEAN NOT NULL
) ON COMMIT DROP;

INSERT INTO fixture_person_contact_methods (
    company_slug,
    contact_key,
    person_external_reference,
    contact_type,
    contact_label,
    contact_value,
    is_primary,
    is_verified
)
VALUES
    -- Solara Retail Mexico
    ('solara-retail-mx', 'SRM-C-EMAIL-001', 'SRM-P001', 'email', 'Work', 'valeria.montes@solara-retail.example', TRUE, TRUE),
    ('solara-retail-mx', 'SRM-C-MOB-001', 'SRM-P001', 'mobile', 'Work mobile', '+52555010001', TRUE, TRUE),
    ('solara-retail-mx', 'SRM-C-EMAIL-002', 'SRM-P002', 'email', 'Work', 'daniel.rios@solara-retail.example', TRUE, TRUE),
    ('solara-retail-mx', 'SRM-C-MOB-002', 'SRM-P002', 'mobile', 'Work mobile', '+52555010002', TRUE, TRUE),
    ('solara-retail-mx', 'SRM-C-EMAIL-003', 'SRM-P003', 'email', 'Work', 'fernanda.alcazar@solara-retail.example', TRUE, TRUE),
    ('solara-retail-mx', 'SRM-C-MOB-003', 'SRM-P003', 'mobile', 'Work mobile', '+52555010003', TRUE, TRUE),
    ('solara-retail-mx', 'SRM-C-EMAIL-004', 'SRM-P004', 'email', 'Work', 'diego.sarmiento@solara-retail.example', TRUE, TRUE),
    ('solara-retail-mx', 'SRM-C-EMAIL-005', 'SRM-P005', 'email', 'Work', 'sofia.cardenas@solara-retail.example', TRUE, TRUE),
    ('solara-retail-mx', 'SRM-C-MOB-005', 'SRM-P005', 'mobile', 'Work mobile', '+52555010005', TRUE, FALSE),
    ('solara-retail-mx', 'SRM-C-EMAIL-006', 'SRM-P006', 'email', 'Work', 'mauricio.leal@solara-retail.example', TRUE, TRUE),
    ('solara-retail-mx', 'SRM-C-MOB-006', 'SRM-P006', 'mobile', 'Work mobile', '+52555010006', TRUE, TRUE),
    ('solara-retail-mx', 'SRM-C-EMAIL-007', 'SRM-P007', 'email', 'Work', 'karla.nunez@solara-retail.example', TRUE, TRUE),
    ('solara-retail-mx', 'SRM-C-MOB-007', 'SRM-P007', 'mobile', 'Work mobile', '+52555010007', TRUE, TRUE),
    ('solara-retail-mx', 'SRM-C-EMAIL-008', 'SRM-P008', 'email', 'Work', 'andres.villasenor@solara-retail.example', TRUE, TRUE),
    ('solara-retail-mx', 'SRM-C-EMAIL-009', 'SRM-P009', 'email', 'Work', 'paula.ibarra@solara-retail.example', TRUE, TRUE),
    ('solara-retail-mx', 'SRM-C-MOB-009', 'SRM-P009', 'mobile', 'Work mobile', '+52555010009', TRUE, TRUE),
    ('solara-retail-mx', 'SRM-C-EMAIL-010', 'SRM-P010', 'email', 'Work', 'jorge.tellez@solara-retail.example', TRUE, TRUE),
    ('solara-retail-mx', 'SRM-C-MOB-010', 'SRM-P010', 'mobile', 'Work mobile', '+52555010010', TRUE, FALSE),
    ('solara-retail-mx', 'SRM-C-EMAIL-011', 'SRM-P011', 'email', 'Work', 'camila.ortega@solara-retail.example', TRUE, TRUE),
    ('solara-retail-mx', 'SRM-C-MOB-011', 'SRM-P011', 'mobile', 'Work mobile', '+52555010011', TRUE, TRUE),
    ('solara-retail-mx', 'SRM-C-EMAIL-012', 'SRM-P012', 'email', 'Work', 'emiliano.cruz@solara-retail.example', TRUE, TRUE),
    ('solara-retail-mx', 'SRM-C-EMAIL-013', 'SRM-P013', 'email', 'Work', 'renata.silva@solara-retail.example', TRUE, TRUE),
    ('solara-retail-mx', 'SRM-C-MOB-013', 'SRM-P013', 'mobile', 'Work mobile', '+52555010013', TRUE, TRUE),
    ('solara-retail-mx', 'SRM-C-EMAIL-014', 'SRM-P014', 'email', 'Work', 'luis.trevino@solara-retail.example', TRUE, TRUE),
    ('solara-retail-mx', 'SRM-C-MOB-014', 'SRM-P014', 'mobile', 'Work mobile', '+52555010014', TRUE, TRUE),
    ('solara-retail-mx', 'SRM-C-EMAIL-015', 'SRM-P015', 'email', 'Work', 'mariana.rosales@solara-retail.example', TRUE, TRUE),
    ('solara-retail-mx', 'SRM-C-MOB-015', 'SRM-P015', 'mobile', 'Work mobile', '+52555010015', TRUE, FALSE),
    ('solara-retail-mx', 'SRM-C-EMAIL-016', 'SRM-P016', 'email', 'Work', 'hector.navarro@solara-retail.example', TRUE, TRUE),
    ('solara-retail-mx', 'SRM-C-EMAIL-017', 'SRM-P017', 'email', 'Work', 'omar.velasco@solara-retail.example', TRUE, TRUE),
    ('solara-retail-mx', 'SRM-C-MOB-017', 'SRM-P017', 'mobile', 'Work mobile', '+52555010017', TRUE, TRUE),
    ('solara-retail-mx', 'SRM-C-EMAIL-018', 'SRM-P018', 'email', 'Work', 'ximena.paredes@solara-retail.example', TRUE, TRUE),
    ('solara-retail-mx', 'SRM-C-MOB-018', 'SRM-P018', 'mobile', 'Work mobile', '+52555010018', TRUE, TRUE),
    ('solara-retail-mx', 'SRM-C-EMAIL-019', 'SRM-P019', 'email', 'Work', 'arturo.beltran@solara-retail.example', TRUE, TRUE),
    ('solara-retail-mx', 'SRM-C-MOB-019', 'SRM-P019', 'mobile', 'Work mobile', '+52555010019', TRUE, TRUE),
    ('solara-retail-mx', 'SRM-C-EMAIL-020', 'SRM-P020', 'email', 'Work', 'lucia.mejia@solara-retail.example', TRUE, TRUE),
    ('solara-retail-mx', 'SRM-C-EMAIL-021', 'SRM-P021', 'email', 'Work', 'ricardo.salas@solara-retail.example', TRUE, TRUE),
    ('solara-retail-mx', 'SRM-C-MOB-021', 'SRM-P021', 'mobile', 'Work mobile', '+52555010021', TRUE, TRUE),
    ('solara-retail-mx', 'SRM-C-EMAIL-022', 'SRM-P022', 'email', 'Work', 'nora.jimenez@altavista-loyalty.example', TRUE, TRUE),
    ('solara-retail-mx', 'SRM-C-EMAIL-023', 'SRM-P023', 'email', 'Work', 'gabriel.mena@envapack.example', TRUE, TRUE),
    ('solara-retail-mx', 'EXTRA-C-001', 'SRM-P024', 'mobile', 'Personal mobile', '+525559900024', TRUE, FALSE),
    ('solara-retail-mx', 'EXTRA-C-002', 'SRM-P025', 'mobile', 'Personal mobile', '+525559900025', TRUE, FALSE),
    ('solara-retail-mx', 'EXTRA-C-003', 'SRM-P026', 'mobile', 'Personal mobile', '+525559900026', TRUE, FALSE),
    ('solara-retail-mx', 'EXTRA-C-004', 'SRM-P027', 'mobile', 'Personal mobile', '+525559900027', TRUE, FALSE),
    ('solara-retail-mx', 'SHOW-C-001', 'SRM-P022', 'messaging_app', 'Partner WhatsApp', '+525559880022', TRUE, TRUE),
    ('solara-retail-mx', 'SHOW-C-002', 'SRM-P023', 'website', 'Supplier portal', 'https://envapack.example', TRUE, TRUE),
    ('solara-retail-mx', 'SHOW-C-009', 'SRM-P021', 'other', 'Secure contact channel', 'security-contact-srm-021', TRUE, TRUE),
    -- Cobalto Industrial Systems
    ('cobalto-industrial-mx', 'CIS-C-EMAIL-001', 'CIS-P001', 'email', 'Work', 'alejandro.barragan@cobalto-industrial.example', TRUE, TRUE),
    ('cobalto-industrial-mx', 'CIS-C-MOB-001', 'CIS-P001', 'mobile', 'Work mobile', '+52815020001', TRUE, TRUE),
    ('cobalto-industrial-mx', 'CIS-C-EMAIL-002', 'CIS-P002', 'email', 'Work', 'monica.cantu@cobalto-industrial.example', TRUE, TRUE),
    ('cobalto-industrial-mx', 'CIS-C-MOB-002', 'CIS-P002', 'mobile', 'Work mobile', '+52815020002', TRUE, TRUE),
    ('cobalto-industrial-mx', 'CIS-C-EMAIL-003', 'CIS-P003', 'email', 'Work', 'patricia.elizondo@cobalto-industrial.example', TRUE, TRUE),
    ('cobalto-industrial-mx', 'CIS-C-MOB-003', 'CIS-P003', 'mobile', 'Work mobile', '+52815020003', TRUE, TRUE),
    ('cobalto-industrial-mx', 'CIS-C-EMAIL-004', 'CIS-P004', 'email', 'Work', 'roberto.garza@cobalto-industrial.example', TRUE, TRUE),
    ('cobalto-industrial-mx', 'CIS-C-EMAIL-005', 'CIS-P005', 'email', 'Work', 'eduardo.villarreal@cobalto-industrial.example', TRUE, TRUE),
    ('cobalto-industrial-mx', 'CIS-C-MOB-005', 'CIS-P005', 'mobile', 'Work mobile', '+52815020005', TRUE, FALSE),
    ('cobalto-industrial-mx', 'CIS-C-EMAIL-006', 'CIS-P006', 'email', 'Work', 'silvia.castanon@cobalto-industrial.example', TRUE, TRUE),
    ('cobalto-industrial-mx', 'CIS-C-MOB-006', 'CIS-P006', 'mobile', 'Work mobile', '+52815020006', TRUE, TRUE),
    ('cobalto-industrial-mx', 'CIS-C-EMAIL-007', 'CIS-P007', 'email', 'Work', 'javier.de.la.fuente@cobalto-industrial.example', TRUE, TRUE),
    ('cobalto-industrial-mx', 'CIS-C-MOB-007', 'CIS-P007', 'mobile', 'Work mobile', '+52815020007', TRUE, TRUE),
    ('cobalto-industrial-mx', 'CIS-C-EMAIL-008', 'CIS-P008', 'email', 'Work', 'claudia.cepeda@cobalto-industrial.example', TRUE, TRUE),
    ('cobalto-industrial-mx', 'CIS-C-EMAIL-009', 'CIS-P009', 'email', 'Work', 'raul.zambrano@cobalto-industrial.example', TRUE, TRUE),
    ('cobalto-industrial-mx', 'CIS-C-MOB-009', 'CIS-P009', 'mobile', 'Work mobile', '+52815020009', TRUE, TRUE),
    ('cobalto-industrial-mx', 'CIS-C-EMAIL-010', 'CIS-P010', 'email', 'Work', 'adriana.flores@cobalto-industrial.example', TRUE, TRUE),
    ('cobalto-industrial-mx', 'CIS-C-MOB-010', 'CIS-P010', 'mobile', 'Work mobile', '+52815020010', TRUE, FALSE),
    ('cobalto-industrial-mx', 'CIS-C-EMAIL-011', 'CIS-P011', 'email', 'Work', 'manuel.guerra@cobalto-industrial.example', TRUE, TRUE),
    ('cobalto-industrial-mx', 'CIS-C-MOB-011', 'CIS-P011', 'mobile', 'Work mobile', '+52815020011', TRUE, TRUE),
    ('cobalto-industrial-mx', 'CIS-C-EMAIL-012', 'CIS-P012', 'email', 'Work', 'veronica.lozano@cobalto-industrial.example', TRUE, TRUE),
    ('cobalto-industrial-mx', 'CIS-C-EMAIL-013', 'CIS-P013', 'email', 'Work', 'sergio.maldonado@cobalto-industrial.example', TRUE, TRUE),
    ('cobalto-industrial-mx', 'CIS-C-MOB-013', 'CIS-P013', 'mobile', 'Work mobile', '+52815020013', TRUE, TRUE),
    ('cobalto-industrial-mx', 'CIS-C-EMAIL-014', 'CIS-P014', 'email', 'Work', 'irene.valdes@cobalto-industrial.example', TRUE, TRUE),
    ('cobalto-industrial-mx', 'CIS-C-MOB-014', 'CIS-P014', 'mobile', 'Work mobile', '+52815020014', TRUE, TRUE),
    ('cobalto-industrial-mx', 'CIS-C-EMAIL-015', 'CIS-P015', 'email', 'Work', 'oscar.padilla@cobalto-industrial.example', TRUE, TRUE),
    ('cobalto-industrial-mx', 'CIS-C-MOB-015', 'CIS-P015', 'mobile', 'Work mobile', '+52815020015', TRUE, FALSE),
    ('cobalto-industrial-mx', 'CIS-C-EMAIL-016', 'CIS-P016', 'email', 'Work', 'natalia.guerra@cobalto-industrial.example', TRUE, TRUE),
    ('cobalto-industrial-mx', 'CIS-C-EMAIL-017', 'CIS-P017', 'email', 'Work', 'ernesto.saldana@cobalto-industrial.example', TRUE, TRUE),
    ('cobalto-industrial-mx', 'CIS-C-MOB-017', 'CIS-P017', 'mobile', 'Work mobile', '+52815020017', TRUE, TRUE),
    ('cobalto-industrial-mx', 'CIS-C-EMAIL-018', 'CIS-P018', 'email', 'Work', 'beatriz.robles@cobalto-industrial.example', TRUE, TRUE),
    ('cobalto-industrial-mx', 'CIS-C-MOB-018', 'CIS-P018', 'mobile', 'Work mobile', '+52815020018', TRUE, TRUE),
    ('cobalto-industrial-mx', 'CIS-C-EMAIL-019', 'CIS-P019', 'email', 'Work', 'miguel.angel.ceballos@cobalto-industrial.example', TRUE, TRUE),
    ('cobalto-industrial-mx', 'CIS-C-MOB-019', 'CIS-P019', 'mobile', 'Work mobile', '+52815020019', TRUE, TRUE),
    ('cobalto-industrial-mx', 'CIS-C-EMAIL-020', 'CIS-P020', 'email', 'Work', 'rocio.esquivel@cobalto-industrial.example', TRUE, TRUE),
    ('cobalto-industrial-mx', 'CIS-C-EMAIL-021', 'CIS-P021', 'email', 'Work', 'hugo.santillan@cobalto-industrial.example', TRUE, TRUE),
    ('cobalto-industrial-mx', 'CIS-C-MOB-021', 'CIS-P021', 'mobile', 'Work mobile', '+52815020021', TRUE, TRUE),
    ('cobalto-industrial-mx', 'CIS-C-EMAIL-022', 'CIS-P022', 'email', 'Work', 'teresa.becerra@metales-del-norte.example', TRUE, TRUE),
    ('cobalto-industrial-mx', 'CIS-C-EMAIL-023', 'CIS-P023', 'email', 'Work', 'ivan.sepulveda@motiongrid.example', TRUE, TRUE),
    ('cobalto-industrial-mx', 'EXTRA-C-005', 'CIS-P024', 'mobile', 'Personal mobile', '+528159900024', TRUE, FALSE),
    ('cobalto-industrial-mx', 'EXTRA-C-006', 'CIS-P025', 'mobile', 'Personal mobile', '+528159900025', TRUE, FALSE),
    ('cobalto-industrial-mx', 'SHOW-C-003', 'CIS-P023', 'website', 'Alliance portal', 'https://motiongrid.example', TRUE, TRUE),
    -- BluePeak Advisory
    ('bluepeak-advisory-us', 'BPA-C-EMAIL-001', 'BPA-P001', 'email', 'Work', 'olivia.bennett@bluepeak-advisory.example', TRUE, TRUE),
    ('bluepeak-advisory-us', 'BPA-C-MOB-001', 'BPA-P001', 'mobile', 'Work mobile', '+15125530001', TRUE, TRUE),
    ('bluepeak-advisory-us', 'BPA-C-EMAIL-002', 'BPA-P002', 'email', 'Work', 'ethan.parker@bluepeak-advisory.example', TRUE, TRUE),
    ('bluepeak-advisory-us', 'BPA-C-MOB-002', 'BPA-P002', 'mobile', 'Work mobile', '+15125530002', TRUE, TRUE),
    ('bluepeak-advisory-us', 'BPA-C-EMAIL-003', 'BPA-P003', 'email', 'Work', 'maya.thompson@bluepeak-advisory.example', TRUE, TRUE),
    ('bluepeak-advisory-us', 'BPA-C-MOB-003', 'BPA-P003', 'mobile', 'Work mobile', '+15125530003', TRUE, TRUE),
    ('bluepeak-advisory-us', 'BPA-C-EMAIL-004', 'BPA-P004', 'email', 'Work', 'jonathan.reed@bluepeak-advisory.example', TRUE, TRUE),
    ('bluepeak-advisory-us', 'BPA-C-EMAIL-005', 'BPA-P005', 'email', 'Work', 'priya.shah@bluepeak-advisory.example', TRUE, TRUE),
    ('bluepeak-advisory-us', 'BPA-C-MOB-005', 'BPA-P005', 'mobile', 'Work mobile', '+15125530005', TRUE, FALSE),
    ('bluepeak-advisory-us', 'BPA-C-EMAIL-006', 'BPA-P006', 'email', 'Work', 'marcus.hill@bluepeak-advisory.example', TRUE, TRUE),
    ('bluepeak-advisory-us', 'BPA-C-MOB-006', 'BPA-P006', 'mobile', 'Work mobile', '+15125530006', TRUE, TRUE),
    ('bluepeak-advisory-us', 'BPA-C-EMAIL-007', 'BPA-P007', 'email', 'Work', 'claire.donovan@bluepeak-advisory.example', TRUE, TRUE),
    ('bluepeak-advisory-us', 'BPA-C-MOB-007', 'BPA-P007', 'mobile', 'Work mobile', '+15125530007', TRUE, TRUE),
    ('bluepeak-advisory-us', 'BPA-C-EMAIL-008', 'BPA-P008', 'email', 'Work', 'noah.williams@bluepeak-advisory.example', TRUE, TRUE),
    ('bluepeak-advisory-us', 'BPA-C-EMAIL-009', 'BPA-P009', 'email', 'Work', 'grace.kim@bluepeak-advisory.example', TRUE, TRUE),
    ('bluepeak-advisory-us', 'BPA-C-MOB-009', 'BPA-P009', 'mobile', 'Work mobile', '+15125530009', TRUE, TRUE),
    ('bluepeak-advisory-us', 'BPA-C-EMAIL-010', 'BPA-P010', 'email', 'Work', 'avery.collins@bluepeak-advisory.example', TRUE, TRUE),
    ('bluepeak-advisory-us', 'BPA-C-MOB-010', 'BPA-P010', 'mobile', 'Work mobile', '+15125530010', TRUE, FALSE),
    ('bluepeak-advisory-us', 'BPA-C-EMAIL-011', 'BPA-P011', 'email', 'Work', 'liam.foster@bluepeak-advisory.example', TRUE, TRUE),
    ('bluepeak-advisory-us', 'BPA-C-MOB-011', 'BPA-P011', 'mobile', 'Work mobile', '+15125530011', TRUE, TRUE),
    ('bluepeak-advisory-us', 'BPA-C-EMAIL-012', 'BPA-P012', 'email', 'Work', 'amelia.brooks@bluepeak-advisory.example', TRUE, TRUE),
    ('bluepeak-advisory-us', 'BPA-C-EMAIL-013', 'BPA-P013', 'email', 'Work', 'david.chen@bluepeak-advisory.example', TRUE, TRUE),
    ('bluepeak-advisory-us', 'BPA-C-MOB-013', 'BPA-P013', 'mobile', 'Work mobile', '+15125530013', TRUE, TRUE),
    ('bluepeak-advisory-us', 'BPA-C-EMAIL-014', 'BPA-P014', 'email', 'Work', 'rachel.morgan@bluepeak-advisory.example', TRUE, TRUE),
    ('bluepeak-advisory-us', 'BPA-C-MOB-014', 'BPA-P014', 'mobile', 'Work mobile', '+15125530014', TRUE, TRUE),
    ('bluepeak-advisory-us', 'BPA-C-EMAIL-015', 'BPA-P015', 'email', 'Work', 'samuel.ortiz@bluepeak-advisory.example', TRUE, TRUE),
    ('bluepeak-advisory-us', 'BPA-C-MOB-015', 'BPA-P015', 'mobile', 'Work mobile', '+15125530015', TRUE, FALSE),
    ('bluepeak-advisory-us', 'BPA-C-EMAIL-016', 'BPA-P016', 'email', 'Work', 'nina.patel@bluepeak-advisory.example', TRUE, TRUE),
    ('bluepeak-advisory-us', 'BPA-C-EMAIL-017', 'BPA-P017', 'email', 'Work', 'jordan.ellis@bluepeak-advisory.example', TRUE, TRUE),
    ('bluepeak-advisory-us', 'BPA-C-MOB-017', 'BPA-P017', 'mobile', 'Work mobile', '+15125530017', TRUE, TRUE),
    ('bluepeak-advisory-us', 'BPA-C-EMAIL-018', 'BPA-P018', 'email', 'Work', 'taylor.monroe@bluepeak-advisory.example', TRUE, TRUE),
    ('bluepeak-advisory-us', 'BPA-C-MOB-018', 'BPA-P018', 'mobile', 'Work mobile', '+15125530018', TRUE, TRUE),
    ('bluepeak-advisory-us', 'BPA-C-EMAIL-019', 'BPA-P019', 'email', 'Work', 'christopher.lang@lang-governance.example', TRUE, TRUE),
    ('bluepeak-advisory-us', 'EXTRA-C-007', 'BPA-P020', 'mobile', 'Personal mobile', '+151259900020', TRUE, FALSE),
    ('bluepeak-advisory-us', 'SHOW-C-004', 'BPA-P019', 'website', 'Advisory profile', 'https://lang-governance.example', TRUE, TRUE),
    ('bluepeak-advisory-us', 'SHOW-C-005', 'BPA-P019', 'social_profile', 'Professional profile', 'https://social.example/christopher-lang', TRUE, TRUE),
    -- LumenForge Technologies
    ('lumenforge-technologies-us', 'LFT-C-EMAIL-001', 'LFT-P001', 'email', 'Work', 'aisha.rahman@lumenforge-tech.example', TRUE, TRUE),
    ('lumenforge-technologies-us', 'LFT-C-MOB-001', 'LFT-P001', 'mobile', 'Work mobile', '+12065540001', TRUE, TRUE),
    ('lumenforge-technologies-us', 'LFT-C-EMAIL-002', 'LFT-P002', 'email', 'Work', 'benjamin.carter@lumenforge-tech.example', TRUE, TRUE),
    ('lumenforge-technologies-us', 'LFT-C-MOB-002', 'LFT-P002', 'mobile', 'Work mobile', '+12065540002', TRUE, TRUE),
    ('lumenforge-technologies-us', 'LFT-C-EMAIL-003', 'LFT-P003', 'email', 'Work', 'elena.rodriguez@lumenforge-tech.example', TRUE, TRUE),
    ('lumenforge-technologies-us', 'LFT-C-MOB-003', 'LFT-P003', 'mobile', 'Work mobile', '+12065540003', TRUE, TRUE),
    ('lumenforge-technologies-us', 'LFT-C-EMAIL-004', 'LFT-P004', 'email', 'Work', 'kevin.wu@lumenforge-tech.example', TRUE, TRUE),
    ('lumenforge-technologies-us', 'LFT-C-EMAIL-005', 'LFT-P005', 'email', 'Work', 'morgan.price@lumenforge-tech.example', TRUE, TRUE),
    ('lumenforge-technologies-us', 'LFT-C-MOB-005', 'LFT-P005', 'mobile', 'Work mobile', '+12065540005', TRUE, FALSE),
    ('lumenforge-technologies-us', 'LFT-C-EMAIL-006', 'LFT-P006', 'email', 'Work', 'natalie.green@lumenforge-tech.example', TRUE, TRUE),
    ('lumenforge-technologies-us', 'LFT-C-MOB-006', 'LFT-P006', 'mobile', 'Work mobile', '+12065540006', TRUE, TRUE),
    ('lumenforge-technologies-us', 'LFT-C-EMAIL-007', 'LFT-P007', 'email', 'Work', 'owen.murphy@lumenforge-tech.example', TRUE, TRUE),
    ('lumenforge-technologies-us', 'LFT-C-MOB-007', 'LFT-P007', 'mobile', 'Work mobile', '+12065540007', TRUE, TRUE),
    ('lumenforge-technologies-us', 'LFT-C-EMAIL-008', 'LFT-P008', 'email', 'Work', 'sierra.james@lumenforge-tech.example', TRUE, TRUE),
    ('lumenforge-technologies-us', 'LFT-C-EMAIL-009', 'LFT-P009', 'email', 'Work', 'caleb.turner@lumenforge-tech.example', TRUE, TRUE),
    ('lumenforge-technologies-us', 'LFT-C-MOB-009', 'LFT-P009', 'mobile', 'Work mobile', '+12065540009', TRUE, TRUE),
    ('lumenforge-technologies-us', 'LFT-C-EMAIL-010', 'LFT-P010', 'email', 'Work', 'hannah.lee@lumenforge-tech.example', TRUE, TRUE),
    ('lumenforge-technologies-us', 'LFT-C-MOB-010', 'LFT-P010', 'mobile', 'Work mobile', '+12065540010', TRUE, FALSE),
    ('lumenforge-technologies-us', 'LFT-C-EMAIL-011', 'LFT-P011', 'email', 'Work', 'victor.alvarez@lumenforge-tech.example', TRUE, TRUE),
    ('lumenforge-technologies-us', 'LFT-C-MOB-011', 'LFT-P011', 'mobile', 'Work mobile', '+12065540011', TRUE, TRUE),
    ('lumenforge-technologies-us', 'LFT-C-EMAIL-012', 'LFT-P012', 'email', 'Work', 'mei.lin@lumenforge-tech.example', TRUE, TRUE),
    ('lumenforge-technologies-us', 'LFT-C-EMAIL-013', 'LFT-P013', 'email', 'Work', 'isaac.coleman@lumenforge-tech.example', TRUE, TRUE),
    ('lumenforge-technologies-us', 'LFT-C-MOB-013', 'LFT-P013', 'mobile', 'Work mobile', '+12065540013', TRUE, TRUE),
    ('lumenforge-technologies-us', 'LFT-C-EMAIL-014', 'LFT-P014', 'email', 'Work', 'zoe.martin@lumenforge-tech.example', TRUE, TRUE),
    ('lumenforge-technologies-us', 'LFT-C-MOB-014', 'LFT-P014', 'mobile', 'Work mobile', '+12065540014', TRUE, TRUE),
    ('lumenforge-technologies-us', 'LFT-C-EMAIL-015', 'LFT-P015', 'email', 'Work', 'daniel.okafor@lumenforge-tech.example', TRUE, TRUE),
    ('lumenforge-technologies-us', 'LFT-C-MOB-015', 'LFT-P015', 'mobile', 'Work mobile', '+12065540015', TRUE, FALSE),
    ('lumenforge-technologies-us', 'LFT-C-EMAIL-016', 'LFT-P016', 'email', 'Work', 'chloe.nguyen@lumenforge-tech.example', TRUE, TRUE),
    ('lumenforge-technologies-us', 'LFT-C-EMAIL-017', 'LFT-P017', 'email', 'Work', 'ryan.scott@lumenforge-tech.example', TRUE, TRUE),
    ('lumenforge-technologies-us', 'LFT-C-MOB-017', 'LFT-P017', 'mobile', 'Work mobile', '+12065540017', TRUE, TRUE),
    ('lumenforge-technologies-us', 'LFT-C-EMAIL-018', 'LFT-P018', 'email', 'Work', 'fatima.hassan@lumenforge-tech.example', TRUE, TRUE),
    ('lumenforge-technologies-us', 'LFT-C-MOB-018', 'LFT-P018', 'mobile', 'Work mobile', '+12065540018', TRUE, TRUE),
    ('lumenforge-technologies-us', 'LFT-C-EMAIL-019', 'LFT-P019', 'email', 'Work', 'lucas.grant@lumenforge-tech.example', TRUE, TRUE),
    ('lumenforge-technologies-us', 'LFT-C-MOB-019', 'LFT-P019', 'mobile', 'Work mobile', '+12065540019', TRUE, TRUE),
    ('lumenforge-technologies-us', 'LFT-C-EMAIL-020', 'LFT-P020', 'email', 'Work', 'madison.cole@lumenforge-tech.example', TRUE, TRUE),
    ('lumenforge-technologies-us', 'LFT-C-EMAIL-021', 'LFT-P021', 'email', 'Work', 'derek.stone@lumenforge-tech.example', TRUE, TRUE),
    ('lumenforge-technologies-us', 'LFT-C-MOB-021', 'LFT-P021', 'mobile', 'Work mobile', '+12065540021', TRUE, TRUE),
    ('lumenforge-technologies-us', 'EXTRA-C-008', 'LFT-P022', 'mobile', 'Personal mobile', '+120659900022', TRUE, FALSE),
    ('lumenforge-technologies-us', 'SHOW-C-006', 'LFT-P021', 'website', 'Consulting company', 'https://stone-security.example', TRUE, TRUE),
    -- Cedarline Logistics
    ('cedarline-logistics-ca', 'CLL-C-EMAIL-001', 'CLL-P001', 'email', 'Work', 'charlotte.tremblay@cedarline-logistics.example', TRUE, TRUE),
    ('cedarline-logistics-ca', 'CLL-C-MOB-001', 'CLL-P001', 'mobile', 'Work mobile', '+14165550001', TRUE, TRUE),
    ('cedarline-logistics-ca', 'CLL-C-EMAIL-002', 'CLL-P002', 'email', 'Work', 'liam.mckenzie@cedarline-logistics.example', TRUE, TRUE),
    ('cedarline-logistics-ca', 'CLL-C-MOB-002', 'CLL-P002', 'mobile', 'Work mobile', '+14165550002', TRUE, TRUE),
    ('cedarline-logistics-ca', 'CLL-C-EMAIL-003', 'CLL-P003', 'email', 'Work', 'sophie.gagnon@cedarline-logistics.example', TRUE, TRUE),
    ('cedarline-logistics-ca', 'CLL-C-MOB-003', 'CLL-P003', 'mobile', 'Work mobile', '+14165550003', TRUE, TRUE),
    ('cedarline-logistics-ca', 'CLL-C-EMAIL-004', 'CLL-P004', 'email', 'Work', 'nathan.wong@cedarline-logistics.example', TRUE, TRUE),
    ('cedarline-logistics-ca', 'CLL-C-EMAIL-005', 'CLL-P005', 'email', 'Work', 'emily.fraser@cedarline-logistics.example', TRUE, TRUE),
    ('cedarline-logistics-ca', 'CLL-C-MOB-005', 'CLL-P005', 'mobile', 'Work mobile', '+14165550005', TRUE, FALSE),
    ('cedarline-logistics-ca', 'CLL-C-EMAIL-006', 'CLL-P006', 'email', 'Work', 'jacob.singh@cedarline-logistics.example', TRUE, TRUE),
    ('cedarline-logistics-ca', 'CLL-C-MOB-006', 'CLL-P006', 'mobile', 'Work mobile', '+14165550006', TRUE, TRUE),
    ('cedarline-logistics-ca', 'CLL-C-EMAIL-007', 'CLL-P007', 'email', 'Work', 'amelie.roy@cedarline-logistics.example', TRUE, TRUE),
    ('cedarline-logistics-ca', 'CLL-C-MOB-007', 'CLL-P007', 'mobile', 'Work mobile', '+14165550007', TRUE, TRUE),
    ('cedarline-logistics-ca', 'CLL-C-EMAIL-008', 'CLL-P008', 'email', 'Work', 'connor.hughes@cedarline-logistics.example', TRUE, TRUE),
    ('cedarline-logistics-ca', 'CLL-C-EMAIL-009', 'CLL-P009', 'email', 'Work', 'mia.campbell@cedarline-logistics.example', TRUE, TRUE),
    ('cedarline-logistics-ca', 'CLL-C-MOB-009', 'CLL-P009', 'mobile', 'Work mobile', '+14165550009', TRUE, TRUE),
    ('cedarline-logistics-ca', 'CLL-C-EMAIL-010', 'CLL-P010', 'email', 'Work', 'william.chen@cedarline-logistics.example', TRUE, TRUE),
    ('cedarline-logistics-ca', 'CLL-C-MOB-010', 'CLL-P010', 'mobile', 'Work mobile', '+14165550010', TRUE, FALSE),
    ('cedarline-logistics-ca', 'CLL-C-EMAIL-011', 'CLL-P011', 'email', 'Work', 'ava.macdonald@cedarline-logistics.example', TRUE, TRUE),
    ('cedarline-logistics-ca', 'CLL-C-MOB-011', 'CLL-P011', 'mobile', 'Work mobile', '+14165550011', TRUE, TRUE),
    ('cedarline-logistics-ca', 'CLL-C-EMAIL-012', 'CLL-P012', 'email', 'Work', 'noah.bouchard@cedarline-logistics.example', TRUE, TRUE),
    ('cedarline-logistics-ca', 'CLL-C-EMAIL-013', 'CLL-P013', 'email', 'Work', 'isabelle.martin@cedarline-logistics.example', TRUE, TRUE),
    ('cedarline-logistics-ca', 'CLL-C-MOB-013', 'CLL-P013', 'mobile', 'Work mobile', '+14165550013', TRUE, TRUE),
    ('cedarline-logistics-ca', 'CLL-C-EMAIL-014', 'CLL-P014', 'email', 'Work', 'ethan.brown@cedarline-logistics.example', TRUE, TRUE),
    ('cedarline-logistics-ca', 'CLL-C-MOB-014', 'CLL-P014', 'mobile', 'Work mobile', '+14165550014', TRUE, TRUE),
    ('cedarline-logistics-ca', 'CLL-C-EMAIL-015', 'CLL-P015', 'email', 'Work', 'layla.ahmed@cedarline-logistics.example', TRUE, TRUE),
    ('cedarline-logistics-ca', 'CLL-C-MOB-015', 'CLL-P015', 'mobile', 'Work mobile', '+14165550015', TRUE, FALSE),
    ('cedarline-logistics-ca', 'CLL-C-EMAIL-016', 'CLL-P016', 'email', 'Work', 'mason.clarke@cedarline-logistics.example', TRUE, TRUE),
    ('cedarline-logistics-ca', 'CLL-C-EMAIL-017', 'CLL-P017', 'email', 'Work', 'zoe.pelletier@cedarline-logistics.example', TRUE, TRUE),
    ('cedarline-logistics-ca', 'CLL-C-MOB-017', 'CLL-P017', 'mobile', 'Work mobile', '+14165550017', TRUE, TRUE),
    ('cedarline-logistics-ca', 'CLL-C-EMAIL-018', 'CLL-P018', 'email', 'Work', 'arjun.mehta@cedarline-logistics.example', TRUE, TRUE),
    ('cedarline-logistics-ca', 'CLL-C-MOB-018', 'CLL-P018', 'mobile', 'Work mobile', '+14165550018', TRUE, TRUE),
    ('cedarline-logistics-ca', 'CLL-C-EMAIL-019', 'CLL-P019', 'email', 'Work', 'grace.tremblay@cedarline-logistics.example', TRUE, TRUE),
    ('cedarline-logistics-ca', 'CLL-C-MOB-019', 'CLL-P019', 'mobile', 'Work mobile', '+14165550019', TRUE, TRUE),
    ('cedarline-logistics-ca', 'CLL-C-EMAIL-020', 'CLL-P020', 'email', 'Work', 'oliver.singh@northmart.example', TRUE, TRUE),
    ('cedarline-logistics-ca', 'CLL-C-EMAIL-021', 'CLL-P021', 'email', 'Work', 'luc.martin@fleetcare.example', TRUE, TRUE),
    ('cedarline-logistics-ca', 'EXTRA-C-009', 'CLL-P019', 'email', 'Contract email', 'grace.tremblay@routeworks.example', FALSE, TRUE),
    ('cedarline-logistics-ca', 'EXTRA-C-010', 'CLL-P020', 'phone', 'Office', '+141659900020', TRUE, TRUE),
    ('cedarline-logistics-ca', 'EXTRA-C-011', 'CLL-P021', 'phone', 'Office', '+151459900021', TRUE, TRUE),
    ('cedarline-logistics-ca', 'SHOW-C-007', 'CLL-P020', 'messaging_app', 'Account messaging', '+141659910020', TRUE, TRUE),
    -- Harvest Circle Foods
    ('harvest-circle-foods-ca', 'HCF-C-EMAIL-001', 'HCF-P001', 'email', 'Work', 'margaret.wilson@harvest-circle.example', TRUE, FALSE),
    ('harvest-circle-foods-ca', 'HCF-C-PHONE-001', 'HCF-P001', 'phone', 'Historical work line', '+16045560001', TRUE, FALSE),
    ('harvest-circle-foods-ca', 'HCF-C-EMAIL-002', 'HCF-P002', 'email', 'Work', 'robert.sinclair@harvest-circle.example', TRUE, FALSE),
    ('harvest-circle-foods-ca', 'HCF-C-PHONE-002', 'HCF-P002', 'phone', 'Historical work line', '+16045560002', TRUE, FALSE),
    ('harvest-circle-foods-ca', 'HCF-C-EMAIL-003', 'HCF-P003', 'email', 'Work', 'janet.liu@harvest-circle.example', TRUE, FALSE),
    ('harvest-circle-foods-ca', 'HCF-C-PHONE-003', 'HCF-P003', 'phone', 'Historical work line', '+16045560003', TRUE, FALSE),
    ('harvest-circle-foods-ca', 'HCF-C-EMAIL-004', 'HCF-P004', 'email', 'Work', 'peter.dubois@harvest-circle.example', TRUE, FALSE),
    ('harvest-circle-foods-ca', 'HCF-C-PHONE-004', 'HCF-P004', 'phone', 'Historical work line', '+16045560004', TRUE, FALSE),
    ('harvest-circle-foods-ca', 'HCF-C-EMAIL-005', 'HCF-P005', 'email', 'Work', 'caroline.grant@harvest-circle.example', TRUE, FALSE),
    ('harvest-circle-foods-ca', 'HCF-C-PHONE-005', 'HCF-P005', 'phone', 'Historical work line', '+16045560005', TRUE, FALSE),
    ('harvest-circle-foods-ca', 'HCF-C-EMAIL-006', 'HCF-P006', 'email', 'Work', 'ahmed.khan@harvest-circle.example', TRUE, FALSE),
    ('harvest-circle-foods-ca', 'HCF-C-EMAIL-007', 'HCF-P007', 'email', 'Work', 'melissa.turner@harvest-circle.example', TRUE, FALSE),
    ('harvest-circle-foods-ca', 'HCF-C-EMAIL-008', 'HCF-P008', 'email', 'Work', 'george.bennett@harvest-circle.example', TRUE, FALSE),
    ('harvest-circle-foods-ca', 'HCF-C-EMAIL-009', 'HCF-P009', 'email', 'Work', 'diane.fraser@harvest-circle.example', TRUE, FALSE),
    ('harvest-circle-foods-ca', 'HCF-C-EMAIL-010', 'HCF-P012', 'email', 'Work', 'victor.moreau@pacific-packaging.example', TRUE, FALSE),
    ('harvest-circle-foods-ca', 'EXTRA-C-012', 'HCF-P010', 'mobile', 'Personal mobile', '+160459900010', TRUE, FALSE),
    ('harvest-circle-foods-ca', 'EXTRA-C-013', 'HCF-P011', 'mobile', 'Personal mobile', '+160459900011', TRUE, FALSE),
    ('harvest-circle-foods-ca', 'SHOW-C-008', 'HCF-P012', 'website', 'Former supplier site', 'https://pacific-packaging.example', TRUE, FALSE);

-- Refresh contact methods already owned by this fixture. The
-- fixture-level natural key is person + type + label.
UPDATE people.person_contact_methods AS contact_methods
SET
    contact_value = fixture.contact_value,
    is_primary = fixture.is_primary,
    is_verified = fixture.is_verified,
    updated_at = NOW()
FROM fixture_person_contact_methods AS fixture
JOIN core.companies AS companies
    ON companies.company_slug = fixture.company_slug
JOIN people.persons AS persons
    ON persons.company_id = companies.company_id
    AND persons.external_reference = fixture.person_external_reference
WHERE contact_methods.company_id = companies.company_id
  AND contact_methods.person_id = persons.person_id
  AND contact_methods.contact_type = fixture.contact_type
  AND contact_methods.contact_label IS NOT DISTINCT FROM fixture.contact_label;

INSERT INTO people.person_contact_methods (
    company_id,
    person_id,
    contact_type,
    contact_label,
    contact_value,
    is_primary,
    is_verified
)
SELECT
    companies.company_id,
    persons.person_id,
    fixture.contact_type,
    fixture.contact_label,
    fixture.contact_value,
    fixture.is_primary,
    fixture.is_verified
FROM fixture_person_contact_methods AS fixture
JOIN core.companies AS companies
    ON companies.company_slug = fixture.company_slug
JOIN people.persons AS persons
    ON persons.company_id = companies.company_id
    AND persons.external_reference = fixture.person_external_reference
WHERE NOT EXISTS (
    SELECT 1
    FROM people.person_contact_methods AS contact_methods
    WHERE contact_methods.company_id = companies.company_id
      AND contact_methods.person_id = persons.person_id
      AND contact_methods.contact_type = fixture.contact_type
      AND contact_methods.contact_label IS NOT DISTINCT FROM fixture.contact_label
);

-- ============================================================
-- Person-company roles
-- ============================================================

CREATE TEMP TABLE fixture_person_company_roles (
    company_slug TEXT NOT NULL,
    role_key TEXT NOT NULL,
    person_external_reference TEXT NOT NULL,
    role_type TEXT NOT NULL,
    role_title TEXT,
    role_status TEXT NOT NULL,
    valid_from DATE NOT NULL,
    valid_to DATE,
    notes TEXT
) ON COMMIT DROP;

INSERT INTO fixture_person_company_roles (
    company_slug,
    role_key,
    person_external_reference,
    role_type,
    role_title,
    role_status,
    valid_from,
    valid_to,
    notes
)
VALUES
    -- Solara Retail Mexico
    ('solara-retail-mx', 'SRM-R001', 'SRM-P001', 'employee', 'Chief Executive Officer', 'active', '2014-03-17', NULL, NULL),
    ('solara-retail-mx', 'SRM-R002', 'SRM-P002', 'employee', 'Chief Financial Officer', 'active', '2016-01-11', NULL, NULL),
    ('solara-retail-mx', 'SRM-R003', 'SRM-P003', 'employee', 'People and Culture Director', 'active', '2017-05-08', NULL, NULL),
    ('solara-retail-mx', 'SRM-R004', 'SRM-P004', 'employee', 'Chief Technology Officer', 'active', '2018-02-19', NULL, NULL),
    ('solara-retail-mx', 'SRM-R005', 'SRM-P005', 'employee', 'Marketing and Customer Insights Director', 'active', '2019-04-01', NULL, NULL),
    ('solara-retail-mx', 'SRM-R006', 'SRM-P006', 'employee', 'Retail Operations Director', 'active', '2015-07-13', NULL, NULL),
    ('solara-retail-mx', 'SRM-R007', 'SRM-P007', 'employee', 'Supply Chain Director', 'active', '2018-09-03', NULL, NULL),
    ('solara-retail-mx', 'SRM-R008', 'SRM-P008', 'employee', 'Digital Commerce Director', 'active', '2020-05-01', NULL, NULL),
    ('solara-retail-mx', 'SRM-R009', 'SRM-P009', 'employee', 'Corporate Controller', 'active', '2018-06-18', NULL, NULL),
    ('solara-retail-mx', 'SRM-R010', 'SRM-P010', 'employee', 'FP&A Manager', 'active', '2021-01-18', NULL, NULL),
    ('solara-retail-mx', 'SRM-R011', 'SRM-P011', 'employee', 'Talent and Development Manager', 'active', '2020-08-10', NULL, NULL),
    ('solara-retail-mx', 'SRM-R012', 'SRM-P012', 'employee', 'Data and Analytics Manager', 'active', '2021-03-15', NULL, NULL),
    ('solara-retail-mx', 'SRM-R013', 'SRM-P013', 'employee', 'CRM and Loyalty Manager', 'active', '2021-11-08', NULL, NULL),
    ('solara-retail-mx', 'SRM-R014', 'SRM-P014', 'employee', 'Polanco Store Manager', 'active', '2019-02-04', NULL, NULL),
    ('solara-retail-mx', 'SRM-R015', 'SRM-P015', 'employee', 'South Mexico City Store Manager', 'active', '2020-01-13', NULL, NULL),
    ('solara-retail-mx', 'SRM-R016', 'SRM-P016', 'employee', 'Guadalajara Store Manager', 'active', '2021-03-29', NULL, NULL),
    ('solara-retail-mx', 'SRM-R017', 'SRM-P017', 'employee', 'Distribution Center Manager', 'active', '2019-05-20', NULL, NULL),
    ('solara-retail-mx', 'SRM-R018', 'SRM-P018', 'employee', 'E-commerce Operations Manager', 'active', '2020-06-15', NULL, NULL),
    ('solara-retail-mx', 'SRM-R019', 'SRM-P019', 'employee', 'Senior Data Analyst', 'active', '2022-07-04', NULL, NULL),
    ('solara-retail-mx', 'SRM-R020', 'SRM-P020', 'employee', 'E-commerce Operations Specialist', 'active', '2023-02-13', NULL, NULL),
    ('solara-retail-mx', 'SRM-R021', 'SRM-P021', 'contractor', 'Cybersecurity Advisor', 'active', '2025-01-06', NULL, 'Independent specialist supporting the technology leadership team.'),
    ('solara-retail-mx', 'SRM-R022', 'SRM-P022', 'customer_contact', 'Loyalty Program Contact', 'active', '2024-03-01', NULL, 'Primary contact at a strategic loyalty-program partner.'),
    ('solara-retail-mx', 'SRM-R023', 'SRM-P023', 'supplier_contact', 'Regional Account Manager', 'active', '2022-09-12', NULL, 'Primary commercial contact for a packaging supplier.'),
    -- Cobalto Industrial Systems
    ('cobalto-industrial-mx', 'CIS-R001', 'CIS-P001', 'employee', 'Chief Executive Officer', 'active', '2008-08-11', NULL, NULL),
    ('cobalto-industrial-mx', 'CIS-R002', 'CIS-P002', 'employee', 'Chief Financial Officer', 'active', '2012-02-06', NULL, NULL),
    ('cobalto-industrial-mx', 'CIS-R003', 'CIS-P003', 'employee', 'People and Culture Director', 'active', '2014-06-02', NULL, NULL),
    ('cobalto-industrial-mx', 'CIS-R004', 'CIS-P004', 'employee', 'Vice President of Engineering', 'active', '2011-09-19', NULL, NULL),
    ('cobalto-industrial-mx', 'CIS-R005', 'CIS-P005', 'employee', 'Vice President of Manufacturing', 'active', '2010-02-22', NULL, NULL),
    ('cobalto-industrial-mx', 'CIS-R006', 'CIS-P006', 'employee', 'Supply Chain Director', 'active', '2015-04-13', NULL, NULL),
    ('cobalto-industrial-mx', 'CIS-R007', 'CIS-P007', 'employee', 'Sales Director', 'active', '2013-08-05', NULL, NULL),
    ('cobalto-industrial-mx', 'CIS-R008', 'CIS-P008', 'employee', 'Quality and Compliance Director', 'active', '2016-01-11', NULL, NULL),
    ('cobalto-industrial-mx', 'CIS-R009', 'CIS-P009', 'employee', 'Field Service Director', 'active', '2018-09-17', NULL, NULL),
    ('cobalto-industrial-mx', 'CIS-R010', 'CIS-P010', 'employee', 'Accounting Manager', 'active', '2017-03-20', NULL, NULL),
    ('cobalto-industrial-mx', 'CIS-R011', 'CIS-P011', 'employee', 'Product Engineering Manager', 'active', '2015-10-12', NULL, NULL),
    ('cobalto-industrial-mx', 'CIS-R012', 'CIS-P012', 'employee', 'Automation Engineering Manager', 'active', '2018-05-14', NULL, NULL),
    ('cobalto-industrial-mx', 'CIS-R013', 'CIS-P013', 'employee', 'Apodaca Plant Manager', 'active', '2016-07-04', NULL, NULL),
    ('cobalto-industrial-mx', 'CIS-R014', 'CIS-P014', 'employee', 'San Luis Potosi Plant Manager', 'active', '2021-10-04', NULL, NULL),
    ('cobalto-industrial-mx', 'CIS-R015', 'CIS-P015', 'employee', 'Warehouse Operations Manager', 'active', '2017-01-09', NULL, NULL),
    ('cobalto-industrial-mx', 'CIS-R016', 'CIS-P016', 'employee', 'Key Accounts Manager', 'active', '2019-06-10', NULL, NULL),
    ('cobalto-industrial-mx', 'CIS-R017', 'CIS-P017', 'employee', 'EHS Manager', 'active', '2018-11-12', NULL, NULL),
    ('cobalto-industrial-mx', 'CIS-R018', 'CIS-P018', 'employee', 'Guadalajara Service Manager', 'active', '2019-01-07', NULL, NULL),
    ('cobalto-industrial-mx', 'CIS-R019', 'CIS-P019', 'employee', 'Senior Automation Engineer', 'active', '2020-02-17', NULL, NULL),
    ('cobalto-industrial-mx', 'CIS-R020', 'CIS-P020', 'employee', 'Field Service Engineer', 'active', '2021-05-24', NULL, NULL),
    ('cobalto-industrial-mx', 'CIS-R021', 'CIS-P021', 'contractor', 'Lean Manufacturing Consultant', 'active', '2025-02-03', NULL, 'Temporary operational-excellence engagement.'),
    ('cobalto-industrial-mx', 'CIS-R022', 'CIS-P022', 'supplier_contact', 'Strategic Metals Account Executive', 'active', '2021-04-12', NULL, NULL),
    ('cobalto-industrial-mx', 'CIS-R023', 'CIS-P023', 'partner_contact', 'Industrial Automation Alliance Manager', 'active', '2023-08-14', NULL, NULL),
    -- BluePeak Advisory
    ('bluepeak-advisory-us', 'BPA-R001', 'BPA-P001', 'owner', 'Managing Partner', 'active', '2012-06-04', NULL, 'Founding equity partner.'),
    ('bluepeak-advisory-us', 'BPA-R002', 'BPA-P001', 'employee', 'Chief Executive Officer', 'active', '2012-06-04', NULL, NULL),
    ('bluepeak-advisory-us', 'BPA-R003', 'BPA-P002', 'employee', 'Chief Financial Officer', 'active', '2015-01-12', NULL, NULL),
    ('bluepeak-advisory-us', 'BPA-R004', 'BPA-P003', 'employee', 'People and Culture Director', 'active', '2016-04-18', NULL, NULL),
    ('bluepeak-advisory-us', 'BPA-R005', 'BPA-P004', 'employee', 'Chief Operating Officer', 'active', '2014-09-08', NULL, NULL),
    ('bluepeak-advisory-us', 'BPA-R006', 'BPA-P005', 'employee', 'Head of Advisory Practices', 'active', '2013-03-11', NULL, NULL),
    ('bluepeak-advisory-us', 'BPA-R007', 'BPA-P006', 'employee', 'Business Development Director', 'active', '2017-02-06', NULL, NULL),
    ('bluepeak-advisory-us', 'BPA-R008', 'BPA-P007', 'employee', 'Knowledge and Research Director', 'active', '2018-05-21', NULL, NULL),
    ('bluepeak-advisory-us', 'BPA-R009', 'BPA-P008', 'employee', 'Technology Enablement Director', 'active', '2019-08-12', NULL, NULL),
    ('bluepeak-advisory-us', 'BPA-R010', 'BPA-P009', 'employee', 'Accounting Manager', 'active', '2018-01-08', NULL, NULL),
    ('bluepeak-advisory-us', 'BPA-R011', 'BPA-P010', 'employee', 'Talent Development Manager', 'active', '2020-06-01', NULL, NULL),
    ('bluepeak-advisory-us', 'BPA-R012', 'BPA-P011', 'employee', 'Engagement Management Office Lead', 'active', '2019-11-04', NULL, NULL),
    ('bluepeak-advisory-us', 'BPA-R013', 'BPA-P012', 'employee', 'Strategy and Transformation Practice Lead', 'active', '2017-09-18', NULL, NULL),
    ('bluepeak-advisory-us', 'BPA-R014', 'BPA-P013', 'employee', 'Risk and Compliance Practice Lead', 'active', '2018-10-15', NULL, NULL),
    ('bluepeak-advisory-us', 'BPA-R015', 'BPA-P014', 'employee', 'Data and Analytics Practice Lead', 'active', '2019-03-04', NULL, NULL),
    ('bluepeak-advisory-us', 'BPA-R016', 'BPA-P015', 'employee', 'Market Intelligence Manager', 'active', '2021-01-11', NULL, NULL),
    ('bluepeak-advisory-us', 'BPA-R017', 'BPA-P016', 'employee', 'Automation and AI Enablement Manager', 'active', '2021-07-12', NULL, NULL),
    ('bluepeak-advisory-us', 'BPA-R018', 'BPA-P017', 'employee', 'Senior Strategy Consultant', 'active', '2022-02-07', NULL, NULL),
    ('bluepeak-advisory-us', 'BPA-R019', 'BPA-P018', 'employee', 'Data Analytics Consultant', 'active', '2023-05-15', NULL, NULL),
    ('bluepeak-advisory-us', 'BPA-R020', 'BPA-P019', 'advisor', 'Independent Board Advisor', 'active', '2024-01-01', NULL, 'External advisor on regulated-industry growth.'),
    -- LumenForge Technologies
    ('lumenforge-technologies-us', 'LFT-R001', 'LFT-P001', 'owner', 'Founder', 'active', '2016-01-18', NULL, 'Founder and controlling shareholder.'),
    ('lumenforge-technologies-us', 'LFT-R002', 'LFT-P001', 'employee', 'Chief Executive Officer', 'active', '2016-01-18', NULL, NULL),
    ('lumenforge-technologies-us', 'LFT-R003', 'LFT-P002', 'employee', 'Chief Financial Officer', 'active', '2018-07-09', NULL, NULL),
    ('lumenforge-technologies-us', 'LFT-R004', 'LFT-P003', 'employee', 'People and Culture Director', 'active', '2019-04-22', NULL, NULL),
    ('lumenforge-technologies-us', 'LFT-R005', 'LFT-P004', 'employee', 'Chief Technology Officer', 'active', '2016-03-14', NULL, NULL),
    ('lumenforge-technologies-us', 'LFT-R006', 'LFT-P005', 'employee', 'Vice President of Product', 'active', '2018-10-01', NULL, NULL),
    ('lumenforge-technologies-us', 'LFT-R007', 'LFT-P006', 'employee', 'Chief Operating Officer', 'active', '2019-01-14', NULL, NULL),
    ('lumenforge-technologies-us', 'LFT-R008', 'LFT-P007', 'employee', 'Vice President of Sales', 'active', '2020-02-03', NULL, NULL),
    ('lumenforge-technologies-us', 'LFT-R009', 'LFT-P008', 'employee', 'Vice President of Customer Success', 'active', '2020-06-08', NULL, NULL),
    ('lumenforge-technologies-us', 'LFT-R010', 'LFT-P009', 'employee', 'Security and Compliance Director', 'active', '2021-03-01', NULL, NULL),
    ('lumenforge-technologies-us', 'LFT-R011', 'LFT-P010', 'employee', 'Accounting Manager', 'active', '2020-08-17', NULL, NULL),
    ('lumenforge-technologies-us', 'LFT-R012', 'LFT-P011', 'employee', 'Talent and Organizational Development Manager', 'active', '2021-01-11', NULL, NULL),
    ('lumenforge-technologies-us', 'LFT-R013', 'LFT-P012', 'employee', 'Platform Engineering Director', 'active', '2017-05-15', NULL, NULL),
    ('lumenforge-technologies-us', 'LFT-R014', 'LFT-P013', 'employee', 'Applied AI Director', 'active', '2019-09-09', NULL, NULL),
    ('lumenforge-technologies-us', 'LFT-R015', 'LFT-P014', 'employee', 'Hardware Systems Director', 'active', '2018-04-02', NULL, NULL),
    ('lumenforge-technologies-us', 'LFT-R016', 'LFT-P015', 'employee', 'Quality Engineering Manager', 'active', '2020-11-02', NULL, NULL),
    ('lumenforge-technologies-us', 'LFT-R017', 'LFT-P016', 'employee', 'Core Products Director', 'active', '2019-06-17', NULL, NULL),
    ('lumenforge-technologies-us', 'LFT-R018', 'LFT-P017', 'employee', 'Customer Support Director', 'active', '2021-05-10', NULL, NULL),
    ('lumenforge-technologies-us', 'LFT-R019', 'LFT-P018', 'employee', 'GRC Manager', 'active', '2022-01-24', NULL, NULL),
    ('lumenforge-technologies-us', 'LFT-R020', 'LFT-P019', 'employee', 'Senior Machine Learning Engineer', 'active', '2022-08-08', NULL, NULL),
    ('lumenforge-technologies-us', 'LFT-R021', 'LFT-P020', 'employee', 'Enterprise Customer Success Manager', 'active', '2022-10-03', NULL, NULL),
    ('lumenforge-technologies-us', 'LFT-R022', 'LFT-P021', 'contractor', 'Penetration Testing Lead', 'active', '2025-03-03', NULL, 'Specialist retained for annual security testing.'),
    -- Cedarline Logistics
    ('cedarline-logistics-ca', 'CLL-R001', 'CLL-P001', 'employee', 'Chief Executive Officer', 'active', '2011-04-04', NULL, NULL),
    ('cedarline-logistics-ca', 'CLL-R002', 'CLL-P002', 'employee', 'Chief Financial Officer', 'active', '2014-01-13', NULL, NULL),
    ('cedarline-logistics-ca', 'CLL-R003', 'CLL-P003', 'employee', 'People and Culture Director', 'active', '2015-06-08', NULL, NULL),
    ('cedarline-logistics-ca', 'CLL-R004', 'CLL-P004', 'employee', 'Vice President of Network Operations', 'active', '2012-09-10', NULL, NULL),
    ('cedarline-logistics-ca', 'CLL-R005', 'CLL-P005', 'employee', 'Warehousing Director', 'active', '2016-02-01', NULL, NULL),
    ('cedarline-logistics-ca', 'CLL-R006', 'CLL-P006', 'employee', 'Transportation Director', 'active', '2015-03-16', NULL, NULL),
    ('cedarline-logistics-ca', 'CLL-R007', 'CLL-P007', 'employee', 'Commercial Director', 'active', '2017-07-10', NULL, NULL),
    ('cedarline-logistics-ca', 'CLL-R008', 'CLL-P008', 'employee', 'Technology Director', 'active', '2018-11-05', NULL, NULL),
    ('cedarline-logistics-ca', 'CLL-R009', 'CLL-P009', 'employee', 'Safety and Compliance Director', 'active', '2016-09-12', NULL, NULL),
    ('cedarline-logistics-ca', 'CLL-R010', 'CLL-P010', 'employee', 'Accounting Manager', 'active', '2018-01-22', NULL, NULL),
    ('cedarline-logistics-ca', 'CLL-R011', 'CLL-P011', 'employee', 'Talent and Training Manager', 'active', '2019-04-15', NULL, NULL),
    ('cedarline-logistics-ca', 'CLL-R012', 'CLL-P012', 'employee', 'Eastern Network Operations Manager', 'active', '2017-10-02', NULL, NULL),
    ('cedarline-logistics-ca', 'CLL-R013', 'CLL-P013', 'employee', 'Western Network Operations Manager', 'active', '2018-06-11', NULL, NULL),
    ('cedarline-logistics-ca', 'CLL-R014', 'CLL-P014', 'employee', 'Mississauga Warehouse Manager', 'active', '2019-01-07', NULL, NULL),
    ('cedarline-logistics-ca', 'CLL-R015', 'CLL-P015', 'employee', 'Calgary Warehouse Manager', 'active', '2020-03-09', NULL, NULL),
    ('cedarline-logistics-ca', 'CLL-R016', 'CLL-P016', 'employee', 'Dispatch and Fleet Manager', 'active', '2019-08-19', NULL, NULL),
    ('cedarline-logistics-ca', 'CLL-R017', 'CLL-P017', 'employee', 'Data and Network Optimization Manager', 'active', '2021-02-08', NULL, NULL),
    ('cedarline-logistics-ca', 'CLL-R018', 'CLL-P018', 'employee', 'Regulatory Compliance Manager', 'active', '2020-05-04', NULL, NULL),
    ('cedarline-logistics-ca', 'CLL-R019', 'CLL-P019', 'contractor', 'Route Optimization Specialist', 'active', '2025-01-13', NULL, NULL),
    ('cedarline-logistics-ca', 'CLL-R020', 'CLL-P020', 'customer_contact', 'National Retail Account Contact', 'active', '2023-09-18', NULL, NULL),
    ('cedarline-logistics-ca', 'CLL-R021', 'CLL-P021', 'supplier_contact', 'Fleet Maintenance Account Manager', 'active', '2022-05-09', NULL, NULL),
    -- Harvest Circle Foods
    ('harvest-circle-foods-ca', 'HCF-R001', 'HCF-P001', 'owner', 'Former Chair and Majority Owner', 'ended', '2003-05-12', '2024-09-30', 'Ownership position ended when operations were sold.'),
    ('harvest-circle-foods-ca', 'HCF-R002', 'HCF-P001', 'employee', 'Chief Executive Officer', 'ended', '2003-05-12', '2024-09-30', NULL),
    ('harvest-circle-foods-ca', 'HCF-R003', 'HCF-P002', 'employee', 'Chief Financial Officer', 'ended', '2008-01-07', '2024-09-30', NULL),
    ('harvest-circle-foods-ca', 'HCF-R004', 'HCF-P003', 'employee', 'People and Culture Manager', 'ended', '2012-06-04', '2024-09-30', NULL),
    ('harvest-circle-foods-ca', 'HCF-R005', 'HCF-P004', 'employee', 'Operations Director', 'ended', '2009-03-16', '2024-09-30', NULL),
    ('harvest-circle-foods-ca', 'HCF-R006', 'HCF-P005', 'employee', 'Sales Director', 'ended', '2011-08-08', '2024-09-30', NULL),
    ('harvest-circle-foods-ca', 'HCF-R007', 'HCF-P006', 'employee', 'Quality and Food Safety Manager', 'ended', '2014-02-10', '2024-09-30', NULL),
    ('harvest-circle-foods-ca', 'HCF-R008', 'HCF-P007', 'employee', 'Supply Chain Manager', 'ended', '2013-09-09', '2024-09-30', NULL),
    ('harvest-circle-foods-ca', 'HCF-R009', 'HCF-P008', 'employee', 'Accounting Manager', 'ended', '2015-01-12', '2024-09-30', NULL),
    ('harvest-circle-foods-ca', 'HCF-R010', 'HCF-P009', 'employee', 'Richmond Cold-Storage Manager', 'ended', '2016-04-04', '2023-12-31', NULL),
    ('harvest-circle-foods-ca', 'HCF-R011', 'HCF-P012', 'supplier_contact', 'Former Packaging Supplier Contact', 'ended', '2018-01-01', '2024-09-30', NULL);

UPDATE relationships.person_company_roles AS roles
SET
    role_title = fixture.role_title,
    status = fixture.role_status,
    valid_to = fixture.valid_to,
    notes = fixture.notes,
    updated_at = NOW()
FROM fixture_person_company_roles AS fixture
JOIN core.companies AS companies
    ON companies.company_slug = fixture.company_slug
JOIN people.persons AS persons
    ON persons.company_id = companies.company_id
    AND persons.external_reference = fixture.person_external_reference
WHERE roles.company_id = companies.company_id
  AND roles.person_id = persons.person_id
  AND roles.role_type = fixture.role_type
  AND roles.valid_from = fixture.valid_from;

INSERT INTO relationships.person_company_roles (
    company_id,
    person_id,
    role_type,
    role_title,
    status,
    valid_from,
    valid_to,
    notes
)
SELECT
    companies.company_id,
    persons.person_id,
    fixture.role_type,
    fixture.role_title,
    fixture.role_status,
    fixture.valid_from,
    fixture.valid_to,
    fixture.notes
FROM fixture_person_company_roles AS fixture
JOIN core.companies AS companies
    ON companies.company_slug = fixture.company_slug
JOIN people.persons AS persons
    ON persons.company_id = companies.company_id
    AND persons.external_reference = fixture.person_external_reference
WHERE NOT EXISTS (
    SELECT 1
    FROM relationships.person_company_roles AS roles
    WHERE roles.company_id = companies.company_id
      AND roles.person_id = persons.person_id
      AND roles.role_type = fixture.role_type
      AND roles.valid_from = fixture.valid_from
);

-- Resolve stable fixture role keys to generated role identities.
CREATE TEMP TABLE fixture_resolved_roles (
    company_slug TEXT NOT NULL,
    role_key TEXT NOT NULL,
    company_id BIGINT NOT NULL,
    person_company_role_id BIGINT NOT NULL,
    PRIMARY KEY (company_slug, role_key)
) ON COMMIT DROP;

INSERT INTO fixture_resolved_roles (
    company_slug,
    role_key,
    company_id,
    person_company_role_id
)
SELECT
    fixture.company_slug,
    fixture.role_key,
    companies.company_id,
    resolved_roles.person_company_role_id
FROM fixture_person_company_roles AS fixture
JOIN core.companies AS companies
    ON companies.company_slug = fixture.company_slug
JOIN people.persons AS persons
    ON persons.company_id = companies.company_id
    AND persons.external_reference = fixture.person_external_reference
JOIN LATERAL (
    SELECT roles.person_company_role_id
    FROM relationships.person_company_roles AS roles
    WHERE roles.company_id = companies.company_id
      AND roles.person_id = persons.person_id
      AND roles.role_type = fixture.role_type
      AND roles.valid_from = fixture.valid_from
    ORDER BY roles.person_company_role_id
    LIMIT 1
) AS resolved_roles
    ON TRUE;

-- ============================================================
-- Person-department assignments
-- ============================================================

CREATE TEMP TABLE fixture_person_department_assignments (
    company_slug TEXT NOT NULL,
    assignment_key TEXT NOT NULL,
    role_key TEXT NOT NULL,
    department_code TEXT NOT NULL,
    assignment_type TEXT NOT NULL,
    position_title TEXT,
    valid_from DATE NOT NULL,
    valid_to DATE,
    notes TEXT
) ON COMMIT DROP;

INSERT INTO fixture_person_department_assignments (
    company_slug,
    assignment_key,
    role_key,
    department_code,
    assignment_type,
    position_title,
    valid_from,
    valid_to,
    notes
)
VALUES
    -- Solara Retail Mexico
    ('solara-retail-mx', 'SRM-A001', 'SRM-R001', 'EXE', 'primary', 'Chief Executive Officer', '2014-03-17', NULL, NULL),
    ('solara-retail-mx', 'SRM-A002', 'SRM-R002', 'FIN', 'primary', 'Chief Financial Officer', '2016-01-11', NULL, NULL),
    ('solara-retail-mx', 'SRM-A003', 'SRM-R003', 'PPL', 'primary', 'People and Culture Director', '2017-05-08', NULL, NULL),
    ('solara-retail-mx', 'SRM-A004', 'SRM-R004', 'TEC', 'primary', 'Chief Technology Officer', '2018-02-19', NULL, NULL),
    ('solara-retail-mx', 'SRM-A005', 'SRM-R005', 'MKT', 'primary', 'Marketing and Customer Insights Director', '2019-04-01', NULL, NULL),
    ('solara-retail-mx', 'SRM-A006', 'SRM-R006', 'RET', 'primary', 'Retail Operations Director', '2015-07-13', NULL, NULL),
    ('solara-retail-mx', 'SRM-A007', 'SRM-R007', 'SCM', 'primary', 'Supply Chain Director', '2018-09-03', NULL, NULL),
    ('solara-retail-mx', 'SRM-A008', 'SRM-R008', 'ECOM', 'primary', 'Digital Commerce Director', '2020-05-01', NULL, NULL),
    ('solara-retail-mx', 'SRM-A009', 'SRM-R009', 'FIN-ACC', 'primary', 'Corporate Controller', '2018-06-18', NULL, NULL),
    ('solara-retail-mx', 'SRM-A010', 'SRM-R010', 'FIN-FPA', 'primary', 'FP&A Manager', '2021-01-18', NULL, NULL),
    ('solara-retail-mx', 'SRM-A011', 'SRM-R011', 'PPL-TAL', 'primary', 'Talent and Development Manager', '2020-08-10', NULL, NULL),
    ('solara-retail-mx', 'SRM-A012', 'SRM-R012', 'TEC-DAT', 'primary', 'Data and Analytics Manager', '2021-03-15', NULL, NULL),
    ('solara-retail-mx', 'SRM-A013', 'SRM-R013', 'MKT-CRM', 'primary', 'CRM and Loyalty Manager', '2021-11-08', NULL, NULL),
    ('solara-retail-mx', 'SRM-A014', 'SRM-R014', 'RET-POL', 'primary', 'Polanco Store Manager', '2019-02-04', NULL, NULL),
    ('solara-retail-mx', 'SRM-A015', 'SRM-R015', 'RET-SUR', 'primary', 'South Mexico City Store Manager', '2020-01-13', NULL, NULL),
    ('solara-retail-mx', 'SRM-A016', 'SRM-R016', 'RET-AND', 'primary', 'Guadalajara Store Manager', '2021-03-29', NULL, NULL),
    ('solara-retail-mx', 'SRM-A017', 'SRM-R017', 'SCM-TOL', 'primary', 'Distribution Center Manager', '2019-05-20', NULL, NULL),
    ('solara-retail-mx', 'SRM-A018', 'SRM-R018', 'ECOM-OPS', 'primary', 'E-commerce Operations Manager', '2020-06-15', NULL, NULL),
    ('solara-retail-mx', 'SRM-A019', 'SRM-R019', 'TEC-DAT', 'primary', 'Senior Data Analyst', '2022-07-04', NULL, NULL),
    ('solara-retail-mx', 'SRM-A020', 'SRM-R020', 'ECOM-OPS', 'primary', 'E-commerce Operations Specialist', '2023-02-13', NULL, NULL),
    ('solara-retail-mx', 'SRM-A021', 'SRM-R021', 'TEC', 'temporary', 'Cybersecurity Advisor', '2025-01-06', '2026-12-31', 'Advisory engagement sponsored by the CTO.'),
    ('solara-retail-mx', 'SRM-A022', 'SRM-R012', 'FIN-FPA', 'secondary', 'Analytics Business Partner', '2024-01-01', NULL, 'Supports financial planning with shared analytics capacity.'),
    -- Cobalto Industrial Systems
    ('cobalto-industrial-mx', 'CIS-A001', 'CIS-R001', 'EXE', 'primary', 'Chief Executive Officer', '2008-08-11', NULL, NULL),
    ('cobalto-industrial-mx', 'CIS-A002', 'CIS-R002', 'FIN', 'primary', 'Chief Financial Officer', '2012-02-06', NULL, NULL),
    ('cobalto-industrial-mx', 'CIS-A003', 'CIS-R003', 'PPL', 'primary', 'People and Culture Director', '2014-06-02', NULL, NULL),
    ('cobalto-industrial-mx', 'CIS-A004', 'CIS-R004', 'ENG', 'primary', 'Vice President of Engineering', '2011-09-19', NULL, NULL),
    ('cobalto-industrial-mx', 'CIS-A005', 'CIS-R005', 'MFG', 'primary', 'Vice President of Manufacturing', '2010-02-22', NULL, NULL),
    ('cobalto-industrial-mx', 'CIS-A006', 'CIS-R006', 'SCM', 'primary', 'Supply Chain Director', '2015-04-13', NULL, NULL),
    ('cobalto-industrial-mx', 'CIS-A007', 'CIS-R007', 'SAL', 'primary', 'Sales Director', '2013-08-05', NULL, NULL),
    ('cobalto-industrial-mx', 'CIS-A008', 'CIS-R008', 'QMS', 'primary', 'Quality and Compliance Director', '2016-01-11', NULL, NULL),
    ('cobalto-industrial-mx', 'CIS-A009', 'CIS-R009', 'SVC', 'primary', 'Field Service Director', '2018-09-17', NULL, NULL),
    ('cobalto-industrial-mx', 'CIS-A010', 'CIS-R010', 'FIN-ACC', 'primary', 'Accounting Manager', '2017-03-20', NULL, NULL),
    ('cobalto-industrial-mx', 'CIS-A011', 'CIS-R011', 'ENG-PRO', 'primary', 'Product Engineering Manager', '2015-10-12', NULL, NULL),
    ('cobalto-industrial-mx', 'CIS-A012', 'CIS-R012', 'ENG-AUT', 'primary', 'Automation Engineering Manager', '2018-05-14', NULL, NULL),
    ('cobalto-industrial-mx', 'CIS-A013', 'CIS-R013', 'MFG-APO', 'primary', 'Apodaca Plant Manager', '2016-07-04', NULL, NULL),
    ('cobalto-industrial-mx', 'CIS-A014', 'CIS-R014', 'MFG-SLP', 'primary', 'San Luis Potosi Plant Manager', '2021-10-04', NULL, NULL),
    ('cobalto-industrial-mx', 'CIS-A015', 'CIS-R015', 'SCM-QRO', 'primary', 'Warehouse Operations Manager', '2017-01-09', NULL, NULL),
    ('cobalto-industrial-mx', 'CIS-A016', 'CIS-R016', 'SAL-KEY', 'primary', 'Key Accounts Manager', '2019-06-10', NULL, NULL),
    ('cobalto-industrial-mx', 'CIS-A017', 'CIS-R017', 'QMS-EHS', 'primary', 'EHS Manager', '2018-11-12', NULL, NULL),
    ('cobalto-industrial-mx', 'CIS-A018', 'CIS-R018', 'SVC-GDL', 'primary', 'Guadalajara Service Manager', '2019-01-07', NULL, NULL),
    ('cobalto-industrial-mx', 'CIS-A019', 'CIS-R019', 'ENG-AUT', 'primary', 'Senior Automation Engineer', '2020-02-17', NULL, NULL),
    ('cobalto-industrial-mx', 'CIS-A020', 'CIS-R020', 'SVC-GDL', 'primary', 'Field Service Engineer', '2021-05-24', NULL, NULL),
    ('cobalto-industrial-mx', 'CIS-A021', 'CIS-R021', 'MFG', 'temporary', 'Lean Manufacturing Consultant', '2025-02-03', '2026-08-31', 'Cross-plant process-improvement engagement.'),
    ('cobalto-industrial-mx', 'CIS-A022', 'CIS-R017', 'MFG-APO', 'secondary', 'Plant EHS Business Partner', '2020-01-01', NULL, 'Secondary assignment supporting plant leadership.'),
    -- BluePeak Advisory
    ('bluepeak-advisory-us', 'BPA-A001', 'BPA-R002', 'EXE', 'primary', 'Chief Executive Officer', '2012-06-04', NULL, NULL),
    ('bluepeak-advisory-us', 'BPA-A002', 'BPA-R003', 'FIN', 'primary', 'Chief Financial Officer', '2015-01-12', NULL, NULL),
    ('bluepeak-advisory-us', 'BPA-A003', 'BPA-R004', 'PPL', 'primary', 'People and Culture Director', '2016-04-18', NULL, NULL),
    ('bluepeak-advisory-us', 'BPA-A004', 'BPA-R005', 'OPS', 'primary', 'Chief Operating Officer', '2014-09-08', NULL, NULL),
    ('bluepeak-advisory-us', 'BPA-A005', 'BPA-R006', 'ADV', 'primary', 'Head of Advisory Practices', '2013-03-11', NULL, NULL),
    ('bluepeak-advisory-us', 'BPA-A006', 'BPA-R007', 'SAL', 'primary', 'Business Development Director', '2017-02-06', NULL, NULL),
    ('bluepeak-advisory-us', 'BPA-A007', 'BPA-R008', 'KNO', 'primary', 'Knowledge and Research Director', '2018-05-21', NULL, NULL),
    ('bluepeak-advisory-us', 'BPA-A008', 'BPA-R009', 'TEC', 'primary', 'Technology Enablement Director', '2019-08-12', NULL, NULL),
    ('bluepeak-advisory-us', 'BPA-A009', 'BPA-R010', 'FIN-ACC', 'primary', 'Accounting Manager', '2018-01-08', NULL, NULL),
    ('bluepeak-advisory-us', 'BPA-A010', 'BPA-R011', 'PPL-TAL', 'primary', 'Talent Development Manager', '2020-06-01', NULL, NULL),
    ('bluepeak-advisory-us', 'BPA-A011', 'BPA-R012', 'OPS-PMO', 'primary', 'Engagement Management Office Lead', '2019-11-04', NULL, NULL),
    ('bluepeak-advisory-us', 'BPA-A012', 'BPA-R013', 'ADV-STR', 'primary', 'Strategy and Transformation Practice Lead', '2017-09-18', NULL, NULL),
    ('bluepeak-advisory-us', 'BPA-A013', 'BPA-R014', 'ADV-RSK', 'primary', 'Risk and Compliance Practice Lead', '2018-10-15', NULL, NULL),
    ('bluepeak-advisory-us', 'BPA-A014', 'BPA-R015', 'ADV-DAT', 'primary', 'Data and Analytics Practice Lead', '2019-03-04', NULL, NULL),
    ('bluepeak-advisory-us', 'BPA-A015', 'BPA-R016', 'KNO-INS', 'primary', 'Market Intelligence Manager', '2021-01-11', NULL, NULL),
    ('bluepeak-advisory-us', 'BPA-A016', 'BPA-R017', 'TEC-AUT', 'primary', 'Automation and AI Enablement Manager', '2021-07-12', NULL, NULL),
    ('bluepeak-advisory-us', 'BPA-A017', 'BPA-R018', 'ADV-STR', 'primary', 'Senior Strategy Consultant', '2022-02-07', NULL, NULL),
    ('bluepeak-advisory-us', 'BPA-A018', 'BPA-R019', 'ADV-DAT', 'primary', 'Data Analytics Consultant', '2023-05-15', NULL, NULL),
    ('bluepeak-advisory-us', 'BPA-A019', 'BPA-R017', 'ADV-DAT', 'secondary', 'AI Advisory Liaison', '2023-01-09', NULL, 'Supports analytics engagements with automation expertise.'),
    -- LumenForge Technologies
    ('lumenforge-technologies-us', 'LFT-A001', 'LFT-R002', 'EXE', 'primary', 'Chief Executive Officer', '2016-01-18', NULL, NULL),
    ('lumenforge-technologies-us', 'LFT-A002', 'LFT-R003', 'FIN', 'primary', 'Chief Financial Officer', '2018-07-09', NULL, NULL),
    ('lumenforge-technologies-us', 'LFT-A003', 'LFT-R004', 'PPL', 'primary', 'People and Culture Director', '2019-04-22', NULL, NULL),
    ('lumenforge-technologies-us', 'LFT-A004', 'LFT-R005', 'ENG', 'primary', 'Chief Technology Officer', '2016-03-14', NULL, NULL),
    ('lumenforge-technologies-us', 'LFT-A005', 'LFT-R006', 'PRD', 'primary', 'Vice President of Product', '2018-10-01', NULL, NULL),
    ('lumenforge-technologies-us', 'LFT-A006', 'LFT-R007', 'OPS', 'primary', 'Chief Operating Officer', '2019-01-14', NULL, NULL),
    ('lumenforge-technologies-us', 'LFT-A007', 'LFT-R008', 'SAL', 'primary', 'Vice President of Sales', '2020-02-03', NULL, NULL),
    ('lumenforge-technologies-us', 'LFT-A008', 'LFT-R009', 'CS', 'primary', 'Vice President of Customer Success', '2020-06-08', NULL, NULL),
    ('lumenforge-technologies-us', 'LFT-A009', 'LFT-R010', 'SEC', 'primary', 'Security and Compliance Director', '2021-03-01', NULL, NULL),
    ('lumenforge-technologies-us', 'LFT-A010', 'LFT-R011', 'FIN-ACC', 'primary', 'Accounting Manager', '2020-08-17', NULL, NULL),
    ('lumenforge-technologies-us', 'LFT-A011', 'LFT-R012', 'PPL-TAL', 'primary', 'Talent and Organizational Development Manager', '2021-01-11', NULL, NULL),
    ('lumenforge-technologies-us', 'LFT-A012', 'LFT-R013', 'ENG-PLT', 'primary', 'Platform Engineering Director', '2017-05-15', NULL, NULL),
    ('lumenforge-technologies-us', 'LFT-A013', 'LFT-R014', 'ENG-ML', 'primary', 'Applied AI Director', '2019-09-09', NULL, NULL),
    ('lumenforge-technologies-us', 'LFT-A014', 'LFT-R015', 'ENG-HW', 'primary', 'Hardware Systems Director', '2018-04-02', NULL, NULL),
    ('lumenforge-technologies-us', 'LFT-A015', 'LFT-R016', 'ENG-QA', 'primary', 'Quality Engineering Manager', '2020-11-02', NULL, NULL),
    ('lumenforge-technologies-us', 'LFT-A016', 'LFT-R017', 'PRD-CORE', 'primary', 'Core Products Director', '2019-06-17', NULL, NULL),
    ('lumenforge-technologies-us', 'LFT-A017', 'LFT-R018', 'CS-SUP', 'primary', 'Customer Support Director', '2021-05-10', NULL, NULL),
    ('lumenforge-technologies-us', 'LFT-A018', 'LFT-R019', 'SEC-GRC', 'primary', 'GRC Manager', '2022-01-24', NULL, NULL),
    ('lumenforge-technologies-us', 'LFT-A019', 'LFT-R020', 'ENG-ML', 'primary', 'Senior Machine Learning Engineer', '2022-08-08', NULL, NULL),
    ('lumenforge-technologies-us', 'LFT-A020', 'LFT-R021', 'CS', 'primary', 'Enterprise Customer Success Manager', '2022-10-03', NULL, NULL),
    ('lumenforge-technologies-us', 'LFT-A021', 'LFT-R022', 'SEC', 'temporary', 'Penetration Testing Lead', '2025-03-03', '2026-10-31', 'Annual security assessment and remediation support.'),
    ('lumenforge-technologies-us', 'LFT-A022', 'LFT-R014', 'PRD-CORE', 'secondary', 'AI Product Technical Lead', '2021-06-01', NULL, 'Shared leadership assignment with Product.'),
    -- Cedarline Logistics
    ('cedarline-logistics-ca', 'CLL-A001', 'CLL-R001', 'EXE', 'primary', 'Chief Executive Officer', '2011-04-04', NULL, NULL),
    ('cedarline-logistics-ca', 'CLL-A002', 'CLL-R002', 'FIN', 'primary', 'Chief Financial Officer', '2014-01-13', NULL, NULL),
    ('cedarline-logistics-ca', 'CLL-A003', 'CLL-R003', 'PPL', 'primary', 'People and Culture Director', '2015-06-08', NULL, NULL),
    ('cedarline-logistics-ca', 'CLL-A004', 'CLL-R004', 'OPS', 'primary', 'Vice President of Network Operations', '2012-09-10', NULL, NULL),
    ('cedarline-logistics-ca', 'CLL-A005', 'CLL-R005', 'WHS', 'primary', 'Warehousing Director', '2016-02-01', NULL, NULL),
    ('cedarline-logistics-ca', 'CLL-A006', 'CLL-R006', 'TRN', 'primary', 'Transportation Director', '2015-03-16', NULL, NULL),
    ('cedarline-logistics-ca', 'CLL-A007', 'CLL-R007', 'SAL', 'primary', 'Commercial Director', '2017-07-10', NULL, NULL),
    ('cedarline-logistics-ca', 'CLL-A008', 'CLL-R008', 'TEC', 'primary', 'Technology Director', '2018-11-05', NULL, NULL),
    ('cedarline-logistics-ca', 'CLL-A009', 'CLL-R009', 'SAF', 'primary', 'Safety and Compliance Director', '2016-09-12', NULL, NULL),
    ('cedarline-logistics-ca', 'CLL-A010', 'CLL-R010', 'FIN-ACC', 'primary', 'Accounting Manager', '2018-01-22', NULL, NULL),
    ('cedarline-logistics-ca', 'CLL-A011', 'CLL-R011', 'PPL-TAL', 'primary', 'Talent and Training Manager', '2019-04-15', NULL, NULL),
    ('cedarline-logistics-ca', 'CLL-A012', 'CLL-R012', 'OPS-EAST', 'primary', 'Eastern Network Operations Manager', '2017-10-02', NULL, NULL),
    ('cedarline-logistics-ca', 'CLL-A013', 'CLL-R013', 'OPS-WEST', 'primary', 'Western Network Operations Manager', '2018-06-11', NULL, NULL),
    ('cedarline-logistics-ca', 'CLL-A014', 'CLL-R014', 'WHS-MIS', 'primary', 'Mississauga Warehouse Manager', '2019-01-07', NULL, NULL),
    ('cedarline-logistics-ca', 'CLL-A015', 'CLL-R015', 'WHS-CGY', 'primary', 'Calgary Warehouse Manager', '2020-03-09', NULL, NULL),
    ('cedarline-logistics-ca', 'CLL-A016', 'CLL-R016', 'TRN-DSP', 'primary', 'Dispatch and Fleet Manager', '2019-08-19', NULL, NULL),
    ('cedarline-logistics-ca', 'CLL-A017', 'CLL-R017', 'TEC-DAT', 'primary', 'Data and Network Optimization Manager', '2021-02-08', NULL, NULL),
    ('cedarline-logistics-ca', 'CLL-A018', 'CLL-R018', 'SAF-COM', 'primary', 'Regulatory Compliance Manager', '2020-05-04', NULL, NULL),
    ('cedarline-logistics-ca', 'CLL-A019', 'CLL-R019', 'TEC-DAT', 'temporary', 'Route Optimization Specialist', '2025-01-13', '2026-12-31', 'Optimization project spanning transportation and technology.'),
    ('cedarline-logistics-ca', 'CLL-A020', 'CLL-R017', 'OPS', 'secondary', 'Network Analytics Business Partner', '2022-01-10', NULL, 'Shared analytics support for network operations.'),
    -- Harvest Circle Foods
    ('harvest-circle-foods-ca', 'HCF-A001', 'HCF-R002', 'EXE', 'historical', 'Chief Executive Officer', '2003-05-12', '2024-09-30', NULL),
    ('harvest-circle-foods-ca', 'HCF-A002', 'HCF-R003', 'FIN', 'historical', 'Chief Financial Officer', '2008-01-07', '2024-09-30', NULL),
    ('harvest-circle-foods-ca', 'HCF-A003', 'HCF-R004', 'PPL', 'historical', 'People and Culture Manager', '2012-06-04', '2024-09-30', NULL),
    ('harvest-circle-foods-ca', 'HCF-A004', 'HCF-R005', 'OPS', 'historical', 'Operations Director', '2009-03-16', '2024-09-30', NULL),
    ('harvest-circle-foods-ca', 'HCF-A005', 'HCF-R006', 'SAL', 'historical', 'Sales Director', '2011-08-08', '2024-09-30', NULL),
    ('harvest-circle-foods-ca', 'HCF-A006', 'HCF-R007', 'QUA', 'historical', 'Quality and Food Safety Manager', '2014-02-10', '2024-09-30', NULL),
    ('harvest-circle-foods-ca', 'HCF-A007', 'HCF-R008', 'SCM', 'historical', 'Supply Chain Manager', '2013-09-09', '2024-09-30', NULL),
    ('harvest-circle-foods-ca', 'HCF-A008', 'HCF-R009', 'FIN-ACC', 'historical', 'Accounting Manager', '2015-01-12', '2024-09-30', NULL),
    ('harvest-circle-foods-ca', 'HCF-A009', 'HCF-R010', 'OPS-RIC', 'historical', 'Richmond Cold-Storage Manager', '2016-04-04', '2023-12-31', NULL);

-- Refresh active primary assignments by role. This aligns with
-- the schema rule allowing only one current primary assignment.
UPDATE relationships.person_department_assignments AS assignments
SET
    department_id = departments.department_id,
    position_title = fixture.position_title,
    valid_from = fixture.valid_from,
    valid_to = fixture.valid_to,
    notes = fixture.notes,
    updated_at = NOW()
FROM fixture_person_department_assignments AS fixture
JOIN fixture_resolved_roles AS resolved_roles
    ON resolved_roles.company_slug = fixture.company_slug
    AND resolved_roles.role_key = fixture.role_key
JOIN core.departments AS departments
    ON departments.company_id = resolved_roles.company_id
    AND departments.department_code = fixture.department_code
WHERE fixture.assignment_type = 'primary'
  AND fixture.valid_to IS NULL
  AND assignments.company_id = resolved_roles.company_id
  AND assignments.person_company_role_id = resolved_roles.person_company_role_id
  AND assignments.assignment_type = 'primary'
  AND assignments.valid_to IS NULL;

-- Refresh historical, secondary, and temporary assignments by
-- role + assignment type + start date.
UPDATE relationships.person_department_assignments AS assignments
SET
    department_id = departments.department_id,
    position_title = fixture.position_title,
    valid_to = fixture.valid_to,
    notes = fixture.notes,
    updated_at = NOW()
FROM fixture_person_department_assignments AS fixture
JOIN fixture_resolved_roles AS resolved_roles
    ON resolved_roles.company_slug = fixture.company_slug
    AND resolved_roles.role_key = fixture.role_key
JOIN core.departments AS departments
    ON departments.company_id = resolved_roles.company_id
    AND departments.department_code = fixture.department_code
WHERE NOT (
        fixture.assignment_type = 'primary'
        AND fixture.valid_to IS NULL
    )
  AND assignments.company_id = resolved_roles.company_id
  AND assignments.person_company_role_id = resolved_roles.person_company_role_id
  AND assignments.assignment_type = fixture.assignment_type
  AND assignments.valid_from = fixture.valid_from;

INSERT INTO relationships.person_department_assignments (
    company_id,
    person_company_role_id,
    department_id,
    assignment_type,
    position_title,
    valid_from,
    valid_to,
    notes
)
SELECT
    resolved_roles.company_id,
    resolved_roles.person_company_role_id,
    departments.department_id,
    fixture.assignment_type,
    fixture.position_title,
    fixture.valid_from,
    fixture.valid_to,
    fixture.notes
FROM fixture_person_department_assignments AS fixture
JOIN fixture_resolved_roles AS resolved_roles
    ON resolved_roles.company_slug = fixture.company_slug
    AND resolved_roles.role_key = fixture.role_key
JOIN core.departments AS departments
    ON departments.company_id = resolved_roles.company_id
    AND departments.department_code = fixture.department_code
WHERE NOT EXISTS (
    SELECT 1
    FROM relationships.person_department_assignments AS assignments
    WHERE assignments.company_id = resolved_roles.company_id
      AND assignments.person_company_role_id = resolved_roles.person_company_role_id
      AND (
          (
              fixture.assignment_type = 'primary'
              AND fixture.valid_to IS NULL
              AND assignments.assignment_type = 'primary'
              AND assignments.valid_to IS NULL
          )
          OR
          (
              NOT (
                  fixture.assignment_type = 'primary'
                  AND fixture.valid_to IS NULL
              )
              AND assignments.assignment_type = fixture.assignment_type
              AND assignments.valid_from = fixture.valid_from
          )
      )
);

-- ============================================================
-- Person reporting lines
-- ============================================================

CREATE TEMP TABLE fixture_person_reporting_lines (
    company_slug TEXT NOT NULL,
    reporting_line_key TEXT NOT NULL,
    manager_role_key TEXT NOT NULL,
    report_role_key TEXT NOT NULL,
    reporting_type TEXT NOT NULL,
    valid_from DATE NOT NULL,
    valid_to DATE,
    notes TEXT
) ON COMMIT DROP;

INSERT INTO fixture_person_reporting_lines (
    company_slug,
    reporting_line_key,
    manager_role_key,
    report_role_key,
    reporting_type,
    valid_from,
    valid_to,
    notes
)
VALUES
    -- Solara Retail Mexico
    ('solara-retail-mx', 'SRM-L001', 'SRM-R001', 'SRM-R002', 'direct', '2016-01-11', NULL, NULL),
    ('solara-retail-mx', 'SRM-L002', 'SRM-R001', 'SRM-R003', 'direct', '2017-05-08', NULL, NULL),
    ('solara-retail-mx', 'SRM-L003', 'SRM-R001', 'SRM-R004', 'direct', '2018-02-19', NULL, NULL),
    ('solara-retail-mx', 'SRM-L004', 'SRM-R001', 'SRM-R005', 'direct', '2019-04-01', NULL, NULL),
    ('solara-retail-mx', 'SRM-L005', 'SRM-R001', 'SRM-R006', 'direct', '2015-07-13', NULL, NULL),
    ('solara-retail-mx', 'SRM-L006', 'SRM-R001', 'SRM-R007', 'direct', '2018-09-03', NULL, NULL),
    ('solara-retail-mx', 'SRM-L007', 'SRM-R001', 'SRM-R008', 'direct', '2020-05-01', NULL, NULL),
    ('solara-retail-mx', 'SRM-L008', 'SRM-R002', 'SRM-R009', 'direct', '2018-06-18', NULL, NULL),
    ('solara-retail-mx', 'SRM-L009', 'SRM-R002', 'SRM-R010', 'direct', '2021-01-18', NULL, NULL),
    ('solara-retail-mx', 'SRM-L010', 'SRM-R003', 'SRM-R011', 'direct', '2020-08-10', NULL, NULL),
    ('solara-retail-mx', 'SRM-L011', 'SRM-R004', 'SRM-R012', 'direct', '2021-03-15', NULL, NULL),
    ('solara-retail-mx', 'SRM-L012', 'SRM-R005', 'SRM-R013', 'direct', '2021-11-08', NULL, NULL),
    ('solara-retail-mx', 'SRM-L013', 'SRM-R006', 'SRM-R014', 'direct', '2019-02-04', NULL, NULL),
    ('solara-retail-mx', 'SRM-L014', 'SRM-R006', 'SRM-R015', 'direct', '2020-01-13', NULL, NULL),
    ('solara-retail-mx', 'SRM-L015', 'SRM-R006', 'SRM-R016', 'direct', '2021-03-29', NULL, NULL),
    ('solara-retail-mx', 'SRM-L016', 'SRM-R007', 'SRM-R017', 'direct', '2019-05-20', NULL, NULL),
    ('solara-retail-mx', 'SRM-L017', 'SRM-R008', 'SRM-R018', 'direct', '2020-06-15', NULL, NULL),
    ('solara-retail-mx', 'SRM-L018', 'SRM-R012', 'SRM-R019', 'direct', '2022-07-04', NULL, NULL),
    ('solara-retail-mx', 'SRM-L019', 'SRM-R018', 'SRM-R020', 'direct', '2023-02-13', NULL, NULL),
    ('solara-retail-mx', 'SRM-L020', 'SRM-R002', 'SRM-R012', 'dotted', '2024-01-01', NULL, 'Matrix relationship for enterprise analytics priorities.'),
    ('solara-retail-mx', 'SRM-L021', 'SRM-R004', 'SRM-R021', 'functional', '2025-01-06', NULL, 'CTO owns the contractor''s technical scope.'),
    -- Cobalto Industrial Systems
    ('cobalto-industrial-mx', 'CIS-L001', 'CIS-R001', 'CIS-R002', 'direct', '2012-02-06', NULL, NULL),
    ('cobalto-industrial-mx', 'CIS-L002', 'CIS-R001', 'CIS-R003', 'direct', '2014-06-02', NULL, NULL),
    ('cobalto-industrial-mx', 'CIS-L003', 'CIS-R001', 'CIS-R004', 'direct', '2011-09-19', NULL, NULL),
    ('cobalto-industrial-mx', 'CIS-L004', 'CIS-R001', 'CIS-R005', 'direct', '2010-02-22', NULL, NULL),
    ('cobalto-industrial-mx', 'CIS-L005', 'CIS-R001', 'CIS-R006', 'direct', '2015-04-13', NULL, NULL),
    ('cobalto-industrial-mx', 'CIS-L006', 'CIS-R001', 'CIS-R007', 'direct', '2013-08-05', NULL, NULL),
    ('cobalto-industrial-mx', 'CIS-L007', 'CIS-R001', 'CIS-R008', 'direct', '2016-01-11', NULL, NULL),
    ('cobalto-industrial-mx', 'CIS-L008', 'CIS-R001', 'CIS-R009', 'direct', '2018-09-17', NULL, NULL),
    ('cobalto-industrial-mx', 'CIS-L009', 'CIS-R002', 'CIS-R010', 'direct', '2017-03-20', NULL, NULL),
    ('cobalto-industrial-mx', 'CIS-L010', 'CIS-R004', 'CIS-R011', 'direct', '2015-10-12', NULL, NULL),
    ('cobalto-industrial-mx', 'CIS-L011', 'CIS-R004', 'CIS-R012', 'direct', '2018-05-14', NULL, NULL),
    ('cobalto-industrial-mx', 'CIS-L012', 'CIS-R005', 'CIS-R013', 'direct', '2016-07-04', NULL, NULL),
    ('cobalto-industrial-mx', 'CIS-L013', 'CIS-R005', 'CIS-R014', 'direct', '2021-10-04', NULL, NULL),
    ('cobalto-industrial-mx', 'CIS-L014', 'CIS-R006', 'CIS-R015', 'direct', '2017-01-09', NULL, NULL),
    ('cobalto-industrial-mx', 'CIS-L015', 'CIS-R007', 'CIS-R016', 'direct', '2019-06-10', NULL, NULL),
    ('cobalto-industrial-mx', 'CIS-L016', 'CIS-R008', 'CIS-R017', 'direct', '2018-11-12', NULL, NULL),
    ('cobalto-industrial-mx', 'CIS-L017', 'CIS-R009', 'CIS-R018', 'direct', '2019-01-07', NULL, NULL),
    ('cobalto-industrial-mx', 'CIS-L018', 'CIS-R012', 'CIS-R019', 'direct', '2020-02-17', NULL, NULL),
    ('cobalto-industrial-mx', 'CIS-L019', 'CIS-R018', 'CIS-R020', 'direct', '2021-05-24', NULL, NULL),
    ('cobalto-industrial-mx', 'CIS-L020', 'CIS-R005', 'CIS-R021', 'temporary', '2025-02-03', '2026-08-31', 'Consulting work coordinated by manufacturing leadership.'),
    ('cobalto-industrial-mx', 'CIS-L021', 'CIS-R013', 'CIS-R017', 'dotted', '2020-01-01', NULL, 'Plant manager provides local direction to the EHS manager.'),
    -- BluePeak Advisory
    ('bluepeak-advisory-us', 'BPA-L001', 'BPA-R002', 'BPA-R003', 'direct', '2015-01-12', NULL, NULL),
    ('bluepeak-advisory-us', 'BPA-L002', 'BPA-R002', 'BPA-R004', 'direct', '2016-04-18', NULL, NULL),
    ('bluepeak-advisory-us', 'BPA-L003', 'BPA-R002', 'BPA-R005', 'direct', '2014-09-08', NULL, NULL),
    ('bluepeak-advisory-us', 'BPA-L004', 'BPA-R002', 'BPA-R006', 'direct', '2013-03-11', NULL, NULL),
    ('bluepeak-advisory-us', 'BPA-L005', 'BPA-R002', 'BPA-R007', 'direct', '2017-02-06', NULL, NULL),
    ('bluepeak-advisory-us', 'BPA-L006', 'BPA-R002', 'BPA-R008', 'direct', '2018-05-21', NULL, NULL),
    ('bluepeak-advisory-us', 'BPA-L007', 'BPA-R002', 'BPA-R009', 'direct', '2019-08-12', NULL, NULL),
    ('bluepeak-advisory-us', 'BPA-L008', 'BPA-R003', 'BPA-R010', 'direct', '2018-01-08', NULL, NULL),
    ('bluepeak-advisory-us', 'BPA-L009', 'BPA-R004', 'BPA-R011', 'direct', '2020-06-01', NULL, NULL),
    ('bluepeak-advisory-us', 'BPA-L010', 'BPA-R005', 'BPA-R012', 'direct', '2019-11-04', NULL, NULL),
    ('bluepeak-advisory-us', 'BPA-L011', 'BPA-R006', 'BPA-R013', 'direct', '2017-09-18', NULL, NULL),
    ('bluepeak-advisory-us', 'BPA-L012', 'BPA-R006', 'BPA-R014', 'direct', '2018-10-15', NULL, NULL),
    ('bluepeak-advisory-us', 'BPA-L013', 'BPA-R006', 'BPA-R015', 'direct', '2019-03-04', NULL, NULL),
    ('bluepeak-advisory-us', 'BPA-L014', 'BPA-R008', 'BPA-R016', 'direct', '2021-01-11', NULL, NULL),
    ('bluepeak-advisory-us', 'BPA-L015', 'BPA-R009', 'BPA-R017', 'direct', '2021-07-12', NULL, NULL),
    ('bluepeak-advisory-us', 'BPA-L016', 'BPA-R013', 'BPA-R018', 'direct', '2022-02-07', NULL, NULL),
    ('bluepeak-advisory-us', 'BPA-L017', 'BPA-R015', 'BPA-R019', 'direct', '2023-05-15', NULL, NULL),
    ('bluepeak-advisory-us', 'BPA-L018', 'BPA-R015', 'BPA-R017', 'dotted', '2023-01-09', NULL, 'AI enablement manager supports data-advisory methods and accelerators.'),
    -- LumenForge Technologies
    ('lumenforge-technologies-us', 'LFT-L001', 'LFT-R002', 'LFT-R003', 'direct', '2018-07-09', NULL, NULL),
    ('lumenforge-technologies-us', 'LFT-L002', 'LFT-R002', 'LFT-R004', 'direct', '2019-04-22', NULL, NULL),
    ('lumenforge-technologies-us', 'LFT-L003', 'LFT-R002', 'LFT-R005', 'direct', '2016-03-14', NULL, NULL),
    ('lumenforge-technologies-us', 'LFT-L004', 'LFT-R002', 'LFT-R006', 'direct', '2018-10-01', NULL, NULL),
    ('lumenforge-technologies-us', 'LFT-L005', 'LFT-R002', 'LFT-R007', 'direct', '2019-01-14', NULL, NULL),
    ('lumenforge-technologies-us', 'LFT-L006', 'LFT-R002', 'LFT-R008', 'direct', '2020-02-03', NULL, NULL),
    ('lumenforge-technologies-us', 'LFT-L007', 'LFT-R002', 'LFT-R009', 'direct', '2020-06-08', NULL, NULL),
    ('lumenforge-technologies-us', 'LFT-L008', 'LFT-R002', 'LFT-R010', 'direct', '2021-03-01', NULL, NULL),
    ('lumenforge-technologies-us', 'LFT-L009', 'LFT-R003', 'LFT-R011', 'direct', '2020-08-17', NULL, NULL),
    ('lumenforge-technologies-us', 'LFT-L010', 'LFT-R004', 'LFT-R012', 'direct', '2021-01-11', NULL, NULL),
    ('lumenforge-technologies-us', 'LFT-L011', 'LFT-R005', 'LFT-R013', 'direct', '2017-05-15', NULL, NULL),
    ('lumenforge-technologies-us', 'LFT-L012', 'LFT-R005', 'LFT-R014', 'direct', '2019-09-09', NULL, NULL),
    ('lumenforge-technologies-us', 'LFT-L013', 'LFT-R005', 'LFT-R015', 'direct', '2018-04-02', NULL, NULL),
    ('lumenforge-technologies-us', 'LFT-L014', 'LFT-R005', 'LFT-R016', 'direct', '2020-11-02', NULL, NULL),
    ('lumenforge-technologies-us', 'LFT-L015', 'LFT-R006', 'LFT-R017', 'direct', '2019-06-17', NULL, NULL),
    ('lumenforge-technologies-us', 'LFT-L016', 'LFT-R009', 'LFT-R018', 'direct', '2021-05-10', NULL, NULL),
    ('lumenforge-technologies-us', 'LFT-L017', 'LFT-R010', 'LFT-R019', 'direct', '2022-01-24', NULL, NULL),
    ('lumenforge-technologies-us', 'LFT-L018', 'LFT-R014', 'LFT-R020', 'direct', '2022-08-08', NULL, NULL),
    ('lumenforge-technologies-us', 'LFT-L019', 'LFT-R009', 'LFT-R021', 'direct', '2022-10-03', NULL, NULL),
    ('lumenforge-technologies-us', 'LFT-L020', 'LFT-R010', 'LFT-R022', 'functional', '2025-03-03', NULL, 'Security director owns testing scope and remediation acceptance.'),
    ('lumenforge-technologies-us', 'LFT-L021', 'LFT-R006', 'LFT-R014', 'dotted', '2021-06-01', NULL, 'Applied AI director participates in product planning.'),
    -- Cedarline Logistics
    ('cedarline-logistics-ca', 'CLL-L001', 'CLL-R001', 'CLL-R002', 'direct', '2014-01-13', NULL, NULL),
    ('cedarline-logistics-ca', 'CLL-L002', 'CLL-R001', 'CLL-R003', 'direct', '2015-06-08', NULL, NULL),
    ('cedarline-logistics-ca', 'CLL-L003', 'CLL-R001', 'CLL-R004', 'direct', '2012-09-10', NULL, NULL),
    ('cedarline-logistics-ca', 'CLL-L004', 'CLL-R001', 'CLL-R005', 'direct', '2016-02-01', NULL, NULL),
    ('cedarline-logistics-ca', 'CLL-L005', 'CLL-R001', 'CLL-R006', 'direct', '2015-03-16', NULL, NULL),
    ('cedarline-logistics-ca', 'CLL-L006', 'CLL-R001', 'CLL-R007', 'direct', '2017-07-10', NULL, NULL),
    ('cedarline-logistics-ca', 'CLL-L007', 'CLL-R001', 'CLL-R008', 'direct', '2018-11-05', NULL, NULL),
    ('cedarline-logistics-ca', 'CLL-L008', 'CLL-R001', 'CLL-R009', 'direct', '2016-09-12', NULL, NULL),
    ('cedarline-logistics-ca', 'CLL-L009', 'CLL-R002', 'CLL-R010', 'direct', '2018-01-22', NULL, NULL),
    ('cedarline-logistics-ca', 'CLL-L010', 'CLL-R003', 'CLL-R011', 'direct', '2019-04-15', NULL, NULL),
    ('cedarline-logistics-ca', 'CLL-L011', 'CLL-R004', 'CLL-R012', 'direct', '2017-10-02', NULL, NULL),
    ('cedarline-logistics-ca', 'CLL-L012', 'CLL-R004', 'CLL-R013', 'direct', '2018-06-11', NULL, NULL),
    ('cedarline-logistics-ca', 'CLL-L013', 'CLL-R005', 'CLL-R014', 'direct', '2019-01-07', NULL, NULL),
    ('cedarline-logistics-ca', 'CLL-L014', 'CLL-R005', 'CLL-R015', 'direct', '2020-03-09', NULL, NULL),
    ('cedarline-logistics-ca', 'CLL-L015', 'CLL-R006', 'CLL-R016', 'direct', '2019-08-19', NULL, NULL),
    ('cedarline-logistics-ca', 'CLL-L016', 'CLL-R008', 'CLL-R017', 'direct', '2021-02-08', NULL, NULL),
    ('cedarline-logistics-ca', 'CLL-L017', 'CLL-R009', 'CLL-R018', 'direct', '2020-05-04', NULL, NULL),
    ('cedarline-logistics-ca', 'CLL-L018', 'CLL-R017', 'CLL-R019', 'temporary', '2025-01-13', '2026-12-31', 'Specialist embedded in the optimization team.'),
    ('cedarline-logistics-ca', 'CLL-L019', 'CLL-R004', 'CLL-R017', 'dotted', '2022-01-10', NULL, 'Network operations sets analytics priorities.'),
    -- Harvest Circle Foods
    ('harvest-circle-foods-ca', 'HCF-L001', 'HCF-R002', 'HCF-R003', 'direct', '2008-01-07', '2024-09-30', NULL),
    ('harvest-circle-foods-ca', 'HCF-L002', 'HCF-R002', 'HCF-R004', 'direct', '2012-06-04', '2024-09-30', NULL),
    ('harvest-circle-foods-ca', 'HCF-L003', 'HCF-R002', 'HCF-R005', 'direct', '2009-03-16', '2024-09-30', NULL),
    ('harvest-circle-foods-ca', 'HCF-L004', 'HCF-R002', 'HCF-R006', 'direct', '2011-08-08', '2024-09-30', NULL),
    ('harvest-circle-foods-ca', 'HCF-L005', 'HCF-R002', 'HCF-R007', 'direct', '2014-02-10', '2024-09-30', NULL),
    ('harvest-circle-foods-ca', 'HCF-L006', 'HCF-R002', 'HCF-R008', 'direct', '2013-09-09', '2024-09-30', NULL),
    ('harvest-circle-foods-ca', 'HCF-L007', 'HCF-R003', 'HCF-R009', 'direct', '2015-01-12', '2024-09-30', NULL),
    ('harvest-circle-foods-ca', 'HCF-L008', 'HCF-R005', 'HCF-R010', 'direct', '2016-04-04', '2023-12-31', NULL);

-- Refresh current direct reporting lines by report role. This
-- aligns with the schema rule allowing one active direct manager.
UPDATE relationships.person_reporting_lines AS reporting_lines
SET
    manager_role_id = manager_roles.person_company_role_id,
    valid_from = fixture.valid_from,
    valid_to = fixture.valid_to,
    notes = fixture.notes,
    updated_at = NOW()
FROM fixture_person_reporting_lines AS fixture
JOIN fixture_resolved_roles AS manager_roles
    ON manager_roles.company_slug = fixture.company_slug
    AND manager_roles.role_key = fixture.manager_role_key
JOIN fixture_resolved_roles AS report_roles
    ON report_roles.company_slug = fixture.company_slug
    AND report_roles.role_key = fixture.report_role_key
WHERE fixture.reporting_type = 'direct'
  AND fixture.valid_to IS NULL
  AND reporting_lines.company_id = report_roles.company_id
  AND reporting_lines.report_role_id = report_roles.person_company_role_id
  AND reporting_lines.reporting_type = 'direct'
  AND reporting_lines.valid_to IS NULL;

-- Refresh historical and matrix reporting lines by their role
-- pair, relationship type, and start date.
UPDATE relationships.person_reporting_lines AS reporting_lines
SET
    valid_to = fixture.valid_to,
    notes = fixture.notes,
    updated_at = NOW()
FROM fixture_person_reporting_lines AS fixture
JOIN fixture_resolved_roles AS manager_roles
    ON manager_roles.company_slug = fixture.company_slug
    AND manager_roles.role_key = fixture.manager_role_key
JOIN fixture_resolved_roles AS report_roles
    ON report_roles.company_slug = fixture.company_slug
    AND report_roles.role_key = fixture.report_role_key
WHERE NOT (
        fixture.reporting_type = 'direct'
        AND fixture.valid_to IS NULL
    )
  AND reporting_lines.company_id = report_roles.company_id
  AND reporting_lines.manager_role_id = manager_roles.person_company_role_id
  AND reporting_lines.report_role_id = report_roles.person_company_role_id
  AND reporting_lines.reporting_type = fixture.reporting_type
  AND reporting_lines.valid_from = fixture.valid_from;

INSERT INTO relationships.person_reporting_lines (
    company_id,
    manager_role_id,
    report_role_id,
    reporting_type,
    valid_from,
    valid_to,
    notes
)
SELECT
    report_roles.company_id,
    manager_roles.person_company_role_id,
    report_roles.person_company_role_id,
    fixture.reporting_type,
    fixture.valid_from,
    fixture.valid_to,
    fixture.notes
FROM fixture_person_reporting_lines AS fixture
JOIN fixture_resolved_roles AS manager_roles
    ON manager_roles.company_slug = fixture.company_slug
    AND manager_roles.role_key = fixture.manager_role_key
JOIN fixture_resolved_roles AS report_roles
    ON report_roles.company_slug = fixture.company_slug
    AND report_roles.role_key = fixture.report_role_key
WHERE NOT EXISTS (
    SELECT 1
    FROM relationships.person_reporting_lines AS reporting_lines
    WHERE reporting_lines.company_id = report_roles.company_id
      AND (
          (
              fixture.reporting_type = 'direct'
              AND fixture.valid_to IS NULL
              AND reporting_lines.report_role_id = report_roles.person_company_role_id
              AND reporting_lines.reporting_type = 'direct'
              AND reporting_lines.valid_to IS NULL
          )
          OR
          (
              NOT (
                  fixture.reporting_type = 'direct'
                  AND fixture.valid_to IS NULL
              )
              AND reporting_lines.manager_role_id = manager_roles.person_company_role_id
              AND reporting_lines.report_role_id = report_roles.person_company_role_id
              AND reporting_lines.reporting_type = fixture.reporting_type
              AND reporting_lines.valid_from = fixture.valid_from
          )
      )
);

-- ============================================================
-- Person-person relationships
-- ============================================================

CREATE TEMP TABLE fixture_person_relationships (
    company_slug TEXT NOT NULL,
    relationship_key TEXT NOT NULL,
    source_person_external_reference TEXT NOT NULL,
    target_person_external_reference TEXT NOT NULL,
    relationship_type TEXT NOT NULL,
    valid_from DATE NOT NULL,
    valid_to DATE,
    notes TEXT
) ON COMMIT DROP;

INSERT INTO fixture_person_relationships (
    company_slug,
    relationship_key,
    source_person_external_reference,
    target_person_external_reference,
    relationship_type,
    valid_from,
    valid_to,
    notes
)
VALUES
    -- Solara Retail Mexico
    ('solara-retail-mx', 'SRM-PR001', 'SRM-P001', 'SRM-P024', 'emergency_contact', '2014-03-17', NULL, 'Primary emergency contact.'),
    ('solara-retail-mx', 'SRM-PR002', 'SRM-P002', 'SRM-P025', 'emergency_contact', '2016-01-11', NULL, 'Primary emergency contact.'),
    ('solara-retail-mx', 'SRM-PR003', 'SRM-P019', 'SRM-P026', 'emergency_contact', '2022-07-04', NULL, NULL),
    ('solara-retail-mx', 'SRM-PR004', 'SRM-P012', 'SRM-P019', 'mentor', '2022-07-04', NULL, 'Formal analytics mentorship.'),
    ('solara-retail-mx', 'SRM-PR005', 'SRM-P023', 'SRM-P007', 'representative', '2022-09-12', NULL, 'Supplier representative assigned to the supply-chain director.'),
    ('solara-retail-mx', 'SRM-PR006', 'SRM-P022', 'SRM-P020', 'referrer', '2024-03-01', NULL, 'Referred the specialist through the loyalty partnership.'),
    ('solara-retail-mx', 'SRM-PR007', 'SRM-P019', 'SRM-P027', 'dependent', '2023-01-01', NULL, 'Dependent recorded for benefits administration.'),
    -- Cobalto Industrial Systems
    ('cobalto-industrial-mx', 'CIS-PR001', 'CIS-P001', 'CIS-P024', 'emergency_contact', '2008-08-11', NULL, NULL),
    ('cobalto-industrial-mx', 'CIS-PR002', 'CIS-P019', 'CIS-P025', 'emergency_contact', '2020-02-17', NULL, NULL),
    ('cobalto-industrial-mx', 'CIS-PR003', 'CIS-P012', 'CIS-P019', 'mentor', '2020-02-17', NULL, 'Technical mentorship in automation engineering.'),
    ('cobalto-industrial-mx', 'CIS-PR004', 'CIS-P022', 'CIS-P006', 'representative', '2021-04-12', NULL, 'Supplier representative assigned to supply-chain leadership.'),
    ('cobalto-industrial-mx', 'CIS-PR005', 'CIS-P023', 'CIS-P004', 'representative', '2023-08-14', NULL, 'Alliance representative for engineering collaboration.'),
    -- BluePeak Advisory
    ('bluepeak-advisory-us', 'BPA-PR001', 'BPA-P001', 'BPA-P020', 'emergency_contact', '2012-06-04', NULL, NULL),
    ('bluepeak-advisory-us', 'BPA-PR002', 'BPA-P012', 'BPA-P017', 'mentor', '2022-02-07', NULL, 'Practice-lead mentorship.'),
    ('bluepeak-advisory-us', 'BPA-PR003', 'BPA-P014', 'BPA-P018', 'mentor', '2023-05-15', NULL, 'Analytics consulting mentorship.'),
    ('bluepeak-advisory-us', 'BPA-PR004', 'BPA-P019', 'BPA-P017', 'referrer', '2022-02-07', NULL, 'Advisor referred the consultant to the firm.'),
    ('bluepeak-advisory-us', 'BPA-PR005', 'BPA-P019', 'BPA-P001', 'other', '2024-01-01', NULL, 'Board-advisory relationship recorded at person level.'),
    -- LumenForge Technologies
    ('lumenforge-technologies-us', 'LFT-PR001', 'LFT-P001', 'LFT-P022', 'emergency_contact', '2016-01-18', NULL, NULL),
    ('lumenforge-technologies-us', 'LFT-PR002', 'LFT-P001', 'LFT-P022', 'dependent', '2019-01-01', NULL, 'Dependent recorded for benefits administration.'),
    ('lumenforge-technologies-us', 'LFT-PR003', 'LFT-P014', 'LFT-P020', 'mentor', '2022-08-08', NULL, 'Applied AI technical mentorship.'),
    ('lumenforge-technologies-us', 'LFT-PR004', 'LFT-P021', 'LFT-P010', 'representative', '2025-03-03', NULL, 'Contractor representative to the security director.'),
    ('lumenforge-technologies-us', 'LFT-PR005', 'LFT-P017', 'LFT-P021', 'referrer', '2022-10-03', NULL, 'Product leader referred the customer-success manager.'),
    -- Cedarline Logistics
    ('cedarline-logistics-ca', 'CLL-PR001', 'CLL-P001', 'CLL-P019', 'emergency_contact', '2011-04-04', NULL, 'Primary emergency contact.'),
    ('cedarline-logistics-ca', 'CLL-PR002', 'CLL-P017', 'CLL-P019', 'mentor', '2025-01-13', NULL, 'Internal mentor for the embedded optimization specialist.'),
    ('cedarline-logistics-ca', 'CLL-PR003', 'CLL-P020', 'CLL-P007', 'representative', '2023-09-18', NULL, 'Customer representative assigned to the commercial director.'),
    ('cedarline-logistics-ca', 'CLL-PR004', 'CLL-P021', 'CLL-P006', 'representative', '2022-05-09', NULL, 'Fleet-maintenance representative assigned to transportation leadership.'),
    ('cedarline-logistics-ca', 'CLL-PR005', 'CLL-P003', 'CLL-P011', 'mentor', '2019-04-15', NULL, 'Leadership-development mentorship.'),
    -- Harvest Circle Foods
    ('harvest-circle-foods-ca', 'HCF-PR001', 'HCF-P001', 'HCF-P010', 'emergency_contact', '2003-05-12', '2024-09-30', NULL),
    ('harvest-circle-foods-ca', 'HCF-PR002', 'HCF-P006', 'HCF-P011', 'emergency_contact', '2014-02-10', '2024-09-30', NULL),
    ('harvest-circle-foods-ca', 'HCF-PR003', 'HCF-P004', 'HCF-P009', 'mentor', '2016-04-04', '2023-12-31', 'Historical operations mentorship.'),
    ('harvest-circle-foods-ca', 'HCF-PR004', 'HCF-P012', 'HCF-P008', 'representative', '2018-01-01', '2024-09-30', 'Former supplier representative assigned to accounting.');

UPDATE relationships.person_relationships AS person_relationships
SET
    valid_to = fixture.valid_to,
    notes = fixture.notes,
    updated_at = NOW()
FROM fixture_person_relationships AS fixture
JOIN core.companies AS companies
    ON companies.company_slug = fixture.company_slug
JOIN people.persons AS source_persons
    ON source_persons.company_id = companies.company_id
    AND source_persons.external_reference = fixture.source_person_external_reference
JOIN people.persons AS target_persons
    ON target_persons.company_id = companies.company_id
    AND target_persons.external_reference = fixture.target_person_external_reference
WHERE person_relationships.company_id = companies.company_id
  AND person_relationships.source_person_id = source_persons.person_id
  AND person_relationships.target_person_id = target_persons.person_id
  AND person_relationships.relationship_type = fixture.relationship_type
  AND person_relationships.valid_from = fixture.valid_from;

INSERT INTO relationships.person_relationships (
    company_id,
    source_person_id,
    target_person_id,
    relationship_type,
    valid_from,
    valid_to,
    notes
)
SELECT
    companies.company_id,
    source_persons.person_id,
    target_persons.person_id,
    fixture.relationship_type,
    fixture.valid_from,
    fixture.valid_to,
    fixture.notes
FROM fixture_person_relationships AS fixture
JOIN core.companies AS companies
    ON companies.company_slug = fixture.company_slug
JOIN people.persons AS source_persons
    ON source_persons.company_id = companies.company_id
    AND source_persons.external_reference = fixture.source_person_external_reference
JOIN people.persons AS target_persons
    ON target_persons.company_id = companies.company_id
    AND target_persons.external_reference = fixture.target_person_external_reference
WHERE NOT EXISTS (
    SELECT 1
    FROM relationships.person_relationships AS person_relationships
    WHERE person_relationships.company_id = companies.company_id
      AND person_relationships.source_person_id = source_persons.person_id
      AND person_relationships.target_person_id = target_persons.person_id
      AND person_relationships.relationship_type = fixture.relationship_type
      AND person_relationships.valid_from = fixture.valid_from
);

COMMIT;

\echo '03_people_and_relationships.sql completed'