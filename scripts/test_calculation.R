# Test the snowbed shrub-abundance calculation for one year.
#
# This script downloads one year of source data and calculates the state
# variable locally. It does not upload or modify anything on the COAT portal.

required_packages <- c("ckanr", "dplyr")

missing_packages <- required_packages[
  !vapply(
    required_packages,
    requireNamespace,
    quietly = TRUE,
    FUN.VALUE = logical(1)
  )
]

if (length(missing_packages) > 0L) {
  stop(
    "Missing packages: ",
    paste(missing_packages, collapse = ", "),
    "\nInstall them once, then run this script again."
  )
}

suppressPackageStartupMessages({
  library(ckanr)
  library(dplyr)
})

source(
  "https://raw.githubusercontent.com/COATnor/data_management_scripts/master/download_data_from_coat_data_portal.R"
)

source(
  "state_variables/v85_snowbed_dwarf_shrub_abundance/calculate.R"
)

api_key <- Sys.getenv("api_COAT")

if (!nzchar(api_key)) {
  stop(
    "The environment variable 'api_COAT' is not set."
  )
}

ckanr::ckanr_setup(
  url = "https://data.coat.no",
  key = api_key
)

year <- 2024

filename <- paste0(
  "V_snowbed_shrub_abundance_intensive_",
  year,
  ".txt"
)

dat_list <- download_coat_data(
  name = "v_snowbed_shrub_abundance_intensive_v4",
  filenames = filename,
  store = "session"
)

if (length(dat_list) == 0L || is.null(dat_list[[1]])) {
  stop("No data were returned.")
}

dat <- dat_list[[1]]

message("Source data downloaded.")
message("Source rows: ", nrow(dat))

state_variable <- calculate_snowbed_shrub_abundance(dat)

message("State variable calculated.")
message("Result rows: ", nrow(state_variable))

print(names(state_variable))
print(utils::head(state_variable))

output_file <- file.path(
  tempdir(),
  paste0(
    "V85_snowbed_dwarf_shrub_abundance_intensive_",
    year,
    ".txt"
  )
)

utils::write.table(
  state_variable,
  file = output_file,
  row.names = FALSE,
  sep = ";"
)

message("Calculated data written to:")
message(output_file)