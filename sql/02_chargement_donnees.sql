-- Chargement des données simulées (à lancer avec psql depuis la racine du dépôt)
-- Les fichiers CSV sont produits par data/generer_donnees.py

\copy especes FROM 'data/especes.csv' WITH (FORMAT csv, HEADER true, ENCODING 'UTF8')
\copy sites_secteurs FROM 'data/sites_secteurs.csv' WITH (FORMAT csv, HEADER true, ENCODING 'UTF8')
\copy touristes FROM 'data/touristes.csv' WITH (FORMAT csv, HEADER true, ENCODING 'UTF8')
\copy visites_activites FROM 'data/visites_activites.csv' WITH (FORMAT csv, HEADER true, ENCODING 'UTF8')

-- Les identifiants sont fournis par les fichiers : on recale les compteurs automatiques
SELECT setval('especes_id_espece_seq', (SELECT MAX(id_espece) FROM especes));
SELECT setval('sites_secteurs_id_site_seq', (SELECT MAX(id_site) FROM sites_secteurs));
SELECT setval('touristes_id_touriste_seq', (SELECT MAX(id_touriste) FROM touristes));
SELECT setval('visites_activites_id_visite_seq', (SELECT MAX(id_visite) FROM visites_activites));
