-- Exécute tout le projet dans une base dédiée (psql, depuis la racine du dépôt) :
--   psql -U postgres -f sql/00_tout_executer.sql -o resultats_analyse.txt

\set ON_ERROR_STOP on
DROP DATABASE IF EXISTS pnkb_portfolio;
CREATE DATABASE pnkb_portfolio;
\c pnkb_portfolio

\ir 01_creation_tables.sql
\ir 02_chargement_donnees.sql
\ir 03_analyse.sql
