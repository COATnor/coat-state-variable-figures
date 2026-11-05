# Calculate V85 snowbed dwarf shrub abundance
#
# This function calculates the state variable from downloaded source data.
# It does not download data and does not upload anything to the COAT portal.

calculate_snowbed_shrub_abundance <- function(dat) {
  required_columns <- c(
    "sn_region",
    "sn_locality",
    "sn_section",
    "sn_site",
    "sn_plot",
    "sc_plot_treatment",
    "t_year",
    "v_species",
    "v_presence"
  )
  
  missing_columns <- setdiff(required_columns, names(dat))
  
  if (length(missing_columns) > 0L) {
    stop(
      "The input data are missing these columns: ",
      paste(missing_columns, collapse = ", ")
    )
  }
  
  dat |>
    dplyr::group_by(
      sn_region,
      sn_locality,
      sn_section,
      sn_site,
      sn_plot,
      sc_plot_treatment,
      t_year,
      v_species
    ) |>
    dplyr::summarise(
      v_abundance = sum(v_presence, na.rm = TRUE),
      .groups = "drop"
    )
}