---------------------------------------------------------
-- Step 0. Construction du Schéma de la table
---------------------------------------------------------

--- Ligne à changer: preprod / prod
CREATE OR REPLACE TABLE `irn-79023-lqd-dat-ope-05.db_domainrestricted_irn_79023_lqd_lup_quality_data.preprocessing_CAPITAMS_preprod`
--- Bien faire attention (1/1)
(
  capitams_key STRING OPTIONS(description = 'Unique Identification Number for a JIRA ticket'),
  capitams_project STRING OPTIONS(description = 'Business project identification'),
  capitams_criticity STRING OPTIONS(description = "Criticité du ticket CAPITAMS"),
  capitams_summary STRING OPTIONS(description = 'Description of the issue, useful to analyze KPI but not to calculate it'),
  capitams_status STRING OPTIONS(description = 'Status in the lifecycle'),
  capitams_creation_date TIMESTAMP OPTIONS(description = 'Date of creation of the CAPITAMS ticket'),
  capitams_assignee STRING OPTIONS(description = 'Assignee name via decryption'),
  capitams_component_names ARRAY<STRING> OPTIONS(description = 'List of component names'),
  capitams_gsfa STRING OPTIONS(description = "GSFA attaché au ticket"),
  capitams_capitalization_status STRING OPTIONS(description = "Statut de capit du ticket"),
  capitams_subtask STRING OPTIONS(description = "Subtask du ticket CAPITAMS. On doit avoir 0 ou 1 subtask maximum"),
  capitams_subtask_summary STRING OPTIONS(description = "Summary de la subtask"),
  capitams_history ARRAY<
    STRUCT<
      change_date TIMESTAMP,
      field STRING,
      from_string STRING,
      to_string STRING
    >
  > OPTIONS(description = 'Array of historical changes for the field components of the ticket'),
  capitams_bmir_encours_date TIMESTAMP OPTIONS(description = 'Date when a <BMIR en cours> component is added'),
  capitams_bmir_termine_date TIMESTAMP OPTIONS(description = 'Date when a <BMIR termine> component is added'),
  capitams_npk_date TIMESTAMP OPTIONS(description = 'Date when an NPK component is added'),

  PRIMARY KEY (capitams_key) NOT ENFORCED
)
PARTITION BY DATE(capitams_creation_date)
AS

---------------------------------------------------------
-- Step 1. Récupération des Assignees
---------------------------------------------------------

WITH assignee_map AS (
  SELECT *
  FROM UNNEST([
    STRUCT("4e7dd5f05ecb4c2a1c0c" AS emailaddress, "Gregory GOMEZ" AS assignee_name),
    STRUCT("043a1ed64c4b884de52e" AS emailaddress, "Audrey TRAN" AS assignee_name),
    STRUCT("d5159349ea0586f55756" AS emailaddress, "Lucian SINESCU" AS assignee_name),
    STRUCT("831e873e3c8396c11a08" AS emailaddress, "Georges ASSANVO" AS assignee_name),
    STRUCT("f5754ce37ccd50ae9484" AS emailaddress, "Sylvain CENTELLES" AS assignee_name),
    STRUCT("2c49792008525b2fe960" AS emailaddress, "Jean-Francois CAMART" AS assignee_name),
    STRUCT("9c2b474fc63a5146b269" AS emailaddress, "Cecile RENOTTE" AS assignee_name),
    STRUCT("9c3fb32967b3dfb4049f" AS emailaddress, "Raul-Cristian NEGREA" AS assignee_name)
  ])
),


---------------------------------------------------------
-- Step 2. Récupération des tickets CAPITAMS courants
--------------------------------------------------------

base_capitams_tickets AS (
  SELECT DISTINCT
    t.Key AS capitams_key,
    t.project AS capitams_project,
    t.criticity AS capitams_criticity,
    t.summary AS capitams_summary,
    t.status.name AS capitams_status,
    t.created AS capitams_creation_date,

    COALESCE(
      m.assignee_name,
      IF(t.assignee.emailaddress IS NULL, "Pas d'Assignee", "email à maj")
    ) AS capitams_assignee,

    ARRAY(
      SELECT c.name
      FROM UNNEST(t.components) AS c
    ) AS capitams_component_names,

    t.subtasks[SAFE_OFFSET(0)] AS capitams_subtask,
    subtask_ticket.summary AS capitams_subtask_summary

  FROM `irn-79023-lqd-dat-ope-05.db_private_irn_79023_lqd_lup_quality_data.sdv_jira_current_copy` AS t

  LEFT JOIN assignee_map AS m
    ON t.assignee.emailaddress = m.emailaddress

  LEFT JOIN `irn-79023-lqd-dat-ope-05.db_private_irn_79023_lqd_lup_quality_data.sdv_jira_current_copy` AS subtask_ticket
    ON t.subtasks[SAFE_OFFSET(0)] = subtask_ticket.Key

  WHERE t.project = 'CAPITAMS'
    AND (t.resolution IS NULL OR t.resolution != "Cancelled")
),


---------------------------------------------------------
-- Step 3. Calcul des champs GSFA / NPK / BMIR
---------------------------------------------------------


capitams_with_gsfa_bmir_npk AS (
  SELECT
    b.*,

    COALESCE(
      (
        SELECT component_name
        FROM UNNEST(b.capitams_component_names) AS component_name WITH OFFSET AS component_position
        WHERE component_name LIKE '%GSFA%'
        ORDER BY component_position
        LIMIT 1
      ),
      'No GSFA'
    ) AS capitams_gsfa,

    COALESCE(
      (
        SELECT component_name
        FROM UNNEST(b.capitams_component_names) AS component_name WITH OFFSET AS component_position
        WHERE component_name LIKE '%BMIR%' OR component_name LIKE '%NPK%'
        ORDER BY component_position
        LIMIT 1
      ),
      'No Capitalisation Status'
    ) AS capitams_capitalization_status

  FROM base_capitams_tickets AS b
),


---------------------------------------------------------
-- Step 4. Agrégation de l'historique des composants
---------------------------------------------------------


jira_history AS (
  SELECT
    KEY AS capitams_key,

    ARRAY_AGG(
      STRUCT(
        created AS change_date,
        field,
        fromString AS from_string,
        toString AS to_string
      )
      ORDER BY created DESC
    ) AS capitams_history,

    MIN(IF(field = 'components' AND REGEXP_CONTAINS(toString, r'BMIR_'), created, NULL))
      AS capitams_bmir_encours_date,

    MIN(IF(field = 'components' AND REGEXP_CONTAINS(toString, r'BMIRF_'), created, NULL))
      AS capitams_bmir_termine_date,

    MIN(IF(field = 'components' AND toString LIKE '%NPK%', created, NULL))
      AS capitams_npk_date

  FROM `irn-79023-lqd-dat-ope-05.db_private_irn_79023_lqd_lup_quality_data.sdv_jira_history_copy ` -- Trailing space preserved
  WHERE field = 'components'
  GROUP BY KEY
)

---------------------------------------------------------
-- Step 4. Assemblage final
---------------------------------------------------------

SELECT
  b.capitams_key,
  b.capitams_project,
  b.capitams_criticity,
  b.capitams_summary,
  b.capitams_status,
  b.capitams_creation_date,
  b.capitams_assignee,
  b.capitams_component_names,
  b.capitams_gsfa,
  b.capitams_capitalization_status,
  b.capitams_subtask,
  b.capitams_subtask_summary,
  h.capitams_history,
  h.capitams_bmir_encours_date,
  h.capitams_bmir_termine_date,
  h.capitams_npk_date

FROM capitams_with_gsfa_bmir_npk AS b
LEFT JOIN jira_history AS h
  USING (capitams_key);