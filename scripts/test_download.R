# Test downloading one year of COAT data.
#
# This script only downloads data to a temporary directory.
# It does not upload data or modify the COAT data portal.

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
    "The following packages are missing: ",
    paste(missing_packages, collapse = ", "),
    "\nInstall them once, outside this script, then run the script again."
  )
}

# dplyr imports the magrittr pipe used by the existing COAT helper.
suppressPackageStartupMessages({
  library(dplyr)
  library(ckanr)
})

source(
  "https://raw.githubusercontent.com/COATnor/data_management_scripts/master/download_data_from_coat_data_portal.R"
)

api_key <- Sys.getenv("api_COAT")

if (!nzchar(api_key)) {
  stop(
    "The environment variable 'api_COAT' is not set. ",
    "Set it before running this script."
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

message("Download successful.")
message("Rows: ", nrow(dat))
message("Columns: ", ncol(dat))

print(names(dat))
print(utils::head(dat))