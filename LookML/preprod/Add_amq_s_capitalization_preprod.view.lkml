# Ligne à changer: preprod / prod

include: "/views/Source/amq_s_capitalization_preprod.view.lkml"
view: +amq_s_capitalization_preprod {
# Bien faire attention (1/1)

# ── URLS ────────────────────────────────────────────────────────
dimension: vies_url {
  label: "Vies Url"
  group_label: "Caracteristic Standard"
  type: string
  sql: CONCAT('https://jira.dt.renault.com/browse/', ${vies_ticket_id}) ;;
  html:
        {% if value != null %}
          <a href="{{ value }}" target="_blank" title="Voir le ticket VIES">
            <img src="https://img.icons8.com/material-outlined/24/1a73e8/external-link.png" alt="Link" style="width:16px;height:16px;"/>
          </a>
        {% endif %} ;;
}

dimension: capitams_url {
  label: "Capitalization Url"
  group_label: "Caracteristic Standard"
  type: string
  sql:
        CASE
          WHEN ${capitams_key} IS NULL THEN NULL
          ELSE CONCAT('https://jira.dt.renault.com/browse/', ${capitams_key})
        END ;;
  html:
        {% if value != null %}
          <a href="{{ value }}" target="_blank" title="Voir le ticket de Capitalisation">
            <img src="https://img.icons8.com/material-outlined/24/1a73e8/external-link.png" alt="Link" style="width:16px;height:16px;"/>
          </a>
        {% endif %} ;;
}

# ── DOMAIN GROUPING ─────────────────────────────────────────────
dimension: domain_group {
  type: string
  label: "Domain Group"
  group_label: "KPI 3C"
  sql: CASE
      WHEN ${vies_domain} IN ('Multimedia', 'Connectivity On-Board', 'Meter') THEN 'CCS'
      WHEN ${vies_domain} = 'Connectivity Off-Board' THEN 'Connectivity Off-Board'
      WHEN ${vies_domain} IN ('Wire Harness', 'Battery') THEN 'Archi'
      WHEN ${vies_domain} = 'ADAS' THEN 'ADAS'
      WHEN ${vies_domain} IN ('e-Body', 'Electrotechnical') THEN 'Fondation'
      ELSE 'Other'
    END ;;
}

# ── KPI 3C BASE MEASURES ────────────────────────────────────────
measure: count_base {
  type: count
  label: "VIES Base (DOR Yes)"
  group_label: "KPI 3C"
  filters: [
    vies_dor_opinion: "VIES ready for capitalisation",
    vies_status: "Ready for Deployment,Deploying,Closed"
  ]
  drill_fields: [
    vies_ticket_id, vies_url,
    vies_domain, domain_group,
    vies_criticity, vies_status,
    vies_dor_opinion,
    capitams_key, capitams_url
  ]
}

  measure: count_capitams_created {
    type: count
    label: "Nb CapitAMS créé"
    group_label: "KPI 3C"
    filters: [
      vies_dor_opinion: "VIES ready for capitalisation",
      vies_status: "Ready for Deployment,Deploying,Closed",
      capitams_key: "-NULL"
    ]
    drill_fields: [vies_ticket_id, vies_url, vies_domain, domain_group, vies_criticity, capitams_key, capitams_url, capitams_status, capitams_criticity, capitams_capitalization_status, capitams_gsfa]
  }

  measure: count_nrl_npk {
    type: count
    label: "Nb NRL validé + NPK"
    group_label: "KPI 3C"
    filters: [
      vies_dor_opinion: "VIES ready for capitalisation",
      vies_status: "Ready for Deployment,Deploying,Closed",
      capitams_key: "-NULL",
      is_nrl_or_npk: "yes"
    ]
    drill_fields: [vies_ticket_id, vies_url, vies_domain, domain_group, vies_criticity, capitams_key, capitams_url, capitams_nrl, nrl_date_statut_valide, capitams_criticity, capitams_capitalization_status]
  }
  dimension: is_nrl_or_npk {
    type: yesno
    hidden: yes
    sql: (
          ${TABLE}.nrl_date_statut_valide IS NOT NULL
          OR CONTAINS_SUBSTR(IFNULL(${TABLE}.capitams_capitalization_status, ''), 'NPK')
        ) ;;
  }

# ── KPI 3C PERCENTAGES ──────────────────────────────────────────
measure: coverage_pct {
  type: number
  label: "Coverage Globale %"
  group_label: "KPI 3C"
  sql: SAFE_DIVIDE(${count_capitams_created}, NULLIF(${count_base}, 0)) * 100 ;;
  value_format: "0.0\"%\""
  drill_fields: [
    vies_ticket_id, vies_url,
    vies_domain, domain_group,
    vies_criticity,
    capitams_key, capitams_url,
    capitams_status, capitams_capitalization_status
  ]
}

measure: completeness_pct {
  type: number
  label: "Completeness %"
  group_label: "KPI 3C"
  sql: SAFE_DIVIDE(${count_nrl_npk}, NULLIF(${count_capitams_created}, 0)) * 100 ;;
  value_format: "0.0\"%\""
  drill_fields: [
    vies_ticket_id, vies_url,
    vies_domain, domain_group,
    vies_criticity,
    capitams_key, capitams_url,
    capitams_nrl,
    capitams_capitalization_status
  ]
}

# ── LEGACY MEASURES ─────────────────────────────────────────────
measure: coverage_count {
  type: number
  label: "🟢 Coverage (En cours)"
  sql: COUNTIF(
      ${TABLE}.vies_dor_opinion = 'VIES ready for capitalisation'
      AND ${TABLE}.vies_status IN ('Ready for Deployment', 'Deploying', 'Closed')
      AND ${TABLE}.capitams_capitalization_status = 'BMIR_EN COURS DE CAPITALISATION'
    ) ;;
  drill_fields: [
    vies_ticket_id, vies_url,
    vies_domain, capitams_key, capitams_url,
    capitams_capitalization_status
  ]
}

measure: completeness_count {
  type: number
  label: "🔴 Completeness (Terminée)"
  sql: COUNTIF(
      ${TABLE}.vies_dor_opinion = 'VIES ready for capitalisation'
      AND ${TABLE}.vies_status IN ('Ready for Deployment', 'Deploying', 'Closed')
      AND (CONTAINS_SUBSTR(IFNULL(${TABLE}.capitams_capitalization_status, ''), 'BMIRF')
        OR CONTAINS_SUBSTR(IFNULL(${TABLE}.capitams_capitalization_status, ''), 'NPK'))
    ) ;;
  drill_fields: [
    vies_ticket_id, vies_url,
    vies_domain, capitams_key, capitams_url,
    capitams_capitalization_status
  ]
}

measure: coverage_pct_old {
  type: number
  label: "Coverage % (ancien)"
  sql: SAFE_DIVIDE(${coverage_count}, NULLIF(${count_base}, 0)) * 100 ;;
  value_format: "0.0"
}

measure: completeness_pct_old {
  type: number
  label: "Completeness % (ancien)"
  sql: SAFE_DIVIDE(${completeness_count}, NULLIF(${count_base}, 0)) * 100 ;;
  value_format: "0.0"
}
}
