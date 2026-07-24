# Ligne à changer: preprod / prod
include: "/views/Source/amq_s_capitalization_preprod.view.lkml"

view: +amq_s_capitalization_preprod {
# Bien faire attention (1/1)
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
}