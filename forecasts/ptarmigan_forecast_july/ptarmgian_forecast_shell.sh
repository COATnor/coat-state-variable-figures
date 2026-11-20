#!/usr/bin/env bash

set -euo pipefail

# Locate the repository root. This works when the script is anywhere inside
# the Git repository. If Git is unavailable, use the script directory.
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

if PROJECT_ROOT="$(git -C "$SCRIPT_DIR" rev-parse --show-toplevel 2>/dev/null)"; then
  :
else
  PROJECT_ROOT="$SCRIPT_DIR"
fi

SOURCE_DIR="$PROJECT_ROOT/forecasts/ptarmigan_forecast_july"
SOURCE_FILE="plot_ptarmigan_forecast.qmd"

OUTPUT_DIR="$PROJECT_ROOT/docs/figures/ptarmigan_forecast_july"
OUTPUT_FILE="plot_ptarmigan_forecast.html"
SUPPORT_DIR="plot_ptarmigan_forecast_files"

LANDING_PAGE="$PROJECT_ROOT/docs/index.html"

DATA_FILE="$SOURCE_DIR/data_JAGS_2026_v1.rds"
FIT_FILE="$SOURCE_DIR/output/H1_noTS_fitto2025_fc2026.RData"

echo "Project root:    $PROJECT_ROOT"
echo "Source directory: $SOURCE_DIR"
echo "Output directory: $OUTPUT_DIR"
echo

# Verify required software and input files.
if ! command -v quarto >/dev/null 2>&1; then
  echo "Error: Quarto was not found on PATH." >&2
  exit 1
fi

if [[ ! -f "$SOURCE_DIR/$SOURCE_FILE" ]]; then
  echo "Error: Quarto source file was not found:" >&2
  echo "  $SOURCE_DIR/$SOURCE_FILE" >&2
  exit 1
fi

if [[ ! -f "$DATA_FILE" ]]; then
  echo "Error: data file was not found:" >&2
  echo "  $DATA_FILE" >&2
  exit 1
fi

if [[ ! -f "$FIT_FILE" ]]; then
  echo "Error: model fit file was not found:" >&2
  echo "  $FIT_FILE" >&2
  exit 1
fi

mkdir -p "$OUTPUT_DIR"

# Remove previous rendered output from both the source and publication
# directories. This avoids retaining stale Plotly dependencies.
rm -f "$SOURCE_DIR/$OUTPUT_FILE"
rm -rf "$SOURCE_DIR/$SUPPORT_DIR"

rm -f "$OUTPUT_DIR/$OUTPUT_FILE"
rm -rf "$OUTPUT_DIR/$SUPPORT_DIR"

echo "Rendering $SOURCE_FILE ..."

# Render from the directory containing the QMD so that the relative paths in
# the QMD resolve to the data and model files in this directory.
(
  cd "$SOURCE_DIR"
  quarto render "$SOURCE_FILE" --to html --output "$OUTPUT_FILE"
)

# Confirm that Quarto produced the expected HTML file.
if [[ ! -f "$SOURCE_DIR/$OUTPUT_FILE" ]]; then
  echo "Error: Quarto did not produce the expected HTML file:" >&2
  echo "  $SOURCE_DIR/$OUTPUT_FILE" >&2
  exit 1
fi

# Move the HTML into the GitHub Pages publication directory.
mv "$SOURCE_DIR/$OUTPUT_FILE" "$OUTPUT_DIR/$OUTPUT_FILE"

# When embed-resources is false, Quarto normally creates this support
# directory for JavaScript, CSS, and Plotly dependencies.
if [[ -d "$SOURCE_DIR/$SUPPORT_DIR" ]]; then
  mv "$SOURCE_DIR/$SUPPORT_DIR" "$OUTPUT_DIR/$SUPPORT_DIR"
else
  echo "Note: no supporting directory was produced."
  echo "This is acceptable if Quarto did not require external support files."
fi

# Create/update the GitHub Pages landing page.
mkdir -p "$PROJECT_ROOT/docs"

cat > "$LANDING_PAGE" <<'EOF'
<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>COAT State Variable Figures</title>
  <style>
    body {
      max-width: 900px;
      margin: 2rem auto;
      padding: 0 1rem;
      font-family: system-ui, -apple-system, BlinkMacSystemFont, "Segoe UI",
        sans-serif;
      line-height: 1.5;
    }

    a {
      color: #0b63a5;
    }
  </style>
</head>
<body>
  <h1>COAT State Variable Figures</h1>

  <p>
    Interactive figures generated from state variables in the COAT Data Portal.
  </p>

  <h2>Available figures</h2>

  <ul>
    <li>
      <a href="figures/ptarmigan_forecast_july/plot_ptarmigan_forecast.html">
        Ptarmigan forecast for 2026
      </a>
    </li>
  </ul>
</body>
</html>
EOF

echo
echo "Published files:"
find "$OUTPUT_DIR" -maxdepth 2 -print | sort

echo
echo "Landing page:"
echo "$LANDING_PAGE"

echo
echo "Render completed successfully."