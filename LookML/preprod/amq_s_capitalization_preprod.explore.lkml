# Tout changer entre la prod et la preprod

include: "/views/Source/amq_s_capitalization_preprod.view.lkml"
include: "/views/Add/Add_amq_s_capitalization_preprod.view.lkml"

explore: amq_s_capitalization_preprod {
  from: amq_s_capitalization_preprod
  view_name: amq_s_capitalization_preprod
  label: "AMQ-S Capitalization Preprod"

  join: amq_s_capitalization_preprod__vies_component_names {
    view_label: "Vies Component Names"
    sql: LEFT JOIN UNNEST(${amq_s_capitalization_preprod.vies_component_names}) as amq_s_capitalization_preprod__vies_component_names ;;
    relationship: one_to_many
  }
  join: amq_s_capitalization_preprod__vies_requesting_teams {
    view_label: "Vies Requesting Teams"
    sql: LEFT JOIN UNNEST(${amq_s_capitalization_preprod.vies_requesting_teams}) as amq_s_capitalization_preprod__vies_requesting_teams ;;
    relationship: one_to_many
  }
  join: amq_s_capitalization_preprod__capitams_component_names {
    view_label: "Capitams Component Names"
    sql: LEFT JOIN UNNEST(${amq_s_capitalization_preprod.capitams_component_names}) as amq_s_capitalization_preprod__capitams_component_names ;;
    relationship: one_to_many
  }
}