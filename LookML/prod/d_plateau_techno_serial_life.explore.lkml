# Tout changer entre la prod et la preprod

include: "/views/Source/d_plateau_techno_serial_life.view.lkml"
include: "/views/Add/Add_d_plateau_techno_serial_life.view.lkml"

explore: plateau_techno_serial_life {
  from: d_plateau_techno_serial_life
  view_name: d_plateau_techno_serial_life
  label: "Plateau Techno Serial Life"

  join: d_plateau_techno_serial_life__vies_component_names {
    view_label: "Vies Component Names"
    sql: LEFT JOIN UNNEST(${d_plateau_techno_serial_life.vies_component_names}) as d_plateau_techno_serial_life__vies_component_names ;;
    relationship: one_to_many
  }
  join: d_plateau_techno_serial_life__vies_requesting_teams {
    view_label: "Vies Requesting Teams"
    sql: LEFT JOIN UNNEST(${d_plateau_techno_serial_life.vies_requesting_teams}) as d_plateau_techno_serial_life__vies_requesting_teams ;;
    relationship: one_to_many
  }
  join: d_plateau_techno_serial_life__capitams_component_names {
    view_label: "CapitAMS Component Names"
    sql: LEFT JOIN UNNEST(${d_plateau_techno_serial_life.capitams_component_names}) as d_plateau_techno_serial_life__capitams_component_names ;;
    relationship: one_to_many
  }
}