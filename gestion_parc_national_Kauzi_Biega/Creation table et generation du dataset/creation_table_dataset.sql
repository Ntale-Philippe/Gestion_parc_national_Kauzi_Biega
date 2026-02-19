-- Nettoyage si besoin
DROP TABLE IF EXISTS visites_activites;
DROP TABLE IF EXISTS touristes;
DROP TABLE IF EXISTS sites_secteurs;
DROP TABLE IF EXISTS especes;

-- A. Table des Espèces
CREATE TABLE especes (
    id_espece SERIAL PRIMARY KEY,
    nom_commun VARCHAR(100),
    nom_scientifique VARCHAR(100),
    statut_uicn VARCHAR(5),
    cout_permis_usd DECIMAL(10,2),
    indice_rarete INT
);

-- B. Table des Sites
CREATE TABLE sites_secteurs (
    id_site SERIAL PRIMARY KEY,
    nom_site VARCHAR(100),
    niveau_insecurite INT CHECK (niveau_insecurite BETWEEN 1 AND 5),
    superficie_ha DECIMAL(10,2)
);

-- C. Table des Touristes
CREATE TABLE touristes (
    id_touriste SERIAL PRIMARY KEY,
    nationalite VARCHAR(50),
    type_client VARCHAR(20), -- National, Expat, International
    genre CHAR(1),
    age INT
);

-- D. Table des Visites (La table de faits)
CREATE TABLE visites_activites (
    id_visite SERIAL PRIMARY KEY,
    id_touriste INT REFERENCES touristes(id_touriste),
    id_espece_cible INT REFERENCES especes(id_espece),
    id_site INT REFERENCES sites_secteurs(id_site),
    date_visite DATE,
    montant_total DECIMAL(10,2),
    note_satisfaction INT,
    incident_signale BOOLEAN
);

--Insertion des données de référence (Dictionnaires)

INSERT INTO especes (nom_commun, nom_scientifique, statut_uicn, cout_permis_usd, indice_rarete) VALUES
('Gorille de Grauer', 'Gorilla beringei graueri', 'CR', 400.00, 10),
('Chimpanzé de l''Est', 'Pan troglodytes schweinfurthii', 'EN', 150.00, 8),
('Cercopithèque de Hamlyn', 'Cercopithecus hamlyni', 'VU', 50.00, 7),
('Oiseau de Paradis', 'Paradisaeidae', 'LC', 30.00, 4);

INSERT INTO sites_secteurs (nom_site, niveau_insecurite, superficie_ha) VALUES
('Secteur Haute Altitude (Tshivanga)', 1, 15000.00),
('Secteur Basse Altitude (Itebero)', 4, 45000.00),
('Zone de Lemera', 5, 12000.00),
('Mont Kahuzi', 2, 8000.00);

--Génération du Dataset (500+ lignes)
-- 1. Génération de 200 touristes fictifs
INSERT INTO touristes (nationalite, type_client, genre, age)
SELECT 
    (ARRAY['RDC', 'Belgique', 'USA', 'France', 'Rwanda', 'Canada'])[floor(random() * 6 + 1)],
    (ARRAY['National', 'Expat', 'International'])[floor(random() * 3 + 1)],
    (ARRAY['M', 'F'])[floor(random() * 2 + 1)],
    floor(random() * 45 + 18)
FROM generate_series(1, 200);

-- 2. Génération de 600 visites (La table centrale)
INSERT INTO visites_activites (id_touriste, id_espece_cible, id_site, date_visite, montant_total, note_satisfaction, incident_signale)
SELECT 
    floor(random() * 199 + 1), -- id_touriste
    floor(random() * 4 + 1),   -- id_espece
    floor(random() * 4 + 1),   -- id_site
    generate_series('2020-01-01'::date, '2025-12-31'::date, '3.5 days'::interval), -- Dates réparties
    (random() * 100 + 400),    -- Montant fluctuant
    floor(random() * 5 + 1),   -- Note
    (random() > 0.9)           -- 10% de chance d'incident
FROM generate_series(1, 600);

