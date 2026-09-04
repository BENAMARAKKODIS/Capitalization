include: "/views/Source/amq_s_suivi_evo_historization.view.lkml"

explore: suivi_evo_historization {
  from: suivi_evo_historization
  view_name: suivi_evo_historization
  label: "Suivi EVO — Weekly Tracking"

  join: suivi_evo_historization__vies_requesting_teams {
    view_label: "Vies Requesting Teams"
    sql: LEFT JOIN UNNEST(${suivi_evo_historization.vies_requesting_teams}) as suivi_evo_historization__vies_requesting_teams ;;
    relationship: one_to_many
  }

  join: suivi_evo_historization__vies_component_names {
    view_label: "Vies Component Names"
    sql: LEFT JOIN UNNEST(${suivi_evo_historization.vies_component_names}) as suivi_evo_historization__vies_component_names ;;
    relationship: one_to_many
  }

  join: suivi_evo_historization__capitams_component_names {
    view_label: "Capitams Component Names"
    sql: LEFT JOIN UNNEST(${suivi_evo_historization.capitams_component_names}) as suivi_evo_historization__capitams_component_names ;;
    relationship: one_to_many
  }
}
