-- DOR Opinion
case(
  when(${amq_s_capitalization_preprod.vies_dor_opinion} = "VIES not to capitalise", "3 - VIES not to capitalise"),
  when(${amq_s_capitalization_preprod.vies_dor_opinion} = "VIES without Plateau DOR", "2 - VIES without Plateau DOR"),
  when(${amq_s_capitalization_preprod.vies_dor_opinion} = "VIES ready for capitalisation", "1 - VIES ready for capitalisation"),
  "4 - Other"
)

-- Sorted Domains
case(
  when(${amq_s_capitalization_preprod.vies_domain} = "Multimedia", "1. Multimedia"),
  when(${amq_s_capitalization_preprod.vies_domain} = "Connectivity On-Board", "2. Connectivity On-Board"),
  when(${amq_s_capitalization_preprod.vies_domain} = "Connectivity Off-Board", "3. Connectivity Off-Board"),
  when(${amq_s_capitalization_preprod.vies_domain} = "Meter", "4. Meter"),
  when(${amq_s_capitalization_preprod.vies_domain} = "ADAS", "5. ADAS"),
  when(${amq_s_capitalization_preprod.vies_domain} = "e-Body", "6. e-Body"),
  when(${amq_s_capitalization_preprod.vies_domain} = "e-Chassis", "7. e-Chassis"),
  when(${amq_s_capitalization_preprod.vies_domain} = "Wire Harness", "8. Wire Harness"),
  when(${amq_s_capitalization_preprod.vies_domain} = "Battery", "9. Battery"),
  when(${amq_s_capitalization_preprod.vies_domain} = "Electrotechnical", "A. Electrotechnical"),
  "Other"
)