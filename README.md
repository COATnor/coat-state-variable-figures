# COAT State Variable Figures

Reusable, interactive figures for state variables from the COAT data portal.

The long-term goal is to provide a general system for calculating, exploring,
and presenting state-variable figures on an existing COAT website. The project
will support state variables from multiple COAT data modules while keeping the
data processing, plotting, and website presentation layers separate.

## Project goal

The current workflow creates static figures locally and stores them in Box.
Those figures are not interactive and the plotting code is difficult to reuse
across modules.

This project aims to provide a general workflow that:

1. Downloads or reads state-variable data from the COAT data portal.
2. Calculates or prepares state-variable summaries.
3. Validates the resulting data.
4. Creates figures using reusable plotting functions.
5. Stores the generated figures in a predictable location.
6. Makes the figures available to the existing Increo website through links.

The first implementation will focus on generating figures reliably. Interactive
web-app functionality may be added later if it is useful for development,
exploration, or internal quality control.

## Workflow

```text
COAT data portal
        |
        v
Download source or state-variable data
        |
        v
Calculate and validate state variables
        |
        v
Create standardised plotting data
        |
        v
Generate figures
        |
        v
Store figures and metadata
        |
        v
Publish files or links
        |
        v
Existing Increo website
```
The current idea is for the website to link to generated figures. The website does not run the download and calculation workflow when a user views a figure.

## Initial state variable

`V85_snowbed_dwarf_shrub_abundance_intensive`: dwarf shrub abundance in snowbed habitats on the Varanger Peninsula. The first figure reproduces the existing plot of mean proportion of subplots with dwarf shrub presence by year, region, and species:

- *Betula nana*
- *Empetrum nigrum*
- *Vaccinium myrtillus*
- *Vaccinium vitis-idaea*

## Outputs

- PNG figures for direct website use
- PDF (and optionally SVG) figures for reports
- Optional interactive HTML figures
- Standardised data file used to create each figure
- Metadata file describing the figure and its source data

Required formats will be agreed with the Increo maintainers and can be set per state variable.

## Repository structure

```text
R/               Reusable functions: data access, processing, validation, plotting
state_variables/ Per-state-variable calculations, metadata and configuration
scripts/         Commands for download, calculation, figures and publishing
figures/         Generated figures
app/             Optional local app for exploring data and figures
tests/           Automated tests
docs/            Project documentation
```

## Getting started

Requires [R](https://www.r-project.org/), [Pixi](https://pixi.sh/), [Git](https://git-scm.com/), [Air](https://posit-dev.github.io/air/) (formatting) and [Prek](https://github.com/j178/prek) (checks). Structure based on the [NINA R project template](https://github.com/NINAnor/template-r).

```bash
git clone <repository-url>
cd coat-state-variable-figures
pixi install
pixi task list
```

Before committing:

```bash
pixi run air format .
pixi run prek --all-files
```

## COAT data access

Data are downloaded from the [COAT data portal](https://data.coat.no), which requires a **COAT API key**. The key must never be committed, hard-coded in scripts, or shared in the README!

The download code reads the key from the environment variable `api_COAT`:

```r
Sys.getenv("api_COAT")
```

### Configure the key locally

Create a `.Renviron` file in RStudio:

```text
api_COAT=your-real-coat-api-key
```

Make sure it is ignored by Git:

```bash
echo ".Renviron" >> .gitignore
```

Restart RStudio, or reload the file with `readRenviron(".Renviron")` from RStudio console. Check that the key is available without printing it:

```r
nzchar(Sys.getenv("api_COAT"))  # should be TRUE
```

### Test data download from data portal

To test if you can download data from the data portal using the API key you can run `scripts/test_download.R`. This script downloads one year of snowbed shrub-abundance source data using the existing COAT download helper, and prints the number of rows and columns, the column names, and the first rows. It does not upload data, change anything on the COAT portal, or save data in the repository.

Run it in one of three ways:

```r
# RStudio Console
source("scripts/test_download.R")
```

- **Editor:** open the file, select all, and click **Run**. Run the whole file, since partial runs may miss packages or functions.
- **Terminal** (Tools → Terminal → New Terminal), from the project root:

```bash
Rscript scripts/test_download.R
```

A successful run prints `Download successful.` followed by row and column counts.

## Status

Under development. Next steps:

1. Add a small example
2. Refactor the existing snowbed shrub-abundance preparation code
3. Generate the first figure and compare it with the existing Box figure
4. Add automated tests
5. Agree output formats and publication mechanism with Increo
6. Add further state variables

## License

See `LICENSE`.
```

