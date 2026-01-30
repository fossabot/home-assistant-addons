#!/bin/bash
#
# Update deployer.yaml workflow_dispatch options from manifest.json

set -euo pipefail

readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
readonly MANIFEST="${REPO_ROOT}/manifest.json"
readonly DEPLOYER_YAML="${REPO_ROOT}/.github/workflows/deployer.yaml"

# Error reporting
err() {
  echo "[$(date +'%Y-%m-%dT%H:%M:%S%z')]: $*" >&2
}

main() {
  # Check if manifest exists
  if [[ ! -f "${MANIFEST}" ]]; then
    err "manifest.json not found at ${MANIFEST}"
    exit 1
  fi

  # Check if deployer.yaml exists
  if [[ ! -f "${DEPLOYER_YAML}" ]]; then
    err "deployer.yaml not found at ${DEPLOYER_YAML}"
    exit 1
  fi

  # Extract slugs from manifest and build options array
  local slugs
  slugs=$(jq -r '[.[].slug] | sort | .[]' "${MANIFEST}" | xargs)

  if [[ -z "${slugs}" ]]; then
    err "No slugs found in manifest.json"
    exit 1
  fi

  echo "Updating deployer.yaml with slugs: ${slugs}"

  # Use yq to update the options array in-place
  # This preserves the entire file structure but replaces the options list
  local temp_file
  temp_file=$(mktemp)

  # Build the new options section
  local new_options="  workflow_dispatch:\n    inputs:\n      addon:\n        description: Addon-Name\n        required: true\n        type: choice\n        options:"

  # Create a temporary yq script to update the file
  yq eval "
    .on.workflow_dispatch.inputs.addon.options = ($(jq -c '[.[].slug]' "${MANIFEST}"))
  " -i "${DEPLOYER_YAML}"

  echo "Updated ${DEPLOYER_YAML}"
}

main "$@"
