### Parc National de Kahuzi-Biega : comment développer le tourisme sans exposer les visiteurs ?

Ce projet est une analyse SQL sur des données fictives. Le Parc National de Kahuzi-Biega existe bien, dans l'est de la République démocratique du Congo, mais les visiteurs, les visites et les montants de ce projet sont simulés. Les tendances que l'analyse met au jour sont donc celles que la simulation contient : l'intérêt du projet est la démarche, de la préparation des données jusqu'aux recommandations.

#### Le problème

Le parc vit des permis de visite, en particulier pour observer le gorille de Grauer, une espèce en danger critique. Mais certains secteurs du parc sont peu sûrs. La direction veut savoir d'où viennent ses revenus, quels visiteurs fidéliser, quand le parc est le plus fréquenté, et quel est le coût réel de l'insécurité pour l'expérience des visiteurs.

#### Les données

La base compte quatre tables : les espèces observables avec le prix de leur permis, quatre sites avec leur niveau d'insécurité, 2 255 touristes et 3 027 visites réparties de janvier 2020 à décembre 2025.

Un script Python génère ces données à partir d'hypothèses plausibles : une fréquentation plus forte en saison sèche, une chute en 2020 suivie d'une reprise, des tarifs qui dépendent de l'espèce et du statut du visiteur (international, expatrié ou national), et davantage d'incidents dans les zones peu sûres. La graine aléatoire est fixe : relancer le script redonne exactement les mêmes données.

Une première version du projet utilisait des données générées par un motif trop régulier : chaque site recevait exactement le même nombre de visites, et chaque espèce la même note. En relisant les résultats, j'ai constaté que les écarts mesurés venaient de ce motif et non de vraies tendances. J'ai donc reconstruit le jeu de données. C'est la principale leçon du projet : avant d'interpréter un chiffre, il faut vérifier comment la donnée a été produite.

#### La méthode

Les tables sont créées et chargées dans PostgreSQL. L'analyse commence par des contrôles : volume de chaque table, valeurs manquantes, montants aberrants et période couverte.

Les indicateurs reposent sur des jointures entre la table des visites et les tables de référence, des agrégations, des expressions de table (CTE), des fonctions de fenêtre pour calculer des parts du total, et des filtres conditionnels. Deux erreurs de la première version ont été corrigées. Le comptage des alertes de sécurité multipliait les incidents à cause d'une jointure croisée. Et la recherche des meilleurs clients comparait le total d'un client à la moyenne d'une seule visite.

La saisonnalité est comparée en chiffre d'affaires moyen par mois, pour que deux saisons de durées différentes restent comparables. Enfin, chaque résultat a été recalculé indépendamment en Python pour contrôler les requêtes.

Les scripts sont dans le dossier sql : création des tables, chargement des données, puis analyse. Le générateur et les fichiers CSV sont dans le dossier data.

#### Les résultats

Le gorille de Grauer fait vivre le parc : il représente 79,5 % du chiffre d'affaires et obtient la meilleure satisfaction, 4,4 sur 5. Le secteur de Tshivanga, où se trouvent les gorilles habitués à l'homme, accueille 53 % des visites mais génère 77 % des revenus.

Les visiteurs internationaux apportent 69 % du chiffre d'affaires avec moins de la moitié des visites, car ils paient le tarif plein. Les nationaux, qui bénéficient d'un tarif réduit, représentent près de 30 % des visites mais 4,5 % des revenus. En revanche, les visiteurs résidents reviennent : près de la moitié des expatriés et 39 % des nationaux ont fait plusieurs visites, contre 5 % des internationaux. Les États-Unis, la Belgique et la France sont les nationalités qui rapportent le plus.

L'insécurité a un coût direct. À Tshivanga, 2,6 % des visites connaissent un incident. Ce taux monte à 10 % à Itebero et à 18 % à Lemera, les deux secteurs les moins sûrs. Or un incident fait chuter la satisfaction de 4,1 à 2,1 sur 5.

La saison sèche (de juin à août et de décembre à février) rapporte deux fois plus par mois que la saison des pluies : environ 10 000 $ contre 5 000 $. Enfin, la fréquentation a été multipliée par plus de trois entre 2020 et 2025, de 210 à 690 visites par an, et le profit net a suivi.

#### Recommandations et impact

La première priorité est la sécurité des secteurs d'Itebero et de Lemera. Si leur taux d'incidents revenait au niveau de Tshivanga, environ 60 incidents sur 150 auraient été évités sur la période, soit plus de 40 %. Renforcer les patrouilles d'écogardes dans ces zones doit précéder toute promotion de ces secteurs.

Il faut ensuite protéger l'activité gorille, qui porte presque 80 % des revenus. Cette dépendance est un risque : la qualité des visites à Tshivanga et la santé des groupes habitués sont à surveiller en priorité.

La saison des pluies mérite des offres dédiées. Elle rapporte moitié moins par mois : des forfaits à prix réduit, destinés aux expatriés et aux nationaux qui reviennent déjà volontiers, permettraient de mieux remplir le parc hors saison.

Enfin, les deux publics appellent deux stratégies. Les résidents sont fidèles : une carte de visite annuelle les inciterait à revenir plus souvent. Les internationaux ne viennent qu'une fois mais paient le plus : c'est sur l'acquisition, aux États-Unis, en Belgique et en France, que la communication doit se concentrer.

#### Reproduire l'analyse

Installez PostgreSQL. Depuis la racine du dépôt, lancez psql avec le fichier sql/00_tout_executer.sql : il crée une base dédiée nommée pnkb_portfolio, charge les données et exécute toutes les requêtes. Pour régénérer les données, lancez data/generer_donnees.py avec Python.

Auteur : Philippe Ntale
