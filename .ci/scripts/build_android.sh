#!/usr/bin/env bash
# build_android.sh — Flutter Android build (AAB for release, APK for debug)
# with deterministic naming, sha256 sidecar, and obfuscation symbols zip.
#
# Usage:
#   ./.ci/scripts/build_android.sh \
#     --flavor=qa \
#     --build-type=release \
#     --build-number=12345 \
#     --git-sha=abcdef0 \
#     --suffix=qa-release-12345
#
# Required env vars (release only):
#   KEYSTORE_FILE, KEYSTORE_PASSWORD, KEY_ALIAS, KEY_PASSWORD
#   (do not echo these — they are read by Gradle via signingConfigs)

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
FLAVORS_FILE="${REPO_ROOT}/.ci/config/flavors.yaml"

FLAVOR=""
BUILD_TYPE=""
BUILD_NUMBER=""
GIT_SHA=""
SUFFIX=""

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
    echo "ERROR: --${v,,} is required (use long-form flags)" >&2
    exit 2
  fi
done

case "${FLAVOR}" in qa|int|prod) ;; *) echo "ERROR: invalid flavor: ${FLAVOR}" >&2; exit 2 ;; esac
case "${BUILD_TYPE}" in debug|release) ;; *) echo "ERROR: invalid build-type: ${BUILD_TYPE}" >&2; exit 2 ;; esac

if ! command -v yq >/dev/null 2>&1; then
  echo "ERROR: yq is required." >&2; exit 2
fi

# Read flavor config
APP_NAME="$(yq -r ".flavors.${FLAVOR}.app_name" "${FLAVORS_FILE}")"
BACKEND_URL="$(yq -r ".flavors.${FLAVOR}.backend_url" "${FLAVORS_FILE}")"
BUNDLE_SUFFIX="$(yq -r ".flavors.${FLAVOR}.bundle_id_suffix" "${FLAVORS_FILE}")"

APP_VERSION="$(yq -r '.version' "${REPO_ROOT}/pubspec.yaml" | cut -d'+' -f1)"

DIST_DIR="${REPO_ROOT}/build/dist/android"
SYMBOLS_DIR="${REPO_ROOT}/build/symbols/android-${SUFFIX}"
mkdir -p "${DIST_DIR}"

# Cross-platform sha256
sha256_of() {
  if command -v sha256sum >/dev/null 2>&1; then
    sha256sum "$1" | awk '{print $1}'
  else
    shasum -a 256 "$1" | awk '{print $1}'
  fi
}

cd "${REPO_ROOT}"

COMMON_DART_DEFINES=(
  --dart-define=APP_NAME="${APP_NAME}"
  --dart-define=BACKEND_URL="${BACKEND_URL}"
  --dart-define=BUNDLE_SUFFIX="${BUNDLE_SUFFIX}"
  --dart-define=GIT_SHA="${GIT_SHA}"
  --dart-define=BUILD_NUMBER="${BUILD_NUMBER}"
  --dart-define=FLAVOR="${FLAVOR}"
)

if [[ "${BUILD_TYPE}" == "release" ]]; then
  for v in KEYSTORE_FILE KEYSTORE_PASSWORD KEY_ALIAS KEY_PASSWORD; do
    if [[ -z "${!v:-}" ]]; then
      echo "ERROR: env var ${v} is required for release builds." >&2
      exit 2
    fi
  done

  mkdir -p "${SYMBOLS_DIR}"
  echo "Building Android AAB: flavor=${FLAVOR} version=${APP_VERSION} build=${BUILD_NUMBER}"
  flutter build appbundle \
    --flavor="${FLAVOR}" \
    --release \
    --build-name="${APP_VERSION}" \
    --build-number="${BUILD_NUMBER}" \
    --obfuscate \
    --split-debug-info="${SYMBOLS_DIR}" \
    "${COMMON_DART_DEFINES[@]}"

  SRC_AAB="${REPO_ROOT}/build/app/outputs/bundle/${FLAVOR}Release/app-${FLAVOR}-release.aab"
  if [[ ! -f "${SRC_AAB}" ]]; then
    # Fall back to default Gradle path layout.
    SRC_AAB="$(find "${REPO_ROOT}/build/app/outputs/bundle" -name '*.aab' | head -n1 || true)"
  fi
  [[ -f "${SRC_AAB}" ]] || { echo "ERROR: AAB not found after build." >&2; exit 1; }

  OUT="${DIST_DIR}/bankingapp-${FLAVOR}-${SUFFIX}.aab"
  cp "${SRC_AAB}" "${OUT}"
  sha256_of "${OUT}" > "${OUT}.sha256"

  # Zip obfuscation symbols for crash deobfuscation.
  SYMBOLS_ZIP="${DIST_DIR}/bankingapp-${FLAVOR}-${SUFFIX}-symbols.zip"
  ( cd "$(dirname "${SYMBOLS_DIR}")" && zip -qr "${SYMBOLS_ZIP}" "$(basename "${SYMBOLS_DIR}")" )
  sha256_of "${SYMBOLS_ZIP}" > "${SYMBOLS_ZIP}.sha256"

  echo "Built: ${OUT}"
  echo "Symbols: ${SYMBOLS_ZIP}"
else
  echo "Building Android APK (debug): flavor=${FLAVOR}"
  flutter build apk \
    --flavor="${FLAVOR}" \
    --debug \
    --build-name="${APP_VERSION}" \
    --build-number="${BUILD_NUMBER}" \
    "${COMMON_DART_DEFINES[@]}"

  SRC_APK="$(find "${REPO_ROOT}/build/app/outputs/flutter-apk" -name "app-${FLAVOR}-debug.apk" | head -n1 || true)"
  [[ -f "${SRC_APK}" ]] || SRC_APK="$(find "${REPO_ROOT}/build/app/outputs/flutter-apk" -name '*.apk' | head -n1 || true)"
  [[ -f "${SRC_APK}" ]] || { echo "ERROR: APK not found after build." >&2; exit 1; }

  OUT="${DIST_DIR}/bankingapp-${FLAVOR}-${SUFFIX}.apk"
  cp "${SRC_APK}" "${OUT}"
  sha256_of "${OUT}" > "${OUT}.sha256"
  echo "Built: ${OUT}"
fi
