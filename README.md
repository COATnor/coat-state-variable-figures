# COAT State Variable Figures

Reusable, interactive figures for state variables from the COAT data portal.

The long-term goal is to provide a general system for calculating, exploring,
and presenting state-variable figures on an existing COAT website. The project
will support state variables from multiple COAT data modules while keeping the
data processing, plotting, and website presentation layers separate.

The first implementation is an interactive HTML figure rendered from a Quarto document which is published through GitHub Pages.

**Currently available example figure on GitHub pages:** [`V85_snowbed_dwarf_shrub_abundance_intensive (dwarf shrub abundance in snowbeds, Varanger Peninsula)`](https://coatnor.github.io/coat-state-variable-figures/figures/v85_snowbed_dwarf_shrub_abundance/plot_existing_state_variable.html)

The figure shows the mean proportion of subplots with dwarf shrub presence by year, region and species (*Betula nana*, *Empetrum nigrum*, *Vaccinium myrtillus*, *Vaccinium vitis-idaea*).

---

## How the current process works

```text
1. Run a script that downloads the state variable from the COAT data portal and makes the figure. The figure created is currently 
saved in this GitHub repository.
2. Publish the figure with GitHub Pages, which gives it a fixed URL.
```
Creating a figure never changes anything on the COAT data portal !

**Why two seperate steps?** The first script has to run on your own computer because GitHub is blocked by Cloudflare (a security service) when they try to download private COAT data with an API key. Once that is solved, steps 1 and 2 could be done in one automatic step without saving figures in the repository. Another alternative is to store the figures on the COAT data portal.

---

## Before you start (one-time setup)

You need [R](https://www.r-project.org/), [RStudio](https://posit.co/download/rstudio-desktop/) and [Git](https://git-scm.com/), and a copy of this repository on your computer:

```bash
git clone https://github.com/COATnor/coat-state-variable-figures.git
```

Open the project in RStudio (File > Open Project, or open the folder).

### Add your COAT API key

The COAT API key is a personal password that lets R download data from the portal. **Never** paste it into scripts, commit it to GitHub, or share it!

1. In RStudio, create a new text file named `.Renviron` in the project folder.
2. Put this single line in it (use your real key):

   ```text
   api_COAT=your-real-coat-api-key
   ```
3. Make sure Git ignores the file: `echo ".Renviron" >> .gitignore`
4. Restart RStudio.
5. Check that the key works (it should print `TRUE`, and does not show the key):

   ```r
   nzchar(Sys.getenv("api_COAT"))
   ```

---

## Instructions for making and publishing state variable figure: V85 dwarf shrub abundance

### Step 1: Make the figure (on your computer)

Open the RStudio and run this script from the project folder:
([script on GitHub](https://github.com/COATnor/coat-state-variable-figures/blob/main/scripts/render_v85_figure.sh))

The script:

- sets up the folders for the figure and the GitHub Pages website,
- downloads the V85 data (yearly files) from the COAT data portal,
- runs the Quarto document that contains the plotting code ([`plot_existing_state_variable.qmd`](https://github.com/COATnor/coat-state-variable-figures/blob/main/state_variables/v85_snowbed_dwarf_shrub_abundance/plot_existing_state_variable.qmd)),
- saves the finished interactive figure in the `docs/` folder.

The result is:

```text
docs/figures/v85_snowbed_dwarf_shrub_abundance/
├── plot_existing_state_variable.html          <- the figure
└── plot_existing_state_variable_files/        <- supporting files
```

**Keep the `.html` file and the `_files` folder together.** The figure does not work without the folder.

To change what the figure shows on the web page (titles, text, species, layout), edit the Quarto document above and run the script again.

Then save the new figure to GitHub (commit and push). In the RStudio Terminal:

```bash
git add docs/
git commit -m "Update V85 figure"
git push
```

### Step 2: Publish with GitHub Pages

Publishing is done automatically by a GitHub Actions workflow ([`workaround_publish-quarto-pages.yml`](https://github.com/COATnor/coat-state-variable-figures/blob/main/.github/workflows/workaround_publish-quarto-pages.yml)). It takes everything in the `docs/` folder and puts it on the web with GitHub Pages. It does **not** download COAT data or make figures. It only publishes the files created in Step 1 which were added to GitHub. Every time changes are made to the code and committed to GitHub this process happens automatically.

This gives the figure a stable URL:

```text
https://coatnor.github.io/coat-state-variable-figures/figures/v85_snowbed_dwarf_shrub_abundance/plot_existing_state_variable.html
```
Use this URL in Increo. It stays the same each time you update the figure! Generated URL can also be found by clicking on Settings tab on the top and then Pages.

#### Alternatively, run the publishing workflow manually (on the GitHub website)
1. Go to the repository on GitHub: <https://github.com/COATnor/coat-state-variable-figures>
2. Click the **Actions** tab.
3. In the left-hand list, click the workflow **Publish locally rendered Quarto figure**.
4. Click the **Run workflow** button (right side), choose the `main` branch, and click the green **Run workflow** button.
5. Wait about 1 to 2 minutes and refresh the page. A green tick means it worked. A red cross means it failed. If failed, click the run to see the error message.


#### Running the publishing workflow at fixed intervals (to be added later)

Later, the workflow can be set to run automatically, for example every week. This is done by adding a `schedule` to the `on:` section of the workflow file:

```yaml
on:
  workflow_dispatch:        # keeps the manual "Run workflow" button
  schedule:
    - cron: "0 6 * * 1"     # every Monday at 06:00 UTC
```

The five values in `cron` are minute, hour, day of month, month and day of week. Times are in UTC.

> **Current status:** Have made and published the state variables from 2009-2024 for V85_snowbed_dwarf_shrub_abundance_intensive dataset using the two step process.

---

## Later plans

- Add further state variables and modules.
- Create PNG/SVG/PDF versions if needed. Formats will be agreed with the Increo maintainers.
- Add automated tests.
- Solve the Cloudflare block so figures can be made and published in one automatic step.

---
## Tools used in this repository

The project uses these tools so that everyone gets the same setup and consistent code:

- [**Pixi**](https://pixi.sh/) installs R, the R packages and other dependencies at fixed versions (`pixi install`, `pixi task list`).
- [**Air**](https://posit-dev.github.io/air/) formats R code in one consistent style.
- [**Prek**](https://github.com/j178/prek) runs automatic checks before each commit (formatting, accidentally committed files and secrets).

```bash
pixi install
pixi run air format .
pixi run prek --all-files
```

Repository structure:

```text
R/               Reusable functions: data access, processing, validation, plotting
state_variables/ Per-state-variable calculations, metadata and Quarto documents
scripts/         Scripts for download, calculation, figures and publishing
docs/            Rendered figures that GitHub Pages publishes
tests/           Automated tests
```

Structure based on the [NINA R project template](https://github.com/NINAnor/template-r).

---

## Optional: calculating a new state variable version

Making a **new version** of a state variable (new data, a new year, a correction or a changed method) is a separate job. It is not part of making figures. Use the existing COAT calculation scripts, for example [`calculate_state_variable_shrub_abundance_snowbeds.R`](https://github.com/COATnor/small_rodent_module/blob/main/state_variable_scripts/calculate_state_variable_shrub_abundance_snowbeds.R). Calculate, validate, then upload to the COAT portal deliberately, and then make the figure as above.

Two optional test scripts check that downloading and calculating work on your computer. They upload nothing and change nothing on the portal. Both need the R packages `ckanr` and `dplyr` installed and `api_COAT` set.

```r
source("scripts/test_download.R")      # prints "Download successful."
source("scripts/test_calculation.R")   # prints "State variable calculated."
```

---

## License

See `LICENSE`.
```

