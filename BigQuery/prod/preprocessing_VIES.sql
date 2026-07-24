---------------------------------------------------------
-- Step 0. Construction du Schéma de la table
---------------------------------------------------------

--- Ligne à changer: preprod / prod
CREATE OR REPLACE TABLE `irn-79023-lqd-dat-ope-05.db_domainrestricted_irn_79023_lqd_lup_quality_data.preprocessing_VIES`
--- Bien faire attention (1/1)
(
  vies_ticket_id         STRING NOT NULL OPTIONS(description = 'Unique Identification Number for a JIRA ticket'),
  vies_project           STRING OPTIONS(description = 'Business project identification'),
  vies_summary           STRING OPTIONS(description = 'Description of the issue'),
  vies_affected_versions STRING OPTIONS(description = 'Scope of the ticket, key information for scoping KPIs'),
  vies_product_lines     STRING OPTIONS(description = 'Product line associated with the ticket'),
  vies_plateau           STRING OPTIONS(description = 'Plateau calculated from product line and IVI2 SW version'),
  vies_domain            STRING OPTIONS(description = 'Domain of the ticket'),
  vies_criticity         STRING OPTIONS(description = 'Criticity of the ticket'),
  vies_dor_opinion       STRING OPTIONS(description = 'Decision to launch Capitalization'),
  vies_requesting_teams  ARRAY<STRING> OPTIONS(description = 'Teams that identified the issue (raw array)'),
  vies_status            STRING OPTIONS(description = 'Current lifecycle status'),
  vies_resolution        STRING OPTIONS(description = 'Resolution status (Done, Fixed, etc.)'),
  vies_issue_type        STRING OPTIONS(description = 'Type of issue'),
  vies_subtasks          ARRAY<STRING> OPTIONS(description = 'List of subtasks'),
  vies_labels            STRING OPTIONS(description = 'Labels flattened as a string'),
  vies_lup_linked        STRING OPTIONS(description = 'Detected LUP linked to this ticket'),
  vies_linked_issues     ARRAY<STRING> OPTIONS(description = 'Linked JIRA tickets'), 
  vies_link_types        ARRAY<STRING> OPTIONS(description = 'Types of links'), 
  vies_creation_date     TIMESTAMP OPTIONS(description = 'Creation date of the ticket'),
  vies_assignee_email    STRING OPTIONS(description = 'Encrypted assignee email'),
  vies_component_names   ARRAY<STRING> OPTIONS(description = 'List of component names'),

  vies_history ARRAY<
    STRUCT<
      change_date TIMESTAMP, 
      field STRING, 
      from_string STRING, 
      to_string STRING
    >
  > OPTIONS(description = 'History of status and DoR changes'),

  vies_dor_yes_favourable_date TIMESTAMP OPTIONS(description = 'First date when DoR became "Yes, favourable opinion"'),
  vies_ready_for_deployment_date TIMESTAMP OPTIONS(description = 'First date when status became "Ready for Deployment"'),
  vies_v0_starting_date TIMESTAMP OPTIONS(description = 'Max of DoR favourable date and Ready for Deployment date'),

  PRIMARY KEY (vies_ticket_id) NOT ENFORCED
)

PARTITION BY DATE(vies_creation_date)
AS

WITH

---------------------------------------------------------
-- Step 1. Extract base tickets and apply filters
---------------------------------------------------------
base_vies_tickets AS (
  SELECT *
  FROM `irn-79023-lqd-dat-ope-05.db_private_irn_79023_lqd_lup_quality_data.isit_jira_current_copy`
  WHERE project = 'VIES'
    AND issuetype = 'Bug'
    AND (resolution IN ('Done', 'Cannot Reproduce') OR resolution IS NULL)
    AND created >= TIMESTAMP('2022-01-01')
    AND NOT REGEXP_CONTAINS(summary, r'(?i)GENERIC')
    AND NOT EXISTS (
      SELECT 1 FROM UNNEST(labels) l 
      WHERE REGEXP_CONTAINS(l, r'(?i)unexploitable|duplicate')
    )
    AND NOT EXISTS (
      SELECT 1 FROM UNNEST(issuelinks) link 
      WHERE REGEXP_CONTAINS(link.type, 'duplicates')
    )
    AND status.name IN ("Ready for Deployment", "Deploying", "Closed")
),

---------------------------------------------------------
-- Step 2. Retrieve subtasks summaries (used for LUP detection)
---------------------------------------------------------
child_summaries AS (
  SELECT key, summary
  FROM `irn-79023-lqd-dat-ope-05.db_private_irn_79023_lqd_lup_quality_data.isit_jira_current_copy`
  WHERE REGEXP_CONTAINS(summary, r'(?i)Q0[0-9]+')
),

---------------------------------------------------------
-- Step 3. Extract LUP from subtasks (deterministic logic)
---------------------------------------------------------
lup_extracted_from_subtasks AS (
  SELECT 
    b.key AS vies_ticket_id,

    CASE
      WHEN COUNT(DISTINCT lup_id) = 1 
        THEN ARRAY_AGG(DISTINCT lup_id)[SAFE_OFFSET(0)]

      WHEN COUNT(DISTINCT lup_id) >= 2 
        THEN CONCAT('Several LUP: ', STRING_AGG(DISTINCT lup_id, ', '))

      ELSE NULL
    END AS vies_lup_linked_from_subtasks

  FROM base_vies_tickets b
  CROSS JOIN UNNEST(b.subtasks) AS st_key
  INNER JOIN child_summaries c 
    ON st_key = c.key
  CROSS JOIN UNNEST(REGEXP_EXTRACT_ALL(c.summary, r'(?i)Q0[0-9]+')) AS lup_id
  GROUP BY b.key
),

---------------------------------------------------------
-- Step 4. Aggregate history into arrays
---------------------------------------------------------
jira_history_nested AS (
  SELECT 
    key AS histo_vies_ticket_id,

    ARRAY_AGG(
      STRUCT(
        created AS change_date,
        field AS field,
        fromString AS from_string,
        toString AS to_string
      )
      ORDER BY created DESC
    ) AS history_array

  FROM `irn-79023-lqd-dat-ope-05.db_private_irn_79023_lqd_lup_quality_data.isit_jira_history_copy`
  WHERE field IN ('status', 'dor')
  GROUP BY key
),

---------------------------------------------------------
-- Step 5. Final assembly (without v0 date)
---------------------------------------------------------
final_without_v0 AS (
  SELECT
    I.key AS vies_ticket_id,
    I.project AS vies_project,
    I.summary AS vies_summary,

    ARRAY_TO_STRING(I.versions, ', ') AS vies_affected_versions,
    ARRAY_TO_STRING(I.product_line_s, ', ') AS vies_product_lines,

    ---------------------------------------------------------
    -- Plateau computation
    ---------------------------------------------------------
    CASE 
      WHEN ARRAY_TO_STRING(I.product_line_s, ',') LIKE '%CCS2%'
           AND ARRAY_TO_STRING(I.versions, ',') NOT LIKE '%A-IVI2_08.%'
           AND ARRAY_TO_STRING(I.versions, ',') NOT LIKE '%A-IVI2_11.%'
        THEN 'CCS2'

      WHEN ARRAY_TO_STRING(I.product_line_s, ',') LIKE '%SWEET4%' 
        THEN 'SWEET400'

      ELSE NULL
    END AS vies_plateau,

    CAST(I.domain AS STRING) AS vies_domain,
    CAST(I.criticity AS STRING) AS vies_criticity,

    ---------------------------------------------------------
    -- DoR interpretation
    ---------------------------------------------------------
    COALESCE(
      (
        SELECT 'VIES ready for capitalisation'
        FROM UNNEST(I.dor) d
        WHERE d.name = 'Yes, favourable opinion'
          AND CAST(d.checked AS STRING) = 'true'
        LIMIT 1
      ),
      (
        SELECT 'VIES not to capitalise'
        FROM UNNEST(I.dor) d
        WHERE d.name = 'No, defavourable opinion'
          AND CAST(d.checked AS STRING) = 'true'
        LIMIT 1
      ),
      'VIES without Plateau DOR'
    ) AS vies_dor_opinion,

    I.requesting_team AS vies_requesting_teams, -- array de plusieurs teams

    I.status.name AS vies_status,
    I.resolution AS vies_resolution,
    I.issuetype AS vies_issue_type,
    I.subtasks AS vies_subtasks,
    ARRAY_TO_STRING(I.labels, ', ') AS vies_labels,

    ---------------------------------------------------------
    -- LUP extraction (prioritizing subtasks)
    ---------------------------------------------------------
    COALESCE(
      lup.vies_lup_linked_from_subtasks,

      CASE 
        WHEN ARRAY_LENGTH(REGEXP_EXTRACT_ALL(I.summary, r'(?i)Q0[0-9]+')) = 1 
          THEN REGEXP_EXTRACT(I.summary, r'(?i)Q0[0-9]+')

        WHEN ARRAY_LENGTH(REGEXP_EXTRACT_ALL(I.summary, r'(?i)Q0[0-9]+')) >= 2 
          THEN CONCAT(
            'Several LUP: ',
            (
              SELECT STRING_AGG(DISTINCT lup_id, ', ')
              FROM UNNEST(REGEXP_EXTRACT_ALL(I.summary, r'(?i)Q0[0-9]+')) AS lup_id
            )
          )

        ELSE NULL 
      END
    ) AS vies_lup_linked,

    ARRAY(SELECT link.linked_issue FROM UNNEST(I.issuelinks) link) AS vies_linked_issues,
    ARRAY(SELECT link.type FROM UNNEST(I.issuelinks) link) AS vies_link_types,

    I.created AS vies_creation_date,
    I.assignee.emailaddress AS vies_assignee_email,

    ARRAY(SELECT c.name FROM UNNEST(I.components) AS c) AS vies_component_names,

    h.history_array AS vies_history,

    ---------------------------------------------------------
    -- Key dates computation
    ---------------------------------------------------------
    -- First DoR favourable date
    (
      SELECT MIN(hist.change_date)
      FROM UNNEST(h.history_array) AS hist
      WHERE hist.field = 'dor'
        AND hist.to_string LIKE '%[Checked] Yes, favourable opinion%'
    ) AS vies_dor_yes_favourable_date,

    -- First Ready for Deployment date
    (
      SELECT MIN(hist.change_date)
      FROM UNNEST(h.history_array) AS hist
      WHERE hist.field = 'status'
        AND hist.to_string = 'Ready for Deployment'
    ) AS vies_ready_for_deployment_date

  FROM base_vies_tickets I
  LEFT JOIN lup_extracted_from_subtasks lup
    ON I.key = lup.vies_ticket_id
  LEFT JOIN jira_history_nested h
    ON I.key = h.histo_vies_ticket_id
)

---------------------------------------------------------
-- Step 6. Add v0 starting date
---------------------------------------------------------
SELECT
  *,
  GREATEST(
    vies_dor_yes_favourable_date,
    vies_ready_for_deployment_date
  ) AS vies_v0_starting_date

FROM final_without_v0
WHERE vies_plateau IS NOT NULL;