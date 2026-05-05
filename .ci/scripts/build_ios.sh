#!/usr/bin/env bash
# build_ios.sh — Flutter iOS build (signed IPA for release, unsigned Runner.app
# zip for debug). Verifies signature, bundles dSYMs + obfuscation symbols.
#
# Usage:
#   ./.ci/scripts/build_ios.sh \
#     --flavor=qa \
#     --build-type=release \
#     --build-number=12345 \
#     --git-sha=abcdef0 \
#     --suffix=qa-release-12345
#
# Required for release:
#   ios/ExportOptions-${FLAVOR}.plist
#   keychain set up via .ci/scripts/ios_keychain_setup.sh
#   env var KEYCHAIN_NAME (or /tmp/build-keychain-name file) must be present

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
FLAVORS_FILE="${REPO_ROOT}/.ci/config/flavors.yaml"

FLAVOR=""; BUILD_TYPE=""; BUILD_NUMBER=""; GIT_SHA=""; SUFFIX=""

for arg in "$@"; do
  case "${arg}" in
    --flavor=*)        FLAVOR="${arg#*=}" ;;
    --build-type=*)    BUILD_TYPE="${arg#*=}" ;;
    --build-number=*)  BUILD_NUMBER="${arg#*=}" ;;
    --git-sha=*)       GIT_SHA="${arg#*=}" ;;
    --suffix=*)        SUFFIX="${arg#*=}" ;;
    *) echo "ERROR: unknown arg: ${arg}" >&2; exit 2 ;;
  esac
done

for v in FLAVOR BUILD_TYPE BUILD_NUMBER GIT_SHA SUFFIX; do
  if [[ -z "${!v}" ]]; then
    echo "ERROR: --${v,,} is required." >&2; exit 2
  fi
done

case "${FLAVOR}" in qa|int|prod) ;; *) echo "ERROR: invalid flavor: ${FLAVOR}" >&2; exit 2 ;; esac
case "${BUILD_TYPE}" in debug|release) ;; *) echo "ERROR: invalid build-type: ${BUILD_TYPE}" >&2; exit 2 ;; esac

if [[ "$(uname -s)" != "Darwin" ]]; then
  echo "ERROR: iOS builds require macOS." >&2; exit 2
fi
if ! command -v yq >/dev/null 2>&1; then
  echo "ERROR: yq is required." >&2; exit 2
fi

APP_NAME="$(yq -r ".flavors.${FLAVOR}.app_name" "${FLAVORS_FILE}")"
BACKEND_URL="$(yq -r ".flavors.${FLAVOR}.backend_url" "${FLAVORS_FILE}")"
BUNDLE_SUFFIX="$(yq -r ".flavors.${FLAVOR}.bundle_id_suffix" "${FLAVORS_FILE}")"
APP_VERSION="$(yq -r '.version' "${REPO_ROOT}/pubspec.yaml" | cut -d'+' -f1)"

DIST_DIR="${REPO_ROOT}/build/dist/ios"
SYMBOLS_DIR="${REPO_ROOT}/build/symbols/ios-${SUFFIX}"
mkdir -p "${DIST_DIR}"

sha256_of() { shasum -a 256 "$1" | awk '{print $1}'; }

cd "${REPO_ROOT}"

echo "Running pod install..."
( cd ios && pod install --repo-update )

COMMON_DART_DEFINES=(
  --dart-define=APP_NAME="${APP_NAME}"
  --dart-define=BACKEND_URL="${BACKEND_URL}"
  --dart-define=BUNDLE_SUFFIX="${BUNDLE_SUFFIX}"
  --dart-define=GIT_SHA="${GIT_SHA}"
  --dart-define=BUILD_NUMBER="${BUILD_NUMBER}"
  --dart-define=FLAVOR="${FLAVOR}"
)

if [[ "${BUILD_TYPE}" == "release" ]]; then
  EXPORT_OPTS="${REPO_ROOT}/ios/ExportOptions-${FLAVOR}.plist"
  if [[ ! -f "${EXPORT_OPTS}" ]]; then
    echo "ERROR: missing ${EXPORT_OPTS} for release build." >&2
    exit 1
  fi

  # Sanity-check that a keychain has been provisioned.
  if [[ -z "${KEYCHAIN_NAME:-}" ]] && [[ ! -f /tmp/build-keychain-name ]]; then
    echo "ERROR: no signing keychain found. Run ios_keychain_setup.sh first." >&2
    exit 1
  fi

  mkdir -p "${SYMBOLS_DIR}"
  echo "Building iOS IPA: flavor=${FLAVOR} version=${APP_VERSION} build=${BUILD_NUMBER}"
  flutter build ipa \
    --flavor="${FLAVOR}" \
    --release \
    --build-name="${APP_VERSION}" \
    --build-number="${BUILD_NUMBER}" \
    --obfuscate \
    --split-debug-info="${SYMBOLS_DIR}" \
    --export-options-plist="${EXPORT_OPTS}" \
    "${COMMON_DART_DEFINES[@]}"

  SRC_IPA="$(find "${REPO_ROOT}/build/ios/ipa" -name '*.ipa' | head -n1 || true)"
  [[ -f "${SRC_IPA}" ]] || { echo "ERROR: IPA not found after build." >&2; exit 1; }

  echo "Verifying code signature..."
  codesign -v --deep --strict "${SRC_IPA}" || {
    echo "ERROR: codesign verification failed for ${SRC_IPA}" >&2
    exit 1
  }

  OUT="${DIST_DIR}/bankingapp-${FLAVOR}-${SUFFIX}.ipa"
  cp "${SRC_IPA}" "${OUT}"
  sha256_of "${OUT}" > "${OUT}.sha256"

  # Bundle dSYMs + obfuscation symbols
  DSYM_DIR="${REPO_ROOT}/build/ios/archive/Runner.xcarchive/dSYMs"
  SYMBOLS_ZIP="${DIST_DIR}/bankingapp-${FLAVOR}-${SUFFIX}-symbols.zip"
  STAGE="$(mktemp -d)"
  mkdir -p "${STAGE}/dSYMs" "${STAGE}/obfuscation"
  if [[ -d "${DSYM_DIR}" ]]; then
    cp -R "${DSYM_DIR}/." "${STAGE}/dSYMs/"
  fi
  cp -R "${SYMBOLS_DIR}/." "${STAGE}/obfuscation/"
  ( cd "${STAGE}" && zip -qr "${SYMBOLS_ZIP}" dSYMs obfuscation )
  rm -rf "${STAGE}"
  sha256_of "${SYMBOLS_ZIP}" > "${SYMBOLS_ZIP}.sha256"

  echo "Built: ${OUT}"
  echo "Symbols: ${SYMBOLS_ZIP}"
else
  echo "Building iOS (debug, no codesign): flavor=${FLAVOR}"
  flutter build ios \
    --flavor="${FLAVOR}" \
    --debug \
    --no-codesign \
    --build-name="${APP_VERSION}" \
    --build-number="${BUILD_NUMBER}" \
    "${COMMON_DART_DEFINES[@]}"

  RUNNER_APP="${REPO_ROOT}/build/ios/iphoneos/Runner.app"
  [[ -d "${RUNNER_APP}" ]] || { echo "ERROR: Runner.app not found." >&2; exit 1; }

  OUT="${DIST_DIR}/bankingapp-${FLAVOR}-${SUFFIX}.app.zip"
  ( cd "$(dirname "${RUNNER_APP}")" && zip -qr "${OUT}" "$(basename "${RUNNER_APP}")" )
  sha256_of "${OUT}" > "${OUT}.sha256"
  echo "Built: ${OUT}"
fi
