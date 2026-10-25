-- Création des tables du PNKB (PostgreSQL)

DROP TABLE IF EXISTS visites_activites;
DROP TABLE IF EXISTS touristes;
DROP TABLE IF EXISTS sites_secteurs;
DROP TABLE IF EXISTS especes;

-- A. Espèces observables et coût du permis de visite
CREATE TABLE especes (
    id_espece SERIAL PRIMARY KEY,
    nom_commun VARCHAR(100),
    nom_scientifique VARCHAR(100),
    statut_uicn VARCHAR(5),
    cout_permis_usd DECIMAL(10,2),
    indice_rarete INT
);

-- B. Sites et secteurs du parc
CREATE TABLE sites_secteurs (
    id_site SERIAL PRIMARY KEY,
    nom_site VARCHAR(100),
    niveau_insecurite INT CHECK (niveau_insecurite BETWEEN 1 AND 5),
    superficie_ha DECIMAL(10,2)
);

-- C. Touristes
CREATE TABLE touristes (
    id_touriste SERIAL PRIMARY KEY,
    nationalite VARCHAR(50),
    type_client VARCHAR(20), -- National, Expat, International
    genre CHAR(1),
    age INT
);

-- D. Visites (table de faits)
CREATE TABLE visites_activites (
    id_visite SERIAL PRIMARY KEY,
    id_touriste INT REFERENCES touristes(id_touriste),
    id_espece_cible INT REFERENCES especes(id_espece),
    id_site INT REFERENCES sites_secteurs(id_site),
    date_visite DATE,
    montant_total DECIMAL(10,2),
    note_satisfaction INT CHECK (note_satisfaction BETWEEN 1 AND 5),
    incident_signale BOOLEAN
);
