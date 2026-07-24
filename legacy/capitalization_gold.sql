CREATE OR REPLACE TABLE `irn-79023-lqd-dat-ope-05.db_domainrestricted_irn_79023_lqd_lup_quality_data.capitalization_gold`
PARTITION BY DATE(sjt_creation_date)
CLUSTER BY sjt_status, sjt_linked_issue
AS

WITH 
  ---------------------------------------------------------
  -- 1. SOURCE Tickets VIES
  ---------------------------------------------------------
  software_issue_filtered AS (
    SELECT
      sjt_ticket_id, 
      sjt_project, 
      sjt_affected_versions, 
      sjt_product_lines, 
      sjt_domain,
      sjt_criticity,
      sjt_dor_opinion, 
      sjt_requesting_team, 
      sjt_status, 
      sjt_issue_type,
      sjt_summary, 
      sjt_lup_linked, 
      sjt_linked_issue, 
      sjt_creation_date,
      sjt_component_names,
      -- Calcul de sjt_plateau
      CASE 
        WHEN sjt_product_lines = 'CCS2' 
             AND sjt_affected_versions NOT LIKE 'A-IVI2_08.%' 
             AND sjt_affected_versions NOT LIKE 'A-IVI2_11.%'
             THEN 'CCS2'
        WHEN sjt_product_lines LIKE 'SWEET4%' 
             THEN 'SWEET400'
        ELSE NULL
      END AS sjt_plateau
        WHEN 
    FROM `irn-79023-lqd-dat-ope-05.db_domainrestricted_irn_79023_lqd_lup_quality_data.capitalization_silver`
    WHERE -- Filtrage des tickets
      sjt_project = 'VIES'
      AND sjt_issue_type = 'Bug'
      AND NOT REGEXP_CONTAINS(sjt_summary, r'(?i)GENERIC')
      AND (
          sjt_labels IS NULL 
          OR NOT REGEXP_CONTAINS(sjt_labels, r'(?i)unexploitable|duplicate')
      )
      AND (sjt_linked_issue IS NULL OR sjt_linked_issue NOT LIKE '%Duplicate%')
      AND sjt_status != 'Cancelled'
      AND (sjt_resolution IN ('Done', 'Cannot Reproduce') OR sjt_resolution IS NULL)
      AND sjt_creation_date >= '2022-01-01'
    GROUP BY 1,2,3,4,5,6,7,8,9,10,11,12,13,14,15 
  ),

  ---------------------------------------------------------
  -- 2. SOURCE CAPITALIZATION : Analyse des tickets CAPITAMS
  ---------------------------------------------------------
  capitalization_metrics AS (
    SELECT
      capitalization_key, capitalization_project, capitalization_summary,
      capitalization_status, capitalization_creation_date,
      MIN(CASE 
            WHEN field = 'components' AND `toString` IS NOT NULL 
            THEN created 
          END) AS capit_initialization_end_date
    FROM `irn-79023-lqd-dat-ope-05.db_domainrestricted_irn_79023_lqd_lup_quality_data_question.d_software_capitalization`
    WHERE capitalization_project = 'CAPITAMS'
      AND capitalization_creation_date >= '2022-01-01'
    GROUP BY 1,2,3,4,5
  ),

  ---------------------------------------------------------
  -- 3. SOURCE INCIDENT : Tickets CCSEXT
  ---------------------------------------------------------
  incident_data AS (
    SELECT
      incident_key, incident_project, incident_summary,
      incident_program, incident_status, incident_label, incident_creation_date
    FROM `irn-79023-lqd-dat-ope-05.db_domainrestricted_irn_79023_lqd_lup_quality_data_question.d_software_incident`
    WHERE incident_project = 'CCSEXT'
      AND incident_creation_date >= '2022-01-01'
  ),

  ---------------------------------------------------------
  -- 4. SOURCE LUP : Référentiel des questions
  ---------------------------------------------------------
  lup_questions AS (
    SELECT
      question_number, wording_question, creation_date_question,
      capitalization_status AS capitalization_status_lup,
      status_code_question, status_label_question
    FROM `irn-79023-lqd-dat-ope-05.db_domainrestricted_irn_79023_lqd_lup_quality_data_question.d_lup_questions`
  ),

  ---------------------------------------------------------
  -- 5. SOURCE NRL : Extraction du premier NRL par LUP
  ---------------------------------------------------------
  nrl_first_occurrence AS (
    SELECT
      question_number,
      ARRAY_AGG(
        STRUCT(
          nrl_number, status_code_nrl, status_label_nrl,
          nrl_customer_effect, creation_date_nrl
        )
        ORDER BY SAFE_CAST(nrl_number AS INT64) ASC
        LIMIT 1
      )[SAFE_OFFSET(0)] AS first_nrl
    FROM `irn-79023-lqd-dat-ope-05.db_domainrestricted_irn_79023_lqd_lup_quality_data_nrl.nrl`
    WHERE question_number IS NOT NULL
    GROUP BY question_number
  )

-----------------------------------------------------------
-- 6. ASSEMBLAGE FINAL
-----------------------------------------------------------
SELECT DISTINCT
  si.*,
  lup.wording_question,
  lup.capitalization_status_lup,
  lup.creation_date_question,
  lup.status_code_question,
  lup.status_label_question,
  n.first_nrl.nrl_number,
  n.first_nrl.status_code_nrl,
  n.first_nrl.status_label_nrl,
  n.first_nrl.nrl_customer_effect,
  n.first_nrl.creation_date_nrl,
  sc.capitalization_key,
  sc.capitalization_project,
  sc.capitalization_summary,
  sc.capitalization_status,
  sc.capitalization_creation_date,
  sc.capit_initialization_end_date,
  i.incident_project,
  i.incident_summary,
  i.incident_program,
  i.incident_status,
  i.incident_label,
  i.incident_creation_date
FROM software_issue_filtered si
LEFT JOIN capitalization_metrics sc  ON si.sjt_linked_issue = sc.capitalization_key
LEFT JOIN incident_data i          ON si.sjt_linked_issue = i.incident_key
LEFT JOIN lup_questions lup        ON si.sjt_lup_linked = lup.question_number
LEFT JOIN nrl_first_occurrence n     ON si.sjt_lup_linked = n.question_number
WHERE (
  si.sjt_plateau IS NOT NULL
  AND si.sjt_status IN ("Ready for Deployment", "Deploying", "Closed")
);

-- 7. Ajout de la Primary Key APRES la création
ALTER TABLE `irn-79023-lqd-dat-ope-05.db_domainrestricted_irn_79023_lqd_lup_quality_data.capitalization_gold`
ADD PRIMARY KEY (sjt_ticket_id) NOT ENFORCED;