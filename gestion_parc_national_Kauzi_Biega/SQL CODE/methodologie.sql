-- METHODOLOGIE DE TRVAIL

--I. Exploration des tables
--1. Lister les premières lignes
SELECT * FROM especes limit 10;
SELECT * from sites_secteurs limit 10,
SELECT * from touristes limit 10;
SELECT * from visites_activites limit 10 ;

--2. Verifier les types et contraintes
-- Vérification de la structure
SELECT 
    conname AS nom_contrainte, 
    contype AS type_contrainte, 
    pg_get_constraintdef(c.oid) AS definition
FROM pg_constraint c
JOIN pg_namespace n ON n.oid = c.connamespace
WHERE n.nspname = 'public'; 

--3.Identification des valeurs manquantes ou anomalies
-- combien de visite sans montant total
SELECT count(*) as montant_visite
from visites_activites
WHERE montant_total is NULL;

--4️.Decompte des enregistrements par table
SELECT count(*) from especes;
SELECT count(*) from sites_secteurs;
SELECT count(*) from touristes;
SELECT count(*) from visites_activites;

--II. Nettoyage des tables
TRUNCATE TABLE visites_activites RESTART IDENTITY;

INSERT INTO visites_activites (id_touriste, id_site, id_espece_cible, date_visite, montant_total, note_satisfaction, incident_signale)
SELECT 
    (id % 200) + 1,                   -- Distribue 200 touristes
    (id % 4) + 1,                     -- Distribue 4 sites
    (id % 4) + 1,                     -- Distribue 4 espèces
    '2020-01-01'::date + (id || ' days')::interval, -- Etale les dates sur 1000 jours
    (200 + (id % 500))::decimal,      -- Montants entre 200 et 700$
    (id % 5) + 1,                     -- Notes entre 1 et 5
    CASE WHEN id % 15 = 0 THEN TRUE ELSE FALSE END -- Un incident toutes les 15 visites
FROM generate_series(1, 1000) AS id;

--Vérification du volume total :
SELECT count(*) FROM visites_activites; 
--Vérification de la cohérence (Pas de "Client à 2000 visites")
SELECT id_touriste, COUNT(*) as nb 
FROM visites_activites 
GROUP BY id_touriste 
ORDER BY nb DESC 
LIMIT 10;
-- III. Calcul des KPI et cohortes
--1. Chiffre d'affaire annuel
SELECT 
EXTRACT (year from date_visite) as annee,
sum(montant_total) as chiffre_daffaire_annuel
from visites_activites
group by annee
order by chiffre_daffaire_annuel desc;

--2.Montant moyen dépensé par un National, un Expat et un International
SELECT
t.type_client,
round (avg(v.montant_total),2) as moyenne_par_type
from visites_activites v
join touristes t on v.id_touriste=t.id_touriste
group by t.type_client
order by moyenne_par_type DESC;

--3.Impact de l'Insécurité sur les Revenus
SELECT
s.niveau_insecurite,
sum(v.montant_total) as somme_par_niveau
from visites_activites v
join sites_secteurs s on v.id_site=s.id_site
group by s.niveau_insecurite
order by somme_par_niveau desc;


--4.Le Taux de Satisfaction par Espèce
SELECT 
e.nom_commun,
e.nom_scientifique,
round(avg (v.note_satisfaction),3) as note_moyenne
from visites_activites v
join especes e on v.id_espece_cible=e.id_espece
group by e.nom_commun,e.nom_scientifique
HAVING COUNT(v.id_visite) > 10
order by note_moyenne DESC;

--5.L'alerte Sécurité: nombre des cas d'alerte
WITH table_des_incidents as
 (SELECT
v.date_visite,
s.nom_site,
v.incident_signale,
case 
    when v.incident_signale is TRUE then 'ALERTE:Incident signalé'
    else 'RAS'
end as statut_incident
from visites_activites v 
join sites_secteurs s on v.id_site=s.id_site ) 

SELECT EXTRACT(year from v.date_visite) as annees,count(statut_incident) as nb_cas
from visites_activites v
cross join table_des_incidents t
where t.statut_incident ='ALERTE:Incident signalé'
group by annees
order by nb_cas desc;


--6.Le Top 3 des Nationalités les plus dépensières
SELECT
t.nationalite,
sum(v.montant_total) as montant_total_par_nationalite
from visites_activites v
join touristes t on v.id_touriste=t.id_touriste
group by t.nationalite
order by montant_total_par_nationalite desc
limit 3;

--7.Analyse de la Fidélité: les visiteurs qui ont le plus de visites
SELECT 
id_touriste,
count(*) as nombre_de_visite
from visites_activites
group by id_touriste
having count(*)>4
order by nombre_de_visite desc;

--8.Le Chiffre d'Affaires par Saison
--Selon les mois
SELECT
EXTRACT(month from date_visite) as mois_de_visite,
case
    when EXTRACT(month from date_visite) in (6,7,8) then 'Saison sèche'
    else 'Saison de pluie'
    end as saison,
sum(montant_total) as montant_total_par_saison
from visites_activites
group by mois_de_visite
order by montant_total_par_saison desc;

--Selon les saisons
SELECT
    CASE
        WHEN EXTRACT(MONTH FROM date_visite) IN (6,7,8) THEN 'Saison Sèche'
        ELSE 'Saison de pluies'
    END AS saison,
    SUM(montant_total) AS montant_total_par_saison
FROM visites_activites
GROUP BY 
    CASE 
        WHEN EXTRACT(MONTH FROM date_visite) IN (6,7,8) THEN 'Saison Sèche'
        ELSE 'Saison de pluies'
    END
ORDER BY montant_total_par_saison DESC;

--9.La rentabilité par site
SELECT
s.nom_site,
COUNT(v.id_visite) AS nb_visites,
SUM(v.montant_total) AS chiffre_daffaire,
ROUND(AVG(v.montant_total), 2) AS panier_moyen
FROM visites_activites v
JOIN sites_secteurs s ON v.id_site = s.id_site
GROUP BY s.nom_site
ORDER BY panier_moyen DESC;

--10.L'Espèce "Star"
SELECT
e.nom_commun,
count(v.id_visite) as nb_visites,
round(avg(v.note_satisfaction),2) as satisfaction_moyenne
from visites_activites v
join especes e on v.id_espece_cible=e.id_espece
group by e.nom_commun
order by nb_visites desc;

--11.Les visiteurs ayant depensé plus que la moyenne globale
WITH depenses_par_touriste AS (
    SELECT 
        id_touriste, 
        SUM(montant_total) AS total_client
    FROM visites_activites
    GROUP BY id_touriste
),
moyenne_globale AS (
    SELECT AVG(montant_total) AS moyenne_ref 
    FROM visites_activites
)
SELECT 
    t.id_touriste, 
    d.total_client,
    ROUND(m.moyenne_ref, 2) AS moyenne_du_parc
FROM depenses_par_touriste d
JOIN touristes t ON d.id_touriste = t.id_touriste
CROSS JOIN moyenne_globale m
WHERE d.total_client > m.moyenne_ref
ORDER BY d.total_client DESC;

--12.Le Profit Réel: chaque visite compte 50 $ au parc
SELECT 
    EXTRACT(YEAR FROM date_visite) AS annee,
    SUM(montant_total) - (COUNT(id_visite) * 50) AS profit_net
FROM visites_activites
GROUP BY EXTRACT(YEAR FROM date_visite)
ORDER BY profit_net DESC;

--13. Les visiteurs fidèles
SELECT
    t.id_touriste,
    count(v.id_visite) as nb_visites
from visites_activites v 
join touristes t on v.id_touriste=t.id_touriste
group by t.id_touriste
having count(v.id_visite)> 3;

--14. Les 3 meilleurs secteurs géographiques en terme de chiffre d'affaire
SELECT 
    s.nom_site,
    sum(v.montant_total) as somme_par_site
from visites_activites v
join sites_secteurs s ON v.id_site = s.id_site
group by s.nom_site
order by somme_par_site desc
limit 3;

--15. Les 3 meilleurs sites en terme de visites
SELECT
    s.nom_site,
    count(v.id_visite) as nb_visites
from visites_activites v 
join sites_secteurs s ON v.id_site = s.id_site
group by s.nom_site
order by nb_visites desc
limit 3;