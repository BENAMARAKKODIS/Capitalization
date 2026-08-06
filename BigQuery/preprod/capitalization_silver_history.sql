---------------------------------------------------------
-- capitalization_silver_history
-- Separate historization table — weekly snapshot of silver
-- CREATE ONCE, then use scheduler to INSERT weekly
---------------------------------------------------------

--- Ligne à changer: preprod / prod
CREATE TABLE IF NOT EXISTS `irn-79023-lqd-dat-ope-05.db_domainrestricted_irn_79023_lqd_lup_quality_data.capitalization_silver_history`
(
  -- colonnes snapshot
  snapshot_date            DATE OPTIONS(description = 'Date of the weekly snapshot'),
  snapshot_week            STRING OPTIONS(description = 'Week label in WYYww format'),
  -- colonnes projet VIES
  vies_ticket_id           STRING NOT NULL OPTIONS(description = 'Unique Identification Number for a VIES ticket'),
  vies_summary             STRING OPTIONS(description = 'Description of the issue'),
  vies_affected_versions   STRING OPTIONS(description = 'Scope of the ticket, key information for scoping KPIs'),
  vies_product_lines       STRING OPTIONS(description = 'Product line associated with the ticket'),
  vies_plateau             STRING OPTIONS(description = 'Plateau calculated from product line and IVI2 SW version'),
  vies_domain              STRING OPTIONS(description = 'Domain of the ticket, key information for scoping KPIs'),
  vies_criticity           STRING OPTIONS(description = 'Criticity of the ticket'),
  vies_dor_opinion         STRING OPTIONS(description = 'Decision to launch Capitalization'),
  vies_requesting_teams    ARRAY<STRING> OPTIONS(description = 'Who identified the issue, key information for scoping KPIs'),
  vies_status              STRING OPTIONS(description = 'Status in the workflow'),
  vies_labels              STRING OPTIONS(description = 'Labels of the ticket flattened as a string'),
  vies_lup_linked          STRING OPTIONS(description = 'LUP linked to this VIES ticket. Must be 1 LUP maximum or NULL.'),
  vies_component_names     ARRAY<STRING> OPTIONS(description = 'List of component names'),
  vies_creation_date       TIMESTAMP OPTIONS(description = 'Creation date of the VIES ticket'),
  -- colonnes projet CAPITAMS
  capitams_key             STRING OPTIONS(description = 'Unique Identification Number for a CAPITAMS ticket'),
  capitams_criticity       STRING OPTIONS(description = 'Criticity of the CAPITAMS ticket'),
  capitams_summary         STRING OPTIONS(description = 'Description of the issue'),
  capitams_status          STRING OPTIONS(description = 'Status in the workflow'),
  capitams_assignee        STRING OPTIONS(description = 'Assignee name via decryption'),
  capitams_component_names ARRAY<STRING> OPTIONS(description = 'List of component names'),
  capitams_gsfa            STRING OPTIONS(description = 'GSFA attaché au ticket'),
  capitams_capitalization_status STRING OPTIONS(description = 'Statut de capit du ticket'),
  capitams_nrl             STRING OPTIONS(description = 'NRL Reference'),
  -- colonnes NRL
  nrl_date_statut_valide   DATE OPTIONS(description = 'Date statut valide from NRL preprocessing table'),
  -- KPI colonnes
  kpi_perfo_v0             INT64 OPTIONS(description = 'Duration of the v0 phase in calendar days'),
  kpi_perfo_v1             INT64 OPTIONS(description = 'Duration of the v1 phase in calendar days'),
  kpi_perfo_v2             INT64 OPTIONS(description = 'Duration of the v2 phase in calendar days'),
  top_priority             STRING OPTIONS(description = 'Statut de la capitalisation'),
  -- KPI 3C colonnes
  tickets_vies_ready       BOOL OPTIONS(description = 'Tickets VIES Ready for Capitalization'),
  tickets_capitams_created BOOL OPTIONS(description = 'Tickets CapitAMS created'),
  tickets_nrl_npk          BOOL OPTIONS(description = 'Tickets CapitAMS with NRL or NPK')
)
PARTITION BY snapshot_date;

---------------------------------------------------------
-- PRIMARY KEY
---------------------------------------------------------
ALTER TABLE `irn-79023-lqd-dat-ope-05.db_domainrestricted_irn_79023_lqd_lup_quality_data.capitalization_silver_history`
ADD PRIMARY KEY (vies_ticket_id, snapshot_week) NOT ENFORCED;