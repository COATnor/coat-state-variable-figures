#!/usr/bin/env bash

set -euo pipefail

# Find the repository root based on the location of this script.
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

SOURCE_DIR="$PROJECT_ROOT/state_variables/v85_snowbed_dwarf_shrub_abundance"
SOURCE_FILE="plot_existing_state_variable.qmd"

OUTPUT_DIR="$PROJECT_ROOT/docs/figures/v85_snowbed_dwarf_shrub_abundance"
OUTPUT_FILE="plot_existing_state_variable.html"
SUPPORT_DIR="plot_existing_state_variable_files"
LANDING_PAGE="$PROJECT_ROOT/docs/index.html"

echo "Project root: $PROJECT_ROOT"
echo "Source directory: $SOURCE_DIR"
echo "Output directory: $OUTPUT_DIR"

mkdir -p "$OUTPUT_DIR"

# Remove old rendered output from both locations.
rm -f "$SOURCE_DIR/$OUTPUT_FILE"
rm -rf "$SOURCE_DIR/$SUPPORT_DIR"

rm -f "$OUTPUT_DIR/$OUTPUT_FILE"
rm -rf "$OUTPUT_DIR/$SUPPORT_DIR"

# Render locally from the directory containing the QMD.
(
  cd "$SOURCE_DIR"
  quarto render "$SOURCE_FILE"
)

# Check that Quarto produced the expected HTML.
if [[ ! -f "$SOURCE_DIR/$OUTPUT_FILE" ]]; then
  echo "Could not find rendered HTML:"
  echo "$SOURCE_DIR/$OUTPUT_FILE"
  exit 1
fi

# Move the HTML to the GitHub Pages publication directory.
mv "$SOURCE_DIR/$OUTPUT_FILE" "$OUTPUT_DIR/$OUTPUT_FILE"

# Move supporting files produced when self-contained is false.
if [[ -d "$SOURCE_DIR/$SUPPORT_DIR" ]]; then
  mv "$SOURCE_DIR/$SUPPORT_DIR" "$OUTPUT_DIR/$SUPPORT_DIR"
else
  echo "Warning: supporting directory was not found:"
  echo "$SOURCE_DIR/$SUPPORT_DIR"
fi

# Create the GitHub Pages landing page.
mkdir -p "$PROJECT_ROOT/docs"

cat > "$LANDING_PAGE" <<'EOF'
<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>COAT State Variable Figures</title>
</head>
<body>
  <h1>COAT State Variable Figures</h1>

  <p>
    Interactive figures generated from state variables in the COAT data portal.
  </p>

  <h2>Available figures</h2>

  <ul>
    <li>
      <a href="figures/v85_snowbed_dwarf_shrub_abundance/plot_existing_state_variable.html">
        Dwarf shrub abundance in snowbeds
      </a>
    </li>
  </ul>
</body>
</html>
EOF

echo
echo "Published local files:"
find "$OUTPUT_DIR" -maxdepth 2 -print

