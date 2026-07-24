CREATE OR REPLACE TABLE `irn-79023-lqd-dat-ope-05.db_domainrestricted_irn_79023_lqd_lup_quality_data.preprocessing_VIES`
(
  vies_ticket_id         STRING NOT NULL OPTIONS(description = 'Unique Identification Number for a JIRA ticket'),
  vies_project               STRING OPTIONS(description = 'Business project identification'),
  vies_summary               STRING OPTIONS(description = 'Description of the issue'),
  vies_affected_versions     STRING OPTIONS(description = 'Scope of the ticket, key information for scoping KPIs'),
  vies_product_lines         STRING OPTIONS(description = 'Product line associated with the ticket'),
  vies_plateau               STRING OPTIONS(description = 'Plateau calculated from product line and IVI2 SW version'),
  vies_domain                STRING OPTIONS(description = 'Domain of the ticket, key information for scoping KPIs'),
  vies_criticity             STRING OPTIONS(description = 'Criticity of the ticket'),
  vies_dor_opinion           STRING OPTIONS(description = 'Decision to launch Capitalization'),
  vies_requesting_team       STRING OPTIONS(description = 'Who identified the issue, key information for scoping KPIs'),
  vies_status                STRING OPTIONS(description = 'Status in the lifecycle'),
  vies_resolution            STRING OPTIONS(description = 'Resolution status (Done, Fixed, etc.)'),
  vies_issue_type            STRING OPTIONS(description = 'Type of issue'),
  vies_subtasks              ARRAY<STRING> OPTIONS(description = 'List of subtasks of the Jira ticket'),
  vies_labels                STRING OPTIONS(description = 'Labels of the Ticket flattened as a string'),
  vies_lup_Linked            STRING OPTIONS(description = 'List of LUP linked to this VIES ticket.'),
  vies_linked_issue          ARRAY<STRING> OPTIONS(description = 'List of JIRA tickets linked to this VIES ticket'), 
  vies_link_type             ARRAY<STRING> OPTIONS(description = 'Type of links (Duplicate, Relates, etc.)'), 
  vies_creation_date         TIMESTAMP OPTIONS(description = 'Date of creation of the VIES ticket'),
  vies_assignee_email        STRING OPTIONS(description = 'Encrypted email of the assignee'),
  vies_component_names       ARRAY<STRING> OPTIONS(description = 'List of component names'),
  PRIMARY KEY (vies_ticket_id) NOT ENFORCED
)
PARTITION BY DATE(vies_creation_date)
AS

WITH 
  ---------------------------------------------------------
  -- Step 1. Get raw base tickets and apply filters
  ---------------------------------------------------------
  base_vies_tickets AS (
    SELECT *
    FROM `irn-79023-lqd-dat-ope-05.db_private_irn_79023_lqd_lup_quality_data.isit_jira_current_copy`
    WHERE project = 'VIES'
      AND issuetype = 'Bug'
      AND status.name != 'Cancelled'
      AND (resolution IN ('Done', 'Cannot Reproduce') OR resolution IS NULL)
      AND created >= '2022-01-01'
      AND NOT REGEXP_CONTAINS(summary, r'(?i)GENERIC')
      AND NOT EXISTS (SELECT 1 FROM UNNEST(labels) l WHERE REGEXP_CONTAINS(l, r'(?i)unexploitable|duplicate'))
      AND NOT EXISTS (SELECT 1 FROM UNNEST(issuelinks) link WHERE REGEXP_CONTAINS(link.type, 'duplicates'))
      AND status.name IN ("Ready for Deployment", "Deploying", "Closed")
  ),

  ---------------------------------------------------------
  -- Step 2. Extract LUP from subtasks
  ---------------------------------------------------------
  child_summaries AS (
    SELECT key, summary
    FROM `irn-79023-lqd-dat-ope-05.db_private_irn_79023_lqd_lup_quality_data.isit_jira_current_copy`
    WHERE REGEXP_CONTAINS(summary, r'(?i)Q0[0-9]+')
  ),

  lup_extracted_from_subtasks AS (
    SELECT 
      b.key AS vies_ticket_id,
      ARRAY_AGG(
        CASE 
          WHEN ARRAY_LENGTH(REGEXP_EXTRACT_ALL(c.summary, r'(?i)Q0[0-9]+')) = 1 THEN REGEXP_EXTRACT(c.summary, r'(?i)Q0[0-9]+')
          WHEN ARRAY_LENGTH(REGEXP_EXTRACT_ALL(c.summary, r'(?i)Q0[0-9]+')) >= 2 THEN '2 lup id detected correct jira ticket'
          ELSE NULL
        END IGNORE NULLS
      ) AS vies_lup_linked_array
    FROM base_vies_tickets b
    CROSS JOIN UNNEST(b.subtasks) AS st_key
    INNER JOIN child_summaries c ON st_key = c.key
    GROUP BY b.key
  ),

  ---------------------------------------------------------
  -- Step 3. Assemble data (Calculations happen here)
  ---------------------------------------------------------
  final_vies_data AS (
    SELECT
      I.key AS vies_ticket_id,
      I.project AS vies_project,
      I.summary AS vies_summary,
      ARRAY_TO_STRING(I.versions, ',') AS vies_affected_versions,
      ARRAY_TO_STRING(I.product_line_s, ',') AS vies_product_lines,

      -- Evaluated Plateau Logic
      CASE 
        WHEN ARRAY_TO_STRING(I.product_line_s, ',') LIKE '%CCS2%'
             AND ARRAY_TO_STRING(I.versions, ',') NOT LIKE '%A-IVI2_08.%' 
             AND ARRAY_TO_STRING(I.versions, ',') NOT LIKE '%A-IVI2_11.%' THEN 'CCS2'
        WHEN ARRAY_TO_STRING(I.product_line_s, ',') LIKE '%SWEET4%' THEN 'SWEET400'
        ELSE NULL
      END AS vies_plateau,

      CAST(I.domain AS STRING) AS vies_domain,
      CAST(I.criticity AS STRING) AS vies_criticity,

      -- DOR Opinion
      COALESCE(
        (SELECT 'VIES ready for capitalisation' FROM UNNEST(I.dor) d WHERE d.name = 'Yes, favourable opinion' AND CAST(d.checked AS STRING) = 'true' LIMIT 1),
        (SELECT 'VIES not to capitalise' FROM UNNEST(I.dor) d WHERE d.name = 'No, defavourable opinion' AND CAST(d.checked AS STRING) = 'true' LIMIT 1),
        'VIES without Plateau DOR'
      ) AS vies_dor_opinion,

      ARRAY_TO_STRING(I.requesting_team, ',') AS vies_requesting_team,
      I.status.name AS vies_status,
      I.resolution AS vies_resolution,
      I.issuetype AS vies_issue_type,
      I.subtasks AS vies_subtasks,
      ARRAY_TO_STRING(I.labels, ', ') AS vies_labels,

      -- LUP Linking Evaluation
      COALESCE(
        lup.vies_lup_linked_array[SAFE_OFFSET(0)],
        CASE 
          WHEN ARRAY_LENGTH(REGEXP_EXTRACT_ALL(I.summary, r'(?i)Q0[0-9]+')) = 1 THEN REGEXP_EXTRACT(I.summary, r'(?i)Q0[0-9]+')
          WHEN ARRAY_LENGTH(REGEXP_EXTRACT_ALL(I.summary, r'(?i)Q0[0-9]+')) >= 2 THEN '2 lup id detected correct jira ticket'
          ELSE NULL 
        END
      ) AS vies_lup_linked,

      ARRAY(SELECT link.linked_issue FROM UNNEST(I.issuelinks) link) AS vies_linked_issue,
      ARRAY(SELECT link.type FROM UNNEST(I.issuelinks) link) AS vies_link_type,

      I.created AS vies_creation_date,
      I.assignee.emailaddress AS vies_assignee_email,
      ARRAY(SELECT c.name FROM UNNEST(I.components) AS c) AS vies_component_names

    FROM base_vies_tickets I
    LEFT JOIN lup_extracted_from_subtasks lup ON I.key = lup.vies_ticket_id
  )

---------------------------------------------------------
-- Step 4. Final filter for non-null plateaux
---------------------------------------------------------
SELECT * FROM final_vies_data 
WHERE vies_plateau IS NOT NULL;