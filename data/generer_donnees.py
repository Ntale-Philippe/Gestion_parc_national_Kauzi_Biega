"""Génère le jeu de données simulé du Parc National de Kahuzi-Biega (PNKB).

Les données sont fictives. Elles suivent des hypothèses plausibles, documentées ci-dessous,
pour que l'analyse SQL ait des tendances réelles à mettre au jour.
La graine aléatoire est fixe : relancer le script redonne exactement les mêmes fichiers.

Usage : python generer_donnees.py   (écrit les CSV dans le dossier du script)
"""
import calendar
import csv
import datetime
import os
import random

rng = random.Random(2026)
OUT = os.path.dirname(os.path.abspath(__file__))

# ------------------------------------------------------------------ référentiels
ESPECES = [  # id, nom commun, nom scientifique, statut UICN, permis (USD), indice de rareté
    (1, "Gorille de Grauer", "Gorilla beringei graueri", "CR", 400.00, 10),
    (2, "Chimpanzé de l'Est", "Pan troglodytes schweinfurthii", "EN", 150.00, 8),
    (3, "Cercopithèque de Hamlyn", "Cercopithecus hamlyni", "VU", 50.00, 7),
    (4, "Touraco du Ruwenzori", "Ruwenzoriornis johnstoni", "LC", 30.00, 4),
]
SITES = [  # id, nom, niveau d'insécurité (1 à 5), superficie (ha)
    (1, "Secteur Haute Altitude (Tshivanga)", 1, 15000.00),
    (2, "Secteur Basse Altitude (Itebero)", 4, 45000.00),
    (3, "Zone de Lemera", 5, 12000.00),
    (4, "Mont Kahuzi", 2, 8000.00),
]

# ------------------------------------------------------------------ hypothèses
# Fréquentation : chute en 2020 (pandémie), puis reprise progressive
VISITES_PAR_AN = {2020: 210, 2021: 360, 2022: 510, 2023: 600, 2024: 660, 2025: 690}
# Saisonnalité : saisons sèches (juin-août, décembre-février) plus fréquentées
POIDS_MOIS = {1: 1.2, 2: 1.2, 3: 0.6, 4: 0.6, 5: 0.6, 6: 1.5, 7: 1.5, 8: 1.5, 9: 0.8, 10: 0.8, 11: 0.8, 12: 1.2}
# Profil des visiteurs
TYPES = {"International": 0.45, "Expat": 0.25, "National": 0.30}
NATIONALITES = {
    "International": {"USA": 0.30, "Belgique": 0.20, "France": 0.20, "Canada": 0.15, "Rwanda": 0.15},
    "Expat": {"Belgique": 0.30, "France": 0.25, "USA": 0.20, "Canada": 0.10, "Rwanda": 0.15},
    "National": {"RDC": 1.0},
}
AGES = {"International": (25, 70), "Expat": (25, 60), "National": (18, 50)}
RETOUR = {"International": 0.05, "Expat": 0.45, "National": 0.35}  # probabilité qu'une visite soit un retour
# Choix du site selon le type de visiteur (les internationaux viennent surtout pour les gorilles de Tshivanga)
SITE_SELON_TYPE = {
    "International": {1: 0.65, 4: 0.20, 2: 0.10, 3: 0.05},
    "Expat": {1: 0.50, 4: 0.30, 2: 0.13, 3: 0.07},
    "National": {1: 0.35, 4: 0.40, 2: 0.15, 3: 0.10},
}
# Espèce observée selon le site
ESPECE_SELON_SITE = {
    1: {1: 0.70, 2: 0.05, 3: 0.10, 4: 0.15},
    2: {1: 0.30, 2: 0.45, 3: 0.15, 4: 0.10},
    3: {1: 0.10, 2: 0.40, 3: 0.30, 4: 0.20},
    4: {1: 0.05, 2: 0.10, 3: 0.25, 4: 0.60},
}
# Tarifs : permis de l'espèce selon le statut du visiteur, plus des frais annexes
TARIF = {"International": 1.00, "Expat": 0.75, "National": 0.10}
FRAIS = {"International": (20, 60), "Expat": (15, 45), "National": (5, 15)}
# Incidents : probabilité selon le niveau d'insécurité du site
INCIDENT = {1: 0.02, 2: 0.04, 4: 0.10, 5: 0.18}
# Satisfaction de base selon l'espèce (sur 5)
SATISFACTION = {1: 4.6, 2: 4.2, 3: 3.8, 4: 4.0}


def tirer(poids):
    cles = list(poids)
    return rng.choices(cles, weights=[poids[k] for k in cles])[0]


touristes, visites = [], []
deja_venus = {t: [] for t in TYPES}

dates = []
for annee, total in VISITES_PAR_AN.items():
    poids_total = sum(POIDS_MOIS.values())
    for mois, poids in POIDS_MOIS.items():
        n = round(total * poids / poids_total)
        jours = calendar.monthrange(annee, mois)[1]
        dates += [datetime.date(annee, mois, rng.randint(1, jours)) for _ in range(n)]
dates.sort()

for id_visite, jour in enumerate(dates, start=1):
    type_client = tirer(TYPES)
    if deja_venus[type_client] and rng.random() < RETOUR[type_client]:
        id_touriste = rng.choice(deja_venus[type_client])
    else:
        id_touriste = len(touristes) + 1
        lo, hi = AGES[type_client]
        touristes.append((id_touriste, tirer(NATIONALITES[type_client]), type_client,
                          rng.choice("MF"), rng.randint(lo, hi)))
        deja_venus[type_client].append(id_touriste)

    id_site = tirer(SITE_SELON_TYPE[type_client])
    id_espece = tirer(ESPECE_SELON_SITE[id_site])
    insecurite = SITES[id_site - 1][2]
    permis = ESPECES[id_espece - 1][4]
    montant = round(permis * TARIF[type_client] + rng.uniform(*FRAIS[type_client]), 2)
    incident = rng.random() < INCIDENT[insecurite]
    note = SATISFACTION[id_espece] - 0.15 * (insecurite - 1) - (1.8 if incident else 0) + rng.gauss(0, 0.6)
    note = min(5, max(1, round(note)))
    visites.append((id_visite, id_touriste, id_espece, id_site, jour.isoformat(), f"{montant:.2f}", note,
                    "true" if incident else "false"))


def ecrire(nom, entetes, lignes):
    with open(os.path.join(OUT, nom), "w", encoding="utf-8", newline="") as f:
        w = csv.writer(f)
        w.writerow(entetes)
        w.writerows(lignes)


ecrire("especes.csv", ["id_espece", "nom_commun", "nom_scientifique", "statut_uicn", "cout_permis_usd", "indice_rarete"],
       [(i, n, s, u, f"{c:.2f}", r) for i, n, s, u, c, r in ESPECES])
ecrire("sites_secteurs.csv", ["id_site", "nom_site", "niveau_insecurite", "superficie_ha"],
       [(i, n, s, f"{a:.2f}") for i, n, s, a in SITES])
ecrire("touristes.csv", ["id_touriste", "nationalite", "type_client", "genre", "age"], touristes)
ecrire("visites_activites.csv", ["id_visite", "id_touriste", "id_espece_cible", "id_site", "date_visite",
                                 "montant_total", "note_satisfaction", "incident_signale"], visites)
print(f"{len(touristes)} touristes, {len(visites)} visites ({dates[0]} -> {dates[-1]})")
