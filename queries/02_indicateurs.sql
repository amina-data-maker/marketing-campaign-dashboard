-- 02_indicateurs.sql
-- Calcul des indicateurs de performance à partir de la table campagnes_clean
-- produite par 01_nettoyage.sql : ROAS, CPA, taux de conversion, par canal et par mois,
-- avec une moyenne mobile sur 3 mois (fenêtrage) pour lisser les variations.

DROP TABLE IF EXISTS indicateurs_mensuels;

CREATE TABLE indicateurs_mensuels AS
WITH agrege AS (
    SELECT
        channel,
        date AS mois,
        SUM(spend)        AS depense_totale,
        SUM(revenue)       AS revenu_total,
        SUM(clicks)        AS clics_totaux,
        SUM(conversions)   AS conversions_totales
    FROM campagnes_clean
    GROUP BY channel, date
),
avec_kpi AS (
    SELECT
        channel,
        mois,
        depense_totale,
        revenu_total,
        clics_totaux,
        conversions_totales,

        -- ROAS = revenu généré / dépense publicitaire
        ROUND(revenu_total * 1.0 / NULLIF(depense_totale, 0), 2) AS roas,

        -- CPA = dépense / nombre de conversions
        ROUND(depense_totale * 1.0 / NULLIF(conversions_totales, 0), 2) AS cpa,

        -- Taux de conversion = conversions / clics
        ROUND(conversions_totales * 1.0 / NULLIF(clics_totaux, 0), 4) AS taux_conversion
    FROM agrege
)
SELECT
    channel,
    mois,
    depense_totale,
    revenu_total,
    roas,
    cpa,
    taux_conversion,

    -- Moyenne mobile du ROAS sur 3 mois (mois courant + 2 précédents), par canal :
    -- lisse les pics/creux mensuels pour voir la tendance de fond.
    ROUND(
        AVG(roas) OVER (
            PARTITION BY channel
            ORDER BY mois
            ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
        ), 2
    ) AS roas_moyenne_mobile_3mois
FROM avec_kpi
ORDER BY channel, mois;

-- Vue de synthèse : performance moyenne par canal sur les 12 mois (pour la recommandation
-- de réallocation budgétaire dans le README).
DROP TABLE IF EXISTS synthese_par_canal;

CREATE TABLE synthese_par_canal AS
SELECT
    channel,
    ROUND(SUM(spend), 2)                                    AS depense_totale_12mois,
    ROUND(SUM(revenue), 2)                                  AS revenu_total_12mois,
    ROUND(SUM(revenue) * 1.0 / SUM(spend), 2)               AS roas_moyen,
    ROUND(SUM(spend) * 1.0 / NULLIF(SUM(conversions), 0), 2) AS cpa_moyen,
    ROUND(SUM(conversions) * 1.0 / NULLIF(SUM(clicks), 0), 4) AS taux_conversion_moyen
FROM campagnes_clean
GROUP BY channel
ORDER BY roas_moyen DESC;
