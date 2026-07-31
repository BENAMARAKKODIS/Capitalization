---------------------------------------------------------
-- Step 0. Table Construction with Specific Schema
---------------------------------------------------------

--- Ligne à changer: preprod / prod
CREATE OR REPLACE TABLE `irn-79023-lqd-dat-ope-05.db_domainrestricted_irn_79023_lqd_lup_quality_data.capitalization_silver`
--- Bien faire attention (1/5)
(
  -- colonnes projet VIES
  vies_ticket_id         STRING NOT NULL OPTIONS(description = 'Unique Identification Number for a VIES ticket'),
  vies_summary           STRING OPTIONS(description = 'Description of the issue'),
  vies_affected_versions STRING OPTIONS(description = 'Scope of the ticket, key information for scoping KPIs'),
  vies_product_lines     STRING OPTIONS(description = 'Product line associated with the ticket'),
  vies_plateau           STRING OPTIONS(description = 'Plateau calculated from product line and IVI2 SW version'),
  vies_domain            STRING OPTIONS(description = 'Domain of the ticket, key information for scoping KPIs'),
  vies_criticity         STRING OPTIONS(description = 'Criticity of the ticket'),
  vies_dor_opinion       STRING OPTIONS(description = 'Decision to launch Capitalization'),
  vies_requesting_teams  ARRAY<STRING> OPTIONS(description = 'Who identified the issue, key information for scoping KPIs'),
  vies_status            STRING OPTIONS(description = 'Status in the workflow'),
  vies_labels            STRING OPTIONS(description = 'Labels of the ticket flattened as a string'),
  vies_lup_linked        STRING OPTIONS(description = 'LUP linked to this VIES ticket. Must be 1 LUP maximum or NULL.'),
  vies_component_names   ARRAY<STRING> OPTIONS(description = 'List of component names'),
  vies_creation_date     TIMESTAMP OPTIONS(description = 'Creation date of the VIES ticket used for partitioning'),  
  -- colonnes projet CAPITAMS
  capitams_key           STRING OPTIONS(description = 'Unique Identification Number for a CAPITAMS ticket'),
  capitams_summary       STRING OPTIONS(description = 'Description of the issue'),
  capitams_status        STRING OPTIONS(description = 'Status in the workflow'),
  capitams_assignee      STRING OPTIONS(description = 'Assignee name via decryption'),
  capitams_component_names ARRAY<STRING> OPTIONS(description = 'List of component names'),
  capitams_gsfa          STRING OPTIONS(description = "GSFA attaché au ticket"),
  capitams_capitalization_status STRING OPTIONS(description = "Statut de capit du ticket"),
  capitams_nrl           STRING OPTIONS(description = 'NRL Reference'),
  -- colonnes NRL
  nrl_date_statut_valide DATE OPTIONS(description = 'Date statut valide from NRL preprocessing table'),
  -- Nouvelles colonnes
  kpi_perfo_v0           INT64 OPTIONS(description = 'Duration of the v0 phase in calendar days'),
  kpi_perfo_v1           INT64 OPTIONS(description = 'Duration of the v1 phase in calendar days'),
  kpi_perfo_v2           INT64 OPTIONS(description = 'Duration of the v2 phase in calendar days'),
  top_priority           STRING OPTIONS(description = 'Statut de la capitalisation')
)
PARTITION BY DATE(vies_creation_date)
AS

WITH
---------------------------------------------------------
-- 1. SOURCE Tickets VIES
---------------------------------------------------------

--- Ligne à changer: preprod / prod
preprocessed_vies AS (
  SELECT *
  FROM `irn-79023-lqd-dat-ope-05.db_domainrestricted_irn_79023_lqd_lup_quality_data.preprocessing_VIES_preprod`
),
--- Bien faire attention (2/5)

---------------------------------------------------------
-- 2. SOURCE CAPITALIZATION
---------------------------------------------------------

--- Ligne à changer: preprod / prod
preprocessed_capitams AS (
  SELECT *
  FROM `irn-79023-lqd-dat-ope-05.db_domainrestricted_irn_79023_lqd_lup_quality_data.preprocessing_CAPITAMS_preprod`
),
--- Bien faire attention (3/5)

---------------------------------------------------------
-- 3. SOURCE NRL
---------------------------------------------------------

--- Ligne à changer: preprod / prod
preprocessing_nrl AS (
  SELECT *
  FROM `irn-79023-lqd-dat-ope-05.db_domainrestricted_irn_79023_lqd_lup_quality_data.preprocessing_NRL_preprod`
)
--- Bien faire attention (4/5)

---------------------------------------------------------
-- 4. FINAL ASSEMBLY
---------------------------------------------------------
SELECT
  -- VIES Fields
  vies.vies_ticket_id,
  vies.vies_summary,
  vies.vies_affected_versions,
  vies.vies_product_lines,
  vies.vies_plateau,
  vies.vies_domain,
  vies.vies_criticity,
  vies.vies_dor_opinion,
  vies.vies_requesting_teams,
  vies.vies_status,
  vies.vies_labels,
  vies.vies_lup_linked,
  vies.vies_component_names,
  vies.vies_creation_date,

  -- CAPITAMS Fields
  capitams.capitams_key,
  capitams.capitams_summary,
  capitams.capitams_status,
  capitams.capitams_assignee,
  capitams.capitams_component_names,
  capitams.capitams_gsfa,
  capitams.capitams_capitalization_status,
  capitams.capitams_subtask_summary AS capitams_nrl,

  -- NRL Fields
  DATE(nrl.date_statut_valide) AS nrl_date_statut_valide,

  -- KPI perfo v0
  GREATEST(
    0, -- 0 si le ticket CAPITAMS a été crée avant la fin de v0
    CASE
      -- Ticket VIES pas pret
      WHEN vies.vies_v0_starting_date IS NULL THEN NULL
      -- Ticket VIES pret mais pas de ticket CAPITAMS associé
      WHEN capitams.capitams_creation_date IS NULL THEN
        DATE_DIFF(CURRENT_DATE(), DATE(vies.vies_v0_starting_date), DAY)
      -- Ticket VIES avec un ticket CAPITAMS associé
      ELSE
        DATE_DIFF(DATE(capitams.capitams_creation_date), DATE(vies.vies_v0_starting_date), DAY)
    END
  ) AS kpi_perfo_v0,

  -- KPI perfo v1 à changer avec date NRL
  CASE
    -- Ticket capitams pas créé
    WHEN capitams.capitams_creation_date IS NULL THEN NULL
    -- Ticket capitams avec un NRL valide
    WHEN nrl.date_statut_valide IS NOT NULL THEN
      DATE_DIFF(DATE(nrl.date_statut_valide), DATE(capitams.capitams_creation_date), DAY)
    -- Ticket capitams sans NRL en statut valide
    ELSE
      DATE_DIFF(CURRENT_DATE(), DATE(capitams.capitams_creation_date), DAY)
  END AS kpi_perfo_v1,

  -- KPI perfo v2 à changer avec date NRL
  CASE
    -- Ticket n'ayant jamais eu de NRL en valide
    WHEN nrl.date_statut_valide IS NULL THEN NULL
    -- Ticket capitams avec un NPK
    WHEN capitams.capitams_npk_date IS NOT NULL THEN
      DATE_DIFF(DATE(capitams.capitams_npk_date), DATE(nrl.date_statut_valide), DAY)
    -- Ticket avec un BMIR terminé
    WHEN capitams.capitams_bmir_termine_date IS NOT NULL THEN
      DATE_DIFF(DATE(capitams.capitams_bmir_termine_date), DATE(nrl.date_statut_valide), DAY)
    -- Ticket avec un BMIR en cours
    ELSE
      DATE_DIFF(CURRENT_DATE(), DATE(nrl.date_statut_valide), DAY)
  END AS kpi_perfo_v2,

  ---------------------------------------------------------
  -- 5. Calcul du statut Top Priority
  ---------------------------------------------------------
  CASE

    -- 0. VIES non capitalisables
    WHEN vies.vies_dor_opinion != 'VIES ready for capitalisation'
    AND capitams.capitams_key IS NULL
    THEN NULL

    -- 1. VIES - CapitAMS ticket to be created
    WHEN 
      vies.vies_dor_opinion = 'VIES ready for capitalisation'
      AND capitams.capitams_key IS NULL
      AND NOT EXISTS (
        SELECT 1
        FROM UNNEST(vies.vies_linked_issues) AS element
        WHERE element LIKE 'CAPT%'
      )
    THEN '1. VIES - CapitAMS ticket to be created'

    -- 2. CapitAMS - Backlog - Without NRL
    WHEN (
        ARRAY_LENGTH(capitams.capitams_component_names) = 0
        OR EXISTS (
            SELECT 1
            FROM UNNEST(capitams.capitams_component_names) AS component
            WHERE component IN (
                'BMIR_EN COURS DE CAPITALISATION',
                'BMIR_T_TRANSFEREE'
            )
        )
    )
    AND capitams.capitams_subtask_summary IS NULL
    THEN '2. CapitAMS - Backlog - Without NRL'

    -- 3. CapitAMS - NPK
    WHEN EXISTS (
      SELECT 1
      FROM UNNEST(capitams.capitams_component_names) AS component
      WHERE LOWER(component) LIKE '%npk%'
    )
    THEN '3. CapitAMS - NPK'

    -- 4. CapitAMS - Backlog - With NRL
    WHEN (
        ARRAY_LENGTH(capitams.capitams_component_names) = 0
        OR EXISTS (
            SELECT 1
            FROM UNNEST(capitams.capitams_component_names) AS component
            WHERE component IN (
                'BMIR_EN COURS DE CAPITALISATION',
                'BMIR_T_TRANSFEREE'
            )
        )
    )
    AND capitams.capitams_subtask_summary IS NOT NULL
    THEN '4. CapitAMS - Backlog - With NRL'

    -- 5. CapitAMS - Capit Terminée - With NRL
    WHEN EXISTS (
      SELECT 1
      FROM UNNEST(capitams.capitams_component_names) AS component
      WHERE component IN (
        'BMIRF_CAPITALISATION TERMINEE',
        'BMIRF_T_TRANSFEREE ET CAPITALISATION TERMINEE',
        'BMIRF_CAPITALISATION TERMINEE_QC'
      )
    )
    AND capitams.capitams_subtask_summary IS NOT NULL
    THEN '5. CapitAMS - Capit Terminée - With NRL'

    -- 6. CapitAMS - Capit Terminée - Without NRL
    WHEN EXISTS (
      SELECT 1
      FROM UNNEST(capitams.capitams_component_names) AS component
      WHERE component IN (
        'BMIRF_CAPITALISATION TERMINEE',
        'BMIRF_T_TRANSFEREE ET CAPITALISATION TERMINEE',
        'BMIRF_CAPITALISATION TERMINEE_QC'
      )
    )
    AND capitams.capitams_subtask_summary IS NULL
    THEN '6. CapitAMS - Capit Terminée - Without NRL'

    -- 7. Autres
    ELSE NULL
  END AS top_priority

FROM preprocessed_vies AS vies

LEFT JOIN UNNEST(vies.vies_linked_issues) AS linked_issue

LEFT JOIN preprocessed_capitams AS capitams
  ON capitams.capitams_key = linked_issue

LEFT JOIN preprocessing_nrl AS nrl
  ON nrl.nrl_number = REGEXP_EXTRACT(capitams.capitams_subtask_summary, r'\d+')

-- keep only 1 CAPITAMS per VIES ticket: latest capitams_creation_date
QUALIFY ROW_NUMBER() OVER (
  PARTITION BY vies.vies_ticket_id
  ORDER BY capitams.capitams_creation_date DESC
) = 1;

---------------------------------------------------------
-- 6. Primary Key Assignment
---------------------------------------------------------

--- Ligne à changer: preprod / prod
ALTER TABLE `irn-79023-lqd-dat-ope-05.db_domainrestricted_irn_79023_lqd_lup_quality_data.capitalization_silver`
ADD PRIMARY KEY (vies_ticket_id) NOT ENFORCED;
--- Bien faire attention (4/4)