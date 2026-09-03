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
  html:
      {% if value == 'CCS' %}
        <div style="background-color:#fff9c4; color:#000; padding:4px; border-radius:4px;">{{ value }}</div>
      {% elsif value == 'ADAS' %}
        <div style="background-color:#ffcdd2; color:#000; padding:4px; border-radius:4px;">{{ value }}</div>
      {% elsif value == 'Archi' %}
        <div style="background-color:#d7ccc8; color:#000; padding:4px; border-radius:4px;">{{ value }}</div>
      {% elsif value == 'Fondation' %}
        <div style="background-color:#e1bee7; color:#000; padding:4px; border-radius:4px;">{{ value }}</div>
      {% elsif value == 'Connectivity Off-Board' %}
        <div style="background-color:#212121; color:#fff; padding:4px; border-radius:4px;">{{ value }}</div>
      {% else %}
        <div style="background-color:#f5f5f5; color:#000; padding:4px; border-radius:4px;">{{ value }}</div>
      {% endif %} ;;
}

# ── DOMAIN ORDERED ──────────────────────────────────────────────
dimension: vies_domain_ordered {
  type: string
  label: "Domain (Ordered)"
  group_label: "KPI 3C"
  sql: CASE
      WHEN ${vies_domain} = 'Multimedia' THEN '1. Multimedia'
      WHEN ${vies_domain} = 'Meter' THEN '2. Meter'
      WHEN ${vies_domain} = 'Connectivity On-Board' THEN '3. Connectivity On-Board'
      WHEN ${vies_domain} = 'Connectivity Off-Board' THEN '4. Connectivity Off-Board'
      WHEN ${vies_domain} = 'ADAS' THEN '5. ADAS'
      WHEN ${vies_domain} = 'e-Body' THEN '6. e-Body'
      WHEN ${vies_domain} = 'Wire Harness' THEN '7. Wire Harness'
      WHEN ${vies_domain} = 'Battery' THEN '8. Battery'
      WHEN ${vies_domain} = 'Electrotechnical' THEN '9. Electrotechnical'
      WHEN ${vies_domain} = 'e-Chassis' THEN 'A. e-Chassis'
      ELSE 'Other'
    END ;;
  html:
      {% if value contains 'Multimedia' or value contains 'Meter' or value contains 'Connectivity On-Board' %}
        <div style="background-color:#fff9c4; color:#000; padding:4px; border-radius:4px;">{{ value }}</div>
      {% elsif value contains 'Connectivity Off-Board' %}
        <div style="background-color:#212121; color:#fff; padding:4px; border-radius:4px;">{{ value }}</div>
      {% elsif value contains 'ADAS' %}
        <div style="background-color:#ffcdd2; color:#000; padding:4px; border-radius:4px;">{{ value }}</div>
      {% elsif value contains 'e-Body' or value contains 'Electrotechnical' or value contains 'e-Chassis' %}
        <div style="background-color:#e1bee7; color:#000; padding:4px; border-radius:4px;">{{ value }}</div>
      {% elsif value contains 'Wire Harness' or value contains 'Battery' %}
        <div style="background-color:#d7ccc8; color:#000; padding:4px; border-radius:4px;">{{ value }}</div>
      {% else %}
        <div style="background-color:#f5f5f5; color:#000; padding:4px; border-radius:4px;">{{ value }}</div>
      {% endif %} ;;
}

# ── HELPER DIMENSION ────────────────────────────────────────────
dimension: is_nrl_or_npk {
  type: yesno
  hidden: yes
  sql: (
      ${TABLE}.nrl_date_statut_valide IS NOT NULL
      OR CONTAINS_SUBSTR(IFNULL(${TABLE}.capitams_capitalization_status, ''), 'NPK')
    ) ;;
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
  drill_fields: [
    vies_ticket_id, vies_url,
    vies_domain, domain_group,
    vies_criticity,
    capitams_key, capitams_url,
    capitams_status, capitams_criticity,
    capitams_capitalization_status, capitams_gsfa
  ]
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
  drill_fields: [
    vies_ticket_id, vies_url,
    vies_domain, domain_group,
    vies_criticity,
    capitams_key, capitams_url,
    capitams_nrl, nrl_date_statut_valide,
    capitams_criticity, capitams_capitalization_status
  ]
}

# ── KPI 3C COMPLETENESS BASE MEASURES: KPI PERFO <= 60 ─────────
measure: count_capitams_created_le_60 {
  type: count
  hidden: yes
  label: "Nb CapitAMS créé - KPI Perfo <= 60"
  group_label: "KPI 3C"
  filters: [
    vies_dor_opinion: "VIES ready for capitalisation",
    vies_status: "Ready for Deployment,Deploying,Closed",
    capitams_key: "-NULL",
    kpi_perfo_v1: "<=60"
  ]
  drill_fields: [
    vies_ticket_id, vies_url,
    vies_domain, domain_group,
    vies_criticity,
    capitams_key, capitams_url,
    capitams_status, capitams_criticity,
    capitams_capitalization_status, capitams_gsfa,
    kpi_perfo_v1
  ]
}

measure: count_nrl_npk_le_60 {
  type: count
  hidden: yes
  label: "Nb NRL validé + NPK - KPI Perfo <= 60"
  group_label: "KPI 3C"
  filters: [
    vies_dor_opinion: "VIES ready for capitalisation",
    vies_status: "Ready for Deployment,Deploying,Closed",
    capitams_key: "-NULL",
    is_nrl_or_npk: "yes",
    kpi_perfo_v1: "<=60"
  ]
  drill_fields: [
    vies_ticket_id, vies_url,
    vies_domain, domain_group,
    vies_criticity,
    capitams_key, capitams_url,
    capitams_nrl, nrl_date_statut_valide,
    capitams_criticity, capitams_capitalization_status,
    kpi_perfo_v1
  ]
}

# ── KPI 3C COMPLETENESS BASE MEASURES: KPI PERFO > 60 ──────────
measure: count_capitams_created_gt_60 {
  type: count
  hidden: yes
  label: "Nb CapitAMS créé - KPI Perfo > 60"
  group_label: "KPI 3C"
  filters: [
    vies_dor_opinion: "VIES ready for capitalisation",
    vies_status: "Ready for Deployment,Deploying,Closed",
    capitams_key: "-NULL",
    kpi_perfo_v1: ">60"
  ]
  drill_fields: [
    vies_ticket_id, vies_url,
    vies_domain, domain_group,
    vies_criticity,
    capitams_key, capitams_url,
    capitams_status, capitams_criticity,
    capitams_capitalization_status, capitams_gsfa,
    kpi_perfo_v1
  ]
}

measure: count_nrl_npk_gt_60 {
  type: count
  hidden: yes
  label: "Nb NRL validé + NPK - KPI Perfo > 60"
  group_label: "KPI 3C"
  filters: [
    vies_dor_opinion: "VIES ready for capitalisation",
    vies_status: "Ready for Deployment,Deploying,Closed",
    capitams_key: "-NULL",
    is_nrl_or_npk: "yes",
    kpi_perfo_v1: ">60"
  ]
  drill_fields: [
    vies_ticket_id, vies_url,
    vies_domain, domain_group,
    vies_criticity,
    capitams_key, capitams_url,
    capitams_nrl, nrl_date_statut_valide,
    capitams_criticity, capitams_capitalization_status,
    kpi_perfo_v1
  ]
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
    capitams_status, capitams_capitalization_status,
    kpi_perfo_v0
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

measure: completeness_pct_le_60 {
  type: number
  label: "Completeness % - KPI Perfo <= 60"
  group_label: "KPI 3C"
  sql: SAFE_DIVIDE(${count_nrl_npk_le_60}, NULLIF(${count_capitams_created_le_60}, 0)) * 100 ;;
  value_format: "0.0\"%\""
  drill_fields: [
    vies_ticket_id, vies_url,
    vies_domain, domain_group,
    vies_criticity,
    capitams_key, capitams_url,
    capitams_nrl,
    capitams_capitalization_status,
    kpi_perfo_v1
  ]
}

measure: completeness_pct_gt_60 {
  type: number
  label: "Completeness % - KPI Perfo > 60"
  group_label: "KPI 3C"
  sql: SAFE_DIVIDE(${count_nrl_npk_gt_60}, NULLIF(${count_capitams_created_gt_60}, 0)) * 100 ;;
  value_format: "0.0\"%\""
  drill_fields: [
    vies_ticket_id, vies_url,
    vies_domain, domain_group,
    vies_criticity,
    capitams_key, capitams_url,
    capitams_nrl,
    capitams_capitalization_status,
    kpi_perfo_v1
  ]
}
}