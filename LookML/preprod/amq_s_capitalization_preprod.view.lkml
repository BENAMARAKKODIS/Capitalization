# Ligne à changer: preprod / prod

view: amq_s_capitalization_preprod {
  sql_table_name: `irn-79023-lqd-dat-ope-05.db_domainrestricted_irn_79023_lqd_lup_quality_data.capitalization_silver` ;;
# Bien faire attention (1/2)
  dimension: capitams_assignee {
    type: string
    description: "Assignee name via decryption"
    sql: ${TABLE}.capitams_assignee ;;
  }
  dimension: capitams_component_names {
    hidden: yes
    sql: ${TABLE}.capitams_component_names ;;
  }
  dimension: capitams_gsfa {
    type: string
    sql: ${TABLE}.capitams_gsfa ;;
  }
  dimension: capitams_capitalization_status {
    type: string
    sql: ${TABLE}.capitams_capitalization_status ;;
  }
  dimension: capitams_key {
    type: string
    description: "Unique Identification Number for a CAPITAMS ticket"
    sql: ${TABLE}.capitams_key ;;
  }
  dimension: capitams_nrl {
    type: string
    description: "NRL Reference"
    sql: ${TABLE}.capitams_nrl ;;
  }
  dimension: capitams_status {
    type: string
    description: "Status in the workflow"
    sql: ${TABLE}.capitams_status ;;
  }
  dimension: capitams_summary {
    type: string
    description: "Description of the issue, useful to analyze KPI but not to calculate it"
    sql: ${TABLE}.capitams_summary ;;
  }
  dimension: top_priority {
    type: string
    description: "Statut de la capitalisation"
    sql: ${TABLE}.top_priority ;;
  }
  dimension: vies_affected_versions {
    type: string
    description: "Scope of the ticket, key information for scoping KPIs"
    sql: ${TABLE}.vies_affected_versions ;;
  }
  dimension: vies_component_names {
    hidden: yes
    sql: ${TABLE}.vies_component_names ;;
  }
  dimension_group: vies_creation {
    type: time
    description: "Internal field for partitioning"
    timeframes: [raw, time, date, week, month, quarter, year]
    sql: ${TABLE}.vies_creation_date ;;
  }
  dimension: vies_criticity {
    type: string
    description: "Criticity of the ticket"
    sql: ${TABLE}.vies_criticity ;;
  }
  dimension: vies_domain {
    type: string
    description: "Domain of the ticket, key information for scoping KPIs"
    sql: ${TABLE}.vies_domain ;;
  }
  dimension: vies_dor_opinion {
    type: string
    description: "Decision to launch Capitalization"
    sql: ${TABLE}.vies_dor_opinion ;;
  }
  dimension: vies_labels {
    type: string
    description: "Labels of the Ticket flattened as a string"
    sql: ${TABLE}.vies_labels ;;
  }
  dimension: vies_lup_linked {
    type: string
    description: "LUP linked to this VIES ticket."
    sql: ${TABLE}.vies_lup_linked ;;
  }
  dimension: vies_plateau {
    type: string
    description: "Plateau calculated from product line and IVI2 SW version"
    sql: ${TABLE}.vies_plateau ;;
  }
  dimension: vies_product_lines {
    type: string
    description: "Product line associated with the ticket"
    sql: ${TABLE}.vies_product_lines ;;
  }
  dimension: vies_requesting_teams {
    hidden: yes
    sql: ${TABLE}.vies_requesting_teams ;;
  }
  dimension: vies_status {
    type: string
    description: "Status in the workflow"
    sql: ${TABLE}.vies_status ;;
  }
  dimension: vies_summary {
    type: string
    description: "Description of the issue"
    sql: ${TABLE}.vies_summary ;;
  }
  dimension: vies_ticket_id {
    type: string
    primary_key: yes
    description: "Unique Identification Number for a VIES ticket"
    sql: ${TABLE}.vies_ticket_id ;;
  }
  dimension: nrl_date_statut_valide {
    type: date
    label: "NRL Date Statut Valide"
    sql: ${TABLE}.nrl_date_statut_valide ;;
  }
  dimension: kpi_perfo_v0 {
    type: number
    description: "Duration of the v0 phase in calendar days"
    sql: ${TABLE}.kpi_perfo_v0 ;;
  }
  dimension: kpi_perfo_v1 {
    type: number
    description: "Duration of the v1 phase in calendar days"
    sql: ${TABLE}.kpi_perfo_v1 ;;
  }
  dimension: kpi_perfo_v2 {
    type: number
    description: "Duration of the v2 phase in calendar days"
    sql: ${TABLE}.kpi_perfo_v2 ;;
  }

  # Placeholders for calculated dimensions

  dimension: vies_url { type: string }
  dimension: capitams_url { type: string }

  measure: count {
    type: count
    drill_fields: [
      vies_ticket_id,
      vies_summary,
      vies_url,
      vies_status,
      vies_domain,
      vies_product_lines,
      capitams_key,
      capitams_summary,
      capitams_status,
      capitams_url
    ]
  }
}

# Array views

# Ligne à changer: preprod / prod
view: amq_s_capitalization_preprod__vies_component_names {
  dimension: amq_s_capitalization_preprod__vies_component_names {
    type: string
    description: "List of component names"
    sql: ${TABLE} ;;
  }
}

view: amq_s_capitalization_preprod__vies_requesting_teams {
  dimension: amq_s_capitalization_preprod__vies_requesting_teams {
    type: string
    description: "Who identified the issue, key information for scoping KPIs"
    sql: ${TABLE} ;;
  }
}

view: amq_s_capitalization_preprod__capitams_component_names {
  dimension: amq_s_capitalization_preprod__capitams_component_names {
    type: string
    description: "List of component names"
    sql: ${TABLE} ;;
  }
}
# Bien faire attention (2/2)
