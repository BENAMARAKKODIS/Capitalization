---------------------------------------------------------
-- NRL Preprocessing Table
-- Extracts unique NRL numbers with their latest date_statut_valide
-- Source: db_domainrestricted_irn_79023_lqd_lup_quality_data_nrl.nrl
-- Note: Source table has 36k rows but only ~3489 unique NRL numbers
--       Duplicates come from NRL-Question links (one row per NRL per question)
--       We deduplicate by keeping the most recent date_statut_valide per NRL
---------------------------------------------------------

--- Ligne à changer: preprod / prod
CREATE OR REPLACE TABLE `irn-79023-lqd-dat-ope-05.db_domainrestricted_irn_79023_lqd_lup_quality_data.preprocessing_NRL_preprod`
AS
SELECT 
  nrl_number,
  date_statut_valide
FROM (
  SELECT 
    nrl_number,
    date_statut_valide,
    ROW_NUMBER() OVER (
      PARTITION BY nrl_number 
      ORDER BY date_statut_valide DESC NULLS LAST
    ) as rn
  FROM `irn-79023-lqd-dat-ope-05.db_domainrestricted_irn_79023_lqd_lup_quality_data_nrl.nrl`
)
WHERE rn = 1;