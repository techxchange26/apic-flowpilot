#!/usr/bin/env bash
# =============================================================================
# createPackage.sh
#
# Builds a distributable zip for one of three release modes:
#   idig  →  Interact_Gateway_Flow_Pilot.zip
#             mcp-servers: interact-gateway-onprem only
#             skills: excludes publish-project, rest-to-mcp-generator,
#                     llm-provider-generator, test-generator
#             setup-agent-kit: excludes apic.md
#   apic  →  IBM_API_Connect_Flow_Pilot.zip
#             mcp-servers: all except interact-gateway-onprem
#             skills: excludes llm-provider-generator, rest-to-mcp-generator
#             setup-agent-kit: excludes interact-gateway.md
#   all   →  IBM_API_Connect_Flow_Pilot.zip  (all mcp-servers + all skills)
#
# Usage:
#   ./scripts/createPackage.sh [idig|apic|all]
#
# If no mode is supplied the script will interactively prompt you to choose.
# =============================================================================

set -euo pipefail

# ---------------------------------------------------------------------------
# Resolve the repo root (one level up from this script's directory)
# ---------------------------------------------------------------------------
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
PACKAGE_DIR="${REPO_ROOT}/packages"

# ---------------------------------------------------------------------------
# Mode selection
# ---------------------------------------------------------------------------
MODE="${1:-}"

if [[ -z "${MODE}" ]]; then
  echo ""
  echo "Select a package mode:"
  echo "  1) idig  — Interact Gateway Flow Pilot"
  echo "  2) apic  — IBM API Connect Flow Pilot"
  echo ""
  read -rp "Enter choice [1/2] or mode name [idig/apic]: " CHOICE

  case "${CHOICE}" in
    1|idig) MODE="idig" ;;
    2|apic) MODE="apic" ;;
    *)
      echo "Error: unrecognised choice '${CHOICE}'. Please enter 1, 2, idig, or apic." >&2
      exit 1
      ;;
  esac
  # Note: 'all' mode is only available via CLI argument
fi

case "${MODE}" in
  idig|apic|all) ;;
  *)
    echo "Error: unknown mode '${MODE}'. Valid modes are: idig, apic, all" >&2
    echo "Usage: $0 [idig|apic|all]" >&2
    exit 1
    ;;
esac

# ---------------------------------------------------------------------------
# Derived values
# ---------------------------------------------------------------------------
if [[ "${MODE}" == "idig" ]]; then
  ZIP_NAME="Interact_Gateway_Flow_Pilot.zip"
else
  ZIP_NAME="IBM_API_Connect_Flow_Pilot.zip"
fi
# Note: both 'apic' and 'all' modes produce IBM_API_Connect_Flow_Pilot.zip

ZIP_PATH="${PACKAGE_DIR}/${ZIP_NAME}"

# ---------------------------------------------------------------------------
# Prepare output directory
# ---------------------------------------------------------------------------
mkdir -p "${PACKAGE_DIR}"

# Remove existing zip so we always produce a clean build
if [[ -f "${ZIP_PATH}" ]]; then
  echo "Removing existing ${ZIP_NAME} ..."
  rm -f "${ZIP_PATH}"
fi

# ---------------------------------------------------------------------------
# Build include/exclude lists
# ---------------------------------------------------------------------------
# Always-included top-level items (relative to repo root)
ALWAYS_INCLUDE=(
  "Licenses"
  "mcp-servers/README.md"
  "skills/README.md"
  "README.md"
  "skills.sh.json"
)

# ---------------------------------------------------------------------------
# Collect paths to zip
# ---------------------------------------------------------------------------
PATHS_TO_ZIP=("${ALWAYS_INCLUDE[@]}")

if [[ "${MODE}" == "idig" ]]; then
  # Only the interact-gateway-onprem mcp-server
  PATHS_TO_ZIP+=(
    "mcp-servers/interact-gateway-onprem"
  )
elif [[ "${MODE}" == "apic" ]]; then
  # All mcp-server folders except interact-gateway-onprem
  while IFS= read -r -d '' dir; do
    folder="${dir#${REPO_ROOT}/}"
    if [[ "${folder}" != "mcp-servers/interact-gateway-onprem" ]]; then
      PATHS_TO_ZIP+=("${folder}")
    fi
  done < <(find "${REPO_ROOT}/mcp-servers" -mindepth 1 -maxdepth 1 -type d -print0 | sort -z)
else
  # all mode — every mcp-server folder
  while IFS= read -r -d '' dir; do
    PATHS_TO_ZIP+=("${dir#${REPO_ROOT}/}")
  done < <(find "${REPO_ROOT}/mcp-servers" -mindepth 1 -maxdepth 1 -type d -print0 | sort -z)
fi

# Skills: build per-mode exclusion list
if [[ "${MODE}" == "idig" ]]; then
  EXCLUDED_SKILLS=(
    "skills/publish-project"
    "skills/rest-to-mcp-generator"
    "skills/llm-provider-generator"
    "skills/test-generator"
  )
  EXCLUDED_SETUP_FILES=(
    "skills/setup-agent-kit/apic.md"
  )
elif [[ "${MODE}" == "apic" ]]; then
  EXCLUDED_SKILLS=(
    "skills/llm-provider-generator"
    "skills/rest-to-mcp-generator"
  )
  EXCLUDED_SETUP_FILES=(
    "skills/setup-agent-kit/interact-gateway.md"
  )
else
  # all mode — no skill exclusions
  EXCLUDED_SKILLS=()
  EXCLUDED_SETUP_FILES=()
fi

# Add skills folders, honouring per-mode exclusions
while IFS= read -r -d '' dir; do
  folder="${dir#${REPO_ROOT}/}"
  excluded=false
  for excl in "${EXCLUDED_SKILLS[@]+"${EXCLUDED_SKILLS[@]}"}"; do
    if [[ "${folder}" == "${excl}" ]]; then
      excluded=true
      break
    fi
  done
  if [[ "${excluded}" == false ]]; then
    PATHS_TO_ZIP+=("${folder}")
  fi
done < <(find "${REPO_ROOT}/skills" -mindepth 1 -maxdepth 1 -type d -print0 | sort -z)

# ---------------------------------------------------------------------------
# Create the zip
# ---------------------------------------------------------------------------
echo ""
echo "Building ${ZIP_NAME} (mode: ${MODE}) ..."
echo ""

cd "${REPO_ROOT}"

# Build the zip; then remove any per-mode excluded files from inside it
zip -r "${ZIP_PATH}" "${PATHS_TO_ZIP[@]}"

if [[ "${#EXCLUDED_SETUP_FILES[@]}" -gt 0 ]]; then
  echo ""
  echo "Removing excluded setup-agent-kit files from zip ..."
  for f in "${EXCLUDED_SETUP_FILES[@]}"; do
    zip --delete "${ZIP_PATH}" "${f}" 2>/dev/null || true
  done
fi

echo ""
echo "Done! Package created at:"
echo "  ${ZIP_PATH}"
