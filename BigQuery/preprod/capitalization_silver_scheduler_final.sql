---------------------------------------------------------
-- Scheduled Query : Weekly Snapshot
-- Runs every Monday at 01:00 UTC
-- Appends current state of silver pipeline to historization
---------------------------------------------------------

INSERT INTO `irn-79023-lqd-dat-ope-05.db_domainrestricted_irn_79023_lqd_lup_quality_data.capitalization_silver`

WITH
preprocessed_vies AS (
  SELECT * FROM `irn-79023-lqd-dat-ope-05.db_domainrestricted_irn_79023_lqd_lup_quality_data.preprocessing_VIES_preprod`
),
preprocessed_capitams AS (
  SELECT * FROM `irn-79023-lqd-dat-ope-05.db_domainrestricted_irn_79023_lqd_lup_quality_data.preprocessing_CAPITAMS_preprod`
),
preprocessing_nrl AS (
  SELECT * FROM `irn-79023-lqd-dat-ope-05.db_domainrestricted_irn_79023_lqd_lup_quality_data.preprocessing_NRL_preprod`
)

SELECT
  CURRENT_DATE() AS snapshot_date,
  CONCAT('W', FORMAT_DATE('%y%V', CURRENT_DATE())) AS snapshot_week,
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
  capitams.capitams_key,
  capitams.capitams_criticity,
  capitams.capitams_summary,
  capitams.capitams_status,
  capitams.capitams_assignee,
  capitams.capitams_component_names,
  capitams.capitams_gsfa,
  capitams.capitams_capitalization_status,
  capitams.capitams_subtask_summary AS capitams_nrl,
  DATE(nrl.date_statut_valide) AS nrl_date_statut_valide,
  GREATEST(0, CASE
    WHEN vies.vies_v0_starting_date IS NULL THEN NULL
    WHEN capitams.capitams_creation_date IS NULL THEN DATE_DIFF(CURRENT_DATE(), DATE(vies.vies_v0_starting_date), DAY)
    ELSE DATE_DIFF(DATE(capitams.capitams_creation_date), DATE(vies.vies_v0_starting_date), DAY)
  END) AS kpi_perfo_v0,
  GREATEST(0, CASE
    WHEN capitams.capitams_creation_date IS NULL THEN NULL
    WHEN nrl.date_statut_valide IS NOT NULL THEN DATE_DIFF(DATE(nrl.date_statut_valide), DATE(capitams.capitams_creation_date), DAY)
    ELSE DATE_DIFF(CURRENT_DATE(), DATE(capitams.capitams_creation_date), DAY)
  END) AS kpi_perfo_v1,
  GREATEST(0, CASE
    WHEN nrl.date_statut_valide IS NULL THEN NULL
    WHEN capitams.capitams_npk_date IS NOT NULL THEN DATE_DIFF(DATE(capitams.capitams_npk_date), DATE(nrl.date_statut_valide), DAY)
    WHEN capitams.capitams_bmir_termine_date IS NOT NULL THEN DATE_DIFF(DATE(capitams.capitams_bmir_termine_date), DATE(nrl.date_statut_valide), DAY)
    ELSE DATE_DIFF(CURRENT_DATE(), DATE(nrl.date_statut_valide), DAY)
  END) AS kpi_perfo_v2,
  CASE
    WHEN vies.vies_dor_opinion != 'VIES ready for capitalisation' AND capitams.capitams_key IS NULL THEN NULL
    WHEN vies.vies_dor_opinion = 'VIES ready for capitalisation' AND capitams.capitams_key IS NULL
      AND NOT EXISTS (SELECT 1 FROM UNNEST(vies.vies_linked_issues) AS element WHERE element LIKE 'CAPT%')
    THEN '1. VIES - CapitAMS ticket to be created'
    WHEN (ARRAY_LENGTH(capitams.capitams_component_names) = 0 OR EXISTS (SELECT 1 FROM UNNEST(capitams.capitams_component_names) AS component WHERE component IN ('BMIR_EN COURS DE CAPITALISATION', 'BMIR_T_TRANSFEREE'))) AND capitams.capitams_subtask_summary IS NULL THEN '2. CapitAMS - Backlog - Without NRL'
    WHEN EXISTS (SELECT 1 FROM UNNEST(capitams.capitams_component_names) AS component WHERE LOWER(component) LIKE '%npk%') THEN '3. CapitAMS - NPK'
    WHEN (ARRAY_LENGTH(capitams.capitams_component_names) = 0 OR EXISTS (SELECT 1 FROM UNNEST(capitams.capitams_component_names) AS component WHERE component IN ('BMIR_EN COURS DE CAPITALISATION', 'BMIR_T_TRANSFEREE'))) AND capitams.capitams_subtask_summary IS NOT NULL THEN '4. CapitAMS - Backlog - With NRL'
    WHEN EXISTS (SELECT 1 FROM UNNEST(capitams.capitams_component_names) AS component WHERE component IN ('BMIRF_CAPITALISATION TERMINEE', 'BMIRF_T_TRANSFEREE ET CAPITALISATION TERMINEE', 'BMIRF_CAPITALISATION TERMINEE_QC')) AND capitams.capitams_subtask_summary IS NOT NULL THEN '5. CapitAMS - Capit Terminée - With NRL'
    WHEN EXISTS (SELECT 1 FROM UNNEST(capitams.capitams_component_names) AS component WHERE component IN ('BMIRF_CAPITALISATION TERMINEE', 'BMIRF_T_TRANSFEREE ET CAPITALISATION TERMINEE', 'BMIRF_CAPITALISATION TERMINEE_QC')) AND capitams.capitams_subtask_summary IS NULL THEN '6. CapitAMS - Capit Terminée - Without NRL'
    ELSE NULL
  END AS top_priority

FROM preprocessed_vies AS vies
LEFT JOIN UNNEST(vies.vies_linked_issues) AS linked_issue
LEFT JOIN preprocessed_capitams AS capitams ON capitams.capitams_key = linked_issue
LEFT JOIN preprocessing_nrl AS nrl ON nrl.nrl_number = REGEXP_EXTRACT(capitams.capitams_subtask_summary, r'\d+')
QUALIFY ROW_NUMBER() OVER (PARTITION BY vies.vies_ticket_id ORDER BY capitams.capitams_creation_date DESC) = 1;