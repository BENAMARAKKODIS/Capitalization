---------------------------------------------------------
-- Scheduled Query — Weekly Snapshot into history table
-- Runs every Wednesday at 07:00 UTC
-- Reads from capitalization_silver and appends to history
---------------------------------------------------------

INSERT INTO `irn-79023-lqd-dat-ope-05.db_domainrestricted_irn_79023_lqd_lup_quality_data.capitalization_silver_history`

SELECT
  CURRENT_DATE() AS snapshot_date,
  CONCAT('W', FORMAT_DATE('%y%V', CURRENT_DATE())) AS snapshot_week,
  vies_ticket_id,
  vies_summary,
  vies_affected_versions,
  vies_product_lines,
  vies_plateau,
  vies_domain,
  vies_criticity,
  vies_dor_opinion,
  vies_requesting_teams,
  vies_status,
  vies_labels,
  vies_lup_linked,
  vies_component_names,
  vies_creation_date,
  capitams_key,
  capitams_criticity,
  capitams_summary,
  capitams_status,
  capitams_assignee,
  capitams_component_names,
  capitams_gsfa,
  capitams_capitalization_status,
  capitams_nrl,
  nrl_date_statut_valide,
  kpi_perfo_v0,
  kpi_perfo_v1,
  kpi_perfo_v2,
  top_priority,
  tickets_vies_ready,
  tickets_capitams_created,
  tickets_nrl_npk

FROM `irn-79023-lqd-dat-ope-05.db_domainrestricted_irn_79023_lqd_lup_quality_data.capitalization_silver`;