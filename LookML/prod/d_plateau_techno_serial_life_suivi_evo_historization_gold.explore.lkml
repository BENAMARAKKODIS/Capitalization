# Ligne à changer: preprod / prod

include: "/views/Source/d_plateau_techno_serial_life_suivi_evo_historization_gold.view.lkml"

explore: suivi_evo_historization_gold {
  from: d_plateau_techno_serial_life_suivi_evo_historization_gold
  view_name: suivi_evo_historization_gold
  label: "Suivi EVO — Weekly Tracking (Gold)"

  join: suivi_evo_historization_gold__vies_requesting_teams {
    view_label: "Vies Requesting Teams"
    sql: LEFT JOIN UNNEST(${suivi_evo_historization_gold.vies_requesting_teams}) as suivi_evo_historization_gold__vies_requesting_teams ;;
    relationship: one_to_many
  }

  join: suivi_evo_historization_gold__vies_component_names {
    view_label: "Vies Component Names"
    sql: LEFT JOIN UNNEST(${suivi_evo_historization_gold.vies_component_names}) as suivi_evo_historization_gold__vies_component_names ;;
    relationship: one_to_many
  }

  join: suivi_evo_historization_gold__capitams_component_names {
    view_label: "Capitams Component Names"
    sql: LEFT JOIN UNNEST(${suivi_evo_historization_gold.capitams_component_names}) as suivi_evo_historization_gold__capitams_component_names ;;
    relationship: one_to_many
  }
}
