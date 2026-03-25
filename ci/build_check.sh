#!/usr/bin/env bash
set -euo pipefail


CI_COMMIT_REF_NAME="${CI_COMMIT_REF_NAME:-unknown-branch}"
CB_ITEMS_CSV="${CB_ITEMS_CSV:-_data/items.csv}"


# Compare branch suffix
BR_TAIL="${CI_COMMIT_REF_NAME#libraries-digital-collection-}"
if [[ "${BR_TAIL}" != "${CI_COMMIT_REF_NAME}" ]] \
   && [[ -n "${BR_TAIL}" ]]  then
  echo "WARN: Branch tail '${BR_TAIL}' (not fatal). Wrong branch?"
fi
echo "==> bundle exec jekyll doctor ..."
bundle exec jekyll doctor || true

echo "==> ruby ci/validate_csv.rb ..."
echo "Generating build-report.txt ..."
ruby ci/validate_csv.rb
echo "==> CSV validation completed."
echo "Checks completed successfully."

echo "==> CSV preflight on ${CB_ITEMS_CSV} ..."
if [[ ! -f "${CB_ITEMS_CSV}" ]]; then
  echo "ERROR: ${CB_ITEMS_CSV} not found. The items CSV file is required."
  exit 1
fi

echo "==> bundle exec jekyll build (strict front matter) ..."
bundle exec jekyll build --trace --verbose --strict_front_matter -d _site
echo "Build completed successfully."
