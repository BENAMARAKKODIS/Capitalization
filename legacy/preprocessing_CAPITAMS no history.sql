CREATE OR REPLACE TABLE `irn-79023-lqd-dat-ope-05.db_domainrestricted_irn_79023_lqd_lup_quality_data.preprocessing_CAPITAMS`
(
  capitalization_key STRING OPTIONS(description = 'Unique Identification Number for a JIRA ticket'),
  capitalization_project STRING OPTIONS(description = 'Business project identification'),
  capitalization_summary STRING OPTIONS(description = 'Description of the issue, useful to analyze KPI but not to calculate it'),
  capitalization_status STRING OPTIONS(description = 'Status in the lifecycle'),
  capitalization_creation_date TIMESTAMP OPTIONS(description = 'Date of creation of the CCSEXT ticket'),
  capitalization_assignee STRING OPTIONS(description = 'Assignee name via decryption'),
  capitalization_component_names ARRAY<STRING> OPTIONS(description = 'List of component names'),
  -- capitalization_subtasks ARRAY<STRING> OPTIONS(description = 'List of subtasks - pas dispo dans la raw')
)
PARTITION BY DATE(capitalization_creation_date)
AS

SELECT DISTINCT
  Key AS capitalization_key,
  project AS capitalization_project,
  summary AS capitalization_summary,
  status.name AS capitalization_status,
  created AS capitalization_creation_date,
  CASE -- decryptage des emails
    WHEN assignee.emailaddress = "4e7dd5f05ecb4c2a1c0c" THEN "Gregory GOMEZ"
    WHEN assignee.emailaddress = "043a1ed64c4b884de52e" THEN "Audrey TRAN"
    WHEN assignee.emailaddress = "d5159349ea0586f55756" THEN "Lucian SINESCU"
    WHEN assignee.emailaddress = "831e873e3c8396c11a08" THEN "Georges ASSANVO"
    WHEN assignee.emailaddress IS NULL THEN "Pas d'Assignee"
    ELSE "email à maj"
  END AS capitalization_assignee,
  ARRAY(SELECT c.name FROM UNNEST(components) AS c) AS capitalization_component_names,
FROM 
  `irn-79023-lqd-dat-ope-05.db_private_irn_79023_lqd_lup_quality_data.sdv_jira_current_copy`
WHERE 
  project = 'CAPITAMS'
  AND resolution != "Cancelled";
