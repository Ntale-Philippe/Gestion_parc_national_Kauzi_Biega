# Analyse des Données du Parc National de Kahuzi-Biega (PNKB)
 Présentation du Projet

Ce projet consiste en une analyse approfondie des données touristiques et écologiques du PNKB (RDC). L'objectif est d'extraire des insights stratégiques pour optimiser la gestion des visites, la protection des espèces et la rentabilité financière du parc.
 Stack Technique

    Langage : SQL (PostgreSQL)

    Outil : pgAdmin

    Concepts clés : CTE (Common Table Expressions), Jointures complexes, Agrégations, Filtrage avancé (HAVING/WHERE), Analyse de rentabilité.

# Structure de la Base de Données

La base est articulée autour de 4 tables piliers :

    touristes : Informations sur les visiteurs.

    especes : Catalogue de la biodiversité.

    sites_secteurs : Géographie du parc (Tshivanga, Secteur Sud, etc.).

    visites_activites : Table de faits contenant les transactions, dates et incidents.

# Key Performance Indicators (KPI) traités

Voici les principales problématiques résolues par mes requêtes SQL :

    Rentabilité : Calcul du Profit Net après déduction des charges fixes par visite.

    Fidélité (Retention) : Identification des "Ambassadeurs" ayant dépensé plus que la moyenne globale.

    Opérations : Top 3 des sites les plus fréquentés pour l'allocation des ressources.

    Sécurité : Monitoring des incidents signalés sur le terrain via des alertes automatisées.

    Saisonnalité : Exemple:Analyse du chiffre d'affaires durant la saison sèche (Juin-Août).