-- 01_nettoyage.sql
-- Nettoyage du export brut des campagnes marketing (Google Ads / Meta Ads / TikTok Ads).
--
-- Problèmes présents dans l'export brut (campagnes_marketing_raw) :
--   1. Doublons de campagnes (export accidentellement dupliqué ~4% des lignes)
--   2. Montants de dépense au format hétérogène ("EUR 1234.56", "1234.56€", "1234.56")
--   3. cpc_reported manquant sur certaines lignes
--   4. Nom de canal non normalisé ("google ads", "GOOGLE ADS", "Facebook/Meta Ads", ...)
--   5. Quelques lignes avec clicks = 0 (bug d'export, à exclure)
--
-- Ce script produit une table propre `campagnes_clean` prête pour l'analyse.

DROP TABLE IF EXISTS campagnes_clean;

CREATE TABLE campagnes_clean AS
WITH deduplique AS (
    -- Étape 1 : suppression des doublons.
    -- Un même campaign_id ne doit apparaître qu'une seule fois : on numérote les
    -- occurrences (fenêtrage) et on ne garde que la première.
    SELECT
        *,
        ROW_NUMBER() OVER (
            PARTITION BY campaign_id
            ORDER BY rowid
        ) AS occurrence
    FROM campagnes_marketing_raw
),
normalise AS (
    SELECT
        campaign_id,
        date,

        -- Étape 2 : normalisation du nom de canal (casse + variantes)
        CASE
            WHEN lower(channel) LIKE '%google%'  THEN 'Google Ads'
            WHEN lower(channel) LIKE '%meta%' OR lower(channel) LIKE '%facebook%' THEN 'Meta Ads'
            WHEN lower(channel) LIKE '%tiktok%' OR lower(channel) LIKE '%tik tok%' THEN 'TikTok Ads'
            ELSE channel
        END AS channel,

        campaign_type,
        campaign_name,

        -- Étape 3 : normalisation de la dépense ("EUR 1234.56" / "1234.56€" / "1234.56" -> nombre)
        CAST(
            REPLACE(REPLACE(REPLACE(spend, 'EUR', ''), '€', ''), ',', '')
            AS REAL
        ) AS spend,

        clicks,
        impressions,
        conversions,
        revenue,
        cpc_reported
    FROM deduplique
    WHERE occurrence = 1        -- on ne garde que la première occurrence de chaque campagne
      AND clicks > 0            -- Étape 4 : on exclut les lignes avec 0 clic (bug d'export)
)
SELECT
    campaign_id,
    date,
    channel,
    campaign_type,
    campaign_name,
    spend,
    clicks,
    impressions,
    conversions,
    revenue,
    -- Étape 5 : recalcul du CPC quand il manque, au lieu de le laisser vide
    COALESCE(cpc_reported, ROUND(spend * 1.0 / clicks, 3)) AS cpc
FROM normalise;

-- Contrôle rapide : nombre de lignes avant / après nettoyage
-- SELECT (SELECT COUNT(*) FROM campagnes_marketing_raw) AS lignes_brutes,
--        (SELECT COUNT(*) FROM campagnes_clean)         AS lignes_propres;
