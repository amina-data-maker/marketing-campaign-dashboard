# Guide pas à pas — construire le dashboard dans Power BI

Ce guide t'accompagne pour monter toi-même le dashboard Power BI à partir des données de ce
repo. Compte environ 45-60 minutes la première fois. L'objectif n'est pas juste d'avoir un
joli résultat, mais de pouvoir l'expliquer en entretien — donc prends le temps de comprendre
chaque étape plutôt que de foncer.

## 0. Prérequis
- **Power BI Desktop** (gratuit) : à installer depuis [powerbi.microsoft.com/desktop](https://www.microsoft.com/fr-fr/power-platform/products/power-bi/desktop) (Windows uniquement — si tu es sur Mac, utilise une VM Windows ou Power BI Service en ligne).
- **DB Browser for SQLite** (gratuit) : [sqlitebrowser.org](https://sqlitebrowser.org/) — pour exécuter les requêtes SQL toi-même et voir le résultat, plutôt que d'importer directement les CSV déjà calculés. C'est cette étape qui te permet de dire en entretien "j'ai écrit et exécuté les requêtes SQL moi-même".

## Étape 1 — Exécuter les requêtes SQL toi-même
1. Ouvre DB Browser for SQLite.
2. `Fichier > Importer > Table depuis un fichier CSV`, sélectionne `data/campagnes_marketing_raw.csv`, nomme la table `campagnes_marketing_raw`.
3. Va dans l'onglet **Exécuter le SQL**, ouvre `queries/01_nettoyage.sql`, clique sur "Exécuter tout" (▶). Une table `campagnes_clean` doit apparaître dans l'onglet "Parcourir les données".
4. Fais pareil avec `queries/02_indicateurs.sql` : ça crée `indicateurs_mensuels` et `synthese_par_canal`.
5. Pour chacune des 3 tables (`campagnes_clean`, `indicateurs_mensuels`, `synthese_par_canal`), clic droit > **Exporter en CSV**.
6. `Fichier > Écrire les modifications` pour sauvegarder la base.

*(Si tu es pressée, les mêmes CSV sont déjà fournis dans `data/` — mais exécuter les requêtes toi-même, c'est ce qui compte pour l'apprentissage et pour l'entretien.)*

## Étape 2 — Importer les données dans Power BI
1. Ouvre Power BI Desktop → **Obtenir les données** → **Texte/CSV**.
2. Importe `indicateurs_mensuels.csv` et `synthese_par_canal.csv` (les deux tables issues de tes requêtes).
3. Vérifie les types de colonnes détectés (Power BI le fait souvent bien tout seul, mais vérifie que `mois` est bien en type Date, et `roas`/`cpa`/`taux_conversion` en type Nombre décimal) — onglet **Transformer les données** (Power Query) si besoin de corriger.
4. **Fermer et appliquer**.

## Étape 3 — Construire les visuels
Crée une page "Vue d'ensemble" avec :

1. **Carte (Card)** — ROAS global : `= DIVIDE(SUM(synthese_par_canal[revenu_total_12mois]), SUM(synthese_par_canal[depense_totale_12mois]))`
2. **Graphique à barres** — `roas_moyen` par `channel` (table `synthese_par_canal`). C'est le visuel qui répond directement à la question business.
3. **Graphique en courbes** — `roas_moyenne_mobile_3mois` par `mois`, une courbe par `channel` (table `indicateurs_mensuels`). Ça montre l'évolution dans le temps, pas juste une moyenne figée.
4. **Table** — `channel`, `depense_totale_12mois`, `roas_moyen`, `cpa_moyen`, `taux_conversion_moyen` (table `synthese_par_canal`), triée par `roas_moyen` décroissant.
5. **Segments (slicers)** — un sur `channel`, un sur `mois` (plage de dates), pour rendre le dashboard interactif comme demandé dans le README.

## Étape 4 — Mise en forme
- Un titre clair en haut ("Performance des campagnes marketing — 12 mois").
- Une couleur cohérente par canal dans tous les visuels (clic droit sur un visuel > Format > Couleurs des données) — ça rend le dashboard plus lisible qu'une palette aléatoire.
- Un sous-titre ou une zone de texte avec la recommandation clé (réallocation de budget).

## Étape 5 — Capture d'écran et publication
1. Une fois satisfaite du résultat, fais une capture d'écran de la page complète.
2. Sauvegarde-la dans `dashboard/apercu.png` (remplace `dashboard/apercu_provisoire.png`).
3. Mets à jour la ligne `![aperçu du dashboard](...)` dans le `README.md` pour pointer vers `dashboard/apercu.png`.
4. Sauvegarde aussi le fichier `.pbix` dans `dashboard/` et ajoute-le au repo (utile si quelqu'un veut l'ouvrir, mais le README + la capture suffisent pour la lecture rapide).

## Ce qu'un recruteur peut te demander sur ce projet
- "Pourquoi une moyenne mobile plutôt qu'une moyenne simple ?" → Pour lisser les variations mois par mois et voir la tendance de fond sans être trompée par un pic ponctuel.
- "Pourquoi ne pas juste utiliser `DISTINCT` pour enlever les doublons ?" → `DISTINCT` aurait aussi supprimé de vraies campagnes ayant les mêmes valeurs par coïncidence ; `ROW_NUMBER() OVER (PARTITION BY campaign_id ...)` cible précisément les doublons du même identifiant.
- "Comment tu justifies la recommandation de réallocation ?" → Avec les chiffres du dashboard : ROAS et taux de conversion par canal, pas juste une impression.
