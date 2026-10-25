-- Analyse des visites du Parc National de Kahuzi-Biega (PostgreSQL)
-- Ce fichier ne contient que du SQL standard : il s'exécute aussi dans pgAdmin.

------------------------------------------------------------------------
-- I. EXPLORATION ET CONTRÔLES
------------------------------------------------------------------------

-- 1. Volume de chaque table
SELECT 'especes' AS table_source, COUNT(*) AS nb_lignes FROM especes
UNION ALL SELECT 'sites_secteurs', COUNT(*) FROM sites_secteurs
UNION ALL SELECT 'touristes', COUNT(*) FROM touristes
UNION ALL SELECT 'visites_activites', COUNT(*) FROM visites_activites;

-- 2. Valeurs manquantes, valeurs aberrantes et période couverte
SELECT
    COUNT(*) FILTER (WHERE montant_total IS NULL) AS montants_manquants,
    COUNT(*) FILTER (WHERE note_satisfaction IS NULL) AS notes_manquantes,
    COUNT(*) FILTER (WHERE montant_total <= 0) AS montants_aberrants,
    MIN(date_visite) AS premiere_visite,
    MAX(date_visite) AS derniere_visite
FROM visites_activites;

------------------------------------------------------------------------
-- II. INDICATEURS
------------------------------------------------------------------------

-- 3. Fréquentation et chiffre d'affaires par année
SELECT
    EXTRACT(YEAR FROM date_visite)::int AS annee,
    COUNT(*) AS nb_visites,
    SUM(montant_total) AS chiffre_affaires,
    ROUND(AVG(montant_total), 2) AS panier_moyen
FROM visites_activites
GROUP BY annee
ORDER BY annee;

-- 4. Chiffre d'affaires par type de visiteur
SELECT
    t.type_client,
    COUNT(*) AS nb_visites,
    SUM(v.montant_total) AS chiffre_affaires,
    ROUND(100.0 * SUM(v.montant_total) / SUM(SUM(v.montant_total)) OVER (), 1) AS part_ca_pct,
    ROUND(AVG(v.montant_total), 2) AS panier_moyen
FROM visites_activites v
JOIN touristes t ON v.id_touriste = t.id_touriste
GROUP BY t.type_client
ORDER BY chiffre_affaires DESC;

-- 5. Chiffre d'affaires et satisfaction par espèce
SELECT
    e.nom_commun,
    COUNT(*) AS nb_visites,
    SUM(v.montant_total) AS chiffre_affaires,
    ROUND(100.0 * SUM(v.montant_total) / SUM(SUM(v.montant_total)) OVER (), 1) AS part_ca_pct,
    ROUND(AVG(v.note_satisfaction), 2) AS satisfaction_moyenne
FROM visites_activites v
JOIN especes e ON v.id_espece_cible = e.id_espece
GROUP BY e.nom_commun
ORDER BY chiffre_affaires DESC;

-- 6. Sites : fréquentation, revenus, incidents et satisfaction selon le niveau d'insécurité
SELECT
    s.nom_site,
    s.niveau_insecurite,
    COUNT(*) AS nb_visites,
    SUM(v.montant_total) AS chiffre_affaires,
    ROUND(100.0 * AVG(v.incident_signale::int), 1) AS taux_incident_pct,
    ROUND(AVG(v.note_satisfaction), 2) AS satisfaction_moyenne
FROM visites_activites v
JOIN sites_secteurs s ON v.id_site = s.id_site
GROUP BY s.nom_site, s.niveau_insecurite
ORDER BY s.niveau_insecurite;

-- 7. Effet d'un incident sur la satisfaction
SELECT
    incident_signale,
    COUNT(*) AS nb_visites,
    ROUND(AVG(note_satisfaction), 2) AS satisfaction_moyenne
FROM visites_activites
GROUP BY incident_signale
ORDER BY incident_signale;

-- 8. Alertes de sécurité par année, en nombre et en taux
--    (la version précédente faisait une jointure croisée qui multipliait les incidents)
WITH table_des_incidents AS (
    SELECT
        v.date_visite,
        s.nom_site,
        CASE WHEN v.incident_signale THEN 'ALERTE : incident signalé' ELSE 'RAS' END AS statut_incident
    FROM visites_activites v
    JOIN sites_secteurs s ON v.id_site = s.id_site
)
SELECT
    EXTRACT(YEAR FROM date_visite)::int AS annee,
    COUNT(*) FILTER (WHERE statut_incident <> 'RAS') AS nb_incidents,
    COUNT(*) AS nb_visites,
    ROUND(100.0 * COUNT(*) FILTER (WHERE statut_incident <> 'RAS') / COUNT(*), 1) AS taux_incident_pct
FROM table_des_incidents
GROUP BY annee
ORDER BY annee;

-- 9. Saisonnalité : on compare le chiffre d'affaires MOYEN PAR MOIS,
--    car les deux saisons n'ont pas forcément le même nombre de mois
SELECT
    CASE WHEN EXTRACT(MONTH FROM date_visite) IN (6, 7, 8, 12, 1, 2) THEN 'Saison sèche' ELSE 'Saison des pluies' END AS saison,
    COUNT(DISTINCT date_trunc('month', date_visite)) AS nb_mois,
    COUNT(*) AS nb_visites,
    SUM(montant_total) AS chiffre_affaires,
    ROUND(SUM(montant_total) / COUNT(DISTINCT date_trunc('month', date_visite)), 2) AS ca_moyen_par_mois
FROM visites_activites
GROUP BY saison
ORDER BY ca_moyen_par_mois DESC;

-- 10. Fidélité : part des visiteurs revenus au moins une fois, par type
WITH visites_par_touriste AS (
    SELECT id_touriste, COUNT(*) AS nb_visites
    FROM visites_activites
    GROUP BY id_touriste
)
SELECT
    t.type_client,
    COUNT(*) AS nb_touristes,
    COUNT(*) FILTER (WHERE vp.nb_visites >= 2) AS nb_fideles,
    ROUND(100.0 * COUNT(*) FILTER (WHERE vp.nb_visites >= 2) / COUNT(*), 1) AS taux_fidelite_pct,
    ROUND(AVG(vp.nb_visites), 2) AS visites_par_touriste
FROM visites_par_touriste vp
JOIN touristes t ON vp.id_touriste = t.id_touriste
GROUP BY t.type_client
ORDER BY taux_fidelite_pct DESC;

-- 11. Les 3 nationalités qui rapportent le plus
SELECT
    t.nationalite,
    SUM(v.montant_total) AS chiffre_affaires
FROM visites_activites v
JOIN touristes t ON v.id_touriste = t.id_touriste
GROUP BY t.nationalite
ORDER BY chiffre_affaires DESC
LIMIT 3;

-- 12. Visiteurs qui dépensent plus que la moyenne des visiteurs
--     (la version précédente comparait le total d'un client à la moyenne d'UNE visite)
WITH depenses_par_touriste AS (
    SELECT id_touriste, SUM(montant_total) AS total_client
    FROM visites_activites
    GROUP BY id_touriste
),
moyenne_globale AS (
    SELECT AVG(total_client) AS moyenne_ref
    FROM depenses_par_touriste
)
SELECT
    COUNT(*) FILTER (WHERE d.total_client > m.moyenne_ref) AS nb_au_dessus_moyenne,
    COUNT(*) AS nb_touristes,
    ROUND(m.moyenne_ref, 2) AS depense_moyenne_par_touriste
FROM depenses_par_touriste d
CROSS JOIN moyenne_globale m
GROUP BY m.moyenne_ref;

-- 13. Profit net par année, avec un coût d'accueil de 50 $ par visite
SELECT
    EXTRACT(YEAR FROM date_visite)::int AS annee,
    SUM(montant_total) - COUNT(*) * 50 AS profit_net
FROM visites_activites
GROUP BY annee
ORDER BY annee;
