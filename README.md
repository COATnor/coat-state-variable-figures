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

## Overview

There are two ways to work with state variables. Both should end in the same standardised plotting data, so the same plotting functions work across state variables and modules.

**Workflow 1: plot an existing state variable (default).** Download a state variable that already exists on the COAT data portal and plot it, without recalculating. This does not create a new version or modify the portal.

```text
Existing state variable on COAT portal -> Download -> Prepare plotting data -> Generate figures -> Store/publish figures
```

**Workflow 2: calculate and publish a new state variable version (when needed).** Use this when new source data, a new year, a correction, or a changed method requires a new state variable version. The existing COAT calculation scripts are the reference implementation, for example [`calculate_state_variable_shrub_abundance_snowbeds.R`](https://github.com/COATnor/small_rodent_module/blob/main/state_variable_scripts/calculate_state_variable_shrub_abundance_snowbeds.R). They download source data, calculate the state variable, create a new version, upload files and update metadata. This repository may call, adapt, or refactor them.

```text
Source data on COAT portal -> Calculate -> Validate -> Create version, upload, update metadata -> Plot via Workflow 1
```

Calculation and upload are always separate from figure generation. Creating a figure never creates a new version or uploads anything to the portal.

## Workflow summary

```text
COAT data portal
        |
        v
Download source or state-variable data
        |
        v
Calculate or download exisiting state variables
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

## 1. Getting started

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
## 2. Run the workflow

Run scripts either in the RStudio Console (`source("scripts/<name>.R")`) or in a terminal (`Rscript scripts/<name>.R`). Script names below may change as the project develops.

### Workflow 1: download and plot an existing state variable

1. Download the state variable from the COAT portal
2. Prepare standardised plotting data
3. Generate figures
4. Store figures and metadata (see [Outputs](#outputs))

### Workflow 2: calculate and publish a new state variable version

1. Download source data and calculate the state variable (adapting the existing COAT calculation script: [`calculate_state_variable_shrub_abundance_snowbeds.R`](https://github.com/COATnor/small_rodent_module/blob/main/state_variable_scripts/calculate_state_variable_shrub_abundance_snowbeds.R)
2. Validate the result
3. Upload files and update metadata on the COAT portal (deliberate, explicit step)
4. Plot the published version using Workflow 1
   
## 3. Optional checks

These are not required. They only confirm that downloading and calculating work on your machine. Neither uploads anything, changes the COAT portal, or saves data in the repository. Both require `ckanr` and `dplyr` to be installed already (they never install packages) and `api_COAT` to be set.

**`scripts/test_download.R`** downloads one year of snowbed shrub-abundance source data and prints row and column counts, column names, and the first rows.

**`scripts/test_calculation.R`** downloads one year (currently 2024) of source data from `v_snowbed_shrub_abundance_intensive_v4`, calculates the state variable with `calculate_snowbed_shrub_abundance()` (from `state_variables/v85_snowbed_dwarf_shrub_abundance/calculate_state_variable.R`), prints the result, and writes it to a temporary file whose path is printed. Change `year <- 2024` in the script to test another year.

```r
source("scripts/test_download.R")
source("scripts/test_calculation.R")
```

A successful download prints `Download successful.`; a successful calculation prints `State variable calculated.`

## Outputs from repository

- PNG figures for direct website use
- PDF (and optionally SVG) figures for reports
- Optional interactive HTML figures
- Standardised data file used to create each figure
- Metadata file describing the figure and its source data

Required formats will be agreed with the Increo maintainers and can be set per state variable.

## Status

Under development. Next steps:

1. Refactor the existing snowbed shrub-abundance code
2. Generate the first figure from the existing portal state variable and compare it with the existing Box figure
3. Add automated tests
4. Agree output formats and publication mechanism with Increo
5. Add further state variables

## License

See `LICENSE`.
```

