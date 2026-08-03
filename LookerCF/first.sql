-- 1. Overall VIES tickets view per domain for MyF3+

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
  when(${amq_s_capitalization_preprod.vies_domain} = "Meter", "2. Meter"),
  when(${amq_s_capitalization_preprod.vies_domain} = "Connectivity On-Board", "3. Connectivity On-Board"),
  when(${amq_s_capitalization_preprod.vies_domain} = "Connectivity Off-Board", "4. Connectivity Off-Board"),
  when(${amq_s_capitalization_preprod.vies_domain} = "ADAS", "5. ADAS"),
  when(${amq_s_capitalization_preprod.vies_domain} = "e-Body", "6. e-Body"),
  when(${amq_s_capitalization_preprod.vies_domain} = "Wire Harness", "7. Wire Harness"),
  when(${amq_s_capitalization_preprod.vies_domain} = "Battery", "8. Battery"),
  when(${amq_s_capitalization_preprod.vies_domain} = "Electrotechnical", "9. Electrotechnical"),
  when(${amq_s_capitalization_preprod.vies_domain} = "e-Chassis", "A. e-Chassis"),
  "Other"
)