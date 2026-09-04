# Ligne à changer: preprod / prod

view: suivi_evo_historization {
  sql_table_name: `irn-79023-lqd-dat-ope-05.db_domainrestricted_irn_79023_lqd_lup_quality_data.suivi_evo_historization` ;;

  # ── PRIMARY KEY ─────────────────────────────────────────────────
  dimension: pk {
    type: string
    primary_key: yes
    hidden: yes
    sql: CONCAT(${TABLE}.vies_ticket_id, ${TABLE}.snapshot_week) ;;
  }

  # ── SNAPSHOT DIMENSIONS ─────────────────────────────────────────
  dimension: snapshot_week {
    type: string
    label: "Semaine"
    sql: ${TABLE}.snapshot_week ;;
  }

  dimension_group: date_filter {
    type: time
    timeframes: [date, week, month, quarter, year]
    datatype: date
    sql: ${TABLE}.snapshot_date ;;
    label: "Date"
  }

  # ── VIES DIMENSIONS ─────────────────────────────────────────────
  dimension: vies_ticket_id {
    type: string
    label: "VIES Key"
    sql: ${TABLE}.vies_ticket_id ;;
    link: {
      label: "Voir dans Jira"
      url: "https://jira.dt.renault.com/browse/{{ value }}"
    }
  }

  dimension: vies_domain {
    type: string
    label: "Domain"
    sql: ${TABLE}.vies_domain ;;
  }

  dimension: vies_criticity {
    type: string
    label: "Criticity"
    sql: ${TABLE}.vies_criticity ;;
  }

  dimension: vies_status {
    type: string
    label: "VIES Status"
    sql: ${TABLE}.vies_status ;;
  }

  dimension: vies_dor_opinion {
    type: string
    label: "DOR Opinion"
    sql: ${TABLE}.vies_dor_opinion ;;
  }

  dimension: vies_requesting_teams {
    hidden: yes
    sql: ${TABLE}.vies_requesting_teams ;;
  }

  dimension: vies_component_names {
    hidden: yes
    sql: ${TABLE}.vies_component_names ;;
  }

  dimension: top_priority {
    type: string
    label: "Top Priority"
    sql: ${TABLE}.top_priority ;;
  }

  # ── CAPITAMS DIMENSIONS ─────────────────────────────────────────
  dimension: capitams_key {
    type: string
    label: "CAPITAMS Key"
    sql: ${TABLE}.capitams_key ;;
    link: {
      label: "Voir dans Jira"
      url: "https://jira.dt.renault.com/browse/{{ value }}"
    }
  }

  dimension: capitams_status {
    type: string
    label: "CAPITAMS Status"
    sql: ${TABLE}.capitams_status ;;
  }

  dimension: capitams_capitalization_status {
    type: string
    label: "Capitalization Status"
    sql: ${TABLE}.capitams_capitalization_status ;;
  }

  dimension: capitams_gsfa {
    type: string
    label: "GSFA"
    sql: ${TABLE}.capitams_gsfa ;;
  }

  dimension: capitams_nrl {
    type: string
    label: "NRL"
    sql: ${TABLE}.capitams_nrl ;;
  }

  dimension: capitams_component_names {
    hidden: yes
    sql: ${TABLE}.capitams_component_names ;;
  }

  # ── EXISTING MEASURES ───────────────────────────────────────────
  measure: count {
    type: count_distinct
    sql: ${vies_ticket_id} ;;
    label: "🔵 Total Backlog"
    drill_fields: [vies_ticket_id, vies_domain, vies_status, top_priority, capitams_key]
  }

  measure: count_top_prio {
    type: count_distinct
    sql: CASE WHEN ${top_priority} IS NOT NULL THEN ${vies_ticket_id} END ;;
    label: "🟠 Top Prio"
    drill_fields: [vies_ticket_id, vies_domain, vies_status, top_priority, capitams_key]
  }

  measure: count_green {
    type: count_distinct
    sql: CASE WHEN
      ${top_priority} IS NOT NULL
      AND ${capitams_key} IS NOT NULL
      AND (${capitams_capitalization_status} IS NULL
        OR ${capitams_capitalization_status} = ''
        OR ${capitams_capitalization_status} = 'No Capitalisation Status'
        OR ${capitams_capitalization_status} = 'BMIR_EN COURS DE CAPITALISATION')
      THEN ${vies_ticket_id} END ;;
    label: "🟢 Capit en cours"
    drill_fields: [vies_ticket_id, vies_domain, vies_status, capitams_key, capitams_capitalization_status]
  }

  measure: count_red {
    type: count_distinct
    sql: CASE WHEN
      ${top_priority} IS NOT NULL
      AND ${capitams_key} IS NOT NULL
      AND (CONTAINS_SUBSTR(IFNULL(${capitams_capitalization_status}, ''), 'BMIRF')
        OR CONTAINS_SUBSTR(IFNULL(${capitams_capitalization_status}, ''), 'NPK'))
      THEN ${vies_ticket_id} END ;;
    label: "🔴 Capit terminée"
    drill_fields: [vies_ticket_id, vies_domain, vies_status, capitams_key, capitams_capitalization_status]
  }

  # ── KPI 3C MEASURES ─────────────────────────────────────────────
  measure: count_vies_ready {

    type: count_distinct
    label: "🔵 VIES Ready for Capitalization"
    group_label: "KPI 3C"
    sql: CASE WHEN
          ${TABLE}.vies_dor_opinion = 'VIES ready for capitalisation'
          AND ${TABLE}.vies_status IN ('Ready for Deployment', 'Deploying', 'Closed')
          THEN ${TABLE}.vies_ticket_id END ;;
    drill_fields: [snapshot_week, vies_ticket_id, vies_domain, vies_criticity, vies_status, capitams_key]
  }

  measure: count_capitams_created {
    type: count_distinct
    label: "🟢 CapitAMS Tickets Created"
    group_label: "KPI 3C"
    sql: CASE WHEN
          ${TABLE}.vies_dor_opinion = 'VIES ready for capitalisation'
          AND ${TABLE}.vies_status IN ('Ready for Deployment', 'Deploying', 'Closed')
          AND ${TABLE}.capitams_key IS NOT NULL
          THEN ${TABLE}.vies_ticket_id END ;;
    drill_fields: [snapshot_week, vies_ticket_id, vies_domain, vies_criticity, capitams_key, capitams_status, capitams_capitalization_status]
  }

  measure: count_nrl_npk {
    type: count_distinct
    label: "🟠 NRL Validated + NPK"
    group_label: "KPI 3C"
    sql: CASE WHEN
          ${TABLE}.vies_dor_opinion = 'VIES ready for capitalisation'
          AND ${TABLE}.vies_status IN ('Ready for Deployment', 'Deploying', 'Closed')
          AND ${TABLE}.capitams_key IS NOT NULL
          AND (
            ${TABLE}.capitams_nrl IS NOT NULL
            OR CONTAINS_SUBSTR(IFNULL(${TABLE}.capitams_capitalization_status, ''), 'NPK')
          )
          THEN ${TABLE}.vies_ticket_id END ;;
    drill_fields: [snapshot_week, vies_ticket_id, vies_domain, vies_criticity, capitams_key, capitams_nrl, capitams_capitalization_status]
  }

  measure: coverage_pct {
    type: number
    label: "Coverage %"
    group_label: "KPI 3C"
    sql: SAFE_DIVIDE(${count_capitams_created}, NULLIF(${count_vies_ready}, 0)) * 100 ;;
    value_format: "0.0\"%\""
  }

  measure: completeness_pct {
    type: number
    label: "Completeness %"
    group_label: "KPI 3C"
    sql: SAFE_DIVIDE(${count_nrl_npk}, NULLIF(${count_capitams_created}, 0)) * 100 ;;
    value_format: "0.0\"%\""
  }
}

# ── ARRAY VIEWS ─────────────────────────────────────────────────
view: suivi_evo_historization__vies_requesting_teams {
  dimension: suivi_evo_historization__vies_requesting_teams {
    type: string
    label: "Requesting Team"
    sql: ${TABLE} ;;
  }
}

view: suivi_evo_historization__vies_component_names {
  dimension: suivi_evo_historization__vies_component_names {
    type: string
    label: "Vies Component Name"
    sql: ${TABLE} ;;
  }
}   

view: suivi_evo_historization__capitams_component_names {
  dimension: suivi_evo_historization__capitams_component_names {
    type: string
    label: "Capitams Component Name"
    sql: ${TABLE} ;;
  }
}
